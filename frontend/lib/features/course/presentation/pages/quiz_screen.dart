import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuizScreen extends StatefulWidget {
  final int lessonId;
  final bool inline;
  final VoidCallback? onComplete;
  
  const QuizScreen({super.key, required this.lessonId, this.inline = false, this.onComplete});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  String? _selectedOption;

  final List<Map<String, dynamic>> _mockQuestions = [
    {
      'question': 'What is the output of `print(2 ** 3)`?',
      'options': ['5', '6', '8', '9'],
      'answer': '8',
    },
    {
      'question': 'Which keyword is used to define a function in Python?',
      'options': ['function', 'def', 'fun', 'define'],
      'answer': 'def',
    }
  ];

  void _submitAnswer() {
    if (_selectedOption == null) return;

    final isCorrect = _selectedOption == _mockQuestions[_currentQuestionIndex]['answer'];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isCorrect ? 'Correct! 🎉' : 'Incorrect 😔'),
        content: Text(isCorrect ? 'Great job! +10 XP' : 'The correct answer was ${_mockQuestions[_currentQuestionIndex]['answer']}'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (_currentQuestionIndex < _mockQuestions.length - 1) {
                setState(() {
                  _currentQuestionIndex++;
                  _selectedOption = null;
                });
              } else {
                // Finish Quiz
                context.pop(); // Close dialog
                if (widget.onComplete != null) {
                  widget.onComplete!();
                } else if (!widget.inline) {
                  context.pop(); // Close screen
                }
              }
            },
            child: const Text('Continue'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = _mockQuestions[_currentQuestionIndex];
    final options = question['options'] as List<String>;

    return Scaffold(
      appBar: widget.inline ? null : AppBar(
        title: const Text('Knowledge Check'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _mockQuestions.length,
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
              'Question ${_currentQuestionIndex + 1} of ${_mockQuestions.length}',
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              question['question'],
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ...options.map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedOption = option;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  alignment: Alignment.centerLeft,
                  side: BorderSide(
                    color: _selectedOption == option ? theme.colorScheme.primary : Colors.grey.shade300,
                    width: _selectedOption == option ? 2 : 1,
                  ),
                  backgroundColor: _selectedOption == option ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedOption == option ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            )),
            const Spacer(),
            FilledButton(
              onPressed: _selectedOption != null ? _submitAnswer : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Submit Answer', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
