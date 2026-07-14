import '../entities/emotion_state.dart';

/// Interface for the Companion Repository.
///
/// Defines the contract for retrieving and managing the companion's
/// overall state, including emotion, friendship level, and session data.
/// Used during app startup and for real-time state synchronization.
abstract class ICompanionRepository {
  /// Retrieves the current companion state from the backend.
  ///
  /// Returns a [CompanionState] containing the last known mood,
  /// friendship data, and session information.
  ///
  /// Throws if the backend is unreachable or session is invalid.
  Future<CompanionState> getCompanionState({required String userId});

  /// Retrieves the current friendship state for the user.
  ///
  /// Returns a [FriendshipState] with level, XP, streak info.
  Future<FriendshipState> getFriendshipState({required String userId});

  /// Claims the daily login reward and increments streak.
  ///
  /// Returns `true` if successfully claimed, `false` if already
  /// claimed today.
  Future<bool> claimDailyLogin({required String userId});
}

/// Represents the overall state of the Momo companion.
class CompanionState {
  /// The last known emotional state of Momo.
  final EmotionState lastEmotion;

  /// When the user last interacted with Momo.
  final DateTime lastSeenAt;

  /// Current friendship level.
  final int friendshipLevel;

  /// Total accumulated XP.
  final int totalXP;

  const CompanionState({
    required this.lastEmotion,
    required this.lastSeenAt,
    required this.friendshipLevel,
    required this.totalXP,
  });
}

/// Represents the friendship progression state.
class FriendshipState {
  /// Current friendship level (always >= 1).
  final int level;

  /// XP accumulated within the current level.
  final int currentXP;

  /// XP required to reach the next level.
  final int xpToNextLevel;

  /// Total XP accumulated across all levels.
  final int totalXP;

  /// Current consecutive daily login streak.
  final int loginStreak;

  /// Date of the last daily login claim.
  final DateTime lastLoginDate;

  /// List of achievement IDs that have been unlocked.
  final List<String> unlockedAchievements;

  const FriendshipState({
    required this.level,
    required this.currentXP,
    required this.xpToNextLevel,
    required this.totalXP,
    required this.loginStreak,
    required this.lastLoginDate,
    required this.unlockedAchievements,
  });
}
