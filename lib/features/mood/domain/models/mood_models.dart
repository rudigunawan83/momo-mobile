/// Mood Feature Models
class MoodRecord {
  final String id;
  final String userId;
  final String? messageId;
  final String mood;
  final double confidence;
  final double intensity;
  final String? note;
  final DateTime recordedAt;

  MoodRecord({
    required this.id,
    required this.userId,
    this.messageId,
    required this.mood,
    required this.confidence,
    required this.intensity,
    this.note,
    required this.recordedAt,
  });

  factory MoodRecord.fromJson(Map<String, dynamic> json) {
    return MoodRecord(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      messageId: json['messageId'] as String?,
      mood: json['mood'] as String? ?? 'Neutral',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.5,
      note: json['note'] as String?,
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'messageId': messageId,
        'mood': mood,
        'confidence': confidence,
        'intensity': intensity,
        'note': note,
        'recordedAt': recordedAt.toIso8601String(),
      };
}

/// Mood type constants dan display helpers
class MoodType {
  static const String veryHappy = 'VeryHappy';
  static const String happy = 'Happy';
  static const String content = 'Content';
  static const String neutral = 'Neutral';
  static const String sad = 'Sad';
  static const String anxious = 'Anxious';
  static const String angry = 'Angry';
  static const String excited = 'Excited';
  static const String tired = 'Tired';

  static const List<String> selectable = [
    veryHappy,
    happy,
    content,
    neutral,
    sad,
    anxious,
    angry,
  ];

  static String emoji(String mood) => switch (mood) {
        'VeryHappy' => '🤩',
        'Happy' => '😄',
        'Content' => '🙂',
        'Neutral' => '😐',
        'Sad' => '😢',
        'Anxious' => '😟',
        'Angry' => '😤',
        'Excited' => '🥳',
        'Tired' => '😴',
        _ => '😐',
      };

  static String label(String mood) => switch (mood) {
        'VeryHappy' => 'Sangat Senang',
        'Happy' => 'Senang',
        'Content' => 'Tenang',
        'Neutral' => 'Biasa',
        'Sad' => 'Sedih',
        'Anxious' => 'Cemas',
        'Angry' => 'Kesal',
        'Excited' => 'Semangat',
        'Tired' => 'Lelah',
        _ => 'Biasa',
      };

  static int colorValue(String mood) => switch (mood) {
        'VeryHappy' => 0xFFFFD700,
        'Happy' => 0xFF4CAF50,
        'Content' => 0xFF81C784,
        'Neutral' => 0xFF90A4AE,
        'Sad' => 0xFF5C6BC0,
        'Anxious' => 0xFFFF8A65,
        'Angry' => 0xFFEF5350,
        'Excited' => 0xFFFF4081,
        'Tired' => 0xFF78909C,
        _ => 0xFF90A4AE,
      };
}

/// Mood stats untuk insight
class MoodStats {
  final String dominantMood;
  final Map<String, int> moodCounts;
  final double averageIntensity;
  final int totalRecords;

  MoodStats({
    required this.dominantMood,
    required this.moodCounts,
    required this.averageIntensity,
    required this.totalRecords,
  });

  factory MoodStats.fromRecords(List<MoodRecord> records) {
    if (records.isEmpty) {
      return MoodStats(
        dominantMood: MoodType.neutral,
        moodCounts: {},
        averageIntensity: 0.5,
        totalRecords: 0,
      );
    }

    final counts = <String, int>{};
    double totalIntensity = 0;
    for (final r in records) {
      counts[r.mood] = (counts[r.mood] ?? 0) + 1;
      totalIntensity += r.intensity;
    }

    final dominant = counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return MoodStats(
      dominantMood: dominant,
      moodCounts: counts,
      averageIntensity: totalIntensity / records.length,
      totalRecords: records.length,
    );
  }
}
