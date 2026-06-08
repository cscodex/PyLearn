import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import '../providers/execution_provider.dart';

class IdeScreen extends ConsumerStatefulWidget {
  final int lessonId;
  final bool inline;
  final VoidCallback? onComplete;
  
  const IdeScreen({super.key, required this.lessonId, this.inline = false, this.onComplete});

  @override
  ConsumerState<IdeScreen> createState() => _IdeScreenState();
}

class _IdeScreenState extends ConsumerState<IdeScreen> {
  late CodeController _controller;
  bool _isExecuting = false;
  String _output = '';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = CodeController(
      text: '# Write your Python code here\nprint("Hello, PythonTutor!")\n',
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
      _output += '\\n\\n[Finished in ${timeMs}ms]';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: widget.inline ? null : AppBar(
        title: const Text('Interactive IDE'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: _isExecuting ? null : _runCode,
              icon: _isExecuting 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.play_arrow),
              label: const Text('Run Code'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
            ),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 800;

          final editorWidget = CodeTheme(
            data: CodeThemeData(styles: monokaiSublimeTheme),
            child: Container(
              color: const Color(0xFF23241f),
              child: SingleChildScrollView(
                child: CodeField(
                  controller: _controller,
                  textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                  background: const Color(0xFF23241f), // monokai background
                ),
              ),
            ),
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
                  'Write a Python program that prints "Hello, PythonTutor!".',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hint: Use the print() function.',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
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

          if (isTablet) {
            // Side-by-side layout: Lesson on Left, Editor+Terminal on Right
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
                      Expanded(flex: 3, child: editorWidget),
                      Container(height: 4, color: theme.colorScheme.primaryContainer),
                      Expanded(flex: 2, child: terminalWidget),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Stacked layout for mobile: Editor on Top, Terminal on Bottom
            // (Lesson content is typically reached via a separate tab or bottom sheet on mobile, omitted here for brevity)
            return Column(
              children: [
                Expanded(flex: 3, child: editorWidget),
                Container(height: 4, color: theme.colorScheme.primaryContainer),
                Expanded(flex: 2, child: terminalWidget),
              ],
            );
          }
        },
      ),
    );
  }
}
