import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_html/flutter_html.dart';

import '../providers/creator_courses_provider.dart';
import '../../../course/presentation/providers/course_provider.dart';
import '../../../course/domain/entities/course.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/network/dio_client.dart';

class CourseEditorScreen extends ConsumerStatefulWidget {
  final int courseId;
  const CourseEditorScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends ConsumerState<CourseEditorScreen> {
  @override
  Widget build(BuildContext context) {
    // Watch the full course details instead of the basic list
    final courseAsync = ref.watch(courseDetailsProvider(widget.courseId));
    final isLoading = courseAsync.isLoading;
    final course = courseAsync.value;
    final authState = ref.watch(authProvider);
    final role = authState.user?.role ?? 'student';
    final isAdmin = role == 'admin';

    if (course == null && !isLoading && !courseAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Course')),
        body: const Center(child: Text('Course not found.')),
      );
    }
    
    if (courseAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Course')),
        body: Center(child: Text('Error: ${courseAsync.error}')),
      );
    }

    return LoadingOverlay(
      isLoading: isLoading || course == null,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Course Editor'),
          actions: [
            if (course != null)
              TextButton.icon(
                onPressed: () {
                  // Navigate to course player preview
                  context.push('/courses/${course.id}');
                },
                icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                label: const Text('Preview Course', style: TextStyle(color: Colors.white)),
              ),
            const SizedBox(width: 8),
            if (course != null && !isAdmin)
              Switch(
                value: course.isPublished,
                onChanged: (val) async {
                  await ref.read(creatorCoursesProvider.notifier).updateCourse(
                        course.id,
                        {'is_published': val},
                      );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(val ? 'Course Published' : 'Course set to Draft')),
                    );
                  }
                },
                activeColor: Colors.green,
                inactiveThumbColor: Colors.grey,
              ),
            const SizedBox(width: 16),
          ],
        ),
        body: course == null ? const SizedBox() : _buildCourseHierarchy(course, isAdmin),
        floatingActionButton: isAdmin ? null : FloatingActionButton.extended(
          onPressed: () => _showAddModuleDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Add Module'),
        ),
      ),
    );
  }

  Widget _buildCourseHierarchy(Course course, bool isAdmin) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Course Header
        Card(
          elevation: 2,
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          child: ListTile(
            title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            subtitle: Text(course.description ?? 'No description'),
            trailing: isAdmin ? null : IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditCourseDialog(course),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Modules
        ...course.modules.map((module) => _buildModuleCard(module, isAdmin)).toList(),
        const SizedBox(height: 80), // Padding for FAB
      ],
    );
  }

  Widget _buildModuleCard(Module module, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text('Module: ${module.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(module.description ?? ''),
        leading: const Icon(Icons.folder),
        trailing: isAdmin ? null : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add Chapter',
              onPressed: () => _showAddChapterDialog(module.id),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditModuleDialog(module),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteModule(module.id),
            ),
          ],
        ),
        children: module.chapters.map((chapter) => _buildChapterTile(chapter, isAdmin)).toList(),
      ),
    );
  }

  Widget _buildChapterTile(Chapter chapter, bool isAdmin) {
    return Container(
      color: Colors.grey.withOpacity(0.05),
      child: ExpansionTile(
        title: Text('Chapter: ${chapter.title}'),
        subtitle: Text(chapter.description ?? ''),
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(Icons.menu_book),
        ),
        trailing: isAdmin ? null : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add Lesson',
              onPressed: () => _showAddLessonDialog(chapter.id),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _showEditChapterDialog(chapter),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => _deleteChapter(chapter.id),
            ),
          ],
        ),
        children: chapter.lessons.map((lesson) => _buildLessonTile(lesson, isAdmin)).toList(),
      ),
    );
  }

  Widget _buildLessonTile(Lesson lesson, bool isAdmin) {
    IconData icon;
    switch (lesson.contentType) {
      case 'video': icon = Icons.play_circle; break;
      case 'quiz': icon = Icons.quiz; break;
      case 'code_challenge': icon = Icons.code; break;
      default: icon = Icons.article; break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 48.0),
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(lesson.title),
        subtitle: Text(lesson.contentType.toUpperCase()),
        trailing: isAdmin ? null : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () {
                if (lesson.contentType == 'quiz') {
                  if (mounted) context.push('/creator/quiz_builder/${lesson.id}');
                } else if (lesson.contentType == 'code_challenge') {
                  if (mounted) context.push('/creator/code_builder/${lesson.id}');
                } else {
                  _showEditLessonDialog(lesson);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => _deleteLesson(lesson.id),
            ),
            const Icon(Icons.expand_more), // Ensure expansion icon is still visible
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: lesson.contentType == 'code_challenge'
              ? Text('Starter Code:\n${lesson.contentBody?['starter_code'] ?? 'No starter code'}\n\nSolution:\n${lesson.contentBody?['solution_code'] ?? 'No solution'}')
              : Html(data: lesson.contentBody?['text'] ?? 'No content'),
          )
        ],
      ),
    );
  }

  // --- Dialogs & Actions ---

  Future<void> _refreshCourse() async {
    ref.invalidate(courseDetailsProvider(widget.courseId));
  }

  Future<void> _deleteModule(int id) async {
    final confirm = await _showConfirmDialog('Delete Module', 'Are you sure you want to delete this module and all its contents?');
    if (confirm) {
      await ref.read(creatorCoursesProvider.notifier).deleteModule(id);
      await _refreshCourse();
    }
  }
  Future<void> _deleteChapter(int id) async {
    final confirm = await _showConfirmDialog('Delete Chapter', 'Are you sure you want to delete this chapter and all its lessons?');
    if (confirm) {
      await ref.read(creatorCoursesProvider.notifier).deleteChapter(id);
      await _refreshCourse();
    }
  }
  Future<void> _deleteLesson(int id) async {
    final confirm = await _showConfirmDialog('Delete Lesson', 'Are you sure you want to delete this lesson?');
    if (confirm) {
      await ref.read(creatorCoursesProvider.notifier).deleteLesson(id);
      await _refreshCourse();
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      )
    ) ?? false;
  }

  void _showAddModuleDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Module'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(creatorCoursesProvider.notifier).createModule(widget.courseId, titleCtrl.text, descCtrl.text);
              await _refreshCourse();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          )
        ],
      )
    );
  }

  void _showEditModuleDialog(Module module) {
    final titleCtrl = TextEditingController(text: module.title);
    final descCtrl = TextEditingController(text: module.description);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Module'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(creatorCoursesProvider.notifier).updateModule(module.id, {'title': titleCtrl.text, 'description': descCtrl.text});
              await _refreshCourse();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          )
        ],
      )
    );
  }

  void _showAddChapterDialog(int moduleId) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Chapter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(creatorCoursesProvider.notifier).createChapter(moduleId, titleCtrl.text, descCtrl.text);
              await _refreshCourse();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          )
        ],
      )
    );
  }

  void _showEditChapterDialog(Chapter chapter) {
    final titleCtrl = TextEditingController(text: chapter.title);
    final descCtrl = TextEditingController(text: chapter.description);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Chapter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(creatorCoursesProvider.notifier).updateChapter(chapter.id, {'title': titleCtrl.text, 'description': descCtrl.text});
              await _refreshCourse();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          )
        ],
      )
    );
  }

  void _showAddLessonDialog(int chapterId) {
    final titleCtrl = TextEditingController();
    String type = 'video';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Lesson'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              DropdownButtonFormField<String>(
                value: type,
                items: const [
                  DropdownMenuItem(value: 'video', child: Text('Video')),
                  DropdownMenuItem(value: 'text', child: Text('Text/Article')),
                  DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                  DropdownMenuItem(value: 'code_challenge', child: Text('Practical Hands-on (Code Challenge)')),
                ],
                onChanged: (val) => setState(() => type = val!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final id = await ref.read(creatorCoursesProvider.notifier).createLesson(chapterId, titleCtrl.text, type, {});
                await _refreshCourse();
                if (mounted) Navigator.pop(ctx);
                if (type == 'quiz' && id != null) {
                  if (mounted) context.push('/creator/quiz_builder/$id');
                } else if (type == 'code_challenge' && id != null) {
                  if (mounted) context.push('/creator/code_builder/$id');
                }
              },
              child: const Text('Add'),
            )
          ],
        )
      )
    );
  }

  void _showEditCourseDialog(Course course) {
    final titleCtrl = TextEditingController(text: course.title);
    final descCtrl = TextEditingController(text: course.description);
    String diff = course.difficultyLevel;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Course Metadata'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              DropdownButtonFormField<String>(
                value: diff,
                items: const [
                  DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                  DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                  DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
                ],
                onChanged: (val) => setState(() => diff = val!),
                decoration: const InputDecoration(labelText: 'Difficulty'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await ref.read(creatorCoursesProvider.notifier).updateCourse(course.id, {
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'difficulty_level': diff,
                });
                await _refreshCourse();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            )
          ],
        )
      )
    );
  }

  void _showEditLessonDialog(Lesson lesson) {
    // Open a full screen dialog for editing lesson content with Markdown preview
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => _LessonEditorDialog(lesson: lesson, ref: ref, courseId: widget.courseId),
      fullscreenDialog: true,
    ));
  }
}

