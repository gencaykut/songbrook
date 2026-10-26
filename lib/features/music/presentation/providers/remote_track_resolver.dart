part of 'music_providers.dart';

TrackInfo _mergeTrackInfo(TrackInfo base, TrackInfo resolved) {
  final hasResolvedTransport =
      resolved.streamUrl != null && resolved.streamUrl!.trim().isNotEmpty;
  final preserveMusicMetadata =
      base.metadataSource == TrackMetadataSource.youtubeMusic;
  final baseArtists = _meaningfulArtists(base.artists);
  final resolvedArtists = _meaningfulArtists(resolved.artists);
  final artists = preserveMusicMetadata
      ? (baseArtists.isNotEmpty ? baseArtists : resolvedArtists)
      : (resolvedArtists.isNotEmpty ? resolvedArtists : baseArtists);
  final artistBrowseIds = preserveMusicMetadata
      ? (base.artistBrowseIds.isNotEmpty
            ? base.artistBrowseIds
            : resolved.artistBrowseIds)
      : (resolved.artistBrowseIds.isNotEmpty
            ? resolved.artistBrowseIds
            : base.artistBrowseIds);
  return TrackInfo(
    id: preserveMusicMetadata
        ? _preferredIdentifier(base.id, resolved.id)
        : (resolved.id.isNotEmpty ? resolved.id : base.id),
    title: preserveMusicMetadata
        ? _preferredText(base.title, resolved.title, 'Sin título')
        : _preferredText(resolved.title, base.title, 'Sin título'),
    artist: preserveMusicMetadata
        ? (artists.isNotEmpty
              ? artists.join(', ')
              : _preferredText(base.artist, resolved.artist, 'Desconocido'))
        : _preferredText(resolved.artist, base.artist, 'Desconocido'),
    url: preserveMusicMetadata
        ? _preferredIdentifier(base.url, resolved.url)
        : (resolved.url.isNotEmpty ? resolved.url : base.url),
    thumbnailUrl: preserveMusicMetadata
        ? _preferredOptionalText(base.thumbnailUrl, resolved.thumbnailUrl)
        : _preferredOptionalText(resolved.thumbnailUrl, base.thumbnailUrl),
    catalogThumbnailUrl: preserveMusicMetadata
        ? _preferredOptionalText(
            base.catalogThumbnailUrl,
            resolved.catalogThumbnailUrl,
          )
        : _preferredOptionalText(
            resolved.catalogThumbnailUrl,
            base.catalogThumbnailUrl,
          ),
    duration: preserveMusicMetadata
        ? base.duration ?? resolved.duration
        : resolved.duration ?? base.duration,
    streamUrl: resolved.streamUrl ?? base.streamUrl,
    streamExtension: hasResolvedTransport
        ? resolved.streamExtension
        : resolved.streamExtension ?? base.streamExtension,
    streamMimeType: hasResolvedTransport
        ? resolved.streamMimeType
        : resolved.streamMimeType ?? base.streamMimeType,
    streamSource: hasResolvedTransport
        ? resolved.streamSource
        : base.streamSource,
    streamFormatId: hasResolvedTransport
        ? resolved.streamFormatId
        : base.streamFormatId,
    streamCodec: hasResolvedTransport ? resolved.streamCodec : base.streamCodec,
    streamBitrate: hasResolvedTransport
        ? resolved.streamBitrate
        : resolved.streamBitrate ?? base.streamBitrate,
    streamSampleRate: hasResolvedTransport
        ? resolved.streamSampleRate
        : resolved.streamSampleRate ?? base.streamSampleRate,
    streamChannels: hasResolvedTransport
        ? resolved.streamChannels
        : resolved.streamChannels ?? base.streamChannels,
    streamClientProfileKey: hasResolvedTransport
        ? resolved.streamClientProfileKey
        : base.streamClientProfileKey,
    streamVideoId: hasResolvedTransport
        ? resolved.streamVideoId
        : base.streamVideoId,
    songVersionTitle: hasResolvedTransport
        ? resolved.songVersionTitle
        : base.songVersionTitle,
    songVersionArtist: hasResolvedTransport
        ? resolved.songVersionArtist
        : base.songVersionArtist,
    streamDuration: hasResolvedTransport
        ? resolved.streamDuration
        : base.streamDuration,
    loudnessDb: hasResolvedTransport ? resolved.loudnessDb : base.loudnessDb,
    extractor: resolved.extractor ?? base.extractor,
    album: preserveMusicMetadata
        ? _preferredOptionalText(base.album, resolved.album)
        : _preferredOptionalText(resolved.album, base.album),
    albumBrowseId: preserveMusicMetadata
        ? _preferredOptionalText(base.albumBrowseId, resolved.albumBrowseId)
        : _preferredOptionalText(resolved.albumBrowseId, base.albumBrowseId),
    viewCount: resolved.viewCount ?? base.viewCount,
    httpHeaders: hasResolvedTransport
        ? resolved.httpHeaders
        : resolved.httpHeaders ?? base.httpHeaders,
    artists: artists,
    artistBrowseIds: artistBrowseIds,
    metadataSource: preserveMusicMetadata
        ? base.metadataSource
        : resolved.metadataSource,
  );
}

