import 'dart:async';

import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// A seek right as a song starts, through the real player: on the Mac
/// libmpv dropped it and the song played from its start. Also the Songbrook
/// Connect handoff path: a queue prepared paused, then seek and resume.
///
/// flutter test integration_test/claude_early_seek_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a seek as a song starts lands where it was sent', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final player = container.read(playerControllerProvider.notifier);
    await container.read(playerControllerProvider.future);
    PlayerSnapshot? snapshot() =>
        container.read(playerControllerProvider).value;

    Future<void> settle(bool Function() done, {int seconds = 30}) async {
      for (var i = 0; i < seconds * 10 && !done(); i++) {
        await tester.pump(const Duration(milliseconds: 100));
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
        .take(3)
        .toList();
    expect(tracks, hasLength(3));

    // 1. Seek the moment the song reports it is playing.
    unawaited(player.playRemote(tracks[0], queue: tracks));
    await settle(
      () =>
          snapshot()?.status == PlayerStatus.playing &&
          snapshot()?.trackId == tracks[0].id,
    );
    await player.seek(const Duration(seconds: 60));
    await tester.pump(const Duration(seconds: 4));
    final first = snapshot()!.position;
    // ignore: avoid_print
    print('CLAUDE_SEEK early seek → $first');
    expect(first, greaterThan(const Duration(seconds: 58)));

    // 2. The handoff path: prepared paused at 1:30, then seek and resume.
    await player.pause();
    await player.prepareRemoteQueue(
      tracks,
      1,
      position: const Duration(seconds: 90),
    );
    await player.seek(const Duration(seconds: 91));
    unawaited(player.resume());
    await settle(
      () =>
          snapshot()?.status == PlayerStatus.playing &&
          snapshot()?.trackId == tracks[1].id,
    );
    await tester.pump(const Duration(seconds: 4));
    final second = snapshot()!.position;
    // ignore: avoid_print
    print('CLAUDE_SEEK handoff resume → $second');
    expect(second, greaterThan(const Duration(seconds: 89)));

    await player.pause();
    await tester.pump(const Duration(seconds: 1));
  });
}
