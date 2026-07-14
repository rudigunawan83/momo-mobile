using System.ClientModel;
using System.Runtime.CompilerServices;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MomoAI.Application.DTOs;
using MomoAI.Application.Interfaces;
using MomoAI.Domain.Enums;
using OpenAI;
using OpenAI.Chat;

namespace MomoAI.Infrastructure.Services;

/// <summary>
/// Configuration options for the OpenAI AI Gateway.
/// </summary>
public class AIGatewayOptions
{
    public const string SectionName = "OpenAI";

    public string ApiKey { get; set; } = string.Empty;
    public string Model { get; set; } = "gpt-4o-mini";
    public int TimeoutSeconds { get; set; } = 30;
    public int MaxRetries { get; set; } = 3;
    public int InitialRetryDelayMs { get; set; } = 1000;
}

/// <summary>
/// AI Gateway implementation wrapping the OpenAI SDK.
/// Handles 30-second timeout, retry with exponential backoff (3 attempts),
/// and fallback response from personality profile on total failure.
/// </summary>
public class AIGateway : IAIGateway
{
    private readonly ChatClient _chatClient;
    private readonly AIGatewayOptions _options;
    private readonly ILogger<AIGateway> _logger;

    public AIGateway(IOptions<AIGatewayOptions> options, ILogger<AIGateway> logger)
    {
        _options = options?.Value ?? throw new ArgumentNullException(nameof(options));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));

        var openAiClient = new OpenAIClient(_options.ApiKey);
        _chatClient = openAiClient.GetChatClient(_options.Model);
    }

    /// <summary>
    /// Constructor for testing — allows injecting a pre-built ChatClient.
    /// </summary>
    internal AIGateway(ChatClient chatClient, AIGatewayOptions options, ILogger<AIGateway> logger)
    {
        _chatClient = chatClient ?? throw new ArgumentNullException(nameof(chatClient));
        _options = options ?? throw new ArgumentNullException(nameof(options));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    /// <inheritdoc />
    public async Task<AIResponse> GenerateAsync(AIRequest request, CancellationToken ct)
    {
        // Create a linked cancellation token with 30-second timeout
        using var timeoutCts = new CancellationTokenSource(TimeSpan.FromSeconds(_options.TimeoutSeconds));
        using var linkedCts = CancellationTokenSource.CreateLinkedTokenSource(ct, timeoutCts.Token);

        var attempt = 0;
        Exception? lastException = null;

        while (attempt < _options.MaxRetries)
        {
            attempt++;

            try
            {
                _logger.LogInformation(
                    "AI Gateway: Attempt {Attempt}/{MaxRetries} for message generation",
                    attempt, _options.MaxRetries);

                var result = await CallOpenAIAsync(request, linkedCts.Token);
                return result;
            }
            catch (OperationCanceledException) when (timeoutCts.IsCancellationRequested)
            {
                _logger.LogWarning("AI Gateway: Request timed out after {Timeout}s on attempt {Attempt}",
                    _options.TimeoutSeconds, attempt);
                lastException = new TimeoutException(
                    $"AI Gateway timed out after {_options.TimeoutSeconds} seconds");
                // On timeout, don't retry — return fallback immediately
                break;
            }
            catch (OperationCanceledException) when (ct.IsCancellationRequested)
            {
                // Caller cancelled — propagate immediately
                _logger.LogInformation("AI Gateway: Request cancelled by caller on attempt {Attempt}", attempt);
                throw;
            }
            catch (Exception ex)
            {
                lastException = ex;
                _logger.LogWarning(ex,
                    "AI Gateway: Attempt {Attempt}/{MaxRetries} failed",
                    attempt, _options.MaxRetries);

                if (attempt < _options.MaxRetries)
                {
                    // Exponential backoff: 1s, 2s, 4s
                    var delayMs = _options.InitialRetryDelayMs * (int)Math.Pow(2, attempt - 1);
                    _logger.LogInformation("AI Gateway: Retrying in {Delay}ms", delayMs);

                    try
                    {
                        await Task.Delay(delayMs, linkedCts.Token);
                    }
                    catch (OperationCanceledException)
                    {
                        // Timeout or caller cancellation during delay
                        if (ct.IsCancellationRequested)
                            throw;
                        break; // Timeout — fall through to fallback
                    }
                }
            }
        }

        // All retries exhausted or timeout — return fallback
        _logger.LogError(lastException,
            "AI Gateway: All {MaxRetries} attempts failed. Returning fallback response.",
            _options.MaxRetries);

        return CreateFallbackResponse();
    }

    /// <inheritdoc />
    public async IAsyncEnumerable<string> GenerateStreamingAsync(
        AIRequest request,
        [EnumeratorCancellation] CancellationToken ct)
    {
        var messages = BuildMessages(request);

        var completionOptions = new ChatCompletionOptions
        {
            Temperature = (float)request.Temperature,
            MaxOutputTokenCount = request.MaxTokens
        };

        AsyncCollectionResult<StreamingChatCompletionUpdate>? streamingResult = null;
        bool useFallback = false;

        try
        {
            streamingResult = _chatClient.CompleteChatStreamingAsync(
                messages, completionOptions, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "AI Gateway: Failed to initiate streaming request");
            useFallback = true;
        }

        if (useFallback)
        {
            // Fallback: yield the full non-streaming response as a single chunk
            var fallbackResponse = await GenerateAsync(request, ct);
            yield return fallbackResponse.Text;
            yield break;
        }

        await foreach (var update in streamingResult!.WithCancellation(ct))
        {
            foreach (var contentPart in update.ContentUpdate)
            {
                if (!string.IsNullOrEmpty(contentPart.Text))
                {
                    yield return contentPart.Text;
                }
            }
        }
    }

    private async Task<AIResponse> CallOpenAIAsync(AIRequest request, CancellationToken ct)
    {
        var messages = BuildMessages(request);

        var completionOptions = new ChatCompletionOptions
        {
            Temperature = (float)request.Temperature,
            MaxOutputTokenCount = request.MaxTokens
        };

        ClientResult<ChatCompletion> response = await _chatClient.CompleteChatAsync(
            messages, completionOptions, ct);

        var completion = response.Value;
        var responseText = completion.Content[0].Text ?? string.Empty;

        return new AIResponse
        {
            Text = responseText,
            DetectedEmotion = DetectEmotionFromText(responseText),
            TokensUsed = completion.Usage?.TotalTokenCount ?? 0,
            SentimentScore = EstimateSentiment(responseText),
            IsFallback = false
        };
    }

    private static List<ChatMessage> BuildMessages(AIRequest request)
    {
        var messages = new List<ChatMessage>();

        // System prompt
        if (!string.IsNullOrWhiteSpace(request.SystemPrompt))
        {
            messages.Add(new SystemChatMessage(request.SystemPrompt));
        }

        // Context as a system-level addition
        if (request.Context.Count > 0)
        {
            var contextText = "Relevant context from memory:\n" +
                              string.Join("\n- ", request.Context);
            messages.Add(new SystemChatMessage(contextText));
        }

        // Recent conversation history
        foreach (var msg in request.RecentHistory)
        {
            messages.Add(msg.Role switch
            {
                MessageRole.User => new UserChatMessage(msg.Content),
                MessageRole.Assistant => new AssistantChatMessage(msg.Content),
                _ => new SystemChatMessage(msg.Content)
            });
        }

        // Current user message
        messages.Add(new UserChatMessage(request.UserMessage));

        return messages;
    }

    /// <summary>
    /// Creates a fallback response when all retry attempts are exhausted or timeout occurs.
    /// Sets emotion to Confused as per requirement 10.1.
    /// </summary>
    private static AIResponse CreateFallbackResponse()
    {
        return new AIResponse
        {
            Text = "Hmm, aku sedang mikir... coba lagi ya!",
            DetectedEmotion = EmotionType.Confused,
            TokensUsed = 0,
            SentimentScore = 0.0,
            IsFallback = true
        };
    }

    /// <summary>
    /// Simple emotion detection from response text using keyword heuristics.
    /// In production, this would use the AI model's sentiment analysis.
    /// </summary>
    private static EmotionType DetectEmotionFromText(string text)
    {
        if (string.IsNullOrWhiteSpace(text))
            return EmotionType.Neutral;

        var lower = text.ToLowerInvariant();

        if (ContainsAny(lower, "haha", "lucu", "😂", "😄", "wkwk", "lol"))
            return EmotionType.Happy;
        if (ContainsAny(lower, "sedih", "maaf", "😢", "😔"))
            return EmotionType.Sad;
        if (ContainsAny(lower, "menarik", "kenapa", "bagaimana", "🤔", "hmm"))
            return EmotionType.Curious;
        if (ContainsAny(lower, "wow", "keren", "amazing", "🎉", "🤩"))
            return EmotionType.Excited;
        if (ContainsAny(lower, "malu", "😳", "blush"))
            return EmotionType.Shy;
        if (ContainsAny(lower, "tenang", "santai", "😌"))
            return EmotionType.Neutral;

        return EmotionType.Happy;
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
    /// Simple sentiment estimation from text.
    /// Returns a value between -1.0 and 1.0.
    /// </summary>
    private static double EstimateSentiment(string text)
    {
        if (string.IsNullOrWhiteSpace(text))
            return 0.0;

        var lower = text.ToLowerInvariant();

        var positiveCount = CountOccurrences(lower, "senang", "bagus", "keren", "suka", "asyik", "hebat", "baik");
        var negativeCount = CountOccurrences(lower, "sedih", "marah", "buruk", "susah", "kesal", "gagal", "salah");

        var total = positiveCount + negativeCount;
        if (total == 0) return 0.1; // Slightly positive default

        return Math.Clamp((positiveCount - negativeCount) / (double)total, -1.0, 1.0);
    }

    private static int CountOccurrences(string text, params string[] words)
    {
        var count = 0;
        foreach (var word in words)
        {
            if (text.Contains(word, StringComparison.Ordinal))
                count++;
        }
        return count;
    }
}
