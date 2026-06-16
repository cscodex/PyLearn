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
  final String? selectedEdgeId;
  final String? animatingEdgeFromId;
  final String? animatingEdgeToId;
  final double edgeAnimationProgress;

  EdgePainter(this.nodes, this.edges, {this.selectedEdgeId, this.animatingEdgeFromId, this.animatingEdgeToId, this.edgeAnimationProgress = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
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

        final isSelected = selectedEdgeId == '${edge.fromNodeId}_${edge.toNodeId}';
        final paint = Paint()
          ..color = isSelected ? Colors.blueAccent : Colors.white54
          ..strokeWidth = isSelected ? 3.0 : 2.0
          ..style = PaintingStyle.stroke;

        final fromCenter = getAnchor(fromNode, edge.fromAnchor);
        final toCenter = getAnchor(toNode, edge.toAnchor);

        // Bezier curve control points
        Offset getControlPoint(Offset pt, FlowchartAnchor anchor, double offset) {
          switch (anchor) {
            case FlowchartAnchor.top: return Offset(pt.dx, pt.dy - offset);
            case FlowchartAnchor.bottom: return Offset(pt.dx, pt.dy + offset);
            case FlowchartAnchor.left: return Offset(pt.dx - offset, pt.dy);
            case FlowchartAnchor.right: return Offset(pt.dx + offset, pt.dy);
          }
        }

        final dist = (fromCenter - toCenter).distance;
        final cpOffset = dist * 0.4; // 40% of distance makes a smooth curve
        
        final cp1 = getControlPoint(fromCenter, edge.fromAnchor, cpOffset);
        final cp2 = getControlPoint(toCenter, edge.toAnchor, cpOffset);

        final edgePath = Path();
        edgePath.moveTo(fromCenter.dx, fromCenter.dy);
        edgePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, toCenter.dx, toCenter.dy);
        
        canvas.drawPath(edgePath, paint);

        // Draw arrow head at the end, angled from the second control point to the destination
        _drawArrowHead(canvas, cp2, toCenter, paint);

        // Draw label if exists (e.g. YES/NO)
        if (edge.label != null && edge.label!.isNotEmpty) {
          // Approximate midpoint of the cubic bezier curve using 0.5 t
          final midX = 0.125 * fromCenter.dx + 0.375 * cp1.dx + 0.375 * cp2.dx + 0.125 * toCenter.dx;
          final midY = 0.125 * fromCenter.dy + 0.375 * cp1.dy + 0.375 * cp2.dy + 0.125 * toCenter.dy;
          final midPoint = Offset(midX, midY);
          final lowerLabel = edge.label!.toLowerCase().trim();
          bool isTrue = lowerLabel == 'true' || lowerLabel == 'yes';
          bool isFalse = lowerLabel == 'false' || lowerLabel == 'no';
          bool isAnimating = edge.fromNodeId == animatingEdgeFromId && edge.toNodeId == animatingEdgeToId;
          bool isHighlighted = (isTrue || isFalse) && isAnimating;
          
          Color textColor = Colors.white;
          if (isHighlighted) {
            textColor = isTrue ? Colors.greenAccent : Colors.redAccent;
          }

          final textSpan = TextSpan(
            text: edge.label,
            style: TextStyle(
                color: textColor,
                fontSize: isHighlighted ? 18 : 12,
                fontWeight: FontWeight.bold,
                backgroundColor: isHighlighted ? Colors.black87 : Colors.black54,
                shadows: isHighlighted ? [Shadow(color: textColor, blurRadius: 15), Shadow(color: textColor, blurRadius: 5)] : null,
            ),
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

        // Draw traveling light orb on animating edge
        if (edge.fromNodeId == animatingEdgeFromId && edge.toNodeId == animatingEdgeToId && edgeAnimationProgress > 0) {
          final t = edgeAnimationProgress;
          // Cubic bezier point at t
          final mt = 1.0 - t;
          final orbX = mt*mt*mt*fromCenter.dx + 3*mt*mt*t*cp1.dx + 3*mt*t*t*cp2.dx + t*t*t*toCenter.dx;
          final orbY = mt*mt*mt*fromCenter.dy + 3*mt*mt*t*cp1.dy + 3*mt*t*t*cp2.dy + t*t*t*toCenter.dy;
          final orbCenter = Offset(orbX, orbY);

          // Outer glow
          canvas.drawCircle(orbCenter, 18, Paint()..color = const Color(0xFFFFD600).withOpacity(0.15));
          // Mid glow
          canvas.drawCircle(orbCenter, 10, Paint()..color = const Color(0xFFFFD600).withOpacity(0.4));
          // Core
          canvas.drawCircle(orbCenter, 5, Paint()..color = const Color(0xFFFFD600)..style = PaintingStyle.fill);
          // Bright center
          canvas.drawCircle(orbCenter, 2, Paint()..color = Colors.white..style = PaintingStyle.fill);

          // Draw trail behind the orb
          for (int i = 1; i <= 5; i++) {
            final trailT = t - i * 0.04;
            if (trailT < 0) break;
            final tmt = 1.0 - trailT;
            final tx = tmt*tmt*tmt*fromCenter.dx + 3*tmt*tmt*trailT*cp1.dx + 3*tmt*trailT*trailT*cp2.dx + trailT*trailT*trailT*toCenter.dx;
            final ty = tmt*tmt*tmt*fromCenter.dy + 3*tmt*tmt*trailT*cp1.dy + 3*tmt*trailT*trailT*cp2.dy + trailT*trailT*trailT*toCenter.dy;
            final opacity = 0.3 * (1.0 - i / 6.0);
            final radius = 5.0 * (1.0 - i / 6.0);
            canvas.drawCircle(Offset(tx, ty), radius, Paint()..color = const Color(0xFFFFD600).withOpacity(opacity));
          }
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
  final String? selectedEdgeId;
  final String? runningNodeId;
  final String? animatingEdgeFromId;
  final String? animatingEdgeToId;
  final double edgeAnimationProgress;
  final Function(FlowchartNodeType, Offset) onNodeDropped;
  final Function(String, Offset) onNodeDragged;
  final Function(String) onNodeTapped;
  final Function(String)? onNodeDoubleTapped;
  final Function(String)? onNodeDragStart;
  final Function(String)? onEdgeTapped;
  final Function(String, String, FlowchartAnchor, FlowchartAnchor)? onEdgeCreate;
  final Function(String nodeId, FlowchartAnchor anchor)? onAnchorTapped;
  final bool Function(String nodeId, FlowchartAnchor anchor)? isAnchorActive;

  const FlowchartCanvas({
    super.key,
    required this.nodes,
    required this.edges,
    required this.onNodeDropped,
    required this.onNodeDragged,
    required this.onNodeTapped,
    this.onNodeDoubleTapped,
    this.onNodeDragStart,
    this.selectedNodeId,
    this.selectedEdgeId,
    this.runningNodeId,
    this.animatingEdgeFromId,
    this.animatingEdgeToId,
    this.edgeAnimationProgress = 0.0,
    this.onEdgeTapped,
    this.onEdgeCreate,
    this.onAnchorTapped,
    this.isAnchorActive,
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
            child: GestureDetector(
              onTapUp: (details) {
                // Find edge tapped near midpoint
                for (final edge in edges) {
                  final fromNode = nodes.firstWhere((n) => n.id == edge.fromNodeId, orElse: () => nodes.first);
                  final toNode = nodes.firstWhere((n) => n.id == edge.toNodeId, orElse: () => nodes.first);
                  if (fromNode == toNode) continue;

                  final fromCenter = getAnchor(fromNode, edge.fromAnchor);
                  final toCenter = getAnchor(toNode, edge.toAnchor);
                  
                  final midPoint = getBezierMidPoint(fromCenter, toCenter, edge.fromAnchor, edge.toAnchor);

                  if ((details.localPosition - midPoint).distance < 40) {
                    onEdgeTapped?.call('${edge.fromNodeId}_${edge.toNodeId}');
                    return;
                  }
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Draw Edges bottom layer
                  CustomPaint(
                    painter: EdgePainter(nodes, edges, selectedEdgeId: selectedEdgeId, animatingEdgeFromId: animatingEdgeFromId, animatingEdgeToId: animatingEdgeToId, edgeAnimationProgress: edgeAnimationProgress),
                    child: Container(),
                  ),
                  // Draw Edge Labels
                  ...edges.where((e) => e.label != null && e.label!.isNotEmpty).map((edge) {
                    final fromNode = nodes.firstWhere((n) => n.id == edge.fromNodeId, orElse: () => nodes.first);
                    final toNode = nodes.firstWhere((n) => n.id == edge.toNodeId, orElse: () => nodes.first);
                    if (fromNode == toNode) return const SizedBox.shrink();

                    final fromCenter = getAnchor(fromNode, edge.fromAnchor);
                    final toCenter = getAnchor(toNode, edge.toAnchor);
                    final midPoint = getBezierMidPoint(fromCenter, toCenter, edge.fromAnchor, edge.toAnchor);

                    return Positioned(
                      left: midPoint.dx - 50,
                      top: midPoint.dy - 15,
                      child: GestureDetector(
                        onTap: () => onEdgeTapped?.call('${edge.fromNodeId}_${edge.toNodeId}'),
                        child: Container(
                          width: 100,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C3E),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: selectedEdgeId == '${edge.fromNodeId}_${edge.toNodeId}' 
                                ? Colors.blueAccent 
                                : Colors.white24,
                            ),
                          ),
                          child: Text(
                            edge.label!,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Draw Nodes top layer
                  ...nodes.map((node) {
                    return Positioned(
                      left: node.position.dx,
                      top: node.position.dy,
                      child: GestureDetector(
                        onPanStart: (_) => onNodeDragStart?.call(node.id),
                        onPanUpdate: (details) {
                          onNodeDragged(
                              node.id,
                              Offset(node.position.dx + details.delta.dx,
                                  node.position.dy + details.delta.dy));
                        },
                        child: FlowchartNodeWidget(
                          node: node,
                          isSelected: selectedNodeId == node.id,
                          isHighlighted: runningNodeId == node.id,
                          edges: edges,
                          onTap: () => onNodeTapped(node.id),
                          onDoubleTap: () => onNodeDoubleTapped?.call(node.id),
                          onEdgeCreate: (fromId, fromAnchor, toAnchor) {
                            onEdgeCreate?.call(fromId, node.id, fromAnchor, toAnchor);
                          },
                          onAnchorTapped: onAnchorTapped,
                          isAnchorActive: isAnchorActive,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

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

Offset getBezierMidPoint(Offset fromCenter, Offset toCenter, FlowchartAnchor fromAnchor, FlowchartAnchor toAnchor) {
  Offset getControlPoint(Offset pt, FlowchartAnchor anchor, double offset) {
    switch (anchor) {
      case FlowchartAnchor.top: return Offset(pt.dx, pt.dy - offset);
      case FlowchartAnchor.bottom: return Offset(pt.dx, pt.dy + offset);
      case FlowchartAnchor.left: return Offset(pt.dx - offset, pt.dy);
      case FlowchartAnchor.right: return Offset(pt.dx + offset, pt.dy);
    }
  }

  final dist = (fromCenter - toCenter).distance;
  final cpOffset = dist * 0.4;
  final cp1 = getControlPoint(fromCenter, fromAnchor, cpOffset);
  final cp2 = getControlPoint(toCenter, toAnchor, cpOffset);

  final midX = 0.125 * fromCenter.dx + 0.375 * cp1.dx + 0.375 * cp2.dx + 0.125 * toCenter.dx;
  final midY = 0.125 * fromCenter.dy + 0.375 * cp1.dy + 0.375 * cp2.dy + 0.125 * toCenter.dy;
  return Offset(midX, midY);
}
