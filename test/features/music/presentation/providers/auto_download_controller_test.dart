import 'dart:async';
import 'dart:io';

import 'package:bstream_music/features/music/domain/entities/catalog_playlist.dart';
import 'package:bstream_music/features/music/domain/entities/download_options.dart';
import 'package:bstream_music/features/music/domain/entities/download_result.dart';
import 'package:bstream_music/features/music/domain/entities/local_track.dart';
import 'package:bstream_music/features/music/domain/entities/playlist.dart';
import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:bstream_music/services/recommendations/recommendations.dart';
import 'package:bstream_music/services/storage/local_database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

TrackInfo _target(String videoId) => TrackInfo(
  id: videoId,
  title: 'Song $videoId',
  artist: 'Artist',
  url: 'https://www.youtube.com/watch?v=$videoId',
);

LocalTrack _local(String id, String videoId) => LocalTrack(
  id: id,
  title: 'Song $videoId',
  artist: 'Artist',
  filePath: '/music/$id.m4a',
  addedAt: DateTime.utc(2026, 10, 1),
  sourceId: videoId,
  sourceUrl: 'https://www.youtube.com/watch?v=$videoId',
);

void main() {
  group('planAutoDownloads', () {
    test('downloads missing targets and removes only dropped automatic '
        'downloads nothing holds', () {
      final plan = planAutoDownloads(
        targets: [
          _target('kept0000001'),
          _target('missing0001'),
          _target('kept0000001'),
          _target('manual00001'),
        ],
        library: [
          _local('auto-kept', 'kept0000001'),
          _local('auto-dropped', 'dropped0001'),
          _local('auto-favorite', 'favorite001'),
          _local('auto-listed', 'listed00001'),
          _local('auto-playing', 'playing0001'),
          _local('manual', 'manual00001'),
          _local('manual-dropped', 'oldmanual01'),
        ],
        autoTrackIds: {
          'auto-kept',
          'auto-dropped',
          'auto-favorite',
          'auto-listed',
          'auto-playing',
        },
        protectedLocalIds: {'auto-favorite'},
        protectedVideoIds: {'listed00001'},
        playingTrackId: 'auto-playing',
      );

      expect(plan.download.map((track) => track.id), ['missing0001']);
      expect(plan.remove.map((track) => track.id), ['auto-dropped']);
    });
  });

  group('AutoDownloadController', () {
    late Directory directory;
    late _TestLocalDatabaseService database;
    late _FakeNetwork network;
    late _RecordingDownloads downloads;
    late _RecordingDeleter deleter;
    late List<LocalTrack> library;
    Completer<void>? libraryGate;
    final now = DateTime.utc(2026, 10, 31, 12);

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('bstream-auto-dl-');
      database = _TestLocalDatabaseService(
        p.join(directory.path, 'library.db'),
      );
      network = _FakeNetwork(unmetered: true);
      downloads = _RecordingDownloads();
      library = [];
      libraryGate = null;
      var session = 0;
      for (final (videoId, plays) in [
        ('topsong0001', 3),
        ('second00001', 2),
        ('alreadyhave', 1),
      ]) {
        for (var i = 0; i < plays; i += 1) {
          session += 1;
          await database.recordPlaybackEvent(
            PlaybackEvent(
              sessionId: 'session-$session',
              trackId: videoId,
              videoId: videoId,
              title: 'Song $videoId',
              artists: const ['Artist'],
              source: PlaybackEventSource.streaming,
              startedAt: now.subtract(Duration(days: i + 1)),
              playedAt: now.subtract(Duration(days: i + 1)),
              listenedMs: 180000,
              completed: true,
            ),
          );
        }
      }
    });

    tearDown(() async {
      await network.close();
      await database.close();
      await directory.delete(recursive: true);
    });

    ProviderContainer container({bool enabled = true}) {
      deleter = _RecordingDeleter();
      final container = ProviderContainer(
        overrides: [
          databaseServiceProvider.overrideWithValue(database),
          autoDownloadNetworkProvider.overrideWithValue(network),
          autoDownloadStartDelayProvider.overrideWithValue(Duration.zero),
          listeningListClockProvider.overrideWithValue(() => now),
          settingsControllerProvider.overrideWith(
            () => _FixedSettingsController(
              SettingsState(
                downloadDirectory: directory.path,
                language: AppLanguage.english,
                autoDownloadMostPlayed: enabled,
              ),
            ),
          ),
          libraryTracksProvider.overrideWith((ref) async {
            await libraryGate?.future;
            return library;
          }),
          playlistsControllerProvider.overrideWith(_NoPlaylists.new),
          catalogPlaylistsProvider.overrideWith(
            (ref) async => const <CatalogPlaylist>[],
          ),
          downloadControllerProvider.overrideWith(() => downloads),
          libraryTrackDeleterProvider.overrideWith((ref) => deleter),
          playerControllerProvider.overrideWith(_IdlePlayer.new),
        ],
      );
      addTearDown(container.dispose);
      container.listen(autoDownloadControllerProvider, (_, _) {});
      return container;
    }

    Future<void> settle() async {
      for (var i = 0; i < 20; i += 1) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }

    test('downloads the most played missing songs and records them', () async {
      library = [_local('mine', 'alreadyhave')];
      final lists = container();
      await lists.read(settingsControllerProvider.future);
      await settle();

      expect(downloads.requested.map((track) => track.id), [
        'topsong0001',
        'second00001',
      ]);
      // The downloader saves the songs to the library as they finish.
      await _saved(database, [
        _local('new-top', 'topsong0001'),
        _local('mine-2', 'second00001'),
      ]);
      downloads.complete('topsong0001', _local('new-top', 'topsong0001'));
      downloads.complete(
        'second00001',
        _local('mine-2', 'second00001'),
        reusedExisting: true,
      );
      await settle();

      // A download that reused the listener's own file stays theirs.
      expect(await database.getAutoDownloadedTrackIds(), {'new-top'});
    });

    test('removes automatic downloads that left the list', () async {
      library = [
        _local('auto-old', 'oldfavour01'),
        _local('auto-top', 'topsong0001'),
      ];
      await _saved(database, library);
      await database.recordAutoDownload(
        localTrackId: 'auto-old',
        videoId: 'oldfavour01',
        downloadedAt: now,
      );
      await database.recordAutoDownload(
        localTrackId: 'auto-top',
        videoId: 'topsong0001',
        downloadedAt: now,
      );
      final lists = container();
      await lists.read(settingsControllerProvider.future);
      await settle();

      expect(deleter.deleted.map((track) => track.id), ['auto-old']);
      expect(await database.getAutoDownloadedTrackIds(), {'auto-top'});
    });

    test('waits for Wi-Fi and cancels when it is lost', () async {
      network.unmetered = false;
      final lists = container();
      await lists.read(settingsControllerProvider.future);
      await settle();
      expect(downloads.requested, isEmpty);

      network.set(true);
      await settle();
      expect(downloads.requested, hasLength(3));

      network.set(false);
      await settle();
      expect(downloads.cancelled, hasLength(3));
    });

    test('leaves a download the listener started to them', () async {
      library = [_local('mine', 'alreadyhave')];
      final lists = container();
      lists.read(downloadControllerProvider);
      downloads.startManual('topsong0001');
      await lists.read(settingsControllerProvider.future);
      await settle();

      expect(downloads.requested.map((track) => track.id), ['second00001']);
      await _saved(database, [_local('manual-top', 'topsong0001')]);
      downloads.complete('topsong0001', _local('manual-top', 'topsong0001'));
      await settle();
      expect(await database.getAutoDownloadedTrackIds(), isEmpty);

      network.set(false);
      await settle();
      expect(downloads.cancelled, [
        'https://www.youtube.com/watch?v=second00001',
      ]);
    });

    test('does nothing while the setting is off', () async {
      final lists = container(enabled: false);
      await lists.read(settingsControllerProvider.future);
      await settle();

      expect(downloads.requested, isEmpty);
      expect(network.listeners, 0);
    });
  });
}

