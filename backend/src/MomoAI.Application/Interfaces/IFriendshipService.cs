using MomoAI.Application.DTOs;
using MomoAI.Domain.Enums;

namespace MomoAI.Application.Interfaces;

/// <summary>
/// Tracks friendship progression, XP accumulation, achievements,
/// and daily engagement mechanics.
/// </summary>
public interface IFriendshipService
{
    /// <summary>
    /// Gets the current friendship state for a user, including level, XP, streak, and achievements.
    /// </summary>
    /// <param name="userId">The user's identifier.</param>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>The current friendship state.</returns>
    Task<FriendshipState> GetStateAsync(Guid userId, CancellationToken ct);

    /// <summary>
    /// Adds XP to a user's friendship state. Enforces daily cap of 500 XP per source.
    /// Recalculates level using formula: XP_needed(level) = FLOOR(100 * level^1.5).
    /// TotalXP is monotonically non-decreasing and level never decreases.
    /// </summary>
    /// <param name="userId">The user's identifier.</param>
    /// <param name="source">The source of XP (Chat, Voice, DailyLogin).</param>
    /// <param name="amount">The amount of XP to add (positive integer).</param>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>Result containing new totals and whether a level-up occurred.</returns>
    Task<XPResult> AddXPAsync(Guid userId, XPSource source, int amount, CancellationToken ct);

    /// <summary>
    /// Claims daily login reward: awards XP and increments login streak.
    /// Resets streak to 0 if more than 48 hours since last login claim.
    /// </summary>
    /// <param name="userId">The user's identifier.</param>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>True if daily login was successfully claimed; false if already claimed today.</returns>
    Task<bool> ClaimDailyLoginAsync(Guid userId, CancellationToken ct);

    /// <summary>
    /// Checks and unlocks any new achievements based on current user state.
    /// Called after XP additions to detect newly met criteria.
    /// </summary>
    /// <param name="userId">The user's identifier.</param>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>List of newly unlocked achievements (empty if none).</returns>
    Task<List<Achievement>> CheckNewAchievementsAsync(Guid userId, CancellationToken ct);
}
