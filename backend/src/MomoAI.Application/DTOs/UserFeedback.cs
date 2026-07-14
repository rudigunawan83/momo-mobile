namespace MomoAI.Application.DTOs;

/// <summary>
/// DTO representing user feedback used to adjust personality traits.
/// </summary>
public record UserFeedback
{
    public Guid UserId { get; init; }
    public string FeedbackType { get; init; } = string.Empty;
    public string? TargetTrait { get; init; }
    public double Sentiment { get; init; }
    public DateTime Timestamp { get; init; }
}
