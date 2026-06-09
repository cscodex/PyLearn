import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/quiz_provider.dart';
import '../../domain/entities/quiz.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final int lessonId;
  final bool inline;
  final VoidCallback? onComplete;
  
  const QuizScreen({super.key, required this.lessonId, this.inline = false, this.onComplete});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestionIndex = 0;
  final Map<int, int> _answers = {}; // question_id -> option_id
  bool _isSubmitting = false;
  QuizSubmissionResult? _result;

  Future<void> _submitQuiz(Quiz quiz) async {
    if (_answers.length < quiz.questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer all questions before submitting.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final service = ref.read(quizServiceProvider);
      final result = await service.submitQuiz(widget.lessonId, _answers);
      
      // Update profile stats if available
      ref.invalidate(profileProvider);

      setState(() {
        _result = result;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit quiz: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_result != null) {
      return Scaffold(
        appBar: widget.inline ? null : AppBar(title: const Text('Quiz Results')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _result!.passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 80,
                  color: _result!.passed ? Colors.amber : Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  'Score: ${_result!.score}%',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  _result!.feedback ?? '',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                if (_result!.xpEarned > 0)
                  Text(
                    '+${_result!.xpEarned} XP',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                const SizedBox(height: 40),
                FilledButton(
                  onPressed: () {
                    if (widget.onComplete != null) {
                      widget.onComplete!();
                    } else if (!widget.inline) {
                      context.pop();
                    }
                  },
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final quizAsync = ref.watch(quizProvider(widget.lessonId));

    return quizAsync.when(
      data: (quiz) {

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

        if (quiz.questions.isEmpty) {
          return Scaffold(
            appBar: widget.inline ? null : AppBar(title: const Text('Knowledge Check')),
            body: const Center(child: Text('No questions available for this quiz.')),
          );
        }

        final question = quiz.questions[_currentQuestionIndex];
        final options = question.options;
        final selectedOptionId = _answers[question.id];

        return Scaffold(
          appBar: widget.inline ? null : AppBar(
            title: const Text('Knowledge Check'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / quiz.questions.length,
                backgroundColor: theme.colorScheme.primaryContainer,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${quiz.questions.length}',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  question.text,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = selectedOptionId == option.id;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _answers[question.id] = option.id;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                            alignment: Alignment.centerLeft,
                            side: BorderSide(
                              color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            backgroundColor: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
                          ),
                          child: Text(
                            option.text,
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (_currentQuestionIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _currentQuestionIndex--;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Previous', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    if (_currentQuestionIndex > 0)
                      const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : () {
                          if (_currentQuestionIndex < quiz.questions.length - 1) {
                            setState(() {
                              _currentQuestionIndex++;
                            });
                          } else {
                            _submitQuiz(quiz);
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              _currentQuestionIndex < quiz.questions.length - 1 ? 'Next' : 'Submit Quiz', 
                              style: const TextStyle(fontSize: 18)
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: widget.inline ? null : AppBar(title: const Text('Knowledge Check')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: widget.inline ? null : AppBar(title: const Text('Knowledge Check')),
        body: Center(child: Text('Error loading quiz: $err')),
      ),
    );
  }
}
