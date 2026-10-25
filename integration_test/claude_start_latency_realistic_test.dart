import 'package:bstream_music/features/music/domain/entities/search_result.dart';
import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:bstream_music/services/youtube_music/playback/ejs_solver.dart';
import 'package:bstream_music/services/youtube_music/playback/headless_inappwebview_runtime.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_playback_service.dart';
import 'package:bstream_music/services/youtube_music/playback/po_token_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Measures start latency the way the app is used: the whole result list is
/// the queue (so upcoming songs are prefetched), songs are picked one after
/// another while the previous one is playing or still loading, and music
/// videos are included.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('realistic start latency', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final origin = Stopwatch()..start();

    Future<void> settle(bool Function() done, {int seconds = 40}) async {
      for (var i = 0; i < seconds * 50 && !done(); i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
    }

    Future<void> wait(Duration duration) async {
      final until = origin.elapsed + duration;
      while (origin.elapsed < until) {
        await tester.pump(const Duration(milliseconds: 20));
      }
    }

    Future<List<TrackInfo>> results(
      String query,
      SearchCategory category,
    ) async {
      final search = container.read(searchControllerProvider.notifier);
      await search.submit(query);
      await settle(
        () =>
            container.read(searchControllerProvider).value?.hasSelectedPage ==
            true,
      );
      if (category != SearchCategory.songs) {
        await search.selectCategory(category);
        await settle(() {
          final state = container.read(searchControllerProvider).value;
          return state?.selectedCategory == category &&
              state?.loadingCategory == null;
        });
      }
      return container
          .read(searchControllerProvider)
          .value!
          .selectedTracks
          .toList();
    }

    final player = container.read(playerControllerProvider.notifier);
    await container.read(playerControllerProvider.future);

    bool audible(TrackInfo track) {
      final snapshot = container.read(playerControllerProvider).value;
      return snapshot?.trackId == track.id &&
          snapshot?.status == PlayerStatus.playing &&
          snapshot!.position > const Duration(milliseconds: 200);
    }

    /// Starts [track] with [queue] and, unless [waitAudible] is false,
    /// waits until it is audible. Prints the status timeline.
    Future<void> pick(
      String label,
      TrackInfo track,
      List<TrackInfo> queue, {
      bool waitAudible = true,
    }) async {
      final watch = Stopwatch()..start();
      final events = <String>[];
      String? last;
      // Songs other than [track] heard while it was starting, such as an
      // abandoned pick that finished loading.
      final others = <String>{};
      final sub = container.listen<AsyncValue<PlayerSnapshot>>(
        playerControllerProvider,
        (_, next) {
          final snapshot = next.value;
          if (snapshot != null &&
              snapshot.trackId != track.id &&
              snapshot.status == PlayerStatus.playing &&
              snapshot.position > const Duration(milliseconds: 200)) {
            others.add(snapshot.trackId ?? '?');
          }
          if (snapshot == null || snapshot.trackId != track.id) return;
          final name =
              '${snapshot.status.name}'
              '${snapshot.position > Duration.zero ? '+moving' : ''}';
          if (name != last) {
            last = name;
            events.add('${watch.elapsedMilliseconds}:$name');
          }
        },
      );
      final call = player.playRemote(track, queue: queue);
      if (!waitAudible) {
        await wait(const Duration(milliseconds: 600));
        sub.close();
        // ignore: avoid_print
        print('CLAUDE_REAL $label video=${track.id} abandoned after 600ms');
        return;
      }
      await settle(() => audible(track));
      sub.close();
      // ignore: avoid_print
      print(
        'CLAUDE_REAL $label video=${track.id} '
        'audibleMs=${audible(track) ? watch.elapsedMilliseconds : -1} '
        'title="${track.title}" others=${others.join(',')} '
        'events=${events.join(' ')}',
      );
      await call.timeout(const Duration(seconds: 5), onTimeout: () {});
    }

    final songs = await results('Sezen Aksu', SearchCategory.songs);
    expect(songs.length, greaterThanOrEqualTo(17));

    // The raw resolver on this network: which client answers and how long
    // the player request and the deep media probe take.
    final playback = InnerTubePlaybackService(
      ejsSolver: EjsSolver(runtime: HeadlessInAppWebViewJavaScriptRuntime()),
      poTokenProvider: BotGuardPoTokenProvider(),
    );
    for (final track in songs.skip(14).take(3)) {
      final watch = Stopwatch()..start();
      final resolved = await playback.resolve(track.id);
      // ignore: avoid_print
      print(
        'CLAUDE_RAW video=${track.id} client=${resolved.profile.key} '
        'itag=${resolved.format.itag} totalMs=${watch.elapsedMilliseconds} '
        'resolutionMs=${resolved.resolutionElapsed.inMilliseconds} '
        'probeMs=${resolved.probe.elapsed.inMilliseconds}',
      );
    }

    // Cold start with the whole result list as the queue.
    await pick('cold', songs[0], songs);
    // Let prefetch of upcoming songs run, then pick another result.
    await wait(const Duration(seconds: 6));
    await pick('after-6s', songs[6], songs);
    // Pick again soon after the previous one started.
    await wait(const Duration(seconds: 1));
    await pick('after-1s', songs[9], songs);
    // Rapid switching: abandon one while loading, then pick another.
    await pick('abandoned', songs[3], songs, waitAudible: false);
    await pick('after-abandon', songs[11], songs);
    await wait(const Duration(seconds: 4));
    // A prefetched song: the next one in the queue.
    await pick('prefetched-next', songs[12], songs);

    final videos = await results('Tarkan', SearchCategory.videos);
    expect(videos.length, greaterThanOrEqualTo(4));
    await wait(const Duration(seconds: 2));
    await pick('video', videos[0], videos);
    await wait(const Duration(seconds: 4));
    await pick('video-2', videos[2], videos);
    await wait(const Duration(seconds: 4));
    await pick('video-next', videos[3], videos);
    await player.pause();
  });
}
