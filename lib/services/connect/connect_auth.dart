import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// How far an identify token's timestamp may be from the host's clock.
const Duration kConnectAuthTokenWindow = Duration(minutes: 5);

/// How long a pairing code shown on the host stays valid.
const Duration kConnectPairingCodeLifetime = Duration(minutes: 2);

/// Wrong codes allowed before the shown code is discarded.
const int kConnectPairingMaxAttempts = 5;

const String _tokenVersion = 'v1';

/// A new random pairing secret, shared by the host and one paired device.
String generateConnectSecret([Random? random]) {
  final source = random ?? Random.secure();
  return base64Url.encode(List<int>.generate(32, (_) => source.nextInt(256)));
}

/// Proves to the host that this device holds its pairing [secret] without
/// sending it. Each token carries a fresh nonce, so the host rejects a token
/// seen on the network if it is sent again.
String createConnectAuthToken({
  required String hostId,
  required String deviceId,
  required String secret,
  DateTime? now,
  Random? random,
}) {
  final source = random ?? Random.secure();
  final milliseconds = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final nonce = base64Url
      .encode(List<int>.generate(16, (_) => source.nextInt(256)))
      .replaceAll('=', '');
  final mac = _tokenMac(
    secret: secret,
    hostId: hostId,
    deviceId: deviceId,
    milliseconds: milliseconds,
    nonce: nonce,
  );
  return '$_tokenVersion.$milliseconds.$nonce.$mac';
}

String _tokenMac({
  required String secret,
  required String hostId,
  required String deviceId,
  required int milliseconds,
  required String nonce,
}) {
  final key = base64Url.decode(secret);
  final message = utf8.encode(
    'songbrook-connect-$_tokenVersion|$hostId|$deviceId|$milliseconds|$nonce',
  );
  return base64Url
      .encode(Hmac(sha256, key).convert(message).bytes)
      .replaceAll('=', '');
}

/// Checks identify tokens on the host and remembers recent nonces so a
/// captured token cannot be replayed within its validity window.
class ConnectAuthVerifier {
  ConnectAuthVerifier({
    this.window = kConnectAuthTokenWindow,
    DateTime Function()? now,
    this.maxRememberedNonces = 4096,
  }) : _now = now ?? DateTime.now;

  final Duration window;
  final int maxRememberedNonces;
  final DateTime Function() _now;
  final LinkedHashMap<String, int> _seenNonces = LinkedHashMap<String, int>();

  bool verify({
    required String token,
    required String hostId,
    required String deviceId,
    required String secret,
  }) {
    final parts = token.split('.');
    if (parts.length != 4 || parts[0] != _tokenVersion) return false;
    final milliseconds = int.tryParse(parts[1]);
    final nonce = parts[2];
    if (milliseconds == null || nonce.isEmpty || nonce.length > 64) {
      return false;
    }
    final now = _now().millisecondsSinceEpoch;
    if ((now - milliseconds).abs() > window.inMilliseconds) return false;
    final String expected;
    try {
      expected = _tokenMac(
        secret: secret,
        hostId: hostId,
        deviceId: deviceId,
        milliseconds: milliseconds,
        nonce: nonce,
      );
    } on FormatException {
      return false;
    }
    if (!_constantTimeEquals(expected, parts[3])) return false;
    _forgetExpiredNonces(now);
    final key = '$deviceId|$nonce';
    if (_seenNonces.containsKey(key)) return false;
    _seenNonces[key] = milliseconds;
    while (_seenNonces.length > maxRememberedNonces) {
      _seenNonces.remove(_seenNonces.keys.first);
    }
    return true;
  }

  void _forgetExpiredNonces(int now) {
    _seenNonces.removeWhere(
      (_, milliseconds) => (now - milliseconds).abs() > window.inMilliseconds,
    );
  }
}

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return difference == 0;
}

enum ConnectPairingFailure { noCode, wrongCode, expired, tooManyAttempts }

/// The six-digit code the host shows while it is ready to pair. It is valid
/// for [kConnectPairingCodeLifetime], for one device, and is discarded after
/// [kConnectPairingMaxAttempts] wrong guesses.
class ConnectPairingCode {
  ConnectPairingCode._(this.code, this.expiresAt);

  factory ConnectPairingCode.generate({DateTime? now, Random? random}) {
    final source = random ?? Random.secure();
    final code = source.nextInt(1000000).toString().padLeft(6, '0');
    return ConnectPairingCode._(
      code,
      (now ?? DateTime.now()).add(kConnectPairingCodeLifetime),
    );
  }

  final String code;
  final DateTime expiresAt;
  int _wrongAttempts = 0;
  bool _used = false;

  bool isActive(DateTime now) =>
      !_used &&
      _wrongAttempts < kConnectPairingMaxAttempts &&
      now.isBefore(expiresAt);

  /// Returns null when [attempt] is correct; the code is then spent.
  ConnectPairingFailure? redeem(String attempt, DateTime now) {
    if (_used) return ConnectPairingFailure.noCode;
    if (_wrongAttempts >= kConnectPairingMaxAttempts) {
      return ConnectPairingFailure.tooManyAttempts;
    }
    if (!now.isBefore(expiresAt)) return ConnectPairingFailure.expired;
    if (!_constantTimeEquals(attempt.trim(), code)) {
      _wrongAttempts++;
      return _wrongAttempts >= kConnectPairingMaxAttempts
          ? ConnectPairingFailure.tooManyAttempts
          : ConnectPairingFailure.wrongCode;
    }
    _used = true;
    return null;
  }
}
