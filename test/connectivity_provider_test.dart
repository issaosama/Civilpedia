import 'dart:async';

import 'package:civilpedia/core/services/connectivity_provider.dart';
import 'package:civilpedia/core/services/transport_source.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTransportSource implements TransportSource {
  _FakeTransportSource(Future<bool> Function() check) : _check = check {
    changes = StreamController<bool>.broadcast(
      sync: true,
      onCancel: () => cancelCount++,
    );
  }

  final Future<bool> Function() _check;
  late final StreamController<bool> changes;
  int checkCount = 0;
  int cancelCount = 0;

  @override
  Future<bool> checkAvailability() {
    checkCount++;
    return _check();
  }

  @override
  Stream<bool> get availabilityChanges => changes.stream;

  Future<void> close() => changes.close();
}

void main() {
  group('ConnectivityProvider canonical transport lifecycle', () {
    test('starts UNKNOWN and UNKNOWN is not confirmed online', () async {
      final check = Completer<bool>();
      final source = _FakeTransportSource(() => check.future);
      final provider = ConnectivityProvider(
        source: source,
        initialCheckTimeout: const Duration(milliseconds: 20),
      );

      expect(provider.state, TransportState.unknown);
      expect(provider.isOnline, isFalse);
      expect(provider.isAvailable, isFalse);

      check.complete(true);
      await provider.initialization;
      provider.dispose();
      await source.close();
    });

    test('successful initial check publishes AVAILABLE', () async {
      final source = _FakeTransportSource(() async => true);
      final provider = ConnectivityProvider(source: source);

      await provider.initialization;

      expect(provider.state, TransportState.available);
      expect(provider.isOnline, isTrue);
      expect(source.checkCount, 1);
      provider.dispose();
      await source.close();
    });

    test('successful initial check publishes UNAVAILABLE', () async {
      final source = _FakeTransportSource(() async => false);
      final provider = ConnectivityProvider(source: source);

      await provider.initialization;

      expect(provider.state, TransportState.unavailable);
      expect(provider.isOnline, isFalse);
      provider.dispose();
      await source.close();
    });

    test('initial check timeout remains safely UNKNOWN', () async {
      final source = _FakeTransportSource(() => Completer<bool>().future);
      final provider = ConnectivityProvider(
        source: source,
        initialCheckTimeout: const Duration(milliseconds: 5),
      );

      await provider.initialization;

      expect(provider.state, TransportState.unknown);
      expect(provider.isOnline, isFalse);
      provider.dispose();
      await source.close();
    });

    test('initial check exception remains safely UNKNOWN', () async {
      final source = _FakeTransportSource(() async => throw StateError('bad'));
      final provider = ConnectivityProvider(source: source);

      await provider.initialization;

      expect(provider.state, TransportState.unknown);
      provider.dispose();
      await source.close();
    });

    test('AVAILABLE to UNAVAILABLE transition is observable', () async {
      final source = _FakeTransportSource(() async => true);
      final provider = ConnectivityProvider(source: source);
      await provider.initialization;

      source.changes.add(false);

      expect(provider.state, TransportState.unavailable);
      expect(provider.reconnectGeneration, 0);
      provider.dispose();
      await source.close();
    });

    test('UNAVAILABLE to AVAILABLE has one reconnect identity', () async {
      final source = _FakeTransportSource(() async => false);
      final provider = ConnectivityProvider(source: source);
      await provider.initialization;

      source.changes.add(true);
      source.changes.add(true);

      expect(provider.state, TransportState.available);
      expect(
        provider.reconnectGeneration,
        1,
        reason: 'duplicate AVAILABLE events must not create a retry storm',
      );
      provider.dispose();
      await source.close();
    });

    test('stream error does not escape and returns state to UNKNOWN', () async {
      final source = _FakeTransportSource(() async => true);
      final provider = ConnectivityProvider(source: source);
      await provider.initialization;

      source.changes.addError(StateError('platform stream failed'));

      expect(provider.state, TransportState.unknown);
      expect(provider.isOnline, isFalse);
      provider.dispose();
      await source.close();
    });

    test('dispose cancels the source subscription exactly once', () async {
      final source = _FakeTransportSource(() async => true);
      final provider = ConnectivityProvider(source: source);
      await provider.initialization;

      provider.dispose();
      provider.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(source.cancelCount, 1);
      await source.close();
      expect(source.cancelCount, 1);
    });

    test('no stream callback publishes after disposal', () async {
      final source = _FakeTransportSource(() async => false);
      final provider = ConnectivityProvider(source: source);
      await provider.initialization;
      expect(provider.state, TransportState.unavailable);

      provider.dispose();
      source.changes.add(true);

      expect(provider.state, TransportState.unavailable);
      expect(provider.reconnectGeneration, 0);
      await source.close();
    });

    test('a newer stream event wins over a stale initial check', () async {
      final check = Completer<bool>();
      final source = _FakeTransportSource(() => check.future);
      final provider = ConnectivityProvider(source: source);

      source.changes.add(false);
      check.complete(true);
      await provider.initialization;

      expect(provider.state, TransportState.unavailable);
      provider.dispose();
      await source.close();
    });
  });

  group('ConnectivityProvider deadline lifecycle ownership', () {
    test('A. initial success settles exactly once and cancels the deadline',
        () async {
      final check = Completer<bool>();
      final source = _FakeTransportSource(() => check.future);
      final provider = ConnectivityProvider(
        source: source,
        initialCheckTimeout: const Duration(milliseconds: 50),
      );

      check.complete(true);
      await provider.initialization;

      expect(provider.state, TransportState.available);
      expect(source.checkCount, 1);
      provider.dispose();
      await source.close();
    });

    test('B. initial failure is consumed and settles safely UNKNOWN', () async {
      final check = Completer<bool>();
      final source = _FakeTransportSource(() => check.future);
      final provider = ConnectivityProvider(source: source);

      check.completeError(StateError('transport probe failed'));
      await provider.initialization;

      expect(provider.state, TransportState.unknown);
      provider.dispose();
      await source.close();
    });

    test('C. deadline win stays UNKNOWN and late completion is ignored',
        () async {
      final check = Completer<bool>();
      final source = _FakeTransportSource(() => check.future);
      final provider = ConnectivityProvider(
        source: source,
        initialCheckTimeout: const Duration(milliseconds: 5),
      );

      await provider.initialization;

      expect(provider.state, TransportState.unknown);

      var notifications = 0;
      provider.addListener(() => notifications++);
      check.complete(true);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      expect(provider.state, TransportState.unknown);
      expect(notifications, 0);
      provider.dispose();
      await source.close();
    });

    test('stream AVAILABLE before deadline is never overwritten by the deadline',
        () async {
      final check = Completer<bool>();
      final source = _FakeTransportSource(() => check.future);
      final provider = ConnectivityProvider(
        source: source,
        initialCheckTimeout: const Duration(milliseconds: 10),
      );

      source.changes.add(true);

      expect(provider.state, TransportState.available);

      await provider.initialization;
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(provider.state, TransportState.available);
      expect(provider.reconnectGeneration, 0);

      check.complete(false);
      await Future<void>.delayed(Duration.zero);

      expect(provider.state, TransportState.available);
      provider.dispose();
      await source.close();
    });

    test(
        'stream UNAVAILABLE before deadline is never overwritten by the '
        'deadline', () async {
      final check = Completer<bool>();
      final source = _FakeTransportSource(() => check.future);
      final provider = ConnectivityProvider(
        source: source,
        initialCheckTimeout: const Duration(milliseconds: 10),
      );

      source.changes.add(false);

      expect(provider.state, TransportState.unavailable);

      await provider.initialization;
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(provider.state, TransportState.unavailable);

      check.complete(true);
      await Future<void>.delayed(Duration.zero);

      expect(provider.state, TransportState.unavailable);
      expect(provider.reconnectGeneration, 0);
      provider.dispose();
      await source.close();
    });

    test('D. dispose before source completion ignores the late result',
        () async {
      final check = Completer<bool>();
      final source = _FakeTransportSource(() => check.future);
      final provider = ConnectivityProvider(source: source);

      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.dispose();
      await provider.initialization;

      check.complete(true);
      await Future<void>.delayed(Duration.zero);

      expect(provider.state, TransportState.unknown);
      expect(notifications, 0);
      await source.close();
    });

    test('E. dispose before the deadline leaves no provider-owned timer',
        () async {
      final source = _FakeTransportSource(() => Completer<bool>().future);
      final provider = ConnectivityProvider(source: source);

      provider.dispose();
      await provider.initialization;

      expect(provider.state, TransportState.unknown);
      await source.close();
    });

    test('F. a late source error after dispose stays consumed', () async {
      final check = Completer<bool>();
      final source = _FakeTransportSource(() => check.future);
      final provider = ConnectivityProvider(source: source);

      provider.dispose();
      check.completeError(StateError('late transport error'));
      await Future<void>.delayed(Duration.zero);

      expect(provider.state, TransportState.unknown);
      await source.close();
    });

    test('G. stream events and errors never publish after disposal', () async {
      final source = _FakeTransportSource(() async => false);
      final provider = ConnectivityProvider(source: source);
      await provider.initialization;
      expect(provider.state, TransportState.unavailable);

      provider.dispose();
      source.changes.add(true);
      source.changes.addError(StateError('late stream error'));

      expect(provider.state, TransportState.unavailable);
      await Future<void>.delayed(Duration.zero);
      expect(source.cancelCount, 1);
      await source.close();
    });

    test('H. repeated dispose and late completion are lifecycle-safe',
        () async {
      final check = Completer<bool>();
      final source = _FakeTransportSource(() => check.future);
      final provider = ConnectivityProvider(source: source);

      provider.dispose();
      provider.dispose();

      check.complete(true);
      await provider.initialization;

      expect(source.checkCount, 1);
      expect(provider.state, TransportState.unknown);
      await source.close();
    });
  });
}
