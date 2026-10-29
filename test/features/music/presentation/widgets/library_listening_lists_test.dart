import 'package:bstream_music/features/music/domain/entities/local_track.dart';
import 'package:bstream_music/features/music/domain/entities/playlist.dart';
import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/features/music/presentation/widgets/library_panel.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('the library offers the listening lists it has songs for', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        lists: {
          ListeningListKind.mostPlayedAllTime: [
            _entry('aaaaaaaaaaa', 'Song A', plays: 12),
            _entry('bbbbbbbbbbb', 'Song B', plays: 4),
          ],
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-most-played-entry')), findsOne);
    expect(find.text('Most played'), findsOne);
    expect(find.text('2 songs · Song A · Song B'), findsOne);
    expect(
      find.byKey(const ValueKey('library-not-played-lately-entry')),
      findsNothing,
    );
  });

  testWidgets('a listening list plays from the tapped song', (tester) async {
    final player = _RecordingPlayerController();
    await tester.pumpWidget(
      _harness(
        player: player,
        lists: {
          ListeningListKind.mostPlayedRecently: [
            _entry('ccccccccccc', 'This month', plays: 6),
            _entry('ddddddddddd', 'Also this month', plays: 2),
          ],
          ListeningListKind.mostPlayedAllTime: [
            _entry('aaaaaaaaaaa', 'Song A', plays: 12),
          ],
          ListeningListKind.notPlayedLately: [
            _entry('eeeeeeeeeee', 'Old favourite', plays: 9),
          ],
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('library-most-played-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Last 30 days'), findsOne);
    expect(find.text('This month'), findsOne);
    expect(find.text('Artist · Played 6 times'), findsOne);

    await tester.tap(find.text('All time'));
    await tester.pumpAndSettle();
    expect(find.text('This month'), findsNothing);
    expect(find.text('Song A'), findsOne);

    await tester.tap(find.text('Last 30 days'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Also this month'));
    await tester.pump();

    expect(player.selected?.track.id, 'ddddddddddd');
    expect(player.queue?.map((item) => item.track.id), [
      'ccccccccccc',
      'ddddddddddd',
    ]);
    expect(player.queueSourceId, 'library-listening:mostPlayedRecently');
  });

  testWidgets('a played song shows as played once', (tester) async {
    await tester.pumpWidget(
      _harness(
        lists: {
          ListeningListKind.notPlayedLately: [
            _entry('eeeeeeeeeee', 'Old favourite', plays: 1),
          ],
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('library-not-played-lately-entry')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not played lately'), findsOne);
    expect(find.text('Artist · Played once'), findsOne);
    expect(
      find.byKey(const ValueKey('library-listening-window')),
      findsNothing,
    );
  });
}

ListeningListEntry _entry(String videoId, String title, {required int plays}) {
  return ListeningListEntry(
    item: HomeRecommendationTrackItem(
      TrackInfo(
        id: videoId,
        title: title,
        artist: 'Artist',
        url: 'https://www.youtube.com/watch?v=$videoId',
      ),
    ),
    playCount: plays,
    lastPlayedAt: DateTime.utc(2026, 10, 1),
  );
}

Widget _harness({
  required Map<ListeningListKind, List<ListeningListEntry>> lists,
  PlayerController? player,
}) {
  return ProviderScope(
    overrides: [
      listeningListProvider.overrideWith(
        (ref, kind) async => lists[kind] ?? const <ListeningListEntry>[],
      ),
      playlistsControllerProvider.overrideWith(_NoPlaylistsController.new),
      catalogPlaylistsProvider.overrideWith((ref) async => const []),
      libraryTracksProvider.overrideWith((ref) async => const <LocalTrack>[]),
      playerControllerProvider.overrideWith(
        () => player ?? _RecordingPlayerController(),
      ),
      appStringsProvider.overrideWithValue(
        const AppStrings(AppLanguage.english),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: LibraryPanel(onOpenPlayer: _noop)),
    ),
  );
}

void _noop() {}

class _NoPlaylistsController extends PlaylistsController {
  @override
  Future<List<Playlist>> build() async => const <Playlist>[];
}

class _RecordingPlayerController extends PlayerController {
  RecommendationPlaybackItem? selected;
  List<RecommendationPlaybackItem>? queue;
  String? queueSourceId;

  @override
  Future<PlayerSnapshot> build() async =>
      const PlayerSnapshot(status: PlayerStatus.stopped);

  @override
  Future<void> playRecommendation(
    RecommendationPlaybackItem selected, {
    required List<RecommendationPlaybackItem> queue,
    String? queueSourceId,
    RecommendationQueueExtender? queueExtender,
  }) async {
    this.selected = selected;
    this.queue = queue;
    this.queueSourceId = queueSourceId;
  }
}
