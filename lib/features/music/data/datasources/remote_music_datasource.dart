import '../../../../core/utils/image_source.dart';
import '../../../../services/downloader/downloader_service.dart';
import '../../../../services/youtube_music/innertube_search_service.dart';
import '../../domain/entities/download_options.dart';
import '../../domain/entities/download_result.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/track_info.dart';

TrackInfo trackInfoFromInnerTubeSong(InnerTubeSong song) {
  return TrackInfo(
    id: song.videoId,
    title: song.title,
    artist: song.artist.isEmpty ? 'Desconocido' : song.artist,
    artists: song.artists,
    artistBrowseIds: song.artistBrowseIds,
    album: song.album,
    albumBrowseId: song.albumBrowseId,
    duration: song.duration,
    // The catalog shelf commonly exposes only tiny artwork. Prefer the stable
    // video thumbnail without invoking an extractor during discovery.
    thumbnailUrl:
        youtubeThumbnailSourceForVideoId(song.videoId) ?? song.thumbnailUrl,
    catalogThumbnailUrl: song.thumbnailUrl,
    url: song.watchUri.toString(),
    metadataSource: TrackMetadataSource.youtubeMusic,
  );
}

SearchAlbum searchAlbumFromInnerTubeAlbum(InnerTubeAlbum album) {
  return SearchAlbum(
    browseId: album.browseId,
    title: album.title,
    artists: album.artists,
    year: album.year,
    type: album.type,
    thumbnailUrl: album.thumbnailUrl,
    playlistId: album.playlistId,
  );
}

SearchPlaylist searchPlaylistFromInnerTubePlaylist(InnerTubePlaylist playlist) {
  return SearchPlaylist(
    browseId: playlist.browseId,
    title: playlist.title,
    subtitle: playlist.subtitle,
    thumbnailUrl: playlist.thumbnailUrl,
  );
}

SearchArtist searchArtistFromInnerTubeArtist(InnerTubeArtist artist) {
  return SearchArtist(
    browseId: artist.browseId,
    name: artist.name,
    thumbnailUrl: artist.thumbnailUrl,
  );
}

class RemoteMusicDataSource {
  const RemoteMusicDataSource(
    this._downloaderService, {
    this.youtubeMusicSearch,
  });

  final DownloaderService _downloaderService;
  final YouTubeMusicSearch? youtubeMusicSearch;

  Stream<DownloadProgress> get progressStream =>
      _downloaderService.progressStream;

  Future<TrackInfo> getInfo(String url) {
    return _downloaderService.getInfo(url);
  }

  Future<TrackInfo> getPlaybackInfo(String url) {
    return _downloaderService.getPlaybackInfo(url);
  }

  Future<List<TrackInfo>> search(String query) async {
    final musicSearch = youtubeMusicSearch;
    if (musicSearch != null && !_isDirectYouTubeReference(query)) {
      try {
        final songs = await musicSearch.searchSongs(query);
        if (songs.isNotEmpty && _hasRelevantResult(query, songs)) {
          return List.unmodifiable(songs.map(trackInfoFromInnerTubeSong));
        }
      } catch (error) {
        if (!_isExpectedInnerTubeFailure(error)) {
          rethrow;
        }
        // InnerTube is an unofficial, changing endpoint. Search must remain
        // usable through the downloader-backed InnerTube fallback whenever
        // the catalog bootstrap, request, or response format is unavailable.
      }
    }
    return _downloaderService.search(query);
  }

  /// Searches one YouTube Music category without eagerly requesting the other
  /// tabs. A successful empty InnerTube response remains an empty page.
  ///
  /// The downloader-backed InnerTube lookup is used exactly once when the
  /// catalog throws, is unavailable, or the query is already a direct YouTube
  /// reference. Its fallback contract always returns the Videos page.
  Future<SearchPage> searchCategory(
    String query,
    SearchCategory category,
  ) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return SearchPage(category: category, backend: SearchBackend.innerTube);
    }
    if (_isDirectYouTubeReference(normalizedQuery)) {
      return _searchVideosWithInnerTubeFallback(normalizedQuery);
    }

    final musicSearch = youtubeMusicSearch;
    try {
      if (musicSearch == null) {
        throw UnsupportedError('YouTube Music search is unavailable.');
      }
      if (musicSearch case final YouTubeMusicPagedSearch paged) {
        return await _searchPagedCategory(paged, normalizedQuery, category);
      }
      return switch (category) {
        SearchCategory.songs => SearchPage(
          category: category,
          backend: SearchBackend.innerTube,
          tracks: (await musicSearch.searchSongs(
            normalizedQuery,
          )).map(trackInfoFromInnerTubeSong).toList(growable: false),
        ),
        SearchCategory.videos => SearchPage(
          category: category,
          backend: SearchBackend.innerTube,
          tracks: (await _catalogSearch(musicSearch).searchVideos(
            normalizedQuery,
          )).map(trackInfoFromInnerTubeSong).toList(growable: false),
        ),
        SearchCategory.albums => SearchPage(
          category: category,
          backend: SearchBackend.innerTube,
          albums: (await _catalogSearch(musicSearch).searchAlbums(
            normalizedQuery,
          )).map(searchAlbumFromInnerTubeAlbum).toList(growable: false),
        ),
        SearchCategory.artists => SearchPage(
          category: category,
          backend: SearchBackend.innerTube,
          artists: (await _artistSearch(musicSearch).searchArtists(
            normalizedQuery,
          )).map(searchArtistFromInnerTubeArtist).toList(growable: false),
        ),
        SearchCategory.playlists => throw UnsupportedError(
          'The configured YouTube Music service cannot search playlists.',
        ),
      };
    } catch (error) {
      if (!_isExpectedInnerTubeFailure(error)) {
        rethrow;
      }
      return _searchVideosWithInnerTubeFallback(
        normalizedQuery,
        primaryError: error,
      );
    }
  }

  /// Loads the page that follows a [continuation] of the same search.
  ///
  /// Unlike [searchCategory] a failure propagates instead of switching to the
  /// video fallback, so the results already shown stay and can be retried.
  Future<SearchPage> searchCategoryContinuation(
    String query,
    SearchCategory category,
    String continuation,
  ) {
    final musicSearch = youtubeMusicSearch;
    if (musicSearch case final YouTubeMusicPagedSearch paged) {
      return _searchPagedCategory(
        paged,
        query.trim(),
        category,
        continuation: continuation,
      );
    }
    throw UnsupportedError(
      'The configured YouTube Music service cannot page search results.',
    );
  }

  Future<SearchPage> _searchPagedCategory(
    YouTubeMusicPagedSearch search,
    String query,
    SearchCategory category, {
    String? continuation,
  }) async {
    SearchPage page<T>(
      InnerTubeSearchResultPage<T> result, {
      List<TrackInfo> Function(List<T>)? tracks,
      List<SearchAlbum> Function(List<T>)? albums,
      List<SearchPlaylist> Function(List<T>)? playlists,
      List<SearchArtist> Function(List<T>)? artists,
    }) => SearchPage(
      category: category,
      backend: SearchBackend.innerTube,
      tracks: tracks?.call(result.items) ?? const [],
      albums: albums?.call(result.items) ?? const [],
      playlists: playlists?.call(result.items) ?? const [],
      artists: artists?.call(result.items) ?? const [],
      continuation: result.continuation,
    );

    List<R> mapped<T, R>(List<T> items, R Function(T) convert) =>
        items.map(convert).toList(growable: false);

    return switch (category) {
      SearchCategory.songs => page(
        await search.searchSongsPage(query, continuation: continuation),
        tracks: (items) => mapped(items, trackInfoFromInnerTubeSong),
      ),
      SearchCategory.videos => page(
        await search.searchVideosPage(query, continuation: continuation),
        tracks: (items) => mapped(items, trackInfoFromInnerTubeSong),
      ),
      SearchCategory.albums => page(
        await search.searchAlbumsPage(query, continuation: continuation),
        albums: (items) => mapped(items, searchAlbumFromInnerTubeAlbum),
      ),
      SearchCategory.playlists => page(
        await search.searchPlaylistsPage(query, continuation: continuation),
        playlists: (items) =>
            mapped(items, searchPlaylistFromInnerTubePlaylist),
      ),
      SearchCategory.artists => page(
        await search.searchArtistsPage(query, continuation: continuation),
        artists: (items) => mapped(items, searchArtistFromInnerTubeArtist),
      ),
    };
  }

  Future<List<TrackInfo>> getAlbumTracks(String browseId) async {
    final normalizedBrowseId = browseId.trim();
    if (normalizedBrowseId.isEmpty) {
      throw ArgumentError.value(browseId, 'browseId', 'Must not be empty.');
    }
    final musicSearch = youtubeMusicSearch;
    if (musicSearch is! YouTubeMusicAlbumLookup) {
      throw UnsupportedError(
        'The configured YouTube Music service cannot resolve albums.',
      );
    }
    final albumLookup = musicSearch as YouTubeMusicAlbumLookup;
    final songs = await albumLookup.getAlbumSongs(normalizedBrowseId);
    return List.unmodifiable(songs.map(trackInfoFromInnerTubeSong));
  }

  Future<DownloadResult> downloadAudio(String url, DownloadOptions options) {
    return _downloaderService.downloadAudio(url, options);
  }

  YouTubeMusicCatalogSearch _catalogSearch(YouTubeMusicSearch search) {
    if (search is YouTubeMusicCatalogSearch) {
      return search as YouTubeMusicCatalogSearch;
    }
    throw UnsupportedError(
      'The configured YouTube Music service cannot search this category.',
    );
  }

  YouTubeMusicArtistSearch _artistSearch(YouTubeMusicSearch search) {
    if (search is YouTubeMusicArtistSearch) {
      return search as YouTubeMusicArtistSearch;
    }
    throw UnsupportedError(
      'The configured YouTube Music service cannot search artists.',
    );
  }

  Future<SearchPage> _searchVideosWithInnerTubeFallback(
    String query, {
    Object? primaryError,
  }) async {
    final tracks = await _downloaderService.search(query);
    return SearchPage(
      category: SearchCategory.videos,
      backend: SearchBackend.innerTubeVideoFallback,
      tracks: tracks,
      primaryError: primaryError,
    );
  }

  bool _isExpectedInnerTubeFailure(Object error) {
    return error is InnerTubeException || error is UnsupportedError;
  }

  bool _isDirectYouTubeReference(String query) {
    final normalized = query.trim();
    // A bare video id is always 11 characters, but ordinary search terms can
    // have that exact shape too (for example, "traicionera"). Requiring an
    // id-like digit or separator keeps pasted ids fast without routing plain
    // words away from the YouTube Music catalog.
    if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(normalized) &&
        RegExp(r'[0-9_-]').hasMatch(normalized)) {
      return true;
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme) {
      return false;
    }
    final host = uri.host.toLowerCase();
    return host == 'youtu.be' ||
        host == 'youtube.com' ||
        host.endsWith('.youtube.com');
  }

  bool _hasRelevantResult(String query, List<InnerTubeSong> songs) {
    final queryTokens = _distinctiveTokens(query);
    if (queryTokens.isEmpty) {
      return false;
    }

    for (final song in songs.take(5)) {
      final titleTokens = _distinctiveTokens(song.title);
      final candidateTokens = <String>{
        ...titleTokens,
        for (final artist in song.artists) ..._distinctiveTokens(artist),
      };
      final matched = queryTokens
          .where(
            (queryToken) => candidateTokens.any(
              (candidateToken) => _tokensMatch(queryToken, candidateToken),
            ),
          )
          .length;
      if (matched == 0) {
        continue;
      }
      final coverage = matched / queryTokens.length;
      final titleMatches = queryTokens.any(titleTokens.contains);
      if (coverage >= 0.8 ||
          (coverage >= 0.5 && titleMatches) ||
          (queryTokens.length == 1 && matched == 1)) {
        return true;
      }
    }
    return false;
  }

  Set<String> _distinctiveTokens(String value) {
    var normalized = value.toLowerCase();
    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
    };
    replacements.forEach((source, replacement) {
      normalized = normalized.replaceAll(source, replacement);
    });
    const ignored = <String>{
      'a',
      'an',
      'and',
      'audio',
      'cancion',
      'de',
      'del',
      'e',
      'el',
      'hd',
      'la',
      'las',
      'los',
      'music',
      'musica',
      'of',
      'official',
      'song',
      'the',
      'video',
      'y',
    };
    final tokens = normalized
        .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
        .where((token) => token.isNotEmpty)
        .toSet();
    final distinctive = tokens
        .where((token) => !ignored.contains(token))
        .toSet();
    // A presentation word can also be a legitimate one-word song title.
    return distinctive.isEmpty ? tokens : distinctive;
  }

  bool _tokensMatch(String left, String right) {
    if (left == right) {
      return true;
    }
    if (left.length >= 4 && right.length >= 4) {
      if (left.contains(right) || right.contains(left)) {
        return true;
      }
      return _isSingleEditApart(left, right);
    }
    return false;
  }

  bool _isSingleEditApart(String left, String right) {
    if ((left.length - right.length).abs() > 1) {
      return false;
    }
    var leftIndex = 0;
    var rightIndex = 0;
    var edits = 0;
    while (leftIndex < left.length && rightIndex < right.length) {
      if (left.codeUnitAt(leftIndex) == right.codeUnitAt(rightIndex)) {
        leftIndex++;
        rightIndex++;
        continue;
      }
      if (++edits > 1) {
        return false;
      }
      if (left.length > right.length) {
        leftIndex++;
      } else if (right.length > left.length) {
        rightIndex++;
      } else {
        leftIndex++;
        rightIndex++;
      }
    }
    if (leftIndex < left.length || rightIndex < right.length) {
      edits++;
    }
    return edits <= 1;
  }
}
