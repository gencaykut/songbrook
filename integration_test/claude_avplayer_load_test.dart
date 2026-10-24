import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';
import 'package:bstream_music/services/youtube_music/playback/ejs_solver.dart';
import 'package:bstream_music/services/youtube_music/playback/headless_inappwebview_runtime.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_playback_service.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_stream_models.dart';
import 'package:bstream_music/services/youtube_music/playback/po_token_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';

/// Loads the same signed YouTube M4A URLs into AVPlayer in several ways and
/// prints how long each takes to become ready and to make audible progress.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AVPlayer load time by source variant', (_) async {
    final search = InnerTubeSearchService();
    final ids = <String>[
      for (final query in const ['Sezen Aksu', 'Tarkan', 'Duman'])
        ...(await search.searchSongs(
          query,
          limit: 6,
        )).map((song) => song.videoId),
    ];
    final playback = InnerTubePlaybackService(
      ejsSolver: EjsSolver(runtime: HeadlessInAppWebViewJavaScriptRuntime()),
      poTokenProvider: BotGuardPoTokenProvider(),
      audioFormatPredicate: isAvFoundationCompatibleInnerTubeAudio,
    );

    const variants = ['clip+headers', 'plain+headers'];
    for (var i = 0; i < ids.length; i++) {
      final resolved = await playback.resolve(ids[i]);
      final uri = resolved.uri.replace(fragment: '.m4a');
      final duration = resolved.format.approxDuration!;
      final sizeMb = (resolved.format.contentLength ?? 0) / (1 << 20);
      // Rotate the variant so CDN warmth does not favour one of them.
      final variant = variants[i % variants.length];
      final headers = variant.contains('noHeaders') ? null : resolved.headers;
      UriAudioSource child() => AudioSource.uri(uri, headers: headers);
      final source = variant.startsWith('plain')
          ? child()
          : ClippingAudioSource(
              child: child(),
              end: duration - const Duration(milliseconds: 300),
            );

      final player = AudioPlayer(useProxyForRequestHeaders: false);
      final watch = Stopwatch()..start();
      int? readyMs;
      String error = '';
      try {
        await player.setAudioSource(source, preload: !variant.endsWith('lazy'));
        readyMs = watch.elapsedMilliseconds;
        player.play();
        await player.positionStream
            .firstWhere(
              (position) => position > const Duration(milliseconds: 200),
            )
            .timeout(const Duration(seconds: 30));
      } catch (e) {
        error = ' error=$e';
      }
      // ignore: avoid_print
      print(
        'CLAUDE_AV video=${ids[i]} variant=$variant '
        'sizeMb=${sizeMb.toStringAsFixed(1)} durationS=${duration.inSeconds} '
        'readyMs=$readyMs audibleMs=${watch.elapsedMilliseconds}$error',
      );
      await player.dispose();
    }
  });
}
