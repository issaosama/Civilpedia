import 'saved_item_reference.dart';

/// W5.6 — Canonical User-owned Saved write gateway (M7 §13/§29).
///
/// A single structured store that persists canonical [SavedItemReference]
/// objects, independent of domain. W5.6 writes Directory/provider references
/// here; future phases may route additional new Saved writes to this store.
///
/// SAVE semantics (by canonical [SavedItemReference.id]):
///  - idempotent: an already-saved reference is never duplicated and its
///    original `savedAt` is preserved.
///
/// REMOVE semantics (by canonical [SavedItemReference.id]):
///  - idempotent: removing a missing reference is a safe no-op.
///
/// No generic toggle lives at storage level; UI layers decide save-vs-remove.
abstract interface class SavedReferenceStore {
  /// Loads every structured reference in insertion order.
  Future<List<SavedItemReference>> loadAll();

  /// Whether a reference with [referenceId] is currently saved.
  Future<bool> contains(String referenceId);

  /// Persists [reference]. Idempotent by id (no duplicate, savedAt preserved).
  Future<void> save(SavedItemReference reference);

  /// Removes the reference with [referenceId]. Idempotent.
  Future<void> remove(String referenceId);
}
