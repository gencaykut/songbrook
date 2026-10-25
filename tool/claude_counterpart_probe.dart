import 'dart:convert';
import 'dart:io';

import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';

import 'innertube_playback_benchmark.dart'
    show bootstrapRawBenchmarkVisitorData;

/// Shows how YouTube Music pairs a music video with its song (ATV) version
/// in the watch-next response, the source of the app's Song/Video switch.
///
/// Usage: dart run tool/claude_counterpart_probe.dart [query]
Future<void> main(List<String> arguments) async {
  final query = arguments.isEmpty ? 'Tarkan' : arguments.join(' ');
  final search = InnerTubeSearchService();
  final transport = IoInnerTubeTransport(
    connectionTimeout: const Duration(seconds: 8),
  );
  try {
    final videos = await search.searchVideos(query, limit: 6);
    final songs = await search.searchSongs(query, limit: 3);
    final visitorData = await bootstrapRawBenchmarkVisitorData(transport);
    final home = await HttpClient()
        .getUrl(Uri.parse('https://music.youtube.com/'))
        .then((request) {
          request.headers.set(
            'User-Agent',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
                '(KHTML, like Gecko) Version/18.0 Safari/605.1.15',
          );
          return request.close();
        })
        .then((response) => response.transform(utf8.decoder).join());
    final clientVersion =
        RegExp(
          r'"INNERTUBE_CLIENT_VERSION":"([^"]+)"',
        ).firstMatch(home)?.group(1) ??
        '1.20251020.01.00';
    stdout.writeln('clientVersion=$clientVersion');
    for (final (kind, id, title) in [
      for (final video in videos) ('video', video.videoId, video.title),
      for (final song in songs) ('song', song.videoId, song.title),
    ]) {
      final response = await transport.postJson(
        Uri.parse(
          'https://music.youtube.com/youtubei/v1/next?prettyPrint=false',
        ),
        headers: <String, String>{
          'Origin': 'https://music.youtube.com',
          'X-Goog-Visitor-Id': visitorData,
        },
        body: <String, Object?>{
          'context': <String, Object?>{
            'client': <String, Object?>{
              'clientName': 'WEB_REMIX',
              'clientVersion': clientVersion,
              'hl': 'en',
              'gl': 'US',
              'visitorData': visitorData,
            },
          },
          'videoId': id,
          'playlistId': 'RDAMVM$id',
        },
        timeout: const Duration(seconds: 12),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final first = _first(json, 'playlistPanelVideoWrapperRenderer');
      final plain = _first(json, 'playlistPanelVideoRenderer');
      stdout.writeln('\n== $kind $id "$title" (HTTP ${response.statusCode})');
      if (first is Map<String, dynamic>) {
        final primary = first['primaryRenderer']?['playlistPanelVideoRenderer'];
        stdout.writeln('  wrapper primary: ${_describe(primary)}');
        for (final counterpart in (first['counterpart'] as List? ?? const [])) {
          final renderer =
              counterpart['counterpartRenderer']?['playlistPanelVideoRenderer'];
          stdout.writeln(
            '  counterpart: ${_describe(renderer)} '
            'segmentMap=${counterpart['segmentMap'] != null}',
          );
        }
      } else {
        stdout.writeln('  no wrapper; first item: ${_describe(plain)}');
      }
    }
  } finally {
    transport.close();
    search.dispose();
  }
}

String _describe(Object? renderer) {
  if (renderer is! Map<String, dynamic>) return 'none';
  final endpoint = renderer['navigationEndpoint']?['watchEndpoint'];
  final type =
      endpoint?['watchEndpointMusicSupportedConfigs']?['watchEndpointMusicConfig']?['musicVideoType'];
  final title = (renderer['title']?['runs'] as List?)?.first?['text'];
  final length = (renderer['lengthText']?['runs'] as List?)?.first?['text'];
  return '${renderer['videoId']} type=$type length=$length "$title"';
}

Object? _first(Object? node, String key) {
  if (node is Map<String, dynamic>) {
    if (node.containsKey(key)) return node[key];
    for (final value in node.values) {
      final found = _first(value, key);
      if (found != null) return found;
    }
  } else if (node is List) {
    for (final value in node) {
      final found = _first(value, key);
      if (found != null) return found;
    }
  }
  return null;
}
