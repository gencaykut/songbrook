import 'dart:convert';
import 'dart:io';

import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/services/player/just_audio_player_service.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';
import 'package:bstream_music/services/youtube_music/playback/ejs_solver.dart';
import 'package:bstream_music/services/youtube_music/playback/headless_inappwebview_runtime.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_client_profile.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_client_router.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_playback_service.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_stream_models.dart';
import 'package:bstream_music/services/youtube_music/playback/po_token_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';

const _profilesDefine = String.fromEnvironment(
  'CLAUDE_FALLBACK_PROFILES',
  defaultValue: 'webEmbedded,mweb,webMusic',
);
const _itagDefine = int.fromEnvironment('CLAUDE_FALLBACK_ITAG');

/// Profiles treated as closed by YouTube for the production-ladder test.
const _closedDefine = String.fromEnvironment(
  'CLAUDE_CLOSED_PROFILES',
  defaultValue: 'visionOS',
);
const _videoDefine = String.fromEnvironment(
  'CLAUDE_FALLBACK_VIDEO',
  defaultValue: 'CHIWNDAwTqQ',
);

/// Diagnoses the EJS/WebPO fallback layers one at a time and prints the
/// underlying error of every failed client, which the matrix reduces to a
/// category. Errors are truncated; they never contain signed media URLs.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('headless JavaScript runtime evaluates code', (_) async {
    final runtime = HeadlessInAppWebViewJavaScriptRuntime();
    final watch = Stopwatch()..start();
    try {
      await runtime.initialize();
      final initMs = watch.elapsedMilliseconds;
      final value = await runtime.callAsyncJavaScript(
        functionBody: 'return 6 * 7;',
        timeout: const Duration(seconds: 20),
      );
      // ignore: avoid_print
      print(
        'CLAUDE_RUNTIME platform=${Platform.operatingSystem} '
        'init=${initMs}ms result=$value total=${watch.elapsedMilliseconds}ms',
      );
      expect(value, 42);
    } catch (error) {
      // ignore: avoid_print
      print('CLAUDE_RUNTIME_ERROR ${_describe(error)}');
      rethrow;
    } finally {
      await runtime.dispose();
    }
  });

  testWidgets('raw audio formats per client', (_) async {
    for (final key in _profilesDefine.split(',')) {
      await _printRawFormats(key.trim());
    }
  });

  testWidgets('the production ladder without closed clients plays audio', (
    _,
  ) async {
    final closed = _closedDefine.split(',').map((key) => key.trim()).toSet();
    final profiles = InnerTubeClientRegistry.defaults
        .where((profile) => !closed.contains(profile.key))
        .toList(growable: false);
    final service = InnerTubePlaybackService(
      router: InnerTubeClientRouter(
        profiles: profiles,
        primaryKey: profiles.first.key,
      ),
      ejsSolver: EjsSolver(runtime: HeadlessInAppWebViewJavaScriptRuntime()),
      poTokenProvider: BotGuardPoTokenProvider(),
      audioFormatPredicate: Platform.isIOS
          ? isAvFoundationCompatibleInnerTubeAudio
          : null,
      requestTimeout: const Duration(seconds: 20),
      resolveTimeout: const Duration(minutes: 3),
      maxRequestAttempts: 2,
    );
    final audioPlayer = AudioPlayer(useProxyForRequestHeaders: false);
    final player = JustAudioPlayerService(audioPlayer: audioPlayer);
    try {
      for (final videoId in const [
        'CHIWNDAwTqQ',
        'PhXEL2FRSag',
        'dQw4w9WgXcQ',
      ]) {
        final watch = Stopwatch()..start();
        final resolved = await service.resolve(videoId);
        final resolveMs = watch.elapsedMilliseconds;
        final track = TrackInfo(
          id: videoId,
          title: videoId,
          artist: 'Artist',
          url: 'https://music.youtube.com/watch?v=$videoId',
          streamUrl: resolved.uri.toString(),
          streamExtension: resolved.extension,
          streamDuration: resolved.format.approxDuration,
          httpHeaders: resolved.headers,
        );
        await player.playRemoteSource(
          RemotePlaybackSource(
            track: track,
            uri: resolved.uri,
            queueEntryId: 'ladder:$videoId',
            httpHeaders: resolved.headers,
          ),
        );
        await Future<void>.delayed(const Duration(seconds: 6));
        // ignore: avoid_print
        print(
          'CLAUDE_LADDER closed=$_closedDefine video=$videoId '
          'client=${resolved.profile.key} itag=${resolved.format.itag} '
          'mime=${resolved.format.mimeType} resolve=${resolveMs}ms '
          'position=${audioPlayer.position.inMilliseconds}ms '
          'status=${player.currentSnapshot.status.name}',
        );
        expect(audioPlayer.position.inMilliseconds, greaterThan(2000));
      }
    } finally {
      await player.dispose();
      await service.dispose();
    }
  });

  testWidgets('each challenge client resolves on its own', (_) async {
    final keys = _profilesDefine.split(',').map((key) => key.trim()).toSet();
    final profiles = InnerTubeClientRegistry.benchmarkCandidates
        .where((profile) => keys.contains(profile.key))
        .toList(growable: false);
    for (final profile in profiles) {
      final service = InnerTubePlaybackService(
        router: InnerTubeClientRouter(
          profiles: <InnerTubeClientProfile>[profile],
          primaryKey: profile.key,
        ),
        ejsSolver: profile.capabilities.requiresPlayerJavaScript
            ? EjsSolver(runtime: HeadlessInAppWebViewJavaScriptRuntime())
            : null,
        poTokenProvider: profile.capabilities.supportsWebPo
            ? BotGuardPoTokenProvider()
            : null,
        audioFormatPredicate: _itagDefine != 0
            ? (format) => format.itag == _itagDefine
            : Platform.isIOS
            ? isAvFoundationCompatibleInnerTubeAudio
            : null,
        requestTimeout: const Duration(seconds: 20),
        resolveTimeout: const Duration(minutes: 3),
        maxRequestAttempts: 2,
      );
      final watch = Stopwatch()..start();
      try {
        final resolved = await service.resolve(_videoDefine);
        // ignore: avoid_print
        print(
          'CLAUDE_FALLBACK_OK client=${profile.key} '
          'itag=${resolved.format.itag} mime=${resolved.format.mimeType} '
          'probedOffset=${resolved.probe.probedOffset} '
          'elapsed=${watch.elapsedMilliseconds}ms',
        );
      } on InnerTubePlaybackException catch (error) {
        for (final failure in error.failures) {
          // ignore: avoid_print
          print(
            'CLAUDE_FALLBACK_FAIL client=${failure.profile.key} '
            'kind=${failure.kind.name} elapsed=${watch.elapsedMilliseconds}ms '
            '${_describe(failure.error)}',
          );
        }
      } catch (error) {
        // ignore: avoid_print
        print(
          'CLAUDE_FALLBACK_FAIL client=${profile.key} '
          'elapsed=${watch.elapsedMilliseconds}ms ${_describe(error)}',
        );
      } finally {
        await service.dispose();
      }
    }
  });
}

