/// Abstract interface for Text-to-Speech synthesis.
///
/// Platform implementations will wrap native TTS APIs (e.g., Google TTS,
/// Apple AVSpeechSynthesizer) behind this interface for testability.
abstract class ITextToSpeechService {
  /// Whether the TTS service is currently available and initialized.
  Future<bool> get isAvailable;

  /// Synthesizes the given [text] to audio and begins playback.
  ///
  /// Returns a [SynthesisResult] containing the audio stream and metadata.
  /// Playback should begin within 3 seconds of calling this method.
  ///
  /// Throws [StateError] if synthesis is already in progress.
  Future<SynthesisResult> synthesize(String text);

  /// Stops any ongoing audio playback.
  Future<void> stop();

  /// Whether audio is currently being played.
  bool get isPlaying;

  /// Stream of playback progress, emitting normalized values in [0.0, 1.0].
  /// Used for lip sync coordination.
  Stream<AudioPlaybackEvent> get playbackStream;

  /// Disposes resources held by the TTS service.
  void dispose();
}

/// Result of a text-to-speech synthesis operation.
class SynthesisResult {
  /// Whether synthesis was successful.
  final bool isSuccess;

  /// Error message if synthesis failed.
  final String? errorMessage;

  /// Duration of the synthesized audio.
  final Duration? duration;

  const SynthesisResult({
    required this.isSuccess,
    this.errorMessage,
    this.duration,
  });

  /// Creates a successful synthesis result.
  const SynthesisResult.success({required this.duration})
      : isSuccess = true,
        errorMessage = null;

  /// Creates a failed synthesis result.
  const SynthesisResult.failure({required String message})
      : isSuccess = false,
        errorMessage = message,
        duration = null;
}

/// Audio playback event emitted during TTS playback.
///
/// Contains timing information for lip sync coordination.
class AudioPlaybackEvent {
  /// Current playback position.
  final Duration position;

  /// Total duration of the audio.
  final Duration totalDuration;

  /// Normalized amplitude/volume at current position, in [0.0, 1.0].
  /// Used for lip sync mouth openness.
  final double amplitude;

  /// Whether this is the final event (playback complete).
  final bool isComplete;

  const AudioPlaybackEvent({
    required this.position,
    required this.totalDuration,
    required this.amplitude,
    this.isComplete = false,
  });

  /// Normalized progress in [0.0, 1.0].
  double get progress =>
      totalDuration.inMilliseconds > 0
          ? position.inMilliseconds / totalDuration.inMilliseconds
          : 0.0;
}
