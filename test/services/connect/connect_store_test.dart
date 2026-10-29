import 'package:bstream_music/services/connect/connect_host_server.dart';
import 'package:bstream_music/services/connect/connect_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keychain stand-in whose reads and writes take a moment, like the real
/// one, so concurrent updates interleave.
class _SlowSecureStore implements ConnectSecureStore {
  final values = <String, String>{};

  Future<void> _pause() => Future<void>.delayed(Duration.zero);

  @override
  Future<String?> read(String key) async {
    await _pause();
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    await _pause();
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    await _pause();
    values.remove(key);
  }
}

ConnectPairedDevice _device(String id) => ConnectPairedDevice(
  id: id,
  name: id,
  type: 'mobile',
  secret: 'secret-$id',
  pairedAt: DateTime.utc(2026, 10, 29),
);

ConnectKnownHost _host(String id, {String? address}) => ConnectKnownHost(
  hostId: id,
  hostName: id,
  secret: 'secret-$id',
  lastAddress: address,
  lastPort: address == null ? null : 47821,
);

void main() {
  test('forgetting two paired devices at once forgets both', () async {
    final store = ConnectStore(_SlowSecureStore());
    for (final id in ['phone', 'tablet', 'laptop']) {
      await store.savePairedDevice(_device(id));
    }

    await Future.wait([
      store.removePairedDevice('phone'),
      store.removePairedDevice('tablet'),
    ]);

    expect((await store.pairedDevices()).map((d) => d.id), ['laptop']);
  });

  test(
    'pairing while another device is forgotten keeps both changes',
    () async {
      final store = ConnectStore(_SlowSecureStore());
      await store.savePairedDevice(_device('phone'));

      await Future.wait([
        store.removePairedDevice('phone'),
        store.savePairedDevice(_device('tablet')),
      ]);

      expect((await store.pairedDevices()).map((d) => d.id), ['tablet']);
    },
  );

  test('forgetting two hosts at once forgets both', () async {
    final store = ConnectStore(_SlowSecureStore());
    for (final id in ['mac', 'imac', 'mini']) {
      await store.saveKnownHost(_host(id));
    }

    await Future.wait([
      store.removeKnownHost('mac'),
      store.removeKnownHost('imac'),
    ]);

    expect((await store.knownHosts()).map((h) => h.hostId), ['mini']);
  });

  test('an address update does not bring back a forgotten host', () async {
    final store = ConnectStore(_SlowSecureStore());
    await store.saveKnownHost(_host('mac'));

    await Future.wait([
      store.removeKnownHost('mac'),
      store.updateKnownHostAddress('mac', address: '10.0.0.2', port: 47821),
    ]);
    await store.updateKnownHostAddress('mac', address: '10.0.0.3', port: 1);

    expect(await store.knownHosts(), isEmpty);
  });

  test('an address update keeps the rest of the host', () async {
    final store = ConnectStore(_SlowSecureStore());
    await store.saveKnownHost(_host('mac', address: '10.0.0.1'));
    await store.saveKnownHost(_host('mini'));

    await store.updateKnownHostAddress('mac', address: '10.0.0.2', port: 5000);

    final hosts = await store.knownHosts();
    final mac = hosts.singleWhere((h) => h.hostId == 'mac');
    expect(mac.secret, 'secret-mac');
    expect(mac.lastAddress, '10.0.0.2');
    expect(mac.lastPort, 5000);
    expect(hosts.map((h) => h.hostId), containsAll(['mac', 'mini']));
  });

  test('concurrent first reads of the device id agree', () async {
    var created = 0;
    final store = ConnectStore(
      _SlowSecureStore(),
      newId: () => 'device-${++created}',
    );

    final ids = await Future.wait([store.deviceId(), store.deviceId()]);

    expect(ids[0], ids[1]);
    expect(await store.deviceId(), ids[0]);
  });
}
