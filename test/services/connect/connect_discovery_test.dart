import 'package:bstream_music/services/connect/connect_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ConnectDiscoveredHost host(List<String> addresses) => ConnectDiscoveredHost(
    hostId: 'mac',
    name: 'Mac',
    addresses: addresses,
    port: 47821,
  );

  test('a LAN IPv4 address wins over loopback and link-local', () {
    // The order the iOS simulator reported for a Mac host.
    final url = host([
      '::1',
      'fe80::1%lo0',
      'fe80::462:d4f3:1ef5:8dbc%en0',
      '127.0.0.1',
      '192.168.68.104',
    ]).baseUrl;
    expect(url.toString(), 'http://192.168.68.104:47821');
  });

  test('a routable IPv6 address is used when there is no IPv4', () {
    final url = host(['fe80::1%en0', '2a02:1:2::5']).baseUrl;
    expect(url?.host, '2a02:1:2::5');
  });

  test('loopback is the last resort and link-local is never used', () {
    expect(host(['::1', '127.0.0.1']).baseUrl?.host, anyOf('::1', '127.0.0.1'));
    expect(host(['fe80::1%en0']).baseUrl, isNull);
    expect(host(const []).baseUrl, isNull);
  });
}
