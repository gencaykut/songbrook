import 'dart:async';
import 'dart:io';

import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/player/notification_artwork_service.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Plays a live song through the real player and fetches the artwork URL the
/// lock screen is given, printing what comes back. Then keeps playing for a
/// minute so the simulator's lock screen can be looked at.
///
/// flutter test integration_test/claude_lockscreen_artwork_test.dart -d 4164F7C0-8133-419B-AA72-02E6ABC9AA6F
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('lock-screen artwork', (tester) async {
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
    unawaited(player.playRemote(tracks[0], queue: tracks));
    await settle(() => snapshot()?.status == PlayerStatus.playing);

    final thumbnail = snapshot()?.thumbnailUrl;
    // ignore: avoid_print
    print('CLAUDE_ART thumbnail=$thumbnail');
    final uri = NotificationArtworkService.instance.uriFor(thumbnail);
    // ignore: avoid_print
    print('CLAUDE_ART lockscreen uri=$uri');
    if (uri != null) {
      final client = HttpClient();
      try {
        final request = await client.getUrl(uri);
        final response = await request.close();
        final bytes = await response.fold<int>(
          0,
          (n, chunk) => n + chunk.length,
        );
        // ignore: avoid_print
        print(
          'CLAUDE_ART fetch status=${response.statusCode} '
          'type=${response.headers.contentType} bytes=$bytes',
        );
      } catch (error) {
        // ignore: avoid_print
        print('CLAUDE_ART fetch failed: $error');
      } finally {
        client.close();
      }
    }
    // ignore: avoid_print
    print('CLAUDE_ART ready to lock');
    await tester.pump(const Duration(seconds: 60));
    await player.pause();
  });
}
