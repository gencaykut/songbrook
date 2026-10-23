import 'dart:convert';
import 'dart:io';

import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_client_profile.dart';

import 'innertube_playback_benchmark.dart'
    show bootstrapRawBenchmarkVisitorData;

/// Prints the loudness metadata YouTube returns in live player responses.
///
/// Usage: dart run tool/claude_loudness_probe.dart [search query ...]
/// For each query's first song it prints `playerConfig.audioConfig` and every
/// audio format's loudness fields, per tokenless client profile.
Future<void> main(List<String> arguments) async {
  final queries = arguments.isNotEmpty
      ? arguments
      : const [
          'Ludovico Einaudi Nuvole Bianche',
          'Metallica Enter Sandman',
          'Tarkan Kuzu Kuzu',
        ];
  final search = InnerTubeSearchService();
  final transport = IoInnerTubeTransport(
    connectionTimeout: const Duration(seconds: 8),
  );
  const profiles = [
    InnerTubeClientRegistry.visionOS,
    InnerTubeClientRegistry.androidSdkless,
    InnerTubeClientRegistry.visionOS01,
  ];
  try {
    final visitorData = await bootstrapRawBenchmarkVisitorData(transport);
    for (final query in queries) {
      final songs = await search.searchSongs(query, limit: 1);
      if (songs.isEmpty) {
        stdout.writeln('"$query": no song');
        continue;
      }
      final song = songs.first;
      stdout.writeln('\n"$query" -> ${song.videoId} ${song.title}');
      for (final profile in profiles) {
        final raw = await transport.postJson(
          profile.playerEndpoint,
          headers: <String, String>{
            ...profile.requestHeaders,
            'X-Goog-Visitor-Id': visitorData,
          },
          body: <String, Object?>{
            'context': profile.buildContext(visitorData: visitorData),
            'videoId': song.videoId,
            'contentCheckOk': true,
            'racyCheckOk': true,
          },
          timeout: const Duration(seconds: 12),
        );
        final decoded = jsonDecode(raw.body) as Map<String, dynamic>;
        final audioConfig =
            (decoded['playerConfig'] as Map?)?['audioConfig'] as Map?;
        stdout.writeln(
          '  ${profile.key} HTTP ${raw.statusCode} '
          '${(decoded['playabilityStatus'] as Map?)?['status']} '
          'audioConfig=$audioConfig',
        );
        final formats =
            ((decoded['streamingData'] as Map?)?['adaptiveFormats'] as List?) ??
            const [];
        for (final format in formats.cast<Map>()) {
          final mime = '${format['mimeType']}';
          if (!mime.startsWith('audio/')) continue;
          final loudKeys = {
            for (final entry in format.entries)
              if ('${entry.key}'.toLowerCase().contains('loud') ||
                  '${entry.key}'.toLowerCase().contains('drc'))
                entry.key: entry.value,
          };
          stdout.writeln(
            '    itag ${format['itag']} ${mime.split(';').first} $loudKeys',
          );
        }
      }
    }
  } finally {
    transport.close();
    search.dispose();
  }
}
