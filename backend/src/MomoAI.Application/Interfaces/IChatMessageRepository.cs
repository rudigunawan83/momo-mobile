using MomoAI.Application.DTOs;

namespace MomoAI.Application.Interfaces;

/// <summary>
/// Repository interface for chat message persistence and retrieval.
/// </summary>
public interface IChatMessageRepository
{
    /// <summary>
    /// Gets the most recent messages for a user, ordered by creation time descending.
    /// </summary>
    /// <param name="userId">The user's identifier.</param>
    /// <param name="limit">Maximum number of messages to retrieve.</param>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>Recent messages ordered most recent first.</returns>
    Task<List<ChatMessageDto>> GetRecentMessagesAsync(Guid userId, int limit, CancellationToken ct);

    /// <summary>
    /// Stores a new chat message.
    /// </summary>
    /// <param name="message">The message DTO to store.</param>
    /// <param name="ct">Cancellation token.</param>
    Task SaveMessageAsync(ChatMessageDto message, CancellationToken ct);

    /// <summary>
    /// Gets paginated conversation history for a user.
    /// </summary>
    /// <param name="userId">The user's identifier.</param>
    /// <param name="page">Page number (1-based).</param>
    /// <param name="pageSize">Number of messages per page.</param>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>Paginated conversation history.</returns>
    Task<ConversationHistory> GetHistoryAsync(Guid userId, int page, int pageSize, CancellationToken ct);
}
