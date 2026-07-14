/// Represents the current state of the SignalR connection.
///
/// Used by UI layer to display connection indicators and
/// enable/disable features based on connectivity.
enum SignalRConnectionState {
  /// Initial state before any connection attempt.
  disconnected,

  /// Actively connected and able to send/receive messages.
  connected,

  /// Connection was lost and automatic reconnection is in progress.
  reconnecting,

  /// All reconnection attempts exhausted. Manual retry required.
  failed,
}
