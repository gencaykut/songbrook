part of 'music_providers.dart';

/// Lists the library builds from this device's listening history.
enum ListeningListKind {
  /// Most played in the last [listeningListRecentWindow].
  mostPlayedRecently,

  /// Most played over the whole history.
  mostPlayedAllTime,

  /// Played often before, but not in the last [listeningListForgottenAfter].
  notPlayedLately,
}

const listeningListRecentWindow = Duration(days: 30);
const listeningListForgottenAfter = Duration(days: 60);

/// Plays a song needs before it counts as one the listener liked.
const listeningListForgottenMinPlays = 3;
const listeningListLimit = 50;

/// One song of a listening list, ready to play.
class ListeningListEntry {
  const ListeningListEntry({
    required this.item,
    required this.playCount,
    required this.lastPlayedAt,
  });

  final HomeRecommendationTrackItem item;
  final int playCount;
  final DateTime lastPlayedAt;

  TrackInfo get track => item.track;
}

/// The clock the listening lists measure their windows against.
final listeningListClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Empty while recommendation history is turned off, so the library does not
/// show what the listener asked not to keep.
final listeningListProvider = FutureProvider.autoDispose
    .family<List<ListeningListEntry>, ListeningListKind>((ref, kind) async {
      final enabled = ref.watch(
        settingsControllerProvider.select(
          (settings) => settings.value?.recommendationHistoryEnabled,
        ),
      );
      if (enabled != true) return const <ListeningListEntry>[];
      final database = ref.watch(databaseServiceProvider);
      final coordinator = ref.watch(libraryOperationCoordinatorProvider);
      final strings = ref.watch(appStringsProvider);
      final now = ref.watch(listeningListClockProvider)().toUtc();
      final seeds = await coordinator.runWithGate(
        () => switch (kind) {
          ListeningListKind.mostPlayedRecently => database.getMostPlayedTracks(
            limit: listeningListLimit,
            since: now.subtract(listeningListRecentWindow),
          ),
          ListeningListKind.mostPlayedAllTime => database.getMostPlayedTracks(
            limit: listeningListLimit,
          ),
          ListeningListKind.notPlayedLately => database.getMostPlayedTracks(
            limit: listeningListLimit,
            lastPlayedBefore: now.subtract(listeningListForgottenAfter),
            minPlayCount: listeningListForgottenMinPlays,
          ),
        },
      );
      return List<ListeningListEntry>.unmodifiable(
        seeds.map((seed) {
          final item = _homeTrackItemFromPersonalized(
            PersonalizedTrackItem.fromSeed(seed),
            strings,
          );
          return item == null
              ? null
              : ListeningListEntry(
                  item: item,
                  playCount: seed.playCount,
                  lastPlayedAt: seed.lastPlayedAt,
                );
        }).whereType<ListeningListEntry>(),
      );
    });

/// Loads the listener's [ListeningPreferences] from this device's history.
/// Empty while recommendation history is off or when the history cannot be
/// read: suggestions then keep YouTube's order.
final listeningPreferencesLoaderProvider =
    Provider<Future<ListeningPreferences> Function()>((ref) {
      return () async {
        final enabled = ref
            .read(settingsControllerProvider)
            .value
            ?.recommendationHistoryEnabled;
        if (enabled != true) return ListeningPreferences.empty;
        final database = ref.read(databaseServiceProvider);
        final coordinator = ref.read(libraryOperationCoordinatorProvider);
        final now = ref.read(listeningListClockProvider)().toUtc();
        try {
          return await coordinator.runWithGate(() async {
            final recentSince = now.subtract(ListeningPreferences.recentWindow);
            return ListeningPreferences.fromHistory(
              recentSkips: await database.getPlaybackSkipCounts(
                since: recentSince,
              ),
              recentPlays: await database.getMostPlayedTracks(
                limit: _listeningPreferencesScanLimit,
                since: recentSince,
              ),
              artistPlays: await database.getMostPlayedTracks(
                limit: _listeningPreferencesScanLimit,
                since: now.subtract(ListeningPreferences.artistWindow),
              ),
            );
          });
        } catch (error) {
          debugPrint('Listening preferences unavailable: $error');
          return ListeningPreferences.empty;
        }
      };
    });

const _listeningPreferencesScanLimit = 500;

/// The current [ListeningPreferences], for widgets that order suggestions.
final listeningPreferencesProvider =
    FutureProvider.autoDispose<ListeningPreferences>((ref) {
      ref.watch(
        settingsControllerProvider.select(
          (settings) => settings.value?.recommendationHistoryEnabled,
        ),
      );
      return ref.read(listeningPreferencesLoaderProvider)();
    });
