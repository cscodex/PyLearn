import 'dart:ui';

enum FlowchartNodeType {
  oval,          // Start/Stop
  parallelogram, // Input/Output
  rectangle,     // Process
  diamond,       // Decision
}

class FlowchartNode {
  final String id;
  FlowchartNodeType type;
  String text;
  Offset position;

  FlowchartNode({
    required this.id,
    required this.type,
    required this.text,
    required this.position,
  });

  factory FlowchartNode.fromJson(Map<String, dynamic> json) {
    return FlowchartNode(
      id: json['id'] as String,
      type: FlowchartNodeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FlowchartNodeType.rectangle,
      ),
      text: json['text'] as String? ?? '',
      position: const Offset(0, 0), // Position is usually client-side state
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'text': text,
    };
  }
}

class FlowchartEdge {
  final String fromNodeId;
  final String toNodeId;
  final String? label; // For 'YES' / 'NO' on decisions

  FlowchartEdge({
    required this.fromNodeId,
    required this.toNodeId,
    this.label,
  });

  factory FlowchartEdge.fromJson(Map<String, dynamic> json) {
    return FlowchartEdge(
      fromNodeId: json['from'] as String,
      toNodeId: json['to'] as String,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': fromNodeId,
      'to': toNodeId,
      if (label != null) 'label': label,
    };
  }
}

class FlowchartPracticalConfig {
  final String problemStatement;
  final List<FlowchartNode> expectedNodes;
  final List<FlowchartEdge> expectedEdges;

  FlowchartPracticalConfig({
    required this.problemStatement,
    required this.expectedNodes,
    required this.expectedEdges,
  });

  factory FlowchartPracticalConfig.fromJson(Map<String, dynamic> json) {
    return FlowchartPracticalConfig(
      problemStatement: json['problem_statement'] as String? ?? 'Build a flowchart.',
      expectedNodes: (json['expected_nodes'] as List<dynamic>?)
          ?.map((e) => FlowchartNode.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      expectedEdges: (json['expected_edges'] as List<dynamic>?)
          ?.map((e) => FlowchartEdge.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}
