import 'package:flutter/material.dart';

import '../../../../core/widgets/remote_data_notice.dart';
import '../../data/personal_profile_remote_gateway.dart';

/// Pure presentation mapping from a typed authenticated-profile READ failure
/// (P2-C1 [ProfileReadFailureKind]) into the shared [RemoteDataCause] that the
/// shared [RemoteDataNotice] can render.
///
/// `offline` is the ONLY presentation-only promotion and it is performed ONLY
/// when the canonical ConnectivityProvider state has actually CONFIRMED the
/// transport is unavailable. Until then, a transport failure stays [RemoteDataCause.network].
RemoteDataCause profileReadFailureToRemoteDataCause(
  ProfileReadFailureKind failure, {
  required bool connectivityIsUnavailable,
}) {
  switch (failure) {
    case ProfileReadFailureKind.network:
      return connectivityIsUnavailable
          ? RemoteDataCause.offline
          : RemoteDataCause.network;
    case ProfileReadFailureKind.timeout:
      return RemoteDataCause.timeout;
    case ProfileReadFailureKind.serviceUnavailable:
      return RemoteDataCause.serviceUnavailable;
    case ProfileReadFailureKind.malformedResponse:
      return RemoteDataCause.malformed;
    case ProfileReadFailureKind.permissionDenied:
      return RemoteDataCause.permissionDenied;
    case ProfileReadFailureKind.authRestricted:
      return RemoteDataCause.authRestricted;
    case ProfileReadFailureKind.unexpected:
      return RemoteDataCause.unexpected;
  }
}

/// Feature adapter for authenticated-profile READ outcomes.
///
/// This widget owns NO read state, NO retry state, NO timers and NO
/// connectivity subscription. The caller resolves the canonical
/// ConnectivityProvider state once and passes [connectivityIsUnavailable];
/// [onRetry] is a plain read retry (never a mutation, never a save).
class AuthenticatedProfileReadNotice extends StatelessWidget {
  const AuthenticatedProfileReadNotice({
    super.key,
    required this.failure,
    this.connectivityIsUnavailable = false,
    this.mode = RemoteDataNoticeMode.compact,
    this.onRetry,
  });

  /// The typed authenticated-profile read failure (P2-C1). Never a raw error.
  final ProfileReadFailureKind failure;

  /// Canonical presentation-resolved transport confirmation. When true and the
  /// failure is [ProfileReadFailureKind.network], the notice renders as offline.
  final bool connectivityIsUnavailable;

  /// [RemoteDataNoticeMode.compact] preserves surrounding content;
  /// [RemoteDataNoticeMode.noData] replaces the content area.
  final RemoteDataNoticeMode mode;

  /// Manual read retry only. Never triggers a mutation.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return RemoteDataNotice(
      cause: profileReadFailureToRemoteDataCause(
        failure,
        connectivityIsUnavailable: connectivityIsUnavailable,
      ),
      mode: mode,
      onRetry: onRetry,
    );
  }
}