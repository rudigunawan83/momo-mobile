/// Mission Repository Implementation
import '../../../../core/errors/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/mission_models.dart';
import '../datasources/mission_remote_data_source.dart';

class MissionRepositoryImpl {
  final MissionRemoteDataSource remoteDataSource;

  MissionRepositoryImpl({required this.remoteDataSource});

  Future<Result<List<UserMission>>> getActiveMissions() async {
    try {
      final missions = await remoteDataSource.getActiveMissions();
      return Success(missions);
    } on MomoException catch (e) {
      return Failure(exception: e, message: 'Gagal mengambil active missions');
    } catch (e) {
      return Failure(
        exception: Exception(e),
        message: 'Gagal mengambil active missions',
      );
    }
  }

  Future<Result<List<UserMission>>> getCompletedMissions() async {
    try {
      final missions = await remoteDataSource.getCompletedMissions();
      return Success(missions);
    } on MomoException catch (e) {
      return Failure(
        exception: e,
        message: 'Gagal mengambil completed missions',
      );
    } catch (e) {
      return Failure(
        exception: Exception(e),
        message: 'Gagal mengambil completed missions',
      );
    }
  }

  Future<Result<UserMission>> updateProgress(
    String userMissionId,
    int progress,
  ) async {
    try {
      final mission = await remoteDataSource.updateProgress(
        userMissionId,
        progress,
      );
      return Success(mission);
    } on MomoException catch (e) {
      return Failure(exception: e, message: 'Gagal update progress');
    } catch (e) {
      return Failure(
        exception: Exception(e),
        message: 'Gagal update progress',
      );
    }
  }
}
