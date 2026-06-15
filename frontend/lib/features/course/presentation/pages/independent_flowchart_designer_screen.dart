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
import 'package:gal/gal.dart';
import 'package:math_expressions/math_expressions.dart' hide Stack;
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

class _IndependentFlowchartDesignerScreenState extends ConsumerState<IndependentFlowchartDesignerScreen> with TickerProviderStateMixin {
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

  // Runner state
  bool isRunning = false;
  String? runningNodeId;
  Map<String, double> variables = {};
  Map<String, List<double>> arrays = {};
  int iterations = 0;
  List<String> consoleOutput = [];

  // Edge animation state
  String? animatingEdgeFromId;
  String? animatingEdgeToId;
  double edgeAnimationProgress = 0.0;
  AnimationController? _edgeAnimController;

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

  @override
  void dispose() {
    _edgeAnimController?.dispose();
    super.dispose();
  }

  Future<void> _animateEdgeTraversal(String fromNodeId, String toNodeId) async {
    _edgeAnimController?.dispose();
    _edgeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    setState(() {
      animatingEdgeFromId = fromNodeId;
      animatingEdgeToId = toNodeId;
      edgeAnimationProgress = 0.0;
      runningNodeId = null; // Dim the node while light travels
    });
    _edgeAnimController!.addListener(() {
      setState(() {
        edgeAnimationProgress = _edgeAnimController!.value;
      });
    });
    await _edgeAnimController!.forward();
    setState(() {
      animatingEdgeFromId = null;
      animatingEdgeToId = null;
      edgeAnimationProgress = 0.0;
    });
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

  Future<Uint8List?> _getRenderedImageBytes() async {
    final boundary = _canvasBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.0);
    
    if (nodes.isEmpty) {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final node in nodes) {
      if (node.position.dx < minX) minX = node.position.dx;
      if (node.position.dy < minY) minY = node.position.dy;
      if (node.position.dx + 160 > maxX) maxX = node.position.dx + 160;
      if (node.position.dy + 80 > maxY) maxY = node.position.dy + 80;
    }

    const padding = 40.0;
    minX -= padding;
    minY -= padding;
    maxX += padding;
    maxY += padding;

    if (minX < 0) minX = 0;
    if (minY < 0) minY = 0;
    if (maxX > 4000) maxX = 4000;
    if (maxY > 4000) maxY = 4000;

    final pixelRatio = 2.0;
    final cropRect = Rect.fromLTRB(
      minX * pixelRatio,
      minY * pixelRatio,
      maxX * pixelRatio,
      maxY * pixelRatio,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    canvas.drawImageRect(
      image,
      cropRect,
      Rect.fromLTWH(0, 0, cropRect.width, cropRect.height),
      Paint(),
    );
    
    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(cropRect.width.toInt(), cropRect.height.toInt());
    final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _downloadFlowchart() async {
    try {
      final bytes = await _getRenderedImageBytes();
      if (bytes == null) return;
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/flowchart.png');
      await file.writeAsBytes(bytes);

      if (mounted) {
        await Share.shareXFiles([XFile(file.path)], text: 'Check out my flowchart!');
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: 'Failed to export flowchart: $e', backgroundColor: Colors.redAccent);
      }
    }
  }

  Future<void> _saveToGallery() async {
    try {
      final bytes = await _getRenderedImageBytes();
      if (bytes == null) return;
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/flowchart_save.png');
      await file.writeAsBytes(bytes);

      await Gal.putImage(file.path);
      
      if (mounted) {
        Fluttertoast.showToast(msg: 'Saved to Gallery!', backgroundColor: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: 'Failed to save to gallery: $e', backgroundColor: Colors.redAccent);
      }
    }
  }

  Future<void> _runFlowchart() async {
    if (nodes.isEmpty) return;
    
    // Find START node
    final startNode = nodes.firstWhere(
      (n) => n.type == FlowchartNodeType.oval && n.text.toUpperCase().contains('START'),
      orElse: () => nodes.firstWhere((n) => n.type == FlowchartNodeType.oval),
    );

    setState(() {
      isRunning = true;
      runningNodeId = startNode.id;
      variables.clear();
      arrays.clear();
      consoleOutput.clear();
      iterations = 0;
    });

    String? currentNodeId = startNode.id;

    while (currentNodeId != null && isRunning) {
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
      await Future.delayed(const Duration(milliseconds: 600)); // Node highlight pause

      if (!isRunning) break;

      final node = nodes.firstWhere((n) => n.id == currentNodeId);

      if (node.type == FlowchartNodeType.oval && node.text.toUpperCase().contains('END') && node.id != startNode.id) {
        setState(() {
          consoleOutput.add("> Execution finished.");
          isRunning = false;
          runningNodeId = null;
        });
        break;
      } else if (node.type == FlowchartNodeType.parallelogram) {
        // I/O Node (Multi-line support)
        final lines = node.text.split('\n');
        for (var rawLine in lines) {
          if (!isRunning) break;
          final line = rawLine.trim();
          if (line.isEmpty) continue;
          
          if (line.toLowerCase().startsWith('input')) {
            final vars = line.substring(5).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            for (final v in vars) {
              final value = await _promptInput(v);
              if (value != null) {
                variables[v] = value;
                setState(() => consoleOutput.add("> Input $v = $value"));
              }
            }
          } else if (line.toLowerCase().startsWith('print')) {
            final exprStr = line.substring(5).trim();
            // Advanced Print Evaluator (split by commas outside quotes)
            List<String> outputParts = [];
            bool inQuotes = false;
            String currentPart = "";
            for (int i = 0; i < exprStr.length; i++) {
              final c = exprStr[i];
              if (c == '"' || c == "'") {
                inQuotes = !inQuotes;
                currentPart += c;
              } else if (c == ',' && !inQuotes) {
                outputParts.add(currentPart);
                currentPart = "";
              } else {
                currentPart += c;
              }
            }
            if (currentPart.isNotEmpty) outputParts.add(currentPart);
            
            String finalPrint = "> ";
            for (final partRaw in outputParts) {
              final part = partRaw.trim();
              if (part.startsWith('"') || part.startsWith("'")) {
                finalPrint += part.replaceAll('"', '').replaceAll("'", '');
              } else {
                 try {
                    if (arrays.containsKey(part)) {
                       final list = arrays[part]!;
                       final formattedList = list.map((e) => e == e.truncateToDouble() ? e.toInt() : e).toList();
                       finalPrint += formattedList.toString();
                    } else {
                       final res = _evalExpr(part);
                       // Format to drop .0 if integer
                       if (res == res.truncateToDouble()) {
                          finalPrint += res.toInt().toString();
                       } else {
                          finalPrint += res.toString();
                       }
                    }
                 } catch (_) {
                    finalPrint += part; // fallback to raw string if not evaluatable
                 }
              }
            }
            setState(() => consoleOutput.add(finalPrint));
          }
        }
      } else if (node.type == FlowchartNodeType.rectangle) {
        // Process Node (Multi-line support with arrays)
        final lines = node.text.split('\n');
        for (var rawLine in lines) {
          final line = rawLine.trim();
          if (line.isEmpty) continue;
          
          // swap arr[i], arr[j]
          if (line.toLowerCase().startsWith('swap ')) {
            final swapExpr = line.substring(5).trim();
            final swapParts = swapExpr.split(',').map((s) => s.trim()).toList();
            if (swapParts.length == 2) {
              try {
                final v1 = _resolveArrayAccess(swapParts[0]);
                final v2 = _resolveArrayAccess(swapParts[1]);
                if (v1 != null && v2 != null) {
                  final temp = v1['value'] as double;
                  _setArrayElement(swapParts[0], v2['value'] as double);
                  _setArrayElement(swapParts[1], temp);
                  setState(() => consoleOutput.add("> Swapped ${swapParts[0]} ↔ ${swapParts[1]}"));
                }
              } catch (e) {
                setState(() => consoleOutput.add("> Error in swap: $e"));
              }
            }
          } else if (line.contains('=')) {
            final eqIndex = line.indexOf('=');
            // Check it's not == 
            if (eqIndex > 0 && line[eqIndex - 1] != '!' && line[eqIndex - 1] != '<' && line[eqIndex - 1] != '>' && (eqIndex + 1 >= line.length || line[eqIndex + 1] != '=')) {
              final lhs = line.substring(0, eqIndex).trim();
              final rhs = line.substring(eqIndex + 1).trim();
              
              // Array initialization: arr = [1, 2, 3]
              if (rhs.startsWith('[') && rhs.endsWith(']')) {
                final inner = rhs.substring(1, rhs.length - 1);
                final elements = inner.split(',').map((e) => _evalExpr(e.trim())).toList();
                arrays[lhs] = elements;
                setState((){});
              }
              // Array element write: arr[i] = expr
              else if (lhs.contains('[') && lhs.contains(']')) {
                final val = _evalExpr(rhs);
                _setArrayElement(lhs, val);
                setState((){});
              }
              // len(arr)
              else if (rhs.startsWith('len(') && rhs.endsWith(')')) {
                final arrName = rhs.substring(4, rhs.length - 1).trim();
                if (arrays.containsKey(arrName)) {
                  variables[lhs] = arrays[arrName]!.length.toDouble();
                } else {
                  variables[lhs] = 0;
                }
                setState((){});
              }
              // Array element read: x = arr[i]
              else {
                try {
                  final val = _evalExpr(rhs);
                  variables[lhs] = val;
                  setState((){});
                } catch (e) {
                  setState(() => consoleOutput.add("> Error evaluating $rhs: $e"));
                }
              }
            }
          }
        }
      }

      // Find next node
      String? nextNodeId;

      if (node.type == FlowchartNodeType.diamond) {
         // Decision Node with full operator support
         final text = node.text.trim();
         bool result = false;
         
         try {
            String op = '';
            List<String> parts = [];
            
            // Check operators in correct order (longer first)
            if (text.contains('>=')) {
               op = '>=';
               parts = text.split('>=');
            } else if (text.contains('<=')) {
               op = '<=';
               parts = text.split('<=');
            } else if (text.contains('!=')) {
               op = '!=';
               parts = text.split('!=');
            } else if (text.contains('==')) {
               op = '==';
               parts = text.split('==');
            } else if (text.contains('>')) {
               op = '>';
               parts = text.split('>');
            } else if (text.contains('<')) {
               op = '<';
               parts = text.split('<');
            }

            if (parts.length == 2 && op.isNotEmpty) {
               double left = _evalExpr(parts[0].trim());
               double right = _evalExpr(parts[1].trim());
               
               switch (op) {
                 case '>': result = left > right; break;
                 case '<': result = left < right; break;
                 case '>=': result = left >= right; break;
                 case '<=': result = left <= right; break;
                 case '==': result = left == right; break;
                 case '!=': result = left != right; break;
               }
            }
            setState(() => consoleOutput.add("> Condition ($text) evaluated to ${result ? 'True' : 'False'}"));
         } catch (e) {
            setState(() => consoleOutput.add("> Error evaluating condition $text"));
         }

         // Look for matching edge
         final outgoing = edges.where((e) => e.fromNodeId == node.id).toList();
         final targetLabel = result ? ['yes', 'true'] : ['no', 'false'];
         
         final match = outgoing.firstWhere(
           (e) => e.label != null && targetLabel.contains(e.label!.toLowerCase().trim()),
           orElse: () => outgoing.isNotEmpty ? outgoing.first : FlowchartEdge(fromNodeId: '', toNodeId: '', fromAnchor: FlowchartAnchor.top, toAnchor: FlowchartAnchor.top),
         );
         
         if (match.fromNodeId.isNotEmpty) nextNodeId = match.toNodeId;

      } else {
         final outgoing = edges.where((e) => e.fromNodeId == node.id).toList();
         if (outgoing.isNotEmpty) {
           nextNodeId = outgoing.first.toNodeId;
         }
      }

      if (nextNodeId == null) {
        setState(() {
           consoleOutput.add("> Execution finished. No more steps.");
           isRunning = false;
           runningNodeId = null;
        });
        break;
      }

      // Animate light traveling along the edge to the next node
      if (isRunning && currentNodeId != null) {
        await _animateEdgeTraversal(currentNodeId!, nextNodeId);
      }
      
      currentNodeId = nextNodeId;
    }
  }

  double _evalExpr(String exprStr) {
    // Check if it's an array access like arr[i]
    final arrVal = _resolveArrayAccess(exprStr);
    if (arrVal != null) return arrVal['value'] as double;
    
    // Otherwise it's a normal math expression
    final p = Parser();
    final exp = p.parse(exprStr);
    final cm = ContextModel();
    variables.forEach((key, val) => cm.bindVariableName(key, Number(val)));
    return exp.evaluate(EvaluationType.REAL, cm);
  }

  Map<String, dynamic>? _resolveArrayAccess(String exprStr) {
    exprStr = exprStr.trim();
    if (!exprStr.contains('[') || !exprStr.endsWith(']')) return null;
    
    final bracketIndex = exprStr.indexOf('[');
    final arrName = exprStr.substring(0, bracketIndex).trim();
    final indexExpr = exprStr.substring(bracketIndex + 1, exprStr.length - 1).trim();
    
    if (arrays.containsKey(arrName)) {
      final index = _evalExpr(indexExpr).toInt();
      final list = arrays[arrName]!;
      if (index >= 0 && index < list.length) {
        return {'array': arrName, 'index': index, 'value': list[index]};
      } else {
        throw Exception("Index $index out of bounds for array $arrName (length ${list.length})");
      }
    }
    return null;
  }

  void _setArrayElement(String exprStr, double value) {
    exprStr = exprStr.trim();
    final bracketIndex = exprStr.indexOf('[');
    final arrName = exprStr.substring(0, bracketIndex).trim();
    final indexExpr = exprStr.substring(bracketIndex + 1, exprStr.length - 1).trim();
    
    if (arrays.containsKey(arrName)) {
      final index = _evalExpr(indexExpr).toInt();
      final list = arrays[arrName]!;
      if (index >= 0 && index < list.length) {
        list[index] = value;
      } else {
         throw Exception("Index $index out of bounds for array $arrName (length ${list.length})");
      }
    } else {
       throw Exception("Array $arrName not initialized. Initialize with $arrName = [...] first.");
    }
  }

  Future<double?> _promptInput(String varName) async {
     final controller = TextEditingController();
     final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
           return AlertDialog(
              backgroundColor: const Color(0xFF2C2C3E),
              title: Text('Input $varName', style: const TextStyle(color: Colors.white)),
              content: TextField(
                 controller: controller,
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
                 style: const TextStyle(color: Colors.white),
                 decoration: const InputDecoration(
                    hintText: 'Enter a number',
                    hintStyle: TextStyle(color: Colors.white54),
                 ),
              ),
              actions: [
                 FilledButton(
                    onPressed: () => Navigator.pop(context, controller.text),
                    child: const Text('Submit'),
                 )
              ],
           );
        }
     );
     if (result != null && result.isNotEmpty) {
        return double.tryParse(result);
     }
     return 0.0;
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
          title: const Text('Flowchart Syntax Guide', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: SizedBox(
            width: double.maxFinite,
            height: 420,
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const TabBar(
                    isScrollable: true,
                    indicatorColor: Colors.purpleAccent,
                    labelColor: Colors.purpleAccent,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(text: 'Basics'),
                      Tab(text: 'Process'),
                      Tab(text: 'I/O'),
                      Tab(text: 'Decision'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // BASICS TAB
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _helpSection('How to Build', [
                                '1. Drag shapes from the toolbox',
                                '2. Tap a shape to select it',
                                '3. Tap anchor dot → tap another anchor to connect',
                                '4. Double-tap a shape to edit text',
                                '5. Label decision edges "Yes" / "No"',
                                '6. Press ▶ Play to simulate',
                              ]),
                              _helpSection('Shape Types', [
                                '⬭ Oval → Start / End',
                                '▱ Parallelogram → Input / Output',
                                '▭ Rectangle → Process (code)',
                                '◇ Diamond → Decision (condition)',
                              ]),
                            ],
                          ),
                        ),
                        // PROCESS TAB
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _helpSection('Variables', [
                                'x = 5',
                                'y = x + 10',
                                'z = x * y - 3',
                              ]),
                              _helpSection('Arrays', [
                                'arr = [5, 3, 8, 1, 2]',
                                'x = arr[i]       ← read element',
                                'arr[i] = x       ← write element',
                                'n = len(arr)     ← array length',
                                'swap arr[i], arr[j]  ← swap',
                              ]),
                              _helpSection('Multi-line', [
                                'Write multiple lines:',
                                'i = 0',
                                'j = n - 1',
                                'temp = arr[i]',
                              ]),
                            ],
                          ),
                        ),
                        // I/O TAB
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _helpSection('Input', [
                                'input x          ← prompt for x',
                                'input x, y       ← prompt multiple',
                              ]),
                              _helpSection('Print', [
                                'print x',
                                'print "Sum = ", x + y',
                                'print arr         ← print array',
                                'print arr[i]      ← print element',
                                'print "Sorted: ", arr',
                              ]),
                            ],
                          ),
                        ),
                        // DECISION TAB
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _helpSection('Operators', [
                                'x > 5      ← greater than',
                                'x < 10     ← less than',
                                'x >= 5     ← greater or equal',
                                'x <= 10    ← less or equal',
                                'x == 0     ← equal to',
                                'x != y     ← not equal',
                              ]),
                              _helpSection('Array Conditions', [
                                'arr[j] > arr[j+1]',
                                'i < len(arr)',
                                'arr[i] != 0',
                              ]),
                              _helpSection('Edge Labels', [
                                'Label edges "Yes" or "No"',
                                'Also accepts "True" / "False"',
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it!', style: TextStyle(color: Colors.purpleAccent)),
            ),
          ],
        );
      },
    );
  }

  static Widget _helpSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 3),
            child: Text(item, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12)),
          )),
        ],
      ),
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
          if (isRunning)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.redAccent),
              tooltip: 'Stop',
              onPressed: () {
                 setState(() {
                    isRunning = false;
                    runningNodeId = null;
                 });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.greenAccent),
              tooltip: 'Run Flowchart',
              onPressed: _runFlowchart,
            ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Save to Gallery',
            onPressed: _saveToGallery,
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Share Image',
            onPressed: _downloadFlowchart,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Load Flowchart',
            onPressed: _showLoadDialog,
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
                      runningNodeId: runningNodeId,
                      animatingEdgeFromId: animatingEdgeFromId,
                      animatingEdgeToId: animatingEdgeToId,
                      edgeAnimationProgress: edgeAnimationProgress,
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
          // Console Output for Runner
          if (isRunning || consoleOutput.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 100,
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                  boxShadow: [
                    BoxShadow(color: Colors.greenAccent.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                    BoxShadow(color: Colors.purpleAccent.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Left Side: Console Output
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Console Output', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                                onPressed: () => setState(() => consoleOutput.clear()),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24),
                          Expanded(
                            child: ListView.builder(
                              itemCount: consoleOutput.length,
                              itemBuilder: (context, index) {
                                return Text(
                                  consoleOutput[index],
                                  style: const TextStyle(color: Colors.green, fontFamily: 'monospace', fontSize: 13),
                                );
                              },
                            ),
                          ),
                          // Array Visualization Bar (Only shown if arrays exist)
                          if (arrays.isNotEmpty) ...[
                            const Divider(color: Colors.white24),
                            const Text('Array Visualization', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: arrays.length,
                                itemBuilder: (context, arrIndex) {
                                  final arrName = arrays.keys.elementAt(arrIndex);
                                  final arr = arrays[arrName]!;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(arrName, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                        Row(
                                          children: List.generate(arr.length, (idx) {
                                            final val = arr[idx];
                                            final displayVal = val == val.truncateToDouble() ? val.toInt().toString() : val.toString();
                                            return Container(
                                              width: 36,
                                              height: 36,
                                              margin: const EdgeInsets.only(right: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white10,
                                                border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(displayVal, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                                  Text('$idx', style: const TextStyle(color: Colors.white38, fontSize: 8)),
                                                ],
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const VerticalDivider(color: Colors.white24, width: 24),
                    // Right Side: State & Complexity
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('State & Complexity', style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                          const Divider(color: Colors.white24),
                          const Text('State Variables', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Expanded(
                            child: (variables.isEmpty && arrays.isEmpty)
                              ? const Text('No variables', style: TextStyle(color: Colors.white54, fontSize: 12))
                              : ListView(
                                  padding: EdgeInsets.zero,
                                  children: [
                                    ...variables.entries.map((e) {
                                      final val = e.value;
                                      final displayVal = val == val.truncateToDouble() ? val.toInt().toString() : val.toString();
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(e.key, style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 13)),
                                            Text(displayVal, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13)),
                                          ],
                                        ),
                                      );
                                    }),
                                    ...arrays.entries.map((e) {
                                      final displayList = e.value.map((v) => v == v.truncateToDouble() ? v.toInt() : v).toList();
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(e.key, style: const TextStyle(color: Colors.orangeAccent, fontFamily: 'monospace', fontSize: 13)),
                                            Text(displayList.toString(), style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13)),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                          ),
                          const Divider(color: Colors.white24),
                          const Text('Algorithm Metrics', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Iterations', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('$iterations', style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Space', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('O(${variables.length + arrays.values.fold<int>(0, (sum, list) => sum + list.length)})', style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Time', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('O(N)', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
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
