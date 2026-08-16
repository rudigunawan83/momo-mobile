/// Memory Feature Models
class MemoryModel {
  final String id;
  final String userId;
  final String summary;
  final String content;
  final String type; // General, Personal, Preference, Event, Goal
  final double importanceScore;
  final bool isFavorite;
  final DateTime occurredAt;
  final DateTime createdAt;
  final List<String> tags;

  MemoryModel({
    required this.id,
    required this.userId,
    required this.summary,
    required this.content,
    required this.type,
    required this.importanceScore,
    required this.isFavorite,
    required this.occurredAt,
    required this.createdAt,
    required this.tags,
  });

  factory MemoryModel.fromJson(Map<String, dynamic> json) {
    List<String> parseTags(dynamic tagsRaw) {
      if (tagsRaw == null) return [];
      if (tagsRaw is List) return tagsRaw.map((e) => e.toString()).toList();
      return [];
    }

    return MemoryModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      summary: json['summary'] as String,
      content: json['content'] as String,
      type: json['type'] as String? ?? 'General',
      importanceScore: (json['importanceScore'] as num?)?.toDouble() ?? 0.5,
      isFavorite: json['isFavorite'] as bool? ?? false,
      occurredAt: json['occurredAt'] != null
          ? DateTime.parse(json['occurredAt'] as String)
          : DateTime.now(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      tags: parseTags(json['tags']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'summary': summary,
        'content': content,
        'type': type,
        'importanceScore': importanceScore,
        'isFavorite': isFavorite,
        'occurredAt': occurredAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'tags': tags,
      };

  MemoryModel copyWith({
    String? summary,
    String? content,
    String? type,
    double? importanceScore,
    bool? isFavorite,
    List<String>? tags,
  }) {
    return MemoryModel(
      id: id,
      userId: userId,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      type: type ?? this.type,
      importanceScore: importanceScore ?? this.importanceScore,
      isFavorite: isFavorite ?? this.isFavorite,
      occurredAt: occurredAt,
      createdAt: createdAt,
      tags: tags ?? this.tags,
    );
  }
}

/// Memory type constants dan display helpers
class MemoryType {
  static const String general = 'General';
  static const String personal = 'Personal';
  static const String preference = 'Preference';
  static const String event = 'Event';
  static const String goal = 'Goal';

  static const List<String> all = [general, personal, preference, event, goal];

  static String emoji(String type) => switch (type) {
        'Personal' => '👤',
        'Preference' => '❤️',
        'Event' => '📅',
        'Goal' => '🎯',
        _ => '💭',
      };

  static String label(String type) => switch (type) {
        'Personal' => 'Pribadi',
        'Preference' => 'Preferensi',
        'Event' => 'Kejadian',
        'Goal' => 'Tujuan',
        _ => 'Umum',
      };
}

/// Request model untuk create memory
class CreateMemoryRequest {
  final String summary;
  final String content;
  final String type;
  final double importanceScore;
  final List<String> tags;

  CreateMemoryRequest({
    required this.summary,
    required this.content,
    this.type = 'General',
    this.importanceScore = 0.5,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'content': content,
        'type': type,
        'importanceScore': importanceScore,
        'tags': tags,
      };
}
