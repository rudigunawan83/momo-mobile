using MomoAI.Domain.Enums;

namespace MomoAI.Application.Exceptions;

/// <summary>
/// Exception thrown when a user exceeds the message rate limit (60 messages/minute).
/// Carries the remaining wait time and the emotion to set on the character.
/// </summary>
public class RateLimitExceededException : Exception
{
    /// <summary>
    /// Seconds remaining until the user can send the next message.
    /// </summary>
    public int RetryAfterSeconds { get; }

    /// <summary>
    /// The emotion to display on the character when rate limited.
    /// Per requirement 10.6, this is "Sleepy".
    /// </summary>
    public EmotionType Emotion { get; }

    public RateLimitExceededException(int retryAfterSeconds)
        : base($"Rate limit exceeded. Please wait {retryAfterSeconds} seconds before sending another message.")
    {
        RetryAfterSeconds = retryAfterSeconds;
        Emotion = EmotionType.Sleepy;
    }

    public RateLimitExceededException(int retryAfterSeconds, string message)
        : base(message)
    {
        RetryAfterSeconds = retryAfterSeconds;
        Emotion = EmotionType.Sleepy;
    }
}
