import 'business_application_staff_gateway.dart';
import 'staff_remote_read.dart';

/// V1-R07 — Result of a bounded staff read operation (capabilities, queue,
/// detail). Mirrors the mutation result shape but carries an arbitrary
/// authoritative payload on success.
sealed class StaffReadResult<T> {
  const StaffReadResult();
}

class StaffReadSuccess<T> extends StaffReadResult<T> {
  const StaffReadSuccess(this.data);

  final T data;
}

class StaffReadDenied<T> extends StaffReadResult<T> {
  const StaffReadDenied(this.cause);

  final BusinessApplicationStaffCause cause;
}

class StaffReadUnavailable<T> extends StaffReadResult<T> {
  const StaffReadUnavailable();
}

/// A sanitized remote failure from the Staff read boundary.
///
/// Domain outcomes such as P0AUT/P0PER/P0NOT/P0DAT remain represented by
/// [StaffReadDenied] and are never flattened into this variant.
class StaffRemoteReadFailure<T> extends StaffReadResult<T> {
  const StaffRemoteReadFailure(this.kind);

  final StaffRemoteReadFailureKind kind;
}
