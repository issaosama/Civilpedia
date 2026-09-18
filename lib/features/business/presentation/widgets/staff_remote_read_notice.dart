import 'package:flutter/material.dart';

import '../../../../core/widgets/remote_data_notice.dart';
import '../../domain/staff_remote_read.dart';

/// Pure presentation mapping from a typed Staff READ failure
/// ([StaffRemoteReadFailureKind], P2-E1) into the shared [RemoteDataCause]
/// that the shared [RemoteDataNotice] renders.
///
/// `offline` is the ONLY presentation-only promotion and it is performed ONLY
/// when the canonical ConnectivityProvider state has actually CONFIRMED the
/// transport is unavailable. Until then, a transport failure stays
/// [RemoteDataCause.network].
RemoteDataCause staffRemoteReadFailureToRemoteDataCause(
  StaffRemoteReadFailureKind failure, {
  required bool connectivityIsUnavailable,
}) {
  switch (failure) {
    case StaffRemoteReadFailureKind.network:
      return connectivityIsUnavailable
          ? RemoteDataCause.offline
          : RemoteDataCause.network;
    case StaffRemoteReadFailureKind.timeout:
      return RemoteDataCause.timeout;
    case StaffRemoteReadFailureKind.serviceUnavailable:
      return RemoteDataCause.serviceUnavailable;
    case StaffRemoteReadFailureKind.malformedResponse:
      return RemoteDataCause.malformed;
    case StaffRemoteReadFailureKind.permissionDenied:
      return RemoteDataCause.permissionDenied;
    case StaffRemoteReadFailureKind.authRestricted:
      return RemoteDataCause.authRestricted;
    case StaffRemoteReadFailureKind.unexpected:
      return RemoteDataCause.unexpected;
  }
}

/// Screen-scoped Staff adapter for authenticated READ outcomes (P2-E2).
///
/// This widget owns NO read state, NO retry state, NO timers and NO
/// connectivity subscription. The caller resolves the canonical
/// ConnectivityProvider state once and passes [connectivityIsUnavailable];
/// [onRetry] is a plain READ retry (never a mutation, never a save).
class StaffRemoteReadNotice extends StatelessWidget {
  const StaffRemoteReadNotice({
    super.key,
    required this.failure,
    this.connectivityIsUnavailable = false,
    this.mode = RemoteDataNoticeMode.compact,
    this.onRetry,
  });

  /// The typed Staff read failure (P2-E1). Never a raw error.
  final StaffRemoteReadFailureKind failure;

  /// Canonical presentation-resolved transport confirmation. When true and the
  /// failure is [StaffRemoteReadFailureKind.network], the notice renders as
  /// offline.
  final bool connectivityIsUnavailable;

  /// [RemoteDataNoticeMode.compact] preserves surrounding content;
  /// [RemoteDataNoticeMode.noData] replaces the content area.
  final RemoteDataNoticeMode mode;

  /// Manual READ retry only. Never triggers a mutation.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return RemoteDataNotice(
      cause: staffRemoteReadFailureToRemoteDataCause(
        failure,
        connectivityIsUnavailable: connectivityIsUnavailable,
      ),
      mode: mode,
      onRetry: onRetry,
    );
  }
}