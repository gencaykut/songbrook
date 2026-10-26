import 'package:bstream_music/features/music/presentation/widgets/playback_wait_indicator.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerSnapshot.isWaitingForAudio', () {
    test('a song that is still resolving or loading is waiting', () {
      const loading = PlayerSnapshot(
        status: PlayerStatus.loading,
        playWhenReady: true,
      );
      expect(loading.isWaitingForAudio, isTrue);
    });

    test('a playing song that is filling its buffer is waiting', () {
      const buffering = PlayerSnapshot(
        status: PlayerStatus.playing,
        isBuffering: true,
      );
      expect(buffering.isWaitingForAudio, isTrue);
      expect(buffering.copyWith(isBuffering: false).isWaitingForAudio, isFalse);
    });

    test('nothing is waiting once playback is not wanted', () {
      const paused = PlayerSnapshot(
        status: PlayerStatus.loading,
        playWhenReady: false,
        isBuffering: true,
      );
      expect(paused.isWaitingForAudio, isFalse);
    });
  });

  group('PlaybackWaitIndicator', () {
    Future<void> pump(WidgetTester tester, {required bool waiting}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox.square(
              dimension: 56,
              child: PlaybackWaitIndicator(
                waiting: waiting,
                child: const Icon(Icons.pause_rounded),
              ),
            ),
          ),
        ),
      );
    }

    final ring = find.byKey(const ValueKey('playback-wait-indicator'));

    testWidgets('appears only after the delay', (tester) async {
      await pump(tester, waiting: true);
      expect(ring, findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      expect(ring, findsNothing);
      await tester.pump(const Duration(milliseconds: 100));
      expect(ring, findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('a short wait never shows the ring', (tester) async {
      await pump(tester, waiting: true);
      await tester.pump(const Duration(milliseconds: 100));
      await pump(tester, waiting: false);
      await tester.pump(const Duration(seconds: 1));
      expect(ring, findsNothing);
    });

    testWidgets('disappears when audio starts', (tester) async {
      await pump(tester, waiting: true);
      await tester.pump(const Duration(milliseconds: 300));
      expect(ring, findsOneWidget);
      await pump(tester, waiting: false);
      expect(ring, findsNothing);
    });
  });
}
