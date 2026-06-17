import re

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'r') as f:
    code = f.read()

# Replace class names
code = code.replace('IndependentFlowchartDesignerScreen', 'FlowchartPracticalScreen')
code = code.replace('_IndependentFlowchartDesignerScreenState', '_FlowchartPracticalScreenState')

# Replace widget properties
code = re.sub(
    r'class FlowchartPracticalScreen extends ConsumerStatefulWidget \{\n  final SavedFlowchart\? initialFlowchart;\n\n  const FlowchartPracticalScreen\(\{\n    super.key,\n    this.initialFlowchart,\n  \}\);',
    '''class FlowchartPracticalScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? contentBody;
  final VoidCallback onComplete;

  const FlowchartPracticalScreen({
    super.key,
    required this.contentBody,
    required this.onComplete,
  });''',
    code
)

# Replace state variables and initState safely
init_state_replacement = '''late FlowchartPracticalConfig config;
  
  @override
  void initState() {
    super.initState();
    config = FlowchartPracticalConfig.fromJson(widget.contentBody ?? {});
  }'''
code = re.sub(
    r'  @override\n  void initState\(\) \{\n    super\.initState\(\);\n    if \(widget\.initialFlowchart != null\) \{\n[^\}]+ \}\n  \}',
    init_state_replacement,
    code
)

# Add verification logic _submitFlowchart BEFORE _saveFlowchart
submit_logic = '''
  void _submitFlowchart() {
    final userTypes = nodes.map((n) => n.type).toList();
    final expectedTypes = config.expectedNodes.map((n) => n.type).toList();

    int matchedCount = 0;
    for (var expected in expectedTypes) {
      if (userTypes.contains(expected)) {
        matchedCount++;
        userTypes.remove(expected);
      }
    }

    final double accuracy = expectedTypes.isEmpty ? 1.0 : matchedCount / expectedTypes.length;

    if (accuracy >= 0.8 && edges.length >= expectedTypes.length - 1) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C3E),
          title: const Text('Success! 🎉', style: TextStyle(color: Colors.white)),
          content: const Text('Great job building the flowchart logic!', style: TextStyle(color: Colors.white70)),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(context);
                widget.onComplete();
              },
              child: const Text('Continue'),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not quite right. Make sure you used the correct shapes and connected them!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _saveFlowchart() async {'''

code = code.replace('  Future<void> _saveFlowchart() async {', submit_logic)

# Add FlowchartPracticalConfig to imports
if 'package:flutter_riverpod/flutter_riverpod.dart' in code:
    code = code.replace("import '../../domain/entities/flowchart.dart';", "import '../../domain/entities/flowchart.dart';\nimport '../../domain/entities/lesson.dart';")

# We also need to add the FAB for submitting
fab_replacement = '''
      floatingActionButton: FloatingActionButton(
        onPressed: _submitFlowchart,
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.check, color: Colors.black),
      ),
'''

code = re.sub(
    r'      floatingActionButton: null, // Removed FAB in favor of top app bar action',
    fab_replacement,
    code
)

with open('lib/features/course/presentation/pages/flowchart_practical_screen.dart', 'w') as f:
    f.write(code)

