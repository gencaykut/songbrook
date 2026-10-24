import 'dart:io';

import 'package:flutter/foundation.dart';

enum AppPlatformType { android, ios, windows, linux, macos, unsupported }

class AppPlatform {
  const AppPlatform._();

  static AppPlatformType get current {
    if (Platform.isAndroid) {
      return AppPlatformType.android;
    }
    if (Platform.isIOS) {
      return AppPlatformType.ios;
    }
    if (Platform.isWindows) {
      return AppPlatformType.windows;
    }
    if (Platform.isLinux) {
      return AppPlatformType.linux;
    }
    if (Platform.isMacOS) {
      return AppPlatformType.macos;
    }
    return AppPlatformType.unsupported;
  }

  static bool get isAndroid => current == AppPlatformType.android;

  static bool get isIOS => current == AppPlatformType.ios;

  static bool get isWindows => current == AppPlatformType.windows;

  static bool get isLinux => current == AppPlatformType.linux;

  static bool get isMobile => isMobileOn(current);

  static bool isMobileOn(AppPlatformType platform) =>
      platform == AppPlatformType.android || platform == AppPlatformType.ios;

  static bool isMobileTargetPlatform(TargetPlatform platform) =>
      platform == TargetPlatform.android || platform == TargetPlatform.iOS;

  /// Native silence skipping is currently provided by Media3/ExoPlayer.
  ///
  /// Do not advertise this on iOS or desktop until their playback backends
  /// expose an equivalent that preserves media timestamps. Timestamp-changing
  /// audio filters can make the dual-deck crossfade start at the wrong point.
  static bool get supportsSkipSilence => supportsSkipSilenceOn(current);

  static bool supportsSkipSilenceOn(AppPlatformType platform) =>
      platform == AppPlatformType.android;

  static bool get isDesktop =>
      current == AppPlatformType.windows ||
      current == AppPlatformType.linux ||
      current == AppPlatformType.macos;
}
