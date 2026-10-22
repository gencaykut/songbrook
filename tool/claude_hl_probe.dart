// Compares what the InnerTube parsers extract from live YouTube Music
// responses in two interface languages (hl). Run with:
//   dart run tool/claude_hl_probe.dart [hl...]
// Defaults to es-419 and tr, both with region TR.
import 'dart:io';

import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';

const _artists = <String>['Tarkan', 'Mabel Matiz', 'Sezen Aksu'];

Future<void> main(List<String> args) async {
  final languages = args.isEmpty ? const ['es-419', 'tr'] : args;
  for (final language in languages) {
    stdout.writeln('\n========== hl=$language ==========');
    final service = InnerTubeSearchService(language: language, region: 'TR');
    try {
      await _probe(service);
    } finally {
      service.dispose();
    }
  }
}

Future<void> _probe(InnerTubeSearchService s) async {
  Future<void> step(String name, Future<void> Function() body) async {
    try {
      await body();
    } on Object catch (error) {
      stdout.writeln('  !! $name failed: $error');
    }
  }

  await step('songs', () async {
    final songs = await s.searchSongs('Tarkan Kuzu Kuzu', limit: 3);
    for (final song in songs) {
      stdout.writeln(
        '  SONG ${song.title} | ${song.artists.join(', ')} | '
        'album=${song.album} | ${song.duration}',
      );
    }
  });

  await step('albums', () async {
    final albums = await s.searchAlbums('Sezen Aksu Gülümse', limit: 4);
    for (final album in albums) {
      stdout.writeln(
        '  ALBUM ${album.title} | ${album.artists.join(', ')} | '
        'year=${album.year} type=${album.type}',
      );
    }
    if (albums.isNotEmpty) {
      final tracks = await s.getAlbumSongs(albums.first.browseId);
      final missing = tracks.where((t) => t.duration == null).length;
      stdout.writeln(
        '  ALBUM_TRACKS ${albums.first.title}: ${tracks.length} '
        '(no duration: $missing) first=${tracks.isEmpty ? '-' : '${tracks.first.title} | ${tracks.first.artists.join(', ')}'}',
      );
    }
  });

  for (final name in _artists) {
    await step('artist $name', () async {
      final artist = (await s.searchArtists(name, limit: 1)).first;
      final profile = await s.getArtistProfile(artist.browseId);
      final singleTypes = profile.singles.map((a) => a.type).toSet();
      final albumTypes = profile.albums.map((a) => a.type).toSet();
      stdout.writeln(
        '  ARTIST ${profile.artist.name}: popular=${profile.popularSongs.length} '
        'albums=${profile.albums.length} $albumTypes '
        'singles=${profile.singles.length} $singleTypes '
        'related=${profile.relatedArtists.length} '
        'radio=${profile.radioPlaylistId != null} '
        'play=${profile.playPlaylistId != null} '
        'subs="${profile.subscriberCount}" '
        'monthly="${profile.monthlyListenerCount}" '
        'desc=${profile.description == null ? 0 : profile.description!.length}',
      );
      if (profile.popularSongs.isNotEmpty) {
        final first = profile.popularSongs.first;
        stdout.writeln(
          '    first popular: ${first.title} | ${first.artists.join(', ')} | '
          '${first.duration}',
        );
      }
    });
  }

  await step('home', () async {
    final sections = await s.getHome(maxSections: 6, maxItemsPerSection: 4);
    for (final section in sections) {
      stdout.writeln('  HOME "${section.title}" items=${section.items.length}');
    }
  });

  await step('moods', () async {
    final sections = await s.getMoodsAndGenres();
    stdout.writeln(
      '  MOODS sections=${sections.length} '
      '${sections.map((x) => '"${x.title}"').take(4).join(' ')}',
    );
  });

  await step('radio', () async {
    final seed = (await s.searchSongs('Mabel Matiz Umrumdışı', limit: 1)).first;
    final page = await s.getNext(seed.videoId, radio: true, limit: 10);
    stdout.writeln(
      '  RADIO ${page.songs.length} songs, first artists: '
      '${page.songs.take(3).map((x) => x.artists.join('/')).join(', ')}',
    );
  });
}
