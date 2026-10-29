import 'dart:async';
import 'dart:io';

import 'package:bstream_music/services/sponsorblock/sponsorblock_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// A server that reads requests but never answers, and reports when the
/// client closes its connection.
class _SilentServer {
  _SilentServer._(this._socket);

  final ServerSocket _socket;
  final requests = StreamController<void>.broadcast();
  final closed = StreamController<void>.broadcast();
  int open = 0;

  static Future<_SilentServer> start() async {
    final server = _SilentServer._(
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
    );
    server._socket.listen((connection) {
      server.open++;
      connection.listen(
        (_) => server.requests.add(null),
        onDone: () {
          server.open--;
          server.closed.add(null);
          connection.destroy();
        },
        onError: (_) {},
      );
    });
    return server;
  }

  Uri get uri => Uri.parse('http://127.0.0.1:${_socket.port}');

  Future<void> stop() => _socket.close();
}

void main() {
  test('a request that times out closes its connection', () async {
    final server = await _SilentServer.start();
    addTearDown(server.stop);
    final client = SponsorBlockClient(
      baseUri: server.uri,
      timeout: const Duration(milliseconds: 200),
    );
    addTearDown(client.close);
    final closed = server.closed.stream.first;

    await expectLater(
      client.musicOffTopicSegments('video00001'),
      throwsA(isA<TimeoutException>()),
    );

    await closed.timeout(const Duration(seconds: 2));
    expect(server.open, 0);
  });

  test('closing the client closes a request still waiting', () async {
    final server = await _SilentServer.start();
    addTearDown(server.stop);
    final client = SponsorBlockClient(
      baseUri: server.uri,
      timeout: const Duration(minutes: 1),
    );
    final requested = server.requests.stream.first;
    final closed = server.closed.stream.first;
    final pending = client.musicOffTopicSegments('video00001');
    unawaited(pending.then((_) {}, onError: (_) {}));
    await requested.timeout(const Duration(seconds: 2));

    client.close();

    await closed.timeout(const Duration(seconds: 2));
    expect(server.open, 0);
  });

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
