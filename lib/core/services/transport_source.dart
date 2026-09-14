import 'package:connectivity_plus/connectivity_plus.dart';

/// Injectable platform transport source used only by the canonical
/// ConnectivityProvider. Feature code must observe the provider instead of
/// constructing connectivity_plus directly.
abstract interface class TransportSource {
  Future<bool> checkAvailability();

  Stream<bool> get availabilityChanges;
}

class ConnectivityPlusTransportSource implements TransportSource {
  ConnectivityPlusTransportSource({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> checkAvailability() async {
    return _hasTransport(await _connectivity.checkConnectivity());
  }

  @override
  Stream<bool> get availabilityChanges =>
      _connectivity.onConnectivityChanged.map(_hasTransport).distinct();

  static bool _hasTransport(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
