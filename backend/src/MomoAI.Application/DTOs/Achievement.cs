namespace MomoAI.Application.DTOs;

/// <summary>
/// DTO representing an unlocked achievement.
/// </summary>
public record Achievement
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string Description { get; init; } = string.Empty;
    public string IconUrl { get; init; } = string.Empty;
    public DateTime UnlockedAt { get; init; }
}
