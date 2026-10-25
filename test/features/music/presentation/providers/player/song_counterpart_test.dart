import 'package:bstream_music/features/music/domain/entities/track_info.dart';
import 'package:bstream_music/features/music/presentation/providers/player/song_counterpart.dart';
import 'package:bstream_music/services/youtube_music/innertube_models.dart';
import 'package:flutter_test/flutter_test.dart';

TrackInfo _video(String title, String artist, {String id = 'video000001'}) =>
    TrackInfo(id: id, title: title, artist: artist, url: '');

InnerTubeSong _song(
  String id,
  String title,
  List<String> artists,
  int seconds,
) => InnerTubeSong(
  videoId: id,
  title: title,
  artists: artists,
  duration: Duration(seconds: seconds),
);

void main() {
  test('only Topic channels publish song versions', () {
    expect(isSongVersionChannel('Tarkan - Topic'), isTrue);
    expect(isSongVersionChannel('Tarkan'), isFalse);
    expect(isSongVersionChannel('LiveYourMusicChannel'), isFalse);
  });

  test('titles drop video labels and featured credits but keep versions', () {
    expect(
      normalizeSongTitle(
        'TARKAN - Verme (Official Music Video)',
        artists: {'tarkan'},
      ),
      'verme',
    );
    expect(
      normalizeSongTitle(
        'Sezen Aksu - Ey Aşk [Official Audio]',
        artists: {'sezen aksu'},
      ),
      'ey ask',
    );
    expect(normalizeSongTitle('Hop De (con Tarkan)'), 'hop de');
    expect(normalizeSongTitle('Magic feat. Someone'), 'magic');
    expect(
      normalizeSongTitle('Training Season (Live)'),
      'training season live',
    );
    expect(normalizeSongTitle('Lan (Akustik)'), 'lan akustik');
    expect(normalizeSongTitle('SIMARIK'), normalizeSongTitle('Şımarık'));
  });

  test('matches the song version of an official video', () {
    final match = matchSongCounterpart(
      video: _video('Verme', 'Tarkan'),
      videoDuration: const Duration(minutes: 4, seconds: 57),
      candidates: [
        _song('oNWQyzKZ0us', 'Verme', ['Tarkan'], 297),
        _song('YTuIfkHjIMg', 'Yandım', ['Tarkan'], 193),
      ],
    );
    expect(match?.videoId, 'oNWQyzKZ0us');
  });

  test('a long video intro still matches a shorter song', () {
    final match = matchSongCounterpart(
      video: _video('Ha Leylim', 'Mabel Matiz'),
      videoDuration: const Duration(minutes: 4, seconds: 55),
      candidates: [
        _song('OW666AK0_YA', 'Ha Leylim', ['Mabel Matiz'], 217),
      ],
    );
    expect(match?.videoId, 'OW666AK0_YA');
  });

  test('a co-credited song matches either artist', () {
    final match = matchSongCounterpart(
      video: _video('Scared To Be Lonely', 'Dua Lipa, Martin Garrix'),
      videoDuration: const Duration(minutes: 3, seconds: 51),
      candidates: [
        _song('vFFT1iAUNDE', 'Scared to Be Lonely', [
          'Martin Garrix',
          'Dua Lipa',
        ], 221),
      ],
    );
    expect(match?.videoId, 'vFFT1iAUNDE');
  });

  test('a lyric video from another channel matches by its title artist', () {
    final match = matchSongCounterpart(
      video: _video(
        'Mabel Matiz - Ha Leylim (Şarkı Sözleri / Lyrics)',
        'Şarkı Sözleri Kütüphanesi',
      ),
      videoDuration: const Duration(minutes: 3, seconds: 42),
      candidates: [
        _song('OW666AK0_YA', 'Ha Leylim', ['Mabel Matiz'], 217),
      ],
    );
    expect(match?.videoId, 'OW666AK0_YA');
  });

  test('a remix upload is not the song', () {
    expect(
      matchSongCounterpart(
        video: _video(
          'Uzi x Mabel Matiz x Organize - Boyalıda Saçların | TikTok Mix',
          'Jiyan Beats',
        ),
        videoDuration: const Duration(minutes: 4, seconds: 27),
        candidates: [
          _song('song0000001', 'Boyalıda Saçların', [
            'Uzi',
            'Mabel Matiz',
          ], 200),
        ],
      ),
      isNull,
    );
  });

  test('covers, other versions and other songs are not matches', () {
    // A cover by someone else.
    expect(
      matchSongCounterpart(
        video: _video('Magic', 'Coldplay'),
        videoDuration: const Duration(minutes: 5, seconds: 16),
        candidates: [
          _song('s4X8MsCZi14', 'Magic', ['Relax α Wave'], 301),
        ],
      ),
      isNull,
    );
    // The live video is not the studio song.
    expect(
      matchSongCounterpart(
        video: _video('Training Season (Live)', 'Dua Lipa'),
        videoDuration: const Duration(minutes: 3, seconds: 34),
        candidates: [
          _song('n0GXk_T2zs8', 'Training Season', ['Dua Lipa'], 210),
        ],
      ),
      isNull,
    );
    // Another song by the same artist.
    expect(
      matchSongCounterpart(
        video: _video('Sezen Aksu - Ey Aşk [Official Audio]', 'Sezen Aksu'),
        videoDuration: const Duration(minutes: 4, seconds: 8),
        candidates: [
          _song('r0Sc0oqeUjk', 'Kavaklar', ['Sezen Aksu'], 291),
        ],
      ),
      isNull,
    );
    // A much longer album edit of a video.
    expect(
      matchSongCounterpart(
        video: _video('Kır Zincirlerini', 'Tarkan'),
        videoDuration: const Duration(minutes: 3, seconds: 52),
        candidates: [
          _song('WKsrPoB86h0', 'Kır Zincirlerini', ['Tarkan'], 324),
        ],
      ),
      isNull,
    );
  });
}
