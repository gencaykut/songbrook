import 'recommendation_storage_models.dart';

/// What this device's listening history says about the listener, for
/// ordering songs YouTube suggests: related radio, the queue's Similar
/// section and Home's recommendations.
///
/// It is deliberately conservative. YouTube's order is kept except that
/// songs the listener keeps skipping are left out, songs by artists they
/// mostly skip go to the end, and songs by artists they play often move up
/// a few places.
class ListeningPreferences {
  const ListeningPreferences({
    this.rejectedTrackKeys = const <String>{},
    this.preferredArtists = const <String>{},
    this.avoidedArtists = const <String>{},
  });

  static const empty = ListeningPreferences();

  /// The window skips and the plays that outweigh them are counted in.
  static const recentWindow = Duration(days: 30);

  /// The window an artist's plays are counted in to prefer them.
  static const artistWindow = Duration(days: 90);

  /// Skips of one song that leave it out, unless it was played since.
  static const rejectAfterSkips = 2;

  /// Skips of an artist's songs, and their share of that artist's listens,
  /// that send the artist's songs to the end.
  static const avoidAfterArtistSkips = 3;
  static const avoidSkipShare = 2 / 3;

  /// Plays of an artist's songs that move them up, and by how many places.
  static const preferAfterArtistPlays = 3;
  static const preferredLead = 3;

  /// Normalized track keys ([recommendationTrackKey]).
  final Set<String> rejectedTrackKeys;

  /// Normalized artist names ([normalizeArtist]).
  final Set<String> preferredArtists;
  final Set<String> avoidedArtists;

  bool get isEmpty =>
      rejectedTrackKeys.isEmpty &&
      preferredArtists.isEmpty &&
      avoidedArtists.isEmpty;

  /// Builds the preferences from skips and plays in [recentWindow]
  /// ([recentSkips], [recentPlays]) and plays in [artistWindow]
  /// ([artistPlays]).
  factory ListeningPreferences.fromHistory({
    required List<PlaybackSkipCount> recentSkips,
    required List<RecommendationSeed> recentPlays,
    required List<RecommendationSeed> artistPlays,
  }) {
    final lastPlayed = <String, DateTime>{
      for (final play in recentPlays) play.trackKey: play.lastPlayedAt,
    };
    final rejected = <String>{
      for (final skip in recentSkips)
        if (skip.count >= rejectAfterSkips &&
            !(lastPlayed[skip.trackKey]?.isAfter(skip.lastSkippedAt) ?? false))
          skip.trackKey,
    };

    final artistSkips = <String, int>{};
    for (final skip in recentSkips) {
      for (final artist in _artistsOf(skip.artists)) {
        artistSkips[artist] = (artistSkips[artist] ?? 0) + skip.count;
      }
    }
    final recentArtistPlays = _playsByArtist(recentPlays);
    final avoided = <String>{
      for (final entry in artistSkips.entries)
        if (entry.value >= avoidAfterArtistSkips &&
            entry.value / (entry.value + (recentArtistPlays[entry.key] ?? 0)) >=
                avoidSkipShare)
          entry.key,
    };

    final preferred = <String>{
      for (final entry in _playsByArtist(artistPlays).entries)
        if (entry.value >= preferAfterArtistPlays &&
            !avoided.contains(entry.key))
          entry.key,
    };

    return ListeningPreferences(
      rejectedTrackKeys: Set<String>.unmodifiable(rejected),
      preferredArtists: Set<String>.unmodifiable(preferred),
      avoidedArtists: Set<String>.unmodifiable(avoided),
    );
  }

  static String normalizeArtist(String artist) => artist.trim().toLowerCase();

  /// Orders [items] for the listener. [trackKey] gives an item's
  /// [recommendationTrackKey] and [artists] its artist names.
  List<T> rank<T>(
    Iterable<T> items, {
    required String? Function(T item) trackKey,
    required List<String> Function(T item) artists,
  }) {
    final list = items.toList(growable: false);
    if (isEmpty) return list;
    final placed = <({T item, int index, int position})>[];
    for (var index = 0; index < list.length; index++) {
      final item = list[index];
      final key = trackKey(item);
      if (key != null && rejectedTrackKeys.contains(key)) continue;
      final names = _artistsOf(artists(item));
      // Positions are doubled so a preferred song lands just ahead of the
      // song it moves up to.
      final position = names.any(avoidedArtists.contains)
          ? 2 * (list.length + index)
          : names.any(preferredArtists.contains)
          ? 2 * (index - preferredLead) - 1
          : 2 * index;
      placed.add((item: item, index: index, position: position));
    }
    placed.sort((left, right) {
      final byPosition = left.position.compareTo(right.position);
      return byPosition != 0 ? byPosition : left.index.compareTo(right.index);
    });
    return List<T>.unmodifiable(placed.map((entry) => entry.item));
  }

  static Iterable<String> _artistsOf(List<String> artists) =>
      artists.map(normalizeArtist).where((artist) => artist.isNotEmpty).toSet();

  static Map<String, int> _playsByArtist(List<RecommendationSeed> plays) {
    final counts = <String, int>{};
    for (final play in plays) {
      for (final artist in _artistsOf(play.artists)) {
        counts[artist] = (counts[artist] ?? 0) + play.playCount;
      }
    }
    return counts;
  }
}
