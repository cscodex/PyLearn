import re

with open("frontend/lib/features/profile/domain/entities/user_stats.dart", "r") as f:
    content = f.read()

new_content = """class UserAchievement {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final String unlockedAt;

  UserAchievement({required this.id, required this.title, required this.description, required this.iconUrl, required this.unlockedAt});

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'] ?? '',
      title: json['title'] ?? json['badgeName'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['iconUrl'] ?? json['icon_url'] ?? '',
      unlockedAt: json['unlockedAt'] ?? json['unlocked_at'] ?? '',
    );
  }
}

class UserHistory {
  final int courseId;
  final String courseTitle;
  final double progressPercentage;
  final String lastAccessedAt;

  UserHistory({required this.courseId, required this.courseTitle, required this.progressPercentage, required this.lastAccessedAt});

  factory UserHistory.fromJson(Map<String, dynamic> json) {
    return UserHistory(
      courseId: (json['courseId'] ?? json['course_id'] as num?)?.toInt() ?? 0,
      courseTitle: json['courseTitle'] ?? json['course_title'] ?? '',
      progressPercentage: (json['progressPercentage'] ?? json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      lastAccessedAt: json['lastAccessedAt'] ?? json['last_accessed_at'] ?? '',
    );
  }
}

class UserStats {
  final String id;
  final String fullName;
  final String email;
  final int xp;
  final int streakDays;
  final String profilePictureUrl;
  final List<UserAchievement> achievements;
  final List<UserHistory> history;

  UserStats({
    required this.id,
    required this.fullName,
    required this.email,
    required this.xp,
    required this.streakDays,
    required this.profilePictureUrl,
    this.achievements = const [],
    this.history = const [],
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streakDays: (json['streakDays'] ?? json['streak_days'] as num?)?.toInt() ?? 0,
      profilePictureUrl: json['profilePictureUrl'] ?? json['profile_picture_url'] ?? '',
      achievements: json['achievements'] != null ? (json['achievements'] as List).map((e) => UserAchievement.fromJson(e)).toList() : [],
      history: json['history'] != null ? (json['history'] as List).map((e) => UserHistory.fromJson(e)).toList() : [],
    );
  }
}
"""

with open("frontend/lib/features/profile/domain/entities/user_stats.dart", "w") as f:
    f.write(new_content)
