import 'dart:async';

import 'package:bstream_music/features/music/presentation/providers/connect_controller.dart';
import 'package:bstream_music/services/connect/connect_discovery.dart';
import 'package:bstream_music/services/connect/connect_pairing_client.dart';
import 'package:bstream_music/services/connect/connect_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemorySecureStore implements ConnectSecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class _MemoryEnabledStore implements ConnectEnabledStore {
  _MemoryEnabledStore([this.enabled = false]);

  bool enabled;

  @override
  Future<bool> read() async => enabled;

  @override
  Future<void> write(bool value) async => enabled = value;
}

/// Records what the host advertises and lets the phone "see" it.
class _FakeLan implements ConnectBroadcaster {
  final hosts = StreamController<List<ConnectDiscoveredHost>>.broadcast();
  ConnectDiscoveredHost? advertised;

  @override
  Future<void> start({
    required String hostId,
    required String name,
    required int port,
  }) async {
    advertised = ConnectDiscoveredHost(
      hostId: hostId,
      name: name,
      addresses: const ['127.0.0.1'],
      port: port,
    );
  }

  @override
  Future<void> stop() async => advertised = null;
}

class _FakeDiscovery implements ConnectHostDiscovery {
  _FakeDiscovery(this.lan);

  final _FakeLan lan;

  @override
  Stream<List<ConnectDiscoveredHost>> get hosts => lan.hosts.stream;

  @override
  Future<void> start() async {
    final host = lan.advertised;
    if (host != null) {
      scheduleMicrotask(() => lan.hosts.add([host]));
    }
  }

  @override
  Future<void> stop() async {}
}

void main() {
  late _FakeLan lan;
  late _MemorySecureStore macKeychain;
  late _MemorySecureStore phoneKeychain;
  final containers = <ProviderContainer>[];

  setUp(() {
    lan = _FakeLan();
    macKeychain = _MemorySecureStore();
    phoneKeychain = _MemorySecureStore();
  });

  tearDown(() async {
    for (final container in containers.reversed) {
      container.dispose();
    }
    containers.clear();
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  ProviderContainer device({
    required bool isHost,
    required _MemorySecureStore keychain,
    bool enabled = false,
  }) {
    var ids = 0;
    final container = ProviderContainer(
      overrides: [
        connectIsHostProvider.overrideWithValue(isHost),
        connectHostPortProvider.overrideWithValue(0),
        connectStoreProvider.overrideWithValue(
          ConnectStore(
            keychain,
            newId: () => '${isHost ? 'mac' : 'phone'}-${ids++}',
          ),
        ),
        connectEnabledStoreProvider.overrideWithValue(
          _MemoryEnabledStore(enabled),
        ),
        connectBroadcasterProvider.overrideWithValue(lan),
        connectHostDiscoveryProvider.overrideWithValue(_FakeDiscovery(lan)),
      ],
    );
    containers.add(container);
    container.listen(connectControllerProvider, (_, _) {});
    return container;
  }

  Future<void> eventually(bool Function() condition) async {
    for (var i = 0; i < 300 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(condition(), isTrue);
  }

  ConnectState stateOf(ProviderContainer container) =>
      container.read(connectControllerProvider);

  test('a phone pairs with the Mac by code and they see each other', () async {
    final mac = device(isHost: true, keychain: macKeychain);
    await eventually(() => stateOf(mac).loaded);
    await mac.read(connectControllerProvider.notifier).setEnabled(true);
    await eventually(() => stateOf(mac).isConnected);
    expect(lan.advertised, isNotNull);

    final phone = device(isHost: false, keychain: phoneKeychain);
    await eventually(() => stateOf(phone).loaded);
    await phone.read(connectControllerProvider.notifier).setEnabled(true);
    await eventually(() => stateOf(phone).discoveredHosts.isNotEmpty);
    final host = stateOf(phone).discoveredHosts.single;
    expect(stateOf(phone).isConnected, isFalse);

    mac.read(connectControllerProvider.notifier).beginPairing();
    final code = stateOf(mac).pairingCode!;
    await phone
        .read(connectControllerProvider.notifier)
        .pairWithHost(host, code);

    await eventually(() => stateOf(phone).isConnected);
    await eventually(
      () =>
          stateOf(phone).devices.length == 2 &&
          stateOf(mac).devices.length == 2,
    );
    expect(stateOf(mac).pairedDevices.single.id, 'phone-0');
    expect(stateOf(mac).pairingCode, isNull);
    expect(stateOf(phone).knownHosts.single.hostId, host.hostId);
  });

  test('a paired phone reconnects on its own after a restart', () async {
    final mac = device(isHost: true, keychain: macKeychain, enabled: true);
    await eventually(() => stateOf(mac).isConnected);
    final firstPhone = device(isHost: false, keychain: phoneKeychain);
    await eventually(() => stateOf(firstPhone).loaded);
    await firstPhone.read(connectControllerProvider.notifier).setEnabled(true);
    await eventually(() => stateOf(firstPhone).discoveredHosts.isNotEmpty);
    mac.read(connectControllerProvider.notifier).beginPairing();
    await firstPhone
        .read(connectControllerProvider.notifier)
        .pairWithHost(
          stateOf(firstPhone).discoveredHosts.single,
          stateOf(mac).pairingCode!,
        );
    await eventually(() => stateOf(firstPhone).isConnected);
    containers.remove(firstPhone);
    firstPhone.dispose();
    await eventually(() => stateOf(mac).devices.length == 1);

    final phone = device(isHost: false, keychain: phoneKeychain, enabled: true);
    await eventually(() => stateOf(phone).isConnected);
    await eventually(() => stateOf(mac).devices.length == 2);
  });

  test('a wrong code fails without pairing', () async {
    final mac = device(isHost: true, keychain: macKeychain, enabled: true);
    await eventually(() => stateOf(mac).isConnected);
    final phone = device(isHost: false, keychain: phoneKeychain, enabled: true);
    await eventually(() => stateOf(phone).discoveredHosts.isNotEmpty);
    mac.read(connectControllerProvider.notifier).beginPairing();
    final wrong = stateOf(mac).pairingCode == '111111' ? '222222' : '111111';

    await expectLater(
      phone
          .read(connectControllerProvider.notifier)
          .pairWithHost(stateOf(phone).discoveredHosts.single, wrong),
      throwsA(isA<ConnectPairingException>()),
    );
    expect(stateOf(phone).knownHosts, isEmpty);
    expect(stateOf(phone).isConnected, isFalse);
  });

  test('removing a phone on the Mac disconnects it', () async {
    final mac = device(isHost: true, keychain: macKeychain, enabled: true);
    await eventually(() => stateOf(mac).isConnected);
    final phone = device(isHost: false, keychain: phoneKeychain, enabled: true);
    await eventually(() => stateOf(phone).discoveredHosts.isNotEmpty);
    mac.read(connectControllerProvider.notifier).beginPairing();
    await phone
        .read(connectControllerProvider.notifier)
        .pairWithHost(
          stateOf(phone).discoveredHosts.single,
          stateOf(mac).pairingCode!,
        );
    await eventually(() => stateOf(mac).devices.length == 2);

    await mac.read(connectControllerProvider.notifier).revokeDevice('phone-0');
    await eventually(() => !stateOf(phone).isConnected);
    expect(stateOf(mac).pairedDevices, isEmpty);
    await eventually(() => stateOf(phone).knownHosts.isEmpty);
    expect(stateOf(phone).errorMessage, ConnectState.pairingRemovedError);
  });

  test('turning Connect off stops the Mac host', () async {
    final mac = device(isHost: true, keychain: macKeychain, enabled: true);
    await eventually(() => stateOf(mac).isConnected);
    await mac.read(connectControllerProvider.notifier).setEnabled(false);
    expect(stateOf(mac).isConnected, isFalse);
    expect(lan.advertised, isNull);
  });
}
