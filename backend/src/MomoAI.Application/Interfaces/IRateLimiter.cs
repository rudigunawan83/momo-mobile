namespace MomoAI.Application.Interfaces;

/// <summary>
/// Provides per-user rate limiting for message processing.
/// </summary>
public interface IRateLimiter
{
    /// <summary>
    /// Checks whether a user is allowed to send a message.
    /// If allowed, records the attempt and returns a passing result.
    /// If not allowed, returns a failing result with the remaining wait time in seconds.
    /// </summary>
    /// <param name="userId">The user's identifier.</param>
    /// <returns>A RateLimitResult indicating whether the request is allowed.</returns>
    RateLimitResult CheckRateLimit(Guid userId);
}

/// <summary>
/// Result of a rate limit check.
/// </summary>
public record RateLimitResult
{
    /// <summary>
    /// Whether the request is allowed.
    /// </summary>
    public bool IsAllowed { get; init; }

    /// <summary>
    /// Seconds remaining until the user can send the next message.
    /// Only meaningful when IsAllowed is false.
    /// </summary>
    public int RetryAfterSeconds { get; init; }

    /// <summary>
    /// Number of remaining messages allowed in the current window.
    /// </summary>
    public int RemainingMessages { get; init; }

    public static RateLimitResult Allowed(int remaining) => new()
    {
        IsAllowed = true,
        RetryAfterSeconds = 0,
        RemainingMessages = remaining,
    };

    public static RateLimitResult Denied(int retryAfterSeconds) => new()
    {
        IsAllowed = false,
        RetryAfterSeconds = retryAfterSeconds,
        RemainingMessages = 0,
    };
}
