import 'dart:io';

import 'package:bstream_music/features/music/domain/entities/playlist.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:bstream_music/services/storage/backup_service.dart';
import 'package:bstream_music/services/storage/library_operation_coordinator.dart';
import 'package:bstream_music/services/storage/local_database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('restoring a backup shows the restored playlists', () async {
    final directory = await Directory.systemTemp.createTemp(
      'bstream-settings-restore-',
    );
    final database = _TestLocalDatabaseService(
      p.join(directory.path, 'library.db'),
    );
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });
    await database.savePlaylist(_playlist('Before restore'));

    final container = ProviderContainer(
      overrides: [
        databaseServiceProvider.overrideWithValue(database),
        backupServiceProvider.overrideWithValue(
          _RestoringBackupService(database),
        ),
        playerControllerProvider.overrideWith(_IdlePlayerController.new),
        settingsControllerProvider.overrideWith(
          () => _FixedSettingsController(
            SettingsState(
              downloadDirectory: directory.path,
              language: AppLanguage.spanish,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    // The library keeps both providers alive while it is on screen.
    final listSubscription = container.listen(
      catalogPlaylistsProvider,
      (_, _) {},
    );
    final detailSubscription = container.listen(
      catalogPlaylistProvider('playlist-1'),
      (_, _) {},
    );
    addTearDown(listSubscription.close);
    addTearDown(detailSubscription.close);
    expect(
      (await container.read(
        catalogPlaylistsProvider.future,
      )).single.playlist.name,
      'Before restore',
    );
    expect(
      (await container.read(
        catalogPlaylistProvider('playlist-1').future,
      ))?.playlist.name,
      'Before restore',
    );

    await container
        .read(settingsControllerProvider.notifier)
        .restoreBackupFile('backup.zip');

    expect(
      (await container.read(
        catalogPlaylistsProvider.future,
      )).single.playlist.name,
      'From backup',
    );
    expect(
      (await container.read(
        catalogPlaylistProvider('playlist-1').future,
      ))?.playlist.name,
      'From backup',
    );
  });
}

Playlist _playlist(String name) => Playlist(
  id: 'playlist-1',
  name: name,
  trackIds: const [],
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

class _TestLocalDatabaseService extends LocalDatabaseService {
  _TestLocalDatabaseService(this.path);

  final String path;

  @override
  Future<String> databasePath() async => path;
}

/// Stands in for unpacking an archive: the database afterwards holds the
/// backup's playlists.
class _RestoringBackupService extends BackupService {
  _RestoringBackupService(this._database)
    : super(_database, LibraryOperationCoordinator());

  final LocalDatabaseService _database;

  @override
  Future<void> restoreBackupFile({
    required String backupPath,
    required String mediaRoot,
  }) => _database.savePlaylist(_playlist('From backup'));
}

class _IdlePlayerController extends PlayerController {
  @override
  Future<PlayerSnapshot> build() async =>
      const PlayerSnapshot(status: PlayerStatus.idle);

  @override
  Future<void> suspendRecommendationHistoryTracking() async {}

  @override
  Future<void> resumeRecommendationHistoryTracking() async {}
}

class _FixedSettingsController extends SettingsController {
  _FixedSettingsController(this.initialState);

  final SettingsState initialState;

  @override
  Future<SettingsState> build() async => initialState;
}
