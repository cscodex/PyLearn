import re

with open("frontend/lib/features/creator/presentation/pages/course_editor_screen.dart", "r") as f:
    content = f.read()

# We need to replace the entire _LessonEditorDialogState class
state_class_pattern = r"class _LessonEditorDialogState extends State<_LessonEditorDialog> \{.*?\n\}\n"
# Actually the file ends with this class. Let's find where it starts
start_idx = content.find("class _LessonEditorDialogState extends State<_LessonEditorDialog> {")

new_state_class = """class _LessonEditorDialogState extends State<_LessonEditorDialog> {
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
        String testCode = _solutionCodeCtrl.text + '\\n\\n' + (tc['input'] ?? '');
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
"""

content = content[:start_idx] + new_state_class

# also need to import dio_client
if "import '../../../../core/network/dio_client.dart';" not in content:
    content = content.replace("import '../../../auth/presentation/providers/auth_provider.dart';", 
                              "import '../../../auth/presentation/providers/auth_provider.dart';\nimport '../../../../core/network/dio_client.dart';")

with open("frontend/lib/features/creator/presentation/pages/course_editor_screen.dart", "w") as f:
    f.write(content)

