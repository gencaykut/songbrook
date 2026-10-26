// Adapted from Ariami (https://github.com/picccassso/Ariami, commit 9b8d27e),
// ariami_core/lib/services/connect/remote_playback.dart, MIT License, Copyright (c) 2026 Alex (aka Picasso).
// See THIRD_PARTY_NOTICES.md.

import 'connect_models.dart';

/// A read-only view of the playback happening on another Connect device.
///
/// Clients hold one of these while a different device is the active player, so
/// their own transport UI can mirror the remote queue, track, and progress —
/// and route every control as a Connect command instead of touching the local
/// audio engine.
class ConnectRemotePlayback {
  ConnectRemotePlayback({
    required this.snapshot,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  final ConnectPlaybackSnapshot snapshot;
  final String deviceId;
  final String deviceName;
  final String deviceType;

  /// When this client received [snapshot]. Progress extrapolation uses only
  /// the local clock relative to this moment, so clock skew between devices
  /// never bends the mirrored seek bar.
  final DateTime receivedAt;

  /// The remote position now, extrapolated locally while the remote device is
  /// playing and clamped to the track duration.
  int get positionMs {
    if (!snapshot.isPlaying) return snapshot.positionMs;
    final elapsed = DateTime.now().difference(receivedAt).inMilliseconds;
    final position = snapshot.positionMs + (elapsed > 0 ? elapsed : 0);
    if (snapshot.durationMs > 0 && position > snapshot.durationMs) {
      return snapshot.durationMs;
    }
    return position;
  }

  Map<String, dynamic>? get currentTrackJson {
    final index = snapshot.currentIndex;
    if (index < 0 || index >= snapshot.queue.length) return null;
    return snapshot.queue[index];
  }

  /// A locally adjusted copy used for optimistic control feedback (the next
  /// state broadcast from the active device remains authoritative).
  ConnectRemotePlayback copyWithSnapshot(ConnectPlaybackSnapshot snapshot) =>
      ConnectRemotePlayback(
        snapshot: snapshot,
        deviceId: deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
      );
}
