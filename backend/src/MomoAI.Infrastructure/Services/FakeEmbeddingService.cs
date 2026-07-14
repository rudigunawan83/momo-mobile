using MomoAI.Application.Interfaces;

namespace MomoAI.Infrastructure.Services;

/// <summary>
/// Fake embedding service for development without OpenAI.
/// Returns random normalized vectors of the correct dimension (1536).
/// </summary>
public class FakeEmbeddingService : IEmbeddingService
{
    private const int Dimension = 1536;

    public Task<float[]> GenerateEmbeddingAsync(string text, CancellationToken ct)
    {
        // Generate a deterministic-ish vector based on text hash for consistency
        var random = new Random(text.GetHashCode());
        var embedding = new float[Dimension];

        float norm = 0;
        for (int i = 0; i < Dimension; i++)
        {
            embedding[i] = (float)(random.NextDouble() * 2 - 1);
            norm += embedding[i] * embedding[i];
        }

        // Normalize the vector
        norm = MathF.Sqrt(norm);
        for (int i = 0; i < Dimension; i++)
        {
            embedding[i] /= norm;
        }

        return Task.FromResult(embedding);
    }
}
