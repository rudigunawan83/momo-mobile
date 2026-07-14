import 'dart:async';

import 'ambient_state.dart';
import 'i_virtual_room_manager.dart';
import 'room_state.dart';
import 'room_type.dart';
import 'time_period.dart';

/// Callback type for loading room resources.
///
/// Implementations should load the actual room assets (Rive, images, etc).
/// Returns true on success, throws on failure.
typedef RoomResourceLoader = Future<bool> Function(RoomType roomType);

/// Manages the virtual room environment where Momo lives.
///
/// Handles:
/// - Room loading with ambient elements within 3 seconds
/// - Time-of-day effects (morning, afternoon, evening, night)
/// - Room access control based on friendship level
/// - Room transitions with 300–800ms animation at 30+ FPS
/// - Locked room handling (show required level, retain current room)
/// - Loading failure handling (show error, retain previous room)
///
/// Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6
class VirtualRoomManager implements IVirtualRoomManager {
  /// Maximum time allowed for room loading (3 seconds per Req 8.1).
  static const Duration loadTimeout = Duration(seconds: 3);

  /// Minimum room transition duration (Req 8.4).
  static const Duration minTransitionDuration = Duration(milliseconds: 300);

  /// Maximum room transition duration (Req 8.4).
  static const Duration maxTransitionDuration = Duration(milliseconds: 800);

  /// Target minimum FPS during transitions (Req 8.4).
  static const int minTransitionFps = 30;

  /// Optional resource loader for loading room assets.
  /// If null, room loading succeeds instantly (for logic-layer testing).
  final RoomResourceLoader? _resourceLoader;

  // --- State ---

  RoomState _currentState;
  int _friendshipLevel;

  // --- Streams ---

  final StreamController<RoomState> _stateController =
      StreamController<RoomState>.broadcast();

  /// Creates a [VirtualRoomManager].
  ///
  /// [friendshipLevel] determines which rooms are accessible.
  /// [resourceLoader] is an optional callback for loading room resources;
  /// if null, loading is simulated (useful for unit testing the logic layer).
  VirtualRoomManager({
    int friendshipLevel = 1,
    RoomResourceLoader? resourceLoader,
  })  : assert(friendshipLevel >= 1, 'friendshipLevel must be >= 1'),
        _friendshipLevel = friendshipLevel,
        _resourceLoader = resourceLoader,
        _currentState = RoomState(
          currentRoom: RoomType.cozy,
          ambientState: AmbientState.forTimePeriod(
            TimePeriod.fromDateTime(DateTime.now()),
          ),
        );

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  @override
  RoomState get currentState => _currentState;

  @override
  Stream<RoomState> get roomStateStream => _stateController.stream;

  @override
  int get friendshipLevel => _friendshipLevel;

  @override
  set friendshipLevel(int level) {
    if (level < 1) {
      throw ArgumentError.value(
        level,
        'friendshipLevel',
        'Must be >= 1.',
      );
    }
    _friendshipLevel = level;
  }

  @override
  List<RoomType> get availableRooms {
    return RoomType.values
        .where((room) => room.isUnlockedAt(_friendshipLevel))
        .toList();
  }

  @override
  Future<void> loadRoom(RoomType type) async {
    // --- Access control check (Req 8.3, 8.5) ---
    if (!type.isUnlockedAt(_friendshipLevel)) {
      _emitState(_currentState.copyWith(
        clearError: true,
        clearFailedRoom: true,
        lockedRoomInfo: LockedRoomInfo(
          attemptedRoom: type,
          requiredLevel: type.requiredLevel,
          currentLevel: _friendshipLevel,
        ),
      ));
      return;
    }

    // If already in this room, just refresh ambient
    if (type == _currentState.currentRoom && !_currentState.isLoading) {
      return;
    }

    // --- Begin loading (Req 8.1) ---
    _emitState(_currentState.copyWith(
      isLoading: true,
      clearError: true,
      clearLockedRoomInfo: true,
      clearFailedRoom: true,
    ));

    try {
      // Load room resources within timeout
      if (_resourceLoader != null) {
        await _resourceLoader(type).timeout(loadTimeout);
      }

      // --- Transition animation (Req 8.4) ---
      // Calculate transition duration based on room "distance"
      final transitionDuration = _calculateTransitionDuration(
        _currentState.currentRoom,
        type,
      );

      _emitState(_currentState.copyWith(
        isLoading: false,
        isTransitioning: true,
        transitionDuration: transitionDuration,
        clearError: true,
        clearLockedRoomInfo: true,
        clearFailedRoom: true,
      ));

      // Simulate transition time (in actual rendering this would be
      // handled by the animation framework)
      await Future<void>.delayed(transitionDuration);

      // --- Complete: set new room with ambient (Req 8.1, 8.2) ---
      final ambientState = AmbientState.forTimePeriod(
        TimePeriod.fromDateTime(DateTime.now()),
      );

      _emitState(RoomState(
        currentRoom: type,
        ambientState: ambientState,
        isLoading: false,
        isTransitioning: false,
        transitionDuration: transitionDuration,
      ));
    } on TimeoutException {
      // Loading timed out (exceeded 3 seconds)
      _emitState(_currentState.copyWith(
        isLoading: false,
        isTransitioning: false,
        error: 'Room loading timed out. Please try again.',
        failedRoom: type,
        clearLockedRoomInfo: true,
      ));
    } catch (e) {
      // --- Loading failure (Req 8.6): show error, retain previous room ---
      _emitState(_currentState.copyWith(
        isLoading: false,
        isTransitioning: false,
        error: 'Failed to load room: ${e.toString()}',
        failedRoom: type,
        clearLockedRoomInfo: true,
      ));
    }
  }

  @override
  void setAmbientState(AmbientState state) {
    _emitState(_currentState.copyWith(
      ambientState: state,
      clearError: true,
      clearLockedRoomInfo: true,
      clearFailedRoom: true,
    ));
  }

  @override
  void applyTimeOfDayEffect(DateTime currentTime) {
    final period = TimePeriod.fromDateTime(currentTime);
    final newAmbient = AmbientState.forTimePeriod(period);
    _emitState(_currentState.copyWith(
      ambientState: newAmbient,
      clearError: true,
      clearLockedRoomInfo: true,
      clearFailedRoom: true,
    ));
  }

  @override
  void dispose() {
    _stateController.close();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Calculates a transition duration between [minTransitionDuration] and
  /// [maxTransitionDuration] based on the "distance" between rooms.
  ///
  /// Rooms that are further apart in the enum order get longer transitions.
  Duration _calculateTransitionDuration(RoomType from, RoomType to) {
    final distance = (from.index - to.index).abs();
    final maxDistance = RoomType.values.length - 1;

    // Linearly interpolate between min and max transition duration
    final fraction = distance / maxDistance;
    final durationMs = minTransitionDuration.inMilliseconds +
        ((maxTransitionDuration.inMilliseconds -
                minTransitionDuration.inMilliseconds) *
            fraction)
            .round();

    return Duration(milliseconds: durationMs);
  }

  /// Updates internal state and emits on the stream.
  void _emitState(RoomState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }
}
