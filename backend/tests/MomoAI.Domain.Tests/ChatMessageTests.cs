namespace MomoAI.Domain.Tests;

using MomoAI.Domain.Entities;
using MomoAI.Domain.Enums;

public class ChatMessageTests
{
    [Fact]
    public void Create_ValidUserMessage_Succeeds()
    {
        var message = ChatMessage.Create(
            Guid.NewGuid(),
            Guid.NewGuid(),
            MessageRole.User,
            "Hello Momo!",
            MessageType.Text,
            DateTime.UtcNow);

        Assert.Equal("Hello Momo!", message.Content);
        Assert.Equal(MessageRole.User, message.Role);
    }

    [Fact]
    public void Create_UserRole_EmptyContent_Throws()
    {
        var ex = Assert.Throws<ArgumentException>(() =>
            ChatMessage.Create(
                Guid.NewGuid(),
                Guid.NewGuid(),
                MessageRole.User,
                "",
                MessageType.Text,
                DateTime.UtcNow));

        Assert.Contains("empty", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Create_UserRole_WhitespaceContent_Throws()
    {
        var ex = Assert.Throws<ArgumentException>(() =>
            ChatMessage.Create(
                Guid.NewGuid(),
                Guid.NewGuid(),
                MessageRole.User,
                "   \t\n  ",
                MessageType.Text,
                DateTime.UtcNow));

        Assert.Contains("empty", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Create_AssistantRole_EmptyContent_Succeeds()
    {
        var message = ChatMessage.Create(
            Guid.NewGuid(),
            Guid.NewGuid(),
            MessageRole.Assistant,
            "",
            MessageType.Text,
            DateTime.UtcNow);

        Assert.Equal(string.Empty, message.Content);
    }

    [Fact]
    public void Create_ContentExceeds4000Chars_Throws()
    {
        var longContent = new string('a', 4001);

        var ex = Assert.Throws<ArgumentException>(() =>
            ChatMessage.Create(
                Guid.NewGuid(),
                Guid.NewGuid(),
                MessageRole.User,
                longContent,
                MessageType.Text,
                DateTime.UtcNow));

        Assert.Contains("4000", ex.Message);
    }

    [Fact]
    public void Create_ContentExactly4000Chars_Succeeds()
    {
        var content = new string('a', 4000);

        var message = ChatMessage.Create(
            Guid.NewGuid(),
            Guid.NewGuid(),
            MessageRole.User,
            content,
            MessageType.Text,
            DateTime.UtcNow);

        Assert.Equal(4000, message.Content.Length);
    }

    [Fact]
    public void Create_FutureCreatedAt_Throws()
    {
        var futureTime = DateTime.UtcNow.AddSeconds(10);

        var ex = Assert.Throws<ArgumentException>(() =>
            ChatMessage.Create(
                Guid.NewGuid(),
                Guid.NewGuid(),
                MessageRole.User,
                "Hello",
                MessageType.Text,
                futureTime));

        Assert.Contains("future", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Create_CreatedAtWithin5Seconds_Succeeds()
    {
        var nearFuture = DateTime.UtcNow.AddSeconds(3);

        var message = ChatMessage.Create(
            Guid.NewGuid(),
            Guid.NewGuid(),
            MessageRole.User,
            "Hello",
            MessageType.Text,
            nearFuture);

        Assert.Equal(nearFuture, message.CreatedAt);
    }
}
