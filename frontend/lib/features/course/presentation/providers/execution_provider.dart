import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

final executionProvider = Provider<ExecutionService>((ref) {
  final dio = ref.watch(dioProvider);
  return ExecutionService(dio);
});

class ExecutionService {
  final Dio dio;

  ExecutionService(this.dio);

  Future<Map<String, dynamic>> executeCode(String code, {int? lessonId}) async {
    try {
      final response = await dio.post('/execute/', data: {
        'code': code,
        if (lessonId != null) 'lesson_id': lessonId,
      });
      return response.data;
    } catch (e) {
      return {
        'is_success': false,
        'stdout': '',
        'stderr': 'Network Error: $e',
        'execution_time_ms': 0,
      };
    }
  }
}
