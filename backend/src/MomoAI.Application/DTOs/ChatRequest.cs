using MomoAI.Domain.Enums;

namespace MomoAI.Application.DTOs;

/// <summary>
/// Request DTO for processing a text chat message.
/// </summary>
public record ChatRequest
{
    public Guid UserId { get; init; }
    public string Message { get; init; } = string.Empty;
    public ConversationType ConversationType { get; init; } = ConversationType.Text;

    /// <summary>
    /// Optional client-provided timestamp for the message.
    /// If provided, it must not be more than 5 seconds in the future relative to server time.
    /// If null, the server uses the current UTC time.
    /// </summary>
    public DateTime? CreatedAt { get; init; }
}
