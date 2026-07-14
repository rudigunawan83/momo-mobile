using MomoAI.Application.DTOs;

namespace MomoAI.Application.Interfaces;

/// <summary>
/// Provides methods for backend services to push real-time notifications
/// to connected clients via SignalR. Decouples domain/application logic
/// from the SignalR Hub implementation.
/// </summary>
public interface IHubNotificationService
{
    /// <summary>
    /// Streams an AI response to the connected user chunk by chunk.
    /// Each chunk is delivered within 300ms, followed by a completion signal.
    /// </summary>
    /// <param name="userId">The target user's identifier.</param>
    /// <param name="chunks">The stream of response chunks to deliver.</param>
    /// <param name="emotion">The detected emotion for the full response.</param>
    /// <param name="ct">Cancellation token.</param>
    Task StreamResponseAsync(Guid userId, IAsyncEnumerable<string> chunks, string emotion, CancellationToken ct);

    /// <summary>
    /// Pushes a friendship state update to the specified user's connected client.
    /// Must be delivered within 500ms of the event occurring.
    /// </summary>
    /// <param name="userId">The target user's identifier.</param>
    /// <param name="update">The friendship state update data.</param>
    /// <param name="ct">Cancellation token.</param>
    Task SendFriendshipUpdateAsync(Guid userId, FriendshipStateUpdate update, CancellationToken ct);

    /// <summary>
    /// Sends an error notification to the connected user.
    /// </summary>
    /// <param name="userId">The target user's identifier.</param>
    /// <param name="errorMessage">A user-friendly error description.</param>
    /// <param name="ct">Cancellation token.</param>
    Task SendErrorAsync(Guid userId, string errorMessage, CancellationToken ct);
}
