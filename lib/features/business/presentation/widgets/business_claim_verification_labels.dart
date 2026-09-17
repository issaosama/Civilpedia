import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';

/// V1-R04 — localized applicant-facing label for a claim target's canonical
/// `verification_status` storage value (migration 00005 CHECK set).
///
/// Presentation-only mapping — never an authority, never changes backend
/// semantics. Unknown/missing values fail safe to a neutral localized label.
abstract final class BusinessClaimVerificationLabels {
  const BusinessClaimVerificationLabels._();

  static String labelFor(String? status, {bool isArabic = true}) {
    switch (status) {
      case 'unverified':
        return isArabic ? Ar.verificationUnverified : En.verificationUnverified;
      case 'pending':
        return isArabic ? Ar.verificationPending : En.verificationPending;
      case 'verified':
        return isArabic ? Ar.verificationVerified : En.verificationVerified;
      case 'rejected':
        return isArabic ? Ar.verificationRejected : En.verificationRejected;
      case 'suspended':
        return isArabic ? Ar.verificationSuspended : En.verificationSuspended;
      default:
        return isArabic ? Ar.directoryNotSpecified : En.directoryNotSpecified;
    }
  }
}