import 'time_period.dart';

/// Represents the ambient environment state within a virtual room.
///
/// Encapsulates all visual ambient properties: lighting, particle effects,
/// and animated objects that make the room feel alive based on the current
/// [TimePeriod].
class AmbientState {
  /// The current time-of-day period driving ambient effects.
  final TimePeriod timePeriod;

  /// Light intensity value from 0.0 (dark) to 1.0 (full brightness).
  final double lightIntensity;

  /// Warm/cool color temperature. Range: 0.0 (cool blue) to 1.0 (warm gold).
  final double colorTemperature;

  /// Whether particle effects are active (e.g., dust motes, fireflies).
  final bool particlesEnabled;

  /// Particle density from 0.0 to 1.0 when particles are enabled.
  final double particleDensity;

  /// Whether animated background objects are active.
  final bool animatedObjectsEnabled;

  /// Creates a validated [AmbientState].
  ///
  /// Throws [ArgumentError] if:
  /// - [lightIntensity] is not in `[0.0, 1.0]`
  /// - [colorTemperature] is not in `[0.0, 1.0]`
  /// - [particleDensity] is not in `[0.0, 1.0]`
  AmbientState({
    required this.timePeriod,
    required this.lightIntensity,
    required this.colorTemperature,
    this.particlesEnabled = true,
    this.particleDensity = 0.5,
    this.animatedObjectsEnabled = true,
  }) {
    if (lightIntensity < 0.0 || lightIntensity > 1.0) {
      throw ArgumentError.value(
        lightIntensity,
        'lightIntensity',
        'Must be between 0.0 and 1.0 inclusive.',
      );
    }
    if (colorTemperature < 0.0 || colorTemperature > 1.0) {
      throw ArgumentError.value(
        colorTemperature,
        'colorTemperature',
        'Must be between 0.0 and 1.0 inclusive.',
      );
    }
    if (particleDensity < 0.0 || particleDensity > 1.0) {
      throw ArgumentError.value(
        particleDensity,
        'particleDensity',
        'Must be between 0.0 and 1.0 inclusive.',
      );
    }
  }

  /// Creates an [AmbientState] appropriate for the given [TimePeriod].
  ///
  /// Default ambient configurations per period:
  /// - Morning: warm golden light, moderate particles
  /// - Afternoon: bright daylight, light particles
  /// - Evening: warm orange/sunset, firefly particles
  /// - Night: cool blue/dark, subtle particles
  factory AmbientState.forTimePeriod(TimePeriod period) {
    switch (period) {
      case TimePeriod.morning:
        return AmbientState(
          timePeriod: period,
          lightIntensity: 0.7,
          colorTemperature: 0.8, // warm golden
          particlesEnabled: true,
          particleDensity: 0.4,
          animatedObjectsEnabled: true,
        );
      case TimePeriod.afternoon:
        return AmbientState(
          timePeriod: period,
          lightIntensity: 1.0,
          colorTemperature: 0.6, // neutral-warm daylight
          particlesEnabled: true,
          particleDensity: 0.2,
          animatedObjectsEnabled: true,
        );
      case TimePeriod.evening:
        return AmbientState(
          timePeriod: period,
          lightIntensity: 0.5,
          colorTemperature: 0.9, // warm orange sunset
          particlesEnabled: true,
          particleDensity: 0.6,
          animatedObjectsEnabled: true,
        );
      case TimePeriod.night:
        return AmbientState(
          timePeriod: period,
          lightIntensity: 0.2,
          colorTemperature: 0.1, // cool blue
          particlesEnabled: true,
          particleDensity: 0.3,
          animatedObjectsEnabled: false,
        );
    }
  }

  /// Creates a copy with optional overrides.
  AmbientState copyWith({
    TimePeriod? timePeriod,
    double? lightIntensity,
    double? colorTemperature,
    bool? particlesEnabled,
    double? particleDensity,
    bool? animatedObjectsEnabled,
  }) {
    return AmbientState(
      timePeriod: timePeriod ?? this.timePeriod,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      colorTemperature: colorTemperature ?? this.colorTemperature,
      particlesEnabled: particlesEnabled ?? this.particlesEnabled,
      particleDensity: particleDensity ?? this.particleDensity,
      animatedObjectsEnabled:
          animatedObjectsEnabled ?? this.animatedObjectsEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmbientState &&
        other.timePeriod == timePeriod &&
        other.lightIntensity == lightIntensity &&
        other.colorTemperature == colorTemperature &&
        other.particlesEnabled == particlesEnabled &&
        other.particleDensity == particleDensity &&
        other.animatedObjectsEnabled == animatedObjectsEnabled;
  }

  @override
  int get hashCode => Object.hash(
        timePeriod,
        lightIntensity,
        colorTemperature,
        particlesEnabled,
        particleDensity,
        animatedObjectsEnabled,
      );

  @override
  String toString() =>
      'AmbientState(timePeriod: $timePeriod, lightIntensity: $lightIntensity, '
      'colorTemperature: $colorTemperature, particles: $particlesEnabled)';
}
