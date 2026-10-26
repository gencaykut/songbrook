import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';

/// The Bonjour service type Songbrook hosts advertise on the LAN.
const String kConnectServiceType = '_songbrook._tcp';

/// A Songbrook host seen on the LAN.
class ConnectDiscoveredHost {
  const ConnectDiscoveredHost({
    required this.hostId,
    required this.name,
    required this.addresses,
    required this.port,
  });

  final String hostId;
  final String name;
  final List<String> addresses;
  final int port;

  /// IPv4 first: link-local IPv6 needs a scope that URIs cannot carry well.
  Uri? get baseUrl {
    final ordered = [
      ...addresses.where(
        (address) =>
            InternetAddress.tryParse(address)?.type == InternetAddressType.IPv4,
      ),
      ...addresses.where(
        (address) =>
            InternetAddress.tryParse(address)?.type == InternetAddressType.IPv6,
      ),
    ];
    if (ordered.isEmpty) return null;
    return Uri(scheme: 'http', host: ordered.first, port: port);
  }
}

/// Advertises this device as a Connect host.
abstract interface class ConnectBroadcaster {
  Future<void> start({
    required String hostId,
    required String name,
    required int port,
  });

  Future<void> stop();
}

/// Finds Connect hosts on the LAN.
abstract interface class ConnectHostDiscovery {
  /// Every change to the set of resolved hosts.
  Stream<List<ConnectDiscoveredHost>> get hosts;

  Future<void> start();

  Future<void> stop();
}

class BonsoirConnectBroadcaster implements ConnectBroadcaster {
  BonsoirBroadcast? _broadcast;

  @override
  Future<void> start({
    required String hostId,
    required String name,
    required int port,
  }) async {
    await stop();
    final broadcast = BonsoirBroadcast(
      service: BonsoirService(
        name: name,
        type: kConnectServiceType,
        port: port,
        attributes: {'id': hostId, 'v': '1'},
      ),
    );
    _broadcast = broadcast;
    await broadcast.initialize();
    await broadcast.start();
  }

  @override
  Future<void> stop() async {
    final broadcast = _broadcast;
    _broadcast = null;
    await broadcast?.stop();
  }
}

class BonsoirConnectHostDiscovery implements ConnectHostDiscovery {
  final _controller = StreamController<List<ConnectDiscoveredHost>>.broadcast();
  final Map<String, ConnectDiscoveredHost> _resolved = {};
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _subscription;

  @override
  Stream<List<ConnectDiscoveredHost>> get hosts => _controller.stream;

  @override
  Future<void> start() async {
    if (_discovery != null) return;
    final discovery = BonsoirDiscovery(type: kConnectServiceType);
    _discovery = discovery;
    await discovery.initialize();
    _subscription = discovery.eventStream?.listen((event) {
      switch (event) {
        case BonsoirDiscoveryServiceFoundEvent(:final service):
          service.resolve(discovery.serviceResolver);
        case BonsoirDiscoveryServiceResolvedEvent(:final service):
        case BonsoirDiscoveryServiceUpdatedEvent(:final service):
          final hostId = service.attributes['id'];
          if (hostId == null || hostId.isEmpty) return;
          _resolved[service.name] = ConnectDiscoveredHost(
            hostId: hostId,
            name: service.name,
            addresses: service.hostAddresses,
            port: service.port,
          );
          _publish();
        case BonsoirDiscoveryServiceLostEvent(:final service):
          if (_resolved.remove(service.name) != null) _publish();
        default:
          break;
      }
    });
    await discovery.start();
  }

  void _publish() =>
      _controller.add(List.unmodifiable(_resolved.values.toList()));

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    final discovery = _discovery;
    _discovery = null;
    _resolved.clear();
    await discovery?.stop();
    _publish();
  }
}
