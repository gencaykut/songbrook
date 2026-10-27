import 'package:bstream_music/services/connect/connect_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Writes, reads and deletes a value through the keychain stores the app
/// uses on this platform, printing each outcome.
///
/// flutter test integration_test/claude_keychain_probe_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<String> probe(ConnectSecureStore store) async {
    const key = 'songbrook.connect.probe.v1';
    try {
      await store.write(key, 'value');
      final read = await store.read(key);
      await store.delete(key);
      final gone = await store.read(key);
      return 'write+read=${read == 'value'} deleted=${gone == null}';
    } catch (error) {
      return 'failed: $error';
    }
  }

  testWidgets('keychain stores', (tester) async {
    // ignore: avoid_print
    print(
      'CLAUDE_KEYCHAIN connect: ${await probe(const FlutterConnectSecureStore())}',
    );
    // ignore: avoid_print
    print(
      'CLAUDE_KEYCHAIN data protection default: '
      '${await probe(const FlutterConnectSecureStore(storage: FlutterSecureStorage()))}',
    );
  });
}
