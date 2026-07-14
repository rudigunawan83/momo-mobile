import 'dart:async';

import '../engines/animation_type.dart';
import '../engines/i_character_engine.dart';
import '../entities/character_state.dart';
import '../repositories/i_chat_repository.dart';
import 'i_speech_to_text_service.dart';
import 'i_text_to_speech_service.dart';
import 'voice_state.dart';

/// Orchestrates the voice conversation flow:
/// recording → transcription → API call → synthesis → playback with lip sync.
///
/// Enforces recording duration constraints (min 0.5s, max 60s) and
/// handles failures at each stage gracefully per Requirements 2.1–2.6.
class VoiceService {
  /// Minimum recording duration before a valid submission.
  static const Duration minRecordingDuration = Duration(milliseconds: 500);

  /// Maximum recording duration before automatic stop.
  static const Duration maxRecordingDuration = Duration(seconds: 60);

  /// Maximum time allowed for STT transcription after recording stops.
  static const Duration transcriptionTimeout = Duration(seconds: 3);

  /// Maximum time allowed for TTS synthesis to begin playback.
  static const Duration synthesisTimeout = Duration(seconds: 3);

  final ISpeechToTextService _sttService;
  final ITextToSpeechService _ttsService;
  final IChatRepository _chatRepository;
  final ICharacterEngine _characterEngine;

  // --- State ---

  VoiceState _currentState = VoiceState.idle;
  VoiceError? _lastError;
  DateTime? _recordingStartTime;
  Timer? _maxDurationTimer;
  StreamSubscription<AudioPlaybackEvent>? _playbackSubscription;

  // --- Streams ---

  final StreamController<VoiceState> _stateController =
      StreamController<VoiceState>.broadcast();

  final StreamController<VoiceError> _errorController =
      StreamController<VoiceError>.broadcast();

  /// Creates a [VoiceService] with required dependencies.
  VoiceService({
    required ISpeechToTextService sttService,
    required ITextToSpeechService ttsService,
    required IChatRepository chatRepository,
    required ICharacterEngine characterEngine,
  })  : _sttService = sttService,
        _ttsService = ttsService,
        _chatRepository = chatRepository,
        _characterEngine = characterEngine;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// The current state of the voice flow.
  VoiceState get currentState => _currentState;

  /// The last error that occurred, if any.
  VoiceError? get lastError => _lastError;

  /// Stream of voice state changes.
  Stream<VoiceState> get stateStream => _stateController.stream;

  /// Stream of voice errors.
  Stream<VoiceError> get errorStream => _errorController.stream;

  /// Starts recording the user's voice.
  ///
  /// Transitions to [VoiceState.recording] and begins capturing audio.
  /// Automatically stops after [maxRecordingDuration] (60 seconds).
  ///
  /// Throws [StateError] if not in [VoiceState.idle] or [VoiceState.error].
  Future<void> startRecording() async {
    if (_currentState != VoiceState.idle &&
        _currentState != VoiceState.error) {
      throw StateError(
        'Cannot start recording in state $_currentState. '
        'Must be idle or error.',
      );
    }

    // Check STT availability
    final available = await _sttService.isAvailable;
    if (!available) {
      _emitError(VoiceError(
        type: VoiceErrorType.permissionDenied,
        message: 'Microphone is not available. Please check permissions.',
      ));
      return;
    }

    _setState(VoiceState.recording);
    _recordingStartTime = DateTime.now();

    // Start the STT service listening
    await _sttService.startListening();

    // Set up max duration timer (auto-stop at 60s)
    _maxDurationTimer?.cancel();
    _maxDurationTimer = Timer(maxRecordingDuration, () {
      _handleMaxDurationReached();
    });
  }

  /// Stops recording and processes the voice message.
  ///
  /// Validates minimum duration (0.5s), transcribes speech, sends through
  /// the AI pipeline, synthesizes response audio, and plays with lip sync.
  ///
  /// Throws [StateError] if not in [VoiceState.recording].
  Future<void> stopRecording() async {
    if (_currentState != VoiceState.recording) {
      throw StateError(
        'Cannot stop recording in state $_currentState. Must be recording.',
      );
    }

    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;

    // Check minimum duration
    final recordingDuration = DateTime.now().difference(_recordingStartTime!);
    if (recordingDuration < minRecordingDuration) {
      await _sttService.cancel();
      _emitError(VoiceError(
        type: VoiceErrorType.recordingTooShort,
        message: 'Recording too short. Please hold for at least 0.5 seconds.',
      ));
      return;
    }

    // Phase 1: Transcribe (must complete within 3 seconds)
    await _transcribe();
  }

  /// Cancels the current voice operation and returns to idle.
  Future<void> cancel() async {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    _playbackSubscription?.cancel();
    _playbackSubscription = null;

    if (_currentState == VoiceState.recording) {
      await _sttService.cancel();
    }
    if (_currentState == VoiceState.playing) {
      await _ttsService.stop();
    }

    _setState(VoiceState.idle);
  }

  /// Retries the voice flow after an error. Returns to idle state.
  void retry() {
    if (_currentState != VoiceState.error) return;
    _lastError = null;
    _setState(VoiceState.idle);
  }

  /// Disposes of all resources held by the voice service.
  void dispose() {
    _maxDurationTimer?.cancel();
    _playbackSubscription?.cancel();
    _stateController.close();
    _errorController.close();
  }

