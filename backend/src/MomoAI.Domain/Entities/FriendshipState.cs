namespace MomoAI.Domain.Entities;

using MomoAI.Domain.Enums;

/// <summary>
/// Represents the friendship progression state between a user and Momo.
/// </summary>
public record FriendshipState
{
    public Guid UserId { get; init; }
    public int Level { get; init; }
    public int CurrentXP { get; init; }
    public int XPToNextLevel { get; init; }
    public int TotalXP { get; init; }
    public int LoginStreak { get; init; }
    public DateTime LastLoginDate { get; init; }
    public List<string> UnlockedAchievements { get; init; } = new();
    public List<RoomType> UnlockedRooms { get; init; } = new();

    private FriendshipState() { }

    /// <summary>
    /// Creates a validated FriendshipState instance.
    /// </summary>
    /// <exception cref="ArgumentException">Thrown when invariants are violated.</exception>
    public static FriendshipState Create(
        Guid userId,
        int level,
        int currentXP,
        int xpToNextLevel,
        int totalXP,
        int loginStreak,
        DateTime lastLoginDate,
        List<string>? unlockedAchievements = null,
        List<RoomType>? unlockedRooms = null)
    {
        Validate(level, currentXP, xpToNextLevel, loginStreak);

        return new FriendshipState
        {
            UserId = userId,
            Level = level,
            CurrentXP = currentXP,
            XPToNextLevel = xpToNextLevel,
            TotalXP = totalXP,
            LoginStreak = loginStreak,
            LastLoginDate = lastLoginDate,
            UnlockedAchievements = unlockedAchievements ?? new List<string>(),
            UnlockedRooms = unlockedRooms ?? new List<RoomType>()
        };
    }

    private static void Validate(int level, int currentXP, int xpToNextLevel, int loginStreak)
    {
        if (level < 1)
        {
            throw new ArgumentException("Level must be greater than or equal to 1.", nameof(level));
        }

        if (currentXP < 0)
        {
            throw new ArgumentException("CurrentXP must be greater than or equal to 0.", nameof(currentXP));
        }

        if (currentXP >= xpToNextLevel)
        {
            throw new ArgumentException(
                $"CurrentXP ({currentXP}) must be less than XPToNextLevel ({xpToNextLevel}).",
                nameof(currentXP));
        }

        if (loginStreak < 0)
        {
            throw new ArgumentException("LoginStreak must be greater than or equal to 0.", nameof(loginStreak));
        }
    }
}
