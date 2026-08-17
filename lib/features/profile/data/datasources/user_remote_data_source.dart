/// User Remote Data Source
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/dto_models.dart';

abstract class UserRemoteDataSource {
  /// Get current user profile
  /// 
  /// Includes: basic info, XP, relationship, mood
  Future<UserProfileDto> getCurrentUser();

  /// Get user by ID
  Future<UserDto> getUserById(String userId);

  /// Update user profile
  Future<UserDto> updateProfile(Map<String, dynamic> updates);

  /// Get XP profile
  Future<XpProfileDto> getXpProfile();

  /// Get relationship profile
  Future<RelationshipDto> getRelationship();

  /// Get current mood
  Future<String?> getCurrentMood();
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final ApiClient apiClient;

  UserRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserProfileDto> getCurrentUser() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.userMe,
      );
      return UserProfileDto.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserDto> getUserById(String userId) async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        '/users/$userId',
      );
      return UserDto.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserDto> updateProfile(Map<String, dynamic> updates) async {
    try {
      final response = await apiClient.put<Map<String, dynamic>>(
        ApiEndpoints.userMe,
        data: updates,
      );
      return UserDto.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<XpProfileDto> getXpProfile() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.profileXp,
      );
      return XpProfileDto.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<RelationshipDto> getRelationship() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.profileRelationship,
      );
      return RelationshipDto.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<String?> getCurrentMood() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.moodCurrent,
      );
      return response['mood'] as String?;
    } catch (e) {
      return null; // Mood is optional
    }
  }
}

