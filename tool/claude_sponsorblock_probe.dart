import 'dart:io';

import 'package:bstream_music/services/sponsorblock/sponsorblock_client.dart';

/// Prints SponsorBlock's music_offtopic segments for the given videos.
///
/// Usage: dart run tool/claude_sponsorblock_probe.dart [videoId...]
Future<void> main(List<String> arguments) async {
  final client = SponsorBlockClient();
  final ids = arguments.isEmpty
      ? const [
          'UCUm7TZ5odo',
          'SCZgGVqVsbY',
          'kJQP7kiw5Fk',
          'fJ9rUzIMcZQ',
          'JGwWNGJdvx8',
        ]
      : arguments;
  for (final id in ids) {
    try {
      final segments = await client.musicOffTopicSegments(id);
      stdout.writeln(
        '$id: ${segments.map((s) => '${s.start}-${s.end}').join(', ')}'
        '${segments.isEmpty ? 'none' : ''}',
      );
    } catch (error) {
      stdout.writeln('$id: error $error');
    }
  }
  client.close();
}
