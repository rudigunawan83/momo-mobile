namespace MomoAI.Domain.Entities;

using MomoAI.Domain.Enums;

/// <summary>
/// Represents a single message in a chat conversation between the user and Momo.
/// </summary>
public record ChatMessage
{
    public Guid Id { get; init; }
    public Guid UserId { get; init; }
    public MessageRole Role { get; init; }
    public string Content { get; init; } = string.Empty;
    public MessageType Type { get; init; }
    public EmotionType? Emotion { get; init; }
    public DateTime CreatedAt { get; init; }
    public Dictionary<string, object>? Metadata { get; init; }

    private const int MaxContentLength = 4000;
    private static readonly TimeSpan FutureTimeTolerance = TimeSpan.FromSeconds(5);

    private ChatMessage() { }

    /// <summary>
    /// Creates a validated ChatMessage instance.
    /// </summary>
    /// <exception cref="ArgumentException">Thrown when validation rules are violated.</exception>
    public static ChatMessage Create(
        Guid id,
        Guid userId,
        MessageRole role,
        string content,
        MessageType type,
        DateTime createdAt,
        EmotionType? emotion = null,
        Dictionary<string, object>? metadata = null)
    {
        Validate(role, content, createdAt);

        return new ChatMessage
        {
            Id = id,
            UserId = userId,
            Role = role,
            Content = content,
            Type = type,
            CreatedAt = createdAt,
            Emotion = emotion,
            Metadata = metadata
        };
    }

    private static void Validate(MessageRole role, string content, DateTime createdAt)
    {
        if (role == MessageRole.User && string.IsNullOrWhiteSpace(content))
        {
            throw new ArgumentException("Content must not be empty or whitespace for User messages.", nameof(content));
        }

        if (content.Length > MaxContentLength)
        {
            throw new ArgumentException($"Content must not exceed {MaxContentLength} characters. Actual: {content.Length}.", nameof(content));
        }

        if (createdAt > DateTime.UtcNow.Add(FutureTimeTolerance))
        {
            throw new ArgumentException("CreatedAt must not be in the future (more than 5 seconds ahead of server time).", nameof(createdAt));
        }
    }
}
