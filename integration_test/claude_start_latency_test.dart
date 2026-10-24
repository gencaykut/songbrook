import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:bstream_music/services/youtube_music/playback/ejs_solver.dart';
import 'package:bstream_music/services/youtube_music/playback/headless_inappwebview_runtime.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_playback_service.dart';
import 'package:bstream_music/services/youtube_music/playback/po_token_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Measures how long a selected song takes to start: the raw InnerTube
/// resolution (including its deep media probe) and the app's own timeline
/// from playRemote to audible playback.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('time from selection to playback', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    Future<void> settle(bool Function() done, {int seconds = 30}) async {
      for (var i = 0; i < seconds * 50 && !done(); i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
    }

    final search = container.read(searchControllerProvider.notifier);
    await search.submit('Sezen Aksu');
    await settle(
      () =>
          container.read(searchControllerProvider).value?.hasSelectedPage ==
          true,
    );
    final tracks = container
        .read(searchControllerProvider)
        .value!
        .selectedTracks
        .take(6)
        .toList();
    expect(tracks.length, greaterThanOrEqualTo(6));

    // 1. Raw resolver, outside the app: cold first, then warm.
    final playback = InnerTubePlaybackService(
      ejsSolver: EjsSolver(runtime: HeadlessInAppWebViewJavaScriptRuntime()),
      poTokenProvider: BotGuardPoTokenProvider(),
    );
    for (final track in tracks.take(3)) {
      final watch = Stopwatch()..start();
      final resolved = await playback.resolve(track.id);
      // ignore: avoid_print
      print(
        'CLAUDE_LATENCY resolve video=${track.id} '
        'client=${resolved.profile.key} itag=${resolved.format.itag} '
        'totalMs=${watch.elapsedMilliseconds} '
        'resolutionMs=${resolved.resolutionElapsed.inMilliseconds} '
        'probeMs=${resolved.probe.elapsed.inMilliseconds}',
      );
    }

    // 2. The app: playRemote to playing, then to an advancing position.
    final player = container.read(playerControllerProvider.notifier);
    await container.read(playerControllerProvider.future);
    for (final track in tracks.skip(3)) {
      final watch = Stopwatch()..start();
      final events = <String>[];
      String? last;
      final sub = container.listen<AsyncValue<PlayerSnapshot>>(
        playerControllerProvider,
        (_, next) {
          final snapshot = next.value;
          if (snapshot == null || snapshot.trackId != track.id) return;
          final label =
              '${snapshot.status.name}'
              '${snapshot.sourceUrl == null || snapshot.sourceUrl == track.url ? '' : '+stream'}'
              '${snapshot.position > Duration.zero ? '+moving' : ''}';
          if (label != last) {
            last = label;
            events.add('${watch.elapsedMilliseconds}ms:$label');
          }
        },
      );
      final call = player.playRemote(track, queue: [track]);
      await settle(() {
        final snapshot = container.read(playerControllerProvider).value;
        return snapshot?.trackId == track.id &&
            snapshot?.status == PlayerStatus.playing &&
            snapshot!.position > const Duration(milliseconds: 200);
      });
      await call;
      sub.close();
      // ignore: avoid_print
      print(
        'CLAUDE_LATENCY app video=${track.id} '
        'audibleMs=${watch.elapsedMilliseconds} events=${events.join(' ')}',
      );
      await player.pause();
      await tester.pump(const Duration(seconds: 1));
    }
  });
}
