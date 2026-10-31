import 'dart:io';

import 'package:bstream_music/features/music/data/datasources/local_music_datasource.dart';
import 'package:bstream_music/features/music/data/repositories/library_repository_impl.dart';
import 'package:bstream_music/features/music/domain/entities/local_track.dart';
import 'package:bstream_music/services/storage/local_database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('automatic downloads are remembered while they stay', () async {
    final directory = await Directory.systemTemp.createTemp(
      'bstream-auto-downloads-',
    );
    final database = _TestLocalDatabaseService(
      p.join(directory.path, 'library.db'),
    );
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });
    final repository = LibraryRepositoryImpl(LocalMusicDataSource(database));
    for (final id in ['auto-1', 'auto-2', 'manual']) {
      await repository.saveLocalTrack(
        LocalTrack(
          id: id,
          title: id,
          artist: 'Artist',
          filePath: p.join(directory.path, '$id.m4a'),
          addedAt: DateTime.utc(2026, 10, 31),
        ),
      );
    }
    final at = DateTime.utc(2026, 10, 31, 12);
    await database.recordAutoDownload(
      localTrackId: 'auto-1',
      videoId: 'video000001',
      downloadedAt: at,
    );
    await database.recordAutoDownload(
      localTrackId: 'auto-2',
      videoId: 'video000002',
      downloadedAt: at,
    );
    expect(await database.getAutoDownloadedTrackIds(), {'auto-1', 'auto-2'});

    // A download the listener deleted is no longer automatic.
    await repository.deleteLocalTrack('auto-2');
    expect(await database.getAutoDownloadedTrackIds(), {'auto-1'});

    await database.forgetAutoDownloads(['auto-1']);
    expect(await database.getAutoDownloadedTrackIds(), isEmpty);
    expect((await repository.getLocalTracks()).map((track) => track.id), [
      'auto-1',
      'manual',
    ]);
  });
}

class _TestLocalDatabaseService extends LocalDatabaseService {
  _TestLocalDatabaseService(this.path);

  final String path;

  @override
  Future<String> databasePath() async => path;
}
