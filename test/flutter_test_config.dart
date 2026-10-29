import 'dart:async';
import 'dart:io';

import 'package:bstream_music/features/music/presentation/providers/music_providers.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Runs before every test file in this directory.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Songbrook follows the device language until one is chosen; upstream's
  // tests were written for a Spanish default, which this keeps.
  systemAppLanguage = () => AppLanguage.spanish;
  // The app opens SQLite through FFI only on Windows and Linux; on macOS it
  // relies on the sqflite plugin, which `flutter test` does not load. Use FFI
  // there too so the database tests run on a Mac as they do in upstream's CI.
  if (Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await testMain();
}
