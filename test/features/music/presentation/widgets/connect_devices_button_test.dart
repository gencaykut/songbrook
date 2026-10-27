import 'package:bstream_music/features/music/presentation/providers/connect_controller.dart';
import 'package:bstream_music/features/music/presentation/widgets/connect_devices_button.dart';
import 'package:bstream_music/services/connect/connect_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedConnectController extends ConnectController {
  _FixedConnectController(this.initial);

  final ConnectState initial;
  final transfers = <String>[];

  @override
  ConnectState build() => initial;

  @override
  void transferTo(String deviceId) => transfers.add(deviceId);
}

ConnectDevice _device(String id, String name, String type) => ConnectDevice(
  id: id,
  name: name,
  type: type,
  canPlay: true,
  connectedAt: DateTime(2026),
);

void main() {
  final mac = _device('mac', 'MacBook Pro', 'desktop');
  final phone = _device('phone', 'iPhone', 'mobile');

  Future<_FixedConnectController> pump(
    WidgetTester tester,
    ConnectState state,
  ) async {
    final controller = _FixedConnectController(state);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectControllerProvider.overrideWith(() => controller)],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: ConnectDevicesButton())),
        ),
      ),
    );
    return controller;
  }

  testWidgets('hidden until another device is connected', (tester) async {
    await pump(
      tester,
      ConnectState(
        enabled: true,
        isConnected: true,
        devices: [phone],
        selfDeviceId: 'phone',
      ),
    );
    expect(find.byKey(const ValueKey('connect-devices-button')), findsNothing);
  });

  testWidgets('the picker moves playback to the chosen device', (tester) async {
    final controller = await pump(
      tester,
      ConnectState(
        enabled: true,
        isConnected: true,
        devices: [mac, phone],
        selfDeviceId: 'phone',
        activeDeviceId: 'mac',
      ),
    );
    await tester.tap(find.byKey(const ValueKey('connect-devices-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('connect-device-picker')), findsOneWidget);
    expect(find.text('MacBook Pro'), findsOneWidget);
    // Tapping the device that is already playing only closes the picker.
    await tester.tap(find.byKey(const ValueKey('connect-device-mac')));
    await tester.pumpAndSettle();
    expect(controller.transfers, isEmpty);

    await tester.tap(find.byKey(const ValueKey('connect-devices-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('connect-device-phone')));
    await tester.pumpAndSettle();
    expect(controller.transfers, ['phone']);
    expect(find.byKey(const ValueKey('connect-device-picker')), findsNothing);
  });

  testWidgets('nothing to move before anything has played', (tester) async {
    final controller = await pump(
      tester,
      ConnectState(
        enabled: true,
        isConnected: true,
        devices: [mac, phone],
        selfDeviceId: 'phone',
      ),
    );
    await tester.tap(find.byKey(const ValueKey('connect-devices-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('connect-nothing-to-move')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('connect-device-mac')));
    await tester.pumpAndSettle();
    expect(controller.transfers, isEmpty);
  });
}
