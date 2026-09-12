import 'business_application_staff_gateway.dart';

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
