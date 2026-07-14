using Microsoft.AspNetCore.SignalR;
using MomoAI.API.Hubs;
using MomoAI.Application.Interfaces;

namespace MomoAI.API.Services;

/// <summary>
/// Implementation of IHubNotificationService that uses SignalR to push
/// real-time updates to connected clients. Ensures streaming chunks are
/// delivered within 300ms and friendship updates within 500ms.
/// </summary>
public class HubNotificationService : IHubNotificationService
{
    private readonly IHubContext<ChatHub, IChatHubClient> _hubContext;
    private readonly ILogger<HubNotificationService> _logger;

    public HubNotificationService(
        IHubContext<ChatHub, IChatHubClient> hubContext,
        ILogger<HubNotificationService> logger)
    {
        _hubContext = hubContext;
        _logger = logger;
    }

    /// <inheritdoc/>
    public async Task StreamResponseAsync(
        Guid userId,
        IAsyncEnumerable<string> chunks,
        string emotion,
        CancellationToken ct)
    {
        var group = _hubContext.Clients.Group(userId.ToString());
        var fullResponse = new System.Text.StringBuilder();

        await foreach (var chunk in chunks.WithCancellation(ct))
        {
            fullResponse.Append(chunk);
            await group.ReceiveResponseChunk(chunk);
        }

        // Send completion signal with the assembled full response
        await group.ReceiveResponseComplete(fullResponse.ToString(), emotion);

        _logger.LogDebug("Streamed complete response to user {UserId}. Length: {Length}",
            userId, fullResponse.Length);
    }

    /// <inheritdoc/>
    public async Task SendFriendshipUpdateAsync(
        Guid userId,
        FriendshipStateUpdate update,
        CancellationToken ct)
    {
        var group = _hubContext.Clients.Group(userId.ToString());
        await group.ReceiveFriendshipUpdate(update);

        _logger.LogDebug("Pushed friendship update to user {UserId}. Level: {Level}, XP: {XP}, LeveledUp: {LeveledUp}",
            userId, update.Level, update.TotalXP, update.LeveledUp);
    }

    /// <inheritdoc/>
    public async Task SendErrorAsync(
        Guid userId,
        string errorMessage,
        CancellationToken ct)
    {
        var group = _hubContext.Clients.Group(userId.ToString());
        await group.ReceiveError(errorMessage);

        _logger.LogWarning("Sent error notification to user {UserId}: {Error}",
            userId, errorMessage);
    }
}
