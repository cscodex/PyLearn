import re

with open("frontend/lib/features/profile/presentation/providers/profile_provider.dart", "r") as f:
    content = f.read()

old_build = """  Future<UserStats> build() async {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/users/me/stats');
    return UserStats.fromJson(response.data);
  }"""

new_build = """  Future<UserStats> build() async {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/users/me/stats');
    Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
    
    try {
      final achievementsRes = await dio.get('/users/me/achievements');
      data['achievements'] = achievementsRes.data;
    } catch (_) {}

    try {
      final historyRes = await dio.get('/users/me/history');
      data['history'] = historyRes.data;
    } catch (_) {}

    return UserStats.fromJson(data);
  }"""

content = content.replace(old_build, new_build)

with open("frontend/lib/features/profile/presentation/providers/profile_provider.dart", "w") as f:
    f.write(content)
