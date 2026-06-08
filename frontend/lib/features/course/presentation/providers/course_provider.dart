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
  final course = await repository.getCourseDetails(id);
  
  // Fetch progress if enrolled
  final progress = await repository.getCourseProgress(id);
  
  return course.copyWith(
    progressPercentage: progress['progress_percentage']?.toDouble() ?? 0.0,
    completedLessonIds: List<int>.from(progress['completed_lesson_ids'] ?? []),
  );
});
