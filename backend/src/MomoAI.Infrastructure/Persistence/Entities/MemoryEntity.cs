using MomoAI.Domain.Enums;
using Pgvector;

namespace MomoAI.Infrastructure.Persistence.Entities;

/// <summary>
/// EF Core entity representing a Memory row in PostgreSQL with pgvector embedding.
/// </summary>
public class MemoryEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Summary { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public MemoryType Type { get; set; }
    public double ImportanceScore { get; set; }
    public Vector Embedding { get; set; } = null!;
    public bool IsFavorite { get; set; }
    public DateTime OccurredAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public Dictionary<string, string> Tags { get; set; } = new();
}
