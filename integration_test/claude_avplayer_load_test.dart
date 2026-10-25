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

    // All variants clip like production; they differ in AVPlayer's
    // automaticallyWaitsToMinimizeStalling (on by default).
    const variants = ['wait', 'noWait'];
    for (var i = 0; i < ids.length; i++) {
      final resolved = await playback.resolve(ids[i]);
      final uri = resolved.uri.replace(fragment: '.m4a');
      final duration = resolved.format.approxDuration!;
      // Each song is loaded with both settings; alternate which goes first
      // so CDN warmth does not favour one of them.
      final order = i.isEven ? variants : variants.reversed.toList();
      for (final variant in order) {
        final source = ClippingAudioSource(
          child: AudioSource.uri(uri, headers: resolved.headers),
          end: duration - const Duration(milliseconds: 300),
        );
        final player = AudioPlayer(
          useProxyForRequestHeaders: false,
          audioLoadConfiguration: AudioLoadConfiguration(
            darwinLoadControl: DarwinLoadControl(
              automaticallyWaitsToMinimizeStalling: variant == 'wait',
            ),
          ),
        );
        final watch = Stopwatch()..start();
        int? readyMs;
        String error = '';
        try {
          await player.setAudioSource(source);
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
          'CLAUDE_AV video=${ids[i]} variant=$variant first=${order.first} '
          'readyMs=$readyMs audibleMs=${watch.elapsedMilliseconds}$error',
        );
        await player.dispose();
      }
    }
  });
}
