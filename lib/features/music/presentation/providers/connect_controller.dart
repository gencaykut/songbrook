import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/platform/app_platform.dart';
import '../../../../services/connect/connect_auth.dart';
import '../../../../services/connect/connect_client.dart';
import '../../../../services/connect/connect_discovery.dart';
import '../../../../services/connect/connect_host_server.dart';
import '../../../../services/connect/connect_hub.dart';
import '../../../../services/connect/connect_models.dart';
import '../../../../services/connect/connect_pairing_client.dart';
import '../../../../services/connect/connect_store.dart';
import '../../../../services/connect/remote_playback.dart';
import 'connect_playback.dart';
import 'music_providers.dart' show ConnectRemoteControl;

/// The feature's name, the same in every language.
const String kConnectProductName = 'Songbrook Connect';

/// Whether this device runs the Connect hub (the Mac) or joins one.
final connectIsHostProvider = Provider<bool>(
  (ref) => AppPlatform.current == AppPlatformType.macos,
);

final connectStoreProvider = Provider<ConnectStore>(
  (ref) => ConnectStore(const FlutterConnectSecureStore()),
);

final connectBroadcasterProvider = Provider<ConnectBroadcaster>(
  (ref) => BonsoirConnectBroadcaster(),
);

final connectHostDiscoveryProvider = Provider<ConnectHostDiscovery>(
  (ref) => BonsoirConnectHostDiscovery(),
);

/// The port the Mac tries first; tests use any free port.
final connectHostPortProvider = Provider<int>((ref) => kConnectPreferredPort);

/// Fires each time the app comes back to the front. iOS suspends an app
/// that is not playing, and a socket it held looks open afterwards while
/// it is dead.
final connectAppResumedProvider = Provider<Stream<void>>((ref) {
  final resumes = StreamController<void>.broadcast();
  final listener = AppLifecycleListener(onResume: () => resumes.add(null));
  ref.onDispose(() {
    listener.dispose();
    unawaited(resumes.close());
  });
  return resumes.stream;
});

final connectEnabledStoreProvider = Provider<ConnectEnabledStore>(
  (ref) => const SharedPreferencesConnectEnabledStore(),
);

final connectControllerProvider =
    NotifierProvider<ConnectController, ConnectState>(ConnectController.new);

/// The Connect switch is not a secret, so it lives in plain preferences.
abstract interface class ConnectEnabledStore {
  Future<bool> read();

  Future<void> write(bool enabled);
}

class SharedPreferencesConnectEnabledStore implements ConnectEnabledStore {
  const SharedPreferencesConnectEnabledStore();

  static const _key = 'songbrook.connect.enabled.v1';

  @override
  Future<bool> read() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  @override
  Future<void> write(bool enabled) async =>
      (await SharedPreferences.getInstance()).setBool(_key, enabled);
}

@immutable
class ConnectState {
  const ConnectState({
    this.loaded = false,
    this.enabled = false,
    this.isHost = false,
    this.deviceName = '',
    this.pairingCode,
    this.pairingExpiresAt,
    this.pairedDevices = const [],
    this.knownHosts = const [],
    this.discoveredHosts = const [],
    this.connectedHostId,
    this.isConnected = false,
    this.devices = const [],
    this.selfDeviceId,
    this.activeDeviceId,
    this.playback,
    this.playbackReceivedAt,
    this.errorMessage,
  });

  final bool loaded;
  final bool enabled;
  final bool isHost;
  final String deviceName;

  /// Host only: the code to type on the device being paired.
  final String? pairingCode;
  final DateTime? pairingExpiresAt;

  /// Host only: devices paired with this Mac, this Mac excluded.
  final List<ConnectPairedDevice> pairedDevices;

  /// Client only: hosts this device has paired with.
  final List<ConnectKnownHost> knownHosts;

  /// Client only: hosts currently seen on the LAN.
  final List<ConnectDiscoveredHost> discoveredHosts;
  final String? connectedHostId;
  final bool isConnected;

  /// Every Songbrook device in the session, this one included.
  final List<ConnectDevice> devices;

  /// This device's id in [devices].
  final String? selfDeviceId;
  final String? activeDeviceId;

  /// The session's playback as the owner last published it.
  final ConnectPlaybackSnapshot? playback;

