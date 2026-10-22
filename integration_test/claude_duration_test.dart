import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';
import 'package:bstream_music/services/youtube_music/playback/ejs_solver.dart';
import 'package:bstream_music/services/youtube_music/playback/headless_inappwebview_runtime.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_playback_service.dart';
import 'package:bstream_music/services/youtube_music/playback/po_token_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('compare catalog and stream durations', (_) async {
    final search = InnerTubeSearchService();
    final playback = InnerTubePlaybackService(
      ejsSolver: EjsSolver(runtime: HeadlessInAppWebViewJavaScriptRuntime()),
      poTokenProvider: BotGuardPoTokenProvider(),
      requestTimeout: const Duration(seconds: 20),
      resolveTimeout: const Duration(minutes: 2),
      maxRequestAttempts: 2,
    );
    try {
      for (final query in ['Hepsi Yalan', 'Emir Makina', 'Tarkan Öp']) {
        final song = (await search.searchSongs(query, limit: 1)).first;
        final result = await playback.resolve(song.videoId);
        // ignore: avoid_print
        print(
          'CLAUDE_DURATION "$query" ${song.videoId} "${song.title}" '
          'catalog=${song.duration} stream=${result.format.approxDuration} '
          'mime=${result.format.mimeType} itag=${result.format.itag} '
          'profile=${result.profile.key}',
        );
      }
    } finally {
      await playback.dispose();
      search.dispose();
    }
  });
}
