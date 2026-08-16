/// Mission Feature Models

class Mission {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final int target;
  final int xpReward;
  final DateTime createdAt;

  Mission({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.target,
    required this.xpReward,
    required this.createdAt,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '🎯',
      category: json['category'] as String? ?? 'General',
      target: json['target'] as int? ?? 1,
      xpReward: json['xpReward'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'category': category,
        'target': target,
        'xpReward': xpReward,
        'createdAt': createdAt.toIso8601String(),
      };
}

class UserMission {
  final String id;
  final String userId;
  final String missionId;
  final Mission? mission;
  final int progress;
  final String status; // Active, Completed, Abandoned
  final DateTime? completedAt;
  final DateTime startedAt;
  final DateTime updatedAt;

  UserMission({
    required this.id,
    required this.userId,
    required this.missionId,
    this.mission,
    required this.progress,
    required this.status,
    this.completedAt,
    required this.startedAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == 'Completed';
  bool get isActive => status == 'Active';

  double get progressPercent {
    if (mission == null || mission!.target == 0) return 0;
    return (progress / mission!.target).clamp(0.0, 1.0);
  }

  factory UserMission.fromJson(Map<String, dynamic> json) {
    return UserMission(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      missionId: json['missionId'] as String,
      mission: json['mission'] != null
          ? Mission.fromJson(json['mission'] as Map<String, dynamic>)
          : null,
      progress: json['progress'] as int? ?? 0,
      status: json['status'] as String? ?? 'Active',
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'missionId': missionId,
        'progress': progress,
        'status': status,
        'completedAt': completedAt?.toIso8601String(),
        'startedAt': startedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

/// Mission category colors
class MissionCategory {
  static int colorValue(String category) => switch (category) {
        'Onboarding' => 0xFF4FA3FF,
        'Daily' => 0xFF4CAF50,
        'Chat' => 0xFF9C27B0,
        'Voice' => 0xFFFF6D00,
        'Mood' => 0xFFE91E63,
        'Memory' => 0xFF00BCD4,
        'Special' => 0xFFFFD700,
        _ => 0xFF78909C,
      };

  static String label(String category) => switch (category) {
        'Onboarding' => 'Mulai',
        'Daily' => 'Harian',
        'Chat' => 'Chat',
        'Voice' => 'Suara',
        'Mood' => 'Mood',
        'Memory' => 'Memori',
        'Special' => 'Spesial',
        _ => category,
      };
}