  // ---------------------------------------------------------------------------
  // Private flow stages
  // ---------------------------------------------------------------------------

  /// Phase 1: Transcribe recorded speech to text.
  /// Must submit within 3 seconds of recording release (Req 2.1).
  Future<void> _transcribe() async {
    _setState(VoiceState.transcribing);

    try {
      final result = await _sttService
          .stopListening()
          .timeout(transcriptionTimeout);

      if (!result.isSuccess || result.text.trim().isEmpty) {
        // STT failure: show message, allow retry (Req 2.5)
        _emitError(VoiceError(
          type: VoiceErrorType.transcriptionFailed,
          message: result.errorMessage ?? 'Speech not recognized. Please try again.',
        ));
        return;
      }

      // Phase 2: Process through AI pipeline
      await _processMessage(result.text);
    } on TimeoutException {
      _emitError(VoiceError(
        type: VoiceErrorType.transcriptionFailed,
        message: 'Speech recognition timed out. Please try again.',
      ));
    } catch (e) {
      _emitError(VoiceError(
        type: VoiceErrorType.transcriptionFailed,
        message: 'Speech not recognized. Please try again.',
      ));
    }
  }

  /// Phase 2: Send transcribed text through the AI chat pipeline (Req 2.2).
  Future<void> _processMessage(String transcribedText) async {
    _setState(VoiceState.processing);
    _characterEngine.setState(CharacterState.thinking);

    try {
      final response = await _chatRepository.sendVoiceMessage(
        userId: '', // userId will be injected by the repository implementation
        transcribedText: transcribedText,
      );

      // Phase 3: Synthesize response to audio
      await _synthesizeAndPlay(response.message);
    } catch (e) {
      _characterEngine.setState(CharacterState.sad);
      _emitError(VoiceError(
        type: VoiceErrorType.processingFailed,
        message: 'Failed to process your message. Please try again.',
      ));
    }
  }

  /// Phase 3: Synthesize AI response to audio and begin playback (Req 2.3).
  /// Must begin playback within 3 seconds of response generation.
  Future<void> _synthesizeAndPlay(String responseText) async {
    _setState(VoiceState.synthesizing);

    try {
      final result = await _ttsService
          .synthesize(responseText)
          .timeout(synthesisTimeout);

      if (!result.isSuccess) {
        // TTS failure: display response as text (Req 2.6)
        _emitError(VoiceError(
          type: VoiceErrorType.synthesisFailed,
          message: 'Audio playback unavailable. Response displayed as text.',
          responseText: responseText,
        ));
        return;
      }

      // Phase 4: Play audio with lip sync (Req 2.4)
      await _playWithLipSync();
    } on TimeoutException {
      // TTS timeout: display response as text (Req 2.6)
      _emitError(VoiceError(
        type: VoiceErrorType.synthesisFailed,
        message: 'Audio synthesis timed out. Response displayed as text.',
        responseText: responseText,
      ));
    } catch (e) {
      _emitError(VoiceError(
        type: VoiceErrorType.synthesisFailed,
        message: 'Audio playback unavailable. Response displayed as text.',
        responseText: responseText,
      ));
    }
  }

  /// Phase 4: Coordinate lip sync animation with audio playback (Req 2.4).
  /// Visual-to-audio offset must be < 100ms.
  Future<void> _playWithLipSync() async {
    _setState(VoiceState.playing);

    final completer = Completer<void>();

    _playbackSubscription?.cancel();
    _playbackSubscription = _ttsService.playbackStream.listen(
      (event) {
        // Coordinate lip sync with character engine.
        // The amplitude drives mouth openness for < 100ms offset.
        _characterEngine.playAnimation(
          AnimationType.lipSync,
          duration: const Duration(milliseconds: 50),
        );
      },
      onDone: () {
        _playbackSubscription?.cancel();
        _playbackSubscription = null;
        _characterEngine.setState(CharacterState.idle);
        _setState(VoiceState.idle);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (error) {
        _playbackSubscription?.cancel();
        _playbackSubscription = null;
        _characterEngine.setState(CharacterState.idle);
        _setState(VoiceState.idle);
        if (!completer.isCompleted) completer.complete();
      },
    );

    // If playback stream doesn't complete normally (no events for too long),
    // we'll timeout and return to idle
    return completer.future.timeout(
      const Duration(seconds: 120),
      onTimeout: () {
        _playbackSubscription?.cancel();
        _playbackSubscription = null;
        _characterEngine.setState(CharacterState.idle);
        _setState(VoiceState.idle);
      },
    );
  }

  /// Handles the maximum recording duration (60s) being reached.
  /// Automatically stops recording and proceeds with transcription.
  void _handleMaxDurationReached() {
    if (_currentState != VoiceState.recording) return;
    // Auto-stop and continue the flow
    stopRecording();
  }

  // ---------------------------------------------------------------------------
  // State management helpers
  // ---------------------------------------------------------------------------

  void _setState(VoiceState state) {
    _currentState = state;
    _stateController.add(state);
  }

  void _emitError(VoiceError error) {
    _lastError = error;
    _currentState = VoiceState.error;
    _stateController.add(VoiceState.error);
    _errorController.add(error);
  }

}
