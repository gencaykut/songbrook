import 'dart:io';

import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/recommendations/recommendations.dart';
import 'package:bstream_music/services/storage/local_database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory directory;
  late _TestLocalDatabaseService database;
  final now = DateTime.utc(2026, 10, 29, 12);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('bstream-listening-');
    database = _TestLocalDatabaseService(p.join(directory.path, 'library.db'));
    var session = 0;
    Future<void> play(String videoId, DateTime at) {
      session += 1;
      return database.recordPlaybackEvent(
        PlaybackEvent(
          sessionId: 'session-$session',
          trackId: videoId,
          videoId: videoId,
          title: 'Song $videoId',
          artists: const ['Artist'],
          source: PlaybackEventSource.streaming,
          startedAt: at,
          playedAt: at.add(const Duration(minutes: 3)),
          listenedMs: 180000,
          completed: true,
        ),
      );
    }

    for (var day = 0; day < 4; day += 1) {
      await play('oldfavour01', now.subtract(Duration(days: 90 + day)));
    }
    for (var day = 0; day < 2; day += 1) {
      await play('thisweek001', now.subtract(Duration(days: day)));
    }
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  ProviderContainer container({required bool historyEnabled}) {
    final container = ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(database),
        listeningListClockProvider.overrideWithValue(() => now),
        settingsControllerProvider.overrideWith(
          () => _FixedSettingsController(
            SettingsState(
              downloadDirectory: directory.path,
              language: AppLanguage.english,
              recommendationHistoryEnabled: historyEnabled,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<List<String>> ids(
    ProviderContainer container,
    ListeningListKind kind,
  ) async {
    final subscription = container.listen(
      listeningListProvider(kind),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(settingsControllerProvider.future);
    final entries = await container.read(listeningListProvider(kind).future);
    return entries.map((entry) => entry.track.id).toList();
  }

  test('builds each listening list from the history', () async {
    final lists = container(historyEnabled: true);

    expect(await ids(lists, ListeningListKind.mostPlayedAllTime), [
      'oldfavour01',
      'thisweek001',
    ]);
    expect(await ids(lists, ListeningListKind.mostPlayedRecently), [
      'thisweek001',
    ]);
    expect(await ids(lists, ListeningListKind.notPlayedLately), [
      'oldfavour01',
    ]);

    final entry = (await lists.read(
      listeningListProvider(ListeningListKind.mostPlayedAllTime).future,
    )).first;
    expect(entry.playCount, 4);
    expect(entry.track.title, 'Song oldfavour01');
    expect(entry.track.url, 'https://www.youtube.com/watch?v=oldfavour01');
  });

  test('shows nothing while recommendation history is off', () async {
    final lists = container(historyEnabled: false);

    for (final kind in ListeningListKind.values) {
      expect(await ids(lists, kind), isEmpty, reason: kind.name);
    }
  });
}

class _TestLocalDatabaseService extends LocalDatabaseService {
  _TestLocalDatabaseService(this.path);

  final String path;

  @override
  Future<String> databasePath() async => path;
}

class _FixedSettingsController extends SettingsController {
  _FixedSettingsController(this.initialState);

  final SettingsState initialState;

  @override
  Future<SettingsState> build() async => initialState;
}
