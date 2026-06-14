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
  final bool isSelected;
  final bool isPaletteItem;

  const FlowchartNodeWidget({
    super.key,
    required this.node,
    this.onTap,
    this.isSelected = false,
    this.isPaletteItem = false,
  });

  Color _getBorderColor() {
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
    return _getBorderColor().withOpacity(0.15);
  }

  @override
  Widget build(BuildContext context) {
    final width = isPaletteItem ? 60.0 : 120.0;
    final height = isPaletteItem ? 40.0 : 60.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: isSelected && !isPaletteItem
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
    );
  }
}
