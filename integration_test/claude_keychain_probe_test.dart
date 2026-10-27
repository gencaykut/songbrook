import 'package:bstream_music/services/connect/connect_store.dart';
import 'package:bstream_music/services/youtube_music/auth/youtube_music_session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Writes, reads and deletes a value through the keychain stores the app
/// uses on this platform (Connect and the YouTube Music session), printing each outcome.
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
    final youtube = const FlutterYouTubeMusicSecureKeyValueStore();
    // ignore: avoid_print
    print(
      'CLAUDE_KEYCHAIN youtube music: ${await probe(_YouTubeStore(youtube))}',
    );
    // ignore: avoid_print
    print(
      'CLAUDE_KEYCHAIN data protection default: '
      '${await probe(const FlutterConnectSecureStore(storage: FlutterSecureStorage()))}',
    );
  });
}

class _YouTubeStore implements ConnectSecureStore {
  _YouTubeStore(this._store);

  final FlutterYouTubeMusicSecureKeyValueStore _store;

  @override
  Future<String?> read(String key) => _store.read(key);

  @override
  Future<void> write(String key, String value) => _store.write(key, value);

  @override
  Future<void> delete(String key) => _store.delete(key);
}
