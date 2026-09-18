import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/remote_operation_policy.dart';
import '../domain/staff_remote_read.dart';

/// P2-E1 — Narrow, source-aware classification for Staff READ failures.
///
/// The gateway must intercept the frozen Staff domain SQLSTATE values before
/// calling this classifier. In particular, P0DAT remains a domain denial and
/// is never treated as malformed response data. Generic PostgREST code
/// strings `401` and `503` are deliberately not interpreted as HTTP status.
StaffRemoteReadFailureKind classifyStaffRemoteReadFailure(
  Object error, {
  bool postgrestJwtCodesAreAuthRestricted = true,
  bool postgrestResponseShapeCodesAreMalformed = false,
}) {
  if (error is InfrastructureFailureException) {
    return switch (error.failure.kind) {
      InfrastructureFailureKind.offline ||
      InfrastructureFailureKind.network => StaffRemoteReadFailureKind.network,
      InfrastructureFailureKind.timeout => StaffRemoteReadFailureKind.timeout,
      InfrastructureFailureKind.serviceUnavailable =>
        StaffRemoteReadFailureKind.serviceUnavailable,
      InfrastructureFailureKind.malformedResponse =>
        StaffRemoteReadFailureKind.malformedResponse,
      InfrastructureFailureKind.unknown =>
        StaffRemoteReadFailureKind.unexpected,
    };
  }

  if (error is TimeoutException) return StaffRemoteReadFailureKind.timeout;
  if (error is SocketException ||
      error is HandshakeException ||
      error is HttpException ||
      error is ClientException ||
      error is AuthRetryableFetchException) {
    return StaffRemoteReadFailureKind.network;
  }
  if (error is FormatException || error is TypeError) {
    return StaffRemoteReadFailureKind.malformedResponse;
  }
  if (error is AuthSessionMissingException ||
      error is AuthInvalidJwtException) {
    return StaffRemoteReadFailureKind.authRestricted;
  }
  if (error is AuthException) {
    return error.statusCode == '401'
        ? StaffRemoteReadFailureKind.authRestricted
        : StaffRemoteReadFailureKind.unexpected;
  }
  if (error is PostgrestException) {
    final code = (error.code ?? '').toUpperCase();
    if (code == '42501') {
      return StaffRemoteReadFailureKind.permissionDenied;
    }
    if (postgrestJwtCodesAreAuthRestricted &&
        const {'PGRST301', 'PGRST302', 'PGRST303'}.contains(code)) {
      return StaffRemoteReadFailureKind.authRestricted;
    }
    if (code.startsWith('08') ||
        code.startsWith('53') ||
        const {'PGRST000', 'PGRST001', 'PGRST002', 'PGRST003'}.contains(code)) {
      return StaffRemoteReadFailureKind.serviceUnavailable;
    }
    if (postgrestResponseShapeCodesAreMalformed &&
        const {'200', '406', 'PGRST116'}.contains(code)) {
      return StaffRemoteReadFailureKind.malformedResponse;
    }
    return StaffRemoteReadFailureKind.unexpected;
  }

  return StaffRemoteReadFailureKind.unexpected;
}
