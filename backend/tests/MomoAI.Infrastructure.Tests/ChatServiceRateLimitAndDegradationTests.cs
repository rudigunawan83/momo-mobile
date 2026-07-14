using Microsoft.Extensions.Logging;
using MomoAI.Application.DTOs;
using MomoAI.Application.Exceptions;
using MomoAI.Application.Interfaces;
using MomoAI.Domain.Enums;
using MomoAI.Infrastructure.Services;
using NSubstitute;
using NSubstitute.ExceptionExtensions;

namespace MomoAI.Infrastructure.Tests;

public class ChatServiceRateLimitAndDegradationTests
{
    private readonly IAIGateway _aiGateway;
    private readonly IMemoryEngine _memoryEngine;
    private readonly IPersonalityEngine _personalityEngine;
    private readonly IFriendshipService _friendshipService;
    private readonly IChatMessageRepository _chatMessageRepository;
    private readonly IPromptInjectionDetector _promptInjectionDetector;
    private readonly IContentFilter _contentFilter;
    private readonly IRateLimiter _rateLimiter;
    private readonly ILogger<ChatService> _logger;
    private readonly ChatService _chatService;

    private readonly Guid _testUserId = Guid.NewGuid();

    public ChatServiceRateLimitAndDegradationTests()
    {
        _aiGateway = Substitute.For<IAIGateway>();
        _memoryEngine = Substitute.For<IMemoryEngine>();
        _personalityEngine = Substitute.For<IPersonalityEngine>();
        _friendshipService = Substitute.For<IFriendshipService>();
        _chatMessageRepository = Substitute.For<IChatMessageRepository>();
        _promptInjectionDetector = Substitute.For<IPromptInjectionDetector>();
        _contentFilter = Substitute.For<IContentFilter>();
        _rateLimiter = Substitute.For<IRateLimiter>();
        _logger = Substitute.For<ILogger<ChatService>>();

        _chatService = new ChatService(
            _aiGateway,
            _memoryEngine,
            _personalityEngine,
            _friendshipService,
            _chatMessageRepository,
            _promptInjectionDetector,
            _contentFilter,
            _rateLimiter,
            _logger);

        SetupDefaults();
    }

