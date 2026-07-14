namespace MomoAI.Domain.Tests;

using MomoAI.Domain.Entities;

public class PersonalityProfileTests
{
    [Fact]
    public void Create_ValidProfile_Succeeds()
    {
        var profile = PersonalityProfile.Create(
            Guid.NewGuid(),
            humor: 0.7,
            caring: 0.8,
            curious: 0.6,
            calm: 0.5,
            "playful",
            DateTime.UtcNow);

        Assert.Equal(0.7, profile.Humor);
        Assert.Equal("playful", profile.TonePreference);
    }

    [Fact]
    public void CreateDefault_HasExpectedDefaults()
    {
        var userId = Guid.NewGuid();
        var profile = PersonalityProfile.CreateDefault(userId);

        Assert.Equal(userId, profile.UserId);
        Assert.Equal(0.5, profile.Humor);
        Assert.Equal(0.5, profile.Caring);
        Assert.Equal(0.5, profile.Curious);
        Assert.Equal(0.5, profile.Calm);
        Assert.Equal("balanced", profile.TonePreference);
    }

    [Theory]
    [InlineData(-0.1)]
    [InlineData(1.1)]
    public void Create_HumorOutOfRange_Throws(double humor)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            PersonalityProfile.Create(
                Guid.NewGuid(), humor, 0.5, 0.5, 0.5, "balanced", DateTime.UtcNow));
    }

    [Theory]
    [InlineData(-0.1)]
    [InlineData(1.1)]
    public void Create_CaringOutOfRange_Throws(double caring)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            PersonalityProfile.Create(
                Guid.NewGuid(), 0.5, caring, 0.5, 0.5, "balanced", DateTime.UtcNow));
    }

    [Theory]
    [InlineData(-0.1)]
    [InlineData(1.1)]
    public void Create_CuriousOutOfRange_Throws(double curious)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            PersonalityProfile.Create(
                Guid.NewGuid(), 0.5, 0.5, curious, 0.5, "balanced", DateTime.UtcNow));
    }

    [Theory]
    [InlineData(-0.1)]
    [InlineData(1.1)]
    public void Create_CalmOutOfRange_Throws(double calm)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            PersonalityProfile.Create(
                Guid.NewGuid(), 0.5, 0.5, 0.5, calm, "balanced", DateTime.UtcNow));
    }

    [Theory]
    [InlineData("invalid")]
    [InlineData("")]
    [InlineData("aggressive")]
    public void Create_InvalidTonePreference_Throws(string tone)
    {
        var ex = Assert.Throws<ArgumentException>(() =>
            PersonalityProfile.Create(
                Guid.NewGuid(), 0.5, 0.5, 0.5, 0.5, tone, DateTime.UtcNow));

        Assert.Contains("TonePreference", ex.Message);
    }

    [Theory]
    [InlineData("playful")]
    [InlineData("supportive")]
    [InlineData("intellectual")]
    [InlineData("balanced")]
    public void Create_ValidTonePreferences_Succeeds(string tone)
    {
        var profile = PersonalityProfile.Create(
            Guid.NewGuid(), 0.5, 0.5, 0.5, 0.5, tone, DateTime.UtcNow);

        Assert.Equal(tone, profile.TonePreference);
    }

    [Fact]
    public void Create_BoundaryTraitValues_Succeeds()
    {
        var profile = PersonalityProfile.Create(
            Guid.NewGuid(),
            humor: 0.0,
            caring: 1.0,
            curious: 0.0,
            calm: 1.0,
            "balanced",
            DateTime.UtcNow);

        Assert.Equal(0.0, profile.Humor);
        Assert.Equal(1.0, profile.Caring);
    }
}
