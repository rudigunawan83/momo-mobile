using MomoAI.Domain.Enums;

namespace MomoAI.Application.DTOs;

/// <summary>
/// Input DTO for storing a new memory entry.
/// </summary>
public record MemoryInput
{
    public string Summary { get; init; } = string.Empty;
    public string Content { get; init; } = string.Empty;
    public MemoryType Type { get; init; }
    public double ImportanceScore { get; init; }
    public Dictionary<string, string> Tags { get; init; } = new();
}
