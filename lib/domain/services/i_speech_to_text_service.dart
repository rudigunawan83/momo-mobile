/// Result of a speech-to-text transcription attempt.
class TranscriptionResult {
  /// The transcribed text, or empty string if transcription failed.
  final String text;

  /// Whether transcription was successful.
  final bool isSuccess;

  /// Error message if transcription failed.
  final String? errorMessage;

  /// Confidence score of the transcription, in [0.0, 1.0].
  final double? confidence;

  const TranscriptionResult({
    required this.text,
    required this.isSuccess,
    this.errorMessage,
    this.confidence,
  });

  /// Creates a successful transcription result.
  const TranscriptionResult.success({
    required this.text,
    this.confidence,
  })  : isSuccess = true,
        errorMessage = null;

  /// Creates a failed transcription result.
  const TranscriptionResult.failure({
    required String message,
  })  : text = '',
        isSuccess = false,
        errorMessage = message,
        confidence = null;
}

/// Abstract interface for Speech-to-Text transcription.
///
/// Platform implementations will wrap native STT APIs (e.g., Google Speech,
/// Apple Speech) behind this interface for testability and flexibility.
abstract class ISpeechToTextService {
  /// Whether the STT service is currently available and initialized.
  Future<bool> get isAvailable;

  /// Starts listening for speech input.
  ///
  /// Returns a stream of partial transcription results as speech is
  /// detected. The final result will have [TranscriptionResult.isSuccess]
  /// set to true when transcription is complete.
  ///
  /// Throws [StateError] if recording is already in progress.
  Future<void> startListening();

  /// Stops listening and returns the final transcription result.
  ///
  /// Must be called after [startListening]. The result will be delivered
  /// within 3 seconds of calling this method.
  ///
  /// Returns [TranscriptionResult.failure] if no speech was recognized.
  Future<TranscriptionResult> stopListening();

  /// Cancels the current listening session without producing a result.
  Future<void> cancel();

  /// Stream of partial transcription results during active listening.
  Stream<String> get partialResults;

  /// Disposes resources held by the STT service.
  void dispose();
}
