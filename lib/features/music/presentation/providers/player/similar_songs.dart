import '../../../../../services/youtube_music/innertube_models.dart';

/// What the queue's "Similar" section is built from: the playing song's
/// related radio and other songs by its artist.
class SimilarSongsSeed {
  const SimilarSongsSeed({this.videoId, this.artist});

  final String? videoId;
  final String? artist;

  bool get isEmpty =>
      (videoId?.trim().isEmpty ?? true) && (artist?.trim().isEmpty ?? true);

  @override
  bool operator ==(Object other) =>
      other is SimilarSongsSeed &&
      other.videoId == videoId &&
      other.artist == artist;

  @override
  int get hashCode => Object.hash(videoId, artist);
}

/// Alternates the related radio, which brings similar artists, with the
/// artist's own songs, so neither source crowds out the other. Songs already
/// in the queue and repeats are left out.
List<InnerTubeSong> mergeSimilarSongs({
  required List<InnerTubeSong> radio,
  required List<InnerTubeSong> artistSongs,
  required Set<String> excludedVideoIds,
  int limit = 20,
}) {
  final seen = <String>{...excludedVideoIds};
  final merged = <InnerTubeSong>[];
  final longest = radio.length > artistSongs.length
      ? radio.length
      : artistSongs.length;
  for (var index = 0; index < longest && merged.length < limit; index++) {
    for (final source in [radio, artistSongs]) {
      if (index >= source.length || merged.length >= limit) continue;
      final song = source[index];
      if (song.videoId.isEmpty || !seen.add(song.videoId)) continue;
      merged.add(song);
    }
  }
  return merged;
}