String _preferredIdentifier(String preferred, String fallback) {
  return preferred.trim().isNotEmpty ? preferred : fallback;
}

String? _preferredOptionalText(String? preferred, String? fallback) {
  final normalized = preferred?.trim();
  if (normalized != null && normalized.isNotEmpty) {
    return preferred;
  }
  final fallbackNormalized = fallback?.trim();
  return fallbackNormalized == null || fallbackNormalized.isEmpty
      ? null
      : fallback;
}

List<String> _meaningfulArtists(List<String> artists) {
  final result = <String>[];
  for (final artist in artists) {
    final normalized = artist.trim();
    if (normalized.isEmpty || _isPlaceholderText(normalized)) {
      continue;
    }
    if (!result.contains(normalized)) {
      result.add(normalized);
    }
  }
  return List.unmodifiable(result);
}

String _preferredText(String preferred, String fallback, String placeholder) {
  final normalized = preferred.trim();
  final fallbackNormalized = fallback.trim();
  if (normalized.isEmpty ||
      normalized.toLowerCase() == placeholder.toLowerCase() ||
      _isPlaceholderText(normalized)) {
    if (fallbackNormalized.isEmpty) {
      return preferred;
    }
    return fallback;
  }
  return preferred;
}

bool _isPlaceholderText(String value) {
  return const {
    'desconocido',
    'unknown',
    'unknown artist',
    'sin artista',
    'sin titulo',
    'sin título',
    'untitled',
  }.contains(value.trim().toLowerCase());
}

final remoteTrackResolverProvider = Provider<RemoteTrackResolver>((ref) {
  final resolver = RemoteTrackResolver(ref);
  ref.onDispose(resolver.dispose);
  return resolver;
});

class RemoteTrackResolver {
  RemoteTrackResolver(this._ref, {bool? useMobileCachePolicy})
    : _usesMobileCachePolicy = useMobileCachePolicy ?? AppPlatform.isMobile;

  static const _ttl = Duration(minutes: 20);
  static const _prefsKey = 'remote_track_resolution_cache_v6';
  static const _legacyPrefsKeys = [
    'remote_track_resolution_cache_v2',
    'remote_track_resolution_cache_v3',
    'remote_track_resolution_cache_v4',
    'remote_track_resolution_cache_v5',
  ];
  static const _maxPersistentEntries = 24;
  static const _maxMemoryEntries = 32;

  final Ref _ref;
  final bool _usesMobileCachePolicy;
  final _entries = <String, _TrackResolutionEntry>{};
  bool _loadedPersistentCache = false;
  Future<void>? _persistentCacheLoad;

