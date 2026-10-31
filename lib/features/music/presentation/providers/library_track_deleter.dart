part of 'music_providers.dart';

/// Removes downloaded songs from the library: their rows, playlist and queue
/// entries, and files no other row uses. The library's Delete action and the
/// cleanup of automatic downloads share it.
final libraryTrackDeleterProvider = Provider<LibraryTrackDeleter>(
  LibraryTrackDeleter.new,
);

class LibraryTrackDeleter {
  LibraryTrackDeleter(this._ref);

  final Ref _ref;

  Future<int> delete(Iterable<LocalTrack> requestedTracks) async {
    final requestedIds = requestedTracks.map((track) => track.id).toSet();
    if (requestedIds.isEmpty) {
      return 0;
    }

    final repository = _ref.read(libraryRepositoryProvider);
    final currentTracks = await repository.getLocalTracks();
    final targets = currentTracks
        .where((track) => requestedIds.contains(track.id))
        .toList(growable: false);
    if (targets.isEmpty) {
      return 0;
    }

    // The repository implementation performs this ID + file-path guarded delete
    // and playlist pruning in one database transaction. Reusing the same
    // primitive as reconciliation also protects against a stale UI selection.
    final deletedIds = await repository.purgeMissingLocalTracks(targets);
    if (deletedIds.isEmpty) {
      return 0;
    }

    final deletedTracks = targets
        .where((track) => deletedIds.contains(track.id))
        .toList(growable: false);
    await _ref
        .read(playerControllerProvider.notifier)
        .removeDeletedLocalTracks(deletedIds);
    await _ref
        .read(playlistsControllerProvider.notifier)
        .reloadFromRepository();
    _ref
      ..invalidate(libraryTracksProvider)
      ..invalidate(historyProvider);

    // Re-read after the transaction and queue replacement so a concurrently
    // restored/downloaded record sharing a legacy path keeps its file.
    final survivors = await repository.getLocalTracks();
    final survivorPaths = survivors
        .expand((track) => [track.filePath, track.thumbnailPath])
        .map(_normalizedLibraryPath)
        .whereType<String>()
        .toSet();
    final filesToDelete = <String, String>{};
    for (final target in deletedTracks) {
      for (final path in [target.filePath, target.thumbnailPath]) {
        final normalized = _normalizedLibraryPath(path);
        if (normalized != null && !survivorPaths.contains(normalized)) {
          filesToDelete.putIfAbsent(normalized, () => path!);
        }
      }
    }
    // Let the list release FileImage listeners before unlinking thumbnails. This
    // matters on Windows tests and keeps the same code safe if desktop selection
    // is enabled later; Android itself permits unlinking open files.
    await WidgetsBinding.instance.endOfFrame;
    for (final path in filesToDelete.values) {
      await _deleteLibraryFileBestEffort(path);
    }
    return deletedIds.length;
  }
}

String? _normalizedLibraryPath(String? path) {
  final trimmed = path?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  try {
    final normalized = p.normalize(p.absolute(trimmed));
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  } on FileSystemException {
    return Platform.isWindows ? trimmed.toLowerCase() : trimmed;
  }
}

Future<void> _deleteLibraryFileBestEffort(String path) async {
  final file = File(path);
  await FileImage(file).evict();
  await ResizeImage(FileImage(file), width: 256).evict();
  await ResizeImage(FileImage(file), width: 640).evict();
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      if (!await file.exists()) {
        return;
      }
      await file.delete();
      return;
    } on FileSystemException {
      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
    }
  }
}
