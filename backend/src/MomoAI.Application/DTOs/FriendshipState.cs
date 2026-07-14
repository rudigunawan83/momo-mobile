using MomoAI.Domain.Enums;

namespace MomoAI.Application.DTOs;

/// <summary>
/// DTO representing the current friendship progression state for a user.
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
}
