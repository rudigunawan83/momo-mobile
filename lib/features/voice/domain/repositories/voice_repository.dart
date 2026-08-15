/// Voice Repository — abstrak interface
import '../../../../core/errors/result.dart';
import '../models/voice_models.dart';

abstract class VoiceRepository {
  /// Request voice token dari server
  /// Server generate LiveKit token dengan identity dan room yang aman
  Future<Result<VoiceTokenResponse>> requestVoiceToken({
    String? conversationId,
    String? roomName,
  });

  /// Bergabung ke voice room dengan token
  Future<Result<void>> joinRoom({
    required String url,
    required String token,
  });

  /// Keluar dari voice room
  Future<Result<void>> leaveRoom();

  /// Enable/disable microphone
  Future<Result<void>> setMicrophoneEnabled(bool enabled);

  /// Enable/disable speaker
  Future<Result<void>> setSpeakerEnabled(bool enabled);

  /// Stream audio level (input = mic, output = speaker)
  Stream<double> get inputLevelStream;
  Stream<double> get outputLevelStream;

  /// Stream koneksi events
  Stream<VoiceConnectionState> get connectionStateStream;
}
