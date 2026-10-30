import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:bstream_music/features/music/presentation/providers/player/personalized_queue_extender.dart';
import 'package:bstream_music/services/recommendations/recommendations.dart';
import 'package:flutter_test/flutter_test.dart';

RecommendationPlaybackItem _item(String videoId, {String artist = 'Artist'}) =>
    RecommendationPlaybackItem(
      track: TrackInfo(
        id: videoId,
        title: 'Song $videoId',
        artist: artist,
        artists: [artist],
        url: 'https://www.youtube.com/watch?v=$videoId',
      ),
    );

List<String> _ids(List<RecommendationPlaybackItem> items) =>
    items.map((item) => item.track.id).toList();

void main() {
  test('keeps the picked songs and orders only what radio adds', () async {
    final pages = [
      [
        _item('picked00001', artist: 'Avoided'),
        _item('picked00002'),
        _item('radio000001', artist: 'Avoided'),
        _item('skipped0001'),
        _item('radio000002'),
      ],
      [
        _item('picked00001', artist: 'Avoided'),
        _item('picked00002'),
        _item('radio000001', artist: 'Avoided'),
        _item('skipped0001'),
        _item('radio000002'),
        _item('radio000003'),
        _item('skipped0001'),
      ],
    ];
    var call = 0;
    var preferenceLoads = 0;
    final extender = personalizeQueueExtender(
      () async => pages[call++],
      keepFirst: 2,
      preferences: () async {
        preferenceLoads += 1;
        return const ListeningPreferences(
          rejectedTrackKeys: {'skipped0001'},
          avoidedArtists: {'avoided'},
        );
      },
    );

    expect(_ids(await extender()), [
      'picked00001',
      'picked00002',
      'radio000002',
      'radio000001',
    ]);
    // Songs returned before are never moved; only the new page is ordered.
    expect(_ids(await extender()), [
      'picked00001',
      'picked00002',
      'radio000002',
      'radio000001',
      'radio000003',
    ]);
    expect(preferenceLoads, 2);
  });

  test('without preferences the extender is unchanged', () async {
    final items = [_item('a0000000001'), _item('b0000000001')];
    final extender = personalizeQueueExtender(
      () async => items,
      keepFirst: 1,
      preferences: () async => ListeningPreferences.empty,
    );

    expect(_ids(await extender()), _ids(items));
  });
}
