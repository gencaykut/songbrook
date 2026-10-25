import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// A part of a video that SponsorBlock contributors marked as not music.
class SponsorBlockSegment {
  const SponsorBlockSegment({required this.start, required this.end});

  final Duration start;
  final Duration end;
}

/// Reads SponsorBlock's community segments (https://sponsor.ajay.app, data
/// under CC BY-NC-SA 4.0) for the `music_offtopic` category: intros, skits
/// and talking in music videos.
///
/// For privacy the request names only the first four hex characters of the
/// video id's SHA-256 hash. The server answers for every video in that
/// bucket and the matching video is picked here, so it never learns which
/// video is playing. Answers are kept for the session; a failed request is
/// forgotten so a later play can try again.
class SponsorBlockClient {
  SponsorBlockClient({
    HttpClient Function()? clientFactory,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 6),
  }) : _clientFactory = clientFactory ?? HttpClient.new,
       _baseUri = baseUri ?? Uri.parse('https://sponsor.ajay.app');

  final HttpClient Function() _clientFactory;
  final Uri _baseUri;
  final Duration timeout;
  final _segments = <String, Future<List<SponsorBlockSegment>>>{};

  Future<List<SponsorBlockSegment>> musicOffTopicSegments(String videoId) {
    return _segments.putIfAbsent(videoId, () async {
      try {
        return await _load(videoId).timeout(timeout);
      } catch (_) {
        _segments.remove(videoId);
        rethrow;
      }
    });
  }

  Future<List<SponsorBlockSegment>> _load(String videoId) async {
    final prefix = sha256
        .convert(utf8.encode(videoId))
        .toString()
        .substring(0, 4);
    final uri = _baseUri.replace(
      path: '/api/skipSegments/$prefix',
      queryParameters: const {
        'categories': '["music_offtopic"]',
        'actionTypes': '["skip"]',
      },
    );
    final client = _clientFactory()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      // No video in the bucket has segments.
      if (response.statusCode == HttpStatus.notFound) return const [];
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'SponsorBlock HTTP ${response.statusCode}',
          uri: uri,
        );
      }
      return parseSponsorBlockSegments(jsonDecode(body), videoId: videoId);
    } finally {
      client.close(force: true);
    }
  }

  void close() => _segments.clear();
}

/// Picks [videoId]'s skippable `music_offtopic` segments out of a hash
/// bucket response.
List<SponsorBlockSegment> parseSponsorBlockSegments(
  Object? decoded, {
  required String videoId,
}) {
  if (decoded is! List) return const [];
  for (final video in decoded) {
    if (video is! Map || video['videoID'] != videoId) continue;
    final segments = <SponsorBlockSegment>[];
    for (final entry in video['segments'] as List? ?? const []) {
      if (entry is! Map ||
          entry['category'] != 'music_offtopic' ||
          (entry['actionType'] ?? 'skip') != 'skip') {
        continue;
      }
      final range = entry['segment'];
      if (range is! List || range.length != 2) continue;
      final start = range[0], end = range[1];
      if (start is! num || end is! num || end <= start || start < 0) continue;
      segments.add(
        SponsorBlockSegment(
          start: Duration(milliseconds: (start * 1000).round()),
          end: Duration(milliseconds: (end * 1000).round()),
        ),
      );
    }
    segments.sort((left, right) => left.start.compareTo(right.start));
    return segments;
  }
  return const [];
}
