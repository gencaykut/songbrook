import 'dart:convert';
import 'dart:io';

import 'package:bstream_music/services/connect/connect_auth.dart';
import 'package:bstream_music/services/connect/connect_client.dart';
import 'package:bstream_music/services/connect/connect_envelope.dart';
import 'package:bstream_music/services/connect/connect_host_server.dart';
import 'package:bstream_music/services/connect/connect_hub.dart';
import 'package:bstream_music/services/connect/connect_models.dart';
import 'package:bstream_music/services/connect/connect_pairing_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  late ConnectHub hub;
  late ConnectHostServer server;
  late Uri baseUrl;
  final paired = <ConnectPairedDevice>[];
  final clients = <ConnectClient>[];

  setUp(() async {
    paired.clear();
    hub = ConnectHub();
    server = ConnectHostServer(
      hostId: 'mac-host',
      hostName: 'Studio Mac',
      hub: hub,
      onPaired: (device) async => paired.add(device),
    );
    final port = await server.start(
      preferredPort: 0,
      address: InternetAddress.loopbackIPv4,
    );
    baseUrl = Uri.parse('http://127.0.0.1:$port');
  });

  tearDown(() async {
    for (final client in clients) {
      await client.dispose();
    }
    clients.clear();
    await server.stop();
    hub.dispose();
  });

  ConnectClient client(String deviceId, {String type = 'mobile'}) {
    final created = ConnectClient(
      deviceId: deviceId,
      deviceName: deviceId,
      clientType: type,
      snapshotProvider: () => ConnectPlaybackSnapshot.fromJson(const {}),
      applySnapshot: (_) async {},
      handleCommand: (_, _) async {},
      pauseForTransfer: () async {},
    );
    clients.add(created);
    return created;
  }

  Future<void> eventually(bool Function() condition) async {
    for (var i = 0; i < 200 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(condition(), isTrue);
  }

  Future<ConnectHostPairing> pair(String code, {String deviceId = 'phone'}) =>
      pairWithConnectHost(
        baseUrl: baseUrl,
        code: code,
        deviceId: deviceId,
        deviceName: 'iPhone',
        deviceType: 'mobile',
      );

  test('a device pairs with the shown code and then connects', () async {
    final code = server.beginPairing();
    final pairing = await pair(code.code);

    expect(pairing.hostId, 'mac-host');
    expect(pairing.hostName, 'Studio Mac');
    expect(paired.single.id, 'phone');
    expect(paired.single.secret, pairing.secret);
    expect(server.activePairingCode, isNull);

    final phone = client('phone');
    await phone.connect(
      baseUrl: '$baseUrl',
      sessionTokenProvider: () => createConnectAuthToken(
        hostId: pairing.hostId,
        deviceId: 'phone',
        secret: pairing.secret,
      ),
    );
    await eventually(() => phone.devices.any((device) => device.id == 'phone'));
    expect(phone.isConnected, isTrue);
  });

  test('two paired devices see each other', () async {
    final first = await pair(server.beginPairing().code);
    final second = await pair(server.beginPairing().code, deviceId: 'mac');

    final phone = client('phone');
    final mac = client('mac', type: 'desktop');
    for (final (connectClient, pairing, id) in [
      (phone, first, 'phone'),
      (mac, second, 'mac'),
    ]) {
      await connectClient.connect(
        baseUrl: '$baseUrl',
        sessionTokenProvider: () => createConnectAuthToken(
          hostId: pairing.hostId,
          deviceId: id,
          secret: pairing.secret,
        ),
      );
    }
    await eventually(
      () => phone.devices.map((device) => device.id).toSet().containsAll({
        'phone',
        'mac',
      }),
    );
  });

  test('a wrong code is refused and the code survives', () async {
    final code = server.beginPairing();
    final wrong = code.code == '123456' ? '654321' : '123456';
    await expectLater(
      pair(wrong),
      throwsA(
        isA<ConnectPairingException>().having(
          (error) => error.code,
          'code',
          'WRONG_CODE',
        ),
      ),
    );
    expect(paired, isEmpty);
    expect(server.activePairingCode, isNotNull);
    await pair(code.code);
    expect(paired, hasLength(1));
  });

  test('pairing without a shown code is refused', () async {
    await expectLater(
      pair('000000'),
      throwsA(
        isA<ConnectPairingException>().having(
          (error) => error.code,
          'code',
          'NO_CODE',
        ),
      ),
    );
  });

  Future<int?> identifyAndWaitForClose(Map<String, dynamic> identify) async {
    final socket = WebSocketChannel.connect(
      baseUrl.replace(scheme: 'ws', path: kConnectSocketPath),
    );
    await socket.ready;
    socket.sink.add(
      jsonEncode(
        WsMessage(type: WsMessageType.identify, data: identify).toJson(),
      ),
    );
    await socket.stream.drain<void>().timeout(const Duration(seconds: 5));
    return socket.closeCode;
  }

  test('an unpaired device or a bad token is disconnected', () async {
    expect(
      await identifyAndWaitForClose({
        'deviceId': 'stranger',
        'deviceName': 'Stranger',
        'clientType': 'mobile',
        'sessionToken': 'v1.1.a.b',
      }),
      4001,
    );

    final pairing = await pair(server.beginPairing().code);
    expect(
      await identifyAndWaitForClose({
        'deviceId': 'phone',
        'deviceName': 'iPhone',
        'clientType': 'mobile',
        'sessionToken': createConnectAuthToken(
          hostId: 'mac-host',
          deviceId: 'phone',
          secret: generateConnectSecret(),
        ),
      }),
      4001,
    );

    // A token captured from a successful identify cannot be replayed.
    final token = createConnectAuthToken(
      hostId: pairing.hostId,
      deviceId: 'phone',
      secret: pairing.secret,
    );
    final first = WebSocketChannel.connect(
      baseUrl.replace(scheme: 'ws', path: kConnectSocketPath),
    );
    await first.ready;
    first.sink.add(
      jsonEncode(
        WsMessage(
          type: WsMessageType.identify,
          data: {
            'deviceId': 'phone',
            'deviceName': 'iPhone',
            'clientType': 'mobile',
            'sessionToken': token,
          },
        ).toJson(),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(
      await identifyAndWaitForClose({
        'deviceId': 'phone',
        'deviceName': 'iPhone',
        'clientType': 'mobile',
        'sessionToken': token,
      }),
      4001,
    );
    await first.sink.close();
  });

  test('a socket that never identifies is closed', () async {
    await server.stop();
    server = ConnectHostServer(
      hostId: 'mac-host',
      hostName: 'Studio Mac',
      hub: hub,
      identifyTimeout: const Duration(milliseconds: 200),
    );
    final port = await server.start(
      preferredPort: 0,
      address: InternetAddress.loopbackIPv4,
    );
    final socket = WebSocketChannel.connect(
      Uri.parse('ws://127.0.0.1:$port$kConnectSocketPath'),
    );
    await socket.ready;
    await socket.stream.drain<void>().timeout(const Duration(seconds: 5));
    expect(socket.closeCode, 4008);
  });

  test('revoking a device disconnects it for good', () async {
    final pairing = await pair(server.beginPairing().code);
    final phone = client('phone');
    await phone.connect(
      baseUrl: '$baseUrl',
      sessionTokenProvider: () => createConnectAuthToken(
        hostId: pairing.hostId,
        deviceId: 'phone',
        secret: pairing.secret,
      ),
    );
    await eventually(() => phone.devices.isNotEmpty);

    server.revoke('phone');
    await eventually(() => !phone.isConnected);
    expect(server.pairedDevices, isEmpty);
  });
}
