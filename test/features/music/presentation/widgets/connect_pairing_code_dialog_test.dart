import 'package:bstream_music/features/music/presentation/providers/connect_controller.dart';
import 'package:bstream_music/features/music/presentation/widgets/connect_pairing_code_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _PairingController extends ConnectController {
  @override
  ConnectState build() => const ConnectState(enabled: true, isHost: true);

  @override
  void beginPairing() => state = state.copyWith(pairingCode: '123456');

  @override
  void cancelPairing() => state = state.copyWith(pairingCode: null);

  void paired() => cancelPairing();
}

void main() {
  late _PairingController controller;

  Future<void> pumpSettings(WidgetTester tester) async {
    controller = _PairingController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectControllerProvider.overrideWith(() => controller)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showConnectPairingCodeDialog(context, ref),
                child: const Text('Add a device'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Add a device'));
    await tester.pumpAndSettle();
    expect(find.text('123 456'), findsOneWidget);
  }

  testWidgets('closing the code keeps the page under it', (tester) async {
    await pumpSettings(tester);

    await tester.tap(
      find.byKey(const ValueKey('settings-connect-pairing-close')),
    );
    await tester.pumpAndSettle();

    expect(find.text('123 456'), findsNothing);
    expect(find.text('Add a device'), findsOneWidget);
    expect(controller.state.pairingCode, isNull);
  });

  testWidgets('pairing closes the code by itself, only once', (tester) async {
    await pumpSettings(tester);

    controller.paired();
    await tester.pumpAndSettle();

    expect(find.text('123 456'), findsNothing);
    expect(find.text('Add a device'), findsOneWidget);
  });
}
