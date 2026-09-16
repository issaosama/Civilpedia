import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/remote_operation_policy.dart';
import '../domain/business_remote_read.dart';

/// P2-D1 — Narrow, source-aware classification for Business READ failures.
///
/// RPC-specific P0 codes are opt-in because their meaning is proven only by
/// the corresponding frozen RPC contract. A generic PostgREST code `401` is
/// intentionally never interpreted as an HTTP/JWT status.
BusinessRemoteReadFailureKind classifyBusinessRemoteReadFailure(
  Object error, {
  bool p0AutIsAuthRestricted = false,
  bool p0PerIsPermissionDenied = false,
  bool postgrestJwtCodesAreAuthRestricted = true,
}) {
  if (error is BusinessRemoteReadException) return error.kind;

  if (error is InfrastructureFailureException) {
    return switch (error.failure.kind) {
      InfrastructureFailureKind.offline || InfrastructureFailureKind.network =>
        BusinessRemoteReadFailureKind.network,
      InfrastructureFailureKind.timeout =>
        BusinessRemoteReadFailureKind.timeout,
      InfrastructureFailureKind.serviceUnavailable =>
        BusinessRemoteReadFailureKind.serviceUnavailable,
      InfrastructureFailureKind.malformedResponse =>
        BusinessRemoteReadFailureKind.malformedResponse,
      InfrastructureFailureKind.unknown =>
        BusinessRemoteReadFailureKind.unexpected,
    };
  }

  if (error is TimeoutException) {
    return BusinessRemoteReadFailureKind.timeout;
  }
  if (error is SocketException ||
      error is HandshakeException ||
      error is HttpException ||
      error is ClientException ||
      error is AuthRetryableFetchException) {
    return BusinessRemoteReadFailureKind.network;
  }
  if (error is FormatException || error is TypeError) {
    return BusinessRemoteReadFailureKind.malformedResponse;
  }
  if (error is AuthSessionMissingException ||
      error is AuthInvalidJwtException) {
    return BusinessRemoteReadFailureKind.authRestricted;
  }
  if (error is AuthException) {
    return error.statusCode == '401'
        ? BusinessRemoteReadFailureKind.authRestricted
        : BusinessRemoteReadFailureKind.unexpected;
  }
  if (error is PostgrestException) {
    final code = (error.code ?? '').toUpperCase();
    if (p0AutIsAuthRestricted && code == 'P0AUT') {
      return BusinessRemoteReadFailureKind.authRestricted;
    }
    if (p0PerIsPermissionDenied && code == 'P0PER') {
      return BusinessRemoteReadFailureKind.permissionDenied;
    }
    if (code == '42501') {
      return BusinessRemoteReadFailureKind.permissionDenied;
    }
    if (postgrestJwtCodesAreAuthRestricted &&
        const {'PGRST301', 'PGRST302', 'PGRST303'}.contains(code)) {
      return BusinessRemoteReadFailureKind.authRestricted;
    }
    if (code.startsWith('08') ||
        code.startsWith('53') ||
        const {'PGRST000', 'PGRST001', 'PGRST002', 'PGRST003'}.contains(code)) {
      return BusinessRemoteReadFailureKind.serviceUnavailable;
    }
    if (code == '200' || code == '406' || code == 'PGRST116') {
      return BusinessRemoteReadFailureKind.malformedResponse;
    }
    return BusinessRemoteReadFailureKind.unexpected;
  }

  return switch (classifyInfrastructureFailure(error).kind) {
    InfrastructureFailureKind.offline ||
    InfrastructureFailureKind.network => BusinessRemoteReadFailureKind.network,
    InfrastructureFailureKind.timeout => BusinessRemoteReadFailureKind.timeout,
    InfrastructureFailureKind.serviceUnavailable =>
      BusinessRemoteReadFailureKind.serviceUnavailable,
    InfrastructureFailureKind.malformedResponse =>
      BusinessRemoteReadFailureKind.malformedResponse,
    InfrastructureFailureKind.unknown =>
      BusinessRemoteReadFailureKind.unexpected,
  };
}

/// Converts a raw gateway failure into a sanitized typed boundary exception.
Never throwBusinessRemoteReadFailure(
  Object error, {
  bool p0AutIsAuthRestricted = false,
  bool p0PerIsPermissionDenied = false,
  bool postgrestJwtCodesAreAuthRestricted = true,
}) {
  throw BusinessRemoteReadException(
    classifyBusinessRemoteReadFailure(
      error,
      p0AutIsAuthRestricted: p0AutIsAuthRestricted,
      p0PerIsPermissionDenied: p0PerIsPermissionDenied,
      postgrestJwtCodesAreAuthRestricted: postgrestJwtCodesAreAuthRestricted,
    ),
  );
}
