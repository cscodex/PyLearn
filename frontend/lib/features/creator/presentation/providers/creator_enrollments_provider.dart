import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../admin/presentation/providers/admin_enrollments_provider.dart';

class CreatorEnrollmentsNotifier extends Notifier<AsyncValue<List<AdminEnrollment>>> {
  Dio get _dio => ref.read(dioProvider);

  @override
  AsyncValue<List<AdminEnrollment>> build() {
    fetchEnrollments();
    return const AsyncValue.loading();
  }

  Future<void> fetchEnrollments() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/creator/enrollments');

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

  Future<bool> assignCourseToStudent(String userId, int courseId) async {
    try {
      final response = await _dio.post(
        '/creator/enrollments/assign',
        data: {
          'user_id': userId,
          'course_id': courseId,
        },
      );
      if (response.statusCode == 200) {
        fetchEnrollments();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final creatorEnrollmentsProvider = NotifierProvider<CreatorEnrollmentsNotifier, AsyncValue<List<AdminEnrollment>>>(() {
  return CreatorEnrollmentsNotifier();
});
