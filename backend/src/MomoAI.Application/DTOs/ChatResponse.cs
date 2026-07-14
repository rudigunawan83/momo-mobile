using MomoAI.Domain.Enums;

namespace MomoAI.Application.DTOs;

/// <summary>
/// Response DTO returned after processing a chat message.
/// </summary>
public record ChatResponse
{
    public string Message { get; init; } = string.Empty;
    public EmotionType Emotion { get; init; }
    public int XpGained { get; init; }
    public bool LevelUp { get; init; }
    public List<string> NewAchievements { get; init; } = new();

    /// <summary>
    /// Indicates whether memory context was available during response generation.
    /// When false, the response was generated without historical memory context.
    /// </summary>
    public bool MemoryContextApplied { get; init; } = true;
}
