import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'independent_flowchart_designer_screen.dart';
import '../../domain/entities/flowchart.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/python.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/github.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
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
  SavedFlowchart? _generatedFlowchart;
  bool _showFlowchartOverlay = false;
  bool _isLoading = false;
  String _output = '';
  String? _savedOutputTabContent;
  List<String> _savedPlotsTabContent = [];
  bool _isSuccess = true;
  
  WebSocketChannel? _wsChannel;
  bool _isWaitingForInput = false;
  final TextEditingController _interactiveInputController = TextEditingController();
  final FocusNode _interactiveInputFocusNode = FocusNode();
  Timer? _saveTimer;
  
  List<String> _plots = [];
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

  void _showIslandNotification(String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60,
        left: 50,
        right: 50,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) entry.remove();
    });
  }

  late final SavedProgramsService _savedProgramsService;

  @override
  void initState() {
    super.initState();
    _savedProgramsService = ref.read(savedProgramsServiceProvider);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (widget.initialSavedProgram != null) {
      _addNewTab(
        initialCode: widget.initialSavedProgram!.code,
        title: widget.initialSavedProgram!.title,
        savedId: widget.initialSavedProgram!.id,
      );
      _output = widget.initialSavedProgram!.terminalOutput ?? '';
      if (widget.initialSavedProgram!.plots != null) {
        _plots = widget.initialSavedProgram!.plots!.map((e) => e.toString()).toList();
      }
    } else if (widget.lessonId != null && widget.inline) {
      // It's a lesson, we should fetch it.
      _isLoading = true;
      _addNewTab(initialCode: "Loading saved program...");
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final service = ref.read(savedProgramsServiceProvider);
        final savedProgram = await service.getProgramForLesson(widget.lessonId!);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          if (savedProgram != null) {
            setState(() {
              _tabs[0].controller.text = savedProgram.code;
              _tabs[0].savedId = savedProgram.id;
              _tabs[0].lastSavedCode = savedProgram.code;
              _savedOutputTabContent = savedProgram.terminalOutput;
              _isSuccess = true;
              if (savedProgram.plots != null) {
                _savedPlotsTabContent = savedProgram.plots!.map((e) => e.toString()).toList();
              }
            });
          } else {
            setState(() {
              _tabs[0].controller.text = widget.contentBody?['starter_code'] ?? '';
              _tabs[0].lastSavedCode = _tabs[0].controller.text;
            });
          }
        }
      });
    } else {
      _addNewTab(initialCode: widget.contentBody?['starter_code']);
    }
  }

  @override
  void dispose() {
    // Auto-save when navigating away
    if (widget.inline && widget.lessonId != null) {
      if (_output.isNotEmpty) {
        _savedOutputTabContent = _output;
        _savedPlotsTabContent = List.from(_plots);
      }
      _saveProgram(); // Fire and forget
    }
    
    for (var tab in _tabs) {
      tab.dispose();
    }
    _output = ''; // Clear output state
    super.dispose();
  }

  void _addNewTab({String? initialCode, String? title, int? savedId}) {
    if (_tabs.length >= 5) {
      _showIslandNotification('Maximum 5 tabs allowed. Please close one to open a new program.');
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
      _currentTabIndex = widget.inline ? 0 : _tabs.length - 1;
      _programCounter++;
    });
  }

  Future<void> _closeTab(int index) async {
    if (_tabs.length == 1) {
      _showIslandNotification('Cannot close the last tab. Clear the code instead.');
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

  ProgramTab get _currentTab => widget.inline ? _tabs.first : _tabs[_currentTabIndex];




  Future<void> _analyzeComplexity() async {
    final code = _currentTab.controller.text;
    if (code.trim().isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final baseUrl = const String.fromEnvironment('API_URL', defaultValue: 'https://pythontutor-api.onrender.com/api/v1');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final res = await http.post(
        Uri.parse('$baseUrl/execute/analyze_complexity'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
      );

      if (mounted) Navigator.pop(context);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Complexity Analysis'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time: ${data['time_complexity']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Space: ${data['space_complexity']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  Text(data['explanation'] ?? ''),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
              ],
            ),
          );
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analysis failed')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _generateFlowchart() async {
    final code = _currentTab.controller.text;
    if (code.trim().isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final baseUrl = const String.fromEnvironment('API_URL', defaultValue: 'https://pythontutor-api.onrender.com/api/v1');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      final res = await http.post(
        Uri.parse('$baseUrl/flowcharts/generate_from_code'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
      );

      if (mounted) Navigator.pop(context);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flowchart generated!')));
          
          final flowchartObj = SavedFlowchart(
            id: 0,
            title: 'AI Generated Flowchart',
            nodes: (data['nodes'] as List<dynamic>?)?.map((e) => FlowchartNode.fromJson(e)).toList() ?? [],
            edges: (data['edges'] as List<dynamic>?)?.map((e) => FlowchartEdge.fromJson(e)).toList() ?? [],
            createdAt: DateTime.now(),
          );

          setState(() {
            _generatedFlowchart = flowchartObj;
            _showFlowchartOverlay = true;
          });
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generation failed')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _runCode() async {
    setState(() {
      _isExecuting = true;
      _output = 'Running ${_currentTab.title}...\n';
      _plots = [];
      _isWaitingForInput = false;
      _isSuccess = true;
    });

    try {
      final baseUrl = const String.fromEnvironment('API_URL', defaultValue: 'https://pythontutor-api.onrender.com/api/v1');
      final wsUrl = baseUrl.replaceFirst('http', 'ws') + '/execute/ws';
      
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _wsChannel!.sink.add(jsonEncode({
        "code": _currentTab.controller.text,
      }));

      _wsChannel!.stream.listen((message) {
        if (!mounted) return;
        final data = jsonDecode(message);
        final type = data['type'];
        final payload = data['data'];

        setState(() {
          if (type == 'stdout' || type == 'stderr') {
            _output += payload;
            if (type == 'stderr') _isSuccess = false;
          } else if (type == 'plot') {
            _plots.add(payload);
          } else if (type == 'input_request') {
            _isWaitingForInput = true;
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) _interactiveInputFocusNode.requestFocus();
            });
          } else if (type == 'completed') {
            _isExecuting = false;
            _isWaitingForInput = false;
            _wsChannel?.sink.close();
            _wsChannel = null;
            _output += '\n\n[Execution Finished]';
            _savedOutputTabContent = _output;
            _savedPlotsTabContent = List.from(_plots);
            _saveProgram();
          }
        });
      }, onError: (error) {
        if (!mounted) return;
        setState(() {
          _output += '\nConnection error: $error';
          _isExecuting = false;
          _isWaitingForInput = false;
          _isSuccess = false;
        });
      }, onDone: () {
        if (!mounted) return;
        setState(() {
          if (_isExecuting) {
             _output += '\n\n[Execution Disconnected]';
          }
          _isExecuting = false;
          _isWaitingForInput = false;
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExecuting = false;
        _isWaitingForInput = false;
        _isSuccess = false;
        _output += '\nFailed to connect: $e';
      });
    }
  }

  Future<void> _saveProgram() async {
    if (_currentTab.controller.text == _currentTab.lastSavedCode && _savedOutputTabContent == _output) return;

    final service = _savedProgramsService;
    
    // If it's already a saved program, update it silently
    if (_currentTab.savedId != null) {
      final success = await service.updateProgram(_currentTab.savedId!, _currentTab.title, _currentTab.controller.text, lessonId: widget.lessonId, terminalOutput: _savedOutputTabContent, plots: _savedPlotsTabContent);
      if (mounted) {
        if (success) {
          setState(() {
            _currentTab.lastSavedCode = _currentTab.controller.text;
          });
        }
        _showIslandNotification(success ? 'Updated successfully!' : 'Failed to update program.');
      }
      return;
    }

    // Otherwise, determine title
    String? title;
    if (widget.inline && widget.lessonId != null) {
      title = 'Lesson ${widget.lessonId} Program';
    } else {
      final asyncPrograms = ref.read(savedProgramsProvider);
      final currentCount = asyncPrograms.maybeWhen(
        data: (list) => list.length,
        orElse: () => 0,
      );

      final titleController = TextEditingController(text: _currentTab.title);
      title = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Save Program', style: TextStyle(fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                ),
                child: Text('$currentCount / 100 Used', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
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
    }

    if (title != null && title.isNotEmpty) {
      final savedProgram = await service.saveProgram(title, _currentTab.controller.text, lessonId: widget.lessonId, terminalOutput: _savedOutputTabContent, plots: _savedPlotsTabContent);
      if (mounted) {
        if (savedProgram != null) {
          setState(() {
            _currentTab.title = title!;
            _currentTab.savedId = savedProgram.id;
            _currentTab.lastSavedCode = _currentTab.controller.text;
          });
          _showIslandNotification('Saved successfully!');
          // Invalidate to refresh the list
          ref.invalidate(savedProgramsProvider);
        } else {
          _showIslandNotification('Failed to save. You may have reached the 100 program limit.');
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
            _output = selectedProgram.terminalOutput ?? '';
            if (selectedProgram.plots != null) {
              _plots = selectedProgram.plots!.map((e) => e.toString()).toList();
            }
          });
        } else {
          _addNewTab(
            initialCode: selectedProgram.code,
            title: selectedProgram.title,
            savedId: selectedProgram.id,
          );
          setState(() {
            _output = selectedProgram.terminalOutput ?? '';
            if (selectedProgram.plots != null) {
              _plots = selectedProgram.plots!.map((e) => e.toString()).toList();
            }
          });
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.code),
              tooltip: 'Insert Example Algorithm',
              onSelected: (value) {
                String newCode = '';
                if (value == 'bubble_sort') {
                  newCode = '''def bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        for j in range(0, n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
    return arr

# Test the function
array = [64, 34, 25, 12, 22, 11, 90]
print("Sorted array is:", bubble_sort(array))
''';
                } else if (value == 'binary_search') {
                  newCode = '''def binary_search(arr, low, high, x):
    if high >= low:
        mid = (high + low) // 2
        if arr[mid] == x:
            return mid
        elif arr[mid] > x:
            return binary_search(arr, low, mid - 1, x)
        else:
            return binary_search(arr, mid + 1, high, x)
    else:
        return -1

# Test the function
arr = [2, 3, 4, 10, 40]
x = 10
result = binary_search(arr, 0, len(arr)-1, x)
print("Element is present at index", result)
''';
                } else if (value == 'fibonacci') {
                  newCode = '''def fibonacci(n):
    if n <= 1:
        return n
    else:
        return(fibonacci(n-1) + fibonacci(n-2))

# Test the function
nterms = 10
print("Fibonacci sequence:")
for i in range(nterms):
    print(fibonacci(i))
''';
                }
                setState(() {
                  _currentTab.controller.text = newCode;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'bubble_sort',
                  child: Text('Bubble Sort'),
                ),
                const PopupMenuItem<String>(
                  value: 'binary_search',
                  child: Text('Binary Search'),
                ),
                const PopupMenuItem<String>(
                  value: 'fibonacci',
                  child: Text('Fibonacci (Recursive)'),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
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
                    itemCount: widget.inline ? 3 : _tabs.length,
                    itemBuilder: (context, index) {
                      String tabTitle;
                      if (widget.inline) {
                        if (index == 0) tabTitle = 'Description';
                        else if (index == 1) tabTitle = 'Program';
                        else tabTitle = 'Output';
                      } else {
                        tabTitle = _tabs[index].title;
                      }

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
                                tabTitle,
                                style: TextStyle(
                                  color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (!widget.inline) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _closeTab(index),
                                  child: Icon(Icons.close, size: 16, color: isSelected ? Colors.grey : Colors.grey.shade600),
                                ),
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (!widget.inline)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addNewTab(),
                    tooltip: 'New Program',
                  ),
                IconButton(
                    icon: const Icon(Icons.text_fields),
                    onPressed: _toggleFontSize,
                    tooltip: 'Toggle Font Size',
                  ),
                if (widget.inline)
                  const ThemeToggleButton(),
                const SizedBox(width: 8),
              ],
            ),
          ),
          
          // Editor Area
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : widget.inline && _currentTabIndex == 0 
              ? Container(
                  color: codeBgColor,
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Html(
                      data: widget.contentBody?['text'] ?? 'No description provided.',
                      style: {
                        "body": Style(
                          fontSize: FontSize(_currentFontSize),
                          lineHeight: LineHeight(1.6),
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      },
                    ),
                  ),
                )
              : widget.inline && _currentTabIndex == 2
              ? Container(
                  color: codeBgColor,
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          _savedOutputTabContent ?? 'No saved output.',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: _currentFontSize,
                            height: 1.6,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (_savedPlotsTabContent.isNotEmpty)
                          ..._savedPlotsTabContent.map((base64String) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Image.memory(
                                base64Decode(base64String),
                                errorBuilder: (context, error, stackTrace) => const Text('Error loading plot', style: TextStyle(color: Colors.red)),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                )
              : CodeTheme(
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
                      bottom: 16,
                      right: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FloatingActionButton(
                            heroTag: 'analyze_btn',
                            onPressed: _analyzeComplexity,
                            backgroundColor: theme.colorScheme.surface,
                            elevation: 4,
                            child: const Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 28),
                          ),
                          const SizedBox(height: 16),
                          FloatingActionButton(
                            heroTag: 'generate_flowchart_btn',
                            onPressed: _generateFlowchart,
                            backgroundColor: theme.colorScheme.surface,
                            elevation: 4,
                            child: const Icon(Icons.account_tree_outlined, color: Colors.purpleAccent, size: 28),
                          ),
                          const SizedBox(height: 16),
                          if (_generatedFlowchart != null) ...[
                            FloatingActionButton(
                              heroTag: 'display_flowchart_btn',
                              onPressed: () {
                                setState(() {
                                  _showFlowchartOverlay = !_showFlowchartOverlay;
                                });
                              },
                              backgroundColor: theme.colorScheme.surface,
                              elevation: 4,
                              child: const Icon(Icons.account_tree, color: Colors.purpleAccent, size: 28),
                            ),
                            const SizedBox(height: 16),
                          ],
                          FloatingActionButton(
                            heroTag: 'run_btn',
                            onPressed: _isExecuting ? null : _runCode,
                            backgroundColor: theme.colorScheme.surface,
                            elevation: 4,
                            child: _isExecuting 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                              : const Icon(Icons.play_arrow, color: Colors.green, size: 32),
                          ),
                        ],
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          _output.isEmpty ? 'Ready.' : _output,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: _isSuccess ? Colors.green.shade400 : (_output.isEmpty ? Colors.grey : Colors.red.shade400),
                            fontSize: _currentFontSize,
                          ),
                        ),
                        if (_isWaitingForInput)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Text('> ', style: TextStyle(color: Colors.green, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: TextField(
                                    controller: _interactiveInputController,
                                    focusNode: _interactiveInputFocusNode,
                                    style: TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: _currentFontSize),
                                    cursorColor: Colors.green,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: 'Type input and press Return...',
                                      hintStyle: TextStyle(color: Colors.white38, fontFamily: 'monospace', fontSize: _currentFontSize * 0.9),
                                    ),
                                    onSubmitted: (val) {
                                      if (_wsChannel != null) {
                                        _wsChannel!.sink.add(jsonEncode({"action": "input", "data": val}));
                                        setState(() {
                                          _isWaitingForInput = false;
                                        });
                                        _interactiveInputController.clear();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_plots.isNotEmpty)
                          ..._plots.map((base64String) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Image.memory(
                                base64Decode(base64String),
                                errorBuilder: (context, error, stackTrace) => const Text('Error loading plot', style: TextStyle(color: Colors.red)),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
              ],
            ),
          ),
          if (widget.inline && widget.onComplete != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.surface,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () async {
                          if (_output.isEmpty) {
                            _showIslandNotification('Please run the program first!');
                            return;
                          }
                          widget.onComplete!();
                        },
                        child: const Text('Mark Complete', textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                        onPressed: () async {
                        if (widget.lessonId == null) {
                          _showIslandNotification('Cannot submit this assignment');
                          return;
                        }
                        
                        setState(() {
                          _isExecuting = true;
                          _output = 'Evaluating against test cases...\n';
                        });

                        try {
                          final service = ref.read(executionProvider);
                          final result = await service.evaluateCode(
                            _currentTab.controller.text, 
                            lessonId: widget.lessonId,
                          );

                          if (!mounted) return;

                          setState(() {
                            _isExecuting = false;
                          });

                          final score = result['score'];
                          final error = result['error'];
                          final passed = result['test_cases_passed'];
                          final total = result['test_cases_total'];
                          final isCompleted = result['status'] == 'completed';

                          if (isCompleted) {
                            _showIslandNotification('Passed! Score: $score');
                          } else if (error != null && passed == null) {
                            _showIslandNotification('Evaluation failed: $error');
                          } else {
                            _showIslandNotification('Passed $passed/$total test cases. Score: $score');
                          }
                          
                          // Show detailed results if available
                          final testResults = result['test_results'] as List<dynamic>?;
                          if (testResults != null && testResults.isNotEmpty) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(isCompleted ? 'Success! 🎉' : 'Evaluation Results'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: testResults.length,
                                    itemBuilder: (context, i) {
                                      final tr = testResults[i];
                                      final bool passed = tr['passed'] ?? false;
                                      return ListTile(
                                        leading: Icon(
                                          passed ? Icons.check_circle : Icons.error,
                                          color: passed ? Colors.green : Colors.red,
                                        ),
                                        title: Text('Test Case ${i+1}'),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Expected: ${tr['expected_output']}\nActual: ${tr['actual_output']}'),
                                            if (tr['error'] != null && tr['error'].toString().isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 8.0),
                                                child: Text(
                                                  'Feedback: ${tr['error']}',
                                                  style: const TextStyle(color: Colors.orange, fontStyle: FontStyle.italic),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                actions: [
                                  if (!isCompleted)
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                                  if (isCompleted)
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        if (widget.onComplete != null) {
                                          widget.onComplete!();
                                        }
                                      },
                                      child: const Text('Continue'),
                                    ),
                                ],
                              ),
                            );
                          } else if (isCompleted && widget.onComplete != null) {
                            // Fallback if no test results for some reason
                            widget.onComplete!();
                          }
                      } catch (e) {
                        if (!mounted) return;
                          setState(() {
                            _isExecuting = false;
                            _output = 'Evaluation failed: $e\n';
                          });
                          _showIslandNotification('Failed to submit assignment.');
                        }
                      },
                      child: const Text('Submit Assignment'),
                    ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      if (_showFlowchartOverlay && _generatedFlowchart != null)
        Positioned.fill(
          child: Container(
            color: Colors.black87,
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Generated Flowchart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _showFlowchartOverlay = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: IndependentFlowchartDesignerScreen(
                      initialFlowchart: _generatedFlowchart,
                    ),
                  ),
                ],
              ),
            ),
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
              Expanded(
                child: Text('Saved Programs', style: theme.textTheme.titleLarge, overflow: TextOverflow.ellipsis),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  asyncPrograms.when(
                    data: (programs) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.5)),
                      ),
                      child: Text('${programs.length} / 100 Used', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
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
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Text('${index + 1}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
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
