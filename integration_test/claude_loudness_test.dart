import 'dart:io';

import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/services/downloader/innertube_audio_resolver.dart';
import 'package:bstream_music/services/player/just_audio_player_service.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_playback_service.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_stream_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';

/// Resolves live songs through the app's resolver and plays them with the
/// real JustAudioPlayerService, checking the volume written to AVPlayer.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loud streams play attenuated, quiet ones at full volume', (
    _,
  ) async {
    final search = InnerTubeSearchService();
    final playback = InnerTubePlaybackService(
      audioFormatPredicate: Platform.isIOS
          ? isAvFoundationCompatibleInnerTubeAudio
          : null,
      requestTimeout: const Duration(seconds: 20),
    );
    final resolver = InnerTubeAudioResolver(playback);
    final player = AudioPlayer(useProxyForRequestHeaders: false);
    final service = JustAudioPlayerService(audioPlayer: player);
    try {
      await service.configureLoudnessNormalization(enabled: true);
      await service.setVolume(0.9);
      for (final query in [
        'Metallica Enter Sandman',
        'Ludovico Einaudi Nuvole Bianche',
      ]) {
        final song = (await search.searchSongs(query, limit: 1)).single;
        final base = TrackInfo(
          id: song.videoId,
          title: song.title,
          artist: song.artists.join(', '),
          url: 'https://music.youtube.com/watch?v=${song.videoId}',
        );
        final resolution = await resolver.resolve(base);
        final track = base.copyWith(
          streamUrl: resolution.streamUrl,
          streamExtension: resolution.streamExtension,
          streamDuration: resolution.streamDuration,
          loudnessDb: resolution.loudnessDb,
          httpHeaders: resolution.httpHeaders,
        );
        await service.playRemoteSource(
          RemotePlaybackSource(
            track: track,
            uri: Uri.parse(resolution.streamUrl),
            queueEntryId: 'live:${song.videoId}',
            httpHeaders: resolution.httpHeaders,
          ),
        );
        await Future<void>.delayed(const Duration(seconds: 6));
        final loudness = resolution.loudnessDb;
        // ignore: avoid_print
        print(
          'CLAUDE_LOUDNESS "$query" ${song.videoId} '
          'profile=${resolution.clientProfileKey} itag=${resolution.formatId} '
          'loudnessDb=$loudness playerVolume=${player.volume} '
          'snapshotVolume=${service.currentSnapshot.volume} '
          'position=${player.position.inMilliseconds}ms',
        );
        expect(loudness, isNotNull);
        expect(player.position.inMilliseconds, greaterThan(2000));
        expect(service.currentSnapshot.volume, 0.9);
        if (loudness! > 0) {
          expect(player.volume, lessThan(0.9));
        } else {
          expect(player.volume, closeTo(0.9, 0.001));
        }
      }
    } finally {
      await service.dispose();
      await playback.dispose();
      search.dispose();
    }
  });
}
