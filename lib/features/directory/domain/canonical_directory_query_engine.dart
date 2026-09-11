import 'canonical_directory_entity.dart';

/// V1-R05 — Pure, stateless, deterministic Directory query/filter engine over
/// canonical cached/cloud models.
///
/// Search/filter execute LOCALLY over the bounded canonical dataset — no
/// server query per keystroke. AND semantics between all active filters.
/// Deterministic ordering: normalized name, then canonical id.
abstract final class CanonicalDirectoryQueryEngine {
  /// Applies [query] to [entities], returning a NEW sorted list (input list
  /// never mutated, entities never mutated).
  static List<CanonicalDirectoryEntity> apply(
    List<CanonicalDirectoryEntity> entities,
    CanonicalDirectoryQuery query,
  ) {
    final normalized = query.text.trim().toLowerCase();
    final hasText = normalized.isNotEmpty;

    final result = <CanonicalDirectoryEntity>[];
    for (final entity in entities) {
      if (!_matches(entity, query, normalized, hasText)) continue;
      result.add(entity);
    }

    result.sort(_compare);
    return result;
  }

  static int _compare(
    CanonicalDirectoryEntity a,
    CanonicalDirectoryEntity b,
  ) {
    final nameCompare = a.name
        .toLowerCase()
        .compareTo(b.name.toLowerCase());
    if (nameCompare != 0) return nameCompare;
    return a.id.compareTo(b.id);
  }

  static bool _matches(
    CanonicalDirectoryEntity entity,
    CanonicalDirectoryQuery query,
    String normalized,
    bool hasText,
  ) {
    if (hasText && !_textMatches(entity, normalized)) return false;
    if (query.entityType != null && entity.entityType != query.entityType) {
      return false;
    }
    if (query.regionCode != null &&
        !entity.locations.any((l) => l.regionCode == query.regionCode)) {
      return false;
    }
    if (query.categoryId != null &&
        !entity.categories.any((c) => c.id == query.categoryId)) {
      return false;
    }
    return true;
  }

  static bool _textMatches(
    CanonicalDirectoryEntity entity,
    String normalized,
  ) {
    if (entity.name.toLowerCase().contains(normalized)) return true;
    for (final category in entity.categories) {
      if (category.name.toLowerCase().contains(normalized)) return true;
      final code = category.code;
      if (code != null && code.toLowerCase().contains(normalized)) return true;
    }
    return false;
  }
}

/// Immutable canonical Directory query/filter model.
class CanonicalDirectoryQuery {
  const CanonicalDirectoryQuery({
    this.text = '',
    this.entityType,
    this.regionCode,
    this.categoryId,
  });

  /// Free-text query. Normalized at match time (trim + lower).
  final String text;

  /// Canonical `directory_entities.entity_type` filter, or null for all.
  final String? entityType;

  /// Canonical region code filter (from `regions.code`), or null for all.
  final String? regionCode;

  /// Canonical assigned category id filter, or null for all.
  final String? categoryId;

  bool get hasText => text.trim().isNotEmpty;
}