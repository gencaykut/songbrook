import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/connect/connect_models.dart';
import '../../../../services/player/player_service.dart';
import '../../domain/entities/track_info.dart';
import 'music_providers.dart';

/// This device's player as Songbrook Connect drives it: what it publishes
/// while it plays, the commands it runs for the other devices and the
/// handoff steps (prepare without playing, restore when a handoff is
/// cancelled, pause when another device takes over).
abstract interface class ConnectPlayback {
  Set<String> get supportedCommands;

  ConnectPlaybackSnapshot snapshot();

  /// Loads [snapshot] paused (a handoff being prepared here) or puts back a
  /// snapshot this device published itself (a handoff that was cancelled).
  Future<void> apply(ConnectPlaybackSnapshot snapshot);

  Future<void> handleCommand(String command, Map<String, dynamic> arguments);

  Future<void> pauseForTransfer();

  /// Something worth publishing changed.
  Stream<ConnectPlaybackChange> get changes;
}

@immutable
class ConnectPlaybackChange {
  const ConnectPlaybackChange({this.started = false, this.stopped = false});

  /// Playback has just started (the user pressed play or picked a song).
  final bool started;

  /// Playback has just been paused or stopped.
  final bool stopped;
}

final connectPlaybackProvider = Provider<ConnectPlayback>((ref) {
  final playback = PlayerConnectPlayback(ref);
  ref.onDispose(playback.dispose);
  return playback;
});

/// The commands Songbrook's player runs for another device. Queue editing
/// from a remote (remove, insert, clear) is not offered yet.
const kConnectPlayerCommands = <String>{
  ConnectCommand.play,
  ConnectCommand.pause,
  ConnectCommand.toggle,
  ConnectCommand.next,
  ConnectCommand.previous,
  ConnectCommand.seek,
  ConnectCommand.setVolume,
  ConnectCommand.toggleShuffle,
  ConnectCommand.cycleRepeat,
  ConnectCommand.playQueueIndex,
  ConnectCommand.playContext,
};

/// A queue entry another device cannot stream: a file only this one has.
const _localOnlyField = 'localOnly';

/// Connect queue entry for [track]: the YouTube video and what a mirror
/// shows. Values are trimmed to the protocol's limits so one long title
/// cannot get a whole queue rejected.
Map<String, dynamic> connectTrackJson(TrackInfo track, {bool portable = true}) {
  String? bounded(String? value, int maximum) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.length <= maximum ? trimmed : trimmed.substring(0, maximum);
  }

  final url = bounded(track.url, kMaxConnectTrackStringLength);
  final thumbnail = track.thumbnailUrl?.trim();
  final durationMs = track.duration?.inMilliseconds;
  return Map<String, dynamic>.unmodifiable(<String, dynamic>{
    'id': bounded(track.id.isEmpty ? track.url : track.id, 64) ?? '-',
    'title': bounded(track.title, 512) ?? '',
    'artist': bounded(track.artist, 512) ?? '',
    'album': ?bounded(track.album, 512),
    if (thumbnail != null &&
        thumbnail.isNotEmpty &&
        thumbnail.length <= kMaxConnectTrackStringLength)
      'thumbnail': thumbnail,
    if (durationMs != null && durationMs > 0) 'durationMs': durationMs,
    if (portable && url != null) 'url': url,
    if (!portable) _localOnlyField: true,
  });
}

/// The track a Connect queue entry names, or null for an entry this device
/// cannot stream.
TrackInfo? trackFromConnectJson(Map<String, dynamic> json) {
  if (json[_localOnlyField] == true) return null;
  final id = (json['id'] as String? ?? '').trim();
  if (id.isEmpty) return null;
  final url = (json['url'] as String?)?.trim();
  final durationMs = (json['durationMs'] as num?)?.toInt();
  final album = (json['album'] as String?)?.trim();
  final thumbnail = (json['thumbnail'] as String?)?.trim();
  return TrackInfo(
    id: id,
    title: json['title'] as String? ?? '',
    artist: json['artist'] as String? ?? '',
    album: album == null || album.isEmpty ? null : album,
    thumbnailUrl: thumbnail == null || thumbnail.isEmpty ? null : thumbnail,
    catalogThumbnailUrl: thumbnail == null || thumbnail.isEmpty
        ? null
        : thumbnail,
    duration: durationMs == null || durationMs <= 0
        ? null
        : Duration(milliseconds: durationMs),
    url: url == null || url.isEmpty
        ? 'https://www.youtube.com/watch?v=$id'
        : url,
  );
}

