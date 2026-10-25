import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays a music video with known SponsorBlock music_offtopic segments
/// through the real controller and player, with and without the song
/// version preference.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final preferSong in [true, false]) {
    testWidgets('a music video, preferSongVersions=$preferSong', (
      tester,
    ) async {
      // Start without remembered resolutions, which would replay the stream
      // chosen under the other setting.
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (key.startsWith('remote_track_resolution_cache')) {
          await prefs.remove(key);
        }
      }
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(settingsControllerProvider.future);
      await container
          .read(settingsControllerProvider.notifier)
          .setPreferSongVersions(preferSong);
      final player = container.read(playerControllerProvider.notifier);
      await container.read(playerControllerProvider.future);
      const video = TrackInfo(
        id: 'kJQP7kiw5Fk',
        title: 'Despacito',
        artist: 'Luis Fonsi',
        artists: ['Luis Fonsi', 'Daddy Yankee'],
        url: 'https://www.youtube.com/watch?v=kJQP7kiw5Fk',
        duration: Duration(minutes: 4, seconds: 42),
      );
      final song = await container
          .read(songCounterpartFinderProvider)
          .find(video, videoDuration: video.duration);

      await player.playRemote(video, queue: [video]);
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final snapshot = container.read(playerControllerProvider).value;
      await player.pause();
      // ignore: avoid_print
      print(
        'CLAUDE_SB preferSong=$preferSong song=${song?.videoId} '
        '"${song?.title}" ${song?.duration} position=${snapshot?.position} '
        'duration=${snapshot?.duration}',
      );
      if (preferSong && song != null) {
        expect(snapshot!.position, lessThan(const Duration(seconds: 21)));
      } else {
        expect(snapshot!.position, greaterThan(const Duration(seconds: 21)));
      }
    });
  }
}