Future<void> _saved(
  LocalDatabaseService database,
  List<LocalTrack> tracks,
) async {
  final db = await database.database;
  for (final track in tracks) {
    await db.insert('local_tracks', <String, Object?>{
      'id': track.id,
      'title': track.title,
      'artist': track.artist,
      'file_path': track.filePath,
      'added_at': track.addedAt.toIso8601String(),
      'source_id': track.sourceId,
      'source_url': track.sourceUrl,
    });
  }
}

class _TestLocalDatabaseService extends LocalDatabaseService {
  _TestLocalDatabaseService(this.path);

  final String path;

  @override
  Future<String> databasePath() async => path;
}

class _FakeNetwork implements AutoDownloadNetwork {
  _FakeNetwork({required this.unmetered});

  bool unmetered;
  final _changes = StreamController<bool>.broadcast(onListen: () {});
  int get listeners => _changes.hasListener ? 1 : 0;

  void set(bool value) {
    unmetered = value;
    _changes.add(value);
  }

  Future<void> close() => _changes.close();

  @override
  Future<bool> isUnmetered() async => unmetered;

  @override
  Stream<bool> get unmeteredChanges => _changes.stream;
}

class _RecordingDownloads extends DownloadController {
  final requested = <TrackInfo>[];
  final cancelled = <String>[];

  @override
  Map<String, DownloadTaskState> build() => const {};

  /// A download the listener started from a song menu.
  void startManual(String videoId) {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    state = {
      ...state,
      url: DownloadTaskState(
        url: url,
        taskId: 'manual-$videoId',
        mediaType: DownloadMediaType.audio,
        status: DownloadProgressStatus.running,
      ),
    };
  }

  @override
  Future<int> downloadTracks(
    Iterable<TrackInfo> tracks, {
    void Function(DownloadTaskState task)? onQueued,
  }) async {
    for (final track in tracks) {
      // Like the real controller, a running download is not queued again.
      if (state[track.url]?.isCancellable == true) continue;
      requested.add(track);
      state = {
        ...state,
        track.url: DownloadTaskState(
          url: track.url,
          taskId: track.id,
          mediaType: DownloadMediaType.audio,
          status: DownloadProgressStatus.queued,
        ),
      };
      onQueued?.call(state[track.url]!);
    }
    return tracks.length;
  }

  void complete(
    String videoId,
    LocalTrack local, {
    bool reusedExisting = false,
  }) {
    final url = 'https://www.youtube.com/watch?v=$videoId';
    state = {
      ...state,
      url: state[url]!.copyWith(
        status: DownloadProgressStatus.completed,
        localTrack: local,
        reusedExisting: reusedExisting,
      ),
    };
  }

  @override
  Future<bool> cancelDownload(String url) async {
    cancelled.add(url);
    return true;
  }
}

class _RecordingDeleter implements LibraryTrackDeleter {
  final deleted = <LocalTrack>[];

  @override
  Future<int> delete(Iterable<LocalTrack> requestedTracks) async {
    deleted.addAll(requestedTracks);
    return requestedTracks.length;
  }
}

class _NoPlaylists extends PlaylistsController {
  @override
  Future<List<Playlist>> build() async => const <Playlist>[];
}

class _IdlePlayer extends PlayerController {
  @override
  Future<PlayerSnapshot> build() async =>
      const PlayerSnapshot(status: PlayerStatus.idle);
}

class _FixedSettingsController extends SettingsController {
  _FixedSettingsController(this.initialState);

  final SettingsState initialState;

  @override
  Future<SettingsState> build() async => initialState;

  void setAutoDownload(bool enabled) {
    state = AsyncData(
      state.requireValue.copyWith(autoDownloadMostPlayed: enabled),
    );
  }
}
