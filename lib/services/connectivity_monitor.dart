import 'dart:async';

/// Represents the current network connectivity state.
enum ConnectivityStatus {
  /// Device is connected to the network.
  online,

  /// Device has no network connectivity.
  offline,
}

/// Callback type for checking network availability.
///
/// Implementations should return `true` when the device has network access.
/// This abstraction allows testing without depending on connectivity_plus.
typedef ConnectivityChecker = Future<bool> Function();

/// Monitors network connectivity state and emits changes.
///
/// Wraps connectivity checking logic (e.g., connectivity_plus package)
/// to detect network state changes and notify listeners.
///
/// Usage:
/// ```dart
/// final monitor = ConnectivityMonitor(
///   connectivityChecker: () async => await hasInternet(),
///   checkInterval: Duration(seconds: 5),
/// );
/// monitor.statusStream.listen((status) {
///   print('Network: $status');
/// });
/// await monitor.start();
/// ```
///
/// Requirements: 10.7
class ConnectivityMonitor {
  /// Default interval between connectivity checks.
  static const Duration defaultCheckInterval = Duration(seconds: 5);

  final ConnectivityChecker _checker;
  final Duration _checkInterval;

  ConnectivityStatus _currentStatus = ConnectivityStatus.online;
  Timer? _pollingTimer;
  bool _isMonitoring = false;

  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  /// Creates a [ConnectivityMonitor].
  ///
  /// [connectivityChecker] is a callback that returns true if online.
  /// [checkInterval] determines how often connectivity is polled.
  /// [initialStatus] sets the initial assumed status before first check.
  ConnectivityMonitor({
    required ConnectivityChecker connectivityChecker,
    Duration checkInterval = defaultCheckInterval,
    ConnectivityStatus initialStatus = ConnectivityStatus.online,
  })  : _checker = connectivityChecker,
        _checkInterval = checkInterval,
        _currentStatus = initialStatus;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Current connectivity status.
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Whether the device is currently online.
  bool get isOnline => _currentStatus == ConnectivityStatus.online;

  /// Whether the device is currently offline.
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Whether monitoring is active.
  bool get isMonitoring => _isMonitoring;

  /// Stream of connectivity status changes.
  ///
  /// Only emits when the status actually changes (deduplicates).
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Starts monitoring connectivity at the configured interval.
  ///
  /// Performs an immediate check, then polls at [_checkInterval].
  Future<void> start() async {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Perform an immediate check
    await _performCheck();

    // Set up periodic polling
    _pollingTimer = Timer.periodic(_checkInterval, (_) => _performCheck());
  }

  /// Stops monitoring connectivity.
  void stop() {
    _isMonitoring = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Manually triggers a connectivity check.
  ///
  /// Useful for forcing a re-check (e.g., after user taps retry).
  Future<void> checkNow() async {
    await _performCheck();
  }

  /// Disposes all resources held by this monitor.
  void dispose() {
    stop();
    _statusController.close();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _performCheck() async {
    try {
      final isConnected = await _checker();
      final newStatus =
          isConnected ? ConnectivityStatus.online : ConnectivityStatus.offline;
      _updateStatus(newStatus);
    } catch (_) {
      // If the checker throws, assume offline
      _updateStatus(ConnectivityStatus.offline);
    }
  }

  void _updateStatus(ConnectivityStatus newStatus) {
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      if (!_statusController.isClosed) {
        _statusController.add(newStatus);
      }
    }
  }
}
