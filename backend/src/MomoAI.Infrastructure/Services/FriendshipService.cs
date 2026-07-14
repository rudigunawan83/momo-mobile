using MomoAI.Application.DTOs;
using MomoAI.Application.Interfaces;
using MomoAI.Domain.Enums;

namespace MomoAI.Infrastructure.Services;

/// <summary>
/// Implements friendship progression, XP accumulation, achievements,
/// and daily engagement mechanics.
/// </summary>
public class FriendshipService : IFriendshipService
{
    private const int BaseXP = 100;
    private const double GrowthFactor = 1.5;
    private const int DailyXPCapPerSource = 500;
    private const int DailyLoginXPAmount = 50;
    private static readonly TimeSpan StreakResetThreshold = TimeSpan.FromHours(48);

    private readonly IFriendshipRepository _repository;

    public FriendshipService(IFriendshipRepository repository)
    {
        _repository = repository ?? throw new ArgumentNullException(nameof(repository));
    }

    /// <inheritdoc />
    public async Task<FriendshipState> GetStateAsync(Guid userId, CancellationToken ct)
    {
        var entity = await _repository.GetByUserIdAsync(userId, ct);
        if (entity is null)
        {
            // New user — return default state (level 1, 0 XP)
            var defaultState = CreateDefaultState(userId);
            await _repository.SaveAsync(defaultState, ct);

            return MapToDto(defaultState, new List<string>());
        }

        var achievements = await _repository.GetUnlockedAchievementsAsync(userId, ct);
        return MapToDto(entity, achievements);
    }

    /// <inheritdoc />
    public async Task<XPResult> AddXPAsync(Guid userId, XPSource source, int amount, CancellationToken ct)
    {
        if (amount <= 0)
            throw new ArgumentException("XP amount must be positive.", nameof(amount));

        var utcNow = DateTime.UtcNow;
        var utcToday = utcNow.Date;

        // Enforce daily XP cap per source
        var dailyUsed = await _repository.GetDailyXPForSourceAsync(userId, source, utcToday, ct);
        var remainingCap = DailyXPCapPerSource - dailyUsed;

        if (remainingCap <= 0)
        {
            // Daily cap already reached for this source
            var currentEntity = await GetOrCreateStateAsync(userId, ct);
            return new XPResult
            {
                Amount = 0,
                NewTotalXP = currentEntity.TotalXP,
                NewLevel = currentEntity.Level,
                LeveledUp = false,
                DailyCapReached = true,
                Source = source
            };
        }

        // Clamp amount to remaining cap
        var effectiveAmount = Math.Min(amount, remainingCap);

        // Get or create current state
        var state = await GetOrCreateStateAsync(userId, ct);
        var previousLevel = state.Level;

        // Monotonic XP addition — never subtract
        var newTotalXP = state.TotalXP + effectiveAmount;

        // Recalculate level from new totalXP
        var levelInfo = CalculateLevelFromXP(newTotalXP);

        // Ensure level never decreases (defensive, should not happen with monotonic XP)
        var newLevel = Math.Max(levelInfo.Level, previousLevel);

        // Update state
        var updatedState = Domain.Entities.FriendshipState.Create(
            userId: userId,
            level: newLevel,
            currentXP: levelInfo.CurrentXP,
            xpToNextLevel: levelInfo.XPToNextLevel,
            totalXP: newTotalXP,
            loginStreak: state.LoginStreak,
            lastLoginDate: state.LastLoginDate,
            unlockedAchievements: state.UnlockedAchievements.ToList(),
            unlockedRooms: state.UnlockedRooms.ToList());

        await _repository.SaveAsync(updatedState, ct);

        // Record the XP transaction for daily cap tracking
        await _repository.RecordXPTransactionAsync(userId, source, effectiveAmount, utcNow, ct);

        // Check achievements after XP addition
        await CheckNewAchievementsAsync(userId, ct);

        var capReachedAfter = (dailyUsed + effectiveAmount) >= DailyXPCapPerSource;

        return new XPResult
        {
            Amount = effectiveAmount,
            NewTotalXP = newTotalXP,
            NewLevel = newLevel,
            LeveledUp = newLevel > previousLevel,
            DailyCapReached = capReachedAfter,
            Source = source
        };
    }

