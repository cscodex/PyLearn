import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../providers/creator_courses_provider.dart';
import '../../../course/domain/entities/course.dart';
import '../../../../core/widgets/loading_overlay.dart';

class CourseEditorScreen extends ConsumerStatefulWidget {
  final int courseId;
  const CourseEditorScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends ConsumerState<CourseEditorScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creatorCoursesProvider);
    final isLoading = state.isLoading;
    final courseList = state.value ?? [];
    final course = courseList.where((c) => c.id == widget.courseId).firstOrNull;

    if (course == null && !isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Course')),
        body: const Center(child: Text('Course not found.')),
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
                  context.push('/learn/course/${course.id}');
                },
                icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                label: const Text('Preview Course', style: TextStyle(color: Colors.white)),
              ),
            const SizedBox(width: 8),
            if (course != null)
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
        body: course == null ? const SizedBox() : _buildCourseHierarchy(course),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddModuleDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Add Module'),
        ),
      ),
    );
  }

  Widget _buildCourseHierarchy(Course course) {
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
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditCourseDialog(course),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Modules
        ...course.modules.map((module) => _buildModuleCard(module)).toList(),
        const SizedBox(height: 80), // Padding for FAB
      ],
    );
  }

  Widget _buildModuleCard(Module module) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text('Module: ${module.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(module.description ?? ''),
        leading: const Icon(Icons.folder),
        trailing: Row(
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
        children: module.chapters.map((chapter) => _buildChapterTile(chapter)).toList(),
      ),
    );
  }

  Widget _buildChapterTile(Chapter chapter) {
    return Container(
      color: Colors.grey.withOpacity(0.05),
      child: ExpansionTile(
        title: Text('Chapter: ${chapter.title}'),
        subtitle: Text(chapter.description ?? ''),
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(Icons.menu_book),
        ),
        trailing: Row(
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
        children: chapter.lessons.map((lesson) => _buildLessonTile(lesson)).toList(),
      ),
    );
  }

  Widget _buildLessonTile(Lesson lesson) {
    IconData icon;
    switch (lesson.contentType) {
      case 'video': icon = Icons.play_circle; break;
      case 'quiz': icon = Icons.quiz; break;
      case 'code_challenge': icon = Icons.code; break;
      default: icon = Icons.article; break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 64, right: 16),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(lesson.title),
      subtitle: Text(lesson.contentType.toUpperCase()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () {
              if (lesson.contentType == 'quiz') {
                context.push('/creator/quiz_builder/${lesson.id}');
              } else {
                _showEditLessonDialog(lesson);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            onPressed: () => _deleteLesson(lesson.id),
          ),
        ],
      ),
    );
  }

  // --- Dialogs & Actions ---

  Future<void> _deleteModule(int id) async {
    final confirm = await _showConfirmDialog('Delete Module', 'Are you sure you want to delete this module and all its contents?');
    if (confirm) await ref.read(creatorCoursesProvider.notifier).deleteModule(id);
  }
  Future<void> _deleteChapter(int id) async {
    final confirm = await _showConfirmDialog('Delete Chapter', 'Are you sure you want to delete this chapter and all its lessons?');
    if (confirm) await ref.read(creatorCoursesProvider.notifier).deleteChapter(id);
  }
  Future<void> _deleteLesson(int id) async {
    final confirm = await _showConfirmDialog('Delete Lesson', 'Are you sure you want to delete this lesson?');
    if (confirm) await ref.read(creatorCoursesProvider.notifier).deleteLesson(id);
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
            onPressed: () {
              ref.read(creatorCoursesProvider.notifier).createModule(widget.courseId, titleCtrl.text, descCtrl.text);
              Navigator.pop(ctx);
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
            onPressed: () {
              ref.read(creatorCoursesProvider.notifier).updateModule(module.id, {'title': titleCtrl.text, 'description': descCtrl.text});
              Navigator.pop(ctx);
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
            onPressed: () {
              ref.read(creatorCoursesProvider.notifier).createChapter(moduleId, titleCtrl.text, descCtrl.text);
              Navigator.pop(ctx);
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
            onPressed: () {
              ref.read(creatorCoursesProvider.notifier).updateChapter(chapter.id, {'title': titleCtrl.text, 'description': descCtrl.text});
              Navigator.pop(ctx);
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
                  DropdownMenuItem(value: 'code_challenge', child: Text('Code Challenge')),
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
                if (mounted) Navigator.pop(ctx);
                if (type == 'quiz' && id != null) {
                  context.push('/creator/quiz_builder/$id');
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
              onPressed: () {
                ref.read(creatorCoursesProvider.notifier).updateCourse(course.id, {
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'difficulty_level': diff,
                });
                Navigator.pop(ctx);
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
      builder: (context) => _LessonEditorDialog(lesson: lesson, ref: ref),
      fullscreenDialog: true,
    ));
  }
}

class _LessonEditorDialog extends StatefulWidget {
  final Lesson lesson;
  final WidgetRef ref;
  const _LessonEditorDialog({required this.lesson, required this.ref});

  @override
  State<_LessonEditorDialog> createState() => _LessonEditorDialogState();
}

class _LessonEditorDialogState extends State<_LessonEditorDialog> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _videoUrlCtrl;
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.lesson.title);
    _contentCtrl = TextEditingController(text: widget.lesson.contentBody?['text'] ?? '');
    _videoUrlCtrl = TextEditingController(text: widget.lesson.videoUrl ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Lesson Content'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _isPreview = !_isPreview),
            icon: Icon(_isPreview ? Icons.edit : Icons.preview, color: Colors.white),
            label: Text(_isPreview ? 'Edit' : 'Preview', style: const TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              Map<String, dynamic> data = {'title': _titleCtrl.text};
              if (widget.lesson.contentType == 'video') {
                data['video_url'] = _videoUrlCtrl.text;
                data['content_body'] = {'text': _contentCtrl.text};
              } else if (widget.lesson.contentType == 'text') {
                data['content_body'] = {'text': _contentCtrl.text};
              }
              await widget.ref.read(creatorCoursesProvider.notifier).updateLesson(widget.lesson.id, data);
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
        child: Column(
          children: [
            if (!_isPreview) ...[
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
                    labelText: 'Content (Markdown / HTML)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ] else ...[
              // Preview Mode
              Expanded(
                child: Container(
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
                        MarkdownBody(
                          data: _contentCtrl.text.isEmpty ? '*No content provided*' : _contentCtrl.text,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
