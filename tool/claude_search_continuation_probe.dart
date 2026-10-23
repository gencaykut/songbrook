import 'dart:convert';
import 'dart:io';

import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';

import 'innertube_playback_benchmark.dart'
    show bootstrapRawBenchmarkVisitorData;

/// Shows where YouTube Music puts search continuations and how deep they go.
///
/// Usage: dart run tool/claude_search_continuation_probe.dart [query]
Future<void> main(List<String> arguments) async {
  final query = arguments.isEmpty ? 'Tarkan' : arguments.join(' ');
  final transport = IoInnerTubeTransport(
    connectionTimeout: const Duration(seconds: 8),
  );
  final filters = <String, String>{
    'songs': InnerTubeSearchService.songsFilter,
    'albums': InnerTubeSearchService.albumsFilter,
    'playlists(community)': 'EgeKAQQoAEABagwQDhAKEAMQBBAJEAU%3D',
    'playlists(featured)': 'EgeKAQQoADgBagwQDhAKEAMQBBAJEAU%3D',
  };
  try {
    final visitorData = await bootstrapRawBenchmarkVisitorData(transport);
    Future<Map<String, dynamic>> post(Map<String, Object?> extra) async {
      final response = await transport.postJson(
        Uri.parse(
          'https://music.youtube.com/youtubei/v1/search?prettyPrint=false',
        ),
        headers: <String, String>{
          'Origin': 'https://music.youtube.com',
          'X-Goog-Visitor-Id': visitorData,
        },
        body: <String, Object?>{
          'context': <String, Object?>{
            'client': <String, Object?>{
              'clientName': 'WEB_REMIX',
              'clientVersion': '1.20251020.01.00',
              'hl': 'en',
              'gl': 'US',
              'visitorData': visitorData,
            },
          },
          ...extra,
        },
        timeout: const Duration(seconds: 12),
      );
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    for (final MapEntry(key: name, value: params) in filters.entries) {
      stdout.writeln('\n== $name "$query"');
      var page = await post(<String, Object?>{
        'query': query,
        'params': Uri.decodeComponent(params),
      });
      var total = 0;
      for (var pageIndex = 0; pageIndex < 6; pageIndex++) {
        final items = _countKeys(page, 'musicResponsiveListItemRenderer');
        total += items;
        final tokens = <String>[];
        _collectTokens(page, r'$', tokens);
        stdout.writeln(
          '  page $pageIndex: items=$items total=$total '
          'topKeys=${page.keys.where((k) => k != 'responseContext').toList()} '
          'tokens=${tokens.map((t) => t.split('=').first).toList()}',
        );
        if (tokens.isEmpty) break;
        final token = tokens.first.split('=').last;
        page = await post(<String, Object?>{'continuation': token});
      }
    }
    await _probeService(query);
  } finally {
    transport.close();
  }
}

/// Pages through the app's own paged search API, as the Search view does.
Future<void> _probeService(String query) async {
  final service = InnerTubeSearchService(language: 'tr', region: 'TR');
  try {
    Future<void> pages<T>(
      String name,
      Future<InnerTubeSearchResultPage<T>> Function(String? token) load,
      String Function(T item) key,
    ) async {
      final seen = <String>{};
      String? token;
      var duplicates = 0;
      for (var page = 0; page < 4; page++) {
        final result = await load(token);
        for (final item in result.items) {
          if (!seen.add(key(item))) duplicates++;
        }
        stdout.writeln(
          '  service $name page $page: +${result.items.length} '
          'unique=${seen.length} duplicates=$duplicates '
          'next=${result.continuation != null}',
        );
        token = result.continuation;
        if (token == null) break;
      }
    }

    stdout.writeln('\n== service (hl=tr) "$query"');
    await pages<InnerTubeSong>(
      'songs',
      (token) => service.searchSongsPage(query, continuation: token),
      (song) => song.videoId,
    );
    await pages<InnerTubePlaylist>(
      'playlists',
      (token) => service.searchPlaylistsPage(query, continuation: token),
      (playlist) => playlist.browseId,
    );
    final first = (await service.searchPlaylistsPage(query)).items.take(3);
    for (final playlist in first) {
      stdout.writeln(
        '    ${playlist.browseId} "${playlist.title}" — ${playlist.subtitle}',
      );
    }
  } finally {
    service.dispose();
  }
}

int _countKeys(Object? node, String key) {
  if (node is Map) {
    var count = node.containsKey(key) ? 1 : 0;
    for (final value in node.values) {
      count += _countKeys(value, key);
    }
    return count;
  }
  if (node is List) {
    return node.fold(0, (sum, value) => sum + _countKeys(value, key));
  }
  return 0;
}

void _collectTokens(Object? node, String path, List<String> out) {
  if (node is Map) {
    for (final entry in node.entries) {
      final key = '${entry.key}';
      if ((key == 'continuation' || key == 'token') && entry.value is String) {
        out.add('$path.$key=${entry.value}');
      } else {
        _collectTokens(entry.value, '$path.$key', out);
      }
    }
  } else if (node is List) {
    for (var i = 0; i < node.length; i++) {
      _collectTokens(node[i], '$path[$i]', out);
    }
  }
}
