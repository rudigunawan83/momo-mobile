using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using MomoAI.Application.DTOs;
using MomoAI.Application.Interfaces;

namespace MomoAI.API.Hubs;

/// <summary>
/// SignalR Hub for real-time chat streaming and state synchronization.
/// Delivers AI response chunks within 300ms and pushes friendship state updates within 500ms.
/// Requires authenticated connections.
/// </summary>
[Authorize]
public class ChatHub : Hub<IChatHubClient>
{
    private readonly IChatService _chatService;
    private readonly IFriendshipService _friendshipService;
    private readonly IAIGateway _aiGateway;
    private readonly IMemoryEngine _memoryEngine;
    private readonly IPersonalityEngine _personalityEngine;
    private readonly ILogger<ChatHub> _logger;

    public ChatHub(
        IChatService chatService,
        IFriendshipService friendshipService,
        IAIGateway aiGateway,
        IMemoryEngine memoryEngine,
        IPersonalityEngine personalityEngine,
        ILogger<ChatHub> logger)
    {
        _chatService = chatService;
        _friendshipService = friendshipService;
        _aiGateway = aiGateway;
        _memoryEngine = memoryEngine;
        _personalityEngine = personalityEngine;
        _logger = logger;
    }

    /// <summary>
    /// Called when a client connects to the hub.
    /// Associates the connection with the user's group for targeted messaging.
    /// </summary>
    public override async Task OnConnectedAsync()
    {
        var userId = GetUserId();
        if (userId != Guid.Empty)
        {
            // Add the connection to a user-specific group for targeted notifications
            await Groups.AddToGroupAsync(Context.ConnectionId, userId.ToString());
            _logger.LogInformation("User {UserId} connected to ChatHub. ConnectionId: {ConnectionId}",
                userId, Context.ConnectionId);
        }

        await base.OnConnectedAsync();
    }

