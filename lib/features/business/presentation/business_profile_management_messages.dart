import '../../../localization/ar.dart';
import '../domain/business_contact_type.dart';
import '../domain/business_profile_management_gateway.dart';
import '../domain/business_profile_validator.dart';

/// V1-R06 — Presentation labels for the business-profile management flow.
///
/// Arabic is the canonical UI language; this resolver is intentionally thin
/// and delegates to [Ar] so widgets and tests share the same keys.
abstract final class BusinessProfileManagementMessages {
  static String titleForList() => Ar.businessManageTitle;

  static String titleForEditor() => Ar.businessProfileEditTitle;

  static String labelForContactType(BusinessContactType type) {
    switch (type) {
      case BusinessContactType.phone:
        return Ar.businessContactTypePhone;
      case BusinessContactType.whatsapp:
        return Ar.businessContactTypeWhatsApp;
      case BusinessContactType.email:
        return Ar.businessContactTypeEmail;
      case BusinessContactType.website:
        return Ar.businessContactTypeWebsite;
      case BusinessContactType.other:
        return Ar.businessContactTypeOther;
      case BusinessContactType.unknown:
        return Ar.businessStatusUnknown;
    }
  }

  static String messageForCause(BusinessProfileManagementCause cause) {
    switch (cause) {
      case BusinessProfileManagementCause.unauthenticated:
        return Ar.businessProfileCauseUnauthenticated;
      case BusinessProfileManagementCause.permissionDenied:
        return Ar.businessProfileCausePermissionDenied;
      case BusinessProfileManagementCause.notFound:
        return Ar.businessProfileCauseNotFound;
      case BusinessProfileManagementCause.invalidData:
        return Ar.businessProfileCauseInvalidData;
      case BusinessProfileManagementCause.conflict:
        return Ar.businessProfileCauseConflict;
      case BusinessProfileManagementCause.network:
        return Ar.businessProfileCauseNetwork;
      case BusinessProfileManagementCause.unavailable:
        return Ar.businessProfileCauseUnavailable;
      case BusinessProfileManagementCause.unexpected:
        return Ar.businessProfileCauseUnexpected;
    }
  }

  static String messageForValidationIssue(
    BusinessProfileValidationIssue issue,
  ) {
    switch (issue.code) {
      case BusinessProfileValidationIssueCode.required:
        return Ar.businessProfileValidationRequired;
      case BusinessProfileValidationIssueCode.tooLong:
        return Ar.businessProfileValidationTooLong;
      case BusinessProfileValidationIssueCode.tooMany:
        return Ar.businessProfileValidationTooMany;
      case BusinessProfileValidationIssueCode.invalidFormat:
        return Ar.businessProfileValidationInvalidFormat;
      case BusinessProfileValidationIssueCode.duplicate:
        return Ar.businessProfileValidationDuplicate;
      case BusinessProfileValidationIssueCode.duplicatePrimary:
        return Ar.businessProfileValidationDuplicatePrimary;
      case BusinessProfileValidationIssueCode.multiplePrimary:
        return Ar.businessProfileValidationMultiplePrimary;
      case BusinessProfileValidationIssueCode.incompleteLocation:
        return Ar.businessProfileValidationIncompleteLocation;
      case BusinessProfileValidationIssueCode.incompletePair:
        return Ar.businessProfileValidationIncompletePair;
      case BusinessProfileValidationIssueCode.outOfRange:
        return Ar.businessProfileValidationOutOfRange;
    }
  }
}
