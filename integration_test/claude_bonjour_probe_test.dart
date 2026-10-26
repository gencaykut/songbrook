import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Advertises `_songbrook._tcp` with Bonsoir alone and prints every event,
/// to separate Bonjour problems from Connect ones.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Bonjour advertisement', (tester) async {
    final broadcast = BonsoirBroadcast(
      service: BonsoirService(
        name: 'Songbrook Probe',
        type: '_songbrook._tcp',
        port: 47999,
        attributes: const {'id': 'probe', 'v': '1'},
      ),
    );
    await broadcast.initialize();
    // ignore: avoid_print
    print(
      'CLAUDE_BONJOUR ready=${broadcast.isReady} stream=${broadcast.eventStream != null}',
    );
    broadcast.eventStream?.listen(
      // ignore: avoid_print
      (event) => print('CLAUDE_BONJOUR event $event'),
      // ignore: avoid_print
      onError: (Object error) => print('CLAUDE_BONJOUR error $error'),
    );
    await broadcast.start();
    // ignore: avoid_print
    print('CLAUDE_BONJOUR started');
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await broadcast.stop();
  });
}
