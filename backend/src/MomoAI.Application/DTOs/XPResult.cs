using MomoAI.Domain.Enums;

namespace MomoAI.Application.DTOs;

/// <summary>
/// Result DTO returned after adding XP to a user's friendship state.
/// </summary>
public record XPResult
{
    public int Amount { get; init; }
    public int NewTotalXP { get; init; }
    public int NewLevel { get; init; }
    public bool LeveledUp { get; init; }
    public bool DailyCapReached { get; init; }
    public XPSource Source { get; init; }
}
