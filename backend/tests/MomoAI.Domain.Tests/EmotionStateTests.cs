namespace MomoAI.Domain.Tests;

using MomoAI.Domain.Enums;
using MomoAI.Domain.ValueObjects;

public class EmotionStateTests
{
    [Fact]
    public void Create_ValidValues_Succeeds()
    {
        var state = EmotionState.Create(
            EmotionType.Happy,
            intensity: 0.8,
            valence: 0.5,
            arousal: 0.7,
            DateTime.UtcNow);

        Assert.Equal(EmotionType.Happy, state.Primary);
        Assert.Equal(0.8, state.Intensity);
        Assert.Equal(0.5, state.Valence);
        Assert.Equal(0.7, state.Arousal);
    }

    [Theory]
    [InlineData(-0.1)]
    [InlineData(1.1)]
    [InlineData(2.0)]
    public void Create_IntensityOutOfRange_Throws(double intensity)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            EmotionState.Create(EmotionType.Happy, intensity, 0.0, 0.5, DateTime.UtcNow));
    }

    [Theory]
    [InlineData(-1.1)]
    [InlineData(1.1)]
    [InlineData(5.0)]
    public void Create_ValenceOutOfRange_Throws(double valence)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            EmotionState.Create(EmotionType.Happy, 0.5, valence, 0.5, DateTime.UtcNow));
    }

    [Theory]
    [InlineData(-0.1)]
    [InlineData(1.1)]
    [InlineData(3.0)]
    public void Create_ArousalOutOfRange_Throws(double arousal)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            EmotionState.Create(EmotionType.Happy, 0.5, 0.0, arousal, DateTime.UtcNow));
    }

    [Fact]
    public void Create_BoundaryValues_Succeeds()
    {
        var state = EmotionState.Create(
            EmotionType.Neutral,
            intensity: 0.0,
            valence: -1.0,
            arousal: 1.0,
            DateTime.UtcNow);

        Assert.Equal(0.0, state.Intensity);
        Assert.Equal(-1.0, state.Valence);
        Assert.Equal(1.0, state.Arousal);
    }

    [Fact]
    public void Create_WithSecondaryEmotion_Succeeds()
    {
        var state = EmotionState.Create(
            EmotionType.Happy,
            intensity: 0.6,
            valence: 0.8,
            arousal: 0.5,
            DateTime.UtcNow,
            secondary: EmotionType.Excited);

        Assert.Equal(EmotionType.Excited, state.Secondary);
    }
}
