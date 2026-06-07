import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/creator_courses_provider.dart';

class CurriculumBuilderScreen extends ConsumerStatefulWidget {
  const CurriculumBuilderScreen({super.key});

  @override
  ConsumerState<CurriculumBuilderScreen> createState() => _CurriculumBuilderScreenState();
}

class _CurriculumBuilderScreenState extends ConsumerState<CurriculumBuilderScreen> {
  int _step = 0;
  
  // IDs to keep track of the created hierarchy
  int? _courseId;
  int? _moduleId;
  int? _chapterId;
  
  // Controllers
  final _courseTitleCtrl = TextEditingController();
  final _courseDescCtrl = TextEditingController();
  String _difficulty = 'beginner';
  
  final _moduleTitleCtrl = TextEditingController();
  final _moduleDescCtrl = TextEditingController();
  
  final _chapterTitleCtrl = TextEditingController();
  final _chapterDescCtrl = TextEditingController();

  final _lessonTitleCtrl = TextEditingController();
  String _lessonType = 'video';
  final _lessonVideoUrlCtrl = TextEditingController();
  final _lessonContentCtrl = TextEditingController();

  Future<void> _createCourse() async {
    if (_courseTitleCtrl.text.isEmpty) return;
    final id = await ref.read(creatorCoursesProvider.notifier).createCourse(
      _courseTitleCtrl.text,
      _courseDescCtrl.text,
      _difficulty,
    );
    if (id != null) {
      setState(() {
        _courseId = id;
        _step = 1;
      });
    }
  }

  Future<void> _createModule() async {
    if (_moduleTitleCtrl.text.isEmpty || _courseId == null) return;
    final id = await ref.read(creatorCoursesProvider.notifier).createModule(
      _courseId!,
      _moduleTitleCtrl.text,
      _moduleDescCtrl.text,
    );
    if (id != null) {
      setState(() {
        _moduleId = id;
        _step = 2;
      });
    }
  }

  Future<void> _createChapter() async {
    if (_chapterTitleCtrl.text.isEmpty || _moduleId == null) return;
    final id = await ref.read(creatorCoursesProvider.notifier).createChapter(
      _moduleId!,
      _chapterTitleCtrl.text,
      _chapterDescCtrl.text,
    );
    if (id != null) {
      setState(() {
        _chapterId = id;
        _step = 3;
      });
    }
  }

  Future<void> _createLesson() async {
    if (_lessonTitleCtrl.text.isEmpty || _chapterId == null) return;
    
    Map<String, dynamic> body = {};
    if (_lessonType == 'video') {
      body['text'] = _lessonContentCtrl.text;
    } else if (_lessonType == 'text') {
      body['text'] = _lessonContentCtrl.text;
    }

    final id = await ref.read(creatorCoursesProvider.notifier).createLesson(
      _chapterId!,
      _lessonTitleCtrl.text,
      _lessonType == 'quiz' ? 'quiz' : _lessonType,
      body,
    );

    if (id != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson Created successfully!')),
      );
      if (_lessonType == 'quiz') {
        context.push('/creator/quiz_builder/$id');
      } else {
        context.pop(); // Go back to dashboard
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creatorCoursesProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Curriculum Builder'),
      ),
      body: Stepper(
        currentStep: _step,
        onStepTapped: (step) {
           if (step < _step) setState(() => _step = step);
        },
        onStepContinue: () {
          if (_step == 0) _createCourse();
          else if (_step == 1) _createModule();
          else if (_step == 2) _createChapter();
          else if (_step == 3) _createLesson();
        },
        onStepCancel: () {
          if (_step > 0) {
            setState(() => _step -= 1);
          } else {
            context.pop();
          }
        },
        steps: [
          Step(
            title: const Text('Create Course'),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.editing,
            content: Column(
              children: [
                TextField(
                  controller: _courseTitleCtrl,
                  decoration: const InputDecoration(labelText: 'Course Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _courseDescCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items: const [
                    DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                    DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                    DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                  ],
                  onChanged: (val) => setState(() => _difficulty = val!),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Add Module'),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.editing,
            content: Column(
              children: [
                TextField(
                  controller: _moduleTitleCtrl,
                  decoration: const InputDecoration(labelText: 'Module Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _moduleDescCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Add Chapter'),
            isActive: _step >= 2,
            state: _step > 2 ? StepState.complete : StepState.editing,
            content: Column(
              children: [
                TextField(
                  controller: _chapterTitleCtrl,
                  decoration: const InputDecoration(labelText: 'Chapter Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _chapterDescCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Create Lesson'),
            isActive: _step >= 3,
            state: _step > 3 ? StepState.complete : StepState.editing,
            content: Column(
              children: [
                TextField(
                  controller: _lessonTitleCtrl,
                  decoration: const InputDecoration(labelText: 'Lesson Title'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _lessonType,
                  decoration: const InputDecoration(labelText: 'Lesson Type'),
                  items: const [
                    DropdownMenuItem(value: 'video', child: Text('Video Lesson')),
                    DropdownMenuItem(value: 'text', child: Text('Text/Reading Lesson')),
                    DropdownMenuItem(value: 'quiz', child: Text('Quiz Assessment')),
                  ],
                  onChanged: (val) => setState(() => _lessonType = val!),
                ),
                const SizedBox(height: 16),
                if (_lessonType == 'video')
                  TextField(
                    controller: _lessonVideoUrlCtrl,
                    decoration: const InputDecoration(labelText: 'Video URL (YouTube/Vimeo)'),
                  ),
                if (_lessonType == 'text' || _lessonType == 'video') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lessonContentCtrl,
                    decoration: const InputDecoration(labelText: 'Content Body (Markdown)'),
                    maxLines: 5,
                  ),
                ],
                if (_lessonType == 'quiz')
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('You will be redirected to the Quiz Builder after creating this lesson to add questions.', style: TextStyle(color: Colors.blue)),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isLoading ? const LinearProgressIndicator() : null,
    );
  }
}