  /// When [playback] arrived, on this device's clock.
  final DateTime? playbackReceivedAt;

  /// An error code or a message for diagnostics; see [pairingRemovedError].
  final String? errorMessage;

  /// The Mac no longer accepts this device; it has to pair again.
  static const pairingRemovedError = 'PAIRING_REMOVED';

  ConnectState copyWith({
    bool? loaded,
    bool? enabled,
    bool? isHost,
    String? deviceName,
    Object? pairingCode = _unset,
    Object? pairingExpiresAt = _unset,
    List<ConnectPairedDevice>? pairedDevices,
    List<ConnectKnownHost>? knownHosts,
    List<ConnectDiscoveredHost>? discoveredHosts,
    Object? connectedHostId = _unset,
    bool? isConnected,
    List<ConnectDevice>? devices,
    Object? selfDeviceId = _unset,
    Object? activeDeviceId = _unset,
    Object? playback = _unset,
    Object? playbackReceivedAt = _unset,
    Object? errorMessage = _unset,
  }) => ConnectState(
    loaded: loaded ?? this.loaded,
    enabled: enabled ?? this.enabled,
    isHost: isHost ?? this.isHost,
    deviceName: deviceName ?? this.deviceName,
    pairingCode: identical(pairingCode, _unset)
        ? this.pairingCode
        : pairingCode as String?,
    pairingExpiresAt: identical(pairingExpiresAt, _unset)
        ? this.pairingExpiresAt
        : pairingExpiresAt as DateTime?,
    pairedDevices: pairedDevices ?? this.pairedDevices,
    knownHosts: knownHosts ?? this.knownHosts,
    discoveredHosts: discoveredHosts ?? this.discoveredHosts,
    connectedHostId: identical(connectedHostId, _unset)
        ? this.connectedHostId
        : connectedHostId as String?,
    isConnected: isConnected ?? this.isConnected,
    devices: devices ?? this.devices,
    selfDeviceId: identical(selfDeviceId, _unset)
        ? this.selfDeviceId
        : selfDeviceId as String?,
    activeDeviceId: identical(activeDeviceId, _unset)
        ? this.activeDeviceId
        : activeDeviceId as String?,
    playback: identical(playback, _unset)
        ? this.playback
        : playback as ConnectPlaybackSnapshot?,
    playbackReceivedAt: identical(playbackReceivedAt, _unset)
        ? this.playbackReceivedAt
        : playbackReceivedAt as DateTime?,
    errorMessage: identical(errorMessage, _unset)
        ? this.errorMessage
        : errorMessage as String?,
  );
}

const _unset = Object();

/// Runs Songbrook Connect for this device: on the Mac the hub, its network
/// server, the Bonjour advertisement and the Mac's own session client; on a
/// phone the discovery of paired Macs and the session client.
///
/// The device whose player is in use owns the session: it publishes its
/// queue and state, and runs the commands the other devices send. Playing
/// something here makes this device the owner.
class ConnectController extends Notifier<ConnectState> {
  ConnectHub? _hub;
  ConnectHostServer? _server;
  ConnectClient? _client;
  StreamSubscription<List<ConnectDiscoveredHost>>? _discoverySubscription;
  StreamSubscription<ConnectPlaybackChange>? _playbackSubscription;
  StreamSubscription<void>? _resumeSubscription;
  Uri? _clientBaseUrl;
  String? _deviceId;
  Future<void> _transition = Future<void>.value();

  ConnectBroadcaster? _broadcaster;
  ConnectHostDiscovery? _discovery;
  bool _disposed = false;

  @override
  ConnectState build() {
    _broadcaster = ref.read(connectBroadcasterProvider);
    _discovery = ref.read(connectHostDiscoveryProvider);
    ref.onDispose(() {
      _disposed = true;
      unawaited(_resumeSubscription?.cancel());
      unawaited(_releaseResources());
    });
    final isHost = ref.watch(connectIsHostProvider);
    // Breadcrumbs for field problems; release builds stay quiet.
    if (!kReleaseMode) {
      ConnectClient.logger ??= (message) => debugPrint('[Connect] $message');
    }
    if (!isHost) {
      _resumeSubscription = ref
          .read(connectAppResumedProvider)
          .listen((_) => unawaited(reconnect()));
    }
    unawaited(_load());
    return ConnectState(isHost: isHost, deviceName: _localDeviceName(isHost));
  }

