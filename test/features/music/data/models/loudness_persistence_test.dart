import 'package:bstream_music/features/music/data/models/local_track_model.dart';
import 'package:bstream_music/features/music/data/models/track_info_model.dart';
import 'package:bstream_music/features/music/domain/entities/local_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('track info keeps its loudness through JSON', () {
    final track = TrackInfoModel.fromJson(const <String, dynamic>{
      'id': 'abc',
      'title': 'Title',
      'artist': 'Artist',
      'url': 'https://www.youtube.com/watch?v=abc',
      'loudness_db': 2.07,
    });
    expect(track.loudnessDb, 2.07);
    expect(TrackInfoModel.fromJson(track.toJson()).loudnessDb, 2.07);
  });

  test('a downloaded track keeps its loudness in the library row', () {
    final track = LocalTrack(
      id: 'remote-1',
      title: 'Title',
      artist: 'Artist',
      filePath: '/music/remote-1.m4a',
      addedAt: DateTime(2026),
      loudnessDb: -8.16,
    );
    final row = LocalTrackModel.fromEntity(track).toMap();
    expect(row['loudness_db'], -8.16);
    expect(LocalTrackModel.fromMap(row).loudnessDb, -8.16);
    expect(
      LocalTrackModel.fromMap({...row, 'loudness_db': null}).loudnessDb,
      isNull,
      reason: 'Downloads made before the column existed stay unnormalized.',
    );
  });
}
