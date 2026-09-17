import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../domain/business_contact_type.dart';
import '../domain/business_profile_management_gateway.dart';
import '../domain/business_profile_validator.dart';

/// V1-R06 — Presentation labels for the business-profile management flow.
///
/// Arabic is the canonical default UI language. P2-D2 makes the resolver
/// ACTIVE-LOCALE aware: callers pass [isArabic]; the default stays `true`
/// (Arabic) so existing Arabic-first call sites and test suites keep working.
/// The cause→text mapping is unchanged — only the selected language differs.
abstract final class BusinessProfileManagementMessages {
  static String titleForList({bool isArabic = true}) =>
      isArabic ? Ar.businessManageTitle : En.businessManageTitle;

  static String titleForEditor({bool isArabic = true}) =>
      isArabic ? Ar.businessProfileEditTitle : En.businessProfileEditTitle;

  static String labelForContactType(
    BusinessContactType type, {
    bool isArabic = true,
  }) {
    switch (type) {
      case BusinessContactType.phone:
        return isArabic
            ? Ar.businessContactTypePhone
            : En.businessContactTypePhone;
      case BusinessContactType.whatsapp:
        return isArabic
            ? Ar.businessContactTypeWhatsApp
            : En.businessContactTypeWhatsApp;
      case BusinessContactType.email:
        return isArabic
            ? Ar.businessContactTypeEmail
            : En.businessContactTypeEmail;
      case BusinessContactType.website:
        return isArabic
            ? Ar.businessContactTypeWebsite
            : En.businessContactTypeWebsite;
      case BusinessContactType.other:
        return isArabic
            ? Ar.businessContactTypeOther
            : En.businessContactTypeOther;
      case BusinessContactType.unknown:
        return isArabic ? Ar.businessStatusUnknown : En.businessStatusUnknown;
    }
  }

  static String messageForCause(
    BusinessProfileManagementCause cause, {
    bool isArabic = true,
  }) {
    switch (cause) {
      case BusinessProfileManagementCause.unauthenticated:
        return isArabic
            ? Ar.businessProfileCauseUnauthenticated
            : En.businessProfileCauseUnauthenticated;
      case BusinessProfileManagementCause.permissionDenied:
        return isArabic
            ? Ar.businessProfileCausePermissionDenied
            : En.businessProfileCausePermissionDenied;
      case BusinessProfileManagementCause.notFound:
        return isArabic
            ? Ar.businessProfileCauseNotFound
            : En.businessProfileCauseNotFound;
      case BusinessProfileManagementCause.invalidData:
        return isArabic
            ? Ar.businessProfileCauseInvalidData
            : En.businessProfileCauseInvalidData;
      case BusinessProfileManagementCause.conflict:
        return isArabic
            ? Ar.businessProfileCauseConflict
            : En.businessProfileCauseConflict;
      case BusinessProfileManagementCause.network:
        return isArabic
            ? Ar.businessProfileCauseNetwork
            : En.businessProfileCauseNetwork;
      case BusinessProfileManagementCause.unavailable:
        return isArabic
            ? Ar.businessProfileCauseUnavailable
            : En.businessProfileCauseUnavailable;
      case BusinessProfileManagementCause.unexpected:
        return isArabic
            ? Ar.businessProfileCauseUnexpected
            : En.businessProfileCauseUnexpected;
    }
  }

  static String messageForValidationIssue(
    BusinessProfileValidationIssue issue, {
    bool isArabic = true,
  }) {
    switch (issue.code) {
      case BusinessProfileValidationIssueCode.required:
        return isArabic
            ? Ar.businessProfileValidationRequired
            : En.businessProfileValidationRequired;
      case BusinessProfileValidationIssueCode.tooLong:
        return isArabic
            ? Ar.businessProfileValidationTooLong
            : En.businessProfileValidationTooLong;
      case BusinessProfileValidationIssueCode.tooMany:
        return isArabic
            ? Ar.businessProfileValidationTooMany
            : En.businessProfileValidationTooMany;
      case BusinessProfileValidationIssueCode.invalidFormat:
        return isArabic
            ? Ar.businessProfileValidationInvalidFormat
            : En.businessProfileValidationInvalidFormat;
      case BusinessProfileValidationIssueCode.duplicate:
        return isArabic
            ? Ar.businessProfileValidationDuplicate
            : En.businessProfileValidationDuplicate;
      case BusinessProfileValidationIssueCode.duplicatePrimary:
        return isArabic
            ? Ar.businessProfileValidationDuplicatePrimary
            : En.businessProfileValidationDuplicatePrimary;
      case BusinessProfileValidationIssueCode.multiplePrimary:
        return isArabic
            ? Ar.businessProfileValidationMultiplePrimary
            : En.businessProfileValidationMultiplePrimary;
      case BusinessProfileValidationIssueCode.incompleteLocation:
        return isArabic
            ? Ar.businessProfileValidationIncompleteLocation
            : En.businessProfileValidationIncompleteLocation;
      case BusinessProfileValidationIssueCode.incompletePair:
        return isArabic
            ? Ar.businessProfileValidationIncompletePair
            : En.businessProfileValidationIncompletePair;
      case BusinessProfileValidationIssueCode.outOfRange:
        return isArabic
            ? Ar.businessProfileValidationOutOfRange
            : En.businessProfileValidationOutOfRange;
    }
  }
}