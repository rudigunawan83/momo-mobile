/// Voice Remote Data Source — API calls untuk voice
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/voice_models.dart';

abstract class VoiceRemoteDataSource {
  /// Request LiveKit token dari backend
  Future<VoiceTokenResponse> requestVoiceToken({
    String? conversationId,
    String? roomName,
  });
}

class VoiceRemoteDataSourceImpl implements VoiceRemoteDataSource {
  final ApiClient apiClient;

  VoiceRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<VoiceTokenResponse> requestVoiceToken({
    String? conversationId,
    String? roomName,
  }) async {
    try {
      final body = <String, dynamic>{
        if (conversationId != null) 'conversationId': conversationId,
        if (roomName != null) 'roomName': roomName,
      };

      final response = await apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.voiceToken,
        data: body,
      );

      return VoiceTokenResponse.fromJson(response);
    } on MomoException {
      rethrow;
    } catch (e) {
      throw GenericException(
        message: 'Gagal mendapatkan voice token',
        originalException: e,
      );
    }
  }
}
