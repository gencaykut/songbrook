import 'package:connectivity_plus/connectivity_plus.dart';

/// Whether [results] include a connection that does not use mobile data:
/// Wi-Fi or a wired network.
bool isUnmeteredConnection(Iterable<ConnectivityResult> results) => results.any(
  (result) =>
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet,
);
