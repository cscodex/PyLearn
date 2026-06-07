import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/course.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CourseRepository(dio);
});

class CourseRepository {
  final Dio _dio;

  CourseRepository(this._dio);

  Future<List<Course>> getCourses() async {
    try {
      final response = await _dio.get('/courses/');
      return (response.data as List)
          .map((json) => Course.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch courses: $e');
    }
  }

  Future<List<Course>> getEnrolledCourses() async {
    try {
      final response = await _dio.get('/courses/enrolled');
      return (response.data as List)
          .map((json) => Course.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch enrolled courses: $e');
    }
  }

  Future<List<Course>> getRecommendedCourses() async {
    try {
      final response = await _dio.get('/courses/recommended');
      return (response.data as List)
          .map((json) => Course.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recommended courses: $e');
    }
  }

  Future<Course> getCourseDetails(int id) async {
    try {
      final response = await _dio.get('/courses/$id');
      return Course.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch course details: $e');
    }
  }

  Future<bool> enrollInCourse(int id) async {
    try {
      final response = await _dio.post('/courses/$id/enroll');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
