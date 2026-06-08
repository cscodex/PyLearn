import 'package:freezed_annotation/freezed_annotation.dart';

part 'course.freezed.dart';
part 'course.g.dart';

@freezed
abstract class Course with _$Course {
  const factory Course({
    required int id,
    required String title,
    required String slug,
    String? description,
    String? thumbnailUrl,
    required String difficultyLevel,
    required bool isPublished,
    int? instructorId,
    @Default([]) List<Module> modules,
    @Default(0.0) double progressPercentage,
    @Default([]) List<int> completedLessonIds,
  }) = _Course;

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
}

@freezed
abstract class Module with _$Module {
  const factory Module({
    required int id,
    required String title,
    String? description,
    required int orderIndex,
    @Default([]) List<Chapter> chapters,
  }) = _Module;

  factory Module.fromJson(Map<String, dynamic> json) => _$ModuleFromJson(json);
}

@freezed
abstract class Chapter with _$Chapter {
  const factory Chapter({
    required int id,
    required String title,
    String? description,
    required int orderIndex,
    @Default([]) List<Lesson> lessons,
  }) = _Chapter;

  factory Chapter.fromJson(Map<String, dynamic> json) => _$ChapterFromJson(json);
}

@freezed
abstract class Lesson with _$Lesson {
  const factory Lesson({
    required int id,
    required String title,
    required String contentType,
    String? videoUrl,
    int? durationMinutes,
    required int orderIndex,
    Map<String, dynamic>? contentBody,
    @Default(false) bool isPremium,
  }) = _Lesson;

  factory Lesson.fromJson(Map<String, dynamic> json) => _$LessonFromJson(json);
}