  ConnectStore get _store => ref.read(connectStoreProvider);

  Future<void> _load() async {
    final bool enabled;
    final List<ConnectKnownHost> knownHosts;
    final List<ConnectPairedDevice> pairedDevices;
    try {
      enabled = await ref.read(connectEnabledStoreProvider).read();
      knownHosts = await _store.knownHosts();
      pairedDevices = await _visiblePairedDevices();
    } catch (error) {
      // Without the keychain Connect stays off; the rest of the app is fine.
      debugPrint('[Connect] Could not load pairings: $error');
      _patch((current) => current.copyWith(loaded: true));
      return;
    }
    if (_disposed) return;
    _patch(
      (current) => current.copyWith(
        loaded: true,
        enabled: enabled,
        knownHosts: knownHosts,
        pairedDevices: pairedDevices,
      ),
    );
    if (enabled) await _serialized(_startAll);
  }

  Future<void> setEnabled(bool enabled) async {
    if (enabled == state.enabled) return;
    _patch((current) => current.copyWith(enabled: enabled, errorMessage: null));
    await ref.read(connectEnabledStoreProvider).write(enabled);
    await _serialized(enabled ? _startAll : _stopAll);
  }

  /// Host: shows a fresh six-digit code for the next device.
  void beginPairing() {
    final code = _server?.beginPairing();
    if (code == null) return;
    _patch(
      (current) => current.copyWith(
        pairingCode: code.code,
        pairingExpiresAt: code.expiresAt,
      ),
    );
  }

  void cancelPairing() {
    _server?.cancelPairing();
    _patch(
      (current) => current.copyWith(pairingCode: null, pairingExpiresAt: null),
    );
  }

  /// Host: forgets a paired device and disconnects it.
  Future<void> revokeDevice(String deviceId) async {
    _server?.revoke(deviceId);
    await _store.removePairedDevice(deviceId);
    final updated0 = await _visiblePairedDevices();
    _patch((current) => current.copyWith(pairedDevices: updated0));
  }

  /// Client: pairs with [host] using the code shown on it, then connects.
  /// Throws [ConnectPairingException] with the host's reason.
  Future<void> pairWithHost(ConnectDiscoveredHost host, String code) async {
    final baseUrl = host.baseUrl;
    if (baseUrl == null) throw const ConnectPairingException('UNREACHABLE');
    final pairing = await pairWithConnectHost(
      baseUrl: baseUrl,
      code: code,
      deviceId: await _ensureDeviceId(),
      deviceName: state.deviceName,
      deviceType: _clientType,
    );
    final known = ConnectKnownHost(
      hostId: pairing.hostId,
      hostName: pairing.hostName,
      secret: pairing.secret,
      lastAddress: baseUrl.host,
      lastPort: baseUrl.port,
    );
    await _store.saveKnownHost(known);
    final updated1 = await _store.knownHosts();
    _patch((current) => current.copyWith(knownHosts: updated1));
    await _serialized(() => _connectToKnownHost(known, baseUrl));
  }

  /// Client: forgets a host; pairing with it again needs a new code.
  Future<void> forgetHost(String hostId) async {
    await _store.removeKnownHost(hostId);
    if (state.connectedHostId == hostId) {
      await _serialized(_disconnectClient);
    }
    final updated2 = await _store.knownHosts();
    _patch((current) => current.copyWith(knownHosts: updated2));
  }

  /// Client: connects to the paired Mac again now: when the app comes back
  /// to the front, or when its card is tapped. A socket that is still open
  /// is reopened (after a suspension it can look open while it is dead);
  /// otherwise Bonjour is searched afresh and the Mac is reached at the
  /// address it is seen at, or at its last one.
  Future<void> reconnect() => _serialized(_reconnect);

  Future<void> _reconnect() async {
    if (!state.enabled || state.isHost || state.knownHosts.isEmpty) return;
    final client = _client;
    if (client != null && client.isConnected) {
      await client.refreshState();
      return;
    }
    await _stopDiscovery();
    await _disconnectClient();
    await _startDiscovery();
  }

