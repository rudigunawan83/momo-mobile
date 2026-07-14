/// Represents an outbound action queued during disconnection.
///
/// When the SignalR connection is lost, outbound actions are stored
/// in a queue and delivered once the connection is re-established.
class QueuedAction {
  /// The SignalR hub method to invoke.
  final String method;

  /// The arguments to pass to the hub method.
  final List<Object?> args;

  /// When this action was queued.
  final DateTime queuedAt;

  const QueuedAction({
    required this.method,
    required this.args,
    required this.queuedAt,
  });

  @override
  String toString() => 'QueuedAction(method: $method, queuedAt: $queuedAt)';
}
