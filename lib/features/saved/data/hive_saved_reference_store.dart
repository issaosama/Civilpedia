import '../../../data/local/hive_helper.dart';
import '../domain/saved_item_reference.dart';
import '../domain/saved_reference_store.dart';

/// W5.6 — Hive-backed [SavedReferenceStore] over the canonical structured key
/// `AppStorageKeys.savedReferences`.
///
/// This implementation owns all load/decode/encode/deduplication/save/remove
/// logic for the structured store. It is LOCAL-FIRST and works fully offline —
/// no network dependency. It is deliberately backend-neutral (uses
/// [HiveHelper]) so the Directory and Saved *application* layers never touch
/// Hive or the `savedReferences` key directly.
class HiveSavedReferenceStore implements SavedReferenceStore {
  const HiveSavedReferenceStore();

  @override
  Future<List<SavedItemReference>> loadAll() async {
    final raw = HiveHelper.getSavedReferences();
    final result = <SavedItemReference>[];
    for (final item in raw) {
      final map = item is Map ? Map<String, dynamic>.from(item) : null;
      final ref = SavedItemReference.tryFromJson(map);
      if (ref == null) continue; // skip malformed, do not crash
      result.add(ref);
    }
    return result;
  }

  @override
  Future<bool> contains(String referenceId) async {
    final refs = await loadAll();
    return refs.any((r) => r.id == referenceId);
  }

  @override
  Future<void> save(SavedItemReference reference) async {
    final refs = await loadAll();
    final index = refs.indexWhere((r) => r.id == reference.id);
    if (index >= 0) return; // idempotent: preserve original, keep position
    refs.add(reference);
    await _write(refs);
  }

  @override
  Future<void> remove(String referenceId) async {
    final refs = await loadAll();
    final next = <SavedItemReference>[];
    var removed = false;
    for (final r in refs) {
      if (r.id == referenceId) {
        removed = true;
        continue;
      }
      next.add(r);
    }
    if (!removed) return; // safe no-op
    await _write(next);
  }

  Future<void> _write(List<SavedItemReference> refs) async {
    await HiveHelper.putSavedReferences(
      refs.map((r) => r.toJson()).toList(),
    );
  }
}
