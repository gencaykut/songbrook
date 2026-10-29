import 'dart:io';

import '../../features/music/domain/entities/local_track.dart';
import '../../features/music/domain/repositories/library_repository.dart';

enum LocalTrackFileAvailability { present, missing, inaccessible }

typedef LocalTrackFileProbe =
    Future<LocalTrackFileAvailability> Function(String path);

Future<LocalTrackFileAvailability> probeLocalTrackFile(String path) async {
  final normalized = path.trim();
  if (normalized.isEmpty) {
    return LocalTrackFileAvailability.missing;
  }

  try {
    final type = await FileSystemEntity.type(normalized, followLinks: true);
    if (type == FileSystemEntityType.file) {
      return LocalTrackFileAvailability.present;
    }
    if (type != FileSystemEntityType.notFound) {
      return LocalTrackFileAvailability.missing;
    }
    return await _probeUnseenFile(normalized);
  } on FileSystemException {
    return LocalTrackFileAvailability.inaccessible;
  }
}

/// `FileSystemEntity.type` also answers notFound when the file cannot be
/// inspected, for example in a folder the app may not read. Only a file that
/// is absent from a folder that is there and readable counts as deleted; a
/// folder that is gone, such as an unmounted drive or a removed SD card, keeps
/// the library entry.
Future<LocalTrackFileAvailability> _probeUnseenFile(String path) async {
  if (!await File(path).parent.exists()) {
    return LocalTrackFileAvailability.inaccessible;
  }
  try {
    final handle = await File(path).open();
    await handle.close();
    return LocalTrackFileAvailability.present;
  } on PathNotFoundException {
    return LocalTrackFileAvailability.missing;
  } on FileSystemException {
    return LocalTrackFileAvailability.inaccessible;
  }
}

class LocalLibraryReconciliationResult {
  const LocalLibraryReconciliationResult({
    required this.checkedTrackCount,
    required this.missingTrackIds,
    required this.removedTrackIds,
    required this.inaccessibleTrackIds,
  });

  static const empty = LocalLibraryReconciliationResult(
    checkedTrackCount: 0,
    missingTrackIds: <String>{},
    removedTrackIds: <String>{},
    inaccessibleTrackIds: <String>{},
  );

  final int checkedTrackCount;
  final Set<String> missingTrackIds;
  final Set<String> removedTrackIds;
  final Set<String> inaccessibleTrackIds;

  bool get changed => removedTrackIds.isNotEmpty;
}

class LocalLibraryReconciler {
  const LocalLibraryReconciler(
    this._repository,
    this._fileProbe, {
    this.batchSize = 32,
  });

  final LibraryRepository _repository;
  final LocalTrackFileProbe _fileProbe;
  final int batchSize;

  Future<LocalLibraryReconciliationResult> reconcile({
    Iterable<LocalTrack>? tracks,
  }) async {
    final source = tracks ?? await _repository.getLocalTracks();
    final candidatesById = <String, LocalTrack>{};
    for (final track in source) {
      final id = track.id.trim();
      if (id.isNotEmpty) {
        candidatesById[id] = track;
      }
    }
    final candidates = candidatesById.values.toList(growable: false);
    if (candidates.isEmpty) {
      return LocalLibraryReconciliationResult.empty;
    }

    final missing = <LocalTrack>[];
    final inaccessibleIds = <String>{};
    final effectiveBatchSize = batchSize < 1 ? 1 : batchSize;
    for (
      var offset = 0;
      offset < candidates.length;
      offset += effectiveBatchSize
    ) {
      final proposedEnd = offset + effectiveBatchSize;
      final end = proposedEnd < candidates.length
          ? proposedEnd
          : candidates.length;
      final batch = candidates.sublist(offset, end);
      final statuses = await Future.wait(
        batch.map((track) async {
          try {
            return await _fileProbe(track.filePath);
          } catch (_) {
            return LocalTrackFileAvailability.inaccessible;
          }
        }),
      );

      for (var index = 0; index < batch.length; index++) {
        switch (statuses[index]) {
          case LocalTrackFileAvailability.present:
            break;
          case LocalTrackFileAvailability.missing:
            missing.add(batch[index]);
            break;
          case LocalTrackFileAvailability.inaccessible:
            inaccessibleIds.add(batch[index].id);
            break;
        }
      }
    }

    final removedIds = missing.isEmpty
        ? const <String>{}
        : await _repository.purgeMissingLocalTracks(missing);
    return LocalLibraryReconciliationResult(
      checkedTrackCount: candidates.length,
      missingTrackIds: Set<String>.unmodifiable(
        missing.map((track) => track.id),
      ),
      removedTrackIds: Set<String>.unmodifiable(removedIds),
      inaccessibleTrackIds: Set<String>.unmodifiable(inaccessibleIds),
    );
  }
}
