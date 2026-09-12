import 'business_application_status.dart';
import 'business_application_type.dart';

/// V1-R07 — Canonical permission codes for staff business-application
/// operations. These are the only codes that may grant authority in the
/// Flutter UI; server RPCs revalidate every call independently.
abstract final class StaffApplicationPermission {
  static const String read = 'business_applications.read';
  static const String review = 'business_applications.review';
  static const String returnForCorrection =
      'business_applications.return_for_correction';
  static const String markContacted = 'business_applications.mark_contacted';
  static const String scheduleVisit = 'business_applications.schedule_visit';
  static const String approve = 'business_applications.approve';
  static const String reject = 'business_applications.reject';
  static const String activate = 'business_applications.activate';

  static const Set<String> _knownCodes = {
    read,
    review,
    returnForCorrection,
    markContacted,
    scheduleVisit,
    approve,
    reject,
    activate,
  };

  /// True when [code] is one of the known V1-R07 staff permission codes.
  static bool isKnown(String code) => _knownCodes.contains(code);
}

/// V1-R07 — Granular, deterministic, duplicate-free current-session staff
/// capabilities for business applications.
///
/// Parsed from the `get_staff_application_capabilities()` RPC projection under
/// a strict fail-closed contract:
/// - the `permissions` member MUST be a JSON array of strings;
/// - every entry MUST be a string — a single non-string entry fails the whole
///   projection (cite: review finding 3);
/// - unknown-but-well-formed permission strings may be ignored for action
///   capabilities;
/// - any malformed or missing projection yields null (fails closed).
class StaffApplicationCapabilities {
  const StaffApplicationCapabilities._({required Set<String> permissions})
      : _permissions = permissions;

  /// A capabilities instance that grants no permissions. Used for safe defaults
  /// while the access provider is still resolving.
  const StaffApplicationCapabilities.empty() : _permissions = const {};

  final Set<String> _permissions;

  bool get canRead => _permissions.contains(StaffApplicationPermission.read);

  bool get canBeginReview =>
      _permissions.contains(StaffApplicationPermission.review);

  bool get canReturnForCorrection =>
      _permissions.contains(StaffApplicationPermission.returnForCorrection);

  bool get canMarkContacted =>
      _permissions.contains(StaffApplicationPermission.markContacted);

  bool get canScheduleVisit =>
      _permissions.contains(StaffApplicationPermission.scheduleVisit);

  bool get canApprove =>
      _permissions.contains(StaffApplicationPermission.approve);

  bool get canReject =>
      _permissions.contains(StaffApplicationPermission.reject);

  bool get canActivate =>
      _permissions.contains(StaffApplicationPermission.activate);

  /// Parses the capabilities RPC response. Returns null when the projection is
  /// malformed or missing the required `permissions` array. A non-string entry
  /// fails the whole projection (strict fail-closed parsing, finding 3).
  static StaffApplicationCapabilities? tryFromJson(Map<String, dynamic> json) {
    final raw = json['permissions'];
    if (raw is! List<dynamic>) return null;
    final permissions = <String>{};
    for (final value in raw) {
      if (value is! String) return null;
      if (StaffApplicationPermission.isKnown(value)) {
        permissions.add(value);
      }
    }
    return StaffApplicationCapabilities._(permissions: permissions);
  }
}

/// V1-R07 — Compact filter carried by the staff queue provider.
///
/// A null [status] means the server's default actionable queue
/// (SUBMITTED/UNDER_REVIEW/CONTACTED/VISIT_SCHEDULED). A null [type] means no
/// application-type restriction.
class StaffApplicationQueueFilter {
  const StaffApplicationQueueFilter({
    this.status,
    this.type,
  });

  final BusinessApplicationStatus? status;
  final BusinessApplicationType? type;

  StaffApplicationQueueFilter copyWith({
    BusinessApplicationStatus? status,
    BusinessApplicationType? type,
    bool clearStatus = false,
    bool clearType = false,
  }) {
    return StaffApplicationQueueFilter(
      status: clearStatus ? null : (status ?? this.status),
      type: clearType ? null : (type ?? this.type),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! StaffApplicationQueueFilter) return false;
    return other.status == status && other.type == type;
  }

  @override
  int get hashCode => Object.hash(status, type);
}
