import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
import '../providers/execution_provider.dart';
import '../providers/saved_programs_provider.dart';

enum CodeFontSize { small, medium, large }

class IdeScreen extends ConsumerStatefulWidget {
  final int? lessonId;
  final bool inline;
  final VoidCallback? onComplete;
  final Map<String, dynamic>? contentBody;
  
  const IdeScreen({super.key, this.lessonId, this.inline = false, this.onComplete, this.contentBody});

  @override
  ConsumerState<IdeScreen> createState() => _IdeScreenState();
}

class _IdeScreenState extends ConsumerState<IdeScreen> {
  late CodeController _controller;
  bool _isExecuting = false;
  String _output = '';
  bool _isSuccess = false;
  double _editorHeight = 260.0; // ~12 lines of code
  CodeFontSize _fontSize = CodeFontSize.medium;

  double get _currentFontSize {
    switch (_fontSize) {
      case CodeFontSize.small: return 12.0;
      case CodeFontSize.medium: return 14.0;
      case CodeFontSize.large: return 18.0;
    }
  }

  void _toggleFontSize() {
    setState(() {
      switch (_fontSize) {
        case CodeFontSize.small: _fontSize = CodeFontSize.medium; break;
        case CodeFontSize.medium: _fontSize = CodeFontSize.large; break;
        case CodeFontSize.large: _fontSize = CodeFontSize.small; break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    String starterCode = widget.contentBody?['starter_code'] ?? '# Write your Python code here';
    starterCode = starterCode.trimRight(); // Remove trailing empty lines
    _controller = CodeController(
      text: starterCode,
      language: python,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runCode() async {
    setState(() {
      _isExecuting = true;
      _output = 'Running...';
    });

    final service = ref.read(executionProvider);
    final result = await service.executeCode(
      _controller.text, 
      lessonId: widget.lessonId,
    );

    setState(() {
      _isExecuting = false;
      _isSuccess = result['is_success'] ?? false;
      
      final stdout = result['stdout'] ?? '';
      final stderr = result['stderr'] ?? '';
      final timeMs = result['execution_time_ms'] ?? 0;
      
      if (stderr.toString().isNotEmpty) {
        _output = stderr;
      } else {
        _output = stdout;
      }
      _output += '\n\n[Finished in ${timeMs}ms]';
    });
  }

  Future<void> _saveProgram() async {
    final titleController = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Program'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Program Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, titleController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (title != null && title.isNotEmpty) {
      final success = await ref.read(savedProgramsServiceProvider).saveProgram(title, _controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Saved successfully!' : 'Failed to save. You may have reached the 100 program limit.')),
        );
      }
    }
  }

  void _loadProgram() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _SavedProgramsBottomSheet(),
    ).then((code) {
      if (code != null && code is String) {
        _controller.text = code;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: widget.inline ? null : AppBar(
        title: const Text('Interactive IDE'),
        actions: [
          if (widget.lessonId == null) ...[
            IconButton(
              icon: const Icon(Icons.folder_open),
              tooltip: 'Load Program',
              onPressed: _loadProgram,
            ),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Program',
              onPressed: _saveProgram,
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              onPressed: _isExecuting ? null : _runCode,
              icon: _isExecuting 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_arrow, color: Colors.green),
              tooltip: 'Run Code',
              style: IconButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.2),
              ),
            ),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 800;

          final isDark = theme.brightness == Brightness.dark;
          final codeTheme = isDark ? monokaiSublimeTheme : githubTheme;
          final codeBgColor = isDark ? const Color(0xFF23241f) : Colors.white;
          final codeTextColor = isDark ? Colors.white : Colors.black87;

          final editorWidget = Column(
            children: [
              Expanded(
                child: CodeTheme(
                  data: CodeThemeData(styles: codeTheme),
                  child: Container(
                    color: codeBgColor,
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          child: CodeField(
                            controller: _controller,
                            textStyle: TextStyle(fontFamily: 'monospace', fontSize: _currentFontSize, color: codeTextColor),
                            background: codeBgColor,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.text_fields),
                            color: isDark ? Colors.white54 : Colors.black54,
                            onPressed: _toggleFontSize,
                            tooltip: 'Toggle Font Size',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Shortcut symbols bar
              Container(
                height: 40,
                color: theme.colorScheme.surfaceContainerHighest,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: [
                    '{', '}', '[', ']', '(', ')', ':', ';', '=', '\'', '"', '+', '-', '_', '<', '>', '/', '*'
                  ].map((symbol) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: ActionChip(
                      label: Text(symbol, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                      padding: EdgeInsets.zero,
                      backgroundColor: theme.colorScheme.surface,
                      onPressed: () {
                        final text = _controller.text;
                        final selection = _controller.selection;
                        if (selection.baseOffset >= 0 && selection.extentOffset >= 0) {
                          final newText = text.replaceRange(selection.start, selection.end, symbol);
                          _controller.value = _controller.value.copyWith(
                            text: newText,
                            selection: TextSelection.collapsed(offset: selection.start + symbol.length),
                          );
                        } else {
                          _controller.text = text + symbol;
                        }
                      },
                    ),
                  )).toList(),
                ),
              ),
            ],
          );

          final terminalWidget = Container(
            width: double.infinity,
            color: Colors.black,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.terminal, color: Colors.white54, size: 16),
                    const SizedBox(width: 8),
                    Text('Terminal', style: theme.textTheme.labelMedium?.copyWith(color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      _output,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: _isSuccess || _output == 'Running...' ? Colors.green.shade400 : Colors.red.shade400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          final lessonContentWidget = Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lesson Instructions',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.contentBody?['text'] ?? 'Write your Python code below.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                if (widget.inline) ...[
                  const Spacer(),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FilledButton.icon(
                        onPressed: _isExecuting ? null : _runCode,
                        icon: _isExecuting 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.play_arrow),
                        label: const Text('Run Code'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600),
                      ),
                      if (widget.onComplete != null)
                        FilledButton(
                          onPressed: widget.onComplete,
                          child: const Text('Mark Complete & Continue'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          );

          final draggableDivider = GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _editorHeight += details.delta.dy;
                // Add some constraints so it doesn't get too small or too large
                if (_editorHeight < 100) _editorHeight = 100;
                final maxHeight = constraints.maxHeight - 100; // Leave space for terminal
                if (_editorHeight > maxHeight) _editorHeight = maxHeight;
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeUpDown,
              child: Container(
                height: 16,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          );

          if (isTablet) {
            // Side-by-side layout: Lesson on Left, Editor+Terminal on Right
            final currentMaxHeight = constraints.maxHeight - 50;
            final effectiveEditorHeight = _editorHeight > currentMaxHeight ? currentMaxHeight : _editorHeight;

            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: lessonContentWidget,
                ),
                VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      SizedBox(height: effectiveEditorHeight, child: editorWidget),
                      draggableDivider,
                      Expanded(child: terminalWidget),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Stacked layout for mobile: Editor on Top, Terminal on Bottom
            // (Lesson content is typically reached via a separate tab or bottom sheet on mobile, omitted here for brevity)
            final currentMaxHeight = constraints.maxHeight - 50; // Leave absolute minimum 50px for terminal/divider
            final effectiveEditorHeight = _editorHeight > currentMaxHeight ? currentMaxHeight : _editorHeight;
            
            return Column(
              children: [
                SizedBox(height: effectiveEditorHeight, child: editorWidget),
                draggableDivider,
                Expanded(child: terminalWidget),
              ],
            );
          }
        },
      ),
    );
  }
}

class _SavedProgramsBottomSheet extends ConsumerWidget {
  const _SavedProgramsBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedProgramsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saved Programs', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (programs) {
                if (programs.isEmpty) {
                  return const Center(child: Text('No saved programs yet.'));
                }
                return ListView.builder(
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    final p = programs[index];
                    return ListTile(
                      title: Text(p.title),
                      subtitle: Text(p.createdAt),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          ref.read(savedProgramsServiceProvider).deleteProgram(p.id);
                        },
                      ),
                      onTap: () => Navigator.pop(context, p.code),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
