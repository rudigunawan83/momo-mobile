/// DTOs (Data Transfer Objects) untuk API responses
/// Dipisah dari Domain entities untuk menjaga clean architecture

/// User DTO untuk API responses
class UserDto {
  final String id;
  final String name;
  final String nickname;
  final String? email;
  final String? avatar;
  final String language;
  final String timezone;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserDto({
    required this.id,
    required this.name,
    required this.nickname,
    this.email,
    this.avatar,
    this.language = 'id-ID',
    this.timezone = 'Asia/Jakarta',
    required this.createdAt,
    this.updatedAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String? ?? json['name'] as String,
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
      language: json['language'] as String? ?? 'id-ID',
      timezone: json['timezone'] as String? ?? 'Asia/Jakarta',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nickname': nickname,
    'email': email,
    'avatar': avatar,
    'language': language,
    'timezone': timezone,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

/// XP Profile DTO
class XpProfileDto {
  final int level;
  final int xp;
  final int nextLevelXp;
  final double progress;

  XpProfileDto({
    required this.level,
    required this.xp,
    required this.nextLevelXp,
    required this.progress,
  });

  factory XpProfileDto.fromJson(Map<String, dynamic> json) {
    return XpProfileDto(
      level: json['level'] as int,
      xp: json['xp'] as int,
      nextLevelXp: json['nextLevelXp'] as int,
      progress: (json['progress'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'xp': xp,
    'nextLevelXp': nextLevelXp,
    'progress': progress,
  };
}

/// Relationship DTO
class RelationshipDto {
  final int level;
  final String title;
  final double progress;
  final String? description;

  RelationshipDto({
    required this.level,
    required this.title,
    required this.progress,
    this.description,
  });

  factory RelationshipDto.fromJson(Map<String, dynamic> json) {
    return RelationshipDto(
      level: json['level'] as int,
      title: json['title'] as String,
      progress: (json['progress'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'title': title,
    'progress': progress,
    'description': description,
  };
}

/// Extended User DTO dengan profile info
class UserProfileDto extends UserDto {
  final XpProfileDto? xpProfile;
  final RelationshipDto? relationship;
  final String? currentMood;

  UserProfileDto({
    required super.id,
    required super.name,
    required super.nickname,
    super.email,
    super.avatar,
    super.language,
    super.timezone,
    required super.createdAt,
    super.updatedAt,
    this.xpProfile,
    this.relationship,
    this.currentMood,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      id: json['id'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String? ?? json['name'] as String,
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
      language: json['language'] as String? ?? 'id-ID',
      timezone: json['timezone'] as String? ?? 'Asia/Jakarta',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      xpProfile: json['xpProfile'] != null
          ? XpProfileDto.fromJson(json['xpProfile'] as Map<String, dynamic>)
          : null,
      relationship: json['relationship'] != null
          ? RelationshipDto.fromJson(json['relationship'] as Map<String, dynamic>)
          : null,
      currentMood: json['currentMood'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'xpProfile': xpProfile?.toJson(),
    'relationship': relationship?.toJson(),
    'currentMood': currentMood,
  };
}
