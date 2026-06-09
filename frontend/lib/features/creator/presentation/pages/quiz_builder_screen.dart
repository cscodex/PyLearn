import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/creator_courses_provider.dart';

class QuizBuilderScreen extends ConsumerStatefulWidget {
  final int lessonId;
  const QuizBuilderScreen({super.key, required this.lessonId});

  @override
  ConsumerState<QuizBuilderScreen> createState() => _QuizBuilderScreenState();
}

class _QuizBuilderScreenState extends ConsumerState<QuizBuilderScreen> {
  final List<Map<String, dynamic>> _questions = [];
  bool _isSaving = false;

  void _addQuestion(String type) {
    setState(() {
      _questions.add({
        'type': type,
        'text': '',
        'points': 1,
        'options': [], // for multiple choice/select
        'tf_answer': true, // for true/false
        'expected_answer': '', // for fill in the blank
      });
    });
  }

  void _addOption(int questionIndex) {
    setState(() {
      _questions[questionIndex]['options'].add({
        'option_text': '',
        'is_correct': false,
      });
    });
  }

  void _showAddQuestionDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.radio_button_checked),
                title: const Text('Multiple Choice'),
                onTap: () {
                  Navigator.pop(context);
                  _addQuestion('multiple_choice');
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_box_outline_blank),
                title: const Text('True / False'),
                onTap: () {
                  Navigator.pop(context);
                  _addQuestion('true_false');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Fill in the Blanks'),
                onTap: () {
                  Navigator.pop(context);
                  _addQuestion('fill_in_the_blank');
                },
              ),
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text('Multiple Select'),
                onTap: () {
                  Navigator.pop(context);
                  _addQuestion('multiple_select');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _parseAIQuiz(String text) {
    List<Map<String, dynamic>> newQuestions = [];
    
    // Split by looking ahead for a number followed by a period at the start of a line
    // e.g., "1.", "2."
    final blocks = text.split(RegExp(r'\n(?=\d+\.)'));
    
    for (var block in blocks) {
      if (block.trim().isEmpty) continue;
      
      final lines = block.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) continue;
      
      String questionText = lines[0].replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
      List<Map<String, dynamic>> options = [];
      
      // Process remaining lines as options
      for (int i = 1; i < lines.length; i++) {
        String line = lines[i].trim();
        bool isCorrect = line.toLowerCase().contains('(correct)') || 
                         line.toLowerCase().contains('*') ||
                         line.toLowerCase().contains('✓');
        
        // Clean option text
        String optionText = line
            .replaceFirst(RegExp(r'^([a-zA-Z]\)|-|\*)\s*'), '')
            .replaceAll(RegExp(r'\s*\(correct\)', caseSensitive: false), '')
            .replaceAll('*', '')
            .replaceAll('✓', '')
            .trim();
            
        if (optionText.isNotEmpty) {
          options.add({
            'option_text': optionText,
            'is_correct': isCorrect,
          });
        }
      }
      
      if (questionText.isNotEmpty && options.isNotEmpty) {
        newQuestions.add({
          'type': 'multiple_choice',
          'text': questionText,
          'points': 1,
          'options': options,
        });
      }
    }
    
    if (newQuestions.isNotEmpty) {
      setState(() {
        _questions.addAll(newQuestions);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${newQuestions.length} questions successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not parse any questions. Ensure they start with numbers (e.g. "1. Question") and options follow.')),
      );
    }
  }

  void _showAIImportDialog() {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('✨ Paste AI Generated Quiz'),
          content: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Paste the text generated by ChatGPT or Claude.\n'
                  'Format example:\n'
                  '1. What is Python?\n'
                  'A) A snake\n'
                  'B) A programming language (Correct)\n',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Paste here...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _parseAIQuiz(_controller.text);
              },
              child: const Text('Import Questions'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveQuiz() async {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one question')));
      return;
    }

    setState(() => _isSaving = true);
    
    // Format questions for backend
    List<Map<String, dynamic>> formatted = _questions.map((q) {
      Map<String, dynamic> out = {
        'type': q['type'],
        'text': q['text'],
        'points': q['points'],
      };
      
      if (q['type'] == 'multiple_choice' || q['type'] == 'multiple_select') {
        out['options'] = q['options'];
      } else if (q['type'] == 'true_false') {
        out['options'] = [
          {'option_text': 'True', 'is_correct': q['tf_answer'] == true},
          {'option_text': 'False', 'is_correct': q['tf_answer'] == false},
        ];
      } else if (q['type'] == 'fill_in_the_blank') {
        out['options'] = [
          {'option_text': q['expected_answer'], 'is_correct': true},
        ];
      }
      return out;
    }).toList();

    final success = await ref.read(creatorCoursesProvider.notifier).saveQuizQuestions(widget.lessonId, formatted);
    
    setState(() => _isSaving = false);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz saved successfully!')),
        );
        context.pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save quiz. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Assessment Builder'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            FilledButton(
              onPressed: _saveQuiz,
              child: const Text('Save Assessment'),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _questions.length + 1,
        itemBuilder: (context, index) {
          if (index == _questions.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _showAddQuestionDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Question'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.tonalIcon(
                    onPressed: _showAIImportDialog,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Paste AI Quiz'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            );
          }
          
          final q = _questions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(q['type'].toString().replaceAll('_', ' ').toUpperCase()),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _questions.removeAt(index);
                          });
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: q['text'],
                    decoration: const InputDecoration(
                      labelText: 'Question Text',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (val) => q['text'] = val,
                  ),
                  const SizedBox(height: 16),
                  
                  // Multiple Choice / Select Options
                  if (q['type'] == 'multiple_choice' || q['type'] == 'multiple_select') ...[
                    ...List.generate(q['options'].length, (optIndex) {
                      final opt = q['options'][optIndex];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: opt['is_correct'],
                              onChanged: (val) {
                                setState(() {
                                  // For MCQ, only one can be true
                                  if (q['type'] == 'multiple_choice' && val == true) {
                                    for (var o in q['options']) {
                                      o['is_correct'] = false;
                                    }
                                  }
                                  opt['is_correct'] = val;
                                });
                              },
                            ),
                            Expanded(
                              child: TextFormField(
                                initialValue: opt['option_text'],
                                decoration: InputDecoration(
                                  labelText: 'Option ${optIndex + 1}',
                                  isDense: true,
                                ),
                                onChanged: (val) => opt['option_text'] = val,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  q['options'].removeAt(optIndex);
                                });
                              },
                            )
                          ],
                        ),
                      );
                    }),
                    ElevatedButton.icon(
                      onPressed: () => _addOption(index),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Option'),
                    ),
                  ],

                  // True/False
                  if (q['type'] == 'true_false')
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            value: true,
                            groupValue: q['tf_answer'],
                            onChanged: (v) {
                              setState(() => q['tf_answer'] = v);
                            },
                            title: const Text('True'),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            value: false,
                            groupValue: q['tf_answer'],
                            onChanged: (v) {
                              setState(() => q['tf_answer'] = v);
                            },
                            title: const Text('False'),
                          ),
                        ),
                      ],
                    ),

                  // Fill in the blanks
                  if (q['type'] == 'fill_in_the_blank')
                    TextFormField(
                      initialValue: q['expected_answer'],
                      decoration: const InputDecoration(
                        labelText: 'Expected Answer',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => q['expected_answer'] = val,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
