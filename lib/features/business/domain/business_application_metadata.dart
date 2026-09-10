/// A6.4 canonical keys for the approved NEW application metadata snapshot.
///
/// The server remains authoritative for value validation. In particular,
/// [entityType] must be one of the exact `directory_entities.entity_type`
/// values; this layer deliberately does not map profile `BusinessType` values.
abstract final class BusinessApplicationMetadata {
  static const String name = 'name';
  static const String entityType = 'entity_type';
}
