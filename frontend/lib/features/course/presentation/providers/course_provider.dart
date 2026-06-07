import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/course.dart';
import '../../data/repositories/course_repository.dart';

final allCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getCourses();
});

final enrolledCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getEnrolledCourses();
});

final recommendedCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getRecommendedCourses();
});

final courseDetailsProvider = FutureProvider.family<Course, int>((ref, id) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getCourseDetails(id);
});
