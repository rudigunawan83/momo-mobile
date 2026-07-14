using Microsoft.Extensions.Time.Testing;
using MomoAI.Application.Interfaces;
using MomoAI.Infrastructure.Services;

namespace MomoAI.Infrastructure.Tests;

public class InMemoryRateLimiterTests
{
    private readonly FakeTimeProvider _timeProvider;
    private readonly InMemoryRateLimiter _rateLimiter;
    private readonly Guid _userId = Guid.NewGuid();

    public InMemoryRateLimiterTests()
    {
        _timeProvider = new FakeTimeProvider(DateTimeOffset.UtcNow);
        _rateLimiter = new InMemoryRateLimiter(_timeProvider);
    }

    [Fact]
    public void CheckRateLimit_FirstMessage_IsAllowed()
    {
        var result = _rateLimiter.CheckRateLimit(_userId);

        Assert.True(result.IsAllowed);
        Assert.Equal(59, result.RemainingMessages);
        Assert.Equal(0, result.RetryAfterSeconds);
    }

    [Fact]
    public void CheckRateLimit_Under60Messages_AllAllowed()
    {
        for (int i = 0; i < 59; i++)
        {
            var result = _rateLimiter.CheckRateLimit(_userId);
            Assert.True(result.IsAllowed);
        }

        // 60th message should still be allowed
        var lastResult = _rateLimiter.CheckRateLimit(_userId);
        Assert.True(lastResult.IsAllowed);
        Assert.Equal(0, lastResult.RemainingMessages);
    }

    [Fact]
    public void CheckRateLimit_61stMessage_IsDenied()
    {
        // Send 60 messages (all allowed)
        for (int i = 0; i < 60; i++)
        {
            var result = _rateLimiter.CheckRateLimit(_userId);
            Assert.True(result.IsAllowed);
        }

        // 61st message should be denied
        var deniedResult = _rateLimiter.CheckRateLimit(_userId);
        Assert.False(deniedResult.IsAllowed);
        Assert.True(deniedResult.RetryAfterSeconds > 0);
        Assert.True(deniedResult.RetryAfterSeconds <= 60);
        Assert.Equal(0, deniedResult.RemainingMessages);
    }

    [Fact]
    public void CheckRateLimit_AfterWindowExpires_AllowsAgain()
    {
        // Send 60 messages
        for (int i = 0; i < 60; i++)
        {
            _rateLimiter.CheckRateLimit(_userId);
        }

        // Verify denied
        var deniedResult = _rateLimiter.CheckRateLimit(_userId);
        Assert.False(deniedResult.IsAllowed);

        // Advance time past the 1-minute window
        _timeProvider.Advance(TimeSpan.FromSeconds(61));

        // Should be allowed again
        var allowedResult = _rateLimiter.CheckRateLimit(_userId);
        Assert.True(allowedResult.IsAllowed);
    }

    [Fact]
    public void CheckRateLimit_SlidingWindow_GradualExpiry()
    {
        // Send 30 messages at t=0
        for (int i = 0; i < 30; i++)
        {
            _rateLimiter.CheckRateLimit(_userId);
        }

        // Advance 30 seconds
        _timeProvider.Advance(TimeSpan.FromSeconds(30));

        // Send 30 more messages at t=30s
        for (int i = 0; i < 30; i++)
        {
            _rateLimiter.CheckRateLimit(_userId);
        }

        // Now at 60 messages in window, next should be denied
        var deniedResult = _rateLimiter.CheckRateLimit(_userId);
        Assert.False(deniedResult.IsAllowed);

        // Advance to t=61s (first 30 messages expire)
        _timeProvider.Advance(TimeSpan.FromSeconds(31));

        // Should be allowed now (only 30 messages in the last minute)
        var allowedResult = _rateLimiter.CheckRateLimit(_userId);
        Assert.True(allowedResult.IsAllowed);
    }

    [Fact]
    public void CheckRateLimit_DifferentUsers_IndependentLimits()
    {
        var userA = Guid.NewGuid();
        var userB = Guid.NewGuid();

        // Fill up userA's limit
        for (int i = 0; i < 60; i++)
        {
            _rateLimiter.CheckRateLimit(userA);
        }

        // UserA is denied
        var userAResult = _rateLimiter.CheckRateLimit(userA);
        Assert.False(userAResult.IsAllowed);

        // UserB should still be allowed
        var userBResult = _rateLimiter.CheckRateLimit(userB);
        Assert.True(userBResult.IsAllowed);
    }

    [Fact]
    public void CheckRateLimit_RetryAfterSeconds_IsPositive()
    {
        // Fill up the limit
        for (int i = 0; i < 60; i++)
        {
            _rateLimiter.CheckRateLimit(_userId);
        }

        var result = _rateLimiter.CheckRateLimit(_userId);
        Assert.False(result.IsAllowed);
        Assert.True(result.RetryAfterSeconds >= 1);
    }

    [Fact]
    public void CheckRateLimit_RetryAfterSeconds_ReflectsRemainingWaitTime()
    {
        // Send 60 messages at t=0
        for (int i = 0; i < 60; i++)
        {
            _rateLimiter.CheckRateLimit(_userId);
        }

        // Advance 45 seconds (15 seconds remaining in window for the first batch)
        _timeProvider.Advance(TimeSpan.FromSeconds(45));

        var result = _rateLimiter.CheckRateLimit(_userId);
        Assert.False(result.IsAllowed);
        // The oldest message was at t=0, window is 60s, so it expires at t=60
        // Current time is t=45, so wait = 60-45 = 15 seconds
        Assert.Equal(15, result.RetryAfterSeconds);
    }

    [Fact]
    public void CheckRateLimit_RemainingMessages_DecreasesCorrectly()
    {
        var first = _rateLimiter.CheckRateLimit(_userId);
        Assert.Equal(59, first.RemainingMessages);

        var second = _rateLimiter.CheckRateLimit(_userId);
        Assert.Equal(58, second.RemainingMessages);

        var third = _rateLimiter.CheckRateLimit(_userId);
        Assert.Equal(57, third.RemainingMessages);
    }
}
