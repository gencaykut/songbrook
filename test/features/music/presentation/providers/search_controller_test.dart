import 'dart:async';

import 'package:bstream_music/features/music/data/datasources/remote_music_datasource.dart';
import 'package:bstream_music/features/music/domain/entities/download_options.dart';
import 'package:bstream_music/features/music/domain/entities/download_result.dart';
import 'package:bstream_music/features/music/domain/entities/search_result.dart';
import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/downloader/downloader_service.dart';
import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('submit loads Songs without resolving playback URLs', () async {
    final catalog = _FakeCatalog(
      songResults: [
        InnerTubeSong(
          videoId: 'H9NJenpBV2I',
          title: 'Easy On Me',
          artists: const ['Adele'],
          album: 'Easy On Me',
          duration: const Duration(minutes: 3, seconds: 45),
        ),
      ],
    );
    final downloader = _FakeDownloaderService();
    final container = _container(catalog, downloader);
    addTearDown(container.dispose);

    await container.read(searchControllerProvider.future);
    await container
        .read(searchControllerProvider.notifier)
        .submit('  easy on me  ');

    final search = container.read(searchControllerProvider).value!;
    expect(catalog.songQueries, ['easy on me']);
    expect(catalog.videoQueries, isEmpty);
    expect(catalog.albumQueries, isEmpty);
    expect(catalog.artistQueries, isEmpty);
    expect(downloader.searchQueries, isEmpty);
    expect(downloader.getInfoCalls, 0);
    expect(downloader.getPlaybackInfoCalls, 0);
    expect(search.query, 'easy on me');
    expect(search.selectedCategory, SearchCategory.songs);
    expect(search.pages.keys, [SearchCategory.songs]);
    expect(search.backend, SearchBackend.innerTube);
    expect(search.selectedTracks.single.id, 'H9NJenpBV2I');
    expect(search.isLoading, isFalse);
  });

  test('tabs load lazily once and reuse their cached pages', () async {
    final catalog = _FakeCatalog(
      songResults: [
        InnerTubeSong(
          videoId: 'songs000001',
          title: 'Song',
          artists: const ['Artist'],
        ),
      ],
      videoResults: [
        InnerTubeSong(
          videoId: 'videos00001',
          title: 'Video',
          artists: const ['Artist'],
        ),
      ],
      albumResults: [
        InnerTubeAlbum(
          browseId: 'MPREalbum001',
          title: 'Album',
          artists: const ['Artist'],
        ),
      ],
      artistResults: const [
        InnerTubeArtist(browseId: 'UCartist001', name: 'Artist'),
      ],
    );
    final container = _container(catalog, _FakeDownloaderService());
    addTearDown(container.dispose);
    await container.read(searchControllerProvider.future);
    final controller = container.read(searchControllerProvider.notifier);

    await controller.submit('Artist');
    await controller.selectCategory(SearchCategory.videos);
    await controller.selectCategory(SearchCategory.songs);
    await controller.selectCategory(SearchCategory.albums);
    await controller.selectCategory(SearchCategory.artists);
    await controller.selectCategory(SearchCategory.videos);

    final search = container.read(searchControllerProvider).value!;
    expect(catalog.songQueries, ['Artist']);
    expect(catalog.videoQueries, ['Artist']);
    expect(catalog.albumQueries, ['Artist']);
    expect(catalog.artistQueries, ['Artist']);
    expect(search.pages.keys.toSet(), {
      SearchCategory.songs,
      SearchCategory.videos,
      SearchCategory.albums,
      SearchCategory.artists,
    });
    expect(search.selectedCategory, SearchCategory.videos);
    expect(search.selectedTracks.single.title, 'Video');
    expect(search.fallbackOnly, isFalse);
  });

  test('a pending tab cannot replace a reselected cached page', () async {
    final pendingVideo = Completer<List<InnerTubeSong>>();
    final catalog = _FakeCatalog(
      songResults: [
        InnerTubeSong(
          videoId: 'songs000001',
          title: 'Song',
          artists: const ['Artist'],
        ),
      ],
      videoLoader: (_) => pendingVideo.future,
    );
    final container = _container(catalog, _FakeDownloaderService());
    addTearDown(container.dispose);
    await container.read(searchControllerProvider.future);
    final controller = container.read(searchControllerProvider.notifier);

    await controller.submit('Artist');
    final videoSearch = controller.selectCategory(SearchCategory.videos);
    await controller.selectCategory(SearchCategory.songs);
    pendingVideo.complete([
      InnerTubeSong(
        videoId: 'videos00001',
        title: 'Late video',
        artists: const ['Artist'],
      ),
    ]);
    await videoSearch;

    final search = container.read(searchControllerProvider).value!;
    expect(catalog.videoQueries, ['Artist']);
    expect(search.selectedCategory, SearchCategory.songs);
    expect(search.selectedTracks.single.title, 'Song');
    expect(search.pages.keys, const [SearchCategory.songs]);
    expect(search.loadingCategory, isNull);
  });

  test('fallback keeps only the Videos tab', () async {
    const failure = InnerTubeFormatException('albums endpoint changed');
    final catalog = _FakeCatalog(
      songResults: [
        InnerTubeSong(
          videoId: 'songs000001',
          title: 'Song',
          artists: const ['Artist'],
        ),
      ],
      albumError: failure,
    );
    const fallback = TrackInfo(
      id: 'fallback001',
      title: 'YouTube fallback',
      artist: 'Uploader',
      url: 'https://www.youtube.com/watch?v=fallback001',
    );
    final downloader = _FakeDownloaderService(searchResults: const [fallback]);
    final container = _container(catalog, downloader);
    addTearDown(container.dispose);
    await container.read(searchControllerProvider.future);
    final controller = container.read(searchControllerProvider.notifier);

    await controller.submit('Artist');
    await controller.selectCategory(SearchCategory.albums);

    final search = container.read(searchControllerProvider).value!;
    expect(downloader.searchQueries, ['Artist']);
    expect(search.fallbackOnly, isTrue);
    expect(search.selectedCategory, SearchCategory.videos);
    expect(search.availableCategories, const [SearchCategory.videos]);
    expect(search.pages.keys, const [SearchCategory.videos]);
    expect(search.backend, SearchBackend.innerTubeVideoFallback);
    expect(search.primaryError, same(failure));
    expect(search.selectedTracks, const [fallback]);

    await controller.selectCategory(SearchCategory.songs);
    expect(catalog.songQueries, ['Artist']);
    expect(downloader.searchQueries, ['Artist']);
    expect(
      container.read(searchControllerProvider).value!.selectedCategory,
      SearchCategory.videos,
    );
  });

  test('video fallback failure keeps the error restricted to Videos', () async {
    final catalog = _FakeCatalog(
      songResults: [
        InnerTubeSong(
          videoId: 'songs000001',
          title: 'Song',
          artists: const ['Artist'],
        ),
      ],
      albumError: const InnerTubeFormatException('albums endpoint changed'),
    );
    final fallbackFailure = StateError('InnerTube video fallback failed');
    final downloader = _FakeDownloaderService(searchError: fallbackFailure);
    final container = _container(catalog, downloader);
    addTearDown(container.dispose);
    await container.read(searchControllerProvider.future);
    final controller = container.read(searchControllerProvider.notifier);

    await controller.submit('Artist');
    await controller.selectCategory(SearchCategory.albums);

    final result = container.read(searchControllerProvider);
    expect(result.hasError, isTrue);
    expect(result.error, same(fallbackFailure));
    expect(result.hasValue, isTrue);
    expect(result.value!.query, 'Artist');
    expect(result.value!.fallbackOnly, isTrue);
    expect(result.value!.selectedCategory, SearchCategory.videos);
    expect(result.value!.availableCategories, const [SearchCategory.videos]);
    expect(result.value!.pages, isEmpty);
    expect(downloader.searchQueries, ['Artist']);
  });

  test('a stale slower query cannot replace a newer submission', () async {
    final pending = <String, Completer<List<InnerTubeSong>>>{};
    final catalog = _FakeCatalog(
      songLoader: (query) {
        final completer = Completer<List<InnerTubeSong>>();
        pending[query] = completer;
        return completer.future;
      },
    );
    final container = _container(catalog, _FakeDownloaderService());
    addTearDown(container.dispose);
    await container.read(searchControllerProvider.future);
    final controller = container.read(searchControllerProvider.notifier);

    final first = controller.submit('first');
    final second = controller.submit('second');
    pending['second']!.complete([
      InnerTubeSong(
        videoId: 'second00001',
        title: 'Second result',
        artists: const ['Artist'],
      ),
    ]);
    await second;
    pending['first']!.complete([
      InnerTubeSong(
        videoId: 'first000001',
        title: 'First result',
        artists: const ['Artist'],
      ),
    ]);
    await first;

    final search = container.read(searchControllerProvider).value!;
    expect(catalog.songQueries, ['first', 'second']);
    expect(search.query, 'second');
    expect(search.selectedTracks.single.title, 'Second result');
  });

  test('clear invalidates an in-flight search', () async {
    final pending = Completer<List<InnerTubeSong>>();
    final catalog = _FakeCatalog(songLoader: (_) => pending.future);
    final container = _container(catalog, _FakeDownloaderService());
    addTearDown(container.dispose);
    await container.read(searchControllerProvider.future);
    final controller = container.read(searchControllerProvider.notifier);

    final searchFuture = controller.submit('pending');
    controller.clear();
    pending.complete([
      InnerTubeSong(
        videoId: 'pending0001',
        title: 'Too late',
        artists: const ['Artist'],
      ),
    ]);
    await searchFuture;

    final search = container.read(searchControllerProvider).value!;
    expect(search.hasQuery, isFalse);
    expect(search.pages, isEmpty);
    expect(search.selectedCategory, SearchCategory.songs);
  });

  test('album track provider caches a browse lookup', () async {
    final catalog = _FakeCatalog(
      albumSongs: [
        InnerTubeSong(
          videoId: 'albumtrack1',
          title: 'Album track',
          artists: const ['Artist'],
        ),
      ],
    );
    final container = _container(catalog, _FakeDownloaderService());
    addTearDown(container.dispose);

    final first = await container.read(
      searchAlbumTracksProvider('MPREalbum001').future,
    );
    final second = await container.read(
      searchAlbumTracksProvider('MPREalbum001').future,
    );

    expect(first.single.id, 'albumtrack1');
    expect(second, same(first));
    expect(catalog.albumBrowseIds, ['MPREalbum001']);
    expect(catalog.lastAlbumLimit, innerTubeDetailResultLimit);
  });

  group('paged results', () {
    InnerTubeSong song(String id) =>
        InnerTubeSong(videoId: id, title: 'Song $id', artists: const ['A']);

    ProviderContainer pagedContainer(_PagedCatalog catalog) {
      final container = ProviderContainer(
        overrides: [
          remoteMusicDataSourceProvider.overrideWithValue(
            RemoteMusicDataSource(
              _FakeDownloaderService(),
              youtubeMusicSearch: catalog,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('loadMore appends the next page and skips repeats', () async {
      final catalog = _PagedCatalog(
        songs: {
          null: [
            InnerTubeSearchResultPage(
              items: [song('a0000000001'), song('b0000000001')],
              continuation: 'page-2',
            ),
          ],
          'page-2': [
            InnerTubeSearchResultPage(
              items: [song('b0000000001'), song('c0000000001')],
            ),
          ],
        },
      );
      final container = pagedContainer(catalog);
      await container.read(searchControllerProvider.future);
      final controller = container.read(searchControllerProvider.notifier);

      await controller.submit('artist');
      expect(
        container.read(searchControllerProvider).value!.selectedPage!.hasMore,
        isTrue,
      );
      await controller.loadMore();

      final search = container.read(searchControllerProvider).value!;
      expect(search.selectedTracks.map((track) => track.id), [
        'a0000000001',
        'b0000000001',
        'c0000000001',
      ]);
      expect(search.selectedPage!.hasMore, isFalse);
      expect(search.isSelectedCategoryLoadingMore, isFalse);
      expect(catalog.songContinuations, [null, 'page-2']);

      await controller.loadMore();
      expect(catalog.songContinuations, hasLength(2));
    });

    test('a failed page keeps the results and can be retried', () async {
      final catalog = _PagedCatalog(
        songs: {
          null: [
            InnerTubeSearchResultPage(
              items: [song('a0000000001')],
              continuation: 'page-2',
            ),
          ],
          'page-2': [
            StateError('offline'),
            InnerTubeSearchResultPage(items: [song('b0000000001')]),
          ],
        },
      );
      final container = pagedContainer(catalog);
      await container.read(searchControllerProvider.future);
      final controller = container.read(searchControllerProvider.notifier);

      await controller.submit('artist');
      await controller.loadMore();
      var search = container.read(searchControllerProvider).value!;
      expect(search.selectedLoadMoreFailed, isTrue);
      expect(search.selectedTracks.single.id, 'a0000000001');
      expect(search.fallbackOnly, isFalse);

      await controller.loadMore();
      search = container.read(searchControllerProvider).value!;
      expect(search.selectedLoadMoreFailed, isFalse);
      expect(search.selectedTracks.map((track) => track.id), [
        'a0000000001',
        'b0000000001',
      ]);
    });

    test('a new search discards a page that arrives late', () async {
      final late = Completer<InnerTubeSearchResultPage<InnerTubeSong>>();
      final catalog = _PagedCatalog(
        songs: {
          null: [
            InnerTubeSearchResultPage(
              items: [song('a0000000001')],
              continuation: 'page-2',
            ),
          ],
          'page-2': [late.future],
        },
      );
      final container = pagedContainer(catalog);
      await container.read(searchControllerProvider.future);
      final controller = container.read(searchControllerProvider.notifier);

      await controller.submit('first');
      final pending = controller.loadMore();
      await controller.submit('second');
      late.complete(InnerTubeSearchResultPage(items: [song('z0000000001')]));
      await pending;

      final search = container.read(searchControllerProvider).value!;
      expect(search.query, 'second');
      expect(search.selectedTracks.map((track) => track.id), ['a0000000001']);
      expect(search.loadingMoreCategory, isNull);
    });

    test('the Playlists tab loads community playlists', () async {
      final catalog = _PagedCatalog(
        songs: {
          null: [
            InnerTubeSearchResultPage(items: [song('a0000000001')]),
          ],
        },
        playlists: {
          null: [
            InnerTubeSearchResultPage(
              items: const [
                InnerTubePlaylist(
                  browseId: 'VLPLbest0001',
                  title: 'Best of',
                  subtitle: 'Curator • 20K views',
                ),
              ],
            ),
          ],
        },
      );
      final container = pagedContainer(catalog);
      await container.read(searchControllerProvider.future);
      final controller = container.read(searchControllerProvider.notifier);

      await controller.submit('best of');
      await controller.selectCategory(SearchCategory.playlists);

      final search = container.read(searchControllerProvider).value!;
      expect(search.selectedPlaylists.single.browseId, 'VLPLbest0001');
      expect(search.selectedPlaylists.single.subtitle, 'Curator • 20K views');
    });
  });
}

ProviderContainer _container(
  _FakeCatalog catalog,
  _FakeDownloaderService downloader,
) {
  final dataSource = RemoteMusicDataSource(
    downloader,
    youtubeMusicSearch: catalog,
  );
  return ProviderContainer(
    overrides: [remoteMusicDataSourceProvider.overrideWithValue(dataSource)],
  );
}

class _FakeCatalog
    implements
        YouTubeMusicSearch,
        YouTubeMusicCatalogSearch,
        YouTubeMusicArtistSearch,
        YouTubeMusicAlbumLookup {
  _FakeCatalog({
    this.songResults = const [],
    this.videoResults = const [],
    this.albumResults = const [],
    this.artistResults = const [],
    this.albumSongs = const [],
    this.songLoader,
    this.videoLoader,
    this.albumError,
  });

  final List<InnerTubeSong> songResults;
  final List<InnerTubeSong> videoResults;
  final List<InnerTubeAlbum> albumResults;
  final List<InnerTubeArtist> artistResults;
  final List<InnerTubeSong> albumSongs;
  final Future<List<InnerTubeSong>> Function(String query)? songLoader;
  final Future<List<InnerTubeSong>> Function(String query)? videoLoader;
  final Object? albumError;
  final List<String> songQueries = [];
  final List<String> videoQueries = [];
  final List<String> albumQueries = [];
  final List<String> artistQueries = [];
  final List<String> albumBrowseIds = [];
  int? lastAlbumLimit;

  @override
  Future<List<InnerTubeSong>> searchSongs(
    String query, {
    int limit = 20,
  }) async {
    songQueries.add(query);
    final loader = songLoader;
    return loader == null ? songResults : loader(query);
  }

  @override
  Future<List<InnerTubeSong>> searchVideos(
    String query, {
    int limit = 20,
  }) async {
    videoQueries.add(query);
    final loader = videoLoader;
    return loader == null ? videoResults : loader(query);
  }

  @override
  Future<List<InnerTubeAlbum>> searchAlbums(
    String query, {
    int limit = 20,
  }) async {
    albumQueries.add(query);
    final failure = albumError;
    if (failure != null) {
      throw failure;
    }
    return albumResults;
  }

  @override
  Future<List<InnerTubeArtist>> searchArtists(
    String query, {
    int limit = 20,
  }) async {
    artistQueries.add(query);
    return artistResults;
  }

  @override
  Future<List<InnerTubeSong>> getAlbumSongs(
    String browseId, {
    int limit = 20,
  }) async {
    albumBrowseIds.add(browseId);
    lastAlbumLimit = limit;
    return albumSongs;
  }
}

class _FakeDownloaderService implements DownloaderService {
  _FakeDownloaderService({this.searchResults = const [], this.searchError});

  final List<TrackInfo> searchResults;
  final Object? searchError;
  final List<String> searchQueries = [];
  int getInfoCalls = 0;
  int getPlaybackInfoCalls = 0;

  @override
  Stream<DownloadProgress> get progressStream => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<List<TrackInfo>> search(String query) async {
    searchQueries.add(query);
    final failure = searchError;
    if (failure != null) {
      throw failure;
    }
    return searchResults;
  }

  @override
  Future<TrackInfo> getInfo(String url) {
    getInfoCalls++;
    throw StateError('Search must not resolve track information.');
  }

  @override
  Future<TrackInfo> getPlaybackInfo(String url) {
    getPlaybackInfoCalls++;
    throw StateError('Search must not resolve playback information.');
  }

  @override
  Future<DownloadResult> downloadAudio(String url, DownloadOptions options) {
    throw UnimplementedError();
  }
}

/// Serves scripted pages per continuation token; a missing token's last
/// outcome repeats. An outcome is a page, a future of one, or an error.
class _PagedCatalog implements YouTubeMusicSearch, YouTubeMusicPagedSearch {
  _PagedCatalog({
    Map<String?, List<Object>> songs = const {},
    Map<String?, List<Object>> playlists = const {},
  }) : _songs = {
         for (final e in songs.entries) e.key: [...e.value],
       },
       _playlists = {
         for (final e in playlists.entries) e.key: [...e.value],
       };

  final Map<String?, List<Object>> _songs;
  final Map<String?, List<Object>> _playlists;
  final List<String?> songContinuations = [];

  Future<InnerTubeSearchResultPage<T>> _serve<T>(
    Map<String?, List<Object>> pages,
    String? continuation,
  ) async {
    final outcomes = pages[continuation];
    if (outcomes == null || outcomes.isEmpty) {
      return InnerTubeSearchResultPage<T>(items: const []);
    }
    final outcome = outcomes.length > 1 ? outcomes.removeAt(0) : outcomes.first;
    if (outcome is Future<InnerTubeSearchResultPage<T>>) return outcome;
    if (outcome is InnerTubeSearchResultPage<T>) return outcome;
    throw outcome;
  }

  @override
  Future<List<InnerTubeSong>> searchSongs(String query, {int limit = 20}) =>
      throw UnsupportedError('The paged API is used instead.');

  @override
  Future<InnerTubeSearchResultPage<InnerTubeSong>> searchSongsPage(
    String query, {
    String? continuation,
  }) {
    songContinuations.add(continuation);
    return _serve(_songs, continuation);
  }

  @override
  Future<InnerTubeSearchResultPage<InnerTubeSong>> searchVideosPage(
    String query, {
    String? continuation,
  }) => _serve(const {}, continuation);

  @override
  Future<InnerTubeSearchResultPage<InnerTubeAlbum>> searchAlbumsPage(
    String query, {
    String? continuation,
  }) => _serve(const {}, continuation);

  @override
  Future<InnerTubeSearchResultPage<InnerTubeArtist>> searchArtistsPage(
    String query, {
    String? continuation,
  }) => _serve(const {}, continuation);

  @override
  Future<InnerTubeSearchResultPage<InnerTubePlaylist>> searchPlaylistsPage(
    String query, {
    String? continuation,
  }) => _serve(_playlists, continuation);
}
