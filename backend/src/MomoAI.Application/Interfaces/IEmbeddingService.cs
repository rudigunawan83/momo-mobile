namespace MomoAI.Application.Interfaces;

/// <summary>
/// Generates embedding vectors from text for semantic similarity search.
/// </summary>
public interface IEmbeddingService
{
    /// <summary>
    /// Generates an embedding vector from the given text.
    /// The returned vector has 1536 dimensions (text-embedding-ada-002).
    /// </summary>
    /// <param name="text">The text to embed.</param>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>A float array with 1536 dimensions representing the semantic embedding.</returns>
    Task<float[]> GenerateEmbeddingAsync(string text, CancellationToken ct);
}
