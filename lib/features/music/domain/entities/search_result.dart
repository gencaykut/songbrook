import 'track_info.dart';

enum SearchCategory { songs, videos, albums, playlists, artists }

enum SearchBackend { innerTube, innerTubeVideoFallback }

class SearchAlbum {
  SearchAlbum({
    required this.browseId,
    required this.title,
    required List<String> artists,
    this.year,
    this.type,
    this.thumbnailUrl,
    this.playlistId,
  }) : artists = List.unmodifiable(artists);

  final String browseId;
  final String title;
  final List<String> artists;
  final String? year;
  final String? type;
  final String? thumbnailUrl;
  final String? playlistId;

  String get artist => artists.join(', ');

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SearchAlbum &&
            browseId == other.browseId &&
            title == other.title &&
            _listsEqual(artists, other.artists) &&
            year == other.year &&
            type == other.type &&
            thumbnailUrl == other.thumbnailUrl &&
            playlistId == other.playlistId;
  }

  @override
  int get hashCode => Object.hash(
    browseId,
    title,
    Object.hashAll(artists),
    year,
    type,
    thumbnailUrl,
    playlistId,
  );
}

class SearchPlaylist {
  const SearchPlaylist({
    required this.browseId,
    required this.title,
    this.subtitle,
    this.thumbnailUrl,
  });

  /// YouTube Music `VL` browse ID of the playlist page.
  final String browseId;
  final String title;
  final String? subtitle;
  final String? thumbnailUrl;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SearchPlaylist &&
            browseId == other.browseId &&
            title == other.title &&
            subtitle == other.subtitle &&
            thumbnailUrl == other.thumbnailUrl;
  }

  @override
  int get hashCode => Object.hash(browseId, title, subtitle, thumbnailUrl);
}

class SearchArtist {
  const SearchArtist({
    required this.browseId,
    required this.name,
    this.thumbnailUrl,
  });

  final String browseId;
  final String name;
  final String? thumbnailUrl;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SearchArtist &&
            browseId == other.browseId &&
            name == other.name &&
            thumbnailUrl == other.thumbnailUrl;
  }

  @override
  int get hashCode => Object.hash(browseId, name, thumbnailUrl);
}

class SearchPage {
  SearchPage({
    required this.category,
    required this.backend,
    List<TrackInfo> tracks = const [],
    List<SearchAlbum> albums = const [],
    List<SearchArtist> artists = const [],
    List<SearchPlaylist> playlists = const [],
    this.continuation,
    this.primaryError,
  }) : assert(switch (category) {
         SearchCategory.songs || SearchCategory.videos =>
           albums.isEmpty && artists.isEmpty && playlists.isEmpty,
         SearchCategory.albums =>
           tracks.isEmpty && artists.isEmpty && playlists.isEmpty,
         SearchCategory.playlists =>
           tracks.isEmpty && albums.isEmpty && artists.isEmpty,
         SearchCategory.artists =>
           tracks.isEmpty && albums.isEmpty && playlists.isEmpty,
       }, 'A search page can contain results only for its category.'),
       assert(
         backend != SearchBackend.innerTubeVideoFallback ||
             category == SearchCategory.videos,
         'InnerTube video fallback results are always YouTube videos.',
       ),
       tracks = List.unmodifiable(tracks),
       albums = List.unmodifiable(albums),
       artists = List.unmodifiable(artists),
       playlists = List.unmodifiable(playlists);

  final SearchCategory category;
  final SearchBackend backend;
  final List<TrackInfo> tracks;
  final List<SearchAlbum> albums;
  final List<SearchArtist> artists;
  final List<SearchPlaylist> playlists;

  /// YouTube's token for the next page of this category, or `null` when the
  /// results end or the backend cannot page.
  final String? continuation;

  /// The catalog failure that caused this page to use the InnerTube video
  /// fallback.
  ///
  /// Direct YouTube references intentionally use the video fallback without a
  /// primary failure, so this remains `null` for those searches.
  final Object? primaryError;

  bool get isFallback => backend == SearchBackend.innerTubeVideoFallback;
  bool get isEmpty =>
      tracks.isEmpty && albums.isEmpty && artists.isEmpty && playlists.isEmpty;

  bool get hasMore => continuation != null;

  int get itemCount =>
      tracks.length + albums.length + artists.length + playlists.length;

  /// Appends [next] from the same search, skipping items already shown:
  /// consecutive YouTube pages can repeat an entry.
  SearchPage appending(SearchPage next, {String? continuation}) {
    List<T> merge<T>(List<T> current, List<T> added, Object Function(T) key) {
      final seen = current.map(key).toSet();
      return [
        ...current,
        for (final item in added)
          if (seen.add(key(item))) item,
      ];
    }

    return SearchPage(
      category: category,
      backend: backend,
      tracks: merge(
        tracks,
        next.tracks,
        (track) => track.id.isNotEmpty ? track.id : track.url,
      ),
      albums: merge(albums, next.albums, (album) => album.browseId),
      artists: merge(artists, next.artists, (artist) => artist.browseId),
      playlists: merge(
        playlists,
        next.playlists,
        (playlist) => playlist.browseId,
      ),
      continuation: continuation,
      primaryError: primaryError,
    );
  }
}

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
