import '../../../core/location/baghdad_area.dart';
import '../../profile/domain/service_business_profile.dart';

/// Immutable Directory query/filter model consumed by the W5.3
/// [DirectoryQueryEngine].
///
/// W5.3 — Directory-local search + location/category filter. This is a pure
/// value/query object: it carries the active filter state and is interpreted
/// by the query engine against a loaded in-memory list. It never talks to
/// data, persistence, localization, or routing.
///
/// Semantics:
/// - [text] empty/trimmed-empty means NO text restriction (browse mode).
/// - [category] null means ALL [BusinessType] values; a non-null value is an
///   exact identity match on [ServiceBusinessProfile.type].
/// - [location] null means ALL locations; a non-null value is an exact enum
///   match on [ServiceBusinessProfile.baghdadArea].
///
/// Deliberately EXCLUDED from W5.3 (see roadmap boundaries):
/// verification, sort, page, limit, sponsored, featured, planType, contact,
/// saved.
class DirectoryQuery {
  /// Free-text query. Normalized at match time by the engine (trim + lower).
  final String text;

  /// Active [BusinessType] filter, or null for all categories.
  final BusinessType? category;

  /// Active [BaghdadArea] filter, or null for all locations.
  final BaghdadArea? location;

  const DirectoryQuery({
    this.text = '',
    this.category,
    this.location,
  });

  /// Whether this query imposes no text restriction.
  bool get hasText => text.trim().isNotEmpty;
}
