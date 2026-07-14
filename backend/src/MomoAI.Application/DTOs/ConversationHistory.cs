using MomoAI.Domain.Enums;

namespace MomoAI.Application.DTOs;

/// <summary>
/// Paginated conversation history response.
/// </summary>
public record ConversationHistory
{
    public List<ChatMessageDto> Messages { get; init; } = new();
    public int Page { get; init; }
    public int PageSize { get; init; }
    public int TotalCount { get; init; }
    public bool HasMore { get; init; }
}

/// <summary>
/// DTO representing a single chat message in conversation history.
/// </summary>
public record ChatMessageDto
{
    public Guid Id { get; init; }
    public MessageRole Role { get; init; }
    public string Content { get; init; } = string.Empty;
    public MessageType Type { get; init; }
    public EmotionType? Emotion { get; init; }
    public DateTime CreatedAt { get; init; }
}
