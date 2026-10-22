import 'dart:io';

import 'package:bstream_music/features/music/domain/entities/download_options.dart';
import 'package:bstream_music/features/music/domain/entities/local_track.dart';
import 'package:bstream_music/services/downloader/innertube_download_service.dart';
import 'package:bstream_music/services/player/just_audio_player_service.dart';
import 'package:bstream_music/services/player/player_service.dart';
import 'package:bstream_music/services/youtube_music/innertube_search_service.dart';
import 'package:bstream_music/services/youtube_music/playback/ejs_solver.dart';
import 'package:bstream_music/services/youtube_music/playback/headless_inappwebview_runtime.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_playback_service.dart';
import 'package:bstream_music/services/youtube_music/playback/innertube_stream_models.dart';
import 'package:bstream_music/services/youtube_music/playback/po_token_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Downloads a track through the app's own download path, then plays the file
// as a library track near its end and records when "completed" arrives.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('completion timing of a downloaded m4a', (_) async {
    final search = InnerTubeSearchService();
    // Same configuration as innerTubePlaybackServiceProvider on iOS.
    final playback = InnerTubePlaybackService(
      ejsSolver: EjsSolver(runtime: HeadlessInAppWebViewJavaScriptRuntime()),
      poTokenProvider: BotGuardPoTokenProvider(),
      audioFormatPredicate: isAvFoundationCompatibleInnerTubeAudio,
    );
    final downloader = InnerTubeDownloadService(
      playback: playback,
      catalog: search,
    );
    final directory = await Directory.systemTemp.createTemp('claude_local_');
    try {
      final song = (await search.searchSongs('Emir Makina', limit: 1)).first;
      final download = await downloader.downloadAudio(
        'https://www.youtube.com/watch?v=${song.videoId}',
        DownloadOptions(outputDirectory: directory.path, fileName: 'track'),
      );
      // ignore: avoid_print
      print(
        'CLAUDE_LOCAL_DOWNLOADED ${song.videoId} catalog=${song.duration} '
        'file=${download.fileName} bytes=${download.bytes}',
      );
      final track = LocalTrack(
        id: 'local:${song.videoId}',
        title: song.title,
        artist: 'Emir Makina',
        filePath: download.filePath,
        addedAt: DateTime.now(),
        // The library stores whole seconds, like the catalog.
        duration: song.duration,
      );

      for (final clip in [false, true]) {
        final service = JustAudioPlayerService(clipMp4ToStreamDuration: clip);
        final started = DateTime.now();
        String t() =>
            '${(DateTime.now().difference(started).inMilliseconds / 1000).toStringAsFixed(1)}s';
        try {
          await service.playLocal(track);
          await Future<void>.delayed(const Duration(seconds: 2));
          final reference = song.duration!;
          await service.seek(reference - const Duration(seconds: 8));
          final deadline = DateTime.now().add(const Duration(seconds: 40));
          while (service.currentSnapshot.status != PlayerStatus.completed &&
              DateTime.now().isBefore(deadline)) {
            final s = service.currentSnapshot;
            // ignore: avoid_print
            print(
              'CLAUDE_LOCAL_TICK clip=$clip ${t()} status=${s.status.name} '
              'pos=${s.position.inMilliseconds} dur=${s.duration?.inMilliseconds}',
            );
            await Future<void>.delayed(const Duration(seconds: 2));
          }
          final s = service.currentSnapshot;
          // ignore: avoid_print
          print(
            'CLAUDE_LOCAL_DONE clip=$clip ${t()} status=${s.status.name} '
            'pos=${s.position.inMilliseconds}',
          );
        } finally {
          await service.dispose();
        }
      }
    } finally {
      await downloader.dispose();
      await playback.dispose();
      search.dispose();
      await directory.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 6)));
}
