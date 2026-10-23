import 'package:bstream_music/features/music/domain/entities/local_track.dart';
import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/services/player/loudness_normalization.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('loudnessNormalizationGain', () {
    test('attenuates tracks louder than the target', () {
      expect(loudnessNormalizationGain(6.0206), closeTo(0.5, 0.0001));
      expect(loudnessNormalizationGain(2.07), closeTo(0.788, 0.001));
    });

    test('never boosts quieter or unknown tracks', () {
      expect(loudnessNormalizationGain(-8.16), 1);
      expect(loudnessNormalizationGain(0), 1);
      expect(loudnessNormalizationGain(null), 1);
      expect(loudnessNormalizationGain(double.nan), 1);
    });
  });

  test('crossfade sources expose their track loudness', () {
    final local = LocalTrack(
      id: 'local',
      title: 'Local',
      artist: 'Artist',
      filePath: '/music/local.m4a',
      addedAt: DateTime(2026),
      loudnessDb: 1.5,
    );
    final remote = RemotePlaybackSource(
      track: const TrackInfo(
        id: 'remote',
        title: 'Remote',
        artist: 'Artist',
        url: 'https://www.youtube.com/watch?v=remote',
        loudnessDb: 3.5,
      ),
      uri: Uri.parse('https://media.example/remote'),
      queueEntryId: 'remote:remote',
    );

    expect(crossfadeSourceLoudnessDb(LocalCrossfadePlaybackSource(local)), 1.5);
    expect(
      crossfadeSourceLoudnessDb(RemoteCrossfadePlaybackSource(remote)),
      3.5,
    );
  });
}
