import 'package:bstream_music/features/music/domain/entities/search_result.dart';
import 'package:bstream_music/features/music/presentation/pages/search_view.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Searches live YouTube Music through the real Search view and scrolls until
/// further pages append, then opens the Playlists tab.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('scrolling appends live result pages', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Scaffold(body: SearchView(onOpenPlayer: () {})),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField).first, 'Tarkan');
    await tester.testTextInput.receiveAction(TextInputAction.search);

    SearchState state() => container.read(searchControllerProvider).value!;
    Future<void> settle(bool Function() done) async {
      for (var i = 0; i < 200 && !done(); i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle(() => state().hasSelectedPage);
    final firstCount = state().selectedTracks.length;
    // ignore: avoid_print
    print(
      'CLAUDE_PAGING first=$firstCount hasMore=${state().selectedPage!.hasMore}',
    );
    expect(firstCount, greaterThan(0));

    final scrollable = find.byType(Scrollable).first;
    for (
      var step = 0;
      step < 40 && state().selectedTracks.length < 60;
      step++
    ) {
      await tester.drag(scrollable, const Offset(0, -1500));
      await tester.pump(const Duration(milliseconds: 300));
      await settle(() => !state().isSelectedCategoryLoadingMore);
    }
    final ids = state().selectedTracks.map((track) => track.id).toList();
    // ignore: avoid_print
    print(
      'CLAUDE_PAGING after scrolling=${ids.length} unique=${ids.toSet().length} '
      'failed=${state().selectedLoadMoreFailed}',
    );
    expect(ids.length, greaterThanOrEqualTo(60));
    expect(ids.toSet().length, ids.length);

    await container
        .read(searchControllerProvider.notifier)
        .selectCategory(SearchCategory.playlists);
    await settle(() => state().hasSelectedPage);
    await tester.pump(const Duration(seconds: 1));
    final playlists = state().selectedPlaylists;
    // ignore: avoid_print
    print(
      'CLAUDE_PAGING playlists=${playlists.length} '
      'first="${playlists.firstOrNull?.title}" — ${playlists.firstOrNull?.subtitle}',
    );
    expect(playlists, isNotEmpty);
    expect(
      find.byKey(ValueKey('search-playlist-open-${playlists.first.browseId}')),
      findsOneWidget,
    );
  });
}
