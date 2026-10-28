import 'package:audio_visualizer/audio_visualizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VisualizerPlayerValue', () {
    test('has expected defaults', () {
      final value = VisualizerPlayerValue();

      expect(value.initialized, isFalse);
      expect(value.loaded, isFalse);
      expect(value.status, PlayerStatus.unknown);
      expect(value.position, Duration.zero);
      expect(value.duration, Duration.zero);
      expect(value.waveform, isEmpty);
      expect(value.fft, isEmpty);
      expect(value.exception, isNull);
    });

    test('copyWith updates only supplied fields', () {
      final initial = VisualizerPlayerValue();
      final updated = initial.copyWith(
        loaded: true,
        status: PlayerStatus.playing,
        duration: const Duration(seconds: 30),
        position: const Duration(seconds: 5),
      );

      expect(updated.loaded, isTrue);
      expect(updated.status, PlayerStatus.playing);
      expect(updated.duration, const Duration(seconds: 30));
      expect(updated.position, const Duration(seconds: 5));
      expect(updated.waveform, isEmpty);
      expect(updated.fft, isEmpty);
    });
  });
}
