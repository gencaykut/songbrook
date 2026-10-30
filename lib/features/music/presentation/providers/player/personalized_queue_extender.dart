import '../../../../../services/recommendations/listening_preferences.dart';
import '../../../../../services/sharing/bstream_track_link.dart';
import '../../../domain/entities/track_info.dart';
import 'recommendation_playback_item.dart';

/// Orders the songs [extender] adds after the first [keepFirst], which the
/// listener picked, by [preferences]: songs they keep skipping are left out
/// and the rest keep YouTube's order, adjusted for the artists they play and
/// skip. Songs already returned are never reordered.
RecommendationQueueExtender personalizeQueueExtender(
  RecommendationQueueExtender extender, {
  required int keepFirst,
  required Future<ListeningPreferences> Function() preferences,
}) {
  final output = <RecommendationPlaybackItem>[];
  var handled = 0;
  return () async {
    final raw = await extender();
    if (raw.length < handled) {
      // The extender restarted; follow it rather than mixing two queues.
      output.clear();
      handled = 0;
    }
    if (handled == 0) {
      final kept = keepFirst.clamp(0, raw.length);
      output.addAll(raw.take(kept));
      handled = kept;
    }
    final added = raw.sublist(handled);
    handled = raw.length;
    if (added.isNotEmpty) {
      output.addAll(
        (await preferences()).rank(
          added,
          trackKey: (item) => playbackItemTrackKey(item.track),
          artists: (item) => trackArtists(item.track),
        ),
      );
    }
    return List<RecommendationPlaybackItem>.unmodifiable(output);
  };
}

/// The history's key for [track]: its YouTube video id when it has one.
String? playbackItemTrackKey(TrackInfo track) {
  final videoId = const BStreamTrackLinkCodec().tryFromTrack(track)?.videoId;
  if (videoId != null && videoId.isNotEmpty) return videoId;
  final id = track.id.trim();
  return id.isEmpty ? null : id;
}

List<String> trackArtists(TrackInfo track) =>
    track.artists.isNotEmpty ? track.artists : [track.artist];
