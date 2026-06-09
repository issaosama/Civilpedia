import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    final results = await Connectivity().checkConnectivity();
    _updateStatus(results);
    _subscription = Connectivity().onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
