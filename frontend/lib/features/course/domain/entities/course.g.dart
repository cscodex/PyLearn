// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Course _$CourseFromJson(Map<String, dynamic> json) => _Course(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  slug: json['slug'] as String,
  description: json['description'] as String?,
  thumbnailUrl: json['thumbnailUrl'] as String?,
  difficultyLevel: json['difficultyLevel'] as String,
  isPublished: json['isPublished'] as bool,
  instructorId: (json['instructorId'] as num?)?.toInt(),
  modules:
      (json['modules'] as List<dynamic>?)
          ?.map((e) => Module.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
  completedLessonIds:
      (json['completedLessonIds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
);

Map<String, dynamic> _$CourseToJson(_Course instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'slug': instance.slug,
  'description': instance.description,
  'thumbnailUrl': instance.thumbnailUrl,
  'difficultyLevel': instance.difficultyLevel,
  'isPublished': instance.isPublished,
  'instructorId': instance.instructorId,
  'modules': instance.modules,
  'progressPercentage': instance.progressPercentage,
  'completedLessonIds': instance.completedLessonIds,
};

_Module _$ModuleFromJson(Map<String, dynamic> json) => _Module(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String?,
  orderIndex: (json['orderIndex'] as num).toInt(),
  chapters:
      (json['chapters'] as List<dynamic>?)
          ?.map((e) => Chapter.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ModuleToJson(_Module instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'orderIndex': instance.orderIndex,
  'chapters': instance.chapters,
};

_Chapter _$ChapterFromJson(Map<String, dynamic> json) => _Chapter(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String?,
  orderIndex: (json['orderIndex'] as num).toInt(),
  lessons:
      (json['lessons'] as List<dynamic>?)
          ?.map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ChapterToJson(_Chapter instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'orderIndex': instance.orderIndex,
  'lessons': instance.lessons,
};

_Lesson _$LessonFromJson(Map<String, dynamic> json) => _Lesson(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  contentType: json['contentType'] as String,
  videoUrl: json['videoUrl'] as String?,
  durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
  orderIndex: (json['orderIndex'] as num).toInt(),
  contentBody: json['contentBody'] as Map<String, dynamic>?,
  isPremium: json['isPremium'] as bool? ?? false,
);

Map<String, dynamic> _$LessonToJson(_Lesson instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'contentType': instance.contentType,
  'videoUrl': instance.videoUrl,
  'durationMinutes': instance.durationMinutes,
  'orderIndex': instance.orderIndex,
  'contentBody': instance.contentBody,
  'isPremium': instance.isPremium,
};
