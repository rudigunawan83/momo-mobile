using Microsoft.EntityFrameworkCore;
using MomoAI.Application.DTOs;
using MomoAI.Application.Interfaces;
using MomoAI.Infrastructure.Persistence;
using MomoAI.Infrastructure.Persistence.Entities;
using Pgvector;
using Pgvector.EntityFrameworkCore;

namespace MomoAI.Infrastructure.Services;

/// <summary>
/// Memory Engine implementation using PostgreSQL with pgvector for semantic similarity search.
/// Manages long-term memory storage, retrieval, and relevance scoring.
/// Memories are encrypted at rest using AES-256 (Req 13.2).
/// </summary>
public class MemoryEngine : IMemoryEngine
{
    private readonly MomoDbContext _dbContext;
    private readonly IEmbeddingService _embeddingService;
    private readonly IEncryptionService _encryptionService;

    // Relevance scoring weights — all positive, sum ≤ 1.0
    private const double SemanticWeight = 0.5;
    private const double RecencyWeight = 0.2;
    private const double ImportanceWeight = 0.2;
    private const double FavoriteWeight = 0.1;

    // Recency decay rate (higher = faster decay)
    private const double DecayRate = 0.01;

    // Minimum relevance threshold to include a memory in results
    private const double MinRelevanceThreshold = 0.1;

    // Validation constants
    private const int MaxSummaryLength = 500;
    private const int MaxContentLength = 2000;
    private const int EmbeddingDimension = 1536;

    public MemoryEngine(MomoDbContext dbContext, IEmbeddingService embeddingService, IEncryptionService encryptionService)
    {
        _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
        _embeddingService = embeddingService ?? throw new ArgumentNullException(nameof(embeddingService));
        _encryptionService = encryptionService ?? throw new ArgumentNullException(nameof(encryptionService));
    }

    /// <inheritdoc />
    public async Task<List<Memory>> GetRelevantMemoriesAsync(
        Guid userId, string context, int maxResults, CancellationToken ct)
    {
        if (maxResults < 1 || maxResults > 20)
            throw new ArgumentOutOfRangeException(nameof(maxResults), "maxResults must be between 1 and 20 inclusive.");

        if (string.IsNullOrWhiteSpace(context))
            throw new ArgumentException("Context must not be empty.", nameof(context));

        // Generate embedding for the query context
        var queryEmbedding = await _embeddingService.GenerateEmbeddingAsync(context, ct);
        var queryVector = new Vector(queryEmbedding);

        // Retrieve candidate memories for this user only (memory isolation)
        var userMemories = await _dbContext.Memories
            .Where(m => m.UserId == userId)
            .OrderBy(m => m.Embedding.CosineDistance(queryVector))
            .Take(maxResults * 3) // Fetch more candidates for relevance re-ranking
            .AsNoTracking()
            .ToListAsync(ct);

        if (userMemories.Count == 0)
            return new List<Memory>();

        // Score and rank memories
        var now = DateTime.UtcNow;
        var scoredMemories = userMemories
            .Select(m => new
            {
                Entity = m,
                Score = CalculateRelevanceScore(m, queryVector, now)
            })
            .Where(x => x.Score >= MinRelevanceThreshold)
            .OrderByDescending(x => x.Score)
            .DistinctBy(x => x.Entity.Id) // Ensure no duplicates
            .Take(maxResults)
            .ToList();

        return scoredMemories
            .Select(x => MapToDto(x.Entity))
            .ToList();
    }

    /// <inheritdoc />
    public async Task<Memory> StoreMemoryAsync(Guid userId, MemoryInput input, CancellationToken ct)
    {
        ValidateMemoryInput(input);

        // Generate embedding from the combined summary and content (before encryption)
        var textToEmbed = $"{input.Summary} {input.Content}".Trim();
        var embedding = await _embeddingService.GenerateEmbeddingAsync(textToEmbed, ct);

        if (embedding.Length != EmbeddingDimension)
        {
            throw new InvalidOperationException(
                $"Embedding service returned {embedding.Length} dimensions, expected {EmbeddingDimension}.");
        }

        // Encrypt sensitive content at rest using AES-256 (Req 13.2)
        var encryptedSummary = _encryptionService.Encrypt(input.Summary);
        var encryptedContent = _encryptionService.Encrypt(input.Content);

        var entity = new MemoryEntity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Summary = encryptedSummary,
            Content = encryptedContent,
            Type = input.Type,
            ImportanceScore = input.ImportanceScore,
            Embedding = new Vector(embedding),
            IsFavorite = false,
            OccurredAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
            Tags = input.Tags ?? new Dictionary<string, string>()
        };

