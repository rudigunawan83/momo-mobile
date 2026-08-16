/// Memory Remote Data Source
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/memory_models.dart';

abstract class MemoryRemoteDataSource {
  Future<List<MemoryModel>> getMemories({int limit = 50, int offset = 0});
  Future<MemoryModel> createMemory(CreateMemoryRequest request);
  Future<MemoryModel> updateMemory(String id, CreateMemoryRequest request);
  Future<void> deleteMemory(String id);
  Future<MemoryModel> toggleFavorite(String id, bool isFavorite);
}

class MemoryRemoteDataSourceImpl implements MemoryRemoteDataSource {
  final ApiClient apiClient;

  MemoryRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<MemoryModel>> getMemories({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.memory,
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final data = response.data;
      if (data is Map) {
        final list = data['memories'] as List<dynamic>? ?? [];
        return list
            .map((e) => MemoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is List) {
        return data
            .map((e) => MemoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Gagal mengambil memories: $e');
    }
  }

  @override
  Future<MemoryModel> createMemory(CreateMemoryRequest request) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.memory,
        data: request.toJson(),
      );
      return MemoryModel.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Gagal membuat memory: $e');
    }
  }

  @override
  Future<MemoryModel> updateMemory(
    String id,
    CreateMemoryRequest request,
  ) async {
    try {
      final response = await apiClient.put(
        '${ApiEndpoints.memory}/$id',
        data: request.toJson(),
      );
      return MemoryModel.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Gagal update memory: $e');
    }
  }

  @override
  Future<void> deleteMemory(String id) async {
    try {
      await apiClient.delete('${ApiEndpoints.memory}/$id');
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Gagal hapus memory: $e');
    }
  }

  @override
  Future<MemoryModel> toggleFavorite(String id, bool isFavorite) async {
    try {
      final response = await apiClient.patch(
        '${ApiEndpoints.memory}/$id/favorite',
        data: {'isFavorite': isFavorite},
      );
      return MemoryModel.fromJson(response.data as Map<String, dynamic>);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Gagal update favorite: $e');
    }
  }
}
