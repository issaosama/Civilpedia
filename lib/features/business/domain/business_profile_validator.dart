import 'business_contact_type.dart';
import 'managed_business_profile.dart';
import 'managed_business_profile_draft.dart';
import 'managed_selectable_options.dart';

/// V1-R06 frozen client bounds. These mirror the accepted server bounds
/// (migration 00020) for UX only — the server remains authoritative on every
/// save.
abstract final class BusinessProfileBounds {
  static const int nameMax = 160;
  static const int descriptionMax = 2000;
  static const int addressMax = 500;
  static const int contactsMax = 10;
  static const int categoriesMax = 10;
  static const int emailMax = 254;
  static const int websiteMax = 2048;
  static const int phoneMax = 32;
  static const int otherContactMax = 500;

  static const int latitudeMin = -90;
  static const int latitudeMax = 90;
  static const int longitudeMin = -180;
  static const int longitudeMax = 180;
}

/// A single client-validation finding. [code] is language-neutral; the
/// presentation layer resolves a localized message.
class BusinessProfileValidationIssue {
  const BusinessProfileValidationIssue({
    required this.field,
    required this.code,
    this.index,
  });

  final BusinessProfileValidationField field;
  final BusinessProfileValidationIssueCode code;

  /// Optional child index (contacts).
  final int? index;

  @override
  bool operator ==(Object other) {
    return other is BusinessProfileValidationIssue &&
        other.field == field &&
        other.code == code &&
        other.index == index;
  }

  @override
  int get hashCode => Object.hash(field, code, index);
}

enum BusinessProfileValidationField {
  name,
  description,
  contacts,
  categories,
  address,
  coordinates,
}

enum BusinessProfileValidationIssueCode {
  required,
  tooLong,
  tooMany,
  invalidFormat,
  duplicate,
  duplicatePrimary,
  multiplePrimary,
  incompleteLocation,
  incompletePair,
  outOfRange,
}

class BusinessProfileValidationResult {
  const BusinessProfileValidationResult(this.issues);

  final List<BusinessProfileValidationIssue> issues;

  bool get isValid => issues.isEmpty;

  /// All issues for [field] (contacts/name/...), for inline field errors.
  List<BusinessProfileValidationIssue> forField(
    BusinessProfileValidationField field,
  ) {
    return issues.where((issue) => issue.field == field).toList();
  }
}

/// V1-R06 — Client-side validator mirroring the frozen server validation for
/// UX. NEVER authoritative: a passing client validation can still be rejected
/// by the server; a failing one is guaranteed to be rejected.
abstract final class BusinessProfileValidator {
  static const String _emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
  static const String _phonePattern = r'^[0-9+(). /-]+$';
  static const String _websitePattern = r'^https?://\S+$';

  static BusinessProfileValidationResult validate({
    required ManagedBusinessProfileDraft draft,
    List<ManagedSelectableCategory> selectableCategories = const [],
    List<ManagedSelectableRegion> selectableRegions = const [],
  }) {
    final issues = <BusinessProfileValidationIssue>[];

    final name = draft.name.trim();
    if (name.isEmpty) {
      issues.add(const BusinessProfileValidationIssue(
        field: BusinessProfileValidationField.name,
        code: BusinessProfileValidationIssueCode.required,
      ));
    } else if (name.length > BusinessProfileBounds.nameMax) {
      issues.add(const BusinessProfileValidationIssue(
        field: BusinessProfileValidationField.name,
        code: BusinessProfileValidationIssueCode.tooLong,
      ));
    }

    final description = draft.description?.trim();
    if (description != null &&
        description.isNotEmpty &&
        description.length > BusinessProfileBounds.descriptionMax) {
      issues.add(const BusinessProfileValidationIssue(
        field: BusinessProfileValidationField.description,
        code: BusinessProfileValidationIssueCode.tooLong,
      ));
    }

    _validateContacts(issues, draft.contacts);

    _validateCategories(
      issues,
      draft.categories,
      selectableCategories,
    );

    _validatePrimaryLocation(
      issues,
      draft.primaryLocation,
      selectableRegions,
    );

    return BusinessProfileValidationResult(
      List.unmodifiable(issues),
    );
  }

