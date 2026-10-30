import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/services/recommendations/recommendations.dart';
import 'package:flutter_test/flutter_test.dart';

HomeRecommendationTrackItem _item(String videoId, {String? localTrackId}) =>
    HomeRecommendationTrackItem(
      TrackInfo(
        id: videoId,
        title: 'Song $videoId',
        artist: 'Artist',
        url: 'https://www.youtube.com/watch?v=$videoId',
      ),
      localTrackId: localTrackId,
    );

HomeRecommendationSection _section(
  PersonalizedSectionKind kind,
  List<HomeRecommendationItem> items,
) => HomeRecommendationSection.items(
  title: kind.name,
  personalizedKind: kind,
  items: items,
);

void main() {
  test('resolves the first streamed Continue songs once, in order', () async {
    final resolved = <String>[];
    final prewarmer = ContinueListeningPrewarmer(
      resolve: (track) async {
        resolved.add(track.id);
        if (track.id == 'failing0001') throw StateError('offline');
        return track;
      },
      playbackIsStarting: () => false,
      delay: Duration.zero,
    );
    final sections = [
      _section(PersonalizedSectionKind.becauseYouListened, [
        _item('because0001'),
      ]),
      _section(PersonalizedSectionKind.continueListening, [
        _item('downloaded1', localTrackId: 'local-1'),
        _item('failing0001'),
        _item('stream00001'),
        _item('stream00002'),
        _item('stream00003'),
      ]),
    ];

    await prewarmer.maybePrewarm(sections);
    await prewarmer.maybePrewarm(sections);

    // A failure does not stop the rest; downloaded songs and other shelves
    // are left alone; a second call does nothing.
    expect(resolved, ['failing0001', 'stream00001', 'stream00002']);
  });

  test(
    'waits for a Home with Continue songs before using its one turn',
    () async {
      final resolved = <String>[];
      final prewarmer = ContinueListeningPrewarmer(
        resolve: (track) async {
          resolved.add(track.id);
          return track;
        },
        playbackIsStarting: () => false,
        delay: Duration.zero,
      );

      await prewarmer.maybePrewarm(const []);
      await prewarmer.maybePrewarm([
        _section(PersonalizedSectionKind.continueListening, [
          _item('stream00001'),
        ]),
      ]);

      expect(resolved, ['stream00001']);
    },
  );

  test('leaves the network to a song that is already loading', () async {
    final resolved = <String>[];
    final prewarmer = ContinueListeningPrewarmer(
      resolve: (track) async {
        resolved.add(track.id);
        return track;
      },
      playbackIsStarting: () => true,
      delay: Duration.zero,
    );

    await prewarmer.maybePrewarm([
      _section(PersonalizedSectionKind.continueListening, [
        _item('stream00001'),
      ]),
    ]);

    expect(resolved, isEmpty);
  });
}
