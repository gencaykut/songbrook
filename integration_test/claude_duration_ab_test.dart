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

  testWidgets('snapshot duration without catalog metadata, clip off vs on', (
    _,
  ) async {
    final playback = InnerTubePlaybackService(
      ejsSolver: EjsSolver(runtime: HeadlessInAppWebViewJavaScriptRuntime()),
      poTokenProvider: BotGuardPoTokenProvider(),
      requestTimeout: const Duration(seconds: 20),
      resolveTimeout: const Duration(minutes: 2),
      maxRequestAttempts: 2,
    );
    try {
      for (final clip in [false, true]) {
        final resolved = await playback.resolve('Be-xjqSJLc8');
        final track = TrackInfo(
          id: 'Be-xjqSJLc8',
          title: 'Makina',
          artist: 'Emir',
          url: 'https://www.youtube.com/watch?v=Be-xjqSJLc8',
          streamUrl: resolved.uri.toString(),
          streamMimeType: resolved.format.mimeType,
          streamDuration: resolved.format.approxDuration,
          httpHeaders: resolved.headers,
        );
        final service = JustAudioPlayerService(clipMp4ToStreamDuration: clip);
        try {
          await service.playRemoteSource(
            RemotePlaybackSource(
              track: track,
              uri: resolved.uri,
              queueEntryId: 'ab:$clip',
              httpHeaders: resolved.headers,
            ),
          );
          await Future<void>.delayed(const Duration(seconds: 5));
          // ignore: avoid_print
          print(
            'CLAUDE_AB clip=$clip snapshotDuration='
            '${service.currentSnapshot.duration} '
            'status=${service.currentSnapshot.status.name}',
          );
        } finally {
          await service.dispose();
        }
      }
    } finally {
      await playback.dispose();
    }
  });
}
