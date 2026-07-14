import 'ambient_state.dart';
import 'room_state.dart';
import 'room_type.dart';

/// Interface for managing the virtual room environment where Momo lives.
///
/// Handles room switching, ambient effects, time-of-day lighting, and
/// access control based on friendship level. Room transitions animate
/// between 300–800ms while maintaining 30+ FPS.
///
/// The Cozy room is always accessible as the default starting room.
/// Other rooms require specific friendship levels to unlock.
abstract class IVirtualRoomManager {
  /// Loads and activates the specified room type.
  ///
  /// Loading includes all ambient elements (lighting, particles, animated
  /// objects) and must complete within 3 seconds.
  ///
  /// If the room is locked (friendship level too low), emits a state with
  /// [LockedRoomInfo] and retains the current room.
  ///
  /// If loading fails, emits an error state and retains the previous room.
  ///
  /// Room transitions animate with a duration between 300–800ms.
  Future<void> loadRoom(RoomType type);

  /// Sets the ambient state directly, overriding the automatic
  /// time-of-day calculation.
  void setAmbientState(AmbientState state);

  /// Applies time-of-day effects based on the given [currentTime].
  ///
  /// Determines the [TimePeriod] (morning, afternoon, evening, night)
  /// and updates ambient lighting and effects accordingly.
  void applyTimeOfDayEffect(DateTime currentTime);

  /// Stream of room state changes.
  ///
  /// Emits whenever:
  /// - A room is loaded or transitions
  /// - Ambient state changes
  /// - A loading error occurs
  /// - A locked room access is attempted
  Stream<RoomState> get roomStateStream;

  /// Returns the list of room types currently accessible at the user's
  /// friendship level.
  List<RoomType> get availableRooms;

  /// The current friendship level used for access control.
  int get friendshipLevel;

  /// Updates the friendship level, which may unlock new rooms.
  set friendshipLevel(int level);

  /// The current room state.
  RoomState get currentState;

  /// Disposes of resources held by the room manager.
  void dispose();
}
