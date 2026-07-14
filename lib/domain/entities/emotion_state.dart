import 'emotion_type.dart';

/// Represents Momo's emotional state at a point in time.
///
/// The Emotion Engine produces [EmotionState] values that drive the Character
/// Engine's animations and expressions. All numerical dimensions are bounded:
/// - [intensity]: How strong the emotion is, in `[0.0, 1.0]`
/// - [valence]: Positivity/negativity, in `[-1.0, 1.0]`
/// - [arousal]: Energy level, in `[0.0, 1.0]`
///
/// Validation is enforced at construction time — invalid values throw
/// [ArgumentError].
class EmotionState {
  /// The dominant emotion being expressed. Always required.
  final EmotionType primary;

  /// An optional secondary emotion for blended expressions.
  final EmotionType? secondary;

  /// Intensity of the emotion, clamped to `[0.0, 1.0]`.
  final double intensity;

  /// Emotional valence from negative (-1.0) to positive (1.0).
  final double valence;

  /// Arousal level from calm (0.0) to excited (1.0).
  final double arousal;

  /// Timestamp when this state was recorded.
  final DateTime timestamp;

  /// Creates a validated [EmotionState].
  ///
  /// Throws [ArgumentError] if:
  /// - [intensity] is not in `[0.0, 1.0]`
  /// - [valence] is not in `[-1.0, 1.0]`
  /// - [arousal] is not in `[0.0, 1.0]`
  EmotionState({
    required this.primary,
    this.secondary,
    required this.intensity,
    required this.valence,
    required this.arousal,
    required this.timestamp,
  }) {
    if (intensity < 0.0 || intensity > 1.0) {
      throw ArgumentError.value(
        intensity,
        'intensity',
        'Must be between 0.0 and 1.0 inclusive.',
      );
    }
    if (valence < -1.0 || valence > 1.0) {
      throw ArgumentError.value(
        valence,
        'valence',
        'Must be between -1.0 and 1.0 inclusive.',
      );
    }
    if (arousal < 0.0 || arousal > 1.0) {
      throw ArgumentError.value(
        arousal,
        'arousal',
        'Must be between 0.0 and 1.0 inclusive.',
      );
    }
  }

  /// Creates a copy of this state with optional field overrides.
  ///
  /// The copied state is re-validated.
  EmotionState copyWith({
    EmotionType? primary,
    EmotionType? secondary,
    double? intensity,
    double? valence,
    double? arousal,
    DateTime? timestamp,
  }) {
    return EmotionState(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      intensity: intensity ?? this.intensity,
      valence: valence ?? this.valence,
      arousal: arousal ?? this.arousal,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Creates a default neutral [EmotionState] at the current time.
  factory EmotionState.neutral() {
    return EmotionState(
      primary: EmotionType.neutral,
      intensity: 0.5,
      valence: 0.0,
      arousal: 0.3,
      timestamp: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmotionState &&
        other.primary == primary &&
        other.secondary == secondary &&
        other.intensity == intensity &&
        other.valence == valence &&
        other.arousal == arousal &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(
        primary,
        secondary,
        intensity,
        valence,
        arousal,
        timestamp,
      );

  @override
  String toString() =>
      'EmotionState(primary: $primary, intensity: $intensity, '
      'valence: $valence, arousal: $arousal)';
}
