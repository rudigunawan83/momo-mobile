import 'ambient_state.dart';
import 'room_type.dart';
import 'time_period.dart';

/// Represents the current state of the virtual room environment.
///
/// Emitted on [IVirtualRoomManager.roomStateStream] whenever the room state
/// changes (room load, transition, ambient update, or error).
class RoomState {
  /// The currently active room type.
  final RoomType currentRoom;

  /// The current ambient state (lighting, particles, etc).
  final AmbientState ambientState;

  /// Whether the room is currently loading.
  final bool isLoading;

  /// Whether a room transition animation is in progress.
  final bool isTransitioning;

  /// Duration of the current/last transition animation.
  final Duration? transitionDuration;

  /// Error message if the last operation failed, null otherwise.
  final String? error;

  /// The room that was attempted but failed to load, if any.
  final RoomType? failedRoom;

  /// Information about a locked room access attempt.
  final LockedRoomInfo? lockedRoomInfo;

  const RoomState({
    required this.currentRoom,
    required this.ambientState,
    this.isLoading = false,
    this.isTransitioning = false,
    this.transitionDuration,
    this.error,
    this.failedRoom,
    this.lockedRoomInfo,
  });

  /// Creates the initial default room state (Cozy room, morning ambient).
  factory RoomState.initial() {
    return RoomState(
      currentRoom: RoomType.cozy,
      ambientState: AmbientState.forTimePeriod(TimePeriod.morning),
    );
  }

  /// Creates a copy with optional overrides.
  RoomState copyWith({
    RoomType? currentRoom,
    AmbientState? ambientState,
    bool? isLoading,
    bool? isTransitioning,
    Duration? transitionDuration,
    String? error,
    RoomType? failedRoom,
    LockedRoomInfo? lockedRoomInfo,
    bool clearError = false,
    bool clearLockedRoomInfo = false,
    bool clearFailedRoom = false,
    bool clearTransitionDuration = false,
  }) {
    return RoomState(
      currentRoom: currentRoom ?? this.currentRoom,
      ambientState: ambientState ?? this.ambientState,
      isLoading: isLoading ?? this.isLoading,
      isTransitioning: isTransitioning ?? this.isTransitioning,
      transitionDuration: clearTransitionDuration
          ? null
          : (transitionDuration ?? this.transitionDuration),
      error: clearError ? null : (error ?? this.error),
      failedRoom: clearFailedRoom ? null : (failedRoom ?? this.failedRoom),
      lockedRoomInfo: clearLockedRoomInfo
          ? null
          : (lockedRoomInfo ?? this.lockedRoomInfo),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomState &&
        other.currentRoom == currentRoom &&
        other.ambientState == ambientState &&
        other.isLoading == isLoading &&
        other.isTransitioning == isTransitioning &&
        other.transitionDuration == transitionDuration &&
        other.error == error &&
        other.failedRoom == failedRoom &&
        other.lockedRoomInfo == lockedRoomInfo;
  }

  @override
  int get hashCode => Object.hash(
        currentRoom,
        ambientState,
        isLoading,
        isTransitioning,
        transitionDuration,
        error,
        failedRoom,
        lockedRoomInfo,
      );

  @override
  String toString() =>
      'RoomState(room: $currentRoom, loading: $isLoading, '
      'transitioning: $isTransitioning, error: $error)';
}

/// Information displayed when a user attempts to access a locked room.
class LockedRoomInfo {
  /// The room that the user attempted to access.
  final RoomType attemptedRoom;

  /// The friendship level required to unlock the room.
  final int requiredLevel;

  /// The user's current friendship level.
  final int currentLevel;

  const LockedRoomInfo({
    required this.attemptedRoom,
    required this.requiredLevel,
    required this.currentLevel,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LockedRoomInfo &&
        other.attemptedRoom == attemptedRoom &&
        other.requiredLevel == requiredLevel &&
        other.currentLevel == currentLevel;
  }

  @override
  int get hashCode => Object.hash(attemptedRoom, requiredLevel, currentLevel);

  @override
  String toString() =>
      'LockedRoomInfo(room: $attemptedRoom, required: $requiredLevel, '
      'current: $currentLevel)';
}
