import 'dart:math';

import 'package:bstream_music/services/connect/connect_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final secret = generateConnectSecret(Random(1));
  final otherSecret = generateConnectSecret(Random(2));
  final now = DateTime.utc(2026, 10, 26, 12);

  ConnectAuthVerifier verifier([DateTime? at]) =>
      ConnectAuthVerifier(now: () => at ?? now);

  String token({String deviceId = 'phone', DateTime? at, int seed = 3}) =>
      createConnectAuthToken(
        hostId: 'mac',
        deviceId: deviceId,
        secret: secret,
        now: at ?? now,
        random: Random(seed),
      );

  group('identify token', () {
    test('a token made with the shared secret is accepted once', () {
      final check = verifier();
      final value = token();
      expect(
        check.verify(
          token: value,
          hostId: 'mac',
          deviceId: 'phone',
          secret: secret,
        ),
        isTrue,
      );
      // The same token seen again on the network is a replay.
      expect(
        check.verify(
          token: value,
          hostId: 'mac',
          deviceId: 'phone',
          secret: secret,
        ),
        isFalse,
      );
    });

    test('another secret, device or host is rejected', () {
      final check = verifier();
      expect(
        check.verify(
          token: token(),
          hostId: 'mac',
          deviceId: 'phone',
          secret: otherSecret,
        ),
        isFalse,
      );
      expect(
        check.verify(
          token: token(seed: 4),
          hostId: 'mac',
          deviceId: 'tablet',
          secret: secret,
        ),
        isFalse,
      );
      expect(
        check.verify(
          token: token(seed: 5),
          hostId: 'other-mac',
          deviceId: 'phone',
          secret: secret,
        ),
        isFalse,
      );
    });

    test('a token outside the time window is rejected', () {
      final old = token(at: now.subtract(const Duration(minutes: 6)));
      final future = token(at: now.add(const Duration(minutes: 6)), seed: 4);
      final check = verifier();
      for (final value in [old, future]) {
        expect(
          check.verify(
            token: value,
            hostId: 'mac',
            deviceId: 'phone',
            secret: secret,
          ),
          isFalse,
        );
      }
    });

    test('malformed tokens are rejected', () {
      final check = verifier();
      for (final value in ['', 'v1', 'v2.1.a.b', 'v1.x.a.b', 'v1.1..b']) {
        expect(
          check.verify(
            token: value,
            hostId: 'mac',
            deviceId: 'phone',
            secret: secret,
          ),
          isFalse,
          reason: value,
        );
      }
    });
  });

  group('pairing code', () {
    test('is six digits and works once', () {
      final code = ConnectPairingCode.generate(now: now, random: Random(7));
      expect(code.code, matches(RegExp(r'^\d{6}$')));
      expect(code.redeem(code.code, now), isNull);
      expect(code.redeem(code.code, now), ConnectPairingFailure.noCode);
      expect(code.isActive(now), isFalse);
    });

    test('expires after two minutes', () {
      final code = ConnectPairingCode.generate(now: now, random: Random(7));
      final later = now.add(kConnectPairingCodeLifetime);
      expect(code.isActive(later), isFalse);
      expect(code.redeem(code.code, later), ConnectPairingFailure.expired);
    });

    test('is discarded after five wrong guesses', () {
      final code = ConnectPairingCode.generate(now: now, random: Random(7));
      final wrong = code.code == '000000' ? '000001' : '000000';
      for (var i = 0; i < kConnectPairingMaxAttempts - 1; i++) {
        expect(code.redeem(wrong, now), ConnectPairingFailure.wrongCode);
      }
      expect(code.redeem(wrong, now), ConnectPairingFailure.tooManyAttempts);
      expect(
        code.redeem(code.code, now),
        ConnectPairingFailure.tooManyAttempts,
      );
    });
  });
}
