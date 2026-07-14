namespace MomoAI.Application.DTOs;

/// <summary>
/// DTO representing a user's personality profile for Momo's AI behavior.
/// All trait values are within [0.0, 1.0].
/// </summary>
public record PersonalityProfile
{
    public Guid UserId { get; init; }
    public double Humor { get; init; }
    public double Caring { get; init; }
    public double Curious { get; init; }
    public double Calm { get; init; }
    public string TonePreference { get; init; } = "balanced";
    public DateTime LastUpdated { get; init; }
}
