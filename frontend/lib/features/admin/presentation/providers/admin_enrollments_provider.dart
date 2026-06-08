import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class AdminEnrollment {
  final int id;
  final String userId;
  final String userName;
  final int courseId;
  final String courseTitle;
  final String enrolledAt;
  final String status;
  final double progressPercentage;

  AdminEnrollment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.courseId,
    required this.courseTitle,
    required this.enrolledAt,
    required this.status,
    required this.progressPercentage,
  });

  factory AdminEnrollment.fromJson(Map<String, dynamic> json) {
    return AdminEnrollment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: json['userName'] ?? json['user_name'] ?? 'Unknown User',
      courseId: (json['courseId'] ?? json['course_id'] as num?)?.toInt() ?? 0,
      courseTitle: json['courseTitle'] ?? json['course_title'] ?? 'Unknown Course',
      enrolledAt: json['enrolledAt'] ?? json['enrolled_at'] ?? '',
      status: json['status'] ?? 'unknown',
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AdminEnrollmentsNotifier extends Notifier<AsyncValue<List<AdminEnrollment>>> {
  Dio get _dio => ref.read(dioProvider);

  @override
  AsyncValue<List<AdminEnrollment>> build() {
    fetchEnrollments();
    return const AsyncValue.loading();
  }

  Future<void> fetchEnrollments() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/admin/enrollments');

      if (response.statusCode == 200) {
        final List data = response.data;
        final enrollments = data.map((e) => AdminEnrollment.fromJson(e)).toList();
        state = AsyncValue.data(enrollments);
      } else {
        state = AsyncValue.error('Failed to load enrollments', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
    }
  }
}

final adminEnrollmentsProvider = NotifierProvider<AdminEnrollmentsNotifier, AsyncValue<List<AdminEnrollment>>>(() {
  return AdminEnrollmentsNotifier();
});
