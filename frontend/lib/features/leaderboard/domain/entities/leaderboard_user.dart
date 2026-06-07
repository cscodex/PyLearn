class LeaderboardUser {
  final String id;
  final String fullName;
  final int xp;
  final String? profilePictureUrl;
  final int rank;

  LeaderboardUser({
    required this.id,
    required this.fullName,
    required this.xp,
    this.profilePictureUrl,
    required this.rank,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? 'User',
      xp: json['xp'],
      profilePictureUrl: json['profilePictureUrl'] ?? json['profile_picture_url'],
      rank: json['rank'],
    );
  }
}

class LeaderboardResponse {
  final List<LeaderboardUser> users;
  final int? currentUserRank;

  LeaderboardResponse({
    required this.users,
    this.currentUserRank,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      users: (json['users'] as List).map((e) => LeaderboardUser.fromJson(e)).toList(),
      currentUserRank: json['currentUserRank'] ?? json['current_user_rank'],
    );
  }
}
