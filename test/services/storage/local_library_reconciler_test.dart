import 'dart:async';
import 'dart:io';

import 'package:bstream_music/features/music/data/datasources/local_music_datasource.dart';
import 'package:bstream_music/features/music/data/repositories/library_repository_impl.dart';
import 'package:bstream_music/features/music/domain/entities/local_track.dart';
import 'package:bstream_music/features/music/domain/entities/playlist.dart';
import 'package:bstream_music/features/music/domain/repositories/library_repository.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/storage/local_database_service.dart';
import 'package:bstream_music/services/storage/local_library_reconciler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'removes missing rows, history, playlist and favorite references atomically',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bstream-library-reconciliation-',
      );
      final databaseService = _TestLocalDatabaseService(
        p.join(directory.path, 'library.db'),
      );
      addTearDown(() async {
        await databaseService.close();
        await directory.delete(recursive: true);
      });
      final repository = LibraryRepositoryImpl(
        LocalMusicDataSource(databaseService),
      );
      final existingFile = File(p.join(directory.path, 'existing.m4a'));
      await existingFile.writeAsBytes(const [1, 2, 3]);
      final tracks = [
        _track('existing', existingFile.path, played: true),
        _track(
          'missing-1',
          p.join(directory.path, 'missing-1.opus'),
          played: true,
        ),
        _track('missing-2', p.join(directory.path, 'missing-2.m4a')),
      ];
      for (final track in tracks) {
        await repository.saveLocalTrack(track);
      }
      final playlistUpdatedAt = DateTime.utc(2026, 8, 4, 12);
      await repository.savePlaylist(
        Playlist(
          id: 'playlist-1',
          name: 'Playlist',
          trackIds: const ['missing-1', 'existing', 'missing-2'],
          createdAt: DateTime.utc(2026),
          updatedAt: playlistUpdatedAt,
        ),
      );
      await repository.savePlaylist(
        Playlist(
          id: Playlist.favoritesId,
          name: 'Favorites',
          trackIds: const ['missing-2', 'existing'],
          createdAt: DateTime.utc(2026),
          updatedAt: playlistUpdatedAt,
        ),
      );

      final reconciler = LocalLibraryReconciler(
        repository,
        probeLocalTrackFile,
      );
      final result = await reconciler.reconcile();

      expect(result.checkedTrackCount, 3);
      expect(result.missingTrackIds, {'missing-1', 'missing-2'});
      expect(result.removedTrackIds, {'missing-1', 'missing-2'});
      expect((await repository.getLocalTracks()).map((track) => track.id), [
        'existing',
      ]);
      expect((await repository.getHistory()).map((track) => track.id), [
        'existing',
      ]);
      final playlists = await repository.getPlaylists();
      expect(
        playlists
            .singleWhere((playlist) => playlist.id == 'playlist-1')
            .trackIds,
        ['existing'],
      );
      expect(
        playlists.singleWhere((playlist) => playlist.isFavorites).trackIds,
        ['existing'],
      );
      expect(
        playlists.every((playlist) => playlist.updatedAt == playlistUpdatedAt),
        isTrue,
      );

      final secondResult = await reconciler.reconcile();
      expect(secondResult.checkedTrackCount, 1);
      expect(secondResult.removedTrackIds, isEmpty);
    },
  );

  group('probeLocalTrackFile', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('bstream-file-probe-');
    });

    tearDown(() async {
      if (!Platform.isWindows) {
        await Process.run('chmod', ['-R', 'u+rwx', directory.path]);
      }
      await directory.delete(recursive: true);
    });

    test('reports a file it can see as present', () async {
      final file = File(p.join(directory.path, 'song.m4a'));
      await file.writeAsBytes(const [1]);

      expect(
        await probeLocalTrackFile(file.path),
        LocalTrackFileAvailability.present,
      );
    });

    test('reports a file absent from a readable folder as missing', () async {
      expect(
        await probeLocalTrackFile(p.join(directory.path, 'deleted.m4a')),
        LocalTrackFileAvailability.missing,
      );
    });

    test(
      'reports a file in a folder it may not read as inaccessible',
      () async {
        final locked = Directory(p.join(directory.path, 'locked'));
        await locked.create();
        final file = File(p.join(locked.path, 'song.m4a'));
        await file.writeAsBytes(const [1]);
        await Process.run('chmod', ['000', locked.path]);

        expect(
          await probeLocalTrackFile(file.path),
          LocalTrackFileAvailability.inaccessible,
        );
      },
      // POSIX permissions only; root reads through them.
      skip: Platform.isWindows,
    );

    test('reports a file whose folder is gone, like an unmounted drive, as '
        'inaccessible', () async {
      expect(
        await probeLocalTrackFile(
          p.join(directory.path, 'Volumes', 'Music', 'song.m4a'),
        ),
        LocalTrackFileAvailability.inaccessible,
      );
    });
  });

  test('keeps a track whose folder may not be read', () async {
    final directory = await Directory.systemTemp.createTemp(
      'bstream-library-locked-',
    );
    final databaseService = _TestLocalDatabaseService(
      p.join(directory.path, 'library.db'),
    );
    final locked = Directory(p.join(directory.path, 'locked'));
    addTearDown(() async {
      await Process.run('chmod', ['-R', 'u+rwx', locked.path]);
      await databaseService.close();
      await directory.delete(recursive: true);
    });
    final repository = LibraryRepositoryImpl(
      LocalMusicDataSource(databaseService),
    );
    await locked.create();
    final file = File(p.join(locked.path, 'song.m4a'));
    await file.writeAsBytes(const [1, 2, 3]);
    await repository.saveLocalTrack(_track('locked', file.path, played: true));
    await Process.run('chmod', ['000', locked.path]);

    final result = await LocalLibraryReconciler(
      repository,
      probeLocalTrackFile,
    ).reconcile();

    expect(result.inaccessibleTrackIds, {'locked'});
    expect(result.removedTrackIds, isEmpty);
    expect((await repository.getLocalTracks()).map((track) => track.id), [
      'locked',
    ]);
    expect((await repository.getHistory()).map((track) => track.id), [
      'locked',
    ]);
  }, skip: Platform.isWindows);

  test('keeps a track when the filesystem check is inaccessible', () async {
    final track = _track('protected', 'protected.m4a');
    final repository = _FakeLibraryRepository(track);
    final reconciler = LocalLibraryReconciler(
      repository,
      (_) => throw const FileSystemException('Access denied'),
    );

    final result = await reconciler.reconcile();

    expect(result.inaccessibleTrackIds, {'protected'});
    expect(result.missingTrackIds, isEmpty);
    expect(repository.purgeCalls, 0);
    expect(repository.track, same(track));
  });

  test(
    'startup reconciliation waits for settings and runs once per session',
    () async {
      final settingsReady = Completer<SettingsState>();
      final repository = _FakeLibraryRepository();
      final container = ProviderContainer(
        overrides: [
          settingsControllerProvider.overrideWith(
            () => _DeferredSettingsController(settingsReady.future),
          ),
          libraryRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final firstRun = container.read(
        localLibraryReconciliationProvider.future,
      );
      await Future<void>.delayed(Duration.zero);
      expect(repository.getLocalTracksCalls, 0);

      settingsReady.complete(
        const SettingsState(
          downloadDirectory: 'test-media',
          language: AppLanguage.spanish,
        ),
      );
      await firstRun;
      expect(repository.getLocalTracksCalls, 1);

      await container.read(localLibraryReconciliationProvider.future);
      expect(repository.getLocalTracksCalls, 1);
    },
  );
}

LocalTrack _track(String id, String filePath, {bool played = false}) {
  return LocalTrack(
    id: id,
    title: id,
    artist: 'BStream Music',
    filePath: filePath,
    addedAt: DateTime.utc(2026),
    lastPlayedAt: played ? DateTime.utc(2026, 8, 4) : null,
  );
}

class _TestLocalDatabaseService extends LocalDatabaseService {
  _TestLocalDatabaseService(this.path);

  final String path;

  @override
  Future<String> databasePath() async => path;
}

class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository([this.track]);

  LocalTrack? track;
  int purgeCalls = 0;
  int getLocalTracksCalls = 0;

  @override
  Future<List<LocalTrack>> getLocalTracks() async {
    getLocalTracksCalls++;
    return [?track];
  }

  @override
  Future<Set<String>> purgeMissingLocalTracks(List<LocalTrack> tracks) async {
    purgeCalls++;
    track = null;
    return tracks.map((track) => track.id).toSet();
  }

  @override
  Future<void> deleteLocalTrack(String trackId) async {}

  @override
  Future<void> deletePlaylist(String playlistId) async {}

  @override
  Future<List<LocalTrack>> getHistory() async => const [];

  @override
  Future<List<Playlist>> getPlaylists() async => const [];

  @override
  Future<void> markPlayed(
    String trackId,
    DateTime playedAt, {
    String? playlistId,
  }) async {}

  @override
  Future<void> saveLocalTrack(LocalTrack track) async {}

  @override
  Future<void> savePlaylist(Playlist playlist) async {}
}

class _DeferredSettingsController extends SettingsController {
  _DeferredSettingsController(this.result);

  final Future<SettingsState> result;

  @override
  Future<SettingsState> build() => result;
}
