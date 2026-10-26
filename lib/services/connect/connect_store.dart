import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'connect_host_server.dart';

/// Minimal key-value seam over the platform keychain, so tests stay in Dart.
abstract interface class ConnectSecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

class FlutterConnectSecureStore implements ConnectSecureStore {
  const FlutterConnectSecureStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        resetOnError: true,
        migrateOnAlgorithmChange: true,
      ),
      wOptions: WindowsOptions(useBackwardCompatibility: false),
    ),
    // Preserve a named injection point for the platform storage.
    // ignore: prefer_initializing_formals
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// A host this device has paired with.
class ConnectKnownHost {
  const ConnectKnownHost({
    required this.hostId,
    required this.hostName,
    required this.secret,
    this.lastAddress,
    this.lastPort,
  });

  final String hostId;
  final String hostName;
  final String secret;

  /// Where the host was last reached, tried when Bonjour finds nothing.
  final String? lastAddress;
  final int? lastPort;

  ConnectKnownHost copyWith({
    String? hostName,
    String? lastAddress,
    int? lastPort,
  }) => ConnectKnownHost(
    hostId: hostId,
    hostName: hostName ?? this.hostName,
    secret: secret,
    lastAddress: lastAddress ?? this.lastAddress,
    lastPort: lastPort ?? this.lastPort,
  );

  factory ConnectKnownHost.fromJson(Map<String, dynamic> json) =>
      ConnectKnownHost(
        hostId: json['hostId'] as String,
        hostName: json['hostName'] as String? ?? 'Songbrook',
        secret: json['secret'] as String,
        lastAddress: json['lastAddress'] as String?,
        lastPort: (json['lastPort'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'hostId': hostId,
    'hostName': hostName,
    'secret': secret,
    if (lastAddress != null) 'lastAddress': lastAddress,
    if (lastPort != null) 'lastPort': lastPort,
  };
}

/// Songbrook Connect's persistent identity and pairings, all in the keychain:
/// this device's id, the devices paired with it as a host, and the hosts it
/// has paired with as a client.
class ConnectStore {
  ConnectStore(this._store, {String Function()? newId})
    : _newId = newId ?? const Uuid().v4;

  static const _deviceIdKey = 'songbrook.connect.device_id.v1';
  static const _pairedDevicesKey = 'songbrook.connect.paired_devices.v1';
  static const _knownHostsKey = 'songbrook.connect.known_hosts.v1';

  final ConnectSecureStore _store;
  final String Function() _newId;

  /// Stable for this installation; created on first use.
  Future<String> deviceId() async {
    final existing = await _store.read(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = _newId();
    await _store.write(_deviceIdKey, created);
    return created;
  }

  Future<List<ConnectPairedDevice>> pairedDevices() async => (await _readList(
    _pairedDevicesKey,
  )).map(ConnectPairedDevice.fromJson).toList(growable: false);

  Future<void> savePairedDevice(ConnectPairedDevice device) async {
    final devices = [
      for (final existing in await pairedDevices())
        if (existing.id != device.id) existing,
      device,
    ];
    await _writeList(_pairedDevicesKey, devices.map((d) => d.toJson()));
  }

  Future<void> removePairedDevice(String deviceId) async {
    final devices = await pairedDevices();
    await _writeList(
      _pairedDevicesKey,
      devices.where((d) => d.id != deviceId).map((d) => d.toJson()),
    );
  }

  Future<List<ConnectKnownHost>> knownHosts() async => (await _readList(
    _knownHostsKey,
  )).map(ConnectKnownHost.fromJson).toList(growable: false);

  Future<void> saveKnownHost(ConnectKnownHost host) async {
    final hosts = [
      for (final existing in await knownHosts())
        if (existing.hostId != host.hostId) existing,
      host,
    ];
    await _writeList(_knownHostsKey, hosts.map((h) => h.toJson()));
  }

  Future<void> removeKnownHost(String hostId) async {
    final hosts = await knownHosts();
    await _writeList(
      _knownHostsKey,
      hosts.where((h) => h.hostId != hostId).map((h) => h.toJson()),
    );
  }

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final raw = await _store.read(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> _writeList(String key, Iterable<Map<String, dynamic>> items) =>
      _store.write(key, jsonEncode(items.toList(growable: false)));
}
