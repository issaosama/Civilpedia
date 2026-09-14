import 'dart:async';
import 'dart:io';

/// Canonical V1-R09 deadlines for material remote/platform operations.
///
/// Callers may inject a shorter duration in focused tests, but production code
/// must use the operation-class defaults instead of scattering magic values.
abstract final class RemoteOperationPolicy {
  static const Duration serviceInitialization = Duration(seconds: 6);
  static const Duration read = Duration(seconds: 15);
  static const Duration mutation = Duration(seconds: 20);
  static const Duration authCredentialExchange = Duration(seconds: 20);
  static const Duration connectivityCheck = Duration(seconds: 3);
}

/// Infrastructure-only failure kinds. Domain denials (authentication,
/// permission, ownership, transition, concurrency, and known server codes)
/// remain owned by their feature model and must be mapped before this layer.
enum InfrastructureFailureKind {
  offline,
  timeout,
  network,
  serviceUnavailable,
  malformedResponse,
  unknown,
}

class InfrastructureFailure {
  const InfrastructureFailure(this.kind);

  final InfrastructureFailureKind kind;
}

/// Typed boundary exception used when a reusable infrastructure helper must
/// terminate a Future without exposing the original exception to UI.
class InfrastructureFailureException implements Exception {
  const InfrastructureFailureException(this.failure);

  final InfrastructureFailure failure;
}

/// Applies one application-owned deadline and maps expiry to the common typed
/// infrastructure boundary. This bounds the caller's wait; it does not claim
/// that an underlying SDK operation is cancellable.
Future<T> runWithRemoteDeadline<T>(
  Future<T> operation, {
  required Duration timeout,
}) async {
  try {
    return await operation.timeout(timeout);
  } on TimeoutException {
    throw const InfrastructureFailureException(
      InfrastructureFailure(InfrastructureFailureKind.timeout),
    );
  }
}

/// Classifies only infrastructure failures. Feature/domain errors must be
/// handled first by the caller so known denials are never erased.
InfrastructureFailure classifyInfrastructureFailure(
  Object error, {
  bool transportUnavailable = false,
}) {
  if (error is InfrastructureFailureException) return error.failure;
  if (error is TimeoutException) {
    return const InfrastructureFailure(InfrastructureFailureKind.timeout);
  }
  if (transportUnavailable) {
    return const InfrastructureFailure(InfrastructureFailureKind.offline);
  }
  if (error is SocketException ||
      error is HandshakeException ||
      error is HttpException) {
    return const InfrastructureFailure(InfrastructureFailureKind.network);
  }
  if (error is FormatException) {
    return const InfrastructureFailure(
      InfrastructureFailureKind.malformedResponse,
    );
  }
  return const InfrastructureFailure(InfrastructureFailureKind.unknown);
}
