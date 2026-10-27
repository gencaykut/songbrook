import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/connect/connect_models.dart';
import '../../../../services/connect/remote_playback.dart';
import '../../../../services/player/player_service.dart';
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

  /// Shows [remote], another device's playback, in this device's player and
  /// sends the player's controls through [control]; null returns the player
  /// to this device's own playback.
  void mirror(ConnectRemotePlayback? remote, ConnectRemoteControl? control);

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

/// [ConnectPlayback] over [PlayerController].
class PlayerConnectPlayback implements ConnectPlayback {
  PlayerConnectPlayback(this._ref) {
    _ref.listen<AsyncValue<PlayerSnapshot>>(playerControllerProvider, (
      previous,
      next,
    ) {
      // Another device's playback on show is not this device's to publish.
      if (_controller.isShowingRemotePlayback) return;
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
    _ref.listen<PlaybackQueueState>(playbackQueueProvider, (_, _) {
      if (!_controller.isShowingRemotePlayback) {
        _emit(const ConnectPlaybackChange());
      }
    });
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
  List<Map<String, dynamic>> _publishedQueue = const [];
  String? _publishedKey;

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
    final player = controller.localPlaybackSnapshot;
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
    final queueJson = _withSongVersion(_encodedQueue, index, player);
    final snapshot = ConnectPlaybackSnapshot.fromValidatedQueue(
      queue: queueJson,
      // Shuffle picks the next entry without reordering the queue.
      backingOrder: _identityOrder,
      currentIndex: queueJson.isEmpty
          ? -1
          : index.clamp(0, queueJson.length - 1),
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

  /// A music video playing its song version is shown under the song's name
  /// and artist; the mirroring devices get them on the current entry. The
  /// list stays the same object until they change, so the queue is not sent
  /// again on every progress update.
  List<Map<String, dynamic>> _withSongVersion(
    List<Map<String, dynamic>> queue,
    int index,
    PlayerSnapshot? player,
  ) {
    if (player == null ||
        !player.isSongVersion ||
        index < 0 ||
        index >= queue.length) {
      return queue;
    }
    String bounded(String? value) {
      final text = value?.trim() ?? '';
      return text.length <= 512 ? text : text.substring(0, 512);
    }

    final title = bounded(player.title);
    final artist = bounded(player.artist);
    final key = '${identityHashCode(queue)}|$index|$title|$artist';
    if (key != _publishedKey) {
      _publishedKey = key;
      _publishedQueue = List<Map<String, dynamic>>.unmodifiable([
        for (var position = 0; position < queue.length; position++)
          position == index
              ? Map<String, dynamic>.unmodifiable({
                  ...queue[position],
                  'songTitle': title,
                  'songArtist': artist,
                  'songVersion': true,
                })
              : queue[position],
      ]);
    }
    return _publishedQueue;
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
        final player = controller.localPlaybackSnapshot;
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

  @override
  void mirror(ConnectRemotePlayback? remote, ConnectRemoteControl? control) {
    final controller = _controller;
    if (remote == null || control == null) {
      controller
        ..attachConnectRemote(null)
        ..hideRemotePlayback();
      return;
    }
    controller
      ..attachConnectRemote(control)
      ..showRemotePlayback(remote);
  }

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
