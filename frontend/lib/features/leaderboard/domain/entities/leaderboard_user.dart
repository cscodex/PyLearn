class LeaderboardUser {
  final int id;
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
      id: json['id'],
      fullName: json['full_name'],
      xp: json['xp'],
      profilePictureUrl: json['profile_picture_url'],
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
      currentUserRank: json['current_user_rank'],
    );
  }
}
