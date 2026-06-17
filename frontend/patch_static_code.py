import re

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'r') as f:
    content = f.read()

static_code_old = """  void _generateStaticCode() {
    final sortedNodes = List<FlowchartNode>.from(nodes)
      ..sort((a, b) => a.position.dy.compareTo(b.position.dy));
    
    staticPseudocode.clear();
    for (final node in sortedNodes) {
      String text = node.text.trim();
      if (text.isEmpty) continue;
      
      if (node.type == FlowchartNodeType.diamond) {
        text = 'if (' + text.replaceAll('\\n', ' ') + ')';
      } else if (node.type == FlowchartNodeType.parallelogram) {"""

static_code_new = """  void _generateStaticCode() {
    final sortedNodes = List<FlowchartNode>.from(nodes)
      ..sort((a, b) => a.position.dy.compareTo(b.position.dy));
    
    staticPseudocode.clear();
    for (final node in sortedNodes) {
      String text = node.text.trim();
      if (text.isEmpty) continue;
      
      if (node.type == FlowchartNodeType.diamond) {
        // Check if any outgoing edge points to a node higher up (y coordinate is smaller) -> indicates a loop
        bool isLoop = false;
        final outgoingEdges = edges.where((e) => e.fromNodeId == node.id).toList();
        for (final edge in outgoingEdges) {
           final targetNode = nodes.firstWhere((n) => n.id == edge.toNodeId, orElse: () => node);
           if (targetNode.position.dy <= node.position.dy && targetNode.id != node.id) {
              isLoop = true;
              break;
           }
        }
        if (isLoop) {
           text = 'while (' + text.replaceAll('\\n', ' ') + ')';
        } else {
           text = 'if (' + text.replaceAll('\\n', ' ') + ')';
        }
      } else if (node.type == FlowchartNodeType.parallelogram) {"""

content = content.replace(static_code_old, static_code_new)

with open('lib/features/course/presentation/pages/independent_flowchart_designer_screen.dart', 'w') as f:
    f.write(content)
