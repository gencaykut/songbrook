import 'dart:io';

import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';
import 'package:bstream_music/services/youtube_music/playback/ejs_solver.dart';
import 'package:bstream_music/services/youtube_music/playback/headless_inappwebview_runtime.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_playback_service.dart';
import 'package:bstream_music/services/youtube_music/playback/po_token_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:media_kit/media_kit.dart' as mk;

// Plays [uri] with the same engine the app uses on this platform
// (media_kit on desktop, just_audio on mobile) and returns the position
// reached after a few seconds.
Future<Duration> _playFor(Uri uri, Map<String, String> headers) async {
  if (Platform.isMacOS) {
    mk.MediaKit.ensureInitialized();
    final player = mk.Player();
    try {
      await player.open(mk.Media(uri.toString(), httpHeaders: headers));
      await Future<void>.delayed(const Duration(seconds: 8));
      return player.state.position;
    } finally {
      await player.dispose();
    }
  }
  final player = ja.AudioPlayer();
  try {
    await player.setAudioSource(ja.AudioSource.uri(uri, headers: headers));
    player.play();
    await Future<void>.delayed(const Duration(seconds: 8));
    return player.position;
  } finally {
    await player.dispose();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('search, resolve and play real audio', (_) async {
    final search = InnerTubeSearchService();
    final playback = InnerTubePlaybackService(
      ejsSolver: EjsSolver(runtime: HeadlessInAppWebViewJavaScriptRuntime()),
      poTokenProvider: BotGuardPoTokenProvider(),
      requestTimeout: const Duration(seconds: 20),
      resolveTimeout: const Duration(minutes: 2),
      maxRequestAttempts: 2,
    );
    try {
      for (final query in ['Tarkan Kuzu Kuzu', 'Daft Punk Get Lucky']) {
        final songs = await search.searchSongs(query, limit: 3);
        expect(songs, isNotEmpty);
        final song = songs.first;

        final watch = Stopwatch()..start();
        final result = await playback.resolve(song.videoId);
        final resolveMs = watch.elapsedMilliseconds;
        // ignore: avoid_print
        print(
          'CLAUDE_RESOLVED "$query" -> ${song.videoId} "${song.title}" '
          'profile=${result.profile.key} resolve=${resolveMs}ms '
          'host=${result.uri.host} '
          'probedOffset=${result.probe.probedOffset}',
        );

        final position = await _playFor(result.uri, result.headers);
        // ignore: avoid_print
        print('CLAUDE_PLAYED "$query" position=${position.inMilliseconds}ms');
        expect(position.inMilliseconds, greaterThan(3000));
      }
    } finally {
      await playback.dispose();
      search.dispose();
    }
  });
}
