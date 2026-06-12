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

  Future<Map<String, dynamic>> executeCode(String code, {int? lessonId, String? standardInput}) async {
    try {
      final response = await dio.post('/execute/', data: {
        'code': code,
        if (standardInput != null) 'standard_input': standardInput,
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

  Future<Map<String, dynamic>> evaluateCode(String code, {int? challengeId, int? lessonId}) async {
    try {
      final response = await dio.post('/execute/evaluate', data: {
        'code': code,
        if (challengeId != null) 'challenge_id': challengeId,
        if (lessonId != null) 'lesson_id': lessonId,
      });
      return response.data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        return {
          'status': 'failed',
          'score': 0,
          'error': e.response?.data?['detail'] ?? 'Evaluation Error',
          'test_results': [],
        };
      }
      return {
        'status': 'failed',
        'score': 0,
        'error': 'Network Error: $e',
        'test_results': [],
      };
    }
  }
}
