namespace MomoAI.Domain.Tests;

using MomoAI.Domain.Entities;
using MomoAI.Domain.Enums;

public class MemoryTests
{
    private static float[] ValidEmbedding() => new float[1536];

    [Fact]
    public void Create_ValidMemory_Succeeds()
    {
        var memory = Memory.Create(
            Guid.NewGuid(),
            Guid.NewGuid(),
            "Short summary",
            "Some content about a conversation.",
            MemoryType.Conversation,
            0.8,
            ValidEmbedding(),
            DateTime.UtcNow.AddHours(-1),
            DateTime.UtcNow);

        Assert.Equal("Short summary", memory.Summary);
        Assert.Equal(0.8, memory.ImportanceScore);
    }

    [Fact]
    public void Create_SummaryExceeds500Chars_Throws()
    {
        var longSummary = new string('x', 501);

        var ex = Assert.Throws<ArgumentException>(() =>
            Memory.Create(
                Guid.NewGuid(),
                Guid.NewGuid(),
                longSummary,
                "content",
                MemoryType.Conversation,
                0.5,
                ValidEmbedding(),
                DateTime.UtcNow,
                DateTime.UtcNow));

        Assert.Contains("500", ex.Message);
    }

    [Fact]
    public void Create_ContentExceeds2000Chars_Throws()
    {
        var longContent = new string('x', 2001);

        var ex = Assert.Throws<ArgumentException>(() =>
            Memory.Create(
                Guid.NewGuid(),
                Guid.NewGuid(),
                "summary",
                longContent,
                MemoryType.Fact,
                0.5,
                ValidEmbedding(),
                DateTime.UtcNow,
                DateTime.UtcNow));

        Assert.Contains("2000", ex.Message);
    }

    [Theory]
    [InlineData(-0.1)]
    [InlineData(1.1)]
    public void Create_ImportanceScoreOutOfRange_Throws(double score)
    {
        Assert.Throws<ArgumentException>(() =>
            Memory.Create(
                Guid.NewGuid(),
                Guid.NewGuid(),
                "summary",
                "content",
                MemoryType.Conversation,
                score,
                ValidEmbedding(),
                DateTime.UtcNow,
                DateTime.UtcNow));
    }

    [Fact]
    public void Create_WrongEmbeddingDimension_Throws()
    {
        var wrongEmbedding = new float[512];

        var ex = Assert.Throws<ArgumentException>(() =>
            Memory.Create(
                Guid.NewGuid(),
                Guid.NewGuid(),
                "summary",
                "content",
                MemoryType.Conversation,
                0.5,
                wrongEmbedding,
                DateTime.UtcNow,
                DateTime.UtcNow));

        Assert.Contains("1536", ex.Message);
    }

    [Fact]
    public void Create_EmptyEmbedding_Throws()
    {
        Assert.Throws<ArgumentException>(() =>
            Memory.Create(
                Guid.NewGuid(),
                Guid.NewGuid(),
                "summary",
                "content",
                MemoryType.Conversation,
                0.5,
                Array.Empty<float>(),
                DateTime.UtcNow,
                DateTime.UtcNow));
    }

    [Fact]
    public void Create_BoundaryValues_Succeeds()
    {
        var summary = new string('a', 500);
        var content = new string('b', 2000);

        var memory = Memory.Create(
            Guid.NewGuid(),
            Guid.NewGuid(),
            summary,
            content,
            MemoryType.Preference,
            1.0,
            ValidEmbedding(),
            DateTime.UtcNow,
            DateTime.UtcNow);

        Assert.Equal(500, memory.Summary.Length);
        Assert.Equal(2000, memory.Content.Length);
        Assert.Equal(1.0, memory.ImportanceScore);
    }
}