  /// Applies [change] unless the controller is gone; async work can finish
  /// after the provider was disposed.
  void _patch(ConnectState Function(ConnectState current) change) {
    if (_disposed) return;
    state = change(state);
  }

  Future<void> _serialized(Future<void> Function() action) {
    final next = _transition.then((_) => action()).catchError((Object error) {
      debugPrint('[Connect] $error');
      _patch((current) => current.copyWith(errorMessage: '$error'));
    });
    _transition = next;
    return next;
  }

  String get _clientType => state.isHost ? 'desktop' : 'mobile';

  Future<String> _ensureDeviceId() async =>
      _deviceId ??= await _store.deviceId();

  Future<List<ConnectPairedDevice>> _visiblePairedDevices() async {
    final deviceId = await _ensureDeviceId();
    return (await _store.pairedDevices())
        .where((device) => device.id != deviceId)
        .toList(growable: false);
  }

  Future<void> _startAll() async {
    if (!state.enabled) return;
    if (state.isHost) {
      await _startHost();
    } else {
      await _startDiscovery();
    }
  }

  Future<void> _startHost() async {
    if (_server != null) return;
    final deviceId = await _ensureDeviceId();
    final hub = ConnectHub();
    final server = ConnectHostServer(
      hostId: deviceId,
      hostName: state.deviceName,
      hub: hub,
      pairedDevices: await _store.pairedDevices(),
      onPaired: (device) async {
        await _store.savePairedDevice(device);
        final updated3 = await _visiblePairedDevices();
        _patch(
          (current) => current.copyWith(
            pairedDevices: updated3,
            pairingCode: null,
            pairingExpiresAt: null,
          ),
        );
      },
    );
    // The Mac's own player joins its hub like any paired device.
    var self = (await _store.pairedDevices()).where((d) => d.id == deviceId);
    if (self.isEmpty) {
      final created = ConnectPairedDevice(
        id: deviceId,
        name: state.deviceName,
        type: 'desktop',
        secret: generateConnectSecret(),
        pairedAt: DateTime.now().toUtc(),
      );
      await _store.savePairedDevice(created);
      self = [created];
    }
    server.trustDevice(self.first);
    final port = await server.start(
      preferredPort: ref.read(connectHostPortProvider),
    );
    _hub = hub;
    _server = server;
    try {
      await _broadcaster!.start(
        hostId: deviceId,
        name: state.deviceName,
        port: port,
      );
    } catch (error) {
      // Paired devices can still reach the Mac at its last address.
      debugPrint('[Connect] Bonjour advertisement failed: $error');
    }
    final selfSecret = self.first.secret;
    await _openClient(
      baseUrl: Uri(scheme: 'http', host: '127.0.0.1', port: port),
      hostId: deviceId,
      secret: selfSecret,
    );
    _patch((current) => current.copyWith(connectedHostId: deviceId));
  }

  Future<void> _startDiscovery() async {
    if (_discoverySubscription != null) return;
    final discovery = _discovery!;
    _discoverySubscription = discovery.hosts.listen(_onHostsDiscovered);
    await discovery.start();
    // Bonjour can be slow or blocked; try the last address of a known host.
    final known = state.knownHosts;
    if (_client == null && known.isNotEmpty) {
      final host = known.first;
      if (host.lastAddress != null && host.lastPort != null) {
        await _connectToKnownHost(
          host,
          Uri(scheme: 'http', host: host.lastAddress, port: host.lastPort),
        );
      }
    }
  }

  void _onHostsDiscovered(List<ConnectDiscoveredHost> hosts) {
    _patch((current) => current.copyWith(discoveredHosts: hosts));
    final client = _client;
    if (client != null) {
      // Still trying an address the Mac is no longer at: go where it is.
      if (client.isConnected) return;
      for (final host in hosts) {
        final known = state.knownHosts.where((k) => k.hostId == host.hostId);
        final baseUrl = host.baseUrl;
        if (known.isNotEmpty &&
            baseUrl != null &&
            host.hostId == state.connectedHostId &&
            baseUrl != _clientBaseUrl) {
          unawaited(
            _serialized(() async {
              await _disconnectClient();
              await _connectToKnownHost(known.first, baseUrl);
            }),
          );
          return;
        }
      }
      return;
    }
    for (final host in hosts) {
      final known = state.knownHosts.where((k) => k.hostId == host.hostId);
      final baseUrl = host.baseUrl;
      if (known.isNotEmpty && baseUrl != null) {
        unawaited(_serialized(() => _connectToKnownHost(known.first, baseUrl)));
        return;
      }
    }
  }

