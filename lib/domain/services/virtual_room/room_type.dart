/// Represents the types of virtual rooms available in Momo's world.
///
/// Each room (except [cozy]) requires a minimum friendship level to unlock.
/// The unlock levels are:
/// - Cozy: always accessible (default room)
/// - Study: level 5
/// - Forest: level 10
/// - Japan: level 15
/// - Ocean: level 20
/// - Space: level 25
/// - Sky: level 30
/// - Gaming: level 35
/// - Fantasy: level 40
/// - AILab: level 45
enum RoomType {
  cozy(requiredLevel: 0),
  study(requiredLevel: 5),
  forest(requiredLevel: 10),
  japan(requiredLevel: 15),
  ocean(requiredLevel: 20),
  space(requiredLevel: 25),
  sky(requiredLevel: 30),
  gaming(requiredLevel: 35),
  fantasy(requiredLevel: 40),
  aiLab(requiredLevel: 45);

  /// The minimum friendship level required to unlock this room.
  /// A value of 0 means always accessible.
  final int requiredLevel;

  const RoomType({required this.requiredLevel});

  /// Whether this room is accessible at the given friendship level.
  bool isUnlockedAt(int friendshipLevel) => friendshipLevel >= requiredLevel;
}