/// The streamable part of [snapshot]'s queue, and where its current entry
/// lands in it. Throws when the current entry is a file this device lacks.
({List<TrackInfo> tracks, int index}) connectPlayableQueue(
  ConnectPlaybackSnapshot snapshot,
) {
  final tracks = <TrackInfo>[];
  var index = -1;
  for (var position = 0; position < snapshot.queue.length; position++) {
    final track = trackFromConnectJson(snapshot.queue[position]);
    if (position == snapshot.currentIndex) {
      if (track == null) {
        throw StateError(
          'The current song is a file on the other device only.',
        );
      }
      index = tracks.length;
    }
    if (track != null) tracks.add(track);
  }
  if (tracks.isEmpty || index < 0) {
    throw StateError('Nothing in that queue can be played here.');
  }
  return (tracks: tracks, index: index);
}

PlaybackRepeatMode connectRepeatMode(String value) => switch (value) {
  'all' => PlaybackRepeatMode.all,
  'one' => PlaybackRepeatMode.one,
  _ => PlaybackRepeatMode.off,
};

String connectRepeatModeName(PlaybackRepeatMode mode) => switch (mode) {
  PlaybackRepeatMode.off => 'off',
  PlaybackRepeatMode.all => 'all',
  PlaybackRepeatMode.one => 'one',
};

/// [ConnectPlayback] over [PlayerController].
class PlayerConnectPlayback implements ConnectPlayback {
  PlayerConnectPlayback(this._ref) {
    _ref.listen<AsyncValue<PlayerSnapshot>>(playerControllerProvider, (
      previous,
      next,
    ) {
      final before = previous?.value;
      final after = next.value;
      if (after == null) return;
      final wasPlaying = before?.wantsToPlay ?? false;
      _emit(
        ConnectPlaybackChange(
          started: !wasPlaying && after.wantsToPlay,
          stopped: wasPlaying && !after.wantsToPlay,
        ),
      );
    });
    _ref.listen<PlaybackQueueState>(
      playbackQueueProvider,
      (_, _) => _emit(const ConnectPlaybackChange()),
    );
  }

  final Ref _ref;
  final _changes = StreamController<ConnectPlaybackChange>.broadcast();

  /// Restore points for the snapshots this device published: a cancelled
  /// handoff gives one back, and it is put back exactly, local files and
  /// all, instead of being rebuilt from the published queue.
  final _restorePoints = Expando<Object>('connectRestorePoint');

  List<ConnectQueueTrack>? _encodedFrom;
  List<Map<String, dynamic>> _encodedQueue = const [];
  List<int> _identityOrder = const [];

  PlayerController get _controller =>
      _ref.read(playerControllerProvider.notifier);

  @override
  Set<String> get supportedCommands => kConnectPlayerCommands;

  @override
  Stream<ConnectPlaybackChange> get changes => _changes.stream;

  void _emit(ConnectPlaybackChange change) {
    if (!_changes.isClosed) _changes.add(change);
  }

  void dispose() => unawaited(_changes.close());

