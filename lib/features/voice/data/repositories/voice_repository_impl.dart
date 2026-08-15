/// Voice Repository Implementation
import '../../domain/repositories/voice_repository.dart';
import '../../domain/models/voice_models.dart';
import '../datasources/voice_remote_data_source.dart';
import '../services/livekit_service.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/config/env_config.dart';

class VoiceRepositoryImpl implements VoiceRepository {
  final VoiceRemoteDataSource remoteDataSource;
  final LiveKitService liveKitService;

  VoiceRepositoryImpl({
    required this.remoteDataSource,
    required this.liveKitService,
  });

  @override
  Future<Result<VoiceTokenResponse>> requestVoiceToken({
    String? conversationId,
    String? roomName,
  }) async {
    try {
      final token = await remoteDataSource.requestVoiceToken(
        conversationId: conversationId,
        roomName: roomName,
      );
      return Result.success(token);
    } on MomoException catch (e) {
      return Result.failure(
        exception: e,
        message: 'Gagal mendapatkan akses suara',
      );
    } catch (e) {
      return Result.failure(
        exception: Exception(e.toString()),
        message: 'Gagal mendapatkan akses suara',
      );
    }
  }

  @override
  Future<Result<void>> joinRoom({
    required String url,
    required String token,
  }) async {
    try {
      // Gunakan url dari response atau fallback ke env config
      final livekitUrl = url.isNotEmpty ? url : EnvConfig.liveKitUrl;
      await liveKitService.connect(url: livekitUrl, token: token);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        exception: Exception(e.toString()),
        message: 'Gagal menghubungkan ke voice room',
      );
    }
  }

  @override
  Future<Result<void>> leaveRoom() async {
    try {
      await liveKitService.disconnect();
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        exception: Exception(e.toString()),
        message: 'Gagal keluar dari voice room',
      );
    }
  }

  @override
  Future<Result<void>> setMicrophoneEnabled(bool enabled) async {
    try {
      await liveKitService.setMicrophoneEnabled(enabled);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        exception: Exception(e.toString()),
        message: 'Gagal mengatur microphone',
      );
    }
  }

  @override
  Future<Result<void>> setSpeakerEnabled(bool enabled) async {
    try {
      await liveKitService.setSpeakerEnabled(enabled);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        exception: Exception(e.toString()),
        message: 'Gagal mengatur speaker',
      );
    }
  }

  @override
  Stream<double> get inputLevelStream => liveKitService.inputLevelStream;

  @override
  Stream<double> get outputLevelStream => liveKitService.outputLevelStream;

  @override
  Stream<VoiceConnectionState> get connectionStateStream =>
      liveKitService.connectionStateStream;
}
