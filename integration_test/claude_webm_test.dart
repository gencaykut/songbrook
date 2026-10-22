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

  testWidgets('WebM duration and completion on iOS without catalog duration', (
    _,
  ) async {
    final playback = InnerTubePlaybackService(
      ejsSolver: EjsSolver(runtime: HeadlessInAppWebViewJavaScriptRuntime()),
      poTokenProvider: BotGuardPoTokenProvider(),
      requestTimeout: const Duration(seconds: 20),
      resolveTimeout: const Duration(minutes: 2),
      maxRequestAttempts: 2,
    );
    final service = JustAudioPlayerService();
    try {
      final resolved = await playback.resolve('_CgHTNuEUHc');
      // ignore: avoid_print
      print(
        'CLAUDE_WEBM mime=${resolved.format.mimeType} '
        'itag=${resolved.format.itag} stream=${resolved.format.approxDuration}',
      );
      await service.playRemoteSource(
        RemotePlaybackSource(
          track: TrackInfo(
            id: '_CgHTNuEUHc',
            title: 'Kuzu Kuzu',
            artist: 'Tarkan',
            url: 'https://www.youtube.com/watch?v=_CgHTNuEUHc',
            streamUrl: resolved.uri.toString(),
            streamMimeType: resolved.format.mimeType,
            streamDuration: resolved.format.approxDuration,
            httpHeaders: resolved.headers,
          ),
          uri: resolved.uri,
          queueEntryId: 'webm:0',
          httpHeaders: resolved.headers,
        ),
      );
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        final s = service.currentSnapshot;
        // ignore: avoid_print
        print(
          'CLAUDE_WEBM_TICK status=${s.status.name} pos=${s.position} '
          'dur=${s.duration}',
        );
      }
      await service.seek(
        resolved.format.approxDuration! - const Duration(seconds: 4),
      );
      final started = DateTime.now();
      while (service.currentSnapshot.status != PlayerStatus.completed &&
          DateTime.now().difference(started) < const Duration(seconds: 90)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      final s = service.currentSnapshot;
      // ignore: avoid_print
      print(
        'CLAUDE_WEBM_END status=${s.status.name} '
        'after=${DateTime.now().difference(started).inMilliseconds}ms '
        'pos=${s.position} dur=${s.duration}',
      );
    } finally {
      await service.dispose();
      await playback.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
