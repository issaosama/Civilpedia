/// V1-R04 — Canonical Directory Entity types for NEW business applications.
///
/// These nine textual values ARE the exact `directory_entities.entity_type`
/// CHECK constraint values from migration 00005 (mirrored again by the
/// server-side validator `is_valid_directory_entity_type` in migration 00018).
/// This is the single Flutter source of truth for the NEW application form's
/// entity type options. It deliberately does NOT use the profile `BusinessType`
/// vocabulary: the two taxonomies are different and must not be conflated.
abstract final class DirectoryEntityType {
  static const String company = 'company';
  static const String engineeringOffice = 'engineering_office';
  static const String contractor = 'contractor';
  static const String supplier = 'supplier';
  static const String store = 'store';
  static const String technician = 'technician';
  static const String laboratory = 'laboratory';
  static const String equipmentProvider = 'equipment_provider';
  static const String serviceProvider = 'service_provider';

  /// The exact nine canonical storage values, in CHECK-constraint order.
  static const List<String> all = <String>[
    company,
    engineeringOffice,
    contractor,
    supplier,
    store,
    technician,
    laboratory,
    equipmentProvider,
    serviceProvider,
  ];

  /// Fail-closed: only the exact nine canonical values are recognized.
  static bool isKnown(String? value) => all.contains(value);
}