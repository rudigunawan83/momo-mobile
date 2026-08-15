/// Voice Providers — Riverpod state management untuk Voice feature
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/voice_models.dart';
import '../../domain/repositories/voice_repository.dart';
import '../../data/repositories/voice_repository_impl.dart';
import '../../data/datasources/voice_remote_data_source.dart';
import '../../data/services/livekit_service.dart';
import '../../../../core/providers/core_providers.dart';

// ===== Infrastructure Providers =====

/// LiveKit Service — singleton (harus sama instance)
final liveKitServiceProvider = Provider<LiveKitService>((ref) {
  final service = LiveKitService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Voice Remote Data Source Provider
final voiceRemoteDataSourceProvider =
    Provider<VoiceRemoteDataSource>((ref) {
  return VoiceRemoteDataSourceImpl(
      apiClient: ref.watch(apiClientProvider));
});

/// Voice Repository Provider
final voiceRepositoryProvider = Provider<VoiceRepository>((ref) {
  return VoiceRepositoryImpl(
    remoteDataSource: ref.watch(voiceRemoteDataSourceProvider),
    liveKitService: ref.watch(liveKitServiceProvider),
  );
});

// ===== VoiceNotifier =====

class VoiceNotifier extends StateNotifier<VoiceSession> {
  final VoiceRepository _repository;
  StreamSubscription<VoiceConnectionState>? _connectionSub;
  StreamSubscription<double>? _inputLevelSub;
  StreamSubscription<double>? _outputLevelSub;

  VoiceNotifier({required VoiceRepository repository})
      : _repository = repository,
        super(const VoiceSession()) {
    _listenToStreams();
  }

  void _listenToStreams() {
    _connectionSub = _repository.connectionStateStream.listen((connState) {
      state = state.copyWith(connectionState: connState);
    });

    _inputLevelSub = _repository.inputLevelStream.listen((level) {
      state = state.copyWith(inputLevel: level);
    });

    _outputLevelSub = _repository.outputLevelStream.listen((level) {
      state = state.copyWith(outputLevel: level);
    });
  }

  /// Start voice session — fetch token lalu connect ke LiveKit
  Future<void> startVoiceSession({String? conversationId}) async {
    if (state.isActive) return; // Sudah aktif

    state = state.copyWith(
      connectionState: VoiceConnectionState.connecting,
      clearError: true,
    );

    // 1. Request token dari server
    final tokenResult = await _repository.requestVoiceToken(
      conversationId: conversationId,
    );

    final tokenSuccess = tokenResult.map(
      (token) => token,
      (failure) {
        state = state.copyWith(
          connectionState: VoiceConnectionState.failed,
          errorMessage: 'Gagal mendapatkan akses suara: ${failure.message}',
        );
        return null;
      },
    );

    if (tokenSuccess == null) return;

    // Update state dengan room info
    state = state.copyWith(
      roomName: tokenSuccess.roomName,
      token: tokenSuccess.token,
      sessionMode: VoiceSessionMode.listening,
    );

    // 2. Connect ke room
    final joinResult = await _repository.joinRoom(
      url: tokenSuccess.livekitUrl,
      token: tokenSuccess.token,
    );

    joinResult.map(
      (_) {
        state = state.copyWith(
          connectionState: VoiceConnectionState.connected,
          connectedAt: DateTime.now(),
          sessionMode: VoiceSessionMode.listening,
        );
      },
      (failure) {
        state = state.copyWith(
          connectionState: VoiceConnectionState.failed,
          errorMessage: 'Gagal terhubung ke voice: ${failure.message}',
        );
      },
    );
  }

  /// Stop voice session — keluar dari room
  Future<void> stopVoiceSession() async {
    if (!state.isActive) return;

    final result = await _repository.leaveRoom();
    result.map(
      (_) {
        state = const VoiceSession(); // Reset ke initial state
      },
      (_) {
        // Force reset meski ada error
        state = const VoiceSession();
      },
    );
  }

  /// Toggle microphone
  Future<void> toggleMicrophone() async {
    final newEnabled = !state.isMicEnabled;
    final result = await _repository.setMicrophoneEnabled(newEnabled);
    result.map(
      (_) {
        state = state.copyWith(isMicEnabled: newEnabled);
      },
      (failure) {
        // Tidak update state jika gagal
      },
    );
  }

  /// Toggle speaker/output
  Future<void> toggleSpeaker() async {
    final newEnabled = !state.isSpeakerEnabled;
    final result = await _repository.setSpeakerEnabled(newEnabled);
    result.map(
      (_) {
        state = state.copyWith(isSpeakerEnabled: newEnabled);
      },
      (failure) {
        // Tidak update state jika gagal
      },
    );
  }

  /// Update session mode (dari server event, misal Momo mulai berbicara)
  void setSessionMode(VoiceSessionMode mode) {
    state = state.copyWith(sessionMode: mode);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _inputLevelSub?.cancel();
    _outputLevelSub?.cancel();
    super.dispose();
  }
}

/// VoiceNotifier Provider
final voiceNotifierProvider =
    StateNotifierProvider<VoiceNotifier, VoiceSession>((ref) {
  final repository = ref.watch(voiceRepositoryProvider);
  return VoiceNotifier(repository: repository);
});

// ===== Convenience Providers =====

final isVoiceConnectedProvider = Provider<bool>((ref) {
  return ref.watch(voiceNotifierProvider).isConnected;
});

final isVoiceActiveProvider = Provider<bool>((ref) {
  return ref.watch(voiceNotifierProvider).isActive;
});

final voiceSessionModeProvider = Provider<VoiceSessionMode>((ref) {
  return ref.watch(voiceNotifierProvider).sessionMode;
});

final voiceConnectionStateProvider = Provider<VoiceConnectionState>((ref) {
  return ref.watch(voiceNotifierProvider).connectionState;
});

final isMicEnabledProvider = Provider<bool>((ref) {
  return ref.watch(voiceNotifierProvider).isMicEnabled;
});

final isSpeakerEnabledProvider = Provider<bool>((ref) {
  return ref.watch(voiceNotifierProvider).isSpeakerEnabled;
});

final inputLevelProvider = Provider<double>((ref) {
  return ref.watch(voiceNotifierProvider).inputLevel;
});

final outputLevelProvider = Provider<double>((ref) {
  return ref.watch(voiceNotifierProvider).outputLevel;
});

final voiceErrorProvider = Provider<String?>((ref) {
  return ref.watch(voiceNotifierProvider).errorMessage;
});
