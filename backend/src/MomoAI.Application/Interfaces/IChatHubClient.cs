namespace MomoAI.Application.Interfaces;

/// <summary>
/// Defines the SignalR client-side methods that the server can invoke on connected clients.
/// Used for streaming AI responses and pushing friendship state updates in real-time.
/// </summary>
public interface IChatHubClient
{
    /// <summary>
    /// Receives a streaming AI response chunk from the server.
    /// Each chunk should arrive within 300ms of generation.
    /// </summary>
    /// <param name="chunk">A partial text chunk of the AI response.</param>
    Task ReceiveResponseChunk(string chunk);

    /// <summary>
    /// Signals that the full AI response has been transmitted.
    /// Sent after the last ReceiveResponseChunk call for a given message.
    /// </summary>
    /// <param name="fullResponse">The complete assembled response text.</param>
    /// <param name="emotion">The detected emotion for the response.</param>
    Task ReceiveResponseComplete(string fullResponse, string emotion);

    /// <summary>
    /// Pushes a friendship state update to the client.
    /// Triggered on XP gain, level up, or achievement unlock — delivered within 500ms.
    /// </summary>
    /// <param name="update">The updated friendship state data.</param>
    Task ReceiveFriendshipUpdate(FriendshipStateUpdate update);

    /// <summary>
    /// Notifies the client that an error occurred during streaming.
    /// </summary>
    /// <param name="errorMessage">A user-friendly error description.</param>
    Task ReceiveError(string errorMessage);
}

/// <summary>
/// DTO for friendship state updates pushed via SignalR.
/// </summary>
public record FriendshipStateUpdate
{
    public int Level { get; init; }
    public int CurrentXP { get; init; }
    public int XPToNextLevel { get; init; }
    public int TotalXP { get; init; }
    public int XpGained { get; init; }
    public bool LeveledUp { get; init; }
    public List<string> NewAchievements { get; init; } = new();
    public string UpdateReason { get; init; } = string.Empty;
}
