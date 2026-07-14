using System.Collections.Concurrent;
using MomoAI.Application.Interfaces;

namespace MomoAI.Infrastructure.Services;

/// <summary>
/// In-memory sliding window rate limiter that enforces 60 messages per minute per user.
/// Uses a concurrent dictionary of timestamp queues for thread safety.
/// </summary>
public class InMemoryRateLimiter : IRateLimiter
{
    private const int MaxMessagesPerMinute = 60;
    private static readonly TimeSpan Window = TimeSpan.FromMinutes(1);

    private readonly ConcurrentDictionary<Guid, ConcurrentQueue<DateTime>> _userRequests = new();
    private readonly TimeProvider _timeProvider;

    public InMemoryRateLimiter(TimeProvider timeProvider)
    {
        _timeProvider = timeProvider ?? throw new ArgumentNullException(nameof(timeProvider));
    }

    /// <summary>
    /// Checks whether a user is within rate limits. If allowed, records the request.
    /// If denied, returns the number of seconds until the oldest request in the window expires.
    /// </summary>
    public RateLimitResult CheckRateLimit(Guid userId)
    {
        var now = _timeProvider.GetUtcNow().UtcDateTime;
        var windowStart = now - Window;

        var queue = _userRequests.GetOrAdd(userId, _ => new ConcurrentQueue<DateTime>());

        // Evict expired entries outside the sliding window
        while (queue.TryPeek(out var oldest) && oldest < windowStart)
        {
            queue.TryDequeue(out _);
        }

        // Check count after eviction
        if (queue.Count >= MaxMessagesPerMinute)
        {
            // Calculate seconds until the oldest request falls out of the window
            if (queue.TryPeek(out var oldestTimestamp))
            {
                var expiresAt = oldestTimestamp + Window;
                var waitSeconds = (int)Math.Ceiling((expiresAt - now).TotalSeconds);
                return RateLimitResult.Denied(Math.Max(1, waitSeconds));
            }

            // Fallback: should not happen, but return 60s max wait
            return RateLimitResult.Denied(60);
        }

        // Allow the request and record the timestamp
        queue.Enqueue(now);
        var remaining = MaxMessagesPerMinute - queue.Count;
        return RateLimitResult.Allowed(remaining);
    }
}
