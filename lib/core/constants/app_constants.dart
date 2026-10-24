class AppConstants {
  const AppConstants._();

  /// Name shown to users: window title, headers, media sessions.
  static const displayName = 'Songbrook';

  /// Upstream identity kept for data formats: backups are validated against
  /// it, so changing it would reject every existing backup.
  static const appName = 'BStream Music';
  static const appVersion = '1.0.0';
  static const databaseName = 'bstream_music.db';
  static const databaseVersion = 9;
  static const fileExportChannel = 'bstream_music/file_export';
  static const androidFileExportChannel = fileExportChannel;
  static const androidScreenChannel = 'bstream_music/screen';
  static const androidSupportedLinksSettingsChannel =
      'bstream_music/supported_links_settings';
  static const androidExternalAudioChannel = 'bstream_music/external_audio';
  static const androidAppActivationChannel = 'bstream_music/app_activation';
  static const defaultSearchLimit = 20;
  static const githubRepository = 'gencaykut/yt-music-app';
  static const githubRepositoryUrl = 'https://github.com/$githubRepository';
  static const appDownloadUrl = '$githubRepositoryUrl/releases/latest';

  /// Songbrook is a fork of BStream Music; the About page credits it.
  static const upstreamRepositoryUrl =
      'https://github.com/BryamContreras/BStream-Music';
}
