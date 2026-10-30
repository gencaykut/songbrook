import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Compares the time from playRemote to audible playback for songs whose
/// stream was resolved ahead, as Home's Continue listening prewarm does, with
/// songs resolved on the tap. Cold and warm songs alternate so network drift
/// affects both.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('prewarmed versus cold start', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    Future<void> settle(bool Function() done, {int seconds = 30}) async {
      for (var i = 0; i < seconds * 50 && !done(); i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
    }

    final search = container.read(searchControllerProvider.notifier);
    await search.submit(
      const String.fromEnvironment('CLAUDE_QUERY', defaultValue: 'Tarkan'),
    );
    await settle(
      () =>
          container.read(searchControllerProvider).value?.hasSelectedPage ==
          true,
    );
    final tracks = container
        .read(searchControllerProvider)
        .value!
        .selectedTracks
        .take(16)
        .toList();
    expect(tracks.length, 16);

    final warm = [
      for (var i = 0; i < tracks.length; i++)
        if (i.isOdd) tracks[i],
    ];
    final resolver = container.read(remoteTrackResolverProvider);
    for (final track in warm) {
      final watch = Stopwatch()..start();
      await resolver.resolve(track);
      // ignore: avoid_print
      print(
        'CLAUDE_PREWARM resolve video=${track.id} '
        'ms=${watch.elapsedMilliseconds}',
      );
    }

    final player = container.read(playerControllerProvider.notifier);
    await container.read(playerControllerProvider.future);
    final results = <String, List<int>>{'cold': [], 'warm': []};
    for (final track in tracks) {
      final kind = warm.contains(track) ? 'warm' : 'cold';
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
            events.add('${watch.elapsedMilliseconds}:$label');
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
      results[kind]!.add(watch.elapsedMilliseconds);
      // ignore: avoid_print
      print(
        'CLAUDE_PREWARM app $kind video=${track.id} '
        'audibleMs=${watch.elapsedMilliseconds} events=${events.join(' ')}',
      );
      await player.pause();
      await tester.pump(const Duration(seconds: 1));
    }
    for (final entry in results.entries) {
      final sorted = [...entry.value]..sort();
      // ignore: avoid_print
      print(
        'CLAUDE_PREWARM median ${entry.key}=${sorted[sorted.length ~/ 2]}ms '
        'all=$sorted',
      );
    }
  });
}
