import 'download_options.dart';

class DownloadResult {
  const DownloadResult({
    required this.id,
    required this.sourceUrl,
    required this.filePath,
    required this.fileName,
    required this.mediaType,
    required this.completedAt,
    this.bytes,
    this.loudnessDb,
  });

  final String id;
  final String sourceUrl;
  final String filePath;
  final String fileName;
  final DownloadMediaType mediaType;
  final DateTime completedAt;
  final int? bytes;

  /// YouTube's loudness of the downloaded stream relative to its playback
  /// target, in dB, when the provider reported it.
  final double? loudnessDb;
}

enum DownloadProgressStatus { queued, running, completed, failed }

class DownloadProgress {
  const DownloadProgress({
    required this.taskId,
    required this.url,
    required this.status,
    this.progress,
    this.message,
    this.eta,
  });

  final String taskId;
  final String url;
  final DownloadProgressStatus status;
  final double? progress;
  final String? message;
  final Duration? eta;
}
