part of 'music_providers.dart';

/// Resolves the stream of the first songs on Home's "Continue listening" once
/// per launch, so the first tap starts sooner. Only the stream address is
/// fetched, never audio; the resolver keeps it for 20 minutes, also across a
/// restart, and a tap during the work joins it.
final continueListeningPrewarmProvider = Provider<ContinueListeningPrewarmer>((
  ref,
) {
  return ContinueListeningPrewarmer(
    resolve: (track) => ref.mounted
        ? ref.read(remoteTrackResolverProvider).resolve(track)
        : Future<TrackInfo>.value(track),
    // A disposed scope (the app closing) has nothing left to prepare for.
    playbackIsStarting: () =>
        !ref.mounted ||
        ref.read(playerControllerProvider).value?.status ==
            PlayerStatus.loading,
  );
});

class ContinueListeningPrewarmer {
  ContinueListeningPrewarmer({
    required this._resolve,
    required this._playbackIsStarting,
    this.delay = const Duration(milliseconds: 1500),
  });

  /// Songs resolved ahead; the first shelf cards are what is tapped.
  static const songCount = 3;

  /// Waited before starting, so Home's own requests go first.
  final Duration delay;

  final Future<TrackInfo> Function(TrackInfo track) _resolve;
  final bool Function() _playbackIsStarting;
  bool _started = false;

  /// Starts once, with the first [sections] that have streamed songs on
  /// "Continue listening". Downloaded songs play from their file and are
  /// skipped.
  Future<void> maybePrewarm(List<HomeRecommendationSection> sections) async {
    if (_started) return;
    final tracks = [
      for (final section in sections)
        if (section.isContinueListening)
          for (final item in section.items)
            if (item is HomeRecommendationTrackItem &&
                item.localTrackId == null &&
                item.track.url.trim().isNotEmpty)
              item.track,
    ].take(songCount).toList(growable: false);
    if (tracks.isEmpty) return;
    _started = true;
    await Future<void>.delayed(delay);
    // A song already loading (a restored or linked queue) gets the network.
    if (_playbackIsStarting()) return;
    for (final track in tracks) {
      try {
        await _resolve(track);
      } catch (error) {
        // Optional: a tap resolves the song again.
        debugPrint('Continue listening prewarm failed: $error');
      }
    }
  }
}
