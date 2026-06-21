import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/user_stats.dart';

class ProfileNotifier extends AsyncNotifier<UserStats> {
  @override
  Future<UserStats> build() async {
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
  }

  Future<void> updateProfile(String fullName, String email) async {
    final dio = ref.read(dioProvider);
    await dio.put('/auth/profile', data: {
      'fullName': fullName,
      'email': email,
    });
    // Refresh stats since email/name changed
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateProfilePicture(String url) async {
    final dio = ref.read(dioProvider);
    await dio.put('/auth/profile', data: {
      'profilePictureUrl': url,
    });
    ref.invalidateSelf();
    await future;
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final dio = ref.read(dioProvider);
    await dio.put('/auth/password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserStats>(() {
  return ProfileNotifier();
});
