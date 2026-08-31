/// W4.8 — stable Tools-owned checklist template identity/version contract.
///
/// Civilpedia ships exactly ONE built-in inspection checklist template, the
/// compiled `kCategories` / `kItemsForCategory` seed. This contract gives that
/// compiled template family a stable, non-derived semantic identity so that
/// project checklist execution records can associate with it.
///
/// The identity is NOT derived from routes, localized text, categories, hashes,
/// or the project record. It is a fixed constant.
///
/// Ownership: Tools owns the template identity/version contract. The Projects
/// domain records the values passed down by Tools but never defines them.
abstract final class ChecklistTemplateContract {
  /// Stable semantic identity of the built-in site inspection template.
  static const String templateId = 'site_inspection';

  /// Version of the CHECKLIST TEMPLATE CONTRACT (not app/pubspec/date).
  ///
  /// Only advanced in a dedicated phase if the compiled item contract changes
  /// incompatibly later. New native W4.8 executions store this; historical
  /// pre-W4.8 checklist records were never versioned and MUST NOT be assigned
  /// this value retroactively.
  static const String templateVersion = '1';
}
