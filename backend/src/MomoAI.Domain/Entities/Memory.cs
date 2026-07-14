namespace MomoAI.Domain.Entities;

using MomoAI.Domain.Enums;

/// <summary>
/// Represents a long-term memory entry stored for contextual conversations.
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

    private const int MaxSummaryLength = 500;
    private const int MaxContentLength = 2000;
    private const int RequiredEmbeddingDimension = 1536;

    private Memory() { }

    /// <summary>
    /// Creates a validated Memory instance.
    /// </summary>
    /// <exception cref="ArgumentException">Thrown when validation rules are violated.</exception>
    public static Memory Create(
        Guid id,
        Guid userId,
        string summary,
        string content,
        MemoryType type,
        double importanceScore,
        float[] embedding,
        DateTime occurredAt,
        DateTime createdAt,
        bool isFavorite = false,
        Dictionary<string, string>? tags = null)
    {
        Validate(summary, content, importanceScore, embedding);

        return new Memory
        {
            Id = id,
            UserId = userId,
            Summary = summary,
            Content = content,
            Type = type,
            ImportanceScore = importanceScore,
            Embedding = embedding,
            IsFavorite = isFavorite,
            OccurredAt = occurredAt,
            CreatedAt = createdAt,
            Tags = tags ?? new Dictionary<string, string>()
        };
    }

    private static void Validate(string summary, string content, double importanceScore, float[] embedding)
    {
        if (summary.Length > MaxSummaryLength)
        {
            throw new ArgumentException(
                $"Summary must not exceed {MaxSummaryLength} characters. Actual: {summary.Length}.",
                nameof(summary));
        }

        if (content.Length > MaxContentLength)
        {
            throw new ArgumentException(
                $"Content must not exceed {MaxContentLength} characters. Actual: {content.Length}.",
                nameof(content));
        }

        if (importanceScore < 0.0 || importanceScore > 1.0)
        {
            throw new ArgumentException(
                "ImportanceScore must be between 0.0 and 1.0 inclusive.",
                nameof(importanceScore));
        }

        if (embedding.Length != RequiredEmbeddingDimension)
        {
            throw new ArgumentException(
                $"Embedding must have exactly {RequiredEmbeddingDimension} dimensions. Actual: {embedding.Length}.",
                nameof(embedding));
        }
    }
}
