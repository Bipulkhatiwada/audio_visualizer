// Original source code from
// - https://github.com/iamSahdeep/FlutterVisualizers

import 'package:flutter/material.dart';
import 'dart:math' as math;


class _LineBarVisualizer extends CustomPainter {
  final List<int> data;
  final Color color;
  final Paint wavePaint;
  final int gap;
  final double distortionIntensity;

  _LineBarVisualizer({
    required this.data,
    required this.color,
    this.gap = 2,
    this.distortionIntensity = 1.5,
  }) : wavePaint = Paint()
          ..color = color.withValues(alpha: 1.0)
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Calculate the maximum number of bars that can fit in the width
    final maxBars = (size.width / (gap + 1)).floor();
    final density = math.min(data.length, maxBars);

    // Calculate bar width ensuring we don't exceed the canvas width
    final barWidth = size.width / density;

    // Calculate sampling interval for data
    final samplingInterval = data.length / density;

    // Set wave paint stroke width
    wavePaint.strokeWidth = math.max(1, barWidth - gap);

    // Find maximum amplitude for scaling
    final maxAmplitude = math.max(1, data.reduce(math.max));

    // Calculate center positions
    final centerY = size.height / 2;
    final centerX = size.width / 2;

    // Calculate maximum possible amplitude in pixels
    final maxPixelAmplitude = centerY * 0.95; // Use 95% to add some padding

    // Draw bars spreading from center outward
    for (int i = 0; i < density; i++) {
      // Calculate the data index, ensuring we don't exceed array bounds
      final dataIndex =
          (i * samplingInterval).floor().clamp(0, data.length - 1);

      // Normalize amplitude to 0-1 range
      final normalizedAmplitude = data[dataIndex] / maxAmplitude;

      // Apply non-linear scaling for more dramatic effect
      // Using power curve to emphasize variations
      final poweredAmplitude = math.pow(normalizedAmplitude, 0.7).toDouble();

      // Add wave-like distortion based on position
      final positionFactor = i / density;
      final waveDistortion = math.sin(positionFactor * math.pi * 2) * 0.15;

      // Combine amplitude with distortion
      final distortedAmplitude =
          (poweredAmplitude + waveDistortion).clamp(0.0, 1.0);

      // Scale to pixel amplitude with intensity multiplier
      final scaledAmplitude =
          distortedAmplitude * maxPixelAmplitude * distortionIntensity;

      // Add subtle random variation for more organic feel
      final randomVariation = (math.Random(dataIndex).nextDouble() - 0.5) * 0.1;
      final finalAmplitude = scaledAmplitude * (1 + randomVariation);

      // Calculate position offset from center
      final distanceFromCenter = ((i + 1) / 2).floor() * barWidth;
      final barX = i % 2 == 0
          ? centerX - distanceFromCenter
          : centerX + distanceFromCenter;

      // Calculate top and bottom points with enhanced amplitude
      final top = (centerY - finalAmplitude).clamp(0.0, size.height);
      final bottom = (centerY + finalAmplitude).clamp(0.0, size.height);

      // Draw only if the bar would be visible
      if (barX >= 0 && barX <= size.width) {
        canvas.drawLine(Offset(barX, centerY), Offset(barX, top), wavePaint);
        canvas.drawLine(Offset(barX, centerY), Offset(barX, bottom), wavePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class LineBarVisualizer extends StatelessWidget {
  const LineBarVisualizer({
    super.key,
    required this.input,
    this.gap = 2,
    this.color,
    this.backgroundColor,
    this.distortionIntensity = 1.5,
  });

  final Color? color;
  final Color? backgroundColor;
  final int gap;
  final List<int> input;
  final double distortionIntensity;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final effectiveBg = backgroundColor ?? Colors.transparent;
    return Container(
      color: effectiveBg,
      child: CustomPaint(
        painter: _LineBarVisualizer(
          data: input,
          gap: gap,
          color: effectiveColor,
          distortionIntensity: distortionIntensity,
        ),
      ),
    );
  }
}