    /// <inheritdoc />
    public async Task<bool> ClaimDailyLoginAsync(Guid userId, CancellationToken ct)
    {
        var utcNow = DateTime.UtcNow;
        var state = await GetOrCreateStateAsync(userId, ct);

        // Check if already claimed today (same UTC calendar day)
        if (state.LastLoginDate.Date == utcNow.Date)
        {
            return false; // Already claimed today
        }

        // Determine streak: reset if gap > 48 hours
        var timeSinceLastLogin = utcNow - state.LastLoginDate;
        var newStreak = timeSinceLastLogin > StreakResetThreshold
            ? 1  // Reset streak to 1 (this login counts)
            : state.LoginStreak + 1;

        // Update state with new streak and login date
        var updatedState = Domain.Entities.FriendshipState.Create(
            userId: userId,
            level: state.Level,
            currentXP: state.CurrentXP,
            xpToNextLevel: state.XPToNextLevel,
            totalXP: state.TotalXP,
            loginStreak: newStreak,
            lastLoginDate: utcNow,
            unlockedAchievements: state.UnlockedAchievements.ToList(),
            unlockedRooms: state.UnlockedRooms.ToList());

        await _repository.SaveAsync(updatedState, ct);

        // Award XP for daily login (respects daily cap)
        await AddXPAsync(userId, XPSource.DailyLogin, DailyLoginXPAmount, ct);

        return true;
    }

    /// <inheritdoc />
    public async Task<List<Achievement>> CheckNewAchievementsAsync(Guid userId, CancellationToken ct)
    {
        var state = await GetOrCreateStateAsync(userId, ct);
        var existingAchievements = await _repository.GetUnlockedAchievementsAsync(userId, ct);
        var newAchievements = new List<Achievement>();

        var utcNow = DateTime.UtcNow;

        // Define achievement criteria and check each one
        var allAchievements = GetAchievementDefinitions();

        foreach (var definition in allAchievements)
        {
            if (existingAchievements.Contains(definition.Name))
                continue; // Already unlocked

            if (await IsAchievementCriteriaMet(definition, state, userId, ct))
            {
                var achievement = new Achievement
                {
                    Id = Guid.NewGuid(),
                    Name = definition.Name,
                    Description = definition.Description,
                    IconUrl = definition.IconUrl,
                    UnlockedAt = utcNow
                };

                await _repository.UnlockAchievementAsync(userId, definition.Name, utcNow, ct);
                newAchievements.Add(achievement);
            }
        }

        return newAchievements;
    }

    // ──────────────────────────────────────────────────────────────
    // Core Level Calculation (Pure, Deterministic)
    // ──────────────────────────────────────────────────────────────

    /// <summary>
    /// Calculates the XP required to advance from a given level.
    /// Formula: XP_needed(level) = FLOOR(100 * level^1.5)
    /// </summary>
    public static int XPRequiredForLevel(int level)
    {
        if (level < 1)
            throw new ArgumentException("Level must be >= 1.", nameof(level));

        return (int)Math.Floor(BaseXP * Math.Pow(level, GrowthFactor));
    }

    /// <summary>
    /// Deterministically calculates level, currentXP, and xpToNextLevel from totalXP.
    /// </summary>
    public static LevelInfo CalculateLevelFromXP(int totalXP)
    {
        if (totalXP < 0)
            throw new ArgumentException("TotalXP must be non-negative.", nameof(totalXP));

        var level = 1;
        var remainingXP = totalXP;

        while (remainingXP >= XPRequiredForLevel(level))
        {
            remainingXP -= XPRequiredForLevel(level);
            level++;
        }

        return new LevelInfo
        {
            Level = level,
            CurrentXP = remainingXP,
            XPToNextLevel = XPRequiredForLevel(level)
        };
    }

    // ──────────────────────────────────────────────────────────────
    // Achievement Definitions
    // ──────────────────────────────────────────────────────────────

