/// Input context used by [IEmotionEngine.calculateEmotion] to determine
/// the appropriate emotional state.
///
/// Contains the AI response sentiment score and time-of-day information
/// needed to compute valence, arousal, and apply sleepiness modifiers.
class EmotionContext {
  /// Sentiment score from the AI response, in `[-1.0, 1.0]`.
  ///
  /// Positive values indicate positive sentiment (happy, excited),
  /// negative values indicate negative sentiment (sad, angry).
  final double sentimentScore;

  /// The current time used for time-of-day modifiers (e.g., sleepiness).
  ///
  /// Defaults to [DateTime.now] if not provided.
  final DateTime timeOfDay;

  /// Creates an [EmotionContext].
  ///
  /// Throws [ArgumentError] if [sentimentScore] is not in `[-1.0, 1.0]`.
  EmotionContext({
    required this.sentimentScore,
    DateTime? timeOfDay,
  }) : timeOfDay = timeOfDay ?? DateTime.now() {
    if (sentimentScore < -1.0 || sentimentScore > 1.0) {
      throw ArgumentError.value(
        sentimentScore,
        'sentimentScore',
        'Must be between -1.0 and 1.0 inclusive.',
      );
    }
  }
}
