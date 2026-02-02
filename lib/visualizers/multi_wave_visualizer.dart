// Original source code from
// - https://github.com/iamSahdeep/FlutterVisualizers

import 'package:flutter/material.dart';
import 'dart:math' as math;

class _MultiWaveVisualizer extends CustomPainter {
  final List<double> data;
  final Color color;
  final Paint wavePaint;

  _MultiWaveVisualizer({
    required this.data,
    required this.color,
  }) : wavePaint = Paint()
          ..color = color.withValues(alpha: 1.0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    _renderWaves(canvas, size);
  }

  void _renderWaves(Canvas canvas, Size size) {
    // Calculate the midpoint of data for splitting into low and high frequencies
    final midPoint = (data.length / 2).floor();

    // Create histograms for low and high frequencies
    // Using dynamic bucket count based on available width
    final bucketCount =
        math.max((size.width / 20).floor(), 5); // Ensure minimum 5 buckets

    final histogramLow = _createHistogram(data, bucketCount, 0, midPoint);
    final histogramHigh =
        _createHistogram(data, bucketCount, midPoint, data.length);

    // Render both histograms
    _renderHistogram(canvas, size, histogramLow);
    _renderHistogram(canvas, size, histogramHigh);
  }

  void _renderHistogram(Canvas canvas, Size size, List<double> histogram) {
    if (histogram.isEmpty) return;

    // If signal is effectively silent, don't draw (prevents static straight line)
    final maxVal = histogram.reduce(math.max);
    if (maxVal <= 0.01) return;

    // Center the waveform vertically so it looks similar to the circular visualizer
    final centerY = size.height / 2;

    // Calculate width per point to fit within canvas
    final pointsToGraph = histogram.length;
    final widthPerSample = size.width / (pointsToGraph - 1);

    final points = List<double>.filled(pointsToGraph * 4, 0.0);

    // Create points for the smooth curve (mapped around center)
    for (int i = 0; i < histogram.length - 1; ++i) {
      points[i * 4] = (i * widthPerSample).clamp(0.0, size.width);
      points[i * 4 + 1] =
          (centerY - (histogram[i] * centerY)).clamp(0.0, size.height);
      points[i * 4 + 2] = ((i + 1) * widthPerSample).clamp(0.0, size.width);
      points[i * 4 + 3] =
          (centerY - (histogram[i + 1] * centerY)).clamp(0.0, size.height);
    }

    // Create and draw the path
    Path path = Path();
    path.moveTo(points[0], points[1]);

    // Calculate control point distance based on width
    final controlPointDistance = widthPerSample * 0.5;

    for (int i = 2; i < points.length - 4; i += 2) {
      path.cubicTo(
          points[i - 2] + controlPointDistance,
          points[i - 1],
          points[i] - controlPointDistance,
          points[i + 1],
          points[i],
          points[i + 1]);
    }

    // Draw just the wave line without filling
    canvas.drawPath(path, wavePaint);
  }

  List<double> _createHistogram(
      List<double> samples, int bucketCount, int start, int end) {
    if (start >= end || samples.isEmpty) return const [];

    final sampleCount = end - start;
    final samplesPerBucket = (sampleCount / bucketCount).floor();

    if (samplesPerBucket == 0) return const [];

    List<double> histogram = List<double>.filled(bucketCount, 0.0);
    double maxValue = 0.0;

    // Calculate histogram values and find maximum
    for (int i = 0; i < bucketCount; i++) {
      double sum = 0.0;
      int count = 0;

      for (int j = 0; j < samplesPerBucket; j++) {
        final idx = start + (i * samplesPerBucket) + j;
        if (idx < end) {
          // Convert from [0-255] to [0-1] range
          sum += samples[idx] / 255.0;
          count++;
        }
      }

      if (count > 0) {
        histogram[i] = sum / count;
        maxValue = math.max(maxValue, histogram[i]);
      }
    }

    // Normalize values to [0-1] range based on maximum value
    if (maxValue > 0) {
      for (int i = 0; i < histogram.length; i++) {
        histogram[i] = histogram[i] / maxValue;
      }
    }

    return histogram;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class MultiWaveVisualizer extends StatelessWidget {
  const MultiWaveVisualizer({
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
        painter: _MultiWaveVisualizer(
          data: input.map((e) => e.toDouble()).toList(),
          color: effectiveColor,
        ),
      ),
    );
  }
}
