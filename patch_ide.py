import sys

def patch_file():
    with open('frontend/lib/features/course/presentation/pages/ide_screen.dart', 'r') as f:
        content = f.read()

    # Move run button to bottom right
    stack_old = """                    SingleChildScrollView(
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
                  ],"""
    stack_new = """                    SingleChildScrollView(
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
                      child: FloatingActionButton(
                        onPressed: _isExecuting ? null : _runCode,
                        backgroundColor: theme.colorScheme.surface,
                        elevation: 4,
                        child: _isExecuting 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                          : const Icon(Icons.play_arrow, color: Colors.green, size: 32),
                      ),
                    ),
                  ],"""
    content = content.replace(stack_old, stack_new)

    toolbar_old = """                // Top Terminal Toolbar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: theme.colorScheme.surface,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _isExecuting ? null : _runCode,
                        icon: _isExecuting 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.play_arrow, color: Colors.green),
                        tooltip: 'Run Code',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
          Expanded(
            child: Container(
              width: double.infinity,"""
    toolbar_new = """          Expanded(
            child: Container(
              width: double.infinity,"""
    content = content.replace(toolbar_old, toolbar_new)

    # Add imports
    if "import 'package:http/http.dart' as http;" not in content:
        content = content.replace("import 'dart:convert';", "import 'dart:convert';\nimport 'package:http/http.dart' as http;\nimport '../../domain/entities/flowchart.dart';")

    # Add methods
    analyze_code = """
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
      final token = await widget.tokenProvider();
      
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
      final token = await widget.tokenProvider();
      
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
            nodes: data['nodes'] ?? [],
            edges: data['edges'] ?? [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndependentFlowchartDesignerScreen(
                initialFlowchart: flowchartObj,
              ),
            ),
          );
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
"""
    if "_analyzeComplexity" not in content:
        content = content.replace("void _runCode() {", analyze_code + "\n  void _runCode() {")

    # Add appbar buttons
    appbar_old = """
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
"""
    appbar_new = """
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
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.blueAccent),
            tooltip: 'Analyze Complexity',
            onPressed: _analyzeComplexity,
          ),
          IconButton(
            icon: const Icon(Icons.account_tree_outlined, color: Colors.purpleAccent),
            tooltip: 'Generate Flowchart',
            onPressed: _generateFlowchart,
          ),
"""
    content = content.replace(appbar_old, appbar_new)

    with open('frontend/lib/features/course/presentation/pages/ide_screen.dart', 'w') as f:
        f.write(content)

patch_file()