  @override
  ConnectPlaybackSnapshot snapshot() {
    final controller = _controller;
    final player = _ref.read(playerControllerProvider).value;
    final queue = controller.connectQueue;
    if (!identical(queue, _encodedFrom)) {
      _encodedFrom = queue;
      _encodedQueue = List<Map<String, dynamic>>.unmodifiable(
        queue.map(
          (entry) => connectTrackJson(entry.track, portable: entry.portable),
        ),
      );
      _identityOrder = List<int>.unmodifiable(
        List<int>.generate(queue.length, (index) => index),
      );
    }
    final index = controller.connectQueueIndex;
    final snapshot = ConnectPlaybackSnapshot.fromValidatedQueue(
      queue: _encodedQueue,
      // Shuffle picks the next entry without reordering the queue.
      backingOrder: _identityOrder,
      currentIndex: _encodedQueue.isEmpty
          ? -1
          : index.clamp(0, _encodedQueue.length - 1),
      positionMs: (player?.position.inMilliseconds ?? 0).clamp(0, 86400000),
      durationMs: (player?.duration?.inMilliseconds ?? 0).clamp(0, 86400000),
      isPlaying: player?.wantsToPlay ?? false,
      shuffle: controller.connectShuffleEnabled,
      repeatMode: connectRepeatModeName(controller.connectRepeatMode),
      volume: (player?.volume ?? 1).clamp(0.0, 1.0),
      updatedAt: DateTime.now().toUtc(),
    );
    _restorePoints[snapshot] = controller.connectRestorePoint();
    return snapshot;
  }

  @override
  Future<void> apply(ConnectPlaybackSnapshot snapshot) async {
    final controller = _controller;
    final restorePoint = _restorePoints[snapshot];
    if (restorePoint != null) {
      await controller.restoreConnectPoint(restorePoint);
      return;
    }
    final playable = connectPlayableQueue(snapshot);
    controller
      ..setShuffleEnabled(snapshot.shuffle)
      ..setRepeatMode(connectRepeatMode(snapshot.repeatMode));
    final current = await controller.prepareRemoteQueue(
      playable.tracks,
      playable.index,
      position: Duration(milliseconds: snapshot.positionMs),
    );
    if (current && snapshot.isPlaying) _start(controller.resume);
  }

  @override
  Future<void> handleCommand(
    String command,
    Map<String, dynamic> arguments,
  ) async {
    final controller = _controller;
    switch (command) {
      case ConnectCommand.play:
        _start(controller.resume);
      case ConnectCommand.pause:
        await controller.pause();
      case ConnectCommand.toggle:
        final player = _ref.read(playerControllerProvider).value;
        if (player?.wantsToPlay ?? false) {
          await controller.pause();
        } else {
          _start(controller.resume);
        }
      case ConnectCommand.next:
        _start(controller.playNext);
      case ConnectCommand.previous:
        _start(controller.playPrevious);
      case ConnectCommand.seek:
        await controller.seek(
          Duration(milliseconds: arguments['positionMs'] as int),
        );
      case ConnectCommand.setVolume:
        await controller.setVolume((arguments['volume'] as num).toDouble());
      case ConnectCommand.toggleShuffle:
        controller.toggleShuffle();
      case ConnectCommand.cycleRepeat:
        controller.cycleRepeatMode();
      case ConnectCommand.playQueueIndex:
        final index = arguments['index'] as int;
        if (index >= controller.connectQueue.length) {
          throw RangeError.index(index, controller.connectQueue, 'index');
        }
        if (index == controller.connectQueueIndex) {
          await controller.seek(Duration.zero);
          _start(controller.resume);
        } else {
          _start(() => controller.playQueueIndex(index));
        }
      case ConnectCommand.playContext:
        final snapshot = ConnectPlaybackSnapshot.fromJson(
          Map<String, dynamic>.from(arguments['snapshot'] as Map),
        );
        final playable = connectPlayableQueue(snapshot);
        controller
          ..setShuffleEnabled(snapshot.shuffle)
          ..setRepeatMode(connectRepeatMode(snapshot.repeatMode));
        final position = Duration(milliseconds: snapshot.positionMs);
        _start(() async {
          await controller.playRemote(
            playable.tracks[playable.index],
            queue: playable.tracks,
          );
          if (position > Duration.zero) await controller.seek(position);
        });
      default:
        throw UnsupportedError('Unsupported Connect command: $command');
    }
  }

  @override
  Future<void> pauseForTransfer() => _controller.pause();

  /// Starts playback without waiting for it: a song's start can take
  /// seconds, and the command's result must not wait that long (the sender
  /// would retry it). The new state is published as it changes.
  void _start(Future<void> Function() action) {
    unawaited(
      Future<void>.sync(action).catchError((Object error) {
        debugPrint('[Connect] Starting playback failed: $error');
      }),
    );
  }
}
