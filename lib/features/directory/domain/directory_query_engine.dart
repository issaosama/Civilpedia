import '../../profile/domain/service_business_profile.dart';
import 'directory_query.dart';

/// Pure, stateless, deterministic Directory query/filter engine (W5.3).
///
/// Consumes the W5.1 [DirectoryRepository.loadAll] result and applies a
/// [DirectoryQuery] in memory. It NEVER searches or filters by:
/// id, [BusinessType] enum name, [BaghdadArea] label, address, description,
/// phones, whatsapp, verificationStatus, featured, foundingPartner, planType.
/// [BusinessType] and [BaghdadArea] are controlled exclusively by their
/// dedicated filters.
///
/// Contract:
/// - stateless, deterministic, stable input ordering (no sorting).
/// - no DI, no SharedPreferences, no Flutter dependency.
/// - no localization dependency (labels are NOT searched).
/// - no mutation of the input list or its entities.
///
/// Text normalization is ONLY [String.trim] + [String.toLowerCase]. No
/// Arabic-specific normalization (no Alef folding, Hamza normalization,
/// Tashkeel/Tatweel stripping, stemming, fuzzy matching, or token scoring).
///
/// A profile text-matches when the normalized query occurs (case-insensitive
/// substring `contains`) in ANY of: profile.name, profile.categories entries,
/// profile.subCategories entries.
///
/// All active conditions must match: text AND category AND location.
abstract final class DirectoryQueryEngine {
  /// Applies [query] to [profiles], returning a NEW list (input order
  /// preserved; input list and entities never mutated).
  ///
  /// Filter sequence does not matter semantically; behavior equals
  /// `text AND category AND location`.
  static List<ServiceBusinessProfile> apply(
    List<ServiceBusinessProfile> profiles,
    DirectoryQuery query,
  ) {
    final normalized = query.text.trim().toLowerCase();
    final hasText = normalized.isNotEmpty;

    final result = <ServiceBusinessProfile>[];
    for (final profile in profiles) {
      if (_matches(profile, query, normalized, hasText)) {
        result.add(profile);
      }
    }
    return result;
  }

  static bool _matches(
    ServiceBusinessProfile profile,
    DirectoryQuery query,
    String normalized,
    bool hasText,
  ) {
    if (hasText && !_textMatches(profile, normalized)) {
      return false;
    }
    if (query.category != null && profile.type != query.category) {
      return false;
    }
    if (query.location != null && profile.baghdadArea != query.location) {
      return false;
    }
    return true;
  }

  static bool _textMatches(
    ServiceBusinessProfile profile,
    String normalized,
  ) {
    if (profile.name.toLowerCase().contains(normalized)) {
      return true;
    }
    for (final category in profile.categories) {
      if (category.toLowerCase().contains(normalized)) {
        return true;
      }
    }
    for (final sub in profile.subCategories) {
      if (sub.toLowerCase().contains(normalized)) {
        return true;
      }
    }
    return false;
  }
}
