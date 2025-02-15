import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class DrawingCanvas extends StatefulWidget {
  final ui.Image image;
  final Function(ui.Image) onMaskComplete;

  const DrawingCanvas({
    super.key,
    required this.image,
    required this.onMaskComplete,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  final List<Offset?> _points = [];
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          RenderBox renderBox = context.findRenderObject() as RenderBox;
          _points.add(renderBox.globalToLocal(details.globalPosition));
        });
      },
      onPanEnd: (details) => _points.add(null),
      child: CustomPaint(
        painter: MaskPainter(
          image: widget.image,
          points: _points,
        ),
        size: Size(widget.image.width.toDouble(), widget.image.height.toDouble()),
      ),
    );
  }

  Future<void> createMask() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    MaskPainter(
      image: widget.image,
      points: _points,
    ).paint(canvas, Size(widget.image.width.toDouble(), widget.image.height.toDouble()));
    
    final picture = recorder.endRecording();
    final mask = await picture.toImage(
      widget.image.width,
      widget.image.height,
    );
    
    widget.onMaskComplete(mask);
  }
}

class MaskPainter extends CustomPainter {
  final ui.Image image;
  final List<Offset?> points;

  MaskPainter({required this.image, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 30.0;

    canvas.drawImage(image, Offset.zero, Paint());

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(MaskPainter oldDelegate) => true;
} 