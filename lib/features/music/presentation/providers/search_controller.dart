part of 'music_providers.dart';

final searchControllerProvider =
    AsyncNotifierProvider<SearchController, SearchState>(SearchController.new);

class SearchState {
  SearchState({
    this.query = '',
    this.selectedCategory = SearchCategory.songs,
    Map<SearchCategory, SearchPage> pages = const {},
    this.fallbackOnly = false,
    this.loadingCategory,
    this.loadingMoreCategory,
    this.loadMoreFailedCategory,
  }) : assert(
         !fallbackOnly || selectedCategory == SearchCategory.videos,
         'A fallback-only search must select Videos.',
       ),
       assert(
         !fallbackOnly ||
             (pages.length <= 1 &&
                 (pages.isEmpty || pages.containsKey(SearchCategory.videos))),
         'A fallback-only search cannot expose InnerTube categories.',
       ),
       pages = Map.unmodifiable(pages);

  final String query;
  final SearchCategory selectedCategory;
  final Map<SearchCategory, SearchPage> pages;
  final bool fallbackOnly;
  final SearchCategory? loadingCategory;

  /// Category whose next page is being appended below its results.
  final SearchCategory? loadingMoreCategory;

  /// Category whose last next-page request failed; its results stay shown.
  final SearchCategory? loadMoreFailedCategory;

  bool get isSelectedCategoryLoadingMore =>
      loadingMoreCategory == selectedCategory;
  bool get selectedLoadMoreFailed => loadMoreFailedCategory == selectedCategory;

  bool get hasQuery => query.isNotEmpty;
  bool get isLoading => loadingCategory != null;
  bool get isSelectedCategoryLoading => loadingCategory == selectedCategory;
  bool get hasSelectedPage => pages.containsKey(selectedCategory);
  SearchPage? get selectedPage => pages[selectedCategory];
  SearchBackend? get backend => selectedPage?.backend;
  Object? get primaryError => selectedPage?.primaryError;
  List<TrackInfo> get selectedTracks =>
      selectedPage?.tracks ?? const <TrackInfo>[];
  List<SearchAlbum> get selectedAlbums =>
      selectedPage?.albums ?? const <SearchAlbum>[];
  List<SearchArtist> get selectedArtists =>
      selectedPage?.artists ?? const <SearchArtist>[];
  List<SearchPlaylist> get selectedPlaylists =>
      selectedPage?.playlists ?? const <SearchPlaylist>[];
  List<SearchCategory> get availableCategories => fallbackOnly
      ? const <SearchCategory>[SearchCategory.videos]
      : SearchCategory.values;

  SearchPage? pageFor(SearchCategory category) => pages[category];

  SearchState copyWith({
    String? query,
    SearchCategory? selectedCategory,
    Map<SearchCategory, SearchPage>? pages,
    bool? fallbackOnly,
    Object? loadingCategory = _searchStateUnset,
    Object? loadingMoreCategory = _searchStateUnset,
    Object? loadMoreFailedCategory = _searchStateUnset,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      pages: pages ?? this.pages,
      fallbackOnly: fallbackOnly ?? this.fallbackOnly,
      loadingCategory: identical(loadingCategory, _searchStateUnset)
          ? this.loadingCategory
          : loadingCategory as SearchCategory?,
      loadingMoreCategory: identical(loadingMoreCategory, _searchStateUnset)
          ? this.loadingMoreCategory
          : loadingMoreCategory as SearchCategory?,
      loadMoreFailedCategory:
          identical(loadMoreFailedCategory, _searchStateUnset)
          ? this.loadMoreFailedCategory
          : loadMoreFailedCategory as SearchCategory?,
    );
  }
}

const _searchStateUnset = Object();

class SearchController extends AsyncNotifier<SearchState> {
  /// Upper bound per category. Results render in one mounted column, and
  /// YouTube's later pages rarely stay relevant.
  static const maxResultsPerCategory = 200;

  int _searchGeneration = 0;

  @override
  Future<SearchState> build() async => SearchState();

  Future<void> submit(String query) async {
    final normalizedQuery = query.trim();
    final generation = ++_searchGeneration;
    ref.read(remotePlaybackCacheProvider).cancelSearchWarmups();
    if (normalizedQuery.isEmpty) {
      state = AsyncData(SearchState());
      return;
    }

    final loadingState = SearchState(
      query: normalizedQuery,
      selectedCategory: SearchCategory.songs,
      loadingCategory: SearchCategory.songs,
    );
    state = AsyncData(loadingState);
    await _loadCategory(loadingState, SearchCategory.songs, generation);
  }