    private static List<AchievementDefinition> GetAchievementDefinitions()
    {
        return new List<AchievementDefinition>
        {
            new("First Chat", "Send your first message to Momo", "🗨️", AchievementType.ChatCount, 1),
            new("Chatty Friend", "Have 10 conversations with Momo", "💬", AchievementType.ChatCount, 10),
            new("Social Butterfly", "Have 50 conversations with Momo", "🦋", AchievementType.ChatCount, 50),
            new("First Words", "Have your first voice conversation", "🎤", AchievementType.VoiceCount, 1),
            new("Voice Friend", "Have 10 voice conversations", "🎙️", AchievementType.VoiceCount, 10),
            new("7-Day Streak", "Log in for 7 consecutive days", "🔥", AchievementType.LoginStreak, 7),
            new("30-Day Streak", "Log in for 30 consecutive days", "⭐", AchievementType.LoginStreak, 30),
            new("Level 5", "Reach friendship level 5", "🏅", AchievementType.Level, 5),
            new("Level 10", "Reach friendship level 10", "🏆", AchievementType.Level, 10),
            new("Level 20", "Reach friendship level 20", "👑", AchievementType.Level, 20),
        };
    }

    private async Task<bool> IsAchievementCriteriaMet(
        AchievementDefinition definition,
        Domain.Entities.FriendshipState state,
        Guid userId,
        CancellationToken ct)
    {
        return definition.Type switch
        {
            AchievementType.ChatCount => await _repository.GetTotalChatCountAsync(userId, ct) >= definition.Threshold,
            AchievementType.VoiceCount => await _repository.GetTotalVoiceCountAsync(userId, ct) >= definition.Threshold,
            AchievementType.LoginStreak => state.LoginStreak >= definition.Threshold,
            AchievementType.Level => state.Level >= definition.Threshold,
            _ => false
        };
    }

    // ──────────────────────────────────────────────────────────────
    // Private Helpers
    // ──────────────────────────────────────────────────────────────

    private async Task<Domain.Entities.FriendshipState> GetOrCreateStateAsync(Guid userId, CancellationToken ct)
    {
        var entity = await _repository.GetByUserIdAsync(userId, ct);
        if (entity is not null)
            return entity;

        var defaultState = CreateDefaultState(userId);
        await _repository.SaveAsync(defaultState, ct);
        return defaultState;
    }

    private static Domain.Entities.FriendshipState CreateDefaultState(Guid userId)
    {
        var xpToNextLevel = XPRequiredForLevel(1); // 100 XP needed for level 1→2
        return Domain.Entities.FriendshipState.Create(
            userId: userId,
            level: 1,
            currentXP: 0,
            xpToNextLevel: xpToNextLevel,
            totalXP: 0,
            loginStreak: 0,
            lastLoginDate: DateTime.MinValue,
            unlockedAchievements: new List<string>(),
            unlockedRooms: new List<RoomType> { RoomType.Cozy });
    }

    private static FriendshipState MapToDto(Domain.Entities.FriendshipState entity, List<string> achievements)
    {
        return new FriendshipState
        {
            UserId = entity.UserId,
            Level = entity.Level,
            CurrentXP = entity.CurrentXP,
            XPToNextLevel = entity.XPToNextLevel,
            TotalXP = entity.TotalXP,
            LoginStreak = entity.LoginStreak,
            LastLoginDate = entity.LastLoginDate,
            UnlockedAchievements = achievements,
            UnlockedRooms = entity.UnlockedRooms.ToList()
        };
    }

    // ──────────────────────────────────────────────────────────────
    // Internal Types
    // ──────────────────────────────────────────────────────────────

    /// <summary>
    /// Result of the level calculation from total XP.
    /// </summary>
    public record LevelInfo
    {
        public int Level { get; init; }
        public int CurrentXP { get; init; }
        public int XPToNextLevel { get; init; }
    }

    private enum AchievementType
    {
        ChatCount,
        VoiceCount,
        LoginStreak,
        Level
    }

    private record AchievementDefinition(
        string Name,
        string Description,
        string IconUrl,
        AchievementType Type,
        int Threshold);
}
