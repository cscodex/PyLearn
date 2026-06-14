import 'dart:ui';

enum FlowchartNodeType {
  oval,          // Start/Stop
  parallelogram, // Input/Output
  rectangle,     // Process
  diamond,       // Decision
}

enum FlowchartAnchor {
  top,
  bottom,
  left,
  right,
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
      position: Offset(
        (json['x'] as num?)?.toDouble() ?? 0.0,
        (json['y'] as num?)?.toDouble() ?? 0.0,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'text': text,
      'x': position.dx,
      'y': position.dy,
    };
  }
}

class FlowchartEdge {
  final String fromNodeId;
  final String toNodeId;
  final FlowchartAnchor fromAnchor;
  final FlowchartAnchor toAnchor;
  String? label; // For 'YES' / 'NO' on decisions

  FlowchartEdge({
    required this.fromNodeId,
    required this.toNodeId,
    this.fromAnchor = FlowchartAnchor.bottom,
    this.toAnchor = FlowchartAnchor.top,
    this.label,
  });

  factory FlowchartEdge.fromJson(Map<String, dynamic> json) {
    return FlowchartEdge(
      fromNodeId: json['fromNodeId'] as String,
      toNodeId: json['toNodeId'] as String,
      fromAnchor: FlowchartAnchor.values.firstWhere(
        (e) => e.name == json['fromAnchor'],
        orElse: () => FlowchartAnchor.bottom,
      ),
      toAnchor: FlowchartAnchor.values.firstWhere(
        (e) => e.name == json['toAnchor'],
        orElse: () => FlowchartAnchor.top,
      ),
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'fromAnchor': fromAnchor.name,
      'toAnchor': toAnchor.name,
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

class SavedFlowchart {
  final int id;
  final String title;
  final List<FlowchartNode> nodes;
  final List<FlowchartEdge> edges;
  final DateTime createdAt;

  SavedFlowchart({
    required this.id,
    required this.title,
    required this.nodes,
    required this.edges,
    required this.createdAt,
  });

  factory SavedFlowchart.fromJson(Map<String, dynamic> json) {
    return SavedFlowchart(
      id: json['id'] as int,
      title: json['title'] as String,
      nodes: (json['nodes'] as List<dynamic>?)
          ?.map((e) => FlowchartNode.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      edges: (json['edges'] as List<dynamic>?)
          ?.map((e) => FlowchartEdge.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
