import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/flowchart.dart';
import 'flowchart_node_widget.dart';

class DotGridPainter extends CustomPainter {
  final Color dotColor;
  final double spacing;

  DotGridPainter({this.dotColor = Colors.white24, this.spacing = 20.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EdgePainter extends CustomPainter {
  final List<FlowchartNode> nodes;
  final List<FlowchartEdge> edges;

  EdgePainter(this.nodes, this.edges);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var edge in edges) {
      try {
        final fromNode = nodes.firstWhere((n) => n.id == edge.fromNodeId);
        final toNode = nodes.firstWhere((n) => n.id == edge.toNodeId);

        Offset getAnchor(FlowchartNode node, FlowchartAnchor anchor) {
          final center = Offset(node.position.dx + 60, node.position.dy + 30);
          switch (anchor) {
            case FlowchartAnchor.top:
              return Offset(center.dx, node.position.dy);
            case FlowchartAnchor.bottom:
              return Offset(center.dx, node.position.dy + 60);
            case FlowchartAnchor.left:
              return Offset(node.position.dx, center.dy);
            case FlowchartAnchor.right:
              return Offset(node.position.dx + 120, center.dy);
          }
        }

        final fromCenter = getAnchor(fromNode, edge.fromAnchor);
        final toCenter = getAnchor(toNode, edge.toAnchor);

        // Simple straight line
        canvas.drawLine(fromCenter, toCenter, paint);

        // Draw arrow head at the end
        _drawArrowHead(canvas, fromCenter, toCenter, paint);

        // Draw label if exists (e.g. YES/NO)
        if (edge.label != null && edge.label!.isNotEmpty) {
          final midPoint = Offset((fromCenter.dx + toCenter.dx) / 2,
              (fromCenter.dy + toCenter.dy) / 2);
          final textSpan = TextSpan(
            text: edge.label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.black54),
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(
              canvas,
              Offset(midPoint.dx - textPainter.width / 2,
                  midPoint.dy - textPainter.height / 2));
        }
      } catch (e) {
        // Node not found
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double angle = dx == 0 && dy == 0 ? 0 : dy > 0 ? 1.5708 : -1.5708; // simplified
    // A better way to calculate angle:
    final double realAngle = math.atan2(dy, dx);
    
    final arrowLength = 10.0;
    final arrowAngle = 0.5;

    final path = Path();
    path.moveTo(p2.dx, p2.dy);
    path.lineTo(
        p2.dx - arrowLength * math.cos(realAngle - arrowAngle),
        p2.dy - arrowLength * math.sin(realAngle - arrowAngle));
    path.lineTo(
        p2.dx - arrowLength * math.cos(realAngle + arrowAngle),
        p2.dy - arrowLength * math.sin(realAngle + arrowAngle));
    path.close();

    final fillPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant EdgePainter oldDelegate) {
    return true; // Simplified: always repaint on drag
  }
}

class FlowchartCanvas extends StatelessWidget {
  final List<FlowchartNode> nodes;
  final List<FlowchartEdge> edges;
  final String? selectedNodeId;
  final Function(FlowchartNodeType, Offset) onNodeDropped;
  final Function(String, Offset) onNodeDragged;
  final Function(String) onNodeTapped;
  final Function(String, String, FlowchartAnchor, FlowchartAnchor)? onEdgeCreate;

  const FlowchartCanvas({
    super.key,
    required this.nodes,
    required this.edges,
    required this.onNodeDropped,
    required this.onNodeDragged,
    required this.onNodeTapped,
    this.selectedNodeId,
    this.onEdgeCreate,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<FlowchartNodeType>(
      onAcceptWithDetails: (details) {
        // RenderBox get local position
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);
        onNodeDropped(details.data, localPosition);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          color: const Color(0xFF1E1E2C), // Dark background
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(
            painter: DotGridPainter(),
            child: Stack(
              children: [
                // Draw Edges bottom layer
                CustomPaint(
                  painter: EdgePainter(nodes, edges),
                  child: Container(),
                ),
                // Draw Nodes top layer
                ...nodes.map((node) {
                  return Positioned(
                    left: node.position.dx,
                    top: node.position.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        onNodeDragged(
                            node.id,
                            Offset(node.position.dx + details.delta.dx,
                                node.position.dy + details.delta.dy));
                      },
                      child: FlowchartNodeWidget(
                        node: node,
                        isSelected: selectedNodeId == node.id,
                        onTap: () => onNodeTapped(node.id),
                        onEdgeCreate: (fromId, fromAnchor, toAnchor) {
                          onEdgeCreate?.call(fromId, node.id, fromAnchor, toAnchor);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
