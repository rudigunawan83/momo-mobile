/// Voice Session Models
/// State dan data untuk LiveKit voice session

// ===== Voice Session State =====

enum VoiceConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  disconnecting,
  failed,
}

enum VoiceSessionMode {
  idle,
  listening,   // Microphone aktif, mendengar user
  processing,  // Momo sedang memproses
  speaking,    // Momo sedang berbicara (TTS)
}

/// Voice Session Data
class VoiceSession {
  final String? roomName;
  final String? token;
  final VoiceConnectionState connectionState;
  final VoiceSessionMode sessionMode;
  final bool isMicEnabled;
  final bool isSpeakerEnabled;
  final double inputLevel;   // Microphone level 0.0-1.0
  final double outputLevel;  // Speaker level 0.0-1.0
  final String? errorMessage;
  final DateTime? connectedAt;

  const VoiceSession({
    this.roomName,
    this.token,
    this.connectionState = VoiceConnectionState.disconnected,
    this.sessionMode = VoiceSessionMode.idle,
    this.isMicEnabled = true,
    this.isSpeakerEnabled = true,
    this.inputLevel = 0.0,
    this.outputLevel = 0.0,
    this.errorMessage,
    this.connectedAt,
  });

  bool get isConnected =>
      connectionState == VoiceConnectionState.connected;

  bool get isActive =>
      connectionState != VoiceConnectionState.disconnected &&
      connectionState != VoiceConnectionState.failed;

  VoiceSession copyWith({
    String? roomName,
    String? token,
    VoiceConnectionState? connectionState,
    VoiceSessionMode? sessionMode,
    bool? isMicEnabled,
    bool? isSpeakerEnabled,
    double? inputLevel,
    double? outputLevel,
    String? errorMessage,
    DateTime? connectedAt,
    bool clearError = false,
  }) {
    return VoiceSession(
      roomName: roomName ?? this.roomName,
      token: token ?? this.token,
      connectionState: connectionState ?? this.connectionState,
      sessionMode: sessionMode ?? this.sessionMode,
      isMicEnabled: isMicEnabled ?? this.isMicEnabled,
      isSpeakerEnabled: isSpeakerEnabled ?? this.isSpeakerEnabled,
      inputLevel: inputLevel ?? this.inputLevel,
      outputLevel: outputLevel ?? this.outputLevel,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }
}

/// Voice Token Response dari API
class VoiceTokenResponse {
  final String token;
  final String roomName;
  final String livekitUrl;
  final int expiresIn;

  const VoiceTokenResponse({
    required this.token,
    required this.roomName,
    required this.livekitUrl,
    required this.expiresIn,
  });

  factory VoiceTokenResponse.fromJson(Map<String, dynamic> json) {
    return VoiceTokenResponse(
      token: json['token'] as String,
      roomName: json['roomName'] as String,
      livekitUrl: json['livekitUrl'] as String? ?? '',
      expiresIn: json['expiresIn'] as int? ?? 3600,
    );
  }
}

/// Voice Transcript — real-time STT result
class VoiceTranscript {
  final String text;
  final bool isFinal;
  final double confidence;
  final DateTime timestamp;

  const VoiceTranscript({
    required this.text,
    required this.isFinal,
    this.confidence = 1.0,
    required this.timestamp,
  });
}
