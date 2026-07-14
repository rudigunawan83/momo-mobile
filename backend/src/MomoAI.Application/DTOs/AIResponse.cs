using MomoAI.Domain.Enums;

namespace MomoAI.Application.DTOs;

/// <summary>
/// Response DTO returned from the AI Gateway after generating a response.
/// </summary>
public record AIResponse
{
    public string Text { get; init; } = string.Empty;
    public EmotionType DetectedEmotion { get; init; }
    public int TokensUsed { get; init; }
    public double SentimentScore { get; init; }

    /// <summary>
    /// Indicates whether this response is a fallback (returned when AI Gateway
    /// fails after all retries or times out).
    /// </summary>
    public bool IsFallback { get; init; }
}
