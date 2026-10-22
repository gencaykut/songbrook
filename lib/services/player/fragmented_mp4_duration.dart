import 'dart:io';
import 'dart:typed_data';

/// Reads the movie duration a fragmented MP4 file declares in `moov`.
///
/// YouTube's itag 140 m4a files (streamed or downloaded) state the full
/// duration in `moov` and again in their `moof` fragments. AVFoundation sums
/// both and reports twice the real length, so callers clip playback to this
/// value instead. Returns null for non-fragmented files (no `mvex`), which
/// AVFoundation measures correctly, and for anything it cannot parse.
Duration? readFragmentedMp4Duration(String path) {
  RandomAccessFile? file;
  try {
    file = File(path).openSync();
    final moov = _findTopLevelBox(file, 'moov');
    if (moov == null) return null;
    return parseFragmentedMp4MoovDuration(moov);
  } on FileSystemException {
    return null;
  } finally {
    file?.closeSync();
  }
}

/// Parses the body of a `moov` box; see [readFragmentedMp4Duration].
Duration? parseFragmentedMp4MoovDuration(Uint8List moov) {
  final data = ByteData.sublistView(moov);
  int? timescale;
  int? movieDuration;
  int? fragmentDuration;
  var fragmented = false;
  for (final box in _boxes(data, 0, data.lengthInBytes)) {
    switch (box.type) {
      case 'mvhd':
        if (box.body >= box.end) return null;
        final version = data.getUint8(box.body);
        if (version == 1) {
          if (box.body + 32 > box.end) return null;
          timescale = data.getUint32(box.body + 20);
          movieDuration = data.getUint64(box.body + 24);
        } else {
          if (box.body + 20 > box.end) return null;
          timescale = data.getUint32(box.body + 12);
          movieDuration = data.getUint32(box.body + 16);
        }
      case 'mvex':
        fragmented = true;
        for (final child in _boxes(data, box.body, box.end)) {
          if (child.type != 'mehd' || child.body >= child.end) continue;
          final version = data.getUint8(child.body);
          if (child.body + (version == 1 ? 12 : 8) > child.end) continue;
          fragmentDuration = version == 1
              ? data.getUint64(child.body + 4)
              : data.getUint32(child.body + 4);
        }
    }
  }
  if (!fragmented || timescale == null || timescale == 0) return null;
  final units = movieDuration != null && movieDuration > 0
      ? movieDuration
      : fragmentDuration;
  if (units == null || units <= 0) return null;
  return Duration(
    microseconds: (units * Duration.microsecondsPerSecond) ~/ timescale,
  );
}

const _maxMoovBytes = 4 * 1024 * 1024;
const _maxTopLevelBoxes = 32;

Uint8List? _findTopLevelBox(RandomAccessFile file, String type) {
  final length = file.lengthSync();
  var offset = 0;
  for (var i = 0; i < _maxTopLevelBoxes && offset + 8 <= length; i++) {
    file.setPositionSync(offset);
    final header = ByteData.sublistView(file.readSync(16));
    if (header.lengthInBytes < 8) return null;
    var size = header.getUint32(0);
    final boxType = String.fromCharCodes(Uint8List.sublistView(header, 4, 8));
    var headerSize = 8;
    if (size == 1) {
      if (header.lengthInBytes < 16) return null;
      size = header.getUint64(8);
      headerSize = 16;
    } else if (size == 0) {
      size = length - offset;
    }
    if (size < headerSize || offset + size > length) return null;
    if (boxType == type) {
      if (size - headerSize > _maxMoovBytes) return null;
      file.setPositionSync(offset + headerSize);
      return file.readSync(size - headerSize);
    }
    // A fragmented file declares moov before its first fragment.
    if (boxType == 'moof' || boxType == 'mdat') return null;
    offset += size;
  }
  return null;
}

typedef _Box = ({String type, int body, int end});

Iterable<_Box> _boxes(ByteData data, int start, int end) sync* {
  var offset = start;
  while (offset + 8 <= end) {
    var size = data.getUint32(offset);
    var headerSize = 8;
    if (size == 1) {
      if (offset + 16 > end) return;
      size = data.getUint64(offset + 8);
      headerSize = 16;
    } else if (size == 0) {
      size = end - offset;
    }
    if (size < headerSize || offset + size > end) return;
    final type = String.fromCharCodes(
      Uint8List.sublistView(data, offset + 4, offset + 8),
    );
    yield (type: type, body: offset + headerSize, end: offset + size);
    offset += size;
  }
}
