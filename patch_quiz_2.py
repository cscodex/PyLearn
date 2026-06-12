import re

content = open("backend/app/api/v1/endpoints/quiz.py").read()

new_python = """
            # Reconstruct submission data
            answers = {}
            score = 0
            
            # Sort subs by submitted_at desc to get latest
            subs.sort(key=lambda x: x.submitted_at, reverse=True)
            seen_questions = set()
            
            for s in subs:
                if s.question_id in seen_questions:
                    continue
                seen_questions.add(s.question_id)
                if s.answer_data and "selected_option_id" in s.answer_data:
                    answers[str(s.question_id)] = s.answer_data["selected_option_id"]
                score += float(s.score or 0)
"""

content = re.sub(
    r'# Reconstruct submission data.*?score \+= \(s\.score or 0\)',
    new_python.strip(),
    content,
    flags=re.DOTALL
)

with open("backend/app/api/v1/endpoints/quiz.py", "w") as f:
    f.write(content)

content2 = open("frontend/lib/features/course/presentation/pages/quiz_screen.dart").read()
# Replace the addPostFrameCallback that sets _result
content2 = re.sub(
    r'WidgetsBinding\.instance\.addPostFrameCallback\(\(_\) \{.*?\}\);\n          }',
    '}',
    content2,
    flags=re.DOTALL
)
# Add a banner if _answers is populated from previous
new_ui = """
          if (quiz.previousSubmission != null && _result == null && _answers.isEmpty) {
            // Restore previous submission state so user can view their marks
            final pSub = quiz.previousSubmission!;
            final pAnswers = pSub['answers'] as Map<String, dynamic>? ?? {};
            pAnswers.forEach((k, v) {
              _answers[int.parse(k)] = v as int;
            });
            // We do NOT set _result here anymore so they can see their responses!
          }

        if (quiz.questions.isEmpty) {
"""

content2 = re.sub(
    r'if \(quiz\.previousSubmission != null && _result == null && _answers\.isEmpty\) \{.*?\n        if \(quiz\.questions\.isEmpty\) \{',
    new_ui.strip() + "\n\n        if (quiz.questions.isEmpty) {",
    content2,
    flags=re.DOTALL
)

# Also add the banner to the Scaffold body
banner_code = """
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (quiz.previousSubmission != null && _result == null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your previous score: ${quiz.previousSubmission!['score']}%. You can review your answers or retake the quiz.',
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${quiz.questions.length}',
"""

content2 = content2.replace(
    """          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${quiz.questions.length}',""",
    banner_code
)

with open("frontend/lib/features/course/presentation/pages/quiz_screen.dart", "w") as f:
    f.write(content2)

print("Patched quiz endpoint and dart UI")
