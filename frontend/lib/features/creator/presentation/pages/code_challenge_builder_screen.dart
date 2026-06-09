import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/creator_courses_provider.dart';

class CodeChallengeBuilderScreen extends ConsumerStatefulWidget {
  final int lessonId;
  const CodeChallengeBuilderScreen({super.key, required this.lessonId});

  @override
  ConsumerState<CodeChallengeBuilderScreen> createState() => _CodeChallengeBuilderScreenState();
}

class _CodeChallengeBuilderScreenState extends ConsumerState<CodeChallengeBuilderScreen> {
  final _promptCtrl = TextEditingController();
  final _starterCodeCtrl = TextEditingController();
  final _solutionCodeCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load existing content if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courses = ref.read(creatorCoursesProvider).value ?? [];
      for (var course in courses) {
        for (var module in course.modules) {
          for (var chapter in module.chapters) {
            for (var lesson in chapter.lessons) {
              if (lesson.id == widget.lessonId) {
                if (lesson.contentBody != null) {
                  _promptCtrl.text = lesson.contentBody?['text'] ?? '';
                  _starterCodeCtrl.text = lesson.contentBody?['starter_code'] ?? '';
                  _solutionCodeCtrl.text = lesson.contentBody?['solution_code'] ?? '';
                }
                return;
              }
            }
          }
        }
      }
    });
  }

  Future<void> _saveChallenge() async {
    setState(() => _isSaving = true);
    
    final success = await ref.read(creatorCoursesProvider.notifier).updateLesson(
      widget.lessonId,
      {
        'content_body': {
          'text': _promptCtrl.text,
          'starter_code': _starterCodeCtrl.text,
          'solution_code': _solutionCodeCtrl.text,
        }
      }
    );
    
    setState(() => _isSaving = false);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code challenge saved successfully!')),
        );
        context.pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save code challenge. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Code Challenge Builder'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            FilledButton(
              onPressed: _saveChallenge,
              child: const Text('Save Challenge'),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Instructions / Prompt', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _promptCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. Write a Python program that prints "Hello, World!"',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            Text('Starter Code', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _starterCodeCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. def hello():\n  pass',
              ),
              maxLines: 6,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 24),
            Text('Solution Code', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _solutionCodeCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. def hello():\n  print("Hello, World!")',
              ),
              maxLines: 6,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
