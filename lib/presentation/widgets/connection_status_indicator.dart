import 'package:flutter/material.dart';

import '../../data/realtime/connection_state.dart';

/// Displays a connection status indicator based on the current SignalR state.
///
/// Shows different UI for each connection state:
/// - [SignalRConnectionState.connected]: Hidden (no indicator)
/// - [SignalRConnectionState.reconnecting]: Subtle reconnecting banner
/// - [SignalRConnectionState.failed]: Prominent failure banner with retry button
/// - [SignalRConnectionState.disconnected]: Hidden (initial state)
///
/// Requirements: 9.4
class ConnectionStatusIndicator extends StatelessWidget {
  /// The current SignalR connection state.
  final SignalRConnectionState connectionState;

  /// Callback invoked when the user taps the manual retry button.
  final VoidCallback? onRetry;

  const ConnectionStatusIndicator({
    super.key,
    required this.connectionState,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (connectionState) {
      case SignalRConnectionState.connected:
      case SignalRConnectionState.disconnected:
        return const SizedBox.shrink();

      case SignalRConnectionState.reconnecting:
        return _buildReconnectingBanner(context);

      case SignalRConnectionState.failed:
        return _buildFailedBanner(context);
    }
  }

  Widget _buildReconnectingBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Reconnecting...',
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Connection lost. Momo is offline.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
