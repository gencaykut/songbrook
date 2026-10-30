import 'package:bstream_music/services/recommendations/recommendations.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 10, 30, 12);

PlaybackSkipCount _skips(
  String key,
  int count, {
  String artist = 'Artist',
  Duration ago = Duration.zero,
}) => PlaybackSkipCount(
  trackKey: key,
  artists: [artist],
  count: count,
  lastSkippedAt: _now.subtract(ago),
);

RecommendationSeed _plays(
  String key,
  int count, {
  String artist = 'Artist',
  Duration ago = Duration.zero,
}) => RecommendationSeed(
  trackKey: key,
  trackId: key,
  videoId: key,
  title: 'Song $key',
  artists: [artist],
  source: PlaybackEventSource.streaming,
  playCount: count,
  totalListenedMs: count * 180000,
  completedCount: count,
  lastPlayedAt: _now.subtract(ago),
);

typedef _Song = ({String key, String artist});

List<String> _rank(ListeningPreferences preferences, List<_Song> songs) =>
    preferences
        .rank<_Song>(
          songs,
          trackKey: (song) => song.key,
          artists: (song) => [song.artist],
        )
        .map((song) => song.key)
        .toList();

void main() {
  test('without history the order is unchanged', () {
    final songs = [for (var i = 0; i < 5; i++) (key: 'song$i', artist: 'A$i')];
    expect(
      _rank(ListeningPreferences.empty, songs),
      songs.map((song) => song.key),
    );
  });

  test('a song skipped twice is left out unless played since', () {
    final preferences = ListeningPreferences.fromHistory(
      recentSkips: [
        _skips('twice', 2, artist: 'One'),
        _skips('once', 1, artist: 'Two'),
        _skips('forgiven', 2, artist: 'Three', ago: const Duration(days: 2)),
      ],
      recentPlays: [_plays('forgiven', 1, artist: 'Three')],
      artistPlays: const [],
    );

    expect(preferences.rejectedTrackKeys, {'twice'});
    expect(
      _rank(preferences, [
        (key: 'twice', artist: 'One'),
        (key: 'once', artist: 'Two'),
        (key: 'forgiven', artist: 'Three'),
      ]),
      ['once', 'forgiven'],
    );
  });

  test('an artist mostly skipped goes to the end', () {
    final preferences = ListeningPreferences.fromHistory(
      recentSkips: [
        _skips('a', 2, artist: 'Skipped Artist', ago: const Duration(days: 1)),
        _skips('b', 1, artist: 'Skipped Artist'),
        _skips('c', 3, artist: 'Mixed Artist'),
      ],
      recentPlays: [
        _plays('a', 1, artist: 'Skipped Artist'),
        _plays('d', 4, artist: 'Mixed Artist'),
      ],
      artistPlays: const [],
    );

    // 3 skips, 1 play: avoided. 3 skips, 4 plays: not.
    expect(preferences.avoidedArtists, {'skipped artist'});
    expect(
      _rank(preferences, [
        (key: 'x1', artist: 'skipped artist'),
        (key: 'x2', artist: 'Other'),
        (key: 'x3', artist: 'Mixed Artist'),
        (key: 'x4', artist: 'Skipped Artist '),
      ]),
      ['x2', 'x3', 'x1', 'x4'],
    );
  });

  test('a loved artist moves up a few places, not to the top', () {
    final preferences = ListeningPreferences.fromHistory(
      recentSkips: const [],
      recentPlays: const [],
      artistPlays: [
        _plays('p1', 2, artist: 'Loved'),
        _plays('p2', 1, artist: 'Loved'),
        _plays('p3', 2, artist: 'Casual'),
      ],
    );

    expect(preferences.preferredArtists, {'loved'});
    final songs = [for (var i = 0; i < 8; i++) (key: 's$i', artist: 'Other')]
      ..[6] = (key: 'loved', artist: 'Loved');
    expect(_rank(preferences, songs), [
      's0',
      's1',
      's2',
      'loved',
      's3',
      's4',
      's5',
      's7',
    ]);
  });

  test('an artist both loved and mostly skipped is avoided', () {
    final preferences = ListeningPreferences.fromHistory(
      recentSkips: [_skips('a', 4, artist: 'Torn')],
      recentPlays: const [],
      artistPlays: [_plays('b', 5, artist: 'Torn')],
    );

    expect(preferences.avoidedArtists, {'torn'});
    expect(preferences.preferredArtists, isEmpty);
  });
}
