import 'dart:io';

import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';

Future<void> main() async {
  final service = InnerTubeSearchService();
  try {
    for (final query in ['Tarkan Kuzu Kuzu', 'Daft Punk Get Lucky']) {
      final watch = Stopwatch()..start();
      final songs = await service.searchSongs(query, limit: 5);
      stdout.writeln(
        '"$query" -> ${songs.length} songs in ${watch.elapsedMilliseconds} ms',
      );
      for (final song in songs) {
        stdout.writeln(
          '  ${song.videoId}  ${song.title} — ${song.artists.join(', ')}  ${song.duration}',
        );
      }
    }
  } finally {
    service.dispose();
  }
}
