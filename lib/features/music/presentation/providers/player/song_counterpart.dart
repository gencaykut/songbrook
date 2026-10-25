import '../../../../../services/youtube_music/innertube_search_service.dart';
import '../../../domain/entities/track_info.dart';

/// YouTube Music publishes the song (audio-only, "ATV") version of a track on
/// an auto-generated `<Artist> - Topic` channel. A stream from any other
/// channel is a music video or an upload, with intros, skits or a different
/// mix.
bool isSongVersionChannel(String channel) =>
    channel.trim().toLowerCase().endsWith(' - topic');

/// Finds the song version of the music video [video] among [candidates],
/// usually the results of a song search for its title and artist.
///
/// Deliberately strict, since playing the wrong song is worse than playing
/// the video: the titles must be equal once video labels such as
/// "(Official Video)" and featured credits are removed, while qualifiers such
/// as "Live", "Remix" or "Akustik" are kept; one credited artist must match,
/// counting an artist named before the title;
/// and the song may be at most 30 seconds longer than the video, which often
/// adds an intro or outro, and at least half its length.
InnerTubeSong? matchSongCounterpart({
  required TrackInfo video,
  required Duration? videoDuration,
  required List<InnerTubeSong> candidates,
}) {
  // Lyric videos and re-uploads come from other channels but usually name
  // the artist before the title, as in "Artist - Title (Lyrics)".
  final dash = video.title.indexOf(' - ');
  final titleArtists = dash > 0
      ? _splitArtists(video.title.substring(0, dash))
      : const <String>[];
  final artists = {
    for (final artist in [
      ...video.artists,
      ..._splitArtists(video.artist),
      ...titleArtists,
    ])
      if (_normalize(artist).isNotEmpty) _normalize(artist),
  };
  final title = normalizeSongTitle(video.title, artists: artists);
  if (title.isEmpty || artists.isEmpty) return null;
  for (final candidate in candidates) {
    if (candidate.videoId == video.id) continue;
    final candidateArtists = {
      for (final artist in [
        ...candidate.artists,
        ..._splitArtists(candidate.artist),
      ])
        _normalize(artist),
    };
    if (!candidateArtists.any(artists.contains)) continue;
    if (normalizeSongTitle(candidate.title, artists: candidateArtists) !=
        title) {
      continue;
    }
    final songLength = candidate.duration;
    if (videoDuration != null && songLength != null) {
      if (songLength > videoDuration + const Duration(seconds: 30) ||
          songLength * 2 < videoDuration) {
        continue;
      }
    }
    return candidate;
  }
  return null;
}

/// The comparable form of a song title: an "Artist - " prefix, video labels
/// and featured credits removed, case, Turkish letters and punctuation
/// folded.
String normalizeSongTitle(String title, {Set<String> artists = const {}}) {
  var value = title;
  final dash = value.indexOf(' - ');
  if (dash > 0) {
    final prefix = _normalize(value.substring(0, dash));
    if (artists.any((artist) => prefix.contains(artist))) {
      value = value.substring(dash + 3);
    }
  }
  value = value.replaceAllMapped(
    RegExp(r'[\(\[]([^\)\]]*)[\)\]]'),
    (match) => _isVideoLabel(match[1]!) ? ' ' : match[0]!,
  );
  value = value.replaceAll(
    RegExp(r'\s(feat\.?|ft\.?|featuring)\s.*$', caseSensitive: false),
    '',
  );
  return _normalize(value);
}

bool _isVideoLabel(String label) {
  final value = _normalize(label);
  if (RegExp(r'^(feat|ft|featuring|con|with)\b').hasMatch(value)) return true;
  return RegExp(
    r'\b(official|video|audio|lyrics?|lirik|klip|visuali[sz]er|mv|hd|4k)\b',
  ).hasMatch(value);
}

Iterable<String> _splitArtists(String value) =>
    value.split(RegExp(r',|&| x | feat\.? | ft\.? ', caseSensitive: false));

String _normalize(String value) {
  const folded = {
    'ı': 'i',
    'İ': 'i',
    'ş': 's',
    'Ş': 's',
    'ç': 'c',
    'Ç': 'c',
    'ğ': 'g',
    'Ğ': 'g',
    'ö': 'o',
    'Ö': 'o',
    'ü': 'u',
    'Ü': 'u',
  };
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final character = String.fromCharCode(rune);
    buffer.write(folded[character] ?? character.toLowerCase());
  }
  return buffer
      .toString()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();
}

/// Searches for, and remembers for the session, the song version of music
/// videos. A failed search is forgotten so a later play can try again.
class SongCounterpartFinder {
  SongCounterpartFinder(this._search);

  final YouTubeMusicSearch _search;
  final _matches = <String, Future<InnerTubeSong?>>{};

  Future<InnerTubeSong?> find(TrackInfo video, {Duration? videoDuration}) {
    final key = video.id;
    return _matches.putIfAbsent(key, () async {
      try {
        final candidates = await _search.searchSongs(
          '${video.title} ${video.artist}',
          limit: 5,
        );
        return matchSongCounterpart(
          video: video,
          videoDuration: videoDuration ?? video.duration,
          candidates: candidates,
        );
      } catch (_) {
        _matches.remove(key);
        rethrow;
      }
    });
  }
}
