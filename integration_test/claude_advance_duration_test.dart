import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/services/player/just_audio_player_service.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:bstream_music/services/youtube_music/playback/ejs_solver.dart';
import 'package:bstream_music/services/youtube_music/playback/headless_inappwebview_runtime.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_playback_service.dart';
import 'package:bstream_music/services/youtube_music/playback/po_token_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('duration across two native auto-advances, like the app queue', (
    _,
  ) async {
    final playback = InnerTubePlaybackService(
      ejsSolver: EjsSolver(runtime: HeadlessInAppWebViewJavaScriptRuntime()),
      poTokenProvider: BotGuardPoTokenProvider(),
      requestTimeout: const Duration(seconds: 20),
      resolveTimeout: const Duration(minutes: 2),
      maxRequestAttempts: 2,
    );

    Future<RemotePlaybackSource> source(
      String id,
      String entry, {
      required bool catalogDuration,
    }) async {
      var resolved = await playback.resolve(id);
      for (
        var attempt = 0;
        attempt < 4 && !resolved.format.mimeType.startsWith('audio/mp4');
        attempt++
      ) {
        // AVPlayer cannot open WebM; the app relies on an MP4 format here.
        resolved = await playback.resolve(id);
      }
      // ignore: avoid_print
      print('CLAUDE_SOURCE $entry $id mime=${resolved.format.mimeType}');
      final track = TrackInfo(
        id: id,
        title: id,
        artist: 'test',
        url: 'https://www.youtube.com/watch?v=$id',
        // Shelf items normally carry a whole-second catalog duration; the
        // Quick picks item that showed --:-- did not.
        duration: catalogDuration
            ? Duration(seconds: resolved.format.approxDuration!.inSeconds + 1)
            : null,
        streamUrl: resolved.uri.toString(),
        streamMimeType: resolved.format.mimeType,
        streamDuration: resolved.format.approxDuration,
        httpHeaders: resolved.headers,
      );
      return RemotePlaybackSource(
        track: track,
        uri: resolved.uri,
        queueEntryId: entry,
        httpHeaders: resolved.headers,
      );
    }

    Future<void> runToEnd(JustAudioPlayerService service, String next) async {
      // Seek against the native timeline so the phantom tail of an unclipped
      // fragmented MP4 is also skipped.
      final nativeEnd = service.currentSnapshot.duration!;
      await service.seek(nativeEnd - const Duration(seconds: 4));
      final deadline = DateTime.now().add(const Duration(minutes: 1));
      var ticks = 0;
      while (service.currentSnapshot.queueEntryId != next &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (++ticks % 20 == 0) {
          final s = service.currentSnapshot;
          // ignore: avoid_print
          print(
            'CLAUDE_WAIT entry=${s.queueEntryId} status=${s.status.name} '
            'pos=${s.position} dur=${s.duration}',
          );
        }
      }
    }

    try {
      for (final clip in [false, true]) {
        final ids = <String>[];
        for (final id in const [
          'Be-xjqSJLc8',
          'VMn4mN7TeAk',
          '4D7u5KF7SP8',
          'Rgrt_8mXrK8',
          'dSybIb9CO2s',
        ]) {
          final probe = await playback.resolve(id);
          if (probe.format.mimeType.startsWith('audio/mp4')) ids.add(id);
          if (ids.length == 3) break;
        }
        final a = await source(ids[0], 'q:$clip:0', catalogDuration: false);
        final b = await source(ids[1], 'q:$clip:1', catalogDuration: false);
        final c = await source(ids[1], 'q:$clip:2', catalogDuration: false);
        final service = JustAudioPlayerService(clipMp4ToStreamDuration: clip);
        String? lastEntry;
        Duration? lastDuration;
        final trace = service.snapshotStream.listen((snapshot) {
          if (snapshot.queueEntryId == lastEntry &&
              snapshot.duration == lastDuration) {
            return;
          }
          lastEntry = snapshot.queueEntryId;
          lastDuration = snapshot.duration;
          // ignore: avoid_print
          print(
            'CLAUDE_TRACE clip=$clip ${DateTime.now().toIso8601String()} '
            'entry=${snapshot.queueEntryId} dur=${snapshot.duration}',
          );
        });
        try {
          await service.playRemoteSource(a);
          await service.updateRemoteQueue([b]);
          await runToEnd(service, b.queueEntryId);
          // The controller extends the native window after every advance.
          await service.updateRemoteQueue([c]);
          await Future<void>.delayed(const Duration(seconds: 2));
          await runToEnd(service, c.queueEntryId);
          await Future<void>.delayed(const Duration(seconds: 6));
          // ignore: avoid_print
          print(
            'CLAUDE_QUEUE clip=$clip '
            'current=${service.currentSnapshot.queueEntryId} '
            'thirdDuration=${service.currentSnapshot.duration} '
            'position=${service.currentSnapshot.position}',
          );
        } finally {
          await trace.cancel();
          await service.dispose();
        }
      }
    } finally {
      await playback.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}