  Future<void> _connectToKnownHost(ConnectKnownHost host, Uri baseUrl) async {
    if (!state.enabled) return;
    final client = _client;
    // A client still retrying an old address must not keep this host from
    // being reached where Bonjour sees it now.
    if (state.connectedHostId == host.hostId &&
        client != null &&
        (client.isConnected || _clientBaseUrl == baseUrl)) {
      return;
    }
    await _disconnectClient();
    await _openClient(
      baseUrl: baseUrl,
      hostId: host.hostId,
      secret: host.secret,
    );
    _patch((current) => current.copyWith(connectedHostId: host.hostId));
    if (host.lastAddress != baseUrl.host || host.lastPort != baseUrl.port) {
      await _store.saveKnownHost(
        host.copyWith(lastAddress: baseUrl.host, lastPort: baseUrl.port),
      );
    }
  }

  Future<void> _openClient({
    required Uri baseUrl,
    required String hostId,
    required String secret,
  }) async {
    final deviceId = await _ensureDeviceId();
    final playback = ref.read(connectPlaybackProvider);
    final client = ConnectClient(
      deviceId: deviceId,
      deviceName: state.deviceName,
      clientType: _clientType,
      supportedCommands: playback.supportedCommands,
      snapshotProvider: playback.snapshot,
      applySnapshot: playback.apply,
      handleCommand: playback.handleCommand,
      pauseForTransfer: playback.pauseForTransfer,
      onChanged: _onClientChanged,
      // The host rejected this device's pairing (it was removed on the Mac).
      onAuthenticationRequired: () {
        if (state.isHost) return;
        unawaited(_onPairingRemoved(hostId));
      },
    );
    _client = client;
    _clientBaseUrl = baseUrl;
    await _playbackSubscription?.cancel();
    _playbackSubscription = playback.changes.listen(
      (change) => _onPlaybackChanged(client, change),
    );
    await client.connect(
      baseUrl: '$baseUrl',
      sessionTokenProvider: () => createConnectAuthToken(
        hostId: hostId,
        deviceId: deviceId,
        secret: secret,
      ),
    );
    // Music already playing here takes over the session; the hub holds the
    // request until this device is welcomed.
    if (playback.snapshot().isPlaying) client.requestLocalTakeover();
    _onClientChanged();
  }

  void _onPlaybackChanged(ConnectClient client, ConnectPlaybackChange change) {
    if (!identical(client, _client)) return;
    if (change.started && !client.isThisDeviceActive) {
      client.requestLocalTakeover();
      return;
    }
    if (change.stopped && client.hasPendingLocalTakeover) {
      client.cancelLocalTakeover();
      return;
    }
    if (client.isThisDeviceActive) client.publishState();
  }

  Future<void> _onPairingRemoved(String hostId) async {
    await forgetHost(hostId);
    _patch(
      (current) =>
          current.copyWith(errorMessage: ConnectState.pairingRemovedError),
    );
  }

  void _onClientChanged() {
    final client = _client;
    if (client == null) return;
    _syncMirror(client);
    _patch(
      (current) => current.copyWith(
        isConnected: client.isConnected,
        devices: List.unmodifiable(client.devices),
        selfDeviceId: client.deviceId,
        activeDeviceId: client.activeDeviceId,
        playback: client.remoteSnapshot,
        playbackReceivedAt: client.remoteSnapshotAt,
      ),
    );
  }

  ConnectPlaybackSnapshot? _mirroredSnapshot;
  ConnectPlayback? _mirroringPlayback;

