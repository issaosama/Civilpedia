import '../../../../localization/ar.dart';

/// V1-R04 — localized applicant-facing label for a claim target's canonical
/// `verification_status` storage value (migration 00005 CHECK set).
///
/// Presentation-only mapping — never an authority, never changes backend
/// semantics. Unknown/missing values fail safe to a neutral localized label.
abstract final class BusinessClaimVerificationLabels {
  const BusinessClaimVerificationLabels._();

  static String labelFor(String? status) {
    switch (status) {
      case 'unverified':
        return Ar.verificationUnverified;
      case 'pending':
        return Ar.verificationPending;
      case 'verified':
        return Ar.verificationVerified;
      case 'rejected':
        return Ar.verificationRejected;
      case 'suspended':
        return Ar.verificationSuspended;
      default:
        return Ar.directoryNotSpecified;
    }
  }
}