import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/leaderboard_user.dart';

final leaderboardProvider = FutureProvider<LeaderboardResponse>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/leaderboard');
  return LeaderboardResponse.fromJson(response.data);
});