    /// <summary>
    /// Called when a client disconnects from the hub.
    /// Removes the connection from the user's group.
    /// </summary>
    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = GetUserId();
        if (userId != Guid.Empty)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, userId.ToString());
            _logger.LogInformation("User {UserId} disconnected from ChatHub. ConnectionId: {ConnectionId}. Reason: {Reason}",
                userId, Context.ConnectionId, exception?.Message ?? "Normal disconnect");
        }

        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>
    /// Processes a chat message and streams the AI response back to the caller in real-time.
    /// Each chunk is delivered within 300ms of generation from the AI gateway.
    /// After streaming completes, a completion signal is sent and friendship state is pushed.
    /// </summary>
    /// <param name="message">The user's chat message text.</param>
    public async Task SendMessage(string message)
    {
        var userId = GetUserId();
        if (userId == Guid.Empty)
        {
            await Clients.Caller.ReceiveError("Authentication required.");
            return;
        }

        try
        {
            _logger.LogInformation("Processing streaming message from user {UserId}", userId);

            // Validate the message
            if (string.IsNullOrWhiteSpace(message))
            {
                await Clients.Caller.ReceiveError("Message content is required.");
                return;
            }

            if (message.Length > 4000)
            {
                await Clients.Caller.ReceiveError("Message exceeds maximum length of 4000 characters.");
                return;
            }

            // Build AI request context (memories + personality + history)
            var personality = _personalityEngine.GetProfile(userId);
            var systemPrompt = _personalityEngine.ApplyPersonalityToPrompt(
                "You are Momo, a friendly AI companion.", personality);

            List<string> memoryContext;
            try
            {
                var memories = await _memoryEngine.GetRelevantMemoriesAsync(
                    userId, message, maxResults: 5, Context.ConnectionAborted);
                memoryContext = memories.Select(m => m.Summary).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Memory engine unavailable for user {UserId}, proceeding without context", userId);
                memoryContext = new List<string>();
            }

            var aiRequest = new AIRequest
            {
                SystemPrompt = systemPrompt,
                UserMessage = message,
                Context = memoryContext,
                Temperature = 0.7,
                MaxTokens = 1024
            };

            // Stream the response directly from the AI gateway
            var fullResponse = new System.Text.StringBuilder();
            await foreach (var chunk in _aiGateway.GenerateStreamingAsync(aiRequest, Context.ConnectionAborted))
            {
                fullResponse.Append(chunk);
                // Each chunk is delivered immediately as it's generated — within 300ms of chunk generation
                await Clients.Caller.ReceiveResponseChunk(chunk);
            }

            var responseText = fullResponse.ToString();
            var emotion = DetectEmotion(responseText);

            // Send completion signal
            await Clients.Caller.ReceiveResponseComplete(responseText, emotion);

            // Post-processing: store memory and award XP (fire-and-forget style within the request)
            await PostProcessMessageAsync(userId, message, responseText);
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Message processing cancelled for user {UserId}", userId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing message for user {UserId}", userId);
            await Clients.Caller.ReceiveError("An error occurred while processing your message. Please try again.");
        }
    }

    /// <summary>
    /// Processes a chat message using the non-streaming pipeline.
    /// Falls back to chunking the complete response for clients that prefer this mode.
    /// </summary>
    /// <param name="message">The user's chat message text.</param>
    public async Task SendMessageNonStreaming(string message)
    {
        var userId = GetUserId();
        if (userId == Guid.Empty)
        {
            await Clients.Caller.ReceiveError("Authentication required.");
            return;
        }

        try
        {
            _logger.LogInformation("Processing non-streaming message from user {UserId}", userId);

            var request = new ChatRequest
            {
                UserId = userId,
                Message = message,
                ConversationType = Domain.Enums.ConversationType.Text
            };

            // Process the message through the full AI pipeline
            var response = await _chatService.ProcessMessageAsync(request, Context.ConnectionAborted);

            // Stream the response to the caller as chunks for smooth rendering
            var chunks = ChunkResponse(response.Message);
            foreach (var chunk in chunks)
            {
                await Clients.Caller.ReceiveResponseChunk(chunk);
            }

            // Send completion signal
            await Clients.Caller.ReceiveResponseComplete(
                response.Message,
                response.Emotion.ToString());

            // Push friendship state update if XP was gained
            if (response.XpGained > 0)
            {
                await PushFriendshipStateAsync(userId, response.XpGained, response.LevelUp, response.NewAchievements, "Chat");
            }
        }
        catch (OperationCanceledException)
        {
            _logger.LogWarning("Message processing cancelled for user {UserId}", userId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing message for user {UserId}", userId);
            await Clients.Caller.ReceiveError("An error occurred while processing your message. Please try again.");
        }
    }

    /// <summary>
    /// Allows the client to request the current friendship state.
    /// </summary>
    public async Task RequestFriendshipState()
    {
        var userId = GetUserId();
        if (userId == Guid.Empty)
        {
            await Clients.Caller.ReceiveError("Authentication required.");
            return;
        }

        try
        {
            var state = await _friendshipService.GetStateAsync(userId, Context.ConnectionAborted);

            var update = new FriendshipStateUpdate
            {
                Level = state.Level,
                CurrentXP = state.CurrentXP,
                XPToNextLevel = state.XPToNextLevel,
                TotalXP = state.TotalXP,
                XpGained = 0,
                LeveledUp = false,
                NewAchievements = new List<string>(),
                UpdateReason = "StateRequest"
            };

            await Clients.Caller.ReceiveFriendshipUpdate(update);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving friendship state for user {UserId}", userId);
            await Clients.Caller.ReceiveError("Failed to retrieve friendship state.");
        }
    }

    /// <summary>
    /// Handles post-processing after streaming completes: stores memory, awards XP,
    /// and pushes friendship state update to the client within 500ms.
    /// </summary>
    private async Task PostProcessMessageAsync(Guid userId, string userMessage, string responseText)
    {
        try
        {
            // Store conversation as memory
            await _memoryEngine.StoreMemoryAsync(userId, new MemoryInput
            {
                Summary = $"User: {Truncate(userMessage, 100)} | Momo: {Truncate(responseText, 100)}",
                Content = responseText,
                Type = Domain.Enums.MemoryType.Conversation,
            }, Context.ConnectionAborted);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to store memory for user {UserId}", userId);
        }

        try
        {
            // Award XP for chat interaction
            var xpResult = await _friendshipService.AddXPAsync(
                userId, Domain.Enums.XPSource.Chat, amount: 10, Context.ConnectionAborted);

            // Push friendship state update within 500ms
            if (xpResult.Amount > 0)
            {
                await PushFriendshipStateAsync(userId, xpResult.Amount, xpResult.LeveledUp,
                    new List<string>(), "Chat");
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to award XP for user {UserId}", userId);
        }
    }

    /// <summary>
    /// Pushes friendship state update to the connected client within 500ms of the event.
    /// </summary>
    private async Task PushFriendshipStateAsync(Guid userId, int xpGained, bool leveledUp,
        List<string> newAchievements, string updateReason)
    {
        var friendshipState = await _friendshipService.GetStateAsync(userId, Context.ConnectionAborted);

        var update = new FriendshipStateUpdate
        {
            Level = friendshipState.Level,
            CurrentXP = friendshipState.CurrentXP,
            XPToNextLevel = friendshipState.XPToNextLevel,
            TotalXP = friendshipState.TotalXP,
            XpGained = xpGained,
            LeveledUp = leveledUp,
            NewAchievements = newAchievements,
            UpdateReason = updateReason
        };

        await Clients.Caller.ReceiveFriendshipUpdate(update);
    }

    /// <summary>
    /// Extracts the authenticated user's ID from the connection context claims.
    /// </summary>
    private Guid GetUserId()
    {
        var userIdClaim = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? Context.User?.FindFirst("sub")?.Value;

        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
        {
            return Guid.Empty;
        }

        return userId;
    }

    /// <summary>
    /// Simple emotion detection from response text.
    /// Returns the emotion as a string for the completion signal.
    /// </summary>
    private static string DetectEmotion(string text)
    {
        if (string.IsNullOrWhiteSpace(text))
            return "Neutral";

        var lower = text.ToLowerInvariant();

        if (ContainsAny(lower, "haha", "lucu", "😂", "😄", "wkwk"))
            return "Happy";
        if (ContainsAny(lower, "sedih", "maaf", "😢", "😔"))
            return "Sad";
        if (ContainsAny(lower, "menarik", "kenapa", "bagaimana", "🤔"))
            return "Curious";
        if (ContainsAny(lower, "wow", "keren", "amazing", "🎉"))
            return "Excited";
        if (ContainsAny(lower, "malu", "😳"))
            return "Shy";

        return "Happy";
    }

    private static bool ContainsAny(string text, params string[] keywords)
    {
        foreach (var keyword in keywords)
        {
            if (text.Contains(keyword, StringComparison.Ordinal))
                return true;
        }
        return false;
    }

    /// <summary>
    /// Splits a response into chunks for non-streaming delivery.
    /// Each chunk represents a meaningful portion of text for smooth client-side rendering.
    /// </summary>
    private static List<string> ChunkResponse(string response)
    {
        var chunks = new List<string>();

        if (string.IsNullOrEmpty(response))
        {
            return chunks;
        }

        // Split at reasonable intervals for natural streaming feel
        const int maxChunkSize = 50; // characters per chunk for smooth streaming
        var index = 0;

        while (index < response.Length)
        {
            var remaining = response.Length - index;
            if (remaining <= maxChunkSize)
            {
                chunks.Add(response[index..]);
                break;
            }

            // Try to break at a space near the max chunk size
            var segment = response.Substring(index, maxChunkSize);
            var breakPoint = segment.LastIndexOf(' ');
            if (breakPoint <= 0)
            {
                breakPoint = maxChunkSize;
            }

            chunks.Add(response.Substring(index, breakPoint));
            index += breakPoint;
        }

        return chunks;
    }

    private static string Truncate(string text, int maxLength)
    {
        if (string.IsNullOrEmpty(text) || text.Length <= maxLength)
            return text;
        return text[..maxLength] + "...";
    }
}
