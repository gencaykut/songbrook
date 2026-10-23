import 'dart:math' as math;

import 'player_service.dart';

/// A player that can attenuate loud tracks to YouTube's loudness target.
abstract interface class LoudnessNormalizingPlayer {
  bool get loudnessNormalizationEnabled;

  Future<void> configureLoudnessNormalization({required bool enabled});
}

/// Linear volume factor for a track [loudnessDb] above YouTube's target.
///
/// Like YouTube's own players this only attenuates: a quieter track keeps
/// unity gain, because AVPlayer and libmpv volumes cannot boost without DSP.
double loudnessNormalizationGain(double? loudnessDb) {
  if (loudnessDb == null || !loudnessDb.isFinite || loudnessDb <= 0) {
    return 1;
  }
  return math.pow(10, -loudnessDb / 20).toDouble();
}

double? crossfadeSourceLoudnessDb(CrossfadePlaybackSource source) {
  return switch (source) {
    LocalCrossfadePlaybackSource(:final track) => track.loudnessDb,
    RemoteCrossfadePlaybackSource(:final source) => source.track.loudnessDb,
  };
}
