namespace MomoAI.Domain.Tests;

using MomoAI.Domain.Entities;
using MomoAI.Domain.Enums;

public class FriendshipStateTests
{
    [Fact]
    public void Create_ValidState_Succeeds()
    {
        var state = FriendshipState.Create(
            Guid.NewGuid(),
            level: 3,
            currentXP: 50,
            xpToNextLevel: 100,
            totalXP: 350,
            loginStreak: 5,
            DateTime.UtcNow);

        Assert.Equal(3, state.Level);
        Assert.Equal(50, state.CurrentXP);
    }

    [Fact]
    public void Create_LevelLessThan1_Throws()
    {
        var ex = Assert.Throws<ArgumentException>(() =>
            FriendshipState.Create(
                Guid.NewGuid(),
                level: 0,
                currentXP: 0,
                xpToNextLevel: 100,
                totalXP: 0,
                loginStreak: 0,
                DateTime.UtcNow));

        Assert.Contains("Level", ex.Message);
    }

    [Fact]
    public void Create_NegativeCurrentXP_Throws()
    {
        var ex = Assert.Throws<ArgumentException>(() =>
            FriendshipState.Create(
                Guid.NewGuid(),
                level: 1,
                currentXP: -1,
                xpToNextLevel: 100,
                totalXP: 0,
                loginStreak: 0,
                DateTime.UtcNow));

        Assert.Contains("CurrentXP", ex.Message);
    }

    [Fact]
    public void Create_CurrentXPEqualToXPToNextLevel_Throws()
    {
        var ex = Assert.Throws<ArgumentException>(() =>
            FriendshipState.Create(
                Guid.NewGuid(),
                level: 1,
                currentXP: 100,
                xpToNextLevel: 100,
                totalXP: 100,
                loginStreak: 0,
                DateTime.UtcNow));

        Assert.Contains("CurrentXP", ex.Message);
    }

    [Fact]
    public void Create_CurrentXPGreaterThanXPToNextLevel_Throws()
    {
        Assert.Throws<ArgumentException>(() =>
            FriendshipState.Create(
                Guid.NewGuid(),
                level: 1,
                currentXP: 150,
                xpToNextLevel: 100,
                totalXP: 150,
                loginStreak: 0,
                DateTime.UtcNow));
    }

    [Fact]
    public void Create_ZeroCurrentXP_Succeeds()
    {
        var state = FriendshipState.Create(
            Guid.NewGuid(),
            level: 1,
            currentXP: 0,
            xpToNextLevel: 100,
            totalXP: 0,
            loginStreak: 0,
            DateTime.UtcNow);

        Assert.Equal(0, state.CurrentXP);
    }

    [Fact]
    public void Create_WithUnlockedRooms_Succeeds()
    {
        var rooms = new List<RoomType> { RoomType.Cozy, RoomType.Garden };

        var state = FriendshipState.Create(
            Guid.NewGuid(),
            level: 5,
            currentXP: 20,
            xpToNextLevel: 200,
            totalXP: 800,
            loginStreak: 10,
            DateTime.UtcNow,
            unlockedRooms: rooms);

        Assert.Equal(2, state.UnlockedRooms.Count);
    }
}
