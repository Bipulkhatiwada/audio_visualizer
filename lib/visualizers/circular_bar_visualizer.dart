// Original source code from
// - https://github.com/iamSahdeep/FlutterVisualizers

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class _CircularBarVisualizer extends CustomPainter {
  final List<int> data;
  Float32List? points;

  final Color color;
  final Paint wavePaint;
  final int gap;
  double radius = -1;

  _CircularBarVisualizer({
    required this.data,
    required this.color,
    this.gap = 2,
  }) : wavePaint = Paint()
          ..color = color.withValues(alpha: 1.0)
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Calculate the maximum radius that will fit in the canvas
    // considering we need space for the amplitude bars
    if (radius == -1) {
      double minDimension = size.height < size.width ? size.height : size.width;
      // Use 1/3 of the minimum dimension for the base circle radius
      // This leaves room for the amplitude bars to stay within bounds
      radius = minDimension / 3.2; // Slightly smaller to leave room for artwork
      wavePaint.strokeWidth = 4.0; // Thicker indicators
      wavePaint.strokeCap = StrokeCap.round;
      wavePaint.style = PaintingStyle.stroke;
    }

    // Center point
    final center = Offset(size.width / 2, size.height / 2);

    // Draw base circle indicator (very subtle)
    canvas.drawCircle(
      center,
      radius.toDouble(),
      wavePaint..color = color.withValues(alpha: 0.1),
    );
    wavePaint.color = color;

    if (points == null || points!.length < data.length * 4) {
      points = Float32List(data.length * 4);
    }

    // Find the maximum value in the data for scaling
    int maxValue = data.reduce((curr, next) => curr > next ? curr : next);
    if (maxValue == 0) maxValue = 1; // Prevent division by zero

    double angle = 0;
    double angleIncrement = 360 / data.length;

    // Calculate maximum safe amplitude that won't exceed canvas bounds
    double maxAmplitude = min(
        (size.width / 2 - radius) * 0.9, (size.height / 2 - radius) * 0.9
        );

    final indicatorPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      // Scale the value relative to the maximum value and the safe amplitude
      double normalizedValue = data[i] / maxValue;
      double barHeight = normalizedValue * maxAmplitude;

      // Calculate points for this bar
      double angleRad = angle * pi / 180.0;
      double cosAngle = cos(angleRad);
      double sinAngle = sin(angleRad);

      // Start point (on the base circle)
      double startX = center.dx + radius * cosAngle;
      double startY = center.dy + radius * sinAngle;

      // End point (extended by bar height)
      double endX = center.dx + (radius + barHeight) * cosAngle;
      double endY = center.dy + (radius + barHeight) * sinAngle;

      // Draw the "thick circular" indicator
      // Instead of lines, we draw rounded lines or circles at the tips
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        wavePaint..strokeWidth = 3.0,
      );

      // Draw a small circle at the tip to make it "circular"
      canvas.drawCircle(Offset(endX, endY), 2.5, indicatorPaint);

      angle += angleIncrement;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class CircularBarVisualizer extends StatelessWidget {
  const CircularBarVisualizer({
    super.key,
    required this.input,
    this.gap = 2,
    this.color,
    this.backgroundColor,
  });

  final Color? color;
  final Color? backgroundColor;
  final int gap;
  final List<int> input;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final effectiveBg = backgroundColor ?? Colors.transparent;
    return Container(
      color: effectiveBg,
      child: CustomPaint(
        painter: _CircularBarVisualizer(
          data: input,
          gap: gap,
          color: effectiveColor,
        ),
      ),
    );
  }
}
