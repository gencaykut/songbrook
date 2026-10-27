part of '../music_providers.dart';

/// One playback queue entry as Songbrook Connect sees it. [track] names a
/// YouTube video any Songbrook device can stream; a [portable] false entry
/// is a file only this device has, shown on the others but not playable
/// there.
@immutable
class ConnectQueueTrack {
  const ConnectQueueTrack({required this.track, required this.portable});

  final TrackInfo track;
  final bool portable;
}

/// What Songbrook Connect publishes about this device's player. Reading it
/// does not change playback.
extension PlayerControllerConnect on PlayerController {
  /// The queue in playback order; the same list until the queue changes.
  List<ConnectQueueTrack> get connectQueue {
    final items = _queue;
    return _connectQueues[items] ??= List<ConnectQueueTrack>.unmodifiable(
      items.map(_connectQueueTrack),
    );
  }

  int get connectQueueIndex => _queueIndex;

  bool get connectShuffleEnabled => _shuffleEnabled;

  PlaybackRepeatMode get connectRepeatMode => _repeatMode;
}

final _connectQueues = Expando<List<ConnectQueueTrack>>('connectQueue');

ConnectQueueTrack _connectQueueTrack(_QueueItem item) {
  final remote = item.remote;
  if (remote != null) {
    return ConnectQueueTrack(track: remote, portable: true);
  }
  final local = item.local!;
  const links = BStreamTrackLinkCodec();
  final videoId = local.isExternal
      ? null
      : links.extractVideoId(local.sourceId ?? '') ??
            links.extractVideoId(local.sourceUrl ?? '');
  final sourceUrl = local.sourceUrl?.trim();
  return ConnectQueueTrack(
    portable: videoId != null,
    track: TrackInfo(
      id: videoId ?? local.id,
      title: local.title,
      artist: local.artist,
      artists: local.artists,
      artistBrowseIds: local.artistBrowseIds,
      album: local.album,
      duration: local.duration,
      thumbnailUrl: local.thumbnailUrl,
      catalogThumbnailUrl: local.catalogThumbnailUrl,
      url: videoId == null
          ? ''
          : sourceUrl != null && sourceUrl.isNotEmpty
          ? sourceUrl
          : 'https://www.youtube.com/watch?v=$videoId',
      metadataSource: local.metadataSource,
    ),
  );
}

class _ConnectRestorePoint {
  const _ConnectRestorePoint({
    required this.queue,
    required this.index,
    required this.snapshot,
    required this.activePlaybackIsRemote,
    required this.useNativeLocalQueue,
    required this.localQueueSourceId,
    required this.remoteQueueSourceId,
  });

  final List<_QueueItem> queue;
  final int index;
  final PlayerSnapshot? snapshot;
  final bool activePlaybackIsRemote;
  final bool useNativeLocalQueue;
  final String? localQueueSourceId;
  final String? remoteQueueSourceId;
}
