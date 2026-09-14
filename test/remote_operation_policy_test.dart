import 'dart:async';
import 'dart:io';

import 'package:civilpedia/core/network/remote_operation_policy.dart';
import 'package:civilpedia/features/profile/data/cloud_profile.dart';
import 'package:civilpedia/features/profile/data/personal_profile_remote_gateway.dart';
import 'package:civilpedia/features/profile/data/timed_profile_gateways.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProfileGateway implements PersonalProfileRemoteGateway {
  Future<CloudProfile?> Function(String userId)? fetch;
  Future<void> Function(CloudProfile profile)? create;

  @override
  Future<CloudProfile?> fetchByUserId(String userId) => fetch!(userId);

  @override
  Future<void> createProfile(CloudProfile profile) => create!(profile);

  @override
  Future<void> saveEditableFields({
    required String userId,
    required String roleCode,
    String? regionPreferenceId,
  }) async {}

  @override
  Future<void> updateRegionPreferenceId({
    required String userId,
    required String regionPreferenceId,
  }) async {}
}

void main() {
  group('V1-R09 remote operation deadlines', () {
    test('ordinary read deadline throws the typed timeout boundary', () async {
      final gateway = _FakeProfileGateway()
        ..fetch = (_) => Completer<CloudProfile?>().future;
      final timed = TimedPersonalProfileRemoteGateway(
        delegate: gateway,
        readTimeout: const Duration(milliseconds: 5),
      );

      await expectLater(
        timed.fetchByUserId('user-a'),
        throwsA(
          isA<InfrastructureFailureException>().having(
            (error) => error.failure.kind,
            'kind',
            InfrastructureFailureKind.timeout,
          ),
        ),
      );
    });

    test('mutation deadline throws the typed timeout boundary', () async {
      final gateway = _FakeProfileGateway()
        ..create = (_) => Completer<void>().future;
      final timed = TimedPersonalProfileRemoteGateway(
        delegate: gateway,
        mutationTimeout: const Duration(milliseconds: 5),
      );

      await expectLater(
        timed.createProfile(const CloudProfile(userId: 'user-a')),
        throwsA(
          isA<InfrastructureFailureException>().having(
            (error) => error.failure.kind,
            'kind',
            InfrastructureFailureKind.timeout,
          ),
        ),
      );
    });

    test('successful operation passes through the deadline boundary', () async {
      expect(
        await runWithRemoteDeadline(
          Future<int>.value(42),
          timeout: const Duration(milliseconds: 5),
        ),
        42,
      );
    });
  });

  group('V1-R09 infrastructure failure classification', () {
    test(
      'explicit unavailable transport classifies a socket error offline',
      () {
        final failure = classifyInfrastructureFailure(
          const SocketException('offline'),
          transportUnavailable: true,
        );

        expect(failure.kind, InfrastructureFailureKind.offline);
      },
    );

    test('socket failure with transport present remains network', () {
      final failure = classifyInfrastructureFailure(
        const SocketException('connection reset'),
      );

      expect(failure.kind, InfrastructureFailureKind.network);
    });

    test('malformed response remains distinct from network', () {
      final failure = classifyInfrastructureFailure(
        const FormatException('invalid projection'),
      );

      expect(failure.kind, InfrastructureFailureKind.malformedResponse);
    });

    test('typed service unavailable remains distinct', () {
      final failure = classifyInfrastructureFailure(
        const InfrastructureFailureException(
          InfrastructureFailure(InfrastructureFailureKind.serviceUnavailable),
        ),
      );

      expect(failure.kind, InfrastructureFailureKind.serviceUnavailable);
    });

    test('unclassified programming error remains unknown', () {
      final failure = classifyInfrastructureFailure(StateError('bug'));

      expect(failure.kind, InfrastructureFailureKind.unknown);
    });

    test(
      'known profile permission denial survives the timeout wrapper',
      () async {
        final gateway = _FakeProfileGateway()
          ..fetch = (_) async =>
              throw const CloudProfilePermissionDeniedException();
        final timed = TimedPersonalProfileRemoteGateway(delegate: gateway);

        await expectLater(
          timed.fetchByUserId('user-a'),
          throwsA(isA<CloudProfilePermissionDeniedException>()),
        );
      },
    );
  });
}
