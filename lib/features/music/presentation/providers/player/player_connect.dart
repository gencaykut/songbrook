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

  bool _playLocalOnConnect(LocalTrack track, List<LocalTrack>? queue) {
    final tracks = queue == null || queue.isEmpty ? [track] : queue;
    var index = tracks.indexWhere((item) => item.id == track.id);
    final items = [
      if (index < 0) _connectQueueTrack(_QueueItem.local(track)),
      for (final item in tracks) _connectQueueTrack(_QueueItem.local(item)),
    ];
    if (index < 0) index = 0;
    return _playOnConnectItems(items, index);
  }
}

/// Where a player that shows another device's playback sends its controls.
abstract interface class ConnectRemoteControl {
  /// False while this device is taking the playback over (a handoff being
  /// applied here): the player then acts on its own audio again.
  bool get forwarding;

  void send(String command, [Map<String, dynamic>? arguments]);
}

PlaybackQueueEntry _connectQueueEntry(Map<String, dynamic> json, int index) {
  final thumbnail = json['thumbnail'] as String?;
  return PlaybackQueueEntry(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    artist: json['artist'] as String? ?? '',
    album: json['album'] as String?,
    thumbnailUrl: thumbnail,
    isRemote: json[_connectLocalOnlyField] != true,
    // Positions, not ids: the same song can be queued twice.
    logicalEntryId: 'connect:$index',
  );
}

ConnectQueueTrack _connectCatalogItem(CatalogPlaybackItem item) {
  final remote = item.remoteTrack;
  if (remote != null) return ConnectQueueTrack(track: remote, portable: true);
  return _connectQueueTrack(_QueueItem.local(item.localTrack));
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

/// A queue entry another device cannot stream: a file only this one has.
const _connectLocalOnlyField = 'localOnly';

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
    if (!portable) _connectLocalOnlyField: true,
  });
}

/// The track a Connect queue entry names, or null for an entry this device
/// cannot stream.
TrackInfo? trackFromConnectJson(Map<String, dynamic> json) {
  if (json[_connectLocalOnlyField] == true) return null;
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
