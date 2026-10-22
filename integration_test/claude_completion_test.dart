import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';
import 'package:bstream_music/services/youtube_music/playback/ejs_solver.dart';
import 'package:bstream_music/services/youtube_music/playback/headless_inappwebview_runtime.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_playback_service.dart';
import 'package:bstream_music/services/youtube_music/playback/po_token_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';

// Mirrors JustAudioPlayerService._remoteExtension for the formats YouTube
// returns, so the native player sees the same URI the app builds.
String? _extensionFor(String mimeType) =>
    switch (mimeType.split(';').first.trim().toLowerCase()) {
      'audio/mp4' => 'm4a',
      'audio/webm' => 'webm',
      _ => null,
    };

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('measure native completion near the end of a track', (_) async {
    final search = InnerTubeSearchService();
    final playback = InnerTubePlaybackService(
      ejsSolver: EjsSolver(runtime: HeadlessInAppWebViewJavaScriptRuntime()),
      poTokenProvider: BotGuardPoTokenProvider(),
      requestTimeout: const Duration(seconds: 20),
      resolveTimeout: const Duration(minutes: 2),
      maxRequestAttempts: 2,
    );
    final player = AudioPlayer();
    final started = DateTime.now();
    String t() =>
        '${(DateTime.now().difference(started).inMilliseconds / 1000).toStringAsFixed(1)}s';
    final events = player.playbackEventStream.listen(
      (event) {
        // ignore: avoid_print
        print(
          'CLAUDE_EVENT ${t()} state=${event.processingState.name} '
          'pos=${event.updatePosition.inMilliseconds} '
          'dur=${event.duration?.inMilliseconds} '
          'buf=${event.bufferedPosition.inMilliseconds}',
        );
      },
      onError: (Object error) {
        // ignore: avoid_print
        print('CLAUDE_ERROR ${t()} $error');
      },
    );
    try {
      final song = (await search.searchSongs('Emir Makina', limit: 1)).first;
      final result = await playback.resolve(song.videoId);
      final extension = _extensionFor(result.format.mimeType);
      final uri = extension == null
          ? result.uri
          : result.uri.replace(fragment: '.$extension');
      // ignore: avoid_print
      print(
        'CLAUDE_RESOLVED ${t()} ${song.videoId} catalog=${song.duration} '
        'stream=${result.format.approxDuration} mime=${result.format.mimeType} '
        'itag=${result.format.itag} contentLength=${result.format.contentLength} '
        'profile=${result.profile.key}',
      );

      // Candidate fix: clip at YouTube's own stream duration so AVPlayer's
      // doubled fragmented-MP4 duration never becomes the end of playback.
      final loaded = await player.setAudioSource(
        ClippingAudioSource(
          child: AudioSource.uri(uri, headers: result.headers),
          end:
              result.format.approxDuration! - const Duration(milliseconds: 300),
        ),
        preload: true,
      );
      final reference = loaded ?? result.format.approxDuration!;
      // ignore: avoid_print
      print('CLAUDE_LOADED ${t()} loadedDuration=$loaded');
      await player.seek(reference - const Duration(seconds: 8));
      player.play();

      final deadline = DateTime.now().add(const Duration(minutes: 5));
      while (player.processingState != ProcessingState.completed &&
          DateTime.now().isBefore(deadline)) {
        // ignore: avoid_print
        print(
          'CLAUDE_TICK ${t()} state=${player.processingState.name} '
          'playing=${player.playing} pos=${player.position.inMilliseconds} '
          'dur=${player.duration?.inMilliseconds}',
        );
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      // ignore: avoid_print
      print(
        'CLAUDE_DONE ${t()} state=${player.processingState.name} '
        'pos=${player.position.inMilliseconds}',
      );
    } finally {
      await events.cancel();
      await player.dispose();
      await playback.dispose();
      search.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 8)));
}
