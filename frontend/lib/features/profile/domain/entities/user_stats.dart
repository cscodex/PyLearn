class UserStats {
  final int id;
  final String fullName;
  final String email;
  final int xp;
  final int streakDays;
  final String? profilePictureUrl;

  UserStats({
    required this.id,
    required this.fullName,
    required this.email,
    required this.xp,
    required this.streakDays,
    this.profilePictureUrl,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      xp: json['xp'],
      streakDays: json['streak_days'],
      profilePictureUrl: json['profile_picture_url'],
    );
  }
}
