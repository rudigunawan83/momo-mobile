/// Represents the time-of-day periods that affect room ambient state.
///
/// Each period maps to distinct lighting and ambient effects:
/// - [morning] (06:00–11:59): warm golden light
/// - [afternoon] (12:00–16:59): bright daylight
/// - [evening] (17:00–20:59): warm orange/sunset
/// - [night] (21:00–05:59): cool blue/dark
enum TimePeriod {
  morning,
  afternoon,
  evening,
  night;

  /// Determines the time period from a given [DateTime].
  ///
  /// Uses the hour component (0–23) to classify:
  /// - 06:00–11:59 → morning
  /// - 12:00–16:59 → afternoon
  /// - 17:00–20:59 → evening
  /// - 21:00–05:59 → night
  static TimePeriod fromDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour >= 6 && hour <= 11) return TimePeriod.morning;
    if (hour >= 12 && hour <= 16) return TimePeriod.afternoon;
    if (hour >= 17 && hour <= 20) return TimePeriod.evening;
    return TimePeriod.night;
  }

  /// Human-readable description of the ambient lighting for this period.
  String get lightingDescription {
    switch (this) {
      case TimePeriod.morning:
        return 'Warm golden light';
      case TimePeriod.afternoon:
        return 'Bright daylight';
      case TimePeriod.evening:
        return 'Warm orange/sunset';
      case TimePeriod.night:
        return 'Cool blue/dark';
    }
  }
}
