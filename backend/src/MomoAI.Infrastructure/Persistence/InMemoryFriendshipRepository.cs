using System.Collections.Concurrent;
using MomoAI.Application.Interfaces;
using MomoAI.Domain.Enums;

namespace MomoAI.Infrastructure.Persistence;

/// <summary>
/// In-memory implementation of IFriendshipRepository for development without a database.
/// </summary>
public class InMemoryFriendshipRepository : IFriendshipRepository
{
    private readonly ConcurrentDictionary<Guid, Domain.Entities.FriendshipState> _states = new();
    private readonly ConcurrentDictionary<string, int> _dailyXP = new();
    private readonly ConcurrentDictionary<Guid, List<string>> _achievements = new();
    private readonly ConcurrentDictionary<Guid, int> _chatCounts = new();
    private readonly ConcurrentDictionary<Guid, int> _voiceCounts = new();

    public Task<Domain.Entities.FriendshipState?> GetByUserIdAsync(Guid userId, CancellationToken ct)
    {
        _states.TryGetValue(userId, out var state);
        return Task.FromResult(state);
    }

    public Task SaveAsync(Domain.Entities.FriendshipState state, CancellationToken ct)
    {
        _states[state.UserId] = state;
        return Task.CompletedTask;
    }

    public Task<int> GetDailyXPForSourceAsync(Guid userId, XPSource source, DateTime utcDate, CancellationToken ct)
    {
        var key = $"{userId}:{source}:{utcDate:yyyy-MM-dd}";
        _dailyXP.TryGetValue(key, out var total);
        return Task.FromResult(total);
    }

    public Task RecordXPTransactionAsync(Guid userId, XPSource source, int amount, DateTime utcTimestamp, CancellationToken ct)
    {
        var key = $"{userId}:{source}:{utcTimestamp:yyyy-MM-dd}";
        _dailyXP.AddOrUpdate(key, amount, (_, existing) => existing + amount);

        // Track counts for achievements
        if (source == XPSource.Chat)
            _chatCounts.AddOrUpdate(userId, 1, (_, c) => c + 1);
        else if (source == XPSource.Voice)
            _voiceCounts.AddOrUpdate(userId, 1, (_, c) => c + 1);

        return Task.CompletedTask;
    }

    public Task<List<string>> GetUnlockedAchievementsAsync(Guid userId, CancellationToken ct)
    {
        _achievements.TryGetValue(userId, out var achievements);
        return Task.FromResult(achievements ?? new List<string>());
    }

    public Task UnlockAchievementAsync(Guid userId, string achievementName, DateTime unlockedAt, CancellationToken ct)
    {
        var userAchievements = _achievements.GetOrAdd(userId, _ => new List<string>());
        lock (userAchievements)
        {
            if (!userAchievements.Contains(achievementName))
                userAchievements.Add(achievementName);
        }
        return Task.CompletedTask;
    }

    public Task<int> GetTotalChatCountAsync(Guid userId, CancellationToken ct)
    {
        _chatCounts.TryGetValue(userId, out var count);
        return Task.FromResult(count);
    }

    public Task<int> GetTotalVoiceCountAsync(Guid userId, CancellationToken ct)
    {
        _voiceCounts.TryGetValue(userId, out var count);
        return Task.FromResult(count);
    }
}
