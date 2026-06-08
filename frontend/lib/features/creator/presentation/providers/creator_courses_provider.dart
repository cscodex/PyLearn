import '../../../course/domain/entities/course.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class CreatorCoursesNotifier extends Notifier<AsyncValue<List<Course>>> {
  Dio get _dio => ref.read(dioProvider);

  @override
  AsyncValue<List<Course>> build() {
    fetchCourses();
    return const AsyncValue.loading();
  }

  
  Future<void> fetchCourses() async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.get('/creator/courses');
      if (response.statusCode == 200) {
        final List data = response.data;
        final courses = data.map((e) => Course.fromJson(e)).toList();
        state = AsyncValue.data(courses);
      } else {
        state = AsyncValue.error('Failed to load courses', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
    }
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
      fetchCourses();
      return response.data['id'];
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
      return null;
    }
  }

  Future<bool> updateCourse(int id, Map<String, dynamic> data) async {
    try {
      final currentList = state.value ?? [];
      state = const AsyncValue.loading();
      final response = await ref.read(dioProvider).put('/creator/courses/$id', data: data);
      
      // Update the local list
      final updatedCourse = Course.fromJson(response.data);
      final updatedList = currentList.map((c) => c.id == id ? updatedCourse : c).toList();
      state = AsyncValue.data(updatedList);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
      return false;
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
      fetchCourses();
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
      fetchCourses();
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
      fetchCourses();
      return response.data['id'];
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
      return null;
    }
  }

  Future<bool> updateModule(int moduleId, Map<String, dynamic> data) async {
    try {
      await _dio.put('/creator/modules/$moduleId', data: data);
      fetchCourses();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteModule(int moduleId) async {
    try {
      await _dio.delete('/creator/modules/$moduleId');
      fetchCourses();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateChapter(int chapterId, Map<String, dynamic> data) async {
    try {
      await _dio.put('/creator/chapters/$chapterId', data: data);
      fetchCourses();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteChapter(int chapterId) async {
    try {
      await _dio.delete('/creator/chapters/$chapterId');
      fetchCourses();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateLesson(int lessonId, Map<String, dynamic> data) async {
    try {
      await _dio.put('/creator/lessons/$lessonId', data: data);
      fetchCourses();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteLesson(int lessonId) async {
    try {
      await _dio.delete('/creator/lessons/$lessonId');
      fetchCourses();
      return true;
    } catch (e) {
      return false;
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
      fetchCourses();
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
      return false;
    }
  }

  Future<Map<String, dynamic>?> generateCourseWithAI(String prompt, String model) async {
    state = const AsyncValue.loading();
    try {
      final response = await _dio.post('/creator/ai/generate', data: {
        'prompt': prompt,
        'model': model,
      });
      state = const AsyncValue.data([]); // reset to avoid showing loading, but fetchCourses will overwrite it eventually
      fetchCourses(); // to refetch courses
      return response.data;
    } catch (e, stack) {
      state = AsyncValue.error(e.toString(), stack);
      return null;
    }
  }
}

final creatorCoursesProvider = NotifierProvider<CreatorCoursesNotifier, AsyncValue<List<Course>>>(() {
  return CreatorCoursesNotifier();
});