class _LessonEditorDialog extends StatefulWidget {
  final Lesson lesson;
  final WidgetRef ref;
  final int courseId;
  const _LessonEditorDialog({required this.lesson, required this.ref, required this.courseId});

  @override
  State<_LessonEditorDialog> createState() => _LessonEditorDialogState();
}

class _LessonEditorDialogState extends State<_LessonEditorDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _videoUrlCtrl;
  
  // Code Challenge Fields
  late TextEditingController _starterCodeCtrl;
  late TextEditingController _solutionCodeCtrl;
  List<Map<String, String>> _testCases = [];
  String _testResult = '';

  bool _isPreview = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.lesson.title);
    _contentCtrl = TextEditingController(text: widget.lesson.contentBody?['text'] ?? '');
    _videoUrlCtrl = TextEditingController(text: widget.lesson.videoUrl ?? '');
    
    _starterCodeCtrl = TextEditingController(text: widget.lesson.contentBody?['starter_code'] ?? '');
    _solutionCodeCtrl = TextEditingController(text: widget.lesson.contentBody?['solution_code'] ?? '');
    
    final tc = widget.lesson.contentBody?['test_cases'];
    if (tc != null && tc is List) {
      _testCases = tc.map((e) => {'input': e['input']?.toString() ?? '', 'expected_output': e['expected_output']?.toString() ?? ''}).toList();
    }
  }

  Future<void> _testProgram() async {
    if (_testCases.isEmpty) {
      setState(() => _testResult = 'No test cases to run.');
      return;
    }
    setState(() {
      _isTesting = true;
      _testResult = 'Testing...';
    });
    
    // We need to import ExecutionService or ExecutionProvider.
    // Wait, executionProvider isn't imported yet. We must import it!
    // But we can also just use Dio directly if executionProvider is tricky.
    // Let's assume executionProvider works.
    
    try {
      final dio = widget.ref.read(dioProvider); // fallback if executionProvider not available
      int passed = 0;
      for (var tc in _testCases) {
        String testCode = _solutionCodeCtrl.text + '\n\n' + (tc['input'] ?? '');
        final res = await dio.post('/execute', data: {'code': testCode});
        final output = (res.data['stdout'] ?? '').toString().trim();
        final expected = (tc['expected_output'] ?? '').trim();
        if (output == expected) {
          passed++;
        }
      }
      setState(() {
        _testResult = 'Score: $passed / ${_testCases.length} test cases passed.';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error executing code: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCodeChallenge = widget.lesson.contentType == 'code_challenge';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Lesson Content'),
        actions: [
          if (!isCodeChallenge)
            TextButton.icon(
              onPressed: () => setState(() => _isPreview = !_isPreview),
              icon: Icon(_isPreview ? Icons.edit : Icons.preview, color: Colors.white),
              label: Text(_isPreview ? 'Edit' : 'Preview', style: const TextStyle(color: Colors.white)),
            ),
          if (isCodeChallenge)
            TextButton.icon(
              onPressed: _isTesting ? null : _testProgram,
              icon: _isTesting 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('Test Program', style: TextStyle(color: Colors.white)),
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              Map<String, dynamic> data = {'title': _titleCtrl.text};
              
              if (isCodeChallenge) {
                data['content_body'] = {
                  'text': _contentCtrl.text,
                  'starter_code': _starterCodeCtrl.text,
                  'solution_code': _solutionCodeCtrl.text,
                  'test_cases': _testCases,
                };
              } else if (widget.lesson.contentType == 'video') {
                data['video_url'] = _videoUrlCtrl.text;
                data['content_body'] = {'text': _contentCtrl.text};
              } else {
                data['content_body'] = {'text': _contentCtrl.text};
              }
              
              await widget.ref.read(creatorCoursesProvider.notifier).updateLesson(widget.lesson.id, data);
              widget.ref.invalidate(courseDetailsProvider(widget.courseId));
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson saved')));
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isCodeChallenge ? _buildCodeChallengeEditor() : _buildStandardEditor(),
      ),
    );
  }

  Widget _buildStandardEditor() {
    if (_isPreview) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_titleCtrl.text, style: Theme.of(context).textTheme.headlineMedium),
              const Divider(),
              if (widget.lesson.contentType == 'video' && _videoUrlCtrl.text.isNotEmpty)
                Container(
                  height: 200,
                  color: Colors.black12,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: const Icon(Icons.play_circle_outline, size: 64),
                ),
              Html(data: _contentCtrl.text.isEmpty ? '<i>No content provided</i>' : _contentCtrl.text),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'Lesson Title', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        if (widget.lesson.contentType == 'video') ...[
          TextField(
            controller: _videoUrlCtrl,
            decoration: const InputDecoration(labelText: 'Video URL', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: TextField(
            controller: _contentCtrl,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              labelText: 'Content (HTML)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeChallengeEditor() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Challenge Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Problem Description (HTML supported)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _starterCodeCtrl,
                  maxLines: 10,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: 'Starter Code',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _solutionCodeCtrl,
                  maxLines: 10,
                  style: const TextStyle(fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    labelText: 'Solution Code (Will be tested)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Test Cases', style: Theme.of(context).textTheme.titleLarge),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _testCases.add({'input': '', 'expected_output': ''});
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Test Case'),
              )
            ],
          ),
          const SizedBox(height: 8),
          if (_testResult.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              color: _testResult.contains('Error') ? Colors.red.shade100 : Colors.green.shade100,
              child: Text(_testResult, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _testCases.length,
            itemBuilder: (ctx, idx) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _testCases[idx]['input'],
                          onChanged: (val) => _testCases[idx]['input'] = val,
                          decoration: const InputDecoration(labelText: 'Test Call / Input (e.g., print(add(2,3)))', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: _testCases[idx]['expected_output'],
                          onChanged: (val) => _testCases[idx]['expected_output'] = val,
                          decoration: const InputDecoration(labelText: 'Expected Output', isDense: true),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => _testCases.removeAt(idx)),
                      )
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
