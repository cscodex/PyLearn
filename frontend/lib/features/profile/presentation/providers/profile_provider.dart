import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/user_stats.dart';

final profileProvider = FutureProvider<UserStats>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/users/me/stats');
  return UserStats.fromJson(response.data);
});
