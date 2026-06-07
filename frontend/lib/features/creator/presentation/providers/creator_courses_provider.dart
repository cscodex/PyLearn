import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class CreatorCoursesNotifier extends Notifier<AsyncValue<void>> {
  Dio get _dio => ref.read(dioProvider);

  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<int?> createCourse(String title, String description, String difficulty) async {
    state = const AsyncValue.loading();
    try {
      final slug = title.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9\-]'), '');
      final response = await _dio.post('/creator/courses', data: {
        'title': title,
        'slug': slug,
        'description': description,
        'difficulty_level': difficulty,
        'is_published': false,
      });
      state = const AsyncValue.data(null);
      return response.data['id'];
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
      return null;
    }
  }

  Future<int?> createModule(int courseId, String title, String description) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.post('/creator/courses/$courseId/modules', data: {
        'title': title,
        'description': description,
        'order_index': 1,
      });
      state = const AsyncValue.data(null);
      return response.data['id'];
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
      return null;
    }
  }

  Future<int?> createChapter(int moduleId, String title, String description) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.post('/creator/modules/$moduleId/chapters', data: {
        'title': title,
        'description': description,
        'order_index': 1,
      });
      state = const AsyncValue.data(null);
      return response.data['id'];
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
      return null;
    }
  }

  Future<int?> createLesson(int chapterId, String title, String contentType, Map<String, dynamic> contentBody) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.post('/creator/chapters/$chapterId/lessons', data: {
        'title': title,
        'content_type': contentType,
        'content_body': contentBody,
        'order_index': 1,
        'is_premium': false,
      });
      state = const AsyncValue.data(null);
      return response.data['id'];
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
      return null;
    }
  }

  Future<bool> saveQuizQuestions(int lessonId, List<Map<String, dynamic>> questions) async {
    state = const AsyncValue.loading();
    try {
      for (var q in questions) {
        await _dio.post('/creator/lessons/$lessonId/questions', data: {
          'question_type': q['type'],
          'question_text': q['text'],
          'question_data': q['data'] ?? {},
          'points': q['points'] ?? 1,
          'order_index': 1,
          'options': q['options'] ?? [],
        });
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
      return false;
    }
  }
}

final creatorCoursesProvider = NotifierProvider<CreatorCoursesNotifier, AsyncValue<void>>(() {
  return CreatorCoursesNotifier();
});
