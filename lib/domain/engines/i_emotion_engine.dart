import '../entities/emotion_state.dart';
import 'emotion_context.dart';

/// Conversation event data used by [IEmotionEngine.updateFromConversation].
class ConversationEvent {
  /// Sentiment score from the AI response, in `[-1.0, 1.0]`.
  final double sentimentScore;

  /// Timestamp of the conversation event.
  final DateTime timestamp;

  const ConversationEvent({
    required this.sentimentScore,
    required this.timestamp,
  });
}

/// Abstract interface for the Emotion Engine.
///
/// Determines Momo's emotional state based on conversation context,
/// time-of-day, and user interaction patterns. Emits emotion changes
/// reactively via [emotionStream].
abstract class IEmotionEngine {
  /// Calculates a new [EmotionState] from the given [context].
  ///
  /// Maps the AI response sentiment score to valence directly and derives
  /// arousal from the absolute value of the sentiment score. Applies
  /// time-of-day sleepiness modifiers (22:00–05:00).
  EmotionState calculateEmotion(EmotionContext context);

  /// Blends between [current] and [target] emotion states using exponential
  /// interpolation over [deltaTime] seconds.
  ///
  /// Formula: `new_value = current + (target - current) * (1 - e^(-2.0 * deltaTime))`
  ///
  /// If [deltaTime] <= 0, returns [current] unchanged.
  /// If factor evaluates to 0, returns [current]; if 1, returns [target].
  EmotionState blendEmotions(
    EmotionState current,
    EmotionState target,
    double deltaTime,
  );

  /// Updates the emotion from a conversation event and pushes the new
  /// state onto [emotionStream].
  void updateFromConversation(ConversationEvent event);

  /// Reactive stream of emotion state updates.
  Stream<EmotionState> get emotionStream;
}
