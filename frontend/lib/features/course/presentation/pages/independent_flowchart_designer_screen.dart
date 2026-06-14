import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../domain/entities/flowchart.dart';
import '../widgets/flowchart_canvas.dart';
import '../widgets/flowchart_node_widget.dart';
import '../../data/repositories/flowchart_repository.dart';

class IndependentFlowchartDesignerScreen extends ConsumerStatefulWidget {
  final SavedFlowchart? initialFlowchart;

  const IndependentFlowchartDesignerScreen({
    super.key,
    this.initialFlowchart,
  });

  @override
  ConsumerState<IndependentFlowchartDesignerScreen> createState() =>
      _IndependentFlowchartDesignerScreenState();
}

class _IndependentFlowchartDesignerScreenState extends ConsumerState<IndependentFlowchartDesignerScreen> {
  List<FlowchartNode> nodes = [];
  List<FlowchartEdge> edges = [];
  String? selectedNodeId;
  bool isSaving = false;
  bool _isToolboxExpanded = false;
  String flowchartTitle = "My Flowchart";

  @override
  void initState() {
    super.initState();
    if (widget.initialFlowchart != null) {
      nodes = List.from(widget.initialFlowchart!.nodes);
      edges = List.from(widget.initialFlowchart!.edges);
      flowchartTitle = widget.initialFlowchart!.title;
    }
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
        return 'I/O';
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
        selectedNodeId = id;
      } else {
        if (selectedNodeId == id) {
          _showEditDialog(id);
          selectedNodeId = null;
        } else {
          selectedNodeId = id; // Select the new node
        }
      }
    });
  }

  Future<void> _createEdge(String fromId, String toId, FlowchartAnchor fromAnchor, FlowchartAnchor toAnchor) async {
    final exists = edges.any((e) => e.fromNodeId == fromId && e.toNodeId == toId);
    if (exists) return;

    final controller = TextEditingController(text: 'label');
    final String? label = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C3E),
          title: const Text('Edge Label', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g. Yes, No, or blank',
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('No Label', style: TextStyle(color: Colors.white54)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.purpleAccent),
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (label != null) {
      setState(() {
        edges.add(FlowchartEdge(
          fromNodeId: fromId,
          toNodeId: toId,
          fromAnchor: fromAnchor,
          toAnchor: toAnchor,
          label: label.isEmpty ? null : label,
        ));
      });
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
          title: const Text('Edit Node', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  nodes.removeWhere((n) => n.id == id);
                  edges.removeWhere((e) => e.fromNodeId == id || e.toNodeId == id);
                });
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.purpleAccent),
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

  Future<void> _saveFlowchart() async {
    if (nodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some nodes first.')),
      );
      return;
    }

    final controller = TextEditingController(text: flowchartTitle);
    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C3E),
        title: const Text('Save Flowchart', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Flowchart Title',
            labelStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () {
              flowchartTitle = controller.text.trim();
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (shouldSave == true && flowchartTitle.isNotEmpty) {
      setState(() => isSaving = true);
      try {
        final repo = ref.read(flowchartRepositoryProvider);
        await repo.saveFlowchart(flowchartTitle, nodes, edges);
        ref.invalidate(savedFlowchartsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Flowchart saved successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Go back to dashboard
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C3E),
        title: Text(flowchartTitle, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear All',
            onPressed: () {
              setState(() {
                nodes.clear();
                edges.clear();
                selectedNodeId = null;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: FilledButton.icon(
              onPressed: isSaving ? null : _saveFlowchart,
              icon: isSaving 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Icon(Icons.save),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Canvas
          FlowchartCanvas(
            nodes: nodes,
            edges: edges,
            selectedNodeId: selectedNodeId,
            onNodeDropped: _onNodeDropped,
            onNodeDragged: _onNodeDragged,
            onNodeTapped: _onNodeTapped,
            onEdgeCreate: _createEdge,
          ),
          // Floating Toolbox
          Positioned(
            left: 16,
            bottom: 16,
            child: _buildFloatingToolbox(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingToolbox() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isToolboxExpanded) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C3E).withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildDraggableTool(FlowchartNodeType.oval, 'Start/End'),
                const SizedBox(height: 8),
                _buildDraggableTool(FlowchartNodeType.parallelogram, 'I/O'),
                const SizedBox(height: 8),
                _buildDraggableTool(FlowchartNodeType.rectangle, 'Process'),
                const SizedBox(height: 8),
                _buildDraggableTool(FlowchartNodeType.diamond, 'Decision'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          backgroundColor: Colors.purpleAccent,
          onPressed: () {
            setState(() {
              _isToolboxExpanded = !_isToolboxExpanded;
            });
          },
          child: Icon(_isToolboxExpanded ? Icons.close : Icons.build),
        ),
      ],
    );
  }

  Widget _buildDraggableTool(FlowchartNodeType type, String label) {
    return Draggable<FlowchartNodeType>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.7,
          child: SizedBox(
            width: 100,
            height: 50,
            child: FlowchartNodeWidget(
              node: FlowchartNode(
                id: 'temp',
                type: type,
                text: label,
                position: Offset.zero,
              ),
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            SizedBox(
              width: 80,
              height: 40,
              child: FlowchartNodeWidget(
                node: FlowchartNode(
                  id: 'tool',
                  type: type,
                  text: label,
                  position: Offset.zero,
                ),
                isSelected: false,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0;

    const spacing = 20.0;
    
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
