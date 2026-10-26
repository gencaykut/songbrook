import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'connect_auth.dart';
import 'connect_envelope.dart';
import 'connect_hub.dart';
import 'connect_models.dart';

/// Messages a device sends before it is paired. They never reach the hub.
class ConnectPairingMessageType {
  static const pair = 'connect_pair';
  static const pairResult = 'connect_pair_result';
}

/// The path every Connect client opens (see [ConnectClient]).
const String kConnectSocketPath = '/api/ws';

/// The port the host tries first, so a paired device can still find it at
/// its last address when Bonjour is slow. Any free port is used otherwise.
const int kConnectPreferredPort = 47821;

/// All paired devices share one session: they belong to the same person.
const String _sessionUserId = 'songbrook';

const Set<String> _playbackClientTypes = {'desktop', 'mobile'};

/// A device that holds a pairing secret for this host.
class ConnectPairedDevice {
  const ConnectPairedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.secret,
    required this.pairedAt,
  });

  final String id;
  final String name;
  final String type;
  final String secret;
  final DateTime pairedAt;

  factory ConnectPairedDevice.fromJson(Map<String, dynamic> json) =>
      ConnectPairedDevice(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Unknown device',
        type: json['type'] as String? ?? 'mobile',
        secret: json['secret'] as String,
        pairedAt:
            DateTime.tryParse(json['pairedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'type': type,
    'secret': secret,
    'pairedAt': pairedAt.toUtc().toIso8601String(),
  };
}

/// The Connect hub's network front on the host (the Mac): accepts
/// WebSockets on the LAN, pairs new devices with a six-digit code, checks
/// every device's identify token, and hands authenticated sockets to [hub].
class ConnectHostServer {
  ConnectHostServer({
    required this.hostId,
    required this.hostName,
    required this.hub,
    Iterable<ConnectPairedDevice> pairedDevices = const [],
    this.onPaired,
    this.identifyTimeout = const Duration(seconds: 20),
    this.maxPendingSockets = 16,
    DateTime Function()? now,
    ConnectAuthVerifier? verifier,
  }) : _now = now ?? DateTime.now,
       _verifier = verifier ?? ConnectAuthVerifier(now: now) {
    for (final device in pairedDevices) {
      _paired[device.id] = device;
    }
  }

  final String hostId;
  final String hostName;
  final ConnectHub hub;

  /// Persists a newly paired device. Pairing fails if it throws.
  final Future<void> Function(ConnectPairedDevice device)? onPaired;
  final Duration identifyTimeout;
  final int maxPendingSockets;
  final DateTime Function() _now;
  final ConnectAuthVerifier _verifier;

  final Map<String, ConnectPairedDevice> _paired = {};
  final Map<WebSocketChannel, Timer> _pending = {};
  final Map<WebSocketChannel, String> _authenticated = {};
  HttpServer? _server;
  ConnectPairingCode? _pairingCode;

  int? get port => _server?.port;
  bool get isRunning => _server != null;
  Iterable<ConnectPairedDevice> get pairedDevices => _paired.values;

  /// The code currently shown for pairing, if one is still usable.
  ConnectPairingCode? get activePairingCode {
    final code = _pairingCode;
    return code != null && code.isActive(_now()) ? code : null;
  }

  Future<int> start({
    int preferredPort = kConnectPreferredPort,
    InternetAddress? address,
  }) async {
    if (_server != null) return _server!.port;
    final bindAddress = address ?? InternetAddress.anyIPv6;
    HttpServer server;
    try {
      server = await HttpServer.bind(bindAddress, preferredPort);
    } on SocketException {
      server = await HttpServer.bind(bindAddress, 0);
    }
    _server = server;
    server.listen(_handleRequest, onError: (_) {});
    return server.port;
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    for (final timer in _pending.values) {
      timer.cancel();
    }
    final sockets = <WebSocketChannel>{
      ..._pending.keys,
      ..._authenticated.keys,
    };
    _pending.clear();
    _authenticated.clear();
    for (final socket in sockets) {
      hub.unregister(socket);
      unawaited(socket.sink.close(4000, 'Songbrook is stopping'));
    }
    await server?.close(force: true);
  }

  /// Starts showing a fresh pairing code, replacing any previous one.
  ConnectPairingCode beginPairing() =>
      _pairingCode = ConnectPairingCode.generate(now: _now());

  void cancelPairing() => _pairingCode = null;

  /// Adds a device without a code, such as this host's own player.
  void trustDevice(ConnectPairedDevice device) => _paired[device.id] = device;

  /// Forgets a paired device and disconnects it. It must pair again.
  void revoke(String deviceId) {
    _paired.remove(deviceId);
    final sockets = _authenticated.entries
        .where((entry) => entry.value == deviceId)
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final socket in sockets) {
      _authenticated.remove(socket);
      hub.unregister(socket);
      unawaited(socket.sink.close(4001, 'Pairing removed'));
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path != kConnectSocketPath ||
        !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    if (_pending.length >= maxPendingSockets) {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      await request.response.close();
      return;
    }
    final WebSocket webSocket;
    try {
      webSocket = await WebSocketTransformer.upgrade(request);
    } catch (_) {
      return;
    }
    final socket = IOWebSocketChannel(webSocket);
    _pending[socket] = Timer(identifyTimeout, () {
      if (_pending.remove(socket) != null) {
        hub.unregister(socket);
        unawaited(socket.sink.close(4008, 'Identify timeout'));
      }
    });
    socket.stream
        .asyncMap((raw) => _handleMessage(socket, raw))
        .listen(
          (_) {},
          onDone: () => _forget(socket),
          onError: (_) {
            _forget(socket);
          },
        );
  }

  void _forget(WebSocketChannel socket) {
    _pending.remove(socket)?.cancel();
    _authenticated.remove(socket);
    hub.unregister(socket);
  }

  Future<void> _handleMessage(WebSocketChannel socket, Object? raw) async {
    if (raw is! String || !isConnectRawMessageWithinLimit(raw)) {
      _send(socket, ConnectMessageType.error, const {
        'code': 'INVALID_MESSAGE',
        'message': 'That Connect message is invalid or too large.',
      });
      return;
    }
    final WsMessage message;
    try {
      message = WsMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _send(socket, ConnectMessageType.error, const {
        'code': 'INVALID_MESSAGE',
        'message': 'That Connect message is malformed.',
      });
      return;
    }
    final data = message.data ?? const <String, dynamic>{};
    final authenticated = _authenticated.containsKey(socket);
    switch (message.type) {
      case ConnectPairingMessageType.pair:
        if (!authenticated) await _pair(socket, data);
      case WsMessageType.identify:
        if (!authenticated) _identify(socket, data);
      case WsMessageType.ping:
        if (authenticated) {
          hub.touch(socket);
          socket.sink.add(jsonEncode(PongMessage().toJson()));
        }
      default:
        // A capability offer is retained by the hub until identify succeeds;
        // nothing else is accepted from a device that has not proven itself.
        if (authenticated || message.type == ConnectMessageType.hello) {
          hub.handle(socket, message);
        }
    }
  }

  Future<void> _pair(WebSocketChannel socket, Map<String, dynamic> data) async {
    final code = data['code'];
    final deviceId = data['deviceId'];
    final name = normalizeDeviceDisplayName(data['deviceName'] as String?);
    final type = data['deviceType'];
    if (code is! String ||
        deviceId is! String ||
        deviceId.isEmpty ||
        deviceId.length > 64 ||
        name == null ||
        !_playbackClientTypes.contains(type)) {
      _send(socket, ConnectPairingMessageType.pairResult, const {
        'ok': false,
        'code': 'INVALID_REQUEST',
      });
      return;
    }
    final pairing = _pairingCode;
    final failure = pairing == null
        ? ConnectPairingFailure.noCode
        : pairing.redeem(code, _now());
    if (failure != null) {
      if (failure != ConnectPairingFailure.wrongCode) _pairingCode = null;
      _send(socket, ConnectPairingMessageType.pairResult, {
        'ok': false,
        'code': switch (failure) {
          ConnectPairingFailure.noCode => 'NO_CODE',
          ConnectPairingFailure.wrongCode => 'WRONG_CODE',
          ConnectPairingFailure.expired => 'CODE_EXPIRED',
          ConnectPairingFailure.tooManyAttempts => 'TOO_MANY_ATTEMPTS',
        },
      });
      return;
    }
    _pairingCode = null;
    final device = ConnectPairedDevice(
      id: deviceId,
      name: name,
      type: type as String,
      secret: generateConnectSecret(),
      pairedAt: _now().toUtc(),
    );
    try {
      await onPaired?.call(device);
    } catch (_) {
      _send(socket, ConnectPairingMessageType.pairResult, const {
        'ok': false,
        'code': 'STORAGE_FAILED',
      });
      return;
    }
    _paired[device.id] = device;
    _send(socket, ConnectPairingMessageType.pairResult, {
      'ok': true,
      'hostId': hostId,
      'hostName': hostName,
      'secret': device.secret,
    });
  }

  void _identify(WebSocketChannel socket, Map<String, dynamic> data) {
    final deviceId = data['deviceId'];
    final token = data['sessionToken'];
    final clientType = data['clientType'];
    final device = deviceId is String ? _paired[deviceId] : null;
    if (device == null ||
        token is! String ||
        !_playbackClientTypes.contains(clientType) ||
        !_verifier.verify(
          token: token,
          hostId: hostId,
          deviceId: device.id,
          secret: device.secret,
        )) {
      _pending.remove(socket)?.cancel();
      hub.unregister(socket);
      unawaited(socket.sink.close(4001, 'Authentication required'));
      return;
    }
    _pending.remove(socket)?.cancel();
    _authenticated[socket] = device.id;
    hub.register(
      socket,
      userId: _sessionUserId,
      deviceId: device.id,
      deviceName:
          normalizeDeviceDisplayName(data['deviceName'] as String?) ??
          device.name,
      clientType: clientType as String,
    );
  }

  void _send(WebSocketChannel socket, String type, Map<String, dynamic> data) {
    try {
      socket.sink.add(jsonEncode(WsMessage(type: type, data: data).toJson()));
    } catch (_) {
      // The socket closed while the reply was being built.
    }
  }
}
