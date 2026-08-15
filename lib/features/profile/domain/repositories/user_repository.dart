/// User Repository - interface
import '../../../../core/errors/result.dart';
import '../../../../core/models/dto_models.dart';

abstract class UserRepository {
  /// Get current user profile with all related data
  Future<Result<UserProfileDto>> getCurrentUser();

  /// Get user by ID
  Future<Result<UserDto>> getUserById(String userId);

  /// Update user profile
  Future<Result<UserDto>> updateProfile(Map<String, dynamic> updates);

  /// Get XP profile
  Future<Result<XpProfileDto>> getXpProfile();

  /// Get relationship profile
  Future<Result<RelationshipDto>> getRelationship();

  /// Get current mood
  Future<Result<String?>> getCurrentMood();

  /// Get greeting message berdasarkan user data
  /// 
  /// Greeting berbeda tergantung waktu, relationship level, mood
  Future<String> getGreeting();
}
