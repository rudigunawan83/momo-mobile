using MomoAI.Application.DTOs;

namespace MomoAI.Application.Interfaces;

/// <summary>
/// Manages long-term memory storage, retrieval, and relevance scoring
/// for contextual conversations.
/// </summary>
public interface IMemoryEngine
{
    /// <summary>
    /// Retrieves memories most relevant to the given context, ordered by relevance score descending.
    /// Enforces memory isolation — only returns memories belonging to the specified user.
    /// </summary>
    /// <param name="userId">The user's identifier.</param>
    /// <param name="context">The current conversation context used for similarity search.</param>
    /// <param name="maxResults">Maximum number of results to return (1-20).</param>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>List of relevant memories ordered by relevance score descending.</returns>
    Task<List<Memory>> GetRelevantMemoriesAsync(Guid userId, string context, int maxResults, CancellationToken ct);

    /// <summary>
    /// Stores a new memory entry with an auto-generated embedding vector for similarity search.
    /// Validates summary (max 500 chars) and content (max 2000 chars) length limits.
    /// </summary>
    /// <param name="userId">The user's identifier.</param>
    /// <param name="input">The memory data to store.</param>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>The stored memory with generated ID and embedding.</returns>
    Task<Memory> StoreMemoryAsync(Guid userId, MemoryInput input, CancellationToken ct);

    /// <summary>
    /// Searches memories by text query using semantic similarity.
    /// Enforces memory isolation — only searches memories belonging to the specified user.
    /// </summary>
    /// <param name="userId">The user's identifier.</param>
    /// <param name="query">The search query text.</param>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>List of matching memories ordered by relevance.</returns>
    Task<List<Memory>> SearchMemoriesAsync(Guid userId, string query, CancellationToken ct);
}
