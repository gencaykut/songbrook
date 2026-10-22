import 'dart:io';
import 'dart:typed_data';

import 'package:bstream_music/services/player/fragmented_mp4_duration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseFragmentedMp4MoovDuration', () {
    test('reads the mvhd duration of a fragmented file', () {
      // YouTube itag 140: 9048960 / 44100 = 205.191836 s.
      final moov = _concat([
        _mvhd(timescale: 44100, duration: 9048960),
        _mvex(),
      ]);

      expect(
        parseFragmentedMp4MoovDuration(moov),
        const Duration(microseconds: 205191836),
      );
    });

    test('reads a version 1 mvhd', () {
      final moov = _concat([
        _mvhd(timescale: 1000, duration: 180500, version: 1),
        _mvex(),
      ]);

      expect(
        parseFragmentedMp4MoovDuration(moov),
        const Duration(milliseconds: 180500),
      );
    });

    test('falls back to mehd when mvhd declares no duration', () {
      final moov = _concat([
        _mvhd(timescale: 48000, duration: 0),
        _mvex(fragmentDuration: 48000 * 90),
      ]);

      expect(parseFragmentedMp4MoovDuration(moov), const Duration(seconds: 90));
    });

    test('ignores files that are not fragmented', () {
      final moov = _mvhd(timescale: 44100, duration: 9048960);

      expect(parseFragmentedMp4MoovDuration(moov), isNull);
    });

    test('ignores fragmented files without any duration', () {
      final moov = _concat([_mvhd(timescale: 44100, duration: 0), _mvex()]);

      expect(parseFragmentedMp4MoovDuration(moov), isNull);
    });

    test('ignores a zero timescale', () {
      final moov = _concat([_mvhd(timescale: 0, duration: 1000), _mvex()]);

      expect(parseFragmentedMp4MoovDuration(moov), isNull);
    });

    test('rejects a truncated mvhd', () {
      final moov = _concat([_box('mvhd', Uint8List(10)), _mvex()]);

      expect(parseFragmentedMp4MoovDuration(moov), isNull);
    });
  });

  group('readFragmentedMp4Duration', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('bstream_fmp4_');
    });

    tearDown(() async {
      await directory.delete(recursive: true);
    });

    Future<String> write(String name, List<Uint8List> boxes) async {
      final file = File('${directory.path}/$name');
      await file.writeAsBytes(_concat(boxes));
      return file.path;
    }

    test('finds moov after ftyp in a downloaded file', () async {
      final path = await write('song.m4a', [
        _box('ftyp', Uint8List(16)),
        _box(
          'moov',
          _concat([_mvhd(timescale: 44100, duration: 9048960), _mvex()]),
        ),
        _box('sidx', Uint8List(24)),
        _box('moof', Uint8List(32)),
        _box('mdat', Uint8List(256)),
      ]);

      expect(
        readFragmentedMp4Duration(path),
        const Duration(microseconds: 205191836),
      );
    });

    test('stops at media data before any moov', () async {
      final path = await write('late.m4a', [
        _box('ftyp', Uint8List(16)),
        _box('mdat', Uint8List(256)),
        _box(
          'moov',
          _concat([_mvhd(timescale: 1000, duration: 1000), _mvex()]),
        ),
      ]);

      expect(readFragmentedMp4Duration(path), isNull);
    });

    test('rejects a box that claims to run past the end of the file', () async {
      final bytes = _box('ftyp', Uint8List(16));
      ByteData.sublistView(bytes).setUint32(0, 4096);
      final path = await write('broken.m4a', [bytes]);

      expect(readFragmentedMp4Duration(path), isNull);
    });

    test('returns null for a missing file', () {
      expect(readFragmentedMp4Duration('${directory.path}/none.m4a'), isNull);
    });
  });
}

Uint8List _box(String type, Uint8List body) {
  final bytes = Uint8List(8 + body.length);
  ByteData.sublistView(bytes).setUint32(0, bytes.length);
  bytes.setRange(4, 8, type.codeUnits);
  bytes.setRange(8, bytes.length, body);
  return bytes;
}

Uint8List _mvhd({
  required int timescale,
  required int duration,
  int version = 0,
}) {
  final body = Uint8List(version == 1 ? 112 : 100);
  final data = ByteData.sublistView(body)..setUint8(0, version);
  if (version == 1) {
    data
      ..setUint32(20, timescale)
      ..setUint64(24, duration);
  } else {
    data
      ..setUint32(12, timescale)
      ..setUint32(16, duration);
  }
  return _box('mvhd', body);
}

Uint8List _mvex({int? fragmentDuration}) {
  final trex = _box('trex', Uint8List(24));
  if (fragmentDuration == null) return _box('mvex', trex);
  final mehd = Uint8List(8);
  ByteData.sublistView(mehd).setUint32(4, fragmentDuration);
  return _box('mvex', _concat([_box('mehd', mehd), trex]));
}

Uint8List _concat(List<Uint8List> parts) {
  final builder = BytesBuilder(copy: false);
  for (final part in parts) {
    builder.add(part);
  }
  return builder.toBytes();
}
