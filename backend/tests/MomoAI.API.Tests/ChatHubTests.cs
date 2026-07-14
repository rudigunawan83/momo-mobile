using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Logging;
using MomoAI.API.Hubs;
using MomoAI.Application.DTOs;
using MomoAI.Application.Interfaces;
using MomoAI.Domain.Enums;
using NSubstitute;

namespace MomoAI.API.Tests;

public class ChatHubTests
{
    private readonly IChatService _chatService;
    private readonly IFriendshipService _friendshipService;
    private readonly IAIGateway _aiGateway;
    private readonly IMemoryEngine _memoryEngine;
    private readonly IPersonalityEngine _personalityEngine;
    private readonly ILogger<ChatHub> _logger;
    private readonly ChatHub _hub;
    private readonly IChatHubClient _callerClient;
    private readonly IHubCallerClients<IChatHubClient> _clients;
    private readonly HubCallerContext _hubContext;
    private readonly IGroupManager _groups;

    private readonly Guid _testUserId = Guid.NewGuid();

    public ChatHubTests()
    {
        _chatService = Substitute.For<IChatService>();
        _friendshipService = Substitute.For<IFriendshipService>();
        _aiGateway = Substitute.For<IAIGateway>();
        _memoryEngine = Substitute.For<IMemoryEngine>();
        _personalityEngine = Substitute.For<IPersonalityEngine>();
        _logger = Substitute.For<ILogger<ChatHub>>();

        _callerClient = Substitute.For<IChatHubClient>();
        _clients = Substitute.For<IHubCallerClients<IChatHubClient>>();
        _clients.Caller.Returns(_callerClient);

        _hubContext = Substitute.For<HubCallerContext>();
        _groups = Substitute.For<IGroupManager>();

        // Set up authenticated user
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, _testUserId.ToString())
        };
        var identity = new ClaimsIdentity(claims, "TestAuth");
        var principal = new ClaimsPrincipal(identity);
        _hubContext.User.Returns(principal);
        _hubContext.ConnectionId.Returns("test-connection-id");
        _hubContext.ConnectionAborted.Returns(CancellationToken.None);

        _hub = new ChatHub(
            _chatService,
            _friendshipService,
            _aiGateway,
            _memoryEngine,
            _personalityEngine,
            _logger);

        // Set Hub properties using the correct declared-only binding flags
        SetHubContext(_hub);
    }

    private void SetHubContext(ChatHub hub)
    {
        // Hub<T>.Clients is declared on Hub<T> itself, but Hub (non-generic) also has Clients
        // Use DeclaredOnly to avoid ambiguous matches
        var hubGenericType = typeof(Hub<IChatHubClient>);
        var clientsProp = hubGenericType.GetProperty("Clients",
            System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.DeclaredOnly);
        clientsProp!.SetValue(hub, _clients);

        // Context and Groups are declared on Hub (non-generic base)
        var hubBaseType = typeof(Hub);
        var contextProp = hubBaseType.GetProperty("Context",
            System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.DeclaredOnly);
        contextProp!.SetValue(hub, _hubContext);

        var groupsProp = hubBaseType.GetProperty("Groups",
            System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.DeclaredOnly);
        groupsProp!.SetValue(hub, _groups);
    }

    [Fact]
    public async Task OnConnectedAsync_AuthenticatedUser_AddsToGroup()
    {
        // Act
        await _hub.OnConnectedAsync();

        // Assert
        await _groups.Received(1).AddToGroupAsync(
            "test-connection-id",
            _testUserId.ToString(),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task OnDisconnectedAsync_AuthenticatedUser_RemovesFromGroup()
    {
        // Act
        await _hub.OnDisconnectedAsync(null);

        // Assert
        await _groups.Received(1).RemoveFromGroupAsync(
            "test-connection-id",
            _testUserId.ToString(),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task SendMessage_UnauthenticatedUser_SendsError()
    {
        // Arrange - set up unauthenticated context
        _hubContext.User.Returns((ClaimsPrincipal?)null);

        // Act
        await _hub.SendMessage("Hello Momo");

        // Assert
        await _callerClient.Received(1).ReceiveError("Authentication required.");
    }

    [Fact]
    public async Task SendMessage_EmptyMessage_SendsValidationError()
    {
        // Act
        await _hub.SendMessage("   ");

        // Assert
        await _callerClient.Received(1).ReceiveError("Message content is required.");
    }

    [Fact]
    public async Task SendMessage_MessageTooLong_SendsValidationError()
    {
        // Arrange
        var longMessage = new string('a', 4001);

        // Act
        await _hub.SendMessage(longMessage);

        // Assert
        await _callerClient.Received(1).ReceiveError("Message exceeds maximum length of 4000 characters.");
    }

    [Fact]
    public async Task SendMessage_ValidMessage_StreamsChunksFromAIGateway()
    {
        // Arrange
        SetupDefaultPersonality();
        SetupDefaultMemories();

        var chunks = new[] { "Hello ", "there, ", "friend!" };
        _aiGateway.GenerateStreamingAsync(Arg.Any<AIRequest>(), Arg.Any<CancellationToken>())
            .Returns(ToAsyncEnumerable(chunks));

        _friendshipService.AddXPAsync(_testUserId, XPSource.Chat, 10, Arg.Any<CancellationToken>())
            .Returns(new XPResult { Amount = 10, NewTotalXP = 110, NewLevel = 1, LeveledUp = false });

        _friendshipService.GetStateAsync(_testUserId, Arg.Any<CancellationToken>())
            .Returns(new FriendshipState
            {
                UserId = _testUserId,
                Level = 1,
                CurrentXP = 110,
                XPToNextLevel = 200,
                TotalXP = 110
            });

        // Act
        await _hub.SendMessage("Hello Momo");

        // Assert - chunks are streamed
        await _callerClient.Received(1).ReceiveResponseChunk("Hello ");
        await _callerClient.Received(1).ReceiveResponseChunk("there, ");
        await _callerClient.Received(1).ReceiveResponseChunk("friend!");
    }

    [Fact]
    public async Task SendMessage_ValidMessage_SendsCompletionSignal()
    {
        // Arrange
        SetupDefaultPersonality();
        SetupDefaultMemories();

        var chunks = new[] { "Hi!" };
        _aiGateway.GenerateStreamingAsync(Arg.Any<AIRequest>(), Arg.Any<CancellationToken>())
            .Returns(ToAsyncEnumerable(chunks));

        _friendshipService.AddXPAsync(_testUserId, XPSource.Chat, 10, Arg.Any<CancellationToken>())
            .Returns(new XPResult { Amount = 10, NewTotalXP = 10, NewLevel = 1, LeveledUp = false });

        _friendshipService.GetStateAsync(_testUserId, Arg.Any<CancellationToken>())
            .Returns(new FriendshipState
            {
                UserId = _testUserId,
                Level = 1,
                CurrentXP = 10,
                XPToNextLevel = 100,
                TotalXP = 10
            });

        // Act
        await _hub.SendMessage("Hey");

        // Assert - completion signal sent with full response and emotion
        await _callerClient.Received(1).ReceiveResponseComplete("Hi!", Arg.Any<string>());
    }

    [Fact]
    public async Task SendMessage_XPGained_PushesFriendshipUpdate()
    {
        // Arrange
        SetupDefaultPersonality();
        SetupDefaultMemories();

        _aiGateway.GenerateStreamingAsync(Arg.Any<AIRequest>(), Arg.Any<CancellationToken>())
            .Returns(ToAsyncEnumerable(new[] { "Response" }));

        _friendshipService.AddXPAsync(_testUserId, XPSource.Chat, 10, Arg.Any<CancellationToken>())
            .Returns(new XPResult { Amount = 10, NewTotalXP = 210, NewLevel = 2, LeveledUp = true });

        _friendshipService.GetStateAsync(_testUserId, Arg.Any<CancellationToken>())
            .Returns(new FriendshipState
            {
                UserId = _testUserId,
                Level = 2,
                CurrentXP = 10,
                XPToNextLevel = 283,
                TotalXP = 210
            });

        // Act
        await _hub.SendMessage("Hello");

        // Assert - friendship update pushed
        await _callerClient.Received(1).ReceiveFriendshipUpdate(
            Arg.Is<FriendshipStateUpdate>(u =>
                u.Level == 2 &&
                u.XpGained == 10 &&
                u.LeveledUp == true &&
                u.UpdateReason == "Chat"));
    }

    [Fact]
    public async Task RequestFriendshipState_AuthenticatedUser_ReturnsFriendshipState()
    {
        // Arrange
        _friendshipService.GetStateAsync(_testUserId, Arg.Any<CancellationToken>())
            .Returns(new FriendshipState
            {
                UserId = _testUserId,
                Level = 3,
                CurrentXP = 50,
                XPToNextLevel = 520,
                TotalXP = 1050,
                LoginStreak = 5
            });

        // Act
        await _hub.RequestFriendshipState();

        // Assert
        await _callerClient.Received(1).ReceiveFriendshipUpdate(
            Arg.Is<FriendshipStateUpdate>(u =>
                u.Level == 3 &&
                u.CurrentXP == 50 &&
                u.TotalXP == 1050 &&
                u.UpdateReason == "StateRequest"));
    }

    [Fact]
    public async Task RequestFriendshipState_UnauthenticatedUser_SendsError()
    {
        // Arrange
        _hubContext.User.Returns((ClaimsPrincipal?)null);

        // Act
        await _hub.RequestFriendshipState();

        // Assert
        await _callerClient.Received(1).ReceiveError("Authentication required.");
    }

    [Fact]
    public async Task SendMessage_MemoryEngineUnavailable_ProceedsWithoutMemory()
    {
        // Arrange
        SetupDefaultPersonality();
        _memoryEngine.GetRelevantMemoriesAsync(
            _testUserId, Arg.Any<string>(), Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Returns<Task<List<Memory>>>(x => throw new Exception("Memory engine down"));

        _memoryEngine.StoreMemoryAsync(_testUserId, Arg.Any<MemoryInput>(), Arg.Any<CancellationToken>())
            .Returns(new Memory { Id = Guid.NewGuid(), UserId = _testUserId });

        _aiGateway.GenerateStreamingAsync(Arg.Any<AIRequest>(), Arg.Any<CancellationToken>())
            .Returns(ToAsyncEnumerable(new[] { "Hi there!" }));

        _friendshipService.AddXPAsync(_testUserId, XPSource.Chat, 10, Arg.Any<CancellationToken>())
            .Returns(new XPResult { Amount = 10, NewTotalXP = 10, NewLevel = 1, LeveledUp = false });

        _friendshipService.GetStateAsync(_testUserId, Arg.Any<CancellationToken>())
            .Returns(new FriendshipState
            {
                UserId = _testUserId,
                Level = 1,
                CurrentXP = 10,
                XPToNextLevel = 100,
                TotalXP = 10
            });

        // Act
        await _hub.SendMessage("Hello");

        // Assert - still streams response despite memory failure
        await _callerClient.Received(1).ReceiveResponseChunk("Hi there!");
        await _callerClient.Received(1).ReceiveResponseComplete("Hi there!", Arg.Any<string>());
    }

    [Fact]
    public async Task SendMessage_AIGatewayThrows_SendsErrorToClient()
    {
        // Arrange
        SetupDefaultPersonality();
        SetupDefaultMemories();

        _aiGateway.GenerateStreamingAsync(Arg.Any<AIRequest>(), Arg.Any<CancellationToken>())
            .Returns(ThrowingAsyncEnumerable());

        // Act
        await _hub.SendMessage("Hello");

        // Assert
        await _callerClient.Received(1).ReceiveError(
            "An error occurred while processing your message. Please try again.");
    }

    private void SetupDefaultPersonality()
    {
        _personalityEngine.GetProfile(_testUserId)
            .Returns(new PersonalityProfile
            {
                UserId = _testUserId,
                Humor = 0.5,
                Caring = 0.5,
                Curious = 0.5,
                Calm = 0.5,
                TonePreference = "balanced"
            });

        _personalityEngine.ApplyPersonalityToPrompt(Arg.Any<string>(), Arg.Any<PersonalityProfile>())
            .Returns("You are Momo, a friendly companion.");
    }

    private void SetupDefaultMemories()
    {
        _memoryEngine.GetRelevantMemoriesAsync(
            _testUserId, Arg.Any<string>(), Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Returns(new List<Memory>());

        _memoryEngine.StoreMemoryAsync(_testUserId, Arg.Any<MemoryInput>(), Arg.Any<CancellationToken>())
            .Returns(new Memory { Id = Guid.NewGuid(), UserId = _testUserId });
    }

    private static async IAsyncEnumerable<string> ToAsyncEnumerable(string[] items)
    {
        foreach (var item in items)
        {
            yield return item;
            await Task.CompletedTask;
        }
    }

    private static async IAsyncEnumerable<string> ThrowingAsyncEnumerable()
    {
        await Task.CompletedTask;
        throw new Exception("AI Gateway failed");
#pragma warning disable CS0162 // Unreachable code
        yield break;
#pragma warning restore CS0162
    }
}
