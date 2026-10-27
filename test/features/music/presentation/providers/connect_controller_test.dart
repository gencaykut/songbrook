import 'dart:async';

import 'package:bstream_music/features/music/presentation/providers/connect_controller.dart';
import 'package:bstream_music/features/music/presentation/providers/connect_playback.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart'
    show ConnectRemoteControl;
import 'package:bstream_music/services/connect/connect_discovery.dart';
import 'package:bstream_music/services/connect/connect_models.dart';
import 'package:bstream_music/services/connect/connect_pairing_client.dart';
import 'package:bstream_music/services/connect/connect_store.dart';
import 'package:bstream_music/services/connect/remote_playback.dart';
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

/// A player that records what Connect asks of it.
class _FakePlayback implements ConnectPlayback {
  final _changes = StreamController<ConnectPlaybackChange>.broadcast();
  final commands = <String>[];
  final applied = <ConnectPlaybackSnapshot>[];
  var pausedForTransfer = 0;
  ConnectPlaybackSnapshot current = ConnectPlaybackSnapshot.fromJson(const {});

  void play(List<String> ids, {int index = 0, int positionMs = 0}) {
    current = ConnectPlaybackSnapshot.fromJson({
      'queue': [
        for (final id in ids) {'id': id, 'title': 'Song $id', 'artist': 'A'},
      ],
      'currentIndex': index,
      'positionMs': positionMs,
      'durationMs': 200000,
      'isPlaying': true,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
    _changes.add(const ConnectPlaybackChange(started: true));
  }

  void _set({bool? isPlaying, int? positionMs}) {
    current = current.copyWith(
      isPlaying: isPlaying,
      positionMs: positionMs,
      updatedAt: DateTime.now().toUtc(),
    );
    _changes.add(
      ConnectPlaybackChange(
        started: isPlaying == true,
        stopped: isPlaying == false,
      ),
    );
  }

  @override
  Set<String> get supportedCommands => kConnectPlayerCommands;

  @override
  Stream<ConnectPlaybackChange> get changes => _changes.stream;

  @override
  ConnectPlaybackSnapshot snapshot() => current;

  @override
  Future<void> apply(ConnectPlaybackSnapshot snapshot) async {
    applied.add(snapshot);
    current = snapshot;
  }

  @override
  Future<void> handleCommand(
    String command,
    Map<String, dynamic> arguments,
  ) async {
    commands.add(command);
    switch (command) {
      case ConnectCommand.pause:
        _set(isPlaying: false);
      case ConnectCommand.play:
        _set(isPlaying: true);
      case ConnectCommand.seek:
        _set(positionMs: arguments['positionMs'] as int);
    }
  }

  ConnectRemotePlayback? mirrored;
  ConnectRemoteControl? control;

  @override
  void mirror(ConnectRemotePlayback? remote, ConnectRemoteControl? control) {
    mirrored = remote;
    this.control = control;
  }

  @override
  Future<void> pauseForTransfer() async {
    pausedForTransfer++;
    _set(isPlaying: false);
  }
}

void main() {
  late _FakeLan lan;
  late StreamController<void> resumes;
  late _MemorySecureStore macKeychain;
  late _MemorySecureStore phoneKeychain;
  final containers = <ProviderContainer>[];

  setUp(() {
    lan = _FakeLan();
    resumes = StreamController<void>.broadcast();
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
    _FakePlayback? playback,
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
        connectPlaybackProvider.overrideWithValue(playback ?? _FakePlayback()),
        connectAppResumedProvider.overrideWithValue(resumes.stream),
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

  /// A Mac with [macPlayback] and a phone with [phonePlayback], paired and
  /// connected to each other.
  Future<(ProviderContainer, ProviderContainer)> pairedDevices(
    _FakePlayback macPlayback,
    _FakePlayback phonePlayback,
  ) async {
    final mac = device(
      isHost: true,
      keychain: macKeychain,
      enabled: true,
      playback: macPlayback,
    );
    await eventually(() => stateOf(mac).isConnected);
    final phone = device(
      isHost: false,
      keychain: phoneKeychain,
      enabled: true,
      playback: phonePlayback,
    );
    await eventually(() => stateOf(phone).discoveredHosts.isNotEmpty);
    mac.read(connectControllerProvider.notifier).beginPairing();
    await phone
        .read(connectControllerProvider.notifier)
        .pairWithHost(
          stateOf(phone).discoveredHosts.single,
          stateOf(mac).pairingCode!,
        );
    await eventually(
      () =>
          stateOf(phone).devices.length == 2 &&
          stateOf(mac).devices.length == 2,
    );
    return (mac, phone);
  }

  test('playing on the Mac makes it the owner the phone mirrors', () async {
    final macPlayback = _FakePlayback();
    final (mac, phone) = await pairedDevices(macPlayback, _FakePlayback());
    final macId = stateOf(mac).connectedHostId;

    macPlayback.play(['a', 'b', 'c'], index: 1, positionMs: 5000);

    await eventually(() => stateOf(phone).activeDeviceId == macId);
    await eventually(() => stateOf(phone).playback?.currentTrackId == 'b');
    final mirrored = stateOf(phone).playback!;
    expect(mirrored.queue.map((track) => track['id']), ['a', 'b', 'c']);
    expect(mirrored.isPlaying, isTrue);
    expect(mirrored.positionMs, greaterThanOrEqualTo(5000));
    // The phone's player shows the Mac's playback; the Mac shows its own.
    final phonePlayback = phone.read(connectPlaybackProvider) as _FakePlayback;
    await eventually(() => phonePlayback.mirrored?.deviceId == macId);
    expect(phonePlayback.mirrored!.snapshot.currentTrackId, 'b');
    expect(phonePlayback.control!.forwarding, isTrue);
    expect(macPlayback.mirrored, isNull);
  });

  test('the phone pauses and seeks the music playing on the Mac', () async {
    final macPlayback = _FakePlayback();
    final (_, phone) = await pairedDevices(macPlayback, _FakePlayback());
    macPlayback.play(['a', 'b']);
    await eventually(() => stateOf(phone).playback?.isPlaying == true);
    final remote = phone.read(connectControllerProvider.notifier);

    remote.sendCommand(ConnectCommand.pause);
    await eventually(() => stateOf(phone).playback?.isPlaying == false);
    remote.sendCommand(ConnectCommand.seek, {'positionMs': 42000});
    await eventually(() => stateOf(phone).playback?.positionMs == 42000);
    expect(macPlayback.commands, [ConnectCommand.pause, ConnectCommand.seek]);
  });

  test('playback moves to the phone: prepared paused, then started', () async {
    final macPlayback = _FakePlayback();
    final phonePlayback = _FakePlayback();
    final (mac, phone) = await pairedDevices(macPlayback, phonePlayback);
    macPlayback.play(['a', 'b'], index: 1, positionMs: 30000);
    await eventually(() => stateOf(phone).playback?.isPlaying == true);
    final phoneId = stateOf(
      phone,
    ).devices.firstWhere((device) => device.type == 'mobile').id;

    phone.read(connectControllerProvider.notifier).transferTo(phoneId);

    await eventually(() => stateOf(mac).activeDeviceId == phoneId);
    await eventually(() => phonePlayback.current.isPlaying);
    // Loaded without playing first, so the Mac kept playing until then.
    expect(phonePlayback.applied.single.isPlaying, isFalse);
    expect(phonePlayback.applied.single.currentTrackId, 'b');
    expect(phonePlayback.current.positionMs, greaterThanOrEqualTo(30000));
    expect(macPlayback.pausedForTransfer, greaterThanOrEqualTo(1));
    expect(macPlayback.current.isPlaying, isFalse);
    // Roles swap: the Mac now shows the phone's playback.
    await eventually(() => macPlayback.mirrored?.deviceId == phoneId);
    expect(phonePlayback.mirrored, isNull);
  });

  test('playing on the phone takes over from the Mac', () async {
    final macPlayback = _FakePlayback();
    final phonePlayback = _FakePlayback();
    final (mac, phone) = await pairedDevices(macPlayback, phonePlayback);
    macPlayback.play(['a']);
    await eventually(() => stateOf(phone).playback?.isPlaying == true);
    final phoneId = stateOf(
      phone,
    ).devices.firstWhere((device) => device.type == 'mobile').id;

    phonePlayback.play(['z']);

    await eventually(() => stateOf(mac).activeDeviceId == phoneId);
    await eventually(() => !macPlayback.current.isPlaying);
    await eventually(() => stateOf(mac).playback?.currentTrackId == 'z');
  });

  /// The Mac restarts on another port; the phone keeps retrying the old one.
  Future<(ProviderContainer, ProviderContainer)> macMovedAway() async {
    final (mac, phone) = await pairedDevices(_FakePlayback(), _FakePlayback());
    final macController = mac.read(connectControllerProvider.notifier);
    await macController.setEnabled(false);
    await eventually(() => !stateOf(phone).isConnected);
    await macController.setEnabled(true);
    await eventually(() => stateOf(mac).isConnected);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(stateOf(phone).isConnected, isFalse);
    return (mac, phone);
  }

  test('coming back to the front reconnects to the Mac', () async {
    final (mac, phone) = await macMovedAway();

    resumes.add(null);

    await eventually(() => stateOf(phone).isConnected);
    await eventually(() => stateOf(mac).devices.length == 2);
  });

  test('the Mac seen at a new address is reached there', () async {
    final (mac, phone) = await macMovedAway();

    lan.hosts.add([lan.advertised!]);

    await eventually(() => stateOf(phone).isConnected);
    await eventually(() => stateOf(mac).devices.length == 2);
  });

  test('coming back while connected keeps the connection', () async {
    final (mac, phone) = await pairedDevices(_FakePlayback(), _FakePlayback());

    resumes.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    await eventually(() => stateOf(phone).isConnected);
    await eventually(() => stateOf(mac).devices.length == 2);
  });

  test(
    'a playing phone that drops off the network keeps the session',
    () async {
      final macPlayback = _FakePlayback();
      final phonePlayback = _FakePlayback();
      final (mac, phone) = await pairedDevices(macPlayback, phonePlayback);
      phonePlayback.play(['a', 'b'], positionMs: 30000);
      final phoneId = stateOf(phone).selfDeviceId;
      await eventually(() => stateOf(mac).activeDeviceId == phoneId);

      // The phone's socket dies (Wi-Fi power saving, a call) and comes back;
      // the hub hands the session to the Mac meanwhile.
      final drops = <String?>[];
      final watch = mac.listen(
        connectControllerProvider.select((state) => state.activeDeviceId),
        (_, next) => drops.add(next),
      );
      addTearDown(watch.close);
      await phone.read(connectControllerProvider.notifier).reconnect();

      await eventually(
        () =>
            stateOf(mac).activeDeviceId == phoneId &&
            stateOf(phone).activeDeviceId == phoneId,
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(stateOf(mac).activeDeviceId, phoneId);
      // The Mac never started the song a second time.
      expect(macPlayback.commands, isNot(contains(ConnectCommand.play)));
      expect(macPlayback.current.isPlaying, isFalse);
      // The phone plays on and is not mirroring the Mac.
      expect(phonePlayback.current.isPlaying, isTrue);
      expect(phonePlayback.mirrored, isNull);
    },
  );
}