  Future<TrackInfo> resolve(
    TrackInfo track, {
    bool forceRefresh = false,
    bool allowStaleStreamFallback = true,
    AudioResolutionMode mode = AudioResolutionMode.primaryThenFallback,
    AudioResolverFailureCallback? onResolverFailure,
    AudioResolverContinuationCallback? shouldContinue,
  }) async {
    final key = _cacheKey(track);
    if (key.isEmpty) {
      return track;
    }

    await _loadPersistentCache();
    _trimMemoryEntries();

    final cached = _entries[key];
    if (!forceRefresh &&
        mode == AudioResolutionMode.primaryThenFallback &&
        cached != null &&
        !cached.isExpired) {
      return cached.future.then(
        (resolved) => _mergeTrackInfo(track, resolved),
        onError: (Object error, StackTrace stackTrace) {
          // The joined resolution may belong to a caller that gave up, such
          // as the prefetch of the song the user has just picked: picking it
          // invalidates that prefetch. This caller still wants the track.
          if (!RemotePlaybackFailureClassifier.isCancellation(error) ||
              (shouldContinue != null && !shouldContinue())) {
            Error.throwWithStackTrace(error, stackTrace);
          }
          return resolve(
            track,
            allowStaleStreamFallback: allowStaleStreamFallback,
            mode: mode,
            onResolverFailure: onResolverFailure,
            shouldContinue: shouldContinue,
          );
        },
      );
    }

    final generation = Object();
    final future = _resolveAndCache(
      track,
      key,
      generation: generation,
      forceRefresh: forceRefresh,
      allowStaleStreamFallback: allowStaleStreamFallback,
      mode: mode,
      onResolverFailure: onResolverFailure,
      shouldContinue: shouldContinue,
    );

    _entries[key] = _TrackResolutionEntry(future, generation: generation);
    _trimMemoryEntries(preserveKey: key);
    return future;
  }

  void dispose() {
    _entries.clear();
  }

  String _cacheKey(TrackInfo track) {
    final normalizedUrl = track.url.trim();
    if (normalizedUrl.isNotEmpty) {
      try {
        final videoId = InnerTubeVideoId.extract(normalizedUrl);
        if (videoId == null) throw const FormatException('Not YouTube.');
        return 'youtube:${videoId.value}';
      } catch (_) {
        // A non-YouTube URL is authoritative; do not reinterpret an unrelated
        // eleven-character extractor id as a YouTube video.
        return normalizedUrl;
      }
    }
    final normalizedId = track.id.trim();
    if (normalizedId.isEmpty) {
      return '';
    }
    try {
      final videoId = InnerTubeVideoId.extract(normalizedId);
      if (videoId == null) throw const FormatException('Not YouTube.');
      return 'youtube:${videoId.value}';
    } catch (_) {
      return normalizedId;
    }
  }

  Future<TrackInfo> _resolveAndCache(
    TrackInfo track,
    String key, {
    required Object generation,
    required bool forceRefresh,
    required bool allowStaleStreamFallback,
    required AudioResolutionMode mode,
    required AudioResolverFailureCallback? onResolverFailure,
    required AudioResolverContinuationCallback? shouldContinue,
  }) async {
    try {
      final resolver = _ref.read(audioStreamResolverProvider);
      Future<AudioStreamResolution> resolve(
        TrackInfo target, {
        AudioResolverFailureCallback? onFailure,
      }) {
        return resolver is FallbackAwareAudioStreamResolver
            ? (resolver as FallbackAwareAudioStreamResolver).resolveWithMode(
                target,
                mode: mode,
                onResolverFailure: onFailure,
                shouldContinue: shouldContinue,
              )
            : resolver.resolve(target);
      }

      var resolved = await resolve(track, onFailure: onResolverFailure);
      if (shouldContinue != null && !shouldContinue()) {
        throw const AudioStreamResolverException(
          'Audio stream resolution was superseded.',
        );
      }
      final songVersion = await _preferSongVersion(track, resolved, resolve);
      if (shouldContinue != null && !shouldContinue()) {
        throw const AudioStreamResolverException(
          'Audio stream resolution was superseded.',
        );
      }
      final song = songVersion?.song;
      if (songVersion != null) resolved = songVersion.resolution;
      var merged = _mergeTrackInfo(track, _trackFromResolution(resolved));
      if (song != null) {
        // The queue keeps the video's metadata, but the song version has its
        // own length, which the player's progress follows, and its own name,
        // which the player shows.
        final songLength = resolved.streamDuration;
        merged = merged.copyWith(
          duration: songLength == null
              ? null
              : Duration(seconds: songLength.inMilliseconds ~/ 1000),
          songVersionTitle: song.title,
          songVersionArtist: song.artists.isEmpty
              ? null
              : song.artists.join(', '),
        );
      }
      if (_hasPlayableStream(merged) && _isCurrentGeneration(key, generation)) {
        final entry = _entries[key]!..streamExpiresAt = resolved.expiresAt;
        if (!entry.isExpired) {
          unawaited(
            _persistResolvedEntry(
              key,
              merged,
              streamExpiresAt: resolved.expiresAt,
            ),
          );
        }
      }
      return merged;
    } catch (_) {
      final currentGeneration = _isCurrentGeneration(key, generation);
      if (currentGeneration) {
        _entries.remove(key);
      }
      if (forceRefresh && currentGeneration) {
        unawaited(_removePersistentEntry(key));
      }
      if (allowStaleStreamFallback && _hasPlayableStream(track)) {
        return track;
      }
      rethrow;
    }
  }

  /// A music video's stream comes from the artist's or an uploader's channel;
  /// its song version, from the artist's Topic channel. When YouTube Music has
  /// that song, play its stream under the video's queue entry. Any failure
  /// keeps the video.
  /// The song version to play instead of the music video [track], or null
  /// to play the video itself.
  Future<({InnerTubeSong song, AudioStreamResolution resolution})?>
  _preferSongVersion(
    TrackInfo track,
    AudioStreamResolution resolved,
    Future<AudioStreamResolution> Function(TrackInfo target) resolve,
  ) async {
    final channel = resolved.channelName;
    final enabled =
        _ref
            .read(settingsControllerProvider)
            .asData
            ?.value
            .preferSongVersions ??
        true;
    if (!enabled || channel == null || isSongVersionChannel(channel)) {
      return null;
    }
    try {
      final song = await _ref
          .read(songCounterpartFinderProvider)
          .find(track, videoDuration: resolved.streamDuration);
      if (song == null) return null;
      final songResolution = await resolve(trackInfoFromInnerTubeSong(song));
      debugPrint(
        '[Playback] ${track.id} is a music video; playing its song '
        'version ${song.videoId}.',
      );
      return (song: song, resolution: songResolution);
    } catch (error) {
      debugPrint('[Playback] No song version for ${track.id}: $error');
      return null;
    }
  }

  bool _isCurrentGeneration(String key, Object generation) {
    return identical(_entries[key]?.generation, generation);
  }

  TrackInfo _trackFromResolution(AudioStreamResolution resolution) {
    return TrackInfo(
      id: '',
      title: '',
      artist: '',
      url: '',
      streamUrl: resolution.streamUrl,
      streamExtension: resolution.streamExtension,
      streamMimeType: resolution.streamMimeType,
      streamSource: resolution.source.name,
      streamFormatId: resolution.formatId,
      streamCodec: resolution.codec,
      streamBitrate: resolution.bitrate,
      streamSampleRate: resolution.sampleRate,
      streamChannels: resolution.channels,
      streamClientProfileKey: resolution.clientProfileKey,
      streamVideoId: resolution.videoId,
      streamDuration: resolution.streamDuration,
      loudnessDb: resolution.loudnessDb,
      httpHeaders: resolution.httpHeaders,
    );
  }

  Future<void> _loadPersistentCache() async {
    if (_loadedPersistentCache) {
      return;
    }
    final pending = _persistentCacheLoad;
    if (pending != null) {
      return pending;
    }

    final completer = Completer<void>();
    _persistentCacheLoad = completer.future;
    try {
      await _readPersistentCacheIntoMemory();
      _loadedPersistentCache = true;
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    } finally {
      if (identical(_persistentCacheLoad, completer.future)) {
        _persistentCacheLoad = null;
      }
    }
    return completer.future;
  }

  Future<void> _readPersistentCacheIntoMemory() async {
    final prefs = await SharedPreferences.getInstance();
    for (final legacyKey in _legacyPrefsKeys) {
      await prefs.remove(legacyKey);
    }

    // Stream URLs and their headers are signed and short-lived. They must not
    // survive a mobile process restart or be reused after a download.
    if (_usesMobileCachePolicy) {
      await prefs.remove(_prefsKey);
      return;
    }

    final cache = _readPersistentCache(prefs.getString(_prefsKey));
    var removedExpired = false;

    final now = DateTime.now();
    for (final entry in cache.entries) {
      final value = entry.value;
      if (_isPersistentEntryExpired(value, now)) {
        removedExpired = true;
        continue;
      }

      final track = _trackFromPersistentEntry(value);
      if (track == null || !_hasPlayableStream(track)) {
        removedExpired = true;
        continue;
      }

      _entries[entry.key] = _TrackResolutionEntry(
        Future.value(track),
        createdAt: _persistentEntryCreatedAt(value),
        streamExpiresAt: _persistentEntryExpiresAt(value),
      );
    }

    if (removedExpired) {
      cache.removeWhere((_, value) => _isPersistentEntryExpired(value, now));
      await prefs.setString(_prefsKey, jsonEncode(cache));
    }
  }

  Future<void> _persistResolvedEntry(
    String key,
    TrackInfo track, {
    required DateTime? streamExpiresAt,
  }) async {
    // Local playback files may live in an OS cache directory. Keep them in
    // memory for this session, but never persist paths the OS may remove.
    final streamUri = Uri.tryParse(track.streamUrl ?? '');
    if (_usesMobileCachePolicy || !_hasPlayableStream(track)) {
      return;
    }
    if (streamUri?.scheme == 'file') {
      await _removePersistentEntry(key);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final cache = _readPersistentCache(prefs.getString(_prefsKey));
    final now = DateTime.now();
    cache.removeWhere((_, value) => _isPersistentEntryExpired(value, now));
    cache[key] = {
      'createdAt': now.millisecondsSinceEpoch,
      if (streamExpiresAt != null)
        'expiresAt': streamExpiresAt.millisecondsSinceEpoch,
      'track': _trackInfoModel(track).toJson(),
    };
    _trimPersistentCache(cache);
    await prefs.setString(_prefsKey, jsonEncode(cache));
  }

  Future<void> _removePersistentEntry(String key) async {
    if (_usesMobileCachePolicy) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = _readPersistentCache(prefs.getString(_prefsKey));
      if (cache.remove(key) == null) {
        return;
      }
      await prefs.setString(_prefsKey, jsonEncode(cache));
    } catch (_) {
      // A cache cleanup failure must not hide the original playback error.
    }
  }

  Map<String, dynamic> _readPersistentCache(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return {};
      }
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    } catch (_) {
      return {};
    }
  }

  void _trimPersistentCache(Map<String, dynamic> cache) {
    if (cache.length <= _maxPersistentEntries) {
      return;
    }

    final entries = cache.entries.toList()
      ..sort((left, right) {
        final leftCreated =
            _persistentEntryCreatedAt(left.value) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final rightCreated =
            _persistentEntryCreatedAt(right.value) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return leftCreated.compareTo(rightCreated);
      });

    for (final entry in entries.take(cache.length - _maxPersistentEntries)) {
      cache.remove(entry.key);
    }
  }

  void _trimMemoryEntries({String? preserveKey}) {
    _entries.removeWhere((key, entry) => key != preserveKey && entry.isExpired);
    if (_entries.length <= _maxMemoryEntries) {
      return;
    }

    final oldest =
        _entries.entries
            .where((entry) => entry.key != preserveKey)
            .toList(growable: false)
          ..sort(
            (left, right) =>
                left.value.createdAt.compareTo(right.value.createdAt),
          );
    final removeCount = _entries.length - _maxMemoryEntries;
    for (final entry in oldest.take(removeCount)) {
      _entries.remove(entry.key);
    }
  }

  TrackInfo? _trackFromPersistentEntry(Object? value) {
    if (value is! Map) {
      return null;
    }
    final track = value['track'];
    if (track is! Map) {
      return null;
    }

    try {
      return TrackInfoModel.fromJson(
        track.map((key, data) => MapEntry(key.toString(), data)),
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? _persistentEntryCreatedAt(Object? value) {
    if (value is! Map) {
      return null;
    }
    final raw = value['createdAt'];
    final milliseconds = raw is num ? raw.toInt() : int.tryParse('$raw');
    if (milliseconds == null || milliseconds <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  DateTime? _persistentEntryExpiresAt(Object? value) {
    if (value is! Map) {
      return null;
    }
    final raw = value['expiresAt'];
    final milliseconds = raw is num ? raw.toInt() : int.tryParse('$raw');
    if (milliseconds == null || milliseconds <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  bool _isPersistentEntryExpired(Object? value, DateTime now) {
    final createdAt = _persistentEntryCreatedAt(value);
    if (createdAt == null) {
      return true;
    }
    if (!now.isBefore(createdAt.add(_ttl))) {
      return true;
    }
    final streamExpiresAt = _persistentEntryExpiresAt(value);
    return streamExpiresAt != null && !now.isBefore(streamExpiresAt);
  }

  bool _hasPlayableStream(TrackInfo track) {
    return track.streamUrl != null && track.streamUrl!.trim().isNotEmpty;
  }

  TrackInfoModel _trackInfoModel(TrackInfo track) {
    return TrackInfoModel(
      id: track.id,
      title: track.title,
      artist: track.artist,
      url: track.url,
      thumbnailUrl: track.thumbnailUrl,
      catalogThumbnailUrl: track.catalogThumbnailUrl,
      duration: track.duration,
      streamUrl: track.streamUrl,
      streamExtension: track.streamExtension,
      streamMimeType: track.streamMimeType,
      streamSource: track.streamSource,
      streamFormatId: track.streamFormatId,
      streamCodec: track.streamCodec,
      streamBitrate: track.streamBitrate,
      streamSampleRate: track.streamSampleRate,
      streamChannels: track.streamChannels,
      streamClientProfileKey: track.streamClientProfileKey,
      streamVideoId: track.streamVideoId,
      songVersionTitle: track.songVersionTitle,
      songVersionArtist: track.songVersionArtist,
      streamDuration: track.streamDuration,
      loudnessDb: track.loudnessDb,
      extractor: track.extractor,
      album: track.album,
      albumBrowseId: track.albumBrowseId,
      viewCount: track.viewCount,
      httpHeaders: track.httpHeaders,
      artists: track.artists,
      artistBrowseIds: track.artistBrowseIds,
      metadataSource: track.metadataSource,
    );
  }
}

class _TrackResolutionEntry {
  _TrackResolutionEntry(
    this.future, {
    Object? generation,
    DateTime? createdAt,
    this.streamExpiresAt,
  }) : generation = generation ?? Object(),
       createdAt = createdAt ?? DateTime.now();

  final Future<TrackInfo> future;
  final Object generation;
  final DateTime createdAt;
  DateTime? streamExpiresAt;

  bool get isExpired {
    final now = DateTime.now();
    return !now.isBefore(createdAt.add(RemoteTrackResolver._ttl)) ||
        (streamExpiresAt != null && !now.isBefore(streamExpiresAt!));
  }
}
