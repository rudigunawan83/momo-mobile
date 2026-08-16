/// Mood Repository Implementation
import '../../../../core/errors/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/mood_models.dart';
import '../datasources/mood_remote_data_source.dart';

class MoodRepositoryImpl {
  final MoodRemoteDataSource remoteDataSource;

  MoodRepositoryImpl({required this.remoteDataSource});

  Future<Result<MoodRecord?>> getCurrentMood() async {
    try {
      final mood = await remoteDataSource.getCurrentMood();
      return Success(mood);
    } on MomoException catch (e) {
      return Failure(exception: e, message: 'Gagal mengambil mood');
    } catch (e) {
      return Failure(exception: Exception(e), message: 'Gagal mengambil mood');
    }
  }

  Future<Result<List<MoodRecord>>> getMoodHistory({int days = 7}) async {
    try {
      final history = await remoteDataSource.getMoodHistory(days: days);
      return Success(history);
    } on MomoException catch (e) {
      return Failure(exception: e, message: 'Gagal mengambil mood history');
    } catch (e) {
      return Failure(
        exception: Exception(e),
        message: 'Gagal mengambil mood history',
      );
    }
  }

  Future<Result<MoodRecord>> recordMood({
    required String mood,
    double intensity = 0.5,
    String? note,
  }) async {
    try {
      final record = await remoteDataSource.recordMood(
        mood: mood,
        intensity: intensity,
        note: note,
      );
      return Success(record);
    } on MomoException catch (e) {
      return Failure(exception: e, message: 'Gagal rekam mood');
    } catch (e) {
      return Failure(exception: Exception(e), message: 'Gagal rekam mood');
    }
  }
}
