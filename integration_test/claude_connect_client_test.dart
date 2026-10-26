import 'dart:io';

import 'package:bstream_music/features/music/presentation/providers/connect_controller.dart';
import 'package:bstream_music/services/connect/connect_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// iOS half of the live Connect check: finds the Mac host from
/// `claude_connect_host_test.dart` over Bonjour and pairs with the code it
/// wrote to `--dart-define=CONNECT_CODE_FILE=<path>`. Pairings stay in memory.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phone pairs with the Mac host', (tester) async {
    // The Mac test writes its code to this host path; the simulator can read
    // the Mac's file system.
    const codeFile = String.fromEnvironment('CONNECT_CODE_FILE');
    var code = '';
    final waitForCode = Stopwatch()..start();
    while (code.length != 6 &&
        waitForCode.elapsed < const Duration(minutes: 4)) {
      final file = File(codeFile);
      if (file.existsSync()) code = file.readAsStringSync().trim();
      if (code.length != 6) await tester.pump(const Duration(seconds: 1));
    }
    expect(code, hasLength(6));
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
    await waitFor(
      () => state().discoveredHosts.isNotEmpty,
      const Duration(seconds: 30),
    );
    final host = state().discoveredHosts.first;
    // ignore: avoid_print
    print(
      'CLAUDE_CONNECT found="${host.name}" addresses=${host.addresses} '
      'port=${host.port} url=${host.baseUrl}',
    );
    final watch = Stopwatch()..start();
    await container
        .read(connectControllerProvider.notifier)
        .pairWithHost(host, code);
    await waitFor(
      () => state().devices.length >= 2,
      const Duration(seconds: 20),
    );
    // ignore: avoid_print
    print(
      'CLAUDE_CONNECT paired+connected in ${watch.elapsedMilliseconds}ms '
      'devices=${state().devices.map((d) => '${d.name}(${d.type})').join(', ')}',
    );
    expect(state().isConnected, isTrue);
    expect(state().devices.length, 2);
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
