import 'package:bstream_music/services/sponsorblock/sponsorblock_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('picks the playing video out of its hash bucket', () {
    final segments = parseSponsorBlockSegments([
      {
        'videoID': 'otherVideo1',
        'segments': [
          {
            'segment': [0, 30],
            'category': 'music_offtopic',
            'actionType': 'skip',
          },
        ],
      },
      {
        'videoID': 'playingVid1',
        'segments': [
          {
            'segment': [249.38, 281.521],
            'category': 'music_offtopic',
            'actionType': 'skip',
          },
          {
            'segment': [0, 21.808],
            'category': 'music_offtopic',
            'actionType': 'skip',
          },
          {
            'segment': [40, 50],
            'category': 'sponsor',
            'actionType': 'skip',
          },
          {
            'segment': [60, 60],
            'category': 'music_offtopic',
            'actionType': 'skip',
          },
          {
            'segment': [70, 80],
            'category': 'music_offtopic',
            'actionType': 'mute',
          },
        ],
      },
    ], videoId: 'playingVid1');

    expect(segments.map((segment) => [segment.start, segment.end]), [
      [Duration.zero, const Duration(milliseconds: 21808)],
      [
        const Duration(milliseconds: 249380),
        const Duration(milliseconds: 281521),
      ],
    ]);
  });

  test('a bucket without the video has nothing to skip', () {
    expect(
      parseSponsorBlockSegments([
        {'videoID': 'otherVideo1', 'segments': []},
      ], videoId: 'playingVid1'),
      isEmpty,
    );
    expect(parseSponsorBlockSegments('not a list', videoId: 'x'), isEmpty);
  });
}