  static void _validateContacts(
    List<BusinessProfileValidationIssue> issues,
    List<ManagedBusinessContact> contacts,
  ) {
    if (contacts.length > BusinessProfileBounds.contactsMax) {
      issues.add(const BusinessProfileValidationIssue(
        field: BusinessProfileValidationField.contacts,
        code: BusinessProfileValidationIssueCode.tooMany,
      ));
    }

    final seenKeys = <String>{};
    final primaryTypes = <BusinessContactType>{};
    for (var i = 0; i < contacts.length; i++) {
      final contact = contacts[i];
      final value = contact.value.trim();

      if (!contact.type.isKnown || value.isEmpty) {
        issues.add(BusinessProfileValidationIssue(
          field: BusinessProfileValidationField.contacts,
          code: BusinessProfileValidationIssueCode.invalidFormat,
          index: i,
        ));
        continue;
      }

      switch (contact.type) {
        case BusinessContactType.phone:
        case BusinessContactType.whatsapp:
          final digits =
              value.replaceAll(RegExp(r'[^0-9]'), '');
          if (value.length > BusinessProfileBounds.phoneMax ||
              !RegExp(_phonePattern).hasMatch(value) ||
              digits.length < 3) {
            issues.add(BusinessProfileValidationIssue(
              field: BusinessProfileValidationField.contacts,
              code: BusinessProfileValidationIssueCode.invalidFormat,
              index: i,
            ));
          }
        case BusinessContactType.email:
          if (value.length > BusinessProfileBounds.emailMax ||
              !RegExp(_emailPattern).hasMatch(value)) {
            issues.add(BusinessProfileValidationIssue(
              field: BusinessProfileValidationField.contacts,
              code: BusinessProfileValidationIssueCode.invalidFormat,
              index: i,
            ));
          }
        case BusinessContactType.website:
          if (value.length > BusinessProfileBounds.websiteMax ||
              !RegExp(_websitePattern).hasMatch(value)) {
            issues.add(BusinessProfileValidationIssue(
              field: BusinessProfileValidationField.contacts,
              code: BusinessProfileValidationIssueCode.invalidFormat,
              index: i,
            ));
          }
        case BusinessContactType.other:
          if (value.length > BusinessProfileBounds.otherContactMax) {
            issues.add(BusinessProfileValidationIssue(
              field: BusinessProfileValidationField.contacts,
              code: BusinessProfileValidationIssueCode.tooLong,
              index: i,
            ));
          }
        case BusinessContactType.unknown:
          issues.add(BusinessProfileValidationIssue(
            field: BusinessProfileValidationField.contacts,
            code: BusinessProfileValidationIssueCode.invalidFormat,
            index: i,
          ));
      }

      // Server semantics dedupe on lower-cased value per type.
      final key = '${contact.type.code}\u0000${value.toLowerCase()}';
      if (!seenKeys.add(key)) {
        issues.add(BusinessProfileValidationIssue(
          field: BusinessProfileValidationField.contacts,
          code: BusinessProfileValidationIssueCode.duplicate,
          index: i,
        ));
      }
    }

    for (final contact in contacts) {
      if (contact.isPrimary && !primaryTypes.add(contact.type)) {
        issues.add(const BusinessProfileValidationIssue(
          field: BusinessProfileValidationField.contacts,
          code: BusinessProfileValidationIssueCode.duplicatePrimary,
        ));
      }
    }
  }

  static void _validateCategories(
    List<BusinessProfileValidationIssue> issues,
    List<ManagedBusinessCategory> categories,
    List<ManagedSelectableCategory> selectableCategories,
  ) {
    if (categories.length > BusinessProfileBounds.categoriesMax) {
      issues.add(const BusinessProfileValidationIssue(
        field: BusinessProfileValidationField.categories,
        code: BusinessProfileValidationIssueCode.tooMany,
      ));
    }

    final seen = <String>{};
    for (final category in categories) {
      if (!seen.add(category.categoryId)) {
        issues.add(const BusinessProfileValidationIssue(
          field: BusinessProfileValidationField.categories,
          code: BusinessProfileValidationIssueCode.duplicate,
        ));
      }
    }

    final knownIds = <String>{
      for (final option in selectableCategories) option.id,
    };
    if (knownIds.isNotEmpty) {
      for (final category in categories) {
        if (!knownIds.contains(category.categoryId)) {
          issues.add(const BusinessProfileValidationIssue(
            field: BusinessProfileValidationField.categories,
            code: BusinessProfileValidationIssueCode.invalidFormat,
          ));
        }
      }
    }

    var primaryCount = 0;
    for (final category in categories) {
      if (category.isPrimary) primaryCount++;
    }
    if (primaryCount > 1) {
      issues.add(const BusinessProfileValidationIssue(
        field: BusinessProfileValidationField.categories,
        code: BusinessProfileValidationIssueCode.multiplePrimary,
      ));
    }
  }

  static void _validatePrimaryLocation(
    List<BusinessProfileValidationIssue> issues,
    ManagedBusinessLocation? location,
    List<ManagedSelectableRegion> selectableRegions,
  ) {
    if (location == null || location.isEmpty) return;

    final address = location.address?.trim();
    if (address != null &&
        address.isNotEmpty &&
        address.length > BusinessProfileBounds.addressMax) {
      issues.add(const BusinessProfileValidationIssue(
        field: BusinessProfileValidationField.address,
        code: BusinessProfileValidationIssueCode.tooLong,
      ));
    }

    if (location.regionId == null) {
      final hasContent = (address != null && address.isNotEmpty) ||
          location.latitude != null ||
          location.longitude != null;
      if (!hasContent) {
        issues.add(const BusinessProfileValidationIssue(
          field: BusinessProfileValidationField.address,
          code: BusinessProfileValidationIssueCode.incompleteLocation,
        ));
      }
    }

    final knownRegionIds = <String>{
      for (final region in selectableRegions) region.id,
    };
    if (location.regionId != null && knownRegionIds.isNotEmpty) {
      if (!knownRegionIds.contains(location.regionId)) {
        issues.add(const BusinessProfileValidationIssue(
          field: BusinessProfileValidationField.address,
          code: BusinessProfileValidationIssueCode.invalidFormat,
        ));
      }
    }

    final latitude = location.latitude;
    final longitude = location.longitude;
    if ((latitude == null) != (longitude == null)) {
      issues.add(const BusinessProfileValidationIssue(
        field: BusinessProfileValidationField.coordinates,
        code: BusinessProfileValidationIssueCode.incompletePair,
      ));
    } else if (latitude != null) {
      final latValid = latitude >= BusinessProfileBounds.latitudeMin &&
          latitude <= BusinessProfileBounds.latitudeMax;
      final lonValid = longitude != null &&
          longitude >= BusinessProfileBounds.longitudeMin &&
          longitude <= BusinessProfileBounds.longitudeMax;
      if (!latValid || !lonValid) {
        issues.add(const BusinessProfileValidationIssue(
          field: BusinessProfileValidationField.coordinates,
          code: BusinessProfileValidationIssueCode.outOfRange,
        ));
      }
    }
  }
}