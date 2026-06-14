import 'package:flutter/material.dart';
import '../../domain/entities/flowchart.dart';
import '../widgets/flowchart_canvas.dart';
import '../widgets/flowchart_node_widget.dart';

class FlowchartPracticalScreen extends StatefulWidget {
  final Map<String, dynamic>? contentBody;
  final VoidCallback onComplete;

  const FlowchartPracticalScreen({
    super.key,
    required this.contentBody,
    required this.onComplete,
  });

  @override
  State<FlowchartPracticalScreen> createState() =>
      _FlowchartPracticalScreenState();
}

class _FlowchartPracticalScreenState extends State<FlowchartPracticalScreen> {
  late FlowchartPracticalConfig config;
  List<FlowchartNode> nodes = [];
  List<FlowchartEdge> edges = [];
  String? selectedNodeId;

  @override
  void initState() {
    super.initState();
    config = FlowchartPracticalConfig.fromJson(widget.contentBody ?? {});
  }

  void _onNodeDropped(FlowchartNodeType type, Offset localPosition) {
    setState(() {
      final newNode = FlowchartNode(
        id: 'node_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        text: _getDefaultTextForType(type),
        position: Offset(localPosition.dx - 60, localPosition.dy - 30),
      );
      nodes.add(newNode);
    });
  }

  String _getDefaultTextForType(FlowchartNodeType type) {
    switch (type) {
      case FlowchartNodeType.oval:
        return 'START/END';
      case FlowchartNodeType.parallelogram:
        return 'INPUT/OUTPUT';
      case FlowchartNodeType.rectangle:
        return 'PROCESS';
      case FlowchartNodeType.diamond:
        return 'DECISION';
    }
  }

  void _onNodeDragged(String id, Offset newPosition) {
    setState(() {
      final nodeIndex = nodes.indexWhere((n) => n.id == id);
      if (nodeIndex != -1) {
        nodes[nodeIndex].position = newPosition;
      }
    });
  }

  void _onNodeTapped(String id) {
    setState(() {
      if (selectedNodeId == null) {
        // Select the node
        selectedNodeId = id;
      } else {
        if (selectedNodeId == id) {
          // Deselect or show edit dialog
          _showEditDialog(id);
          selectedNodeId = null;
        } else {
          // Create edge from selected to this
          _createEdge(selectedNodeId!, id);
          selectedNodeId = null;
        }
      }
    });
  }

  void _createEdge(String fromId, String toId) {
    // Check if edge already exists
    final exists = edges
        .any((e) => e.fromNodeId == fromId && e.toNodeId == toId);
    if (!exists) {
      edges.add(FlowchartEdge(fromNodeId: fromId, toNodeId: toId));
    }
  }

  void _showEditDialog(String id) {
    final node = nodes.firstWhere((n) => n.id == id);
    final controller = TextEditingController(text: node.text);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C3E),
          title: const Text('Edit Node Text',
              style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.purpleAccent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Delete node
                setState(() {
                  nodes.removeWhere((n) => n.id == id);
                  edges.removeWhere(
                      (e) => e.fromNodeId == id || e.toNodeId == id);
                });
                Navigator.pop(context);
              },
              child: const Text('Delete Node',
                  style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.purpleAccent),
              onPressed: () {
                setState(() {
                  node.text = controller.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _submitFlowchart() {
    // Basic MVP lenient validation
    // Check if the counts of node types roughly match the expected
    final userTypes = nodes.map((n) => n.type).toList();
    final expectedTypes = config.expectedNodes.map((n) => n.type).toList();

    int matchedCount = 0;
    for (var expected in expectedTypes) {
      if (userTypes.contains(expected)) {
        matchedCount++;
        userTypes.remove(expected); // avoid double counting
      }
    }

    final double accuracy = expectedTypes.isEmpty ? 1.0 : matchedCount / expectedTypes.length;

    if (accuracy >= 0.8 && edges.length >= expectedTypes.length - 1) {
      // Success!
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C3E),
          title: const Text('Success! 🎉',
              style: TextStyle(color: Colors.white)),
          content: const Text(
              'Great job building the flowchart logic!',
              style: TextStyle(color: Colors.white70)),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
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
      // Failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not quite right. Make sure you used the correct shapes and connected them!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Palette Bar
        Container(
          height: 80,
          color: const Color(0xFF2A2A3C),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: FlowchartNodeType.values.map((type) {
              final dummyNode = FlowchartNode(
                  id: 'dummy',
                  type: type,
                  text: _getDefaultTextForType(type),
                  position: Offset.zero);
              return Draggable<FlowchartNodeType>(
                data: type,
                feedback: Material(
                  color: Colors.transparent,
                  child: FlowchartNodeWidget(
                      node: dummyNode, isPaletteItem: true),
                ),
                child: FlowchartNodeWidget(
                    node: dummyNode, isPaletteItem: true),
              );
            }).toList(),
          ),
        ),
        // Problem Statement
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: const Color(0xFF1E1E2C),
          child: Text(
            config.problemStatement,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        // Instruction
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 8.0),
          color: const Color(0xFF1E1E2C),
          child: const Text(
            "Drag shapes to canvas. Tap a shape to select it, then tap another to connect. Double-tap/Tap selected to edit text.",
            style: TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        // Canvas
        Expanded(
          child: FlowchartCanvas(
            nodes: nodes,
            edges: edges,
            selectedNodeId: selectedNodeId,
            onNodeDropped: _onNodeDropped,
            onNodeDragged: _onNodeDragged,
            onNodeTapped: _onNodeTapped,
          ),
        ),
        // Submit Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: const Color(0xFF2A2A3C),
          child: FilledButton(
            onPressed: _submitFlowchart,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Submit Flowchart',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