/// Lists the audio formats a client's raw player response offers, with
/// whether each carries a direct URL or a cipher. Never prints the URLs.
Future<void> _printRawFormats(String profileKey) async {
  final profile = InnerTubeClientRegistry.benchmarkCandidates.firstWhere(
    (candidate) => candidate.key == profileKey,
  );
  final transport = IoInnerTubeTransport();
  try {
    final home = await transport.get(
      Uri.https('music.youtube.com', '/'),
      headers: const {'User-Agent': InnerTubeSearchService.defaultUserAgent},
    );
    final visitorData = const InnerTubeBootstrapParser()
        .parse(home.body)
        .visitorData;
    final raw = await transport.postJson(
      profile.playerEndpoint,
      headers: {...profile.requestHeaders, 'X-Goog-Visitor-Id': visitorData},
      body: {
        'context': profile.buildContext(visitorData: visitorData),
        'videoId': _videoDefine,
        'contentCheckOk': true,
        'racyCheckOk': true,
      },
    );
    final decoded = jsonDecode(raw.body) as Map<String, dynamic>;
    final streaming = decoded['streamingData'] as Map<String, dynamic>? ?? {};
    for (final source in ['formats', 'adaptiveFormats']) {
      for (final format
          in (streaming[source] as List? ?? const []).cast<Map>()) {
        final mime = '${format['mimeType']}';
        if (!mime.contains('mp4a') && !mime.startsWith('audio/')) continue;
        // ignore: avoid_print
        print(
          'CLAUDE_RAW client=$profileKey $source itag=${format['itag']} '
          'mime=${mime.split(';').first} codecs=${mime.split('codecs=').last} '
          'url=${format['url'] != null} cipher=${format['signatureCipher'] != null}',
        );
      }
    }
    // ignore: avoid_print
    print(
      'CLAUDE_RAW client=$profileKey status='
      '${(decoded['playabilityStatus'] as Map?)?['status']}',
    );
  } finally {
    transport.close();
  }
}

String _describe(Object? error) {
  var text = '$error'.replaceAll('\n', ' ');
  // Drop any query string so a token or signature can never be printed.
  text = text.replaceAll(RegExp(r'\?[^\s"]*'), '?…');
  if (text.length > 400) text = '${text.substring(0, 400)}…';
  final cause = switch (error) {
    final InnerTubePlaybackException e => e.cause,
    _ => null,
  };
  return 'type=${error.runtimeType} message=$text'
      '${cause == null ? '' : ' cause=${_describe(cause)}'}';
}
