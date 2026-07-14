using MomoAI.Domain.Enums;

namespace MomoAI.Application.Interfaces;

/// <summary>
/// Repository interface for friendship state and daily XP tracking persistence.
/// </summary>
public interface IFriendshipRepository
{
    /// <summary>
    /// Retrieves the friendship state entity for a user.
    /// Returns null if no state exists (new user).
    /// </summary>
    Task<Domain.Entities.FriendshipState?> GetByUserIdAsync(Guid userId, CancellationToken ct);

    /// <summary>
    /// Saves or updates the friendship state for a user.
    /// </summary>
    Task SaveAsync(Domain.Entities.FriendshipState state, CancellationToken ct);

    /// <summary>
    /// Gets the total XP earned from a specific source on a given UTC date.
    /// Used to enforce the daily 500 XP cap per source.
    /// </summary>
    Task<int> GetDailyXPForSourceAsync(Guid userId, XPSource source, DateTime utcDate, CancellationToken ct);

    /// <summary>
    /// Records an XP transaction for daily tracking purposes.
    /// </summary>
    Task RecordXPTransactionAsync(Guid userId, XPSource source, int amount, DateTime utcTimestamp, CancellationToken ct);

    /// <summary>
    /// Gets the list of unlocked achievement names for a user.
    /// </summary>
    Task<List<string>> GetUnlockedAchievementsAsync(Guid userId, CancellationToken ct);

    /// <summary>
    /// Records a newly unlocked achievement for a user.
    /// </summary>
    Task UnlockAchievementAsync(Guid userId, string achievementName, DateTime unlockedAt, CancellationToken ct);

    /// <summary>
    /// Gets the total number of chat messages sent by a user (for achievement tracking).
    /// </summary>
    Task<int> GetTotalChatCountAsync(Guid userId, CancellationToken ct);

    /// <summary>
    /// Gets the total number of voice interactions for a user (for achievement tracking).
    /// </summary>
    Task<int> GetTotalVoiceCountAsync(Guid userId, CancellationToken ct);
}