        _dbContext.Memories.Add(entity);
        await _dbContext.SaveChangesAsync(ct);

        return MapToDto(entity);
    }

    /// <inheritdoc />
    public async Task<List<Memory>> SearchMemoriesAsync(Guid userId, string query, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(query))
            throw new ArgumentException("Query must not be empty.", nameof(query));

        var queryEmbedding = await _embeddingService.GenerateEmbeddingAsync(query, ct);
        var queryVector = new Vector(queryEmbedding);

        // Search with memory isolation — only this user's memories
        var results = await _dbContext.Memories
            .Where(m => m.UserId == userId)
            .OrderBy(m => m.Embedding.CosineDistance(queryVector))
            .Take(10)
            .AsNoTracking()
            .ToListAsync(ct);

        return results.Select(MapToDto).ToList();
    }

    /// <summary>
    /// Calculates the composite relevance score for a memory.
    /// Formula: SEMANTIC_WEIGHT * semanticScore + RECENCY_WEIGHT * recencyScore + importanceBoost + favoriteBoost
    /// Result is clamped to [0.0, 1.0].
    /// </summary>
    private double CalculateRelevanceScore(MemoryEntity memory, Vector queryVector, DateTime now)
    {
        // Semantic similarity: 1 - cosineDistance (cosine distance is in [0, 2], similarity in [-1, 1])
        var cosineDistance = CosineDistance(memory.Embedding, queryVector);
        var semanticScore = 1.0 - cosineDistance;

        // Recency decay: e^(-DECAY_RATE * daysSinceMemory)
        var daysSinceMemory = Math.Max(0, (now - memory.OccurredAt).TotalDays);
        var recencyScore = Math.Exp(-DecayRate * daysSinceMemory);

        // Importance boost
        var importanceBoost = memory.ImportanceScore * ImportanceWeight;

        // Favorite boost
        var favoriteBoost = memory.IsFavorite ? FavoriteWeight : 0.0;

        // Weighted combination
        var relevanceScore =
            SemanticWeight * semanticScore +
            RecencyWeight * recencyScore +
            importanceBoost +
            favoriteBoost;

        // Clamp to [0.0, 1.0]
        return Math.Clamp(relevanceScore, 0.0, 1.0);
    }

    /// <summary>
    /// Calculates cosine distance between two vectors.
    /// Cosine distance = 1 - cosine_similarity.
    /// Returns value in [0, 2].
    /// </summary>
    private static double CosineDistance(Vector a, Vector b)
    {
        var vecA = a.ToArray();
        var vecB = b.ToArray();

        if (vecA.Length != vecB.Length)
            return 2.0; // Maximum distance for mismatched dimensions

        double dotProduct = 0;
        double normA = 0;
        double normB = 0;

        for (int i = 0; i < vecA.Length; i++)
        {
            dotProduct += vecA[i] * vecB[i];
            normA += vecA[i] * vecA[i];
            normB += vecB[i] * vecB[i];
        }

        var denominator = Math.Sqrt(normA) * Math.Sqrt(normB);
        if (denominator == 0)
            return 1.0; // Undefined, treat as orthogonal

        var cosineSimilarity = dotProduct / denominator;
        return 1.0 - cosineSimilarity;
    }

    private static void ValidateMemoryInput(MemoryInput input)
    {
        if (input.Summary.Length > MaxSummaryLength)
        {
            throw new ArgumentException(
                $"Summary must not exceed {MaxSummaryLength} characters. Actual: {input.Summary.Length}.",
                nameof(input));
        }

        if (input.Content.Length > MaxContentLength)
        {
            throw new ArgumentException(
                $"Content must not exceed {MaxContentLength} characters. Actual: {input.Content.Length}.",
                nameof(input));
        }

        if (input.ImportanceScore < 0.0 || input.ImportanceScore > 1.0)
        {
            throw new ArgumentException(
                "ImportanceScore must be between 0.0 and 1.0 inclusive.",
                nameof(input));
        }
    }

    /// <summary>
    /// Maps an entity to a DTO, decrypting the summary and content fields (Req 13.2).
    /// </summary>
    private Memory MapToDto(MemoryEntity entity)
    {
        return new Memory
        {
            Id = entity.Id,
            UserId = entity.UserId,
            Summary = _encryptionService.Decrypt(entity.Summary),
            Content = _encryptionService.Decrypt(entity.Content),
            Type = entity.Type,
            ImportanceScore = entity.ImportanceScore,
            Embedding = entity.Embedding.ToArray(),
            IsFavorite = entity.IsFavorite,
            OccurredAt = entity.OccurredAt,
            CreatedAt = entity.CreatedAt,
            Tags = entity.Tags
        };
    }
}
