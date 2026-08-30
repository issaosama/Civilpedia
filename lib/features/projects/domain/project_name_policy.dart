/// W4.3 — canonical Project name policy.
///
/// Single source of truth for Create / Edit (rename) name normalization so the
/// rule never lives only in a TextField/dialog and cannot diverge between the
/// Create UI, Edit UI, and repository. Pure — no dependencies, safe to call
/// independently of any UI.
///
/// `'Untitled Project'` is persisted domain data (the stored fallback for a
/// blank/whitespace Create). It is deliberately NOT translated: it is a stored
/// record value, not a display-only string.
class ProjectNamePolicy {
  const ProjectNamePolicy._();

  static const String _untitledFallback = 'Untitled Project';

  /// Returns the name to persist for a Create.
  ///
  /// Input is trimmed; a blank/whitespace input resolves to the persisted
  /// fallback `'Untitled Project'` (approved domain semantics).
  static String createName(String input) {
    final trimmed = input.trim();
    return trimmed.isEmpty ? _untitledFallback : trimmed;
  }

  /// Returns the name to persist for a Rename, or `null` to mean "no change".
  ///
  /// Input is trimmed; a blank/whitespace input keeps the existing name (a
  /// rename to blank is a no-op, preserving current behavior).
  static String? renameName(String input) {
    final trimmed = input.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
