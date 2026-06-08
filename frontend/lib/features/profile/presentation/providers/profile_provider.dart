import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/user_stats.dart';

class ProfileNotifier extends AsyncNotifier<UserStats> {
  @override
  Future<UserStats> build() async {
    final dio = ref.watch(dioProvider);
    final response = await dio.get('/users/me/stats');
    return UserStats.fromJson(response.data);
  }

  Future<void> updateProfile(String fullName, String email) async {
    final dio = ref.read(dioProvider);
    final response = await dio.put('/auth/profile', data: {
      'fullName': fullName,
      'email': email,
    });
    // Refresh stats since email/name changed
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
