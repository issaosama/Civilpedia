import 'business_application.dart';
import 'business_application_capabilities.dart';
import 'business_application_status.dart';

/// A6.2 — Pure, stateless resolver deriving applicant-facing capabilities from
/// a [BusinessApplication].
///
/// Single entry point so raw status-string comparisons never spread into
/// widgets/features. Never consults local legacy metadata (e.g.
/// `futureOwnerUserId`) or Google/email identity.
abstract final class BusinessApplicationCapabilityResolver {
  /// Capabilities for [application]; a null application or one that cannot be
  /// attributed to a canonical applicant fails closed to [unknown] capabilities
  /// (no elevated applicant capability).
  static BusinessApplicationCapabilities capabilitiesFor(
    BusinessApplication? application,
  ) {
    if (application == null) return _unknown();
    return BusinessApplicationCapabilities.forStatus(application.status);
  }

  /// Capabilities for a raw status value, fail closed for unknown codes.
  static BusinessApplicationCapabilities forStatus(
    BusinessApplicationStatus status,
  ) {
    return BusinessApplicationCapabilities.forStatus(status);
  }

  static BusinessApplicationCapabilities _unknown() {
    return BusinessApplicationCapabilities.forStatus(
      BusinessApplicationStatus.unknown,
    );
  }
}