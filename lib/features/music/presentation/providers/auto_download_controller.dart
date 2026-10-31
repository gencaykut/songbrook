part of 'music_providers.dart';

/// Songs kept downloaded automatically: the most played of this window.
const autoDownloadSongCount = 50;
const autoDownloadWindow = Duration(days: 90);

/// Whether the device is on a network without mobile data costs.
abstract interface class AutoDownloadNetwork {
  Future<bool> isUnmetered();

  /// Emits whenever that answer changes.
  Stream<bool> get unmeteredChanges;
}

class ConnectivityAutoDownloadNetwork implements AutoDownloadNetwork {
  ConnectivityAutoDownloadNetwork([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> isUnmetered() async =>
      isUnmeteredConnection(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get unmeteredChanges =>
      _connectivity.onConnectivityChanged.map(isUnmeteredConnection).distinct();
}

final autoDownloadNetworkProvider = Provider<AutoDownloadNetwork>(
  (ref) => ConnectivityAutoDownloadNetwork(),
);

/// Waited after launch before the first check, so it does not compete with
/// Home and the first song.
final autoDownloadStartDelayProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 30),
);

/// Library ids of the songs Songbrook downloaded by itself, for marking them.
final autoDownloadedTrackIdsProvider = FutureProvider<Set<String>>((ref) {
  ref.watch(libraryTracksProvider);
  return ref.watch(databaseServiceProvider).getAutoDownloadedTrackIds();
});

/// What one automatic download pass does.
class AutoDownloadPlan {
  const AutoDownloadPlan({required this.download, required this.remove});

  final List<TrackInfo> download;
  final List<LocalTrack> remove;
}

/// Downloads the [targets] (most played first) missing from the [library],
/// and removes automatic downloads ([autoTrackIds]) that are no longer
/// targets, unless a playlist or favorites holds them ([protectedLocalIds],
/// [protectedVideoIds]) or they are playing ([playingTrackId]). Songs the
/// listener downloaded are never removed.
AutoDownloadPlan planAutoDownloads({
  required List<TrackInfo> targets,
  required List<LocalTrack> library,
  required Set<String> autoTrackIds,
  required Set<String> protectedLocalIds,
  required Set<String> protectedVideoIds,
  String? playingTrackId,
}) {
  final libraryVideoIds = {
    for (final track in library) ?localTrackVideoId(track),
  };
  final targetVideoIds = <String>{};
  final download = <TrackInfo>[];
  for (final target in targets) {
    final videoId = const BStreamTrackLinkCodec().tryFromTrack(target)?.videoId;
    if (videoId == null || !targetVideoIds.add(videoId)) continue;
    if (!libraryVideoIds.contains(videoId)) download.add(target);
  }
  final remove = [
    for (final track in library)
      if (autoTrackIds.contains(track.id) &&
          !targetVideoIds.contains(localTrackVideoId(track)) &&
          !protectedLocalIds.contains(track.id) &&
          !protectedVideoIds.contains(localTrackVideoId(track)) &&
          track.id != playingTrackId)
        track,
  ];
  return AutoDownloadPlan(
    download: List.unmodifiable(download),
    remove: List.unmodifiable(remove),
  );
}

/// The YouTube video a downloaded song came from, when it came from one.
String? localTrackVideoId(LocalTrack track) => const BStreamTrackLinkCodec()
    .tryFromTrack(
      TrackInfo(
        id: track.sourceId ?? '',
        title: track.title,
        artist: track.artist,
        url: track.sourceUrl ?? '',
      ),
    )
    ?.videoId;

final autoDownloadControllerProvider =
    NotifierProvider<AutoDownloadController, void>(AutoDownloadController.new);

/// Keeps the most played songs downloaded while
/// [SettingsState.autoDownloadMostPlayed] is on: once per launch (after
/// [autoDownloadStartDelayProvider]), at once when the setting is turned on,
/// and when Wi-Fi returns after a pass waited for it. Downloads still queued
/// when Wi-Fi is lost or the setting is turned off are cancelled, and a pass
/// still reading the library then stops before changing it.
class AutoDownloadController extends Notifier<void> {
  /// Tasks this controller created, by task id, until they finish. Songs
  /// the listener was already downloading are not among them.
  final _requested = <String, ({String url, String videoId})>{};
  bool _ranThisLaunch = false;
  bool _waitingForWifi = false;
  Future<void>? _running;

  /// Bumped when Wi-Fi is lost or the setting is turned off, so a pass still
  /// reading the library stops before it deletes or downloads anything.
  int _generation = 0;
  int? _runningGeneration;

  /// Whether the setting was seen off in this launch: turning it on then
  /// starts a pass at once instead of after the launch delay.
  bool _seenDisabled = false;

  @override
  void build() {
    final enabled = ref.watch(
      settingsControllerProvider.select(
        (settings) => settings.value?.autoDownloadMostPlayed,
      ),
    );
    if (enabled != true) {
      // Nothing runs, waits or listens while the setting is off.
      if (enabled == false) _seenDisabled = true;
      _generation += 1;
      _cancelRequested();
      return;
    }

    final network = ref.watch(autoDownloadNetworkProvider);
    final turnedOn = _seenDisabled;
    final start = Timer(
      turnedOn ? Duration.zero : ref.read(autoDownloadStartDelayProvider),
      () {
        if (ref.mounted) unawaited(run(force: turnedOn));
      },
    );
    ref.onDispose(start.cancel);

    final changes = network.unmeteredChanges.listen((unmetered) {
      if (!ref.mounted) return;
      if (!unmetered) {
        // A pass dropped before it asked for downloads starts over too.
        if (_running != null) _waitingForWifi = true;
        _generation += 1;
        _cancelRequested();
      } else if (_waitingForWifi) {
        unawaited(run(force: true));
      }
    }, onError: (Object _) {});
    ref.onDispose(changes.cancel);

    ref.listen<Map<String, DownloadTaskState>>(
      downloadControllerProvider,
      (_, tasks) => _recordFinished(tasks),
    );
  }

  /// One pass. Without [force] it runs at most once per launch.
  Future<void> run({bool force = false}) {
    final running = _running;
    // A pass dropped by Wi-Fi loss or the setting is ending on its own.
    if (running != null && _runningGeneration == _generation) return running;
    if (_ranThisLaunch && !force) return Future<void>.value();
    final generation = _generation;
    late final Future<void> pass;
    pass = _run(generation).whenComplete(() {
      if (identical(_running, pass)) _running = null;
    });
    _running = pass;
    _runningGeneration = generation;
    return pass;
  }

  /// Whether the pass started in [generation] may still change the library.
  Future<bool> _stillWanted(int generation) async {
    if (!ref.mounted || generation != _generation) return false;
    if (ref.read(settingsControllerProvider).value?.autoDownloadMostPlayed !=
        true) {
      return false;
    }
    final unmetered = await ref.read(autoDownloadNetworkProvider).isUnmetered();
    if (!ref.mounted || generation != _generation) return false;
    if (!unmetered) _waitingForWifi = true;
    return unmetered;
  }

  Future<void> _run(int generation) async {
    final settings = await ref.read(settingsControllerProvider.future);
    if (!ref.mounted ||
        generation != _generation ||
        !settings.autoDownloadMostPlayed ||
        !settings.recommendationHistoryEnabled) {
      return;
    }
    if (!await ref.read(autoDownloadNetworkProvider).isUnmetered()) {
      if (ref.mounted && generation == _generation) _waitingForWifi = true;
      return;
    }
    _waitingForWifi = false;
    _ranThisLaunch = true;
    try {
      final database = ref.read(databaseServiceProvider);
      final strings = ref.read(appStringsProvider);
      final now = ref.read(listeningListClockProvider)().toUtc();
      final seeds = await ref
          .read(libraryOperationCoordinatorProvider)
          .runWithGate(
            () => database.getMostPlayedTracks(
              limit: autoDownloadSongCount,
              since: now.subtract(autoDownloadWindow),
            ),
          );
      final targets = [
        for (final seed in seeds)
          if (seed.canQueryYouTube)
            ?_homeTrackItemFromPersonalized(
              PersonalizedTrackItem.fromSeed(seed),
              strings,
            )?.track,
      ];
      final library = await ref.read(libraryTracksProvider.future);
      final playlists = await ref.read(playlistsControllerProvider.future);
      final catalogs = await ref.read(catalogPlaylistsProvider.future);
      if (!ref.mounted) return;
      final protectedLocalIds = <String>{
        for (final playlist in playlists) ...playlist.trackIds,
        for (final catalog in catalogs)
          for (final entry in catalog.entries) ?entry.localTrackId,
      };
      final protectedVideoIds = <String>{
        for (final catalog in catalogs)
          for (final entry in catalog.entries) ?entry.remoteVideoId,
      };
      final plan = planAutoDownloads(
        targets: targets,
        library: library,
        autoTrackIds: await database.getAutoDownloadedTrackIds(),
        protectedLocalIds: protectedLocalIds,
        protectedVideoIds: protectedVideoIds,
        playingTrackId: ref.read(playerControllerProvider).value?.trackId,
      );
      if (!await _stillWanted(generation)) return;

      if (plan.remove.isNotEmpty) {
        await ref.read(libraryTrackDeleterProvider).delete(plan.remove);
        await database.forgetAutoDownloads(
          plan.remove.map((track) => track.id),
        );
      }
      if (!await _stillWanted(generation)) return;
      if (plan.download.isNotEmpty) {
        await ref
            .read(downloadControllerProvider.notifier)
            .downloadTracks(
              plan.download,
              onQueued: (task) {
                final videoId = const BStreamTrackLinkCodec()
                    .tryFromTrack(
                      TrackInfo(id: '', title: '', artist: '', url: task.url),
                    )
                    ?.videoId;
                if (videoId != null) {
                  _requested[task.taskId] = (url: task.url, videoId: videoId);
                }
              },
            );
        // A task may have finished before the call returned.
        if (ref.mounted) _recordFinished(ref.read(downloadControllerProvider));
      }
      if (ref.mounted) ref.invalidate(autoDownloadedTrackIdsProvider);
    } catch (error, stackTrace) {
      // Optional: the next launch or Wi-Fi connection tries again.
      debugPrint('Automatic downloads failed: $error\n$stackTrace');
    }
  }

  void _recordFinished(Map<String, DownloadTaskState> tasks) {
    for (final MapEntry(key: taskId, value: request)
        in _requested.entries.toList()) {
      final task = tasks[request.url];
      // Cancelled, or replaced by a download the listener started.
      if (task == null || task.taskId != taskId) {
        _requested.remove(taskId);
        continue;
      }
      if (task.status == DownloadProgressStatus.failed) {
        _requested.remove(taskId);
        continue;
      }
      final local = task.localTrack;
      if (task.status != DownloadProgressStatus.completed || local == null) {
        continue;
      }
      _requested.remove(taskId);
      final videoId = request.videoId;
      // A song the listener already had stays theirs.
      if (task.reusedExisting) continue;
      unawaited(() async {
        try {
          await ref
              .read(databaseServiceProvider)
              .recordAutoDownload(
                localTrackId: local.id,
                videoId: videoId,
                downloadedAt: ref.read(listeningListClockProvider)(),
              );
          if (ref.mounted) ref.invalidate(autoDownloadedTrackIdsProvider);
        } catch (error) {
          debugPrint('Automatic download not recorded: $error');
        }
      }());
    }
  }

  void _cancelRequested() {
    if (_requested.isEmpty) return;
    final downloads = ref.read(downloadControllerProvider.notifier);
    final tasks = ref.read(downloadControllerProvider);
    for (final MapEntry(key: taskId, value: request) in _requested.entries) {
      if (tasks[request.url]?.taskId == taskId) {
        unawaited(downloads.cancelDownload(request.url));
      }
    }
    _requested.clear();
    // The pass resumes on the next Wi-Fi connection.
    _waitingForWifi = true;
  }
}
