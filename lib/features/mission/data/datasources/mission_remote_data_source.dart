/// Mission Remote Data Source
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/mission_models.dart';

abstract class MissionRemoteDataSource {
  Future<List<UserMission>> getActiveMissions();
  Future<List<UserMission>> getCompletedMissions();
  Future<List<Mission>> getAllMissions();
  Future<UserMission> updateProgress(String userMissionId, int progress);
}

class MissionRemoteDataSourceImpl implements MissionRemoteDataSource {
  final ApiClient apiClient;

  MissionRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<UserMission>> getActiveMissions() async {
    try {
      final response = await apiClient.get<dynamic>(
        '${ApiEndpoints.missions}/active',
      );

      final data = response.data;
      if (data is List) {
        return data
            .map((e) => UserMission.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is Map && data['missions'] is List) {
        return (data['missions'] as List)
            .map((e) => UserMission.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Gagal mengambil active missions: $e');
    }
  }

  @override
  Future<List<UserMission>> getCompletedMissions() async {
    try {
      final response = await apiClient.get<dynamic>(
        '${ApiEndpoints.missions}/completed',
      );

      final data = response.data;
      if (data is List) {
        return data
            .map((e) => UserMission.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is Map && data['missions'] is List) {
        return (data['missions'] as List)
            .map((e) => UserMission.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Gagal mengambil completed missions: $e');
    }
  }

  @override
  Future<List<Mission>> getAllMissions() async {
    try {
      final response = await apiClient.get<dynamic>(ApiEndpoints.missions);
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => Mission.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is Map && data['missions'] is List) {
        return (data['missions'] as List)
            .map((e) => Mission.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Gagal mengambil missions: $e');
    }
  }

  @override
  Future<UserMission> updateProgress(
    String userMissionId,
    int progress,
  ) async {
    try {
      final response = await apiClient.patch<dynamic>(
        '${ApiEndpoints.missions}/$userMissionId/progress',
        data: {'progress': progress},
      );
      return UserMission.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Gagal update progress: $e');
    }
  }
}
