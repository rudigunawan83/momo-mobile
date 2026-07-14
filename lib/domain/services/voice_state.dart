/// Represents the current state of the voice conversation flow.
///
/// The flow follows: idle → recording → transcribing → processing → synthesizing → playing → idle
/// Any state can transition to [error] on failure, and [error] transitions back to [idle].
enum VoiceState {
  /// No voice activity. Ready to accept a new recording.
  idle,

  /// Microphone is active and recording user speech.
  /// Duration constraints: min 0.5s, max 60s.
  recording,

  /// Recording complete, speech is being transcribed to text.
  transcribing,

  /// Transcribed text is being sent through the AI chat pipeline.
  processing,

  /// AI response is being synthesized to audio via TTS.
  synthesizing,

  /// Audio is playing back with lip sync animation.
  playing,

  /// An error occurred. Contains error details in [VoiceError].
  error,
}

/// Describes a voice flow error with type and user-facing message.
class VoiceError {
  /// The type of error that occurred.
  final VoiceErrorType type;

  /// User-facing error message.
  final String message;

  /// The AI response text (available when TTS fails but response exists).
  final String? responseText;

  const VoiceError({
    required this.type,
    required this.message,
    this.responseText,
  });
}

/// Types of errors that can occur during voice conversation flow.
enum VoiceErrorType {
  /// Recording was too short (< 0.5 seconds).
  recordingTooShort,

  /// Recording reached maximum duration (60 seconds).
  recordingMaxDuration,

  /// Speech-to-text failed to recognize speech.
  transcriptionFailed,

  /// AI pipeline failed to process the message.
  processingFailed,

  /// Text-to-speech synthesis failed (response available as text).
  synthesisFailed,

  /// Microphone permission denied.
  permissionDenied,

  /// Generic/unknown error.
  unknown,
}
