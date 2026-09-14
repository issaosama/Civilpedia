import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/remote_operation_policy.dart';
import 'transport_source.dart';

enum TransportState { unknown, available, unavailable }

class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider({
    TransportSource? source,
    Duration initialCheckTimeout = RemoteOperationPolicy.connectivityCheck,
  }) : _source = source ?? ConnectivityPlusTransportSource(),
       _initialCheckTimeout = initialCheckTimeout {
    initialization = _initialize();
  }

  final TransportSource _source;
  final Duration _initialCheckTimeout;

  TransportState _state = TransportState.unknown;
  StreamSubscription<bool>? _subscription;
  Timer? _initialCheckTimer;
  Completer<void>? _initializationCompleter;
  bool _disposed = false;
  int _sourceEventSequence = 0;
  int _reconnectGeneration = 0;

  late final Future<void> initialization;

  TransportState get state => _state;

  /// Backward-compatible view for the existing Home icon. UNKNOWN is not
  /// confirmed online and therefore returns false.
  bool get isOnline => _state == TransportState.available;

  bool get isAvailable => _state == TransportState.available;
  bool get isUnavailable => _state == TransportState.unavailable;

  /// Monotonic identity for real UNAVAILABLE -> AVAILABLE transitions. A
  /// consumer can remember the last handled value to prevent reconnect storms.
  int get reconnectGeneration => _reconnectGeneration;

  Future<void> _initialize() async {
    final sequenceBeforeCheck = _sourceEventSequence;
    final completer = Completer<void>();
    _initializationCompleter = completer;

    void completeInitialization() {
      if (!completer.isCompleted) completer.complete();
    }

    _subscribeSafely();

    var settled = false;

    void settleDeadline() {
      if (settled || _disposed) return;
      settled = true;
      if (sequenceBeforeCheck == _sourceEventSequence) {
        _setState(TransportState.unknown);
      }
      completeInitialization();
    }

    final deadline = Timer(_initialCheckTimeout, settleDeadline);
    _initialCheckTimer = deadline;

    Future<bool> rawCheck;
    try {
      rawCheck = _source.checkAvailability();
    } catch (_) {
      deadline.cancel();
      _initialCheckTimer = null;
      if (settled || _disposed) return;
      settled = true;
      _setState(TransportState.unknown);
      completeInitialization();
      return;
    }

    unawaited(
      rawCheck
          .then(
            (available) {
              deadline.cancel();
              _initialCheckTimer = null;
              if (settled || _disposed) return;
              settled = true;
              if (sequenceBeforeCheck != _sourceEventSequence) {
                completeInitialization();
                return;
              }
              _setState(
                available
                    ? TransportState.available
                    : TransportState.unavailable,
              );
              completeInitialization();
            },
            onError: (Object error, StackTrace _) {
              deadline.cancel();
              _initialCheckTimer = null;
              if (settled || _disposed) return;
              settled = true;
              if (sequenceBeforeCheck != _sourceEventSequence) {
                completeInitialization();
                return;
              }
              _setState(TransportState.unknown);
              completeInitialization();
            },
          )
          .catchError((Object _) {}),
    );

    await completer.future;
  }

  void _subscribeSafely() {
    try {
      _subscription = _source.availabilityChanges.listen(
        (available) {
          if (_disposed) return;
          _sourceEventSequence++;
          _setState(
            available ? TransportState.available : TransportState.unavailable,
          );
        },
        onError: (_) {
          if (_disposed) return;
          _sourceEventSequence++;
          _setState(TransportState.unknown);
        },
        cancelOnError: false,
      );
    } catch (_) {
      _setState(TransportState.unknown);
    }
  }

  void _setState(TransportState next) {
    if (_disposed || next == _state) return;
    final previous = _state;
    _state = next;
    if (previous == TransportState.unavailable &&
        next == TransportState.available) {
      _reconnectGeneration++;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final timer = _initialCheckTimer;
    _initialCheckTimer = null;
    timer?.cancel();
    final completer = _initializationCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel().catchError((Object _) {}));
    }
    super.dispose();
  }
}