  Future<void> selectCategory(SearchCategory category) async {
    final current = state.value ?? SearchState();
    if (current.fallbackOnly) {
      return;
    }
    if (!current.hasQuery) {
      state = AsyncData(current.copyWith(selectedCategory: category));
      return;
    }
    if (current.loadingCategory == category) {
      return;
    }
    if (current.pages.containsKey(category)) {
      if (current.loadingCategory != null) {
        _searchGeneration++;
        ref.read(remotePlaybackCacheProvider).cancelSearchWarmups();
        // A next page still loading is discarded with this generation, so
        // its category must not stay marked as loading more.
        state = AsyncData(
          current.copyWith(
            selectedCategory: category,
            loadingCategory: null,
            loadingMoreCategory: null,
          ),
        );
        return;
      }
      state = AsyncData(
        current.copyWith(selectedCategory: category, loadingCategory: null),
      );
      return;
    }

    final generation = ++_searchGeneration;
    ref.read(remotePlaybackCacheProvider).cancelSearchWarmups();
    final loadingState = current.copyWith(
      selectedCategory: category,
      loadingCategory: category,
      loadingMoreCategory: null,
    );
    state = AsyncData(loadingState);
    await _loadCategory(loadingState, category, generation);
  }

  /// Appends the next page of the selected category, when YouTube has one.
  ///
  /// A failure keeps the shown results and marks the category for a retry.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasQuery || current.isLoading) {
      return;
    }
    final category = current.selectedCategory;
    final page = current.pageFor(category);
    final continuation = page?.continuation;
    if (page == null ||
        continuation == null ||
        current.loadingMoreCategory != null ||
        page.itemCount >= maxResultsPerCategory) {
      return;
    }

    final generation = _searchGeneration;
    state = AsyncData(
      current.copyWith(
        loadingMoreCategory: category,
        loadMoreFailedCategory: null,
      ),
    );
    try {
      final next = await ref
          .read(remoteMusicDataSourceProvider)
          .searchCategoryContinuation(current.query, category, continuation);
      final latest = state.value;
      if (generation != _searchGeneration || latest == null) {
        return;
      }
      final merged = page.appending(next, continuation: next.continuation);
      final complete =
          next.isEmpty || merged.itemCount >= maxResultsPerCategory;
      state = AsyncData(
        latest.copyWith(
          pages: <SearchCategory, SearchPage>{
            ...latest.pages,
            category: complete ? page.appending(next) : merged,
          },
          loadingMoreCategory: null,
        ),
      );
    } catch (error, stackTrace) {
      final latest = state.value;
      if (generation != _searchGeneration || latest == null) {
        return;
      }
      debugPrint('Search page load failed: $error\n$stackTrace');
      state = AsyncData(
        latest.copyWith(
          loadingMoreCategory: null,
          loadMoreFailedCategory: category,
        ),
      );
    }
  }

  void clear() {
    _searchGeneration++;
    ref.read(remotePlaybackCacheProvider).cancelSearchWarmups();
    state = AsyncData(SearchState());
  }

  Future<void> _loadCategory(
    SearchState loadingState,
    SearchCategory category,
    int generation,
  ) async {
    try {
      final page = await ref
          .read(remoteMusicDataSourceProvider)
          .searchCategory(loadingState.query, category);
      if (generation != _searchGeneration) {
        return;
      }
      if (page.isFallback) {
        state = AsyncData(
          SearchState(
            query: loadingState.query,
            selectedCategory: SearchCategory.videos,
            pages: <SearchCategory, SearchPage>{SearchCategory.videos: page},
            fallbackOnly: true,
          ),
        );
        return;
      }
      state = AsyncData(
        loadingState.copyWith(
          pages: <SearchCategory, SearchPage>{
            ...loadingState.pages,
            category: page,
          },
          loadingCategory: null,
        ),
      );
    } catch (error, stackTrace) {
      if (generation != _searchGeneration) {
        return;
      }
      final fallbackState = SearchState(
        query: loadingState.query,
        selectedCategory: SearchCategory.videos,
        fallbackOnly: true,
      );
      final errorState = AsyncError<SearchState>(error, stackTrace);
      // Riverpod has no public error-with-value constructor. Keeping this
      // previous value makes the fallback restriction observable to the UI
      // even when the InnerTube video fallback also fails.
      // ignore: invalid_use_of_internal_member
      state = errorState.copyWithPrevious(AsyncData(fallbackState));
    }
  }
}