  /// While another device owns the session, this device's player shows its
  /// playback and sends its controls there.
  void _syncMirror(ConnectClient client) {
    final playback = ref.read(connectPlaybackProvider);
    final owner = client.activeDevice;
    final snapshot = client.remoteSnapshot;
    if (!client.isSessionReady ||
        owner == null ||
        owner.id == client.deviceId ||
        snapshot == null ||
        snapshot.queue.isEmpty) {
      _endMirror();
      return;
    }
    // Only one device plays. This one still does (it kept playing while it
    // was off the network and another device took the session), so it takes
    // the session back rather than mirror the other while its own audio and
    // lock-screen controls carry on unseen.
    if (playback.snapshot().isPlaying) {
      if (!client.hasPendingLocalTakeover) client.requestLocalTakeover();
      _endMirror();
      return;
    }
    // Device-list updates repeat the last snapshot; showing it again would
    // undo the player's optimistic view of a command still on its way.
    if (identical(snapshot, _mirroredSnapshot)) return;
    _mirroredSnapshot = snapshot;
    _mirroringPlayback = playback;
    playback.mirror(
      ConnectRemotePlayback(
        snapshot: snapshot,
        deviceId: owner.id,
        deviceName: owner.name,
        deviceType: owner.type,
        receivedAt: client.remoteSnapshotAt,
      ),
      _ClientRemoteControl(client),
    );
  }

  /// Sends a playback command to the device that owns the session. Commands
  /// are retried until that device answers, so they survive a brief drop.
  void sendCommand(String command, [Map<String, dynamic>? arguments]) {
    _client?.sendCommand(command, arguments);
  }

  void _endMirror() {
    final playback = _mirroringPlayback;
    _mirroredSnapshot = null;
    _mirroringPlayback = null;
    playback?.mirror(null, null);
  }

  /// Moves playback to [deviceId]: it loads the same song, position and
  /// queue, then starts while the current owner goes quiet.
  void transferTo(String deviceId) {
    _client?.transferTo(deviceId);
  }

  Future<void> _disconnectClient() async {
    final client = _client;
    _client = null;
    _clientBaseUrl = null;
    _endMirror();
    await _playbackSubscription?.cancel();
    _playbackSubscription = null;
    await client?.dispose();
    _patch(
      (current) => current.copyWith(
        connectedHostId: null,
        isConnected: false,
        devices: const [],
        activeDeviceId: null,
        playback: null,
        playbackReceivedAt: null,
      ),
    );
  }

  /// Closes sockets and servers without touching provider state.
  Future<void> _releaseResources() async {
    final client = _client;
    _client = null;
    // Providers are going away with this one; the player needs no reset.
    _mirroredSnapshot = null;
    _mirroringPlayback = null;
    await _playbackSubscription?.cancel();
    _playbackSubscription = null;
    await client?.dispose();
    await _stopDiscovery();
    final server = _server;
    _server = null;
    if (server != null) {
      await _broadcaster?.stop();
      await server.stop();
    }
    _hub?.dispose();
    _hub = null;
  }

  Future<void> _stopDiscovery() async {
    final subscription = _discoverySubscription;
    if (subscription == null) return;
    _discoverySubscription = null;
    await subscription.cancel();
    await _discovery?.stop();
  }

  Future<void> _stopAll() async {
    await _disconnectClient();
    await _stopDiscovery();
    final server = _server;
    _server = null;
    if (server != null) {
      await _broadcaster?.stop();
      await server.stop();
    }
    _hub?.dispose();
    _hub = null;
    {
      _patch(
        (current) => current.copyWith(
          discoveredHosts: const [],
          pairingCode: null,
          pairingExpiresAt: null,
        ),
      );
    }
  }
}

class _ClientRemoteControl implements ConnectRemoteControl {
  _ClientRemoteControl(this._client);

  final ConnectClient _client;

  @override
  bool get forwarding =>
      _client.isConnected &&
      !_client.isApplyingRemoteState &&
      !_client.isThisDeviceActive;

  @override
  void send(String command, [Map<String, dynamic>? arguments]) =>
      _client.sendCommand(command, arguments);
}

String _localDeviceName(bool isHost) {
  var name = Platform.localHostname.trim();
  if (name.toLowerCase().endsWith('.local')) {
    name = name.substring(0, name.length - 6);
  }
  name = name.replaceAll('-', ' ').trim();
  if (name.isEmpty || name.toLowerCase() == 'localhost') {
    return isHost ? 'Mac' : 'iPhone';
  }
  return normalizeDeviceDisplayName(name) ?? (isHost ? 'Mac' : 'iPhone');
}
