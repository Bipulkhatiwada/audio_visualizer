// Original source code from
// - https://github.com/iamSahdeep/FlutterVisualizers

import 'package:flutter/material.dart';
import 'dart:math' as math;

class _MultiWaveVisualizer extends CustomPainter {
  final List<double> data;
  final Color color;
  final Paint wavePaint;
  final double distortionIntensity;
  final bool showMirror;
  final double minimumAmplitude;

  _MultiWaveVisualizer({
    required this.data,
    required this.color,
    this.distortionIntensity = 1.8,
    this.showMirror = true,
    this.minimumAmplitude = 0.15,
  }) : wavePaint = Paint()
          ..color = color.withValues(alpha: 1.0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
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
    // Using dynamic bucket count based on available width for smoother curves
    final bucketCount = math.max((size.width / 15).floor(), 8);

    final histogramLow = _createHistogram(data, bucketCount, 0, midPoint);
    final histogramHigh =
        _createHistogram(data, bucketCount, midPoint, data.length);

    // Render low frequency wave (bottom wave)
    _renderHistogram(canvas, size, histogramLow, isLowFreq: true);

    // Render high frequency wave (top wave) with different characteristics
    wavePaint.strokeWidth = 2.0;
    _renderHistogram(canvas, size, histogramHigh, isLowFreq: false);
  }

  void _renderHistogram(Canvas canvas, Size size, List<double> histogram,
      {required bool isLowFreq}) {
    if (histogram.isEmpty) return;

    // Check if there's actual signal variance (not just a flat line)
    final maxVal = histogram.reduce(math.max);
    final minVal = histogram.reduce(math.min);
    final variance = maxVal - minVal;

    // Don't draw if signal is too flat or too quiet
    if (maxVal <= 0.01 || variance < 0.05) return;

    // Center the waveform vertically
    final centerY = size.height / 2;

    // Calculate width per point to fit within canvas
    final pointsToGraph = histogram.length;
    final widthPerSample = size.width / (pointsToGraph - 1);

    final points = <Offset>[];

    // Create points for the smooth curve with enhanced distortion
    for (int i = 0; i < histogram.length; i++) {
      final x = (i * widthPerSample).clamp(0.0, size.width);

      // Apply non-linear scaling for more dramatic effect
      var amplitude = math.pow(histogram[i], 0.65).toDouble();

      // Ensure minimum amplitude to prevent flat lines
      amplitude = math.max(amplitude, minimumAmplitude);

      // Add wave-like modulation based on position
      final positionFactor = i / histogram.length;
      final waveModulation = math.sin(positionFactor * math.pi * 3) * 0.2;

      // Add frequency-specific characteristics
      final freqModulation = isLowFreq
          ? math.sin(positionFactor * math.pi * 5) *
              0.15 // More waves for low freq
          : math.cos(positionFactor * math.pi * 4) *
              0.18; // Different pattern for high freq

      // Combine all modulations
      amplitude = (amplitude + waveModulation + freqModulation)
          .clamp(minimumAmplitude, 1.0);

      // Apply intensity multiplier
      amplitude *= distortionIntensity;

      // Add subtle randomization for organic feel
      final random = math.Random(i * 100);
      final randomFactor = 1.0 + (random.nextDouble() - 0.5) * 0.12;
      amplitude *= randomFactor;

      // Ensure amplitude stays above minimum threshold
      amplitude = math.max(amplitude, minimumAmplitude);

      // Calculate Y position (above center for positive, below for mirrored)
      final y =
          (centerY - (amplitude * centerY * 0.85)).clamp(0.0, size.height);

      points.add(Offset(x, y));
    }

    // Only draw if we have enough variation in the points
    if (_hasSignificantVariation(points, centerY)) {
      // Draw the main wave
      _drawSmoothCurve(canvas, points);

      // Draw mirrored wave below center if enabled
      if (showMirror) {
        final mirroredPoints = points.map((p) {
          final distanceFromCenter = centerY - p.dy;
          return Offset(p.dx, centerY + distanceFromCenter);
        }).toList();

        _drawSmoothCurve(canvas, mirroredPoints);
      }
    }
  }

  bool _hasSignificantVariation(List<Offset> points, double centerY) {
    if (points.length < 2) return false;

    // Check if points deviate significantly from center
    double maxDeviation = 0.0;
    for (final point in points) {
      final deviation = (point.dy - centerY).abs();
      maxDeviation = math.max(maxDeviation, deviation);
    }
    
    // Require at least 5% deviation from center
    return maxDeviation > (centerY * 0.05);
  }

  void _drawSmoothCurve(Canvas canvas, List<Offset> points) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    // Use Catmull-Rom spline for smoother curves
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      // Calculate control points for smooth bezier curve
      final tension = 0.5;
      final cp1x = p1.dx + (p2.dx - p0.dx) / 6 * tension;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6 * tension;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6 * tension;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6 * tension;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

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

    // Calculate histogram values with weighted averaging
    for (int i = 0; i < bucketCount; i++) {
      double sum = 0.0;
      int count = 0;

      for (int j = 0; j < samplesPerBucket; j++) {
        final idx = start + (i * samplesPerBucket) + j;
        if (idx < end) {
          // Convert from [0-255] to [0-1] range
          final value = samples[idx] / 255.0;

          // Apply emphasis to higher values for better visibility
          final emphasized = math.pow(value, 0.8).toDouble();
          sum += emphasized;
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

    // Apply smoothing to reduce jitter
    histogram = _smoothHistogram(histogram);

    return histogram;
  }

  List<double> _smoothHistogram(List<double> data) {
    if (data.length < 3) return data;

    final smoothed = List<double>.filled(data.length, 0.0);

    // Simple moving average
    smoothed[0] = data[0];
    smoothed[data.length - 1] = data[data.length - 1];

    for (int i = 1; i < data.length - 1; i++) {
      smoothed[i] = (data[i - 1] + data[i] * 2 + data[i + 1]) / 4;
    }

    return smoothed;
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
    this.distortionIntensity = 1.8,
    this.showMirror = true,
    this.minimumAmplitude = 0.15,
  });

  final Color? color;
  final Color? backgroundColor;
  final int gap;
  final List<int> input;
  final double distortionIntensity;
  final bool showMirror;
  final double minimumAmplitude;

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
          distortionIntensity: distortionIntensity,
          showMirror: showMirror,
          minimumAmplitude: minimumAmplitude,
        ),
      ),
    );
  }
}
