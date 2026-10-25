import 'package:bstream_music/features/music/presentation/providers/player/similar_songs.dart';
import 'package:bstream_music/services/youtube_music/innertube_models.dart';
import 'package:flutter_test/flutter_test.dart';

InnerTubeSong _song(String id, {String artist = 'Artist'}) =>
    InnerTubeSong(videoId: id, title: 'Song $id', artists: [artist]);

void main() {
  test('alternates radio and artist songs', () {
    final merged = mergeSimilarSongs(
      radio: [_song('r1'), _song('r2'), _song('r3')],
      artistSongs: [_song('a1')],
      excludedVideoIds: const {},
    );

    expect(merged.map((song) => song.videoId), ['r1', 'a1', 'r2', 'r3']);
  });

  test('leaves out queued songs and repeats across both sources', () {
    final merged = mergeSimilarSongs(
      radio: [_song('queued'), _song('both'), _song('r2')],
      artistSongs: [_song('both'), _song('a2'), _song('queued')],
      excludedVideoIds: const {'queued'},
    );

    expect(merged.map((song) => song.videoId), ['both', 'a2', 'r2']);
  });

  test('stops at the limit', () {
    final merged = mergeSimilarSongs(
      radio: [for (var i = 0; i < 30; i++) _song('r$i')],
      artistSongs: [for (var i = 0; i < 30; i++) _song('a$i')],
      excludedVideoIds: const {},
      limit: 5,
    );

    expect(merged.map((song) => song.videoId), ['r0', 'a0', 'r1', 'a1', 'r2']);
  });

  test('a seed needs a video or an artist', () {
    expect(const SimilarSongsSeed().isEmpty, isTrue);
    expect(const SimilarSongsSeed(artist: ' ').isEmpty, isTrue);
    expect(const SimilarSongsSeed(artist: 'Tarkan').isEmpty, isFalse);
    expect(const SimilarSongsSeed(videoId: 'abc').isEmpty, isFalse);
  });
}
