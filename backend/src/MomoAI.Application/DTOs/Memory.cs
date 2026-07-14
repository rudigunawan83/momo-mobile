using MomoAI.Domain.Enums;

namespace MomoAI.Application.DTOs;

/// <summary>
/// DTO representing a stored memory entry.
/// </summary>
public record Memory
{
    public Guid Id { get; init; }
    public Guid UserId { get; init; }
    public string Summary { get; init; } = string.Empty;
    public string Content { get; init; } = string.Empty;
    public MemoryType Type { get; init; }
    public double ImportanceScore { get; init; }
    public float[] Embedding { get; init; } = Array.Empty<float>();
    public bool IsFavorite { get; init; }
    public DateTime OccurredAt { get; init; }
    public DateTime CreatedAt { get; init; }
    public Dictionary<string, string> Tags { get; init; } = new();
}
