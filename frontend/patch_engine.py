import re

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'r') as f:
    content = f.read()

# Add _generateStaticCode method before _runFlowchart
generate_static_code = """
  void _generateStaticCode() {
    final sortedNodes = List<FlowchartNode>.from(nodes)
      ..sort((a, b) => a.position.dy.compareTo(b.position.dy));
    
    staticPseudocode.clear();
    for (final node in sortedNodes) {
      String text = node.text.trim();
      if (text.isEmpty) continue;
      
      if (node.type == FlowchartNodeType.diamond) {
        text = 'if (' + text.replace('\n', ' ') + ')';
      } else if (node.type == FlowchartNodeType.parallelogram) {
        // keep as is, maybe collapse newlines
      }
      
      staticPseudocode.add({
        'nodeId': node.id,
        'text': text,
        'type': node.type,
      });
    }
    setState(() {});
  }

  Future<void> _runFlowchart() async {"""

content = content.replace("Future<void> _runFlowchart() async {", generate_static_code)

# Insert call to _generateStaticCode inside _runFlowchart
run_init_old = """    setState(() {
      isRunning = true;
      runningNodeId = startNode.id;
      variables.clear();
      arrays.clear();
      consoleOutput.clear();
      iterations = 0;
    });"""

run_init_new = """    _generateStaticCode();
    
    setState(() {
      isRunning = true;
      isPaused = false;
      stepNext = false;
      stepPrev = false;
      executionHistory.clear();
      runningNodeId = startNode.id;
      variables.clear();
      arrays.clear();
      consoleOutput.clear();
      iterations = 0;
    });"""

content = content.replace(run_init_old, run_init_new)

# Update the loop to handle pause/step
loop_old = """    while (currentNodeId != null && isRunning) {
      iterations++;
      if (iterations > 1000) {
        setState(() {
          consoleOutput.add("> Error: Maximum iterations (1000) reached. Infinite loop aborted.");
          isRunning = false;
          runningNodeId = null;
        });
        break;
      }
      
      setState(() => runningNodeId = currentNodeId);
      await Future.delayed(const Duration(milliseconds: 600)); // Node highlight pause"""

loop_new = """    while (currentNodeId != null && isRunning) {
      if (isPaused) {
        if (stepPrev) {
          stepPrev = false;
          if (executionHistory.isNotEmpty) {
            final snapshot = executionHistory.removeLast();
            setState(() {
              runningNodeId = snapshot.runningNodeId;
              variables = Map.from(snapshot.variables);
              arrays = Map.from(snapshot.arrays.map((k, v) => MapEntry(k, List.from(v))));
              consoleOutput = List.from(snapshot.consoleOutput);
              iterations = snapshot.iterations;
            });
            currentNodeId = runningNodeId;
            // Un-animate edge if we step back
            setState(() {
              edgeAnimationProgress = 0.0;
            });
            continue;
          }
        } else if (stepNext) {
          stepNext = false;
        } else {
          await Future.delayed(const Duration(milliseconds: 50));
          continue;
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 600)); // Node highlight pause
      }

      // Push history snapshot before executing this node
      executionHistory.add(ExecutionSnapshot(
        runningNodeId: currentNodeId,
        variables: Map.from(variables),
        arrays: Map.from(arrays.map((k, v) => MapEntry(k, List.from(v)))),
        consoleOutput: List.from(consoleOutput),
        iterations: iterations,
      ));

      iterations++;
      if (iterations > 1000) {
        setState(() {
          consoleOutput.add("> Error: Maximum iterations (1000) reached. Infinite loop aborted.");
          isRunning = false;
          runningNodeId = null;
        });
        break;
      }
      
      setState(() => runningNodeId = currentNodeId);"""

content = content.replace(loop_old, loop_new)

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'w') as f:
    f.write(content)
