/// Base models untuk aplikasi Momo AI

/// User model
class User {
  final String id;
  final String name;
  final String nickname;
  final String? email;
  final String? avatar;
  final String language;
  final String timezone;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
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

  Map<String, dynamic> toJson() {
    return {
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
}

/// Chat Message model
class ChatMessage {
  final String id;
  final String conversationId;
  final String role; // user, assistant, system, tool
  final String content;
  final DateTime createdAt;
  final String? mood;
  final String? intent;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.mood,
    this.intent,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      mood: json['mood'] as String?,
      intent: json['intent'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'mood': mood,
      'intent': intent,
      'metadata': metadata,
    };
  }
}

/// Conversation model
class Conversation {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int messageCount;
  final List<ChatMessage>? messages;

  Conversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    this.updatedAt,
    this.messageCount = 0,
    this.messages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? 'Percakapan baru',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      messageCount: json['messageCount'] as int? ?? 0,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'messageCount': messageCount,
      'messages': messages?.map((m) => m.toJson()).toList(),
    };
  }
}

/// XP/Level model
class XpProfile {
  final int level;
  final int xp;
  final int nextLevelXp;
  final double progress;

  XpProfile({
    required this.level,
    required this.xp,
    required this.nextLevelXp,
    required this.progress,
  });

  factory XpProfile.fromJson(Map<String, dynamic> json) {
    return XpProfile(
      level: json['level'] as int,
      xp: json['xp'] as int,
      nextLevelXp: json['nextLevelXp'] as int,
      progress: (json['progress'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'xp': xp,
      'nextLevelXp': nextLevelXp,
      'progress': progress,
    };
  }
}

/// Relationship model
class Relationship {
  final int level;
  final String title;
  final double progress;
  final String? description;

  Relationship({
    required this.level,
    required this.title,
    required this.progress,
    this.description,
  });

  factory Relationship.fromJson(Map<String, dynamic> json) {
    return Relationship(
      level: json['level'] as int,
      title: json['title'] as String,
      progress: (json['progress'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'title': title,
      'progress': progress,
      'description': description,
    };
  }
}

/// Mood model
class Mood {
  final String mood;
  final double confidence;
  final String? explanation;

  Mood({
    required this.mood,
    required this.confidence,
    this.explanation,
  });

  factory Mood.fromJson(Map<String, dynamic> json) {
    return Mood(
      mood: json['mood'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mood': mood,
      'confidence': confidence,
      'explanation': explanation,
    };
  }
}
