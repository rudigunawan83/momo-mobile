/// LiveKit Service — wrapper tipis untuk livekit_client
/// Memisahkan LiveKit SDK dari business logic
import 'dart:async';
import 'package:livekit_client/livekit_client.dart';
import '../../domain/models/voice_models.dart';

class LiveKitService {
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  // Audio level controllers
  final _inputLevelController = StreamController<double>.broadcast();
  final _outputLevelController = StreamController<double>.broadcast();
  final _connectionStateController =
      StreamController<VoiceConnectionState>.broadcast();

  Stream<double> get inputLevelStream => _inputLevelController.stream;
  Stream<double> get outputLevelStream => _outputLevelController.stream;
  Stream<VoiceConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  bool get isConnected => _room?.connectionState == ConnectionState.connected;

  Room? get room => _room;

  /// Connect ke LiveKit room
  Future<void> connect({
    required String url,
    required String token,
    RoomOptions? options,
  }) async {
    // Disconnect existing jika ada
    await disconnect();

    _room = Room();
    _listener = _room!.createListener();

    // Listen ke room events
    _listenToRoomEvents();

    _connectionStateController.add(VoiceConnectionState.connecting);

    try {
      await _room!.connect(
        url,
        token,
        roomOptions: options ??
            const RoomOptions(
              adaptiveStream: true,
              dynacast: true,
              defaultAudioPublishOptions: AudioPublishOptions(
                name: 'microphone',
                dtx: true,
              ),
            ),
      );

      // Enable microphone saat connect
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      _connectionStateController.add(VoiceConnectionState.connected);
      _startAudioLevelMonitoring();
    } catch (e) {
      _connectionStateController.add(VoiceConnectionState.failed);
      await disconnect();
      rethrow;
    }
  }

  /// Disconnect dari room
  Future<void> disconnect() async {
    _stopAudioLevelMonitoring();
    await _listener?.dispose();
    _listener = null;

    if (_room != null) {
      _connectionStateController.add(VoiceConnectionState.disconnecting);
      await _room!.disconnect();
      await _room!.dispose();
      _room = null;
      _connectionStateController.add(VoiceConnectionState.disconnected);
    }
  }

  /// Enable/disable microphone
  Future<void> setMicrophoneEnabled(bool enabled) async {
    await _room?.localParticipant?.setMicrophoneEnabled(enabled);
  }

  /// Enable/disable speaker (untuk mute Momo)
  Future<void> setSpeakerEnabled(bool enabled) async {
    if (_room == null) return;
    // Mute/unmute semua remote participants
    for (final participant in _room!.remoteParticipants.values) {
      for (final publication in participant.audioTrackPublications) {
        final track = publication.track;
        if (track != null) {
          if (enabled) {
            await track.start();
          } else {
            await track.stop();
          }
        }
      }
    }
  }

  // ===== Private =====

  Timer? _audioLevelTimer;

  void _startAudioLevelMonitoring() {
    _audioLevelTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _updateAudioLevels(),
    );
  }

  void _stopAudioLevelMonitoring() {
    _audioLevelTimer?.cancel();
    _audioLevelTimer = null;
    _inputLevelController.add(0.0);
    _outputLevelController.add(0.0);
  }

  void _updateAudioLevels() {
    if (_room == null) return;

    // Input level dari local participant mic
    final hasMic = _room!.localParticipant?.audioTrackPublications
            .where((p) => p.track != null)
            .isNotEmpty ??
        false;
    _inputLevelController.add(hasMic ? 0.3 : 0.0);

    // Output level dari remote participants
    double maxOutputLevel = 0.0;
    for (final participant in _room!.remoteParticipants.values) {
      if (participant.audioLevel > maxOutputLevel) {
        maxOutputLevel = participant.audioLevel;
      }
    }
    _outputLevelController.add(maxOutputLevel);
  }

  void _listenToRoomEvents() {
    _listener
      ?..on<RoomDisconnectedEvent>((event) {
        _connectionStateController.add(VoiceConnectionState.disconnected);
        _stopAudioLevelMonitoring();
      })
      ..on<RoomReconnectingEvent>((event) {
        _connectionStateController.add(VoiceConnectionState.reconnecting);
      })
      ..on<RoomReconnectedEvent>((event) {
        _connectionStateController.add(VoiceConnectionState.connected);
      });
  }

  /// Dispose semua resources
  void dispose() {
    _stopAudioLevelMonitoring();
    _listener?.dispose();
    _room?.dispose();
    _inputLevelController.close();
    _outputLevelController.close();
    _connectionStateController.close();
  }
}
