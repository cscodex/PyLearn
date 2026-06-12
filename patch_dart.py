import sys

content = open("frontend/lib/features/course/domain/entities/quiz.dart").read()
if "previousSubmission" not in content:
    content = content.replace(
        "final List<Question> questions;",
        "final List<Question> questions;\n  final Map<String, dynamic>? previousSubmission;"
    )
    content = content.replace(
        "Quiz({required this.lessonId, required this.questions});",
        "Quiz({required this.lessonId, required this.questions, this.previousSubmission});"
    )
    content = content.replace(
        "questions: (json['questions'] as List).map((q) => Question.fromJson(q)).toList(),",
        "questions: (json['questions'] as List).map((q) => Question.fromJson(q)).toList(),\n      previousSubmission: json['previous_submission'],"
    )
    with open("frontend/lib/features/course/domain/entities/quiz.dart", "w") as f:
        f.write(content)

content2 = open("frontend/lib/features/course/presentation/pages/quiz_screen.dart").read()
if "if (quiz.previousSubmission != null && _result == null) {" not in content2:
    new_init = """
          if (quiz.previousSubmission != null && _result == null && _answers.isEmpty) {
            // Restore previous submission state so user can view their marks
            final pSub = quiz.previousSubmission!;
            final pAnswers = pSub['answers'] as Map<String, dynamic>? ?? {};
            pAnswers.forEach((k, v) {
              _answers[int.parse(k)] = v as int;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _result = QuizSubmissionResult(
                    score: pSub['score'] ?? 0,
                    passed: pSub['passed'] ?? false,
                    xpEarned: 0,
                    feedback: "You previously scored ${pSub['score']}% on this quiz.",
                  );
                });
              }
            });
          }
"""
    content2 = content2.replace(
        "data: (quiz) {",
        "data: (quiz) {\n" + new_init
    )
    # also we need to avoid the setState during build error, so we put it in addPostFrameCallback which is valid.
    with open("frontend/lib/features/course/presentation/pages/quiz_screen.dart", "w") as f:
        f.write(content2)

print("Patched frontend")
