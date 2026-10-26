import 'dart:io';

import 'package:bstream_music/features/music/presentation/providers/connect_controller.dart';
import 'package:bstream_music/services/connect/connect_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// macOS half of the live Connect check: runs the real host (server and
/// Bonjour) and prints a pairing code for `claude_connect_client_test.dart`
/// on the iOS simulator. Pairings stay in memory, not in the keychain.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Mac host pairs a phone over Bonjour', (tester) async {
    final container = ProviderContainer(
      overrides: [
        connectStoreProvider.overrideWithValue(ConnectStore(_Memory())),
        connectEnabledStoreProvider.overrideWithValue(_Enabled()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(connectControllerProvider, (_, _) {});
    ConnectState state() => container.read(connectControllerProvider);
    Future<void> waitFor(bool Function() done, Duration limit) async {
      final watch = Stopwatch()..start();
      while (!done() && watch.elapsed < limit) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    }

    await waitFor(() => state().loaded, const Duration(seconds: 10));
    await container.read(connectControllerProvider.notifier).setEnabled(true);
    await waitFor(() => state().isConnected, const Duration(seconds: 10));
    container.read(connectControllerProvider.notifier).beginPairing();
    // The phone test on the simulator reads the code from this file.
    const codeFile = String.fromEnvironment('CONNECT_CODE_FILE');
    if (codeFile.isNotEmpty) {
      File(codeFile).writeAsStringSync(state().pairingCode!);
    }
    // ignore: avoid_print
    print(
      'CLAUDE_CONNECT host="${state().deviceName}" '
      'code=${state().pairingCode} connected=${state().isConnected}',
    );
    await waitFor(
      () => state().devices.length >= 2,
      const Duration(minutes: 3),
    );
    // ignore: avoid_print
    print(
      'CLAUDE_CONNECT devices=${state().devices.map((d) => '${d.name}(${d.type})').join(', ')} '
      'paired=${state().pairedDevices.map((d) => d.name).join(', ')}',
    );
    expect(state().devices.length, 2);
    // Keep serving briefly so the phone side can finish its checks.
    await waitFor(() => false, const Duration(seconds: 10));
  });
}

class _Memory implements ConnectSecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class _Enabled implements ConnectEnabledStore {
  bool enabled = false;

  @override
  Future<bool> read() async => enabled;

  @override
  Future<void> write(bool value) async => enabled = value;
}