    private void SetupDefaults()
    {
        // Default: allow rate limit
        _rateLimiter.CheckRateLimit(Arg.Any<Guid>())
            .Returns(RateLimitResult.Allowed(59));

        // Default: no injection detected
        _promptInjectionDetector.Detect(Arg.Any<string>())
            .Returns(new PromptInjectionResult { IsInjectionDetected = false });

        // Default: content passes filter
        _contentFilter.Filter(Arg.Any<string>())
            .Returns(new ContentFilterResult { IsBlocked = false });

        // Default: personality
        _personalityEngine.GetProfile(Arg.Any<Guid>())
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
            .Returns("System prompt with personality");

        // Default: memories
        _memoryEngine.GetRelevantMemoriesAsync(Arg.Any<Guid>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Returns(new List<Memory>());
        _memoryEngine.StoreMemoryAsync(Arg.Any<Guid>(), Arg.Any<MemoryInput>(), Arg.Any<CancellationToken>())
            .Returns(new Memory { Id = Guid.NewGuid(), UserId = _testUserId });

        // Default: recent messages
        _chatMessageRepository.GetRecentMessagesAsync(Arg.Any<Guid>(), Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Returns(new List<ChatMessageDto>());

        // Default: AI response
        _aiGateway.GenerateAsync(Arg.Any<AIRequest>(), Arg.Any<CancellationToken>())
            .Returns(new AIResponse
            {
                Text = "Hello friend!",
                DetectedEmotion = EmotionType.Happy,
                SentimentScore = 0.7
            });

        // Default: XP result
        _friendshipService.AddXPAsync(Arg.Any<Guid>(), Arg.Any<XPSource>(), Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Returns(new XPResult { Amount = 10, NewTotalXP = 100, NewLevel = 1, LeveledUp = false });

        // Default: no new achievements
        _friendshipService.CheckNewAchievementsAsync(Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns(new List<Achievement>());
    }

    // ==================== Rate Limiting Tests ====================

    [Fact]
    public async Task ProcessMessageAsync_RateLimitExceeded_ThrowsRateLimitExceededException()
    {
        // Arrange
        _rateLimiter.CheckRateLimit(_testUserId)
            .Returns(RateLimitResult.Denied(retryAfterSeconds: 30));

        var request = new ChatRequest
        {
            UserId = _testUserId,
            Message = "Hello"
        };

        // Act & Assert
        var ex = await Assert.ThrowsAsync<RateLimitExceededException>(
            () => _chatService.ProcessMessageAsync(request, CancellationToken.None));

        Assert.Equal(30, ex.RetryAfterSeconds);
        Assert.Equal(EmotionType.Sleepy, ex.Emotion);
    }

    [Fact]
    public async Task ProcessMessageAsync_RateLimitExceeded_DoesNotCallAIGateway()
    {
        // Arrange
        _rateLimiter.CheckRateLimit(_testUserId)
            .Returns(RateLimitResult.Denied(retryAfterSeconds: 15));

        var request = new ChatRequest
        {
            UserId = _testUserId,
            Message = "Hello"
        };

        // Act
        try { await _chatService.ProcessMessageAsync(request, CancellationToken.None); }
        catch (RateLimitExceededException) { }

        // Assert - AI Gateway should never be called
        await _aiGateway.DidNotReceive().GenerateAsync(Arg.Any<AIRequest>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task ProcessMessageAsync_RateLimitExceeded_DoesNotStoreMemoryOrAwardXP()
    {
        // Arrange
        _rateLimiter.CheckRateLimit(_testUserId)
            .Returns(RateLimitResult.Denied(retryAfterSeconds: 10));

        var request = new ChatRequest
        {
            UserId = _testUserId,
            Message = "Hello"
        };

        // Act
        try { await _chatService.ProcessMessageAsync(request, CancellationToken.None); }
        catch (RateLimitExceededException) { }

        // Assert
        await _memoryEngine.DidNotReceive().StoreMemoryAsync(Arg.Any<Guid>(), Arg.Any<MemoryInput>(), Arg.Any<CancellationToken>());
        await _friendshipService.DidNotReceive().AddXPAsync(Arg.Any<Guid>(), Arg.Any<XPSource>(), Arg.Any<int>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task ProcessMessageAsync_RateLimitAllowed_ProcessesNormally()
    {
        // Arrange
        _rateLimiter.CheckRateLimit(_testUserId)
            .Returns(RateLimitResult.Allowed(remaining: 50));

        var request = new ChatRequest
        {
            UserId = _testUserId,
            Message = "Hello Momo"
        };

        // Act
        var response = await _chatService.ProcessMessageAsync(request, CancellationToken.None);

        // Assert
        Assert.NotNull(response);
        Assert.Equal("Hello friend!", response.Message);
        Assert.Equal(EmotionType.Happy, response.Emotion);
    }

    [Fact]
    public async Task ProcessVoiceMessageAsync_RateLimitExceeded_ThrowsRateLimitExceededException()
    {
        // Arrange
        _rateLimiter.CheckRateLimit(_testUserId)
            .Returns(RateLimitResult.Denied(retryAfterSeconds: 45));

        var request = new VoiceRequest
        {
            UserId = _testUserId,
            TranscribedText = "Hello voice",
            DurationSeconds = 2.0
        };

        // Act & Assert
        var ex = await Assert.ThrowsAsync<RateLimitExceededException>(
            () => _chatService.ProcessVoiceMessageAsync(request, CancellationToken.None));

        Assert.Equal(45, ex.RetryAfterSeconds);
        Assert.Equal(EmotionType.Sleepy, ex.Emotion);
    }

    [Fact]
    public async Task ProcessMessageAsync_RateLimitException_ContainsWaitTimeInMessage()
    {
        // Arrange
        _rateLimiter.CheckRateLimit(_testUserId)
            .Returns(RateLimitResult.Denied(retryAfterSeconds: 22));

        var request = new ChatRequest
        {
            UserId = _testUserId,
            Message = "Hello"
        };

        // Act & Assert
        var ex = await Assert.ThrowsAsync<RateLimitExceededException>(
            () => _chatService.ProcessMessageAsync(request, CancellationToken.None));

        Assert.Contains("22", ex.Message);
    }

    // ==================== Memory Engine Degradation Tests ====================

    [Fact]
    public async Task ProcessMessageAsync_MemoryEngineUnavailable_ProceedsWithoutContext()
    {
        // Arrange
        _memoryEngine.GetRelevantMemoriesAsync(Arg.Any<Guid>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Throws(new Exception("Memory engine is down"));

        var request = new ChatRequest
        {
            UserId = _testUserId,
            Message = "Hello Momo"
        };

        // Act
        var response = await _chatService.ProcessMessageAsync(request, CancellationToken.None);

        // Assert - response is still generated successfully
        Assert.NotNull(response);
        Assert.Equal("Hello friend!", response.Message);
    }

    [Fact]
    public async Task ProcessMessageAsync_MemoryEngineUnavailable_SetsMemoryContextAppliedFalse()
    {
        // Arrange
        _memoryEngine.GetRelevantMemoriesAsync(Arg.Any<Guid>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Throws(new Exception("Memory engine is down"));

        var request = new ChatRequest
        {
            UserId = _testUserId,
            Message = "Hello Momo"
        };

        // Act
        var response = await _chatService.ProcessMessageAsync(request, CancellationToken.None);

        // Assert - metadata flag indicates memory context was not applied
        Assert.False(response.MemoryContextApplied);
    }

    [Fact]
    public async Task ProcessMessageAsync_MemoryEngineAvailable_SetsMemoryContextAppliedTrue()
    {
        // Arrange
        _memoryEngine.GetRelevantMemoriesAsync(Arg.Any<Guid>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Returns(new List<Memory>
            {
                new Memory { Id = Guid.NewGuid(), UserId = _testUserId, Summary = "Previous chat" }
            });

        var request = new ChatRequest
        {
            UserId = _testUserId,
            Message = "Hello Momo"
        };

        // Act
        var response = await _chatService.ProcessMessageAsync(request, CancellationToken.None);

        // Assert
        Assert.True(response.MemoryContextApplied);
    }

    [Fact]
    public async Task ProcessMessageAsync_MemoryEngineUnavailable_StillAwardsXP()
    {
        // Arrange
        _memoryEngine.GetRelevantMemoriesAsync(Arg.Any<Guid>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Throws(new Exception("Memory engine is down"));

        var request = new ChatRequest
        {
            UserId = _testUserId,
            Message = "Hello Momo"
        };

        // Act
        var response = await _chatService.ProcessMessageAsync(request, CancellationToken.None);

        // Assert - XP was still awarded
        Assert.Equal(10, response.XpGained);
        await _friendshipService.Received(1).AddXPAsync(_testUserId, XPSource.Chat, 10, Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task ProcessVoiceMessageAsync_MemoryEngineUnavailable_SetsMemoryContextAppliedFalse()
    {
        // Arrange
        _memoryEngine.GetRelevantMemoriesAsync(Arg.Any<Guid>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<CancellationToken>())
            .Throws(new Exception("Memory engine is down"));

        var request = new VoiceRequest
        {
            UserId = _testUserId,
            TranscribedText = "Hello voice",
            DurationSeconds = 2.0
        };

        // Act
        var response = await _chatService.ProcessVoiceMessageAsync(request, CancellationToken.None);

        // Assert
        Assert.False(response.MemoryContextApplied);
    }
}
