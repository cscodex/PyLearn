import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  int? loadedFlowchartId;
  List<FlowchartNode> nodes = [];
  List<FlowchartEdge> edges = [];
  String? selectedNodeId;
  String? selectedEdgeId;
  String? connectingFromNodeId;
  FlowchartAnchor? connectingFromAnchor;
  bool isSaving = false;
  bool _isToolboxExpanded = false;
  String flowchartTitle = "My Flowchart";

  List<String> undoStack = [];
  List<String> redoStack = [];
  final GlobalKey _canvasBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.initialFlowchart != null) {
      loadedFlowchartId = widget.initialFlowchart!.id;
      nodes = List.from(widget.initialFlowchart!.nodes);
      edges = List.from(widget.initialFlowchart!.edges);
      flowchartTitle = widget.initialFlowchart!.title;
    }
  }

  void _saveSnapshot() {
    final state = jsonEncode({
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
    });
    undoStack.add(state);
    if (undoStack.length > 50) {
      undoStack.removeAt(0);
    }
    redoStack.clear();
  }

  void _undo() {
    if (undoStack.isEmpty) return;
    final currentState = jsonEncode({
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
    });
    redoStack.add(currentState);
    _restoreSnapshot(undoStack.removeLast());
  }

  void _redo() {
    if (redoStack.isEmpty) return;
    final currentState = jsonEncode({
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
    });
    undoStack.add(currentState);
    _restoreSnapshot(redoStack.removeLast());
  }

  void _restoreSnapshot(String stateStr) {
    final state = jsonDecode(stateStr);
    setState(() {
      nodes = (state['nodes'] as List).map((n) => FlowchartNode.fromJson(n)).toList();
      edges = (state['edges'] as List).map((e) => FlowchartEdge.fromJson(e)).toList();
      selectedNodeId = null;
      selectedEdgeId = null;
      connectingFromNodeId = null;
      connectingFromAnchor = null;
    });
  }

  void _onNodeDropped(FlowchartNodeType type, Offset localPosition) {
    _saveSnapshot();
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

  void _onNodeTapped(String nodeId) {
    setState(() {
      selectedEdgeId = null;
      if (selectedNodeId == nodeId) {
        selectedNodeId = null;
      } else {
        selectedNodeId = nodeId;
      }
    });
  }

  void _onEdgeTapped(String edgeId) {
    setState(() {
      selectedNodeId = null;
      if (selectedEdgeId == edgeId) {
        selectedEdgeId = null;
      } else {
        selectedEdgeId = edgeId;
      }
    });
  }

  void _onAnchorTapped(String nodeId, FlowchartAnchor anchor) {
    if (connectingFromNodeId == null) {
      // Start connection
      setState(() {
        connectingFromNodeId = nodeId;
        connectingFromAnchor = anchor;
      });
    } else {
      // Finish connection
      if (connectingFromNodeId != nodeId) {
        _createEdge(connectingFromNodeId!, nodeId, connectingFromAnchor!, anchor);
      }
      setState(() {
        connectingFromNodeId = null;
        connectingFromAnchor = null;
      });
    }
  }

  Future<void> _createEdge(String fromId, String toId, FlowchartAnchor fromAnchor, FlowchartAnchor toAnchor) async {
    final exists = edges.any((e) => e.fromNodeId == fromId && e.toNodeId == toId);
    if (exists) return;

    _saveSnapshot();

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

  void _showEditNodeDialog(String id) {
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.purpleAccent),
              onPressed: () {
                _saveSnapshot();
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

  void _showEditEdgeDialog(String id) {
    final edge = edges.firstWhere((e) => '${e.fromNodeId}_${e.toNodeId}' == id);
    final controller = TextEditingController(text: edge.label ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C3E),
          title: const Text('Edit Edge Label', style: TextStyle(color: Colors.white)),
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.purpleAccent),
              onPressed: () {
                _saveSnapshot();
                setState(() {
                  edge.label = controller.text.isEmpty ? null : controller.text;
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
      Fluttertoast.showToast(msg: 'Please add some nodes first.', backgroundColor: Colors.redAccent);
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
        if (loadedFlowchartId != null) {
          await repo.updateFlowchart(loadedFlowchartId!, flowchartTitle, nodes, edges);
        } else {
          final saved = await repo.saveFlowchart(flowchartTitle, nodes, edges);
          loadedFlowchartId = saved.id; // Update ID so subsequent saves overwrite
        }
        
        ref.invalidate(savedFlowchartsProvider);
        if (mounted) {
          Fluttertoast.showToast(msg: 'Flowchart saved successfully!', backgroundColor: Colors.green);
        }
      } catch (e) {
        if (mounted) {
          Fluttertoast.showToast(msg: 'Failed to save: $e', backgroundColor: Colors.redAccent);
        }
      } finally {
        if (mounted) {
          setState(() => isSaving = false);
        }
      }
    }
  }

  Future<void> _downloadFlowchart() async {
    try {
      final boundary = _canvasBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/flowchart.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'Check out my flowchart!');
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: 'Failed to export flowchart: $e', backgroundColor: Colors.redAccent);
      }
    }
  }

  void _showLoadDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C3E),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final flowchartsAsyncValue = ref.watch(savedFlowchartsProvider);

            return flowchartsAsyncValue.when(
              data: (flowcharts) {
                if (flowcharts.isEmpty) {
                  return const Center(child: Text('No saved flowcharts found.', style: TextStyle(color: Colors.white70)));
                }
                return ListView.builder(
                  itemCount: flowcharts.length,
                  itemBuilder: (context, index) {
                    final flowchart = flowcharts[index];
                    return ListTile(
                      title: Text(flowchart.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('${flowchart.nodes.length} nodes', style: const TextStyle(color: Colors.white54)),
                      trailing: const Icon(Icons.download, color: Colors.purpleAccent),
                      onTap: () {
                        setState(() {
                          loadedFlowchartId = flowchart.id;
                          flowchartTitle = flowchart.title;
                          nodes = List.from(flowchart.nodes);
                          edges = List.from(flowchart.edges);
                          selectedNodeId = null;
                          connectingFromNodeId = null;
                          connectingFromAnchor = null;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
            );
          },
        );
      },
    );
  }

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C3E),
          title: const Text('How to Connect Arrows', style: TextStyle(color: Colors.white)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Drag shapes from the purple toolbox onto the grid.', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text('2. Tap a shape to select it.', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text('3. Tap an anchor dot on a shape to start an arrow. It will turn green.', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text('4. Tap an anchor dot on another shape to connect them.', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 8),
              Text('5. Tap a selected shape again to edit or delete it.', style: TextStyle(color: Colors.white70)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it', style: TextStyle(color: Colors.purpleAccent)),
            ),
          ],
        );
      },
    );
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
            icon: const Icon(Icons.folder_open),
            tooltip: 'Load Flowchart',
            onPressed: _showLoadDialog,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Flowchart',
            onPressed: _downloadFlowchart,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Instructions',
            onPressed: _showInstructionsDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Canvas
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedNodeId = null;
                  selectedEdgeId = null;
                  connectingFromNodeId = null;
                  connectingFromAnchor = null;
                });
              },
              child: InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(2000),
                minScale: 0.1,
                maxScale: 5.0,
                child: SizedBox(
                  width: 4000,
                  height: 4000,
                  child: RepaintBoundary(
                    key: _canvasBoundaryKey,
                    child: FlowchartCanvas(
                      nodes: nodes,
                      edges: edges,
                      selectedNodeId: selectedNodeId,
                      selectedEdgeId: selectedEdgeId,
                      onNodeDropped: _onNodeDropped,
                      onNodeDragged: _onNodeDragged,
                      onNodeDragStart: (_) => _saveSnapshot(),
                      onNodeTapped: _onNodeTapped,
                      onNodeDoubleTapped: _showEditNodeDialog,
                      onEdgeTapped: _onEdgeTapped,
                      onEdgeCreate: _createEdge,
                      onAnchorTapped: _onAnchorTapped,
                      isAnchorActive: (id, anchor) => connectingFromNodeId == id && connectingFromAnchor == anchor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Info icon removed from here, as requested
          // Quick Actions for Selected Item
          if (selectedNodeId != null || selectedEdgeId != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  color: const Color(0xFF3E3E5C),
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          tooltip: 'Edit Text',
                          onPressed: () {
                            if (selectedNodeId != null) {
                              _showEditNodeDialog(selectedNodeId!);
                            } else if (selectedEdgeId != null) {
                              _showEditEdgeDialog(selectedEdgeId!);
                            }
                          },
                        ),
                        if (selectedNodeId != null)
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white),
                            tooltip: 'Duplicate',
                            onPressed: () {
                              _saveSnapshot();
                              final node = nodes.firstWhere((n) => n.id == selectedNodeId);
                              setState(() {
                                nodes.add(FlowchartNode(
                                  id: 'node_${DateTime.now().millisecondsSinceEpoch}',
                                  type: node.type,
                                  text: node.text,
                                  position: Offset(node.position.dx + 40, node.position.dy + 40),
                                ));
                              });
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          tooltip: 'Delete',
                          onPressed: () {
                            _saveSnapshot();
                            setState(() {
                              if (selectedNodeId != null) {
                                nodes.removeWhere((n) => n.id == selectedNodeId);
                                edges.removeWhere((e) => e.fromNodeId == selectedNodeId || e.toNodeId == selectedNodeId);
                                if (connectingFromNodeId == selectedNodeId) {
                                  connectingFromNodeId = null;
                                  connectingFromAnchor = null;
                                }
                                selectedNodeId = null;
                              } else if (selectedEdgeId != null) {
                                edges.removeWhere((e) => '${e.fromNodeId}_${e.toNodeId}' == selectedEdgeId);
                                selectedEdgeId = null;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Undo/Redo Buttons
          Positioned(
            right: 16,
            bottom: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'undo',
                  backgroundColor: undoStack.isNotEmpty ? const Color(0xFF2C2C3E) : const Color(0xFF2C2C3E).withOpacity(0.5),
                  onPressed: undoStack.isNotEmpty ? _undo : null,
                  child: Icon(Icons.undo, color: undoStack.isNotEmpty ? Colors.white : Colors.white54),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'redo',
                  backgroundColor: redoStack.isNotEmpty ? const Color(0xFF2C2C3E) : const Color(0xFF2C2C3E).withOpacity(0.5),
                  onPressed: redoStack.isNotEmpty ? _redo : null,
                  child: Icon(Icons.redo, color: redoStack.isNotEmpty ? Colors.white : Colors.white54),
                ),
              ],
            ),
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
                _buildDraggableTool(FlowchartNodeType.oval, Icons.power_input, 'Start/End'),
                const SizedBox(height: 8),
                _buildDraggableTool(FlowchartNodeType.parallelogram, Icons.input, 'I/O'),
                const SizedBox(height: 8),
                _buildDraggableTool(FlowchartNodeType.rectangle, Icons.crop_square, 'Process'),
                const SizedBox(height: 8),
                _buildDraggableTool(FlowchartNodeType.diamond, Icons.change_history, 'Decision'),
                const Divider(color: Colors.white54),
                IconButton(
                  icon: const Icon(Icons.clear_all, color: Colors.redAccent),
                  tooltip: 'Clear Canvas',
                  onPressed: () {
                    _saveSnapshot();
                    setState(() {
                      nodes.clear();
                      edges.clear();
                      selectedNodeId = null;
                      selectedEdgeId = null;
                      connectingFromNodeId = null;
                      connectingFromAnchor = null;
                    });
                  },
                ),
                IconButton(
                  icon: isSaving 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save, color: Colors.greenAccent),
                  tooltip: 'Save',
                  onPressed: isSaving ? null : _saveFlowchart,
                ),
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

  Widget _buildDraggableTool(FlowchartNodeType type, IconData icon, String label) {
    return Draggable<FlowchartNodeType>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: SizedBox(
            width: 120,
            height: 60,
            child: FlowchartNodeWidget(
              node: FlowchartNode(
                id: 'temp',
                type: type,
                text: label,
                position: Offset.zero,
              ),
              isSelected: false,
              isPaletteItem: true,
              onTap: () {},
            ),
          ),
        ),
      ),
      child: Tooltip(
        message: label,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF3E3E5C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white),
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
