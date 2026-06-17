import re

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'r') as f:
    content = f.read()

# Insert ExecutionSnapshot class before _IndependentFlowchartDesignerScreenState
snapshot_class = """
// Debugger State Snapshot for Prev/Next
class ExecutionSnapshot {
  final String? runningNodeId;
  final Map<String, double> variables;
  final Map<String, List<dynamic>> arrays;
  final List<String> consoleOutput;
  final int iterations;

  ExecutionSnapshot({
    required this.runningNodeId,
    required this.variables,
    required this.arrays,
    required this.consoleOutput,
    required this.iterations,
  });

  ExecutionSnapshot clone() {
    return ExecutionSnapshot(
      runningNodeId: runningNodeId,
      variables: Map.from(variables),
      arrays: Map.from(arrays.map((k, v) => MapEntry(k, List.from(v)))),
      consoleOutput: List.from(consoleOutput),
      iterations: iterations,
    );
  }
}
"""

content = content.replace("class _IndependentFlowchartDesignerScreenState", snapshot_class + "\nclass _IndependentFlowchartDesignerScreenState")

# Replace Runner state variables
old_runner_state = """  // Runner state
  bool isRunning = false;
  String? runningNodeId;
  Map<String, double> variables = {};
  Map<String, List<double>> arrays = {};
  int iterations = 0;
  List<String> consoleOutput = [];"""

new_runner_state = """  // Runner state
  bool isRunning = false;
  bool isPaused = false;
  bool stepNext = false;
  bool stepPrev = false;
  String? runningNodeId;
  Map<String, double> variables = {};
  Map<String, List<dynamic>> arrays = {};
  int iterations = 0;
  List<String> consoleOutput = [];
  List<ExecutionSnapshot> executionHistory = [];
  
  // Static Pseudo-code generation
  List<Map<String, dynamic>> staticPseudocode = []; // Stores {nodeId: ..., text: ...}"""

content = content.replace(old_runner_state, new_runner_state)

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'w') as f:
    f.write(content)
