import 'managed_business_profile.dart';

/// V1-R06 — Editable draft owned by the Manage/Edit Business Profile screen.
///
/// Only the frozen OWNER/ADMIN editable fields are present:
/// * name + description (entity scalars);
/// * contacts (replace-all);
/// * primary location (replace-one);
/// * category assignments (replace-all).
///
/// Status fields, entity type, timestamps and ids are deliberately NOT part of
/// the editable surface. The authoritative [updatedAt] version lives on the
/// loaded [ManagedBusinessProfile], which the save flow must pass through as
/// `p_expected_updated_at`.
class ManagedBusinessProfileDraft {
  const ManagedBusinessProfileDraft({
    required this.name,
    required this.contacts,
    required this.categories,
    this.description,
    this.primaryLocation,
  });

  final String name;
  final String? description;
  final List<ManagedBusinessContact> contacts;
  final ManagedBusinessLocation? primaryLocation;
  final List<ManagedBusinessCategory> categories;

  /// Builds the initial clean draft from the authoritative loaded profile.
  ///
  /// Child rows reuse their server rows (id preserved when present). The draft
  /// and the authoritative profile start byte-identical so [dirty] starts
  /// false without any "initialized == changed" false positive.
  factory ManagedBusinessProfileDraft.fromProfile(
    ManagedBusinessProfile profile,
  ) {
    return ManagedBusinessProfileDraft(
      name: profile.name,
      description: profile.description,
      contacts: List<ManagedBusinessContact>.unmodifiable(
        profile.contacts.map(
          (c) => ManagedBusinessContact(
            id: c.id,
            type: c.type,
            value: c.value,
            isPrimary: c.isPrimary,
          ),
        ),
      ),
      primaryLocation: profile.primaryLocation == null
          ? null
          : ManagedBusinessLocation(
              id: profile.primaryLocation!.id,
              regionId: profile.primaryLocation!.regionId,
              regionCode: profile.primaryLocation!.regionCode,
              regionNameAr: profile.primaryLocation!.regionNameAr,
              regionNameEn: profile.primaryLocation!.regionNameEn,
              address: profile.primaryLocation!.address,
              latitude: profile.primaryLocation!.latitude,
              longitude: profile.primaryLocation!.longitude,
              isPrimary: profile.primaryLocation!.isPrimary,
            ),
      categories: List<ManagedBusinessCategory>.unmodifiable(
        profile.categories.map(
          (c) => ManagedBusinessCategory(
            categoryId: c.categoryId,
            code: c.code,
            nameAr: c.nameAr,
            nameEn: c.nameEn,
            isPrimary: c.isPrimary,
          ),
        ),
      ),
    );
  }

  ManagedBusinessProfileDraft copyWith({
    String? name,
    String? Function()? description,
    List<ManagedBusinessContact>? contacts,
    ManagedBusinessLocation? Function()? primaryLocation,
    List<ManagedBusinessCategory>? categories,
  }) {
    return ManagedBusinessProfileDraft(
      name: name ?? this.name,
      description:
          description != null ? description() : this.description,
      contacts: contacts ?? this.contacts,
      primaryLocation:
          primaryLocation != null ? primaryLocation() : this.primaryLocation,
      categories: categories ?? this.categories,
    );
  }

  /// Field-level equality over the editable surface only. Child ids and
  /// display-only region/category labels are ignored (a draft edit never
  /// changes server identity/labels).
  @override
  bool operator ==(Object other) {
    if (other is! ManagedBusinessProfileDraft) return false;
    return other.name == name &&
        other.description == description &&
        _sameContacts(other.contacts) &&
        _sameLocation(other.primaryLocation) &&
        _sameCategories(other.categories);
  }

  @override
  int get hashCode => Object.hash(
        name,
        description,
        Object.hashAll(contacts),
        primaryLocation,
        Object.hashAll(categories),
      );

  bool _sameContacts(List<ManagedBusinessContact> other) {
    if (other.length != contacts.length) return false;
    for (var i = 0; i < contacts.length; i++) {
      if (contacts[i] != other[i]) return false;
    }
    return true;
  }

  bool _sameCategories(List<ManagedBusinessCategory> other) {
    if (other.length != categories.length) return false;
    for (var i = 0; i < categories.length; i++) {
      if (categories[i] != other[i]) return false;
    }
    return true;
  }

  bool _sameLocation(ManagedBusinessLocation? other) {
    final mine = primaryLocation;
    if (mine == null && other == null) return true;
    if (mine == null || other == null) return false;
    return mine.regionId == other.regionId &&
        mine.address == other.address &&
        mine.latitude == other.latitude &&
        mine.longitude == other.longitude &&
        mine.isPrimary == other.isPrimary;
  }
}