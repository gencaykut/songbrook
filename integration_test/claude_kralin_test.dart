import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/services/player/just_audio_player_service.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';
import 'package:bstream_music/services/youtube_music/playback/ejs_solver.dart';
import 'package:bstream_music/services/youtube_music/playback/headless_inappwebview_runtime.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_playback_service.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_stream_models.dart';
import 'package:bstream_music/services/youtube_music/playback/po_token_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the --:-- track with the app iOS format filter', (_) async {
    final search = InnerTubeSearchService();
    // Same configuration as innerTubePlaybackServiceProvider on iOS.
    final playback = InnerTubePlaybackService(
      ejsSolver: EjsSolver(runtime: HeadlessInAppWebViewJavaScriptRuntime()),
      poTokenProvider: BotGuardPoTokenProvider(),
      audioFormatPredicate: isAvFoundationCompatibleInnerTubeAudio,
    );
    try {
      final song = (await search.searchSongs('Ahiyan Kralın Kızı', limit: 1))
          .first;
      for (final clip in [false, true]) {
        final resolved = await playback.resolve(song.videoId);
        // ignore: avoid_print
        print(
          'CLAUDE_KRALIN clip=$clip ${song.videoId} "${song.title}" '
          'catalog=${song.duration} mime=${resolved.format.mimeType} '
          'itag=${resolved.format.itag} audioOnly=${resolved.format.isAudioOnly} '
          'stream=${resolved.format.approxDuration}',
        );
        final service = JustAudioPlayerService(clipMp4ToStreamDuration: clip);
        try {
          await service.playRemoteSource(
            RemotePlaybackSource(
              track: TrackInfo(
                id: song.videoId,
                title: song.title,
                artist: 'Ahiyan',
                url: 'https://www.youtube.com/watch?v=${song.videoId}',
                streamUrl: resolved.uri.toString(),
                streamMimeType: resolved.format.mimeType,
                streamDuration: resolved.format.approxDuration,
                httpHeaders: resolved.headers,
              ),
              uri: resolved.uri,
              queueEntryId: 'kralin:$clip',
              httpHeaders: resolved.headers,
            ),
          );
          await Future<void>.delayed(const Duration(seconds: 6));
          final s = service.currentSnapshot;
          // ignore: avoid_print
          print(
            'CLAUDE_KRALIN_SNAPSHOT clip=$clip status=${s.status.name} '
            'pos=${s.position} dur=${s.duration}',
          );
        } finally {
          await service.dispose();
        }
      }
    } finally {
      await playback.dispose();
      search.dispose();
    }
  });
}
