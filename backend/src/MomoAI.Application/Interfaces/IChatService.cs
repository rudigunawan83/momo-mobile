using MomoAI.Application.DTOs;

namespace MomoAI.Application.Interfaces;

/// <summary>
/// Orchestrates AI conversation flow including context retrieval,
/// response generation, and post-processing.
/// </summary>
public interface IChatService
{
    /// <summary>
    /// Processes a text chat message through the full AI pipeline:
    /// retrieve memories, apply personality, generate response, store memory, award XP.
    /// </summary>
    /// <param name="request">The chat request containing userId and message.</param>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>A ChatResponse with the AI reply, detected emotion, and XP info.</returns>
    Task<ChatResponse> ProcessMessageAsync(ChatRequest request, CancellationToken ct);

    /// <summary>
    /// Processes a voice message by transcribing audio and routing through the same AI pipeline.
    /// </summary>
    /// <param name="request">The voice request containing audio data.</param>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>A ChatResponse with the AI reply, detected emotion, and XP info.</returns>
    Task<ChatResponse> ProcessVoiceMessageAsync(VoiceRequest request, CancellationToken ct);

    /// <summary>
    /// Retrieves paginated conversation history for a user.
    /// </summary>
    /// <param name="userId">The user's identifier.</param>
    /// <param name="page">Page number (1-based).</param>
    /// <param name="pageSize">Number of messages per page.</param>
    /// <param name="ct">Cancellation token.</param>
    /// <returns>Paginated conversation history.</returns>
    Task<ConversationHistory> GetHistoryAsync(Guid userId, int page, int pageSize, CancellationToken ct);
}
