import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
import '../providers/execution_provider.dart';
import '../providers/saved_programs_provider.dart';

enum CodeFontSize { small, medium, large }

class ProgramTab {
  String title;
  int? savedId;
  final CodeController controller;
  final TextEditingController inputController;
  String lastSavedCode;

  ProgramTab({
    required this.title,
    this.savedId,
    required this.controller,
    String? initialCode,
  })  : inputController = TextEditingController(),
        lastSavedCode = initialCode ?? '';

  bool get isDirty => controller.text != lastSavedCode;

  void dispose() {
    controller.dispose();
    inputController.dispose();
  }
}

class IdeScreen extends ConsumerStatefulWidget {
  final int? lessonId;
  final bool inline;
  final VoidCallback? onComplete;
  final Map<String, dynamic>? contentBody;
  final SavedProgram? initialSavedProgram;
  
  const IdeScreen({super.key, this.lessonId, this.inline = false, this.onComplete, this.contentBody, this.initialSavedProgram});

  @override
  ConsumerState<IdeScreen> createState() => _IdeScreenState();
}

class _IdeScreenState extends ConsumerState<IdeScreen> {
  final List<ProgramTab> _tabs = [];
  int _currentTabIndex = 0;
  
  bool _isExecuting = false;
  String _output = '';
  bool _isSuccess = false;
  CodeFontSize _fontSize = CodeFontSize.medium;
  double _terminalHeight = 250.0;
  int _programCounter = 1;

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
    if (widget.initialSavedProgram != null) {
      _addNewTab(
        initialCode: widget.initialSavedProgram!.code,
        title: widget.initialSavedProgram!.title,
        savedId: widget.initialSavedProgram!.id,
      );
    } else {
      _addNewTab(initialCode: widget.contentBody?['starter_code']);
    }
  }

  @override
  void dispose() {
    for (var tab in _tabs) {
      tab.dispose();
    }
    super.dispose();
  }

  void _addNewTab({String? initialCode, String? title, int? savedId}) {
    if (_tabs.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 tabs allowed. Please close one to open a new program.')),
      );
      return;
    }

    String starterCode = initialCode ?? '# Write your Python code here\n';
    starterCode = starterCode.trimRight(); 

    final newTab = ProgramTab(
      title: title ?? 'Program $_programCounter',
      savedId: savedId,
      initialCode: starterCode,
      controller: CodeController(
        text: starterCode,
        language: python,
      ),
    );

    setState(() {
      _tabs.add(newTab);
      _currentTabIndex = _tabs.length - 1;
      _programCounter++;
    });
  }

  Future<void> _closeTab(int index) async {
    if (_tabs.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot close the last tab. Clear the code instead.')),
      );
      return;
    }

    if (_tabs[index].isDirty) {
      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: Text('You have unsaved changes in "${_tabs[index].title}". Are you sure you want to close it without saving?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Close Anyway'),
            ),
          ],
        ),
      );

      if (shouldClose != true) return;
    }

    setState(() {
      _tabs[index].dispose();
      _tabs.removeAt(index);
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      }
    });
  }

  ProgramTab get _currentTab => _tabs[_currentTabIndex];

  Future<void> _runCode() async {
    setState(() {
      _isExecuting = true;
      _output = 'Running ${_currentTab.title}...\n';
    });

    final service = ref.read(executionProvider);
    final result = await service.executeCode(
      _currentTab.controller.text, 
      lessonId: widget.lessonId,
      standardInput: _currentTab.inputController.text,
    );

    if (!mounted) return;

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
    final service = ref.read(savedProgramsServiceProvider);
    
    // If it's already a saved program, update it silently
    if (_currentTab.savedId != null) {
      final success = await service.updateProgram(_currentTab.savedId!, _currentTab.title, _currentTab.controller.text);
      if (mounted) {
        if (success) {
          setState(() {
            _currentTab.lastSavedCode = _currentTab.controller.text;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Updated successfully!' : 'Failed to update program.')),
        );
      }
      return;
    }

    // Otherwise, prompt for a name
    final titleController = TextEditingController(text: _currentTab.title);
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
      final savedProgram = await service.saveProgram(title, _currentTab.controller.text);
      if (mounted) {
        if (savedProgram != null) {
          setState(() {
            _currentTab.title = title;
            _currentTab.savedId = savedProgram.id;
            _currentTab.lastSavedCode = _currentTab.controller.text;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved successfully!')),
          );
          // Invalidate to refresh the list
          ref.invalidate(savedProgramsProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save. You may have reached the 100 program limit.')),
          );
        }
      }
    }
  }

  void _loadProgram() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _SavedProgramsBottomSheet(),
    ).then((selectedProgram) {
      if (selectedProgram != null && selectedProgram is SavedProgram) {
        // Check if it's already open
        final existingIndex = _tabs.indexWhere((tab) => tab.savedId == selectedProgram.id);
        if (existingIndex != -1) {
          setState(() {
            _currentTabIndex = existingIndex;
          });
          // Flash effect could be added here, but switching tab is usually enough feedback
          return;
        }

        // If current tab is completely empty/untouched, replace it. Otherwise open new tab.
        if (!_currentTab.isDirty && (_currentTab.controller.text.trim() == '# Write your Python code here' || _currentTab.controller.text.trim().isEmpty)) {
          setState(() {
            _currentTab.title = selectedProgram.title;
            _currentTab.savedId = selectedProgram.id;
            _currentTab.controller.text = selectedProgram.code;
            _currentTab.lastSavedCode = selectedProgram.code;
          });
        } else {
          _addNewTab(
            initialCode: selectedProgram.code,
            title: selectedProgram.title,
            savedId: selectedProgram.id,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final isDark = theme.brightness == Brightness.dark;
    final codeTheme = isDark ? monokaiSublimeTheme : githubTheme;
    final codeBgColor = isDark ? const Color(0xFF23241f) : Colors.white;
    final codeTextColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: widget.inline ? null : AppBar(
        title: Text('Interactive IDE - ${_currentTab.title}'),
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
                backgroundColor: Colors.green.withValues(alpha: 0.2),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      final tab = _tabs[index];
                      final isSelected = index == _currentTabIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentTabIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? codeBgColor : theme.colorScheme.surfaceContainerHighest,
                            border: Border(
                              bottom: BorderSide(
                                color: isSelected ? Colors.blue : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                tab.title,
                                style: TextStyle(
                                  color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _closeTab(index),
                                child: Icon(Icons.close, size: 16, color: isSelected ? Colors.grey : Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addNewTab(),
                  tooltip: 'New Program',
                ),
              ],
            ),
          ),
          
          // Editor Area
          Expanded(
            child: CodeTheme(
              data: CodeThemeData(styles: codeTheme),
              child: Container(
                color: codeBgColor,
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: CodeField(
                        controller: _currentTab.controller,
                        textStyle: TextStyle(fontFamily: 'monospace', fontSize: _currentFontSize, color: codeTextColor),
                        background: codeBgColor,
                        gutterStyle: const GutterStyle(
                          margin: 0,
                          width: 40,
                          showLineNumbers: true,
                          showErrors: false,
                          showFoldingHandles: false,
                        ),
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
                '{', '}', '[', ']', '(', ')', '=', ':', ';', '\'', '"', '+', '-', '_', '<', '>', '/', '*'
              ].map((symbol) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: ActionChip(
                  label: Text(symbol, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                  padding: EdgeInsets.zero,
                  backgroundColor: theme.colorScheme.surface,
                  onPressed: () {
                    final text = _currentTab.controller.text;
                    final selection = _currentTab.controller.selection;
                    if (selection.baseOffset >= 0 && selection.extentOffset >= 0) {
                      final newText = text.replaceRange(selection.start, selection.end, symbol);
                      _currentTab.controller.value = _currentTab.controller.value.copyWith(
                        text: newText,
                        selection: TextSelection.collapsed(offset: selection.start + symbol.length),
                      );
                    } else {
                      _currentTab.controller.text = text + symbol;
                    }
                  },
                ),
              )).toList(),
            ),
          ),
          // Drag Splitter
          GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _terminalHeight -= details.delta.dy;
                // Clamp terminal height between 100 and screen height - 200
                _terminalHeight = _terminalHeight.clamp(100.0, MediaQuery.of(context).size.height - 200.0);
              });
            },
            child: Container(
              height: 12,
              color: theme.colorScheme.surfaceContainerHighest,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          
          // Terminal & Input Area
          SizedBox(
            height: _terminalHeight,
            child: Column(
              children: [
                // Standard Input Area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surface,
            child: TextField(
              controller: _currentTab.inputController,
              decoration: const InputDecoration(
                labelText: 'Standard Input (for input() function)',
                labelStyle: TextStyle(fontSize: 12),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              maxLines: 2,
              minLines: 1,
            ),
          ),
          
          // Terminal Output
          Expanded(
            child: Container(
              width: double.infinity,
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Colors.grey.shade900,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      const Text('Terminal', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (_isExecuting)
                        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: SelectableText(
                      _output.isEmpty ? 'Ready.' : _output,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: _isSuccess ? Colors.green.shade400 : (_output.isEmpty ? Colors.grey : Colors.red.shade400),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
              ],
            ),
          ),
          if (widget.inline)
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _saveProgram,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.tonalIcon(
                    onPressed: _isExecuting ? null : _runCode,
                    icon: _isExecuting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow),
                    label: const Text('Run Code'),
                  ),
                  const SizedBox(width: 16),
                  if (widget.onComplete != null)
                    FilledButton(
                      onPressed: widget.onComplete,
                      child: const Text('Mark Complete & Continue'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SavedProgramsBottomSheet extends ConsumerWidget {
  const _SavedProgramsBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPrograms = ref.watch(savedProgramsProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Saved Programs', style: theme.textTheme.titleLarge),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          Expanded(
            child: asyncPrograms.when(
              data: (programs) {
                if (programs.isEmpty) {
                  return const Center(child: Text('No saved programs yet.'));
                }
                return ListView.builder(
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    final program = programs[index];
                    return ListTile(
                      leading: const Icon(Icons.description, color: Colors.blue),
                      title: Text(program.title),
                      subtitle: Text('Saved: ${program.createdAt.split('T').first}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          ref.read(savedProgramsServiceProvider).deleteProgram(program.id);
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context, program);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
