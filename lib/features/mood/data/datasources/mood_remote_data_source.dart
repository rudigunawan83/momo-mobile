/// Mood Remote Data Source
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/mood_models.dart';

abstract class MoodRemoteDataSource {
  Future<MoodRecord?> getCurrentMood();
  Future<List<MoodRecord>> getMoodHistory({int days = 7});
  Future<MoodRecord> recordMood({
    required String mood,
    double intensity,
    String? note,
  });
}

class MoodRemoteDataSourceImpl implements MoodRemoteDataSource {
  final ApiClient apiClient;

  MoodRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<MoodRecord?> getCurrentMood() async {
    try {
      final response = await apiClient.get<dynamic>(ApiEndpoints.mood);
      final data = response.data;
      if (data == null) return null;
      if (data is Map<String, dynamic>) {
        return MoodRecord.fromJson(data);
      }
      return null;
    } on NotFoundException {
      return null;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Gagal mengambil mood: $e');
    }
  }

  @override
  Future<List<MoodRecord>> getMoodHistory({int days = 7}) async {
    try {
      final response = await apiClient.get<dynamic>(
        '${ApiEndpoints.mood}/history',
        queryParameters: {'days': days},
      );

      final data = response.data;
      if (data is List) {
        return data
            .map((e) => MoodRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is Map && data['records'] is List) {
        return (data['records'] as List)
            .map((e) => MoodRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Gagal mengambil mood history: $e');
    }
  }

  @override
  Future<MoodRecord> recordMood({
    required String mood,
    double intensity = 0.5,
    String? note,
  }) async {
    try {
      final response = await apiClient.post<dynamic>(
        ApiEndpoints.mood,
        data: {
          'mood': mood,
          'intensity': intensity,
          if (note != null) 'note': note,
        },
      );
      return MoodRecord.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Gagal rekam mood: $e');
    }
  }
}
