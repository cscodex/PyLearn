import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class SavedProgram {
  final int id;
  final String title;
  final String code;
  final String? language;
  final String createdAt;
  final String? studentName;
  final String? studentEmail;

  SavedProgram({
    required this.id,
    required this.title,
    required this.code,
    this.language,
    required this.createdAt,
    this.studentName,
    this.studentEmail,
  });

  factory SavedProgram.fromJson(Map<String, dynamic> json) {
    return SavedProgram(
      id: json['id'],
      title: json['title'],
      code: json['code'],
      language: json['language'],
      createdAt: json['created_at'],
      studentName: json['student_name'],
      studentEmail: json['student_email'],
    );
  }
}

final savedProgramsProvider = FutureProvider.autoDispose<List<SavedProgram>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/saved-programs/');
  return (response.data as List)
      .map((item) => SavedProgram.fromJson(item))
      .toList();
});

class SavedProgramsService {
  final Ref ref;

  SavedProgramsService(this.ref);

  Future<SavedProgram?> saveProgram(String title, String code, {int? lessonId}) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/saved-programs/', data: {
        'title': title,
        'code': code,
        if (lessonId != null) 'lesson_id': lessonId,
      });
      ref.invalidate(savedProgramsProvider);
      return SavedProgram.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateProgram(int id, String title, String code, {int? lessonId}) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/saved-programs/$id', data: {
        'title': title,
        'code': code,
        if (lessonId != null) 'lesson_id': lessonId,
      });
      ref.invalidate(savedProgramsProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteProgram(int id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/saved-programs/$id');
      ref.invalidate(savedProgramsProvider);
    } catch (e) {
      // ignore
    } catch (e) {
      // ignore
    }
  }

  Future<List<SavedProgram>> getStudentPrograms() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/saved-programs/students');
      return (response.data as List)
          .map((item) => SavedProgram.fromJson(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<SavedProgram?> getProgramForLesson(int lessonId) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/saved-programs/lesson/$lessonId');
      return SavedProgram.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }
}

final studentProgramsProvider = FutureProvider.autoDispose<List<SavedProgram>>((ref) async {
  final service = ref.watch(savedProgramsServiceProvider);
  return await service.getStudentPrograms();
});

final savedProgramsServiceProvider = Provider<SavedProgramsService>((ref) {
  return SavedProgramsService(ref);
});
