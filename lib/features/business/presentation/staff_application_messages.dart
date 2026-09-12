import 'package:flutter/widgets.dart';

import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../domain/business_application_staff_gateway.dart';
import '../domain/business_application_type.dart';

/// Localized message resolver for staff application causes and UI labels.
///
/// Every staff label resolves against the app's active locale
/// ([Localizations.localeOf]) — never a hard-coded locale and never a raw
/// server code (findings 11, 12).
abstract final class StaffApplicationMessages {
  static String messageForCause(
    BusinessApplicationStaffCause cause, {
    required bool isArabic,
  }) {
    return switch (cause) {
      BusinessApplicationStaffCause.unauthenticated =>
        _pick(isArabic, Ar.staffCauseUnauthenticated, En.staffCauseUnauthenticated),
      BusinessApplicationStaffCause.staffPermissionDenied => _pick(
          isArabic,
          Ar.staffCausePermissionDenied,
          En.staffCausePermissionDenied,
        ),
      BusinessApplicationStaffCause.applicationNotFound =>
        _pick(isArabic, Ar.staffCauseNotFound, En.staffCauseNotFound),
      BusinessApplicationStaffCause.invalidTransition => _pick(
          isArabic,
          Ar.staffCauseInvalidTransition,
          En.staffCauseInvalidTransition,
        ),
      BusinessApplicationStaffCause.correctionReasonRequired => _pick(
          isArabic,
          Ar.staffCauseCorrectionReasonRequired,
          En.staffCauseCorrectionReasonRequired,
        ),
      BusinessApplicationStaffCause.rejectionReasonRequired => _pick(
          isArabic,
          Ar.staffCauseRejectionReasonRequired,
          En.staffCauseRejectionReasonRequired,
        ),
      BusinessApplicationStaffCause.requiredDataMissing => _pick(
          isArabic,
          Ar.staffCauseRequiredDataMissing,
          En.staffCauseRequiredDataMissing,
        ),
      BusinessApplicationStaffCause.targetNotClaimable =>
        _pick(isArabic, Ar.businessCauseTargetNotClaimable, En.businessCauseTargetNotClaimable),
      BusinessApplicationStaffCause.ownershipProvisioningConflict =>
        _pick(isArabic, Ar.businessCauseAlreadyOwner, En.businessCauseAlreadyOwner),
      BusinessApplicationStaffCause.unexpected =>
        _pick(isArabic, Ar.staffCauseUnexpected, En.staffCauseUnexpected),
    };
  }

  /// Localized label for the raw server application-type code.
  static String applicationTypeLabel(
    BusinessApplicationType type, {
    required bool isArabic,
  }) {
    return type == BusinessApplicationType.claim
        ? _pick(isArabic, Ar.businessTypeClaim, En.businessTypeClaim)
        : _pick(isArabic, Ar.businessTypeNew, En.businessTypeNew);
  }

  /// Localized label for a raw server contact-type code (never shown raw).
  static String contactTypeLabel(String code, {required bool isArabic}) {
    return switch (code) {
      'phone' => _pick(isArabic, Ar.staffContactTypePhone, En.staffContactTypePhone),
      'whatsapp' =>
        _pick(isArabic, Ar.staffContactTypeWhatsapp, En.staffContactTypeWhatsapp),
      'email' =>
        _pick(isArabic, Ar.staffContactTypeEmail, En.staffContactTypeEmail),
      'visit' =>
        _pick(isArabic, Ar.staffContactTypeVisit, En.staffContactTypeVisit),
      'other' =>
        _pick(isArabic, Ar.staffContactTypeOther, En.staffContactTypeOther),
      _ => _pick(isArabic, Ar.staffContactTypeUnknown, En.staffContactTypeUnknown),
    };
  }

  /// Localized label for a raw server visit-status code (never shown raw).
  static String visitStatusLabel(String status, {required bool isArabic}) {
    return switch (status) {
      'scheduled' =>
        _pick(isArabic, Ar.staffVisitStatusScheduled, En.staffVisitStatusScheduled),
      'completed' =>
        _pick(isArabic, Ar.staffVisitStatusCompleted, En.staffVisitStatusCompleted),
      'cancelled' =>
        _pick(isArabic, Ar.staffVisitStatusCancelled, En.staffVisitStatusCancelled),
      'no_show' =>
        _pick(isArabic, Ar.staffVisitStatusNoShow, En.staffVisitStatusNoShow),
      _ => _pick(isArabic, Ar.staffVisitStatusUnknown, En.staffVisitStatusUnknown),
    };
  }

  /// Resolves [ar]/[en] against the current app locale. Requires a live
  /// [BuildContext]; use the [isArabic] variants above when no context is at
  /// hand.
  static String localized(BuildContext context, String ar, String en) {
    return Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  }

  static String _pick(bool isArabic, String ar, String en) =>
      isArabic ? ar : en;
}