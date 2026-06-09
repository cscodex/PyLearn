class QuestionOption {
  final int id;
  final String text;

  QuestionOption({required this.id, required this.text});

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'],
      text: json['option_text'],
    );
  }
}

class Question {
  final int id;
  final String text;
  final String type;
  final List<QuestionOption> options;

  Question({required this.id, required this.text, required this.type, required this.options});

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['question_text'],
      type: json['question_type'],
      options: (json['options'] as List).map((o) => QuestionOption.fromJson(o)).toList(),
    );
  }
}

class Quiz {
  final int lessonId;
  final List<Question> questions;

  Quiz({required this.lessonId, required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      lessonId: json['lesson_id'],
      questions: (json['questions'] as List).map((q) => Question.fromJson(q)).toList(),
    );
  }
}

class QuizSubmissionResult {
  final int score;
  final bool passed;
  final int xpEarned;
  final String? feedback;

  QuizSubmissionResult({required this.score, required this.passed, required this.xpEarned, this.feedback});

  factory QuizSubmissionResult.fromJson(Map<String, dynamic> json) {
    return QuizSubmissionResult(
      score: json['score'],
      passed: json['passed'],
      xpEarned: json['xp_earned'],
      feedback: json['feedback'],
    );
  }
}
