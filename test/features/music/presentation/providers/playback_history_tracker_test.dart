import 'dart:async';

import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:bstream_music/services/recommendations/recommendation_storage_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses 40 percent for short tracks and caps the threshold at 30s', () {
    expect(
      QualifiedPlaybackHistoryTracker.qualificationThreshold(
        const Duration(seconds: 10),
      ),
      const Duration(seconds: 4),
    );
    expect(
      QualifiedPlaybackHistoryTracker.qualificationThreshold(
        const Duration(minutes: 4),
      ),
      const Duration(seconds: 30),
    );
    expect(
      QualifiedPlaybackHistoryTracker.qualificationThreshold(null),
      const Duration(seconds: 30),
    );
  });

  test(
    'counts only monotonic playing time and ignores a seek-like update',
    () async {
      final writes = <PlaybackHistoryWrite>[];
      final tracker = _tracker(writes);
      await tracker.setEnabled(true);
      final track = _track(duration: const Duration(milliseconds: 500));

      tracker.update(track: track, status: PlayerStatus.playing);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // A player position can jump here; the tracker deliberately receives no
      // media position and therefore cannot turn a seek into listened time.
      tracker.update(track: track, status: PlayerStatus.playing);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(writes, isEmpty);

      await _waitUntil(() => writes.isNotEmpty);
      expect(writes, hasLength(1));
      expect(writes.single.event.listenedMs, greaterThanOrEqualTo(200));
      expect(writes.single.event.videoId, 'abcdefghijk');
      expect(writes.single.event.artistBrowseIds, ['UC-artist']);
      expect(writes.single.isInitialQualification, isTrue);

      await tracker.dispose();
    },
  );

  test('pause time is excluded and completion reuses the session id', () async {
    final writes = <PlaybackHistoryWrite>[];
    var nextSession = 0;
    final tracker = _tracker(
      writes,
      sessionIdFactory: () => 'session-${++nextSession}',
    );
    await tracker.setEnabled(true);
    final track = _track(duration: const Duration(seconds: 1));

    tracker.update(track: track, status: PlayerStatus.playing);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    tracker.update(track: track, status: PlayerStatus.paused);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(writes, isEmpty);

    tracker.update(track: track, status: PlayerStatus.playing);
    await _waitUntil(() => writes.isNotEmpty);
    expect(writes.single.event.sessionId, 'session-1');
    expect(writes.single.event.completed, isFalse);

    tracker.update(track: track, status: PlayerStatus.completed);
    await _waitUntil(() => writes.length == 2);
    expect(writes.last.event.sessionId, 'session-1');
    expect(writes.last.event.completed, isTrue);
    expect(writes.last.isInitialQualification, isFalse);

    tracker.update(track: track, status: PlayerStatus.playing);
    await _waitUntil(() => writes.length == 3);
    expect(writes.last.event.sessionId, 'session-2');

    await tracker.dispose();
  });

  test('disabled tracking discards partial listening', () async {
    final writes = <PlaybackHistoryWrite>[];
    final tracker = _tracker(writes);
    final track = _track(duration: const Duration(milliseconds: 500));

    await tracker.setEnabled(true);
    tracker.update(track: track, status: PlayerStatus.playing);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tracker.setEnabled(false);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    expect(writes, isEmpty);

    await tracker.setEnabled(true);
    tracker.update(track: track, status: PlayerStatus.playing);
    await _waitUntil(() => writes.isNotEmpty);
    expect(writes, hasLength(1));

    await tracker.dispose();
  });

  test('a terminal skip updates the qualified session listened time', () async {
    final writes = <PlaybackHistoryWrite>[];
    final tracker = _tracker(writes);
    await tracker.setEnabled(true);
    final track = _track(duration: const Duration(milliseconds: 500));

    tracker.update(track: track, status: PlayerStatus.playing);
    await _waitUntil(() => writes.isNotEmpty);
    final qualifiedMs = writes.single.event.listenedMs;
    await Future<void>.delayed(const Duration(milliseconds: 80));

    tracker.update(track: track, status: PlayerStatus.stopped);
    await _waitUntil(() => writes.length == 2);

    expect(writes.last.event.sessionId, writes.first.event.sessionId);
    expect(writes.last.event.listenedMs, greaterThan(qualifiedMs));
    expect(writes.last.event.completed, isFalse);
    expect(writes.last.isInitialQualification, isFalse);

    await tracker.dispose();
  });

  testWidgets('position ticks keep one qualification timer', (tester) async {
    final writes = <PlaybackHistoryWrite>[];
    var now = Duration.zero;
    var timerCount = 0;
    final tracker = QualifiedPlaybackHistoryTracker(
      onWrite: (write) async => writes.add(write),
      monotonicClock: () => now,
      timerFactory: (duration, callback) {
        timerCount++;
        return Timer(duration, callback);
      },
    );
    addTearDown(tracker.dispose);
    await tracker.setEnabled(true);
    final track = _track(duration: const Duration(minutes: 3));
    tracker.update(track: track, status: PlayerStatus.playing);

    for (var index = 0; index < 119; index++) {
      now += const Duration(milliseconds: 250);
      await tester.pump(const Duration(milliseconds: 250));
      tracker.update(track: track, status: PlayerStatus.playing);
    }
    expect(writes, isEmpty);
    expect(timerCount, 1);

    now += const Duration(milliseconds: 250);
    await tester.pump(const Duration(milliseconds: 250));
    expect(writes, hasLength(1));
    expect(writes.single.event.listenedMs, 30000);
    expect(timerCount, 1);
    await tracker.dispose();
  });

  testWidgets('changed duration reschedules the qualification deadline', (
    tester,
  ) async {
    final writes = <PlaybackHistoryWrite>[];
    var now = Duration.zero;
    final scheduledDelays = <Duration>[];
    final tracker = QualifiedPlaybackHistoryTracker(
      onWrite: (write) async => writes.add(write),
      monotonicClock: () => now,
      timerFactory: (duration, callback) {
        scheduledDelays.add(duration);
        return Timer(duration, callback);
      },
    );
    addTearDown(tracker.dispose);
    await tracker.setEnabled(true);
    tracker.update(
      track: _track(duration: const Duration(minutes: 3)),
      status: PlayerStatus.playing,
    );
    now = const Duration(seconds: 2);
    await tester.pump(const Duration(seconds: 2));
    tracker.update(
      track: _track(duration: const Duration(seconds: 10)),
      status: PlayerStatus.playing,
    );
    expect(scheduledDelays, [
      const Duration(seconds: 30),
      const Duration(seconds: 2),
    ]);
    now = const Duration(seconds: 4);
    await tester.pump(const Duration(seconds: 2));
    expect(writes, hasLength(1));
    expect(writes.single.event.listenedMs, 4000);
    expect(writes.single.event.durationMs, 10000);
    await tracker.dispose();
  });

  testWidgets(
    'pause cancels the stable timer and resume excludes paused time',
    (tester) async {
      final writes = <PlaybackHistoryWrite>[];
      var now = Duration.zero;
      final scheduledDelays = <Duration>[];
      final tracker = QualifiedPlaybackHistoryTracker(
        onWrite: (write) async => writes.add(write),
        monotonicClock: () => now,
        timerFactory: (duration, callback) {
          scheduledDelays.add(duration);
          return Timer(duration, callback);
        },
      );
      addTearDown(tracker.dispose);
      await tracker.setEnabled(true);
      final track = _track(duration: const Duration(seconds: 10));
      tracker.update(track: track, status: PlayerStatus.playing);
      now = const Duration(seconds: 1);
      await tester.pump(const Duration(seconds: 1));
      tracker.update(track: track, status: PlayerStatus.paused);
      now = const Duration(seconds: 11);
      await tester.pump(const Duration(seconds: 10));
      expect(writes, isEmpty);

      tracker.update(track: track, status: PlayerStatus.playing);
      expect(scheduledDelays, [
        const Duration(seconds: 4),
        const Duration(seconds: 3),
      ]);
      now = const Duration(seconds: 14);
      await tester.pump(const Duration(seconds: 3));
      expect(writes, hasLength(1));
      expect(writes.single.event.listenedMs, 4000);
      await tracker.dispose();
    },
  );

  group('skips', () {
    late Duration now;
    late List<PlaybackHistoryWrite> writes;
    late List<PlaybackSkip> skips;
    late QualifiedPlaybackHistoryTracker tracker;
    final song = _track(duration: const Duration(minutes: 3));
    final next = _track(
      duration: const Duration(minutes: 3),
      logicalKey: 'remote:queue:1',
      videoId: 'nextnextnex',
    );

    setUp(() async {
      now = Duration.zero;
      writes = [];
      skips = [];
      var session = 0;
      tracker = QualifiedPlaybackHistoryTracker(
        onWrite: (write) async => writes.add(write),
        onSkip: (skip) async => skips.add(skip),
        monotonicClock: () => now,
        sessionIdFactory: () => 'session-${++session}',
        wallClock: () => DateTime.utc(2026, 10, 29),
        // The qualification deadline is reached by advancing the clock and
        // sending another observation, never by a real timer.
        timerFactory: (duration, callback) =>
            Timer(const Duration(days: 1), callback),
      );
      await tracker.setEnabled(true);
    });

    tearDown(() => tracker.dispose());

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('moving to another song a few seconds in is a skip', () async {
      tracker.update(track: song, status: PlayerStatus.playing);
      now = const Duration(seconds: 5);
      tracker.update(track: next, status: PlayerStatus.loading);
      await settle();

      expect(writes, isEmpty);
      expect(skips, hasLength(1));
      expect(skips.single.sessionId, 'session-1');
      expect(skips.single.videoId, 'abcdefghijk');
      expect(skips.single.artists, ['Artist']);
      expect(skips.single.listenedMs, 5000);
      expect(skips.single.durationMs, 180000);
      expect(skips.single.skippedAt, DateTime.utc(2026, 10, 29));
    });

    test('moving on from a paused song is a skip', () async {
      tracker.update(track: song, status: PlayerStatus.playing);
      now = const Duration(seconds: 3);
      tracker.update(track: song, status: PlayerStatus.paused);
      now = const Duration(minutes: 5);
      tracker.update(track: next, status: PlayerStatus.playing);
      await settle();

      expect(skips.single.listenedMs, 3000);
    });

    test('the gap before the next queue item still counts', () async {
      tracker.update(track: song, status: PlayerStatus.playing);
      now = const Duration(seconds: 5);
      tracker.update(track: null, status: PlayerStatus.playing);
      tracker.update(track: next, status: PlayerStatus.playing);
      await settle();

      expect(skips.single.listenedMs, 5000);
    });

    test('passing over a song within a second is not a skip', () async {
      tracker.update(track: song, status: PlayerStatus.playing);
      now = const Duration(milliseconds: 600);
      tracker.update(track: next, status: PlayerStatus.playing);
      await settle();

      expect(skips, isEmpty);
    });

    test('a song that failed before the next one is not a skip', () async {
      tracker.update(track: song, status: PlayerStatus.playing);
      now = const Duration(seconds: 5);
      tracker.update(track: song, status: PlayerStatus.failed);
      tracker.update(track: next, status: PlayerStatus.playing);
      await settle();

      expect(skips, isEmpty);
    });

    test('a song whose play counted is not a skip', () async {
      tracker.update(track: song, status: PlayerStatus.playing);
      now = const Duration(seconds: 31);
      tracker.update(track: song, status: PlayerStatus.playing);
      tracker.update(track: next, status: PlayerStatus.playing);
      await settle();

      expect(writes, isNotEmpty);
      expect(skips, isEmpty);
    });

    test('stopping or clearing the queue is not a skip', () async {
      tracker.update(track: song, status: PlayerStatus.playing);
      now = const Duration(seconds: 5);
      tracker.update(track: song, status: PlayerStatus.stopped);
      tracker.update(track: next, status: PlayerStatus.playing);
      now = const Duration(seconds: 10);
      tracker.update(track: null, status: PlayerStatus.idle);
      await settle();

      expect(skips, isEmpty);
    });

    test('nothing is recorded while tracking is off', () async {
      await tracker.setEnabled(false);
      tracker.update(track: song, status: PlayerStatus.playing);
      now = const Duration(seconds: 5);
      tracker.update(track: next, status: PlayerStatus.playing);
      await settle();

      expect(skips, isEmpty);
    });
  });
}

QualifiedPlaybackHistoryTracker _tracker(
  List<PlaybackHistoryWrite> writes, {
  String Function()? sessionIdFactory,
}) {
  return QualifiedPlaybackHistoryTracker(
    onWrite: (write) async => writes.add(write),
    sessionIdFactory: sessionIdFactory ?? () => 'session',
  );
}

PlaybackHistoryTrack _track({
  required Duration duration,
  String logicalKey = 'remote:queue:0',
  String videoId = 'abcdefghijk',
}) {
  return PlaybackHistoryTrack(
    logicalKey: logicalKey,
    trackId: videoId,
    videoId: videoId,
    title: 'Track',
    artists: const ['Artist'],
    artistBrowseIds: const ['UC-artist'],
    album: 'Album',
    thumbnailUrl: 'https://example.test/art.jpg',
    duration: duration,
    source: PlaybackEventSource.streaming,
  );
}

Future<void> _waitUntil(bool Function() predicate) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (predicate()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('Timed out waiting for the qualified playback write.');
}
