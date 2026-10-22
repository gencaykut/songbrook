import 'dart:async';

import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';

/// Runs before every test file in this directory.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Songbrook follows the device language until one is chosen; upstream's
  // tests were written for a Spanish default, which this keeps.
  systemAppLanguage = () => AppLanguage.spanish;
  await testMain();
}
