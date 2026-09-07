import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../storage/app_storage_keys.dart';
import 'ownership_registry.dart';

/// A5.5 — Persistence boundary for the [OwnershipRegistry].
///
/// The registry is a single JSON document under
/// [AppStorageKeys.ownershipRegistry]. Writes are one atomic
/// `setString`, so an interrupted save can never leave a partial registry;
/// the claim coordinator rebuilds the full document in memory and persists it
/// in one call.
///
/// Loads FAIL CLOSED: the three persisted states are distinguished explicitly
/// so corruption can never be mistaken for a legitimate first-run (missing)
/// registry.
abstract interface class OwnershipRegistryStore {
  /// Loads the registry state:
  /// * [RegistryMissing] — key absent (legitimate first-run);
  /// * [RegistryValid] — structurally sound registry;
  /// * [RegistryCorrupt] — the stored payload is corrupt; the claim must be
  ///   blocked and the raw payload preserved (never silently replaced).
  Future<RegistryState> load();

  /// Atomically replaces the stored registry with [registry].
  Future<void> save(OwnershipRegistry registry);
}

/// Decoded result of a registry load.
abstract class RegistryState {
  const RegistryState();
}

/// The registry key is absent: the legitimate first-run/empty state.
class RegistryMissing extends RegistryState {
  const RegistryMissing();
}

/// A structurally valid registry.
class RegistryValid extends RegistryState {
  const RegistryValid(this.registry);

  final OwnershipRegistry registry;
}

/// The registry exists but is corrupt/structurally invalid. FAIL CLOSED:
/// no claim, no overwrite of the stored payload, no re-binding.
class RegistryCorrupt extends RegistryState {
  const RegistryCorrupt(this.reason);

  /// A generic, sanitized reason (never payload contents or user PII).
  final String reason;
}

/// SharedPreferences-backed [OwnershipRegistryStore].
class SharedPreferencesOwnershipRegistryStore
    implements OwnershipRegistryStore {
  const SharedPreferencesOwnershipRegistryStore();

  @override
  Future<RegistryState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppStorageKeys.ownershipRegistry);
    // Only an ABSENT key is "missing". An empty/invalid payload is corruption.
    if (raw == null) return const RegistryMissing();
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const RegistryCorrupt('invalid JSON payload');
    }
    try {
      return RegistryValid(OwnershipRegistry.tryDecode(decoded));
    } on OwnershipRegistryCorruptException catch (error) {
      return RegistryCorrupt(error.reason);
    }
  }

  @override
  Future<void> save(OwnershipRegistry registry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppStorageKeys.ownershipRegistry,
      jsonEncode(registry.toJson()),
    );
  }
}