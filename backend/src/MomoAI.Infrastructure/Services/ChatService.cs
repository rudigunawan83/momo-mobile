using Microsoft.Extensions.Logging;
using MomoAI.Application.DTOs;
using MomoAI.Application.Exceptions;
using MomoAI.Application.Interfaces;
using MomoAI.Domain.Enums;

namespace MomoAI.Infrastructure.Services;

/// <summary>
/// Orchestrates the AI conversation flow: validation, context retrieval,
/// response generation, memory storage, and XP award.
/// </summary>
public class ChatService : IChatService
{
    private const int MaxMessageLength = 4000;
    private const int MaxMemoryResults = 5;
    private const int RecentMessageLimit = 10;
    private const int ChatXPAmount = 10;
    private const double MinVoiceDurationSeconds = 0.5;
    private const double MaxVoiceDurationSeconds = 60.0;
    private static readonly TimeSpan FutureTimeTolerance = TimeSpan.FromSeconds(5);

    private const string BaseSystemPrompt = @"You are Momo, an AI companion who is warm, caring, and has a unique personality. 
You remember past conversations and respond in a personalized way. 
You are not just a chatbot — you are a friend who grows with the user over time.";

    private readonly IAIGateway _aiGateway;
    private readonly IMemoryEngine _memoryEngine;
    private readonly IPersonalityEngine _personalityEngine;
    private readonly IFriendshipService _friendshipService;
    private readonly IChatMessageRepository _chatMessageRepository;
    private readonly IPromptInjectionDetector _promptInjectionDetector;
    private readonly IContentFilter _contentFilter;
    private readonly IRateLimiter _rateLimiter;
    private readonly ILogger<ChatService> _logger;

    private const string SafeReplacementResponse = "Maaf, aku nggak bisa jawab itu. Yuk kita ngobrol yang lain aja!";
    private const string InjectionRefusalResponse = "Maaf, pesanmu nggak bisa diproses. Coba kirim yang lain ya!";

    public ChatService(
        IAIGateway aiGateway,
        IMemoryEngine memoryEngine,
        IPersonalityEngine personalityEngine,
        IFriendshipService friendshipService,
        IChatMessageRepository chatMessageRepository,
        IPromptInjectionDetector promptInjectionDetector,
        IContentFilter contentFilter,
        IRateLimiter rateLimiter,
        ILogger<ChatService> logger)
    {
        _aiGateway = aiGateway ?? throw new ArgumentNullException(nameof(aiGateway));
        _memoryEngine = memoryEngine ?? throw new ArgumentNullException(nameof(memoryEngine));
        _personalityEngine = personalityEngine ?? throw new ArgumentNullException(nameof(personalityEngine));
        _friendshipService = friendshipService ?? throw new ArgumentNullException(nameof(friendshipService));
        _chatMessageRepository = chatMessageRepository ?? throw new ArgumentNullException(nameof(chatMessageRepository));
        _promptInjectionDetector = promptInjectionDetector ?? throw new ArgumentNullException(nameof(promptInjectionDetector));
        _contentFilter = contentFilter ?? throw new ArgumentNullException(nameof(contentFilter));
        _rateLimiter = rateLimiter ?? throw new ArgumentNullException(nameof(rateLimiter));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc />
    public async Task<ChatResponse> ProcessMessageAsync(ChatRequest request, CancellationToken ct)
    {
        // Step 1: Validate input
        ValidateMessage(request.Message);
        ValidateTimestamp(request.CreatedAt);

        // Step 1.1: Check rate limit (60 messages/minute per user)
        var rateLimitResult = _rateLimiter.CheckRateLimit(request.UserId);
        if (!rateLimitResult.IsAllowed)
        {
            _logger.LogWarning(
                "Rate limit exceeded for user {UserId}. Retry after {RetryAfterSeconds}s.",
                request.UserId, rateLimitResult.RetryAfterSeconds);

            throw new RateLimitExceededException(rateLimitResult.RetryAfterSeconds);
        }

        // Step 1.5: Check for prompt injection before any AI processing
        var injectionResult = _promptInjectionDetector.Detect(request.Message);
        if (injectionResult.IsInjectionDetected)
        {
            _logger.LogWarning(
                "Prompt injection detected for user {UserId}. Category: {Category}",
                request.UserId, injectionResult.Category);

            // Return generic refusal without revealing detection logic
            return new ChatResponse
            {
                Message = InjectionRefusalResponse,
                Emotion = Domain.Enums.EmotionType.Neutral,
                XpGained = 0,
                LevelUp = false,
                NewAchievements = new List<string>(),
                MemoryContextApplied = false,
            };
        }

        // Step 2: Get personality profile
        var personality = _personalityEngine.GetProfile(request.UserId);

        // Step 3: Retrieve relevant memories (up to 5)
        List<Memory> memories;
        bool memoryContextAvailable = true;
        try
        {
            memories = await _memoryEngine.GetRelevantMemoriesAsync(
                request.UserId, request.Message, MaxMemoryResults, ct);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Memory Engine unavailable for user {UserId}. Proceeding without memory context.", request.UserId);
            memories = new List<Memory>();
            memoryContextAvailable = false;
        }

        // Step 4: Get recent messages (up to 10)
        var recentMessages = await _chatMessageRepository.GetRecentMessagesAsync(
            request.UserId, RecentMessageLimit, ct);

        // Step 5: Apply personality to system prompt
        var systemPrompt = _personalityEngine.ApplyPersonalityToPrompt(BaseSystemPrompt, personality);

        // Step 6: Call AI Gateway with context
        AIResponse aiResult;
        try
        {
            aiResult = await _aiGateway.GenerateAsync(new AIRequest
            {
                SystemPrompt = systemPrompt,
                UserMessage = request.Message,
                Context = memories.Select(m => m.Summary).ToList(),
                RecentHistory = recentMessages,
            }, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "AI Gateway unavailable for user {UserId}. Returning error response.", request.UserId);
            // AI Gateway unavailable: return error, do NOT store memory or award XP
            throw new InvalidOperationException("AI service is temporarily unavailable. Please try again later.", ex);
        }

        // Step 7: Extract emotion from AI response
        var emotion = aiResult.DetectedEmotion;

        // Step 7.5: Filter AI response content
        var filterResult = _contentFilter.Filter(aiResult.Text);
        if (filterResult.IsBlocked)
        {
            _logger.LogWarning(
                "AI response content blocked for user {UserId}. Violations: {Violations}",
                request.UserId,
                string.Join(", ", filterResult.ViolationCategories));

            // Discard blocked response and generate safe replacement
            aiResult = aiResult with
            {
                Text = SafeReplacementResponse,
                DetectedEmotion = Domain.Enums.EmotionType.Neutral,
                SentimentScore = 0.0
            };
            emotion = Domain.Enums.EmotionType.Neutral;
        }

        // Step 8: Store conversation as memory (exactly 1 entry)
        var userSummary = Truncate(request.Message, 100);
        var momoSummary = Truncate(aiResult.Text, 100);

        await _memoryEngine.StoreMemoryAsync(request.UserId, new MemoryInput
        {
            Summary = $"User: {userSummary} | Momo: {momoSummary}",
            Content = aiResult.Text,
            Type = MemoryType.Conversation,
            ImportanceScore = 0.5,
        }, ct);

        // Step 9: Award 10 XP via FriendshipService
        var xpResult = await _friendshipService.AddXPAsync(
            request.UserId, XPSource.Chat, ChatXPAmount, ct);

        // Store user message and assistant response for history
        var now = DateTime.UtcNow;
        await _chatMessageRepository.SaveMessageAsync(new ChatMessageDto
        {
            Id = Guid.NewGuid(),
            Role = MessageRole.User,
            Content = request.Message,
            Type = MessageType.Text,
            Emotion = null,
            CreatedAt = now,
        }, ct);

        await _chatMessageRepository.SaveMessageAsync(new ChatMessageDto
        {
            Id = Guid.NewGuid(),
            Role = MessageRole.Assistant,
            Content = aiResult.Text,
            Type = MessageType.Text,
            Emotion = emotion,
            CreatedAt = now,
        }, ct);

        // Build response with metadata
        var response = new ChatResponse
        {
            Message = aiResult.Text,
            Emotion = emotion,
            XpGained = xpResult.Amount,
            LevelUp = xpResult.LeveledUp,
            NewAchievements = new List<string>(),
            MemoryContextApplied = memoryContextAvailable,
        };

        // Check for new achievements
        var newAchievements = await _friendshipService.CheckNewAchievementsAsync(request.UserId, ct);
        if (newAchievements.Any())
        {
            response = response with
            {
                NewAchievements = newAchievements.Select(a => a.Name).ToList()
            };
        }

        return response;
    }

    /// <inheritdoc />
    public async Task<ChatResponse> ProcessVoiceMessageAsync(VoiceRequest request, CancellationToken ct)
    {
        // Validate transcribed text (same rules as text messages)
        ValidateMessage(request.TranscribedText);

        // Validate recording duration (0.5s minimum, 60s maximum)
        ValidateVoiceDuration(request.DurationSeconds);

        // Check rate limit (60 messages/minute per user)
        var rateLimitResult = _rateLimiter.CheckRateLimit(request.UserId);
        if (!rateLimitResult.IsAllowed)
        {
            _logger.LogWarning(
                "Rate limit exceeded for voice message from user {UserId}. Retry after {RetryAfterSeconds}s.",
                request.UserId, rateLimitResult.RetryAfterSeconds);

            throw new RateLimitExceededException(rateLimitResult.RetryAfterSeconds);
        }

        // Route through the same AI pipeline as text messages
        // by creating a ChatRequest from the voice transcription
        var chatRequest = new ChatRequest
        {
            UserId = request.UserId,
            Message = request.TranscribedText,
            ConversationType = ConversationType.Voice,
        };

        // Step 1: Get personality profile
        var personality = _personalityEngine.GetProfile(request.UserId);

        // Step 2: Retrieve relevant memories (up to 5)
        List<Memory> memories;
        bool memoryContextAvailable = true;
        try
        {
            memories = await _memoryEngine.GetRelevantMemoriesAsync(
                request.UserId, request.TranscribedText, MaxMemoryResults, ct);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Memory Engine unavailable for voice message from user {UserId}. Proceeding without memory context.", request.UserId);
            memories = new List<Memory>();
            memoryContextAvailable = false;
        }

        // Step 3: Get recent messages (up to 10)
        var recentMessages = await _chatMessageRepository.GetRecentMessagesAsync(
            request.UserId, RecentMessageLimit, ct);

        // Step 4: Apply personality to system prompt
        var systemPrompt = _personalityEngine.ApplyPersonalityToPrompt(BaseSystemPrompt, personality);

        // Step 5: Call AI Gateway with context
        AIResponse aiResult;
        try
        {
            aiResult = await _aiGateway.GenerateAsync(new AIRequest
            {
                SystemPrompt = systemPrompt,
                UserMessage = request.TranscribedText,
                Context = memories.Select(m => m.Summary).ToList(),
                RecentHistory = recentMessages,
            }, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "AI Gateway unavailable for voice message from user {UserId}.", request.UserId);
            throw new InvalidOperationException("AI service is temporarily unavailable. Please try again later.", ex);
        }

        // Step 6: Extract emotion
        var emotion = aiResult.DetectedEmotion;

        // Step 7: Store conversation as memory
        var userSummary = Truncate(request.TranscribedText, 100);
        var momoSummary = Truncate(aiResult.Text, 100);

        await _memoryEngine.StoreMemoryAsync(request.UserId, new MemoryInput
        {
            Summary = $"User (voice): {userSummary} | Momo: {momoSummary}",
            Content = aiResult.Text,
            Type = MemoryType.Conversation,
            ImportanceScore = 0.5,
        }, ct);

        // Step 8: Award XP (Voice source)
        var xpResult = await _friendshipService.AddXPAsync(
            request.UserId, XPSource.Voice, ChatXPAmount, ct);

        // Step 9: Store messages for history
        var now = DateTime.UtcNow;
        await _chatMessageRepository.SaveMessageAsync(new ChatMessageDto
        {
            Id = Guid.NewGuid(),
            Role = MessageRole.User,
            Content = request.TranscribedText,
            Type = MessageType.Voice,
            Emotion = null,
            CreatedAt = now,
        }, ct);

        await _chatMessageRepository.SaveMessageAsync(new ChatMessageDto
        {
            Id = Guid.NewGuid(),
            Role = MessageRole.Assistant,
            Content = aiResult.Text,
            Type = MessageType.Text,
            Emotion = emotion,
            CreatedAt = now,
        }, ct);

        // Step 10: Build response
        var response = new ChatResponse
        {
            Message = aiResult.Text,
            Emotion = emotion,
            XpGained = xpResult.Amount,
            LevelUp = xpResult.LeveledUp,
            NewAchievements = new List<string>(),
            MemoryContextApplied = memoryContextAvailable,
        };

        // Check for new achievements
        var newAchievements = await _friendshipService.CheckNewAchievementsAsync(request.UserId, ct);
        if (newAchievements.Any())
        {
            response = response with
            {
                NewAchievements = newAchievements.Select(a => a.Name).ToList()
            };
        }

        return response;
    }

    /// <inheritdoc />
    public async Task<ConversationHistory> GetHistoryAsync(Guid userId, int page, int pageSize, CancellationToken ct)
    {
        return await _chatMessageRepository.GetHistoryAsync(userId, page, pageSize, ct);
    }

    /// <summary>
    /// Validates message content: rejects empty/whitespace and messages exceeding 4000 characters.
    /// </summary>
    private static void ValidateMessage(string message)
    {
        if (string.IsNullOrWhiteSpace(message))
        {
            throw new ArgumentException("Message content is required. Empty or whitespace-only messages are not allowed.", nameof(message));
        }

        if (message.Length > MaxMessageLength)
        {
            throw new ArgumentException(
                $"Message content must not exceed {MaxMessageLength} characters. Actual: {message.Length}.",
                nameof(message));
        }
    }

    /// <summary>
    /// Validates voice recording duration: minimum 0.5 seconds, maximum 60 seconds.
    /// </summary>
    private static void ValidateVoiceDuration(double durationSeconds)
    {
        if (durationSeconds < MinVoiceDurationSeconds)
        {
            throw new ArgumentException(
                $"Voice recording must be at least {MinVoiceDurationSeconds} seconds. Actual: {durationSeconds:F1}s.",
                nameof(durationSeconds));
        }

        if (durationSeconds > MaxVoiceDurationSeconds)
        {
            throw new ArgumentException(
                $"Voice recording must not exceed {MaxVoiceDurationSeconds} seconds. Actual: {durationSeconds:F1}s.",
                nameof(durationSeconds));
        }
    }

    /// <summary>
    /// Validates that the provided timestamp is not in the future (more than 5 seconds ahead of server time).
    /// If no timestamp is provided (null), validation passes as server time is used.
    /// </summary>
    private static void ValidateTimestamp(DateTime? timestamp)
    {
        if (timestamp is null)
            return;

        if (timestamp.Value > DateTime.UtcNow.Add(FutureTimeTolerance))
        {
            throw new ArgumentException(
                "Message timestamp must not be in the future (more than 5 seconds ahead of server time).",
                nameof(timestamp));
        }
    }

    /// <summary>
    /// Truncates a string to the specified max length, appending "..." if truncated.
    /// </summary>
    private static string Truncate(string value, int maxLength)
    {
        if (string.IsNullOrEmpty(value))
            return string.Empty;

        return value.Length <= maxLength
            ? value
            : value[..maxLength] + "...";
    }
}
