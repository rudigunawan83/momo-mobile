/// Memory Repository Implementation
import '../../../../core/errors/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/memory_models.dart';
import '../datasources/memory_remote_data_source.dart';

class MemoryRepositoryImpl {
  final MemoryRemoteDataSource remoteDataSource;

  MemoryRepositoryImpl({required this.remoteDataSource});

  Future<Result<List<MemoryModel>>> getMemories({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final memories = await remoteDataSource.getMemories(
        limit: limit,
        offset: offset,
      );
      return Success(memories);
    } on MomoException catch (e) {
      return Failure(exception: e, message: 'Gagal mengambil memories');
    } catch (e) {
      return Failure(
        exception: Exception(e),
        message: 'Gagal mengambil memories',
      );
    }
  }

  Future<Result<MemoryModel>> createMemory(
    CreateMemoryRequest request,
  ) async {
    try {
      final memory = await remoteDataSource.createMemory(request);
      return Success(memory);
    } on MomoException catch (e) {
      return Failure(exception: e, message: 'Gagal membuat memory');
    } catch (e) {
      return Failure(exception: Exception(e), message: 'Gagal membuat memory');
    }
  }

  Future<Result<MemoryModel>> updateMemory(
    String id,
    CreateMemoryRequest request,
  ) async {
    try {
      final memory = await remoteDataSource.updateMemory(id, request);
      return Success(memory);
    } on MomoException catch (e) {
      return Failure(exception: e, message: 'Gagal update memory');
    } catch (e) {
      return Failure(exception: Exception(e), message: 'Gagal update memory');
    }
  }

  Future<Result<void>> deleteMemory(String id) async {
    try {
      await remoteDataSource.deleteMemory(id);
      return Success(null);
    } on MomoException catch (e) {
      return Failure(exception: e, message: 'Gagal hapus memory');
    } catch (e) {
      return Failure(exception: Exception(e), message: 'Gagal hapus memory');
    }
  }

  Future<Result<MemoryModel>> toggleFavorite(
    String id,
    bool isFavorite,
  ) async {
    try {
      final memory = await remoteDataSource.toggleFavorite(id, isFavorite);
      return Success(memory);
    } on MomoException catch (e) {
      return Failure(exception: e, message: 'Gagal update favorite');
    } catch (e) {
      return Failure(
        exception: Exception(e),
        message: 'Gagal update favorite',
      );
    }
  }
}
