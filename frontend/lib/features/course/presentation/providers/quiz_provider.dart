import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/quiz.dart';

class QuizService {
  final Ref ref;

  QuizService(this.ref);

  Future<Quiz> fetchQuiz(int lessonId) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/quiz/$lessonId');
    return Quiz.fromJson(response.data);
  }

  Future<QuizSubmissionResult> submitQuiz(int lessonId, Map<int, int> answers) async {
    final dio = ref.read(dioProvider);
    final response = await dio.post('/quiz/submit', data: {
      'lesson_id': lessonId,
      'answers': answers,
    });
    return QuizSubmissionResult.fromJson(response.data);
  }
}

final quizServiceProvider = Provider<QuizService>((ref) {
  return QuizService(ref);
});

final quizProvider = FutureProvider.family<Quiz, int>((ref, lessonId) async {
  return ref.read(quizServiceProvider).fetchQuiz(lessonId);
});
