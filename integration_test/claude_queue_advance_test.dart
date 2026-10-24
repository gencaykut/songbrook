import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Plays a live search result queue through the real PlayerController and
/// player service: automatic advance at a song's end, next/previous, and the
/// shuffle and repeat switches.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a remote queue advances, navigates and keeps its options', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final player = container.read(playerControllerProvider.notifier);
    await container.read(playerControllerProvider.future);

    Future<void> settle(bool Function() done, {int seconds = 60}) async {
      for (var i = 0; i < seconds * 10 && !done(); i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    PlayerSnapshot? snapshot() =>
        container.read(playerControllerProvider).value;
    int index() => container.read(playbackQueueProvider).currentIndex;
    void log(String label) {
      final current = snapshot();
      // ignore: avoid_print
      print(
        'CLAUDE_QUEUE $label index=${index()} status=${current?.status} '
        'track=${current?.trackId} position=${current?.position} '
        'duration=${current?.duration} error=${current?.errorMessage}',
      );
    }

    final search = container.read(searchControllerProvider.notifier);
    await search.submit('Tarkan');
    await settle(
      () =>
          container.read(searchControllerProvider).value?.hasSelectedPage ==
          true,
    );
    final tracks = container
        .read(searchControllerProvider)
        .value!
        .selectedTracks
        .take(3)
        .toList();
    expect(tracks, hasLength(3));
    // ignore: avoid_print
    print('CLAUDE_QUEUE tracks=${tracks.map((t) => t.id).toList()}');

    bool playing(TrackInfo track) {
      final current = snapshot();
      return current?.status == PlayerStatus.playing &&
          current?.trackId == track.id &&
          (current?.duration ?? Duration.zero) > Duration.zero;
    }

    await player.playRemote(tracks[0], queue: tracks, queueSourceId: 'search');
    await settle(() => playing(tracks[0]));
    log('first');
    expect(playing(tracks[0]), isTrue);
    expect(index(), 0);

    final duration = snapshot()!.duration!;
    await player.seek(duration - const Duration(seconds: 4));
    await settle(() => playing(tracks[1]), seconds: 40);
    log('after automatic advance');
    expect(index(), 1);
    expect(playing(tracks[1]), isTrue);

    // Next is coalesced with a transition that started under 900 ms ago, so
    // give the automatic advance time to finish, as a listener would.
    await tester.pump(const Duration(seconds: 2));
    await player.playNext();
    await settle(() => playing(tracks[2]));
    log('after next');
    expect(index(), 2);

    await tester.pump(const Duration(seconds: 2));
    await player.playPrevious();
    await settle(() => playing(tracks[1]));
    log('after previous');
    expect(index(), 1);

    player.setShuffleEnabled(true);
    player.setRepeatMode(PlaybackRepeatMode.all);
    await tester.pump(const Duration(milliseconds: 300));
    log('after options');
    expect(snapshot()?.shuffleEnabled, isTrue);
    expect(snapshot()?.repeatMode, PlaybackRepeatMode.all);

    player.setShuffleEnabled(false);
    player.setRepeatMode(PlaybackRepeatMode.off);
    await player.pause();
    await tester.pump(const Duration(seconds: 1));
  });
}
