import 'package:flutter/material.dart';
import '../../domain/entities/flowchart.dart';

class FlowchartShapePainter extends CustomPainter {
  final FlowchartNodeType type;
  final Color borderColor;
  final Color fillColor;

  FlowchartShapePainter({
    required this.type,
    required this.borderColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    Path path = Path();

    switch (type) {
      case FlowchartNodeType.oval:
        final rect = Rect.fromLTWH(0, 0, size.width, size.height);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2)),
            fillPaint);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2)),
            borderPaint);
        break;
      case FlowchartNodeType.rectangle:
        final rect = Rect.fromLTWH(0, 0, size.width, size.height);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(8.0)),
            fillPaint);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(8.0)),
            borderPaint);
        break;
      case FlowchartNodeType.parallelogram:
        final skew = size.height * 0.3; // horizontal offset
        path.moveTo(skew, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width - skew, size.height);
        path.lineTo(0, size.height);
        path.close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
        break;
      case FlowchartNodeType.diamond:
        path.moveTo(size.width / 2, 0);
        path.lineTo(size.width, size.height / 2);
        path.lineTo(size.width / 2, size.height);
        path.lineTo(0, size.height / 2);
        path.close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, borderPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant FlowchartShapePainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.fillColor != fillColor;
  }
}

class FlowchartNodeWidget extends StatelessWidget {
  final FlowchartNode node;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final bool isSelected;
  final bool isPaletteItem;
  final bool isHighlighted; // For flowchart runner
  final List<FlowchartEdge> edges; // Passed down to check for connected anchors
  final Function(String fromNodeId, FlowchartAnchor fromAnchor, FlowchartAnchor toAnchor)? onEdgeCreate;
  final Function(String nodeId, FlowchartAnchor anchor)? onAnchorTapped;
  final bool Function(String nodeId, FlowchartAnchor anchor)? isAnchorActive;

  const FlowchartNodeWidget({
    super.key,
    required this.node,
    this.onTap,
    this.onDoubleTap,
    this.isSelected = false,
    this.isPaletteItem = false,
    this.isHighlighted = false,
    this.edges = const [],
    this.onEdgeCreate,
    this.onAnchorTapped,
    this.isAnchorActive,
  });

  Color _getBorderColor() {
    if (isHighlighted) return const Color(0xFFFFD600); // Bright yellow for running
    if (isSelected && !isPaletteItem) return Colors.white;
    switch (node.type) {
      case FlowchartNodeType.oval:
        return Colors.pinkAccent;
      case FlowchartNodeType.parallelogram:
        return Colors.lightBlueAccent;
      case FlowchartNodeType.rectangle:
        return Colors.greenAccent;
      case FlowchartNodeType.diamond:
        return Colors.amberAccent;
    }
  }

  Color _getFillColor() {
    if (isHighlighted) return const Color(0xFFFFD600).withOpacity(0.35);
    return _getBorderColor().withOpacity(0.15);
  }

  Widget _buildAnchor(FlowchartAnchor anchor, double left, double top) {
    if (isPaletteItem) return const SizedBox.shrink();

    final bool isConnected = edges.any((e) =>
        (e.fromNodeId == node.id && e.fromAnchor == anchor) ||
        (e.toNodeId == node.id && e.toAnchor == anchor));

    if (isConnected) return const SizedBox.shrink(); // Hide connected anchors

    final bool isActive = isAnchorActive?.call(node.id, anchor) ?? false;
    return Positioned(
      left: left - 15,
      top: top - 15,
      child: GestureDetector(
        onTap: () {
          onAnchorTapped?.call(node.id, anchor);
        },
        child: Container(
          width: 30,
          height: 30,
          color: Colors.transparent, // larger hit area
          alignment: Alignment.center,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: isActive 
                  ? Colors.greenAccent 
                  : (isSelected ? Colors.blueAccent : Colors.white24),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: isSelected || isActive ? 2 : 1),
              boxShadow: isActive ? [BoxShadow(color: Colors.greenAccent, blurRadius: 10, spreadRadius: 2)] : null,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = isPaletteItem ? 60.0 : 120.0;
    final height = isPaletteItem ? 40.0 : 60.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: Container(
            width: width,
            height: height,
            decoration: isHighlighted
                ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD600).withOpacity(0.7),
                        blurRadius: 25,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFFD600).withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 15,
                      ),
                    ],
                  )
                : isSelected && !isPaletteItem
                ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: _getBorderColor().withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      )
                    ],
                  )
                : null,
            child: CustomPaint(
              painter: FlowchartShapePainter(
                type: node.type,
                borderColor: _getBorderColor(),
                fillColor: _getFillColor(),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    node.text,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isPaletteItem ? 10 : 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildAnchor(FlowchartAnchor.top, width / 2, 0),
        _buildAnchor(FlowchartAnchor.bottom, width / 2, height),
        _buildAnchor(FlowchartAnchor.left, 0, height / 2),
        _buildAnchor(FlowchartAnchor.right, width, height / 2),
      ],
    );
  }
}
