import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Resolves live music videos through the app's remote resolver and prints
/// whether it switched to the song version, and how long that took.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('music videos play their song versions', (_) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(settingsControllerProvider.future);
    final search =
        container.read(youtubeMusicSearchProvider) as YouTubeMusicCatalogSearch;
    final videos = [
      for (final query in const ['Tarkan', 'Mabel Matiz', 'Duman'])
        ...await search.searchVideos(query, limit: 4),
    ];
    var switched = 0;
    for (final video in videos) {
      final track = TrackInfo(
        id: video.videoId,
        title: video.title,
        artist: video.artist,
        artists: video.artists,
        url: 'https://www.youtube.com/watch?v=${video.videoId}',
        duration: video.duration,
      );
      final watch = Stopwatch()..start();
      final resolved = await container
          .read(remoteTrackResolverProvider)
          .resolve(track);
      final streamVideo = Uri.parse(resolved.streamUrl ?? '').toString();
      final played = RegExp(r'[?&]id=o-').hasMatch(streamVideo)
          ? 'signed'
          : 'url';
      final song = await container
          .read(songCounterpartFinderProvider)
          .find(track, videoDuration: video.duration);
      if (song != null) switched++;
      // ignore: avoid_print
      print(
        'CLAUDE_SONG video=${video.videoId} "${video.title}" / ${video.artist} '
        '${video.duration} -> song=${song?.videoId} "${song?.title}" '
        '${song?.duration} ms=${watch.elapsedMilliseconds} $played',
      );
    }
    // ignore: avoid_print
    print('CLAUDE_SONG switched $switched of ${videos.length}');
  });
}
