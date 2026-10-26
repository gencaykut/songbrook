import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'connect_envelope.dart';
import 'connect_host_server.dart';

/// What a device keeps after pairing with a host.
class ConnectHostPairing {
  const ConnectHostPairing({
    required this.hostId,
    required this.hostName,
    required this.secret,
  });

  final String hostId;
  final String hostName;
  final String secret;
}

class ConnectPairingException implements Exception {
  const ConnectPairingException(this.code);

  /// `WRONG_CODE`, `CODE_EXPIRED`, `TOO_MANY_ATTEMPTS`, `NO_CODE`,
  /// `INVALID_REQUEST`, `STORAGE_FAILED`, `UNREACHABLE` or `NO_REPLY`.
  final String code;

  @override
  String toString() => 'ConnectPairingException($code)';
}

/// Sends the code shown on the host and returns the pairing secret.
Future<ConnectHostPairing> pairWithConnectHost({
  required Uri baseUrl,
  required String code,
  required String deviceId,
  required String deviceName,
  required String deviceType,
  Duration timeout = const Duration(seconds: 10),
  WebSocketChannel Function(Uri uri)? webSocketFactory,
}) async {
  final socketUri = baseUrl.replace(
    scheme: baseUrl.scheme == 'https' ? 'wss' : 'ws',
    path: kConnectSocketPath,
  );
  final socket = (webSocketFactory ?? WebSocketChannel.connect)(socketUri);
  try {
    await socket.ready.timeout(timeout);
  } catch (_) {
    unawaited(socket.sink.close());
    throw const ConnectPairingException('UNREACHABLE');
  }
  try {
    final reply = socket.stream
        .where((raw) => raw is String)
        .map((raw) => WsMessage.fromJson(jsonDecode(raw as String)))
        .firstWhere(
          (message) => message.type == ConnectPairingMessageType.pairResult,
        )
        .timeout(timeout);
    socket.sink.add(
      jsonEncode(
        WsMessage(
          type: ConnectPairingMessageType.pair,
          data: <String, dynamic>{
            'code': code.trim(),
            'deviceId': deviceId,
            'deviceName': deviceName,
            'deviceType': deviceType,
          },
        ).toJson(),
      ),
    );
    final WsMessage result;
    try {
      result = await reply;
    } catch (_) {
      throw const ConnectPairingException('NO_REPLY');
    }
    final data = result.data ?? const <String, dynamic>{};
    final hostId = data['hostId'];
    final hostName = data['hostName'];
    final secret = data['secret'];
    if (data['ok'] != true ||
        hostId is! String ||
        hostName is! String ||
        secret is! String) {
      throw ConnectPairingException(data['code'] as String? ?? 'NO_REPLY');
    }
    return ConnectHostPairing(
      hostId: hostId,
      hostName: hostName,
      secret: secret,
    );
  } finally {
    unawaited(socket.sink.close());
  }
}
