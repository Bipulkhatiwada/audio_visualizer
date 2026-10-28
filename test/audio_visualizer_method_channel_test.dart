import 'package:audio_visualizer/audio_visualizer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('audio_visualizer');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getState':
          return {
            'duration': 1000,
            'position': 250,
            'loaded': true,
            'status': 'playing',
          };
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('initialize marks player as initialized', () async {
    final player = VisualizerPlayer();

    await player.initialize();

    expect(player.value.initialized, isTrue);
    player.dispose();
  });

  test('player ids are unique per instance', () {
    final a = VisualizerPlayer();
    final b = VisualizerPlayer();

    expect(a.playerId, isNot(equals(b.playerId)));
    a.dispose();
    b.dispose();
  });
}
