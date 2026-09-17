import 'package:flutter/material.dart';

import '../../../../core/widgets/remote_data_notice.dart';
import '../../domain/business_remote_read.dart';

/// Pure presentation mapping from a typed Business READ failure
/// ([BusinessRemoteReadFailureKind], P2-D1) into the shared [RemoteDataCause]
/// that the shared [RemoteDataNotice] renders.
///
/// `offline` is the ONLY presentation-only promotion and it is performed ONLY
/// when the canonical ConnectivityProvider state has actually CONFIRMED the
/// transport is unavailable. Until then, a transport failure stays
/// [RemoteDataCause.network].
RemoteDataCause businessReadFailureToRemoteDataCause(
  BusinessRemoteReadFailureKind failure, {
  required bool connectivityIsUnavailable,
}) {
  switch (failure) {
    case BusinessRemoteReadFailureKind.network:
      return connectivityIsUnavailable
          ? RemoteDataCause.offline
          : RemoteDataCause.network;
    case BusinessRemoteReadFailureKind.timeout:
      return RemoteDataCause.timeout;
    case BusinessRemoteReadFailureKind.serviceUnavailable:
      return RemoteDataCause.serviceUnavailable;
    case BusinessRemoteReadFailureKind.malformedResponse:
      return RemoteDataCause.malformed;
    case BusinessRemoteReadFailureKind.permissionDenied:
      return RemoteDataCause.permissionDenied;
    case BusinessRemoteReadFailureKind.authRestricted:
      return RemoteDataCause.authRestricted;
    case BusinessRemoteReadFailureKind.unexpected:
      return RemoteDataCause.unexpected;
  }
}

/// Feature adapter for authenticated Business READ outcomes (P2-D2).
///
/// This widget owns NO read state, NO retry state, NO timers and NO
/// connectivity subscription. The caller resolves the canonical
/// ConnectivityProvider state once and passes [connectivityIsUnavailable];
/// [onRetry] is a plain READ retry (never a mutation, never a save).
class BusinessRemoteReadNotice extends StatelessWidget {
  const BusinessRemoteReadNotice({
    super.key,
    required this.failure,
    this.connectivityIsUnavailable = false,
    this.mode = RemoteDataNoticeMode.compact,
    this.onRetry,
  });

  /// The typed Business read failure (P2-D1). Never a raw error.
  final BusinessRemoteReadFailureKind failure;

  /// Canonical presentation-resolved transport confirmation. When true and the
  /// failure is [BusinessRemoteReadFailureKind.network], the notice renders as
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
      cause: businessReadFailureToRemoteDataCause(
        failure,
        connectivityIsUnavailable: connectivityIsUnavailable,
      ),
      mode: mode,
      onRetry: onRetry,
    );
  }
}