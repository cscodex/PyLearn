import sys

def patch_file():
    with open('frontend/lib/features/course/presentation/pages/ide_screen.dart', 'r') as f:
        content = f.read()

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

    if "Future<void> _analyzeComplexity() async" not in content:
        content = content.replace("  Future<void> _runCode() async {", analyze_code + "\n  Future<void> _runCode() async {")

    with open('frontend/lib/features/course/presentation/pages/ide_screen.dart', 'w') as f:
        f.write(content)

patch_file()
