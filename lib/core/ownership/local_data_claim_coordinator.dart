import 'package:flutter/foundation.dart';

import '../../features/projects/data/project_persistence_gateway.dart';
import '../../features/saved/domain/saved_reference_store.dart';
import 'claim_outcome.dart';
import 'guest_install_identity.dart';
import 'local_favorites_gateway.dart';
import 'ownership_registry.dart';
import 'ownership_registry_store.dart';

/// A5.5 — Coordinates the guest → authenticated ownership claim.
///
/// Triggered only after a REAL authenticated Supabase session is available
/// (the [AuthProvider] `onAuthenticated` seam); never by picker-open, attempt
/// start, or a temporary provider token.
///
/// The claim NEVER moves, deletes, overwrites, or re-encodes user data. It
/// only associates stable record identities with an owner inside the
/// [OwnershipRegistry] sidecar, written as one atomic JSON document. That makes
/// the whole lifecycle:
/// * deterministic — the same local state always produces the same registry;
/// * idempotent — running it twice yields the same final result;
/// * retry-safe — a failed/interrupted run leaves the source data untouched
///   and the previous registry in place, so a later run completes cleanly.
///
/// Device boundary: the first authenticated account to claim on a device binds
/// the device to that account. A different authenticated user signing in later
/// is REFUSED a claim (nothing is reassigned) — the product has no account
/// switching semantics, so a one-account-per-device ownership boundary is the
/// safest behavior.
class LocalDataClaimCoordinator {
  LocalDataClaimCoordinator({
    required OwnershipRegistryStore registryStore,
    required GuestInstallIdentity guestIdentity,
    required ProjectPersistenceGateway projectGateway,
    required SavedReferenceStore savedReferenceStore,
    required LocalFavoritesGateway favoritesGateway,
  }) : _registryStore = registryStore,
       _guestIdentity = guestIdentity,
       _projectGateway = projectGateway,
       _savedReferenceStore = savedReferenceStore,
       _favoritesGateway = favoritesGateway;

  /// Stable registry keys for the Hive-backed whole-store lists.
  static const String articleFavoritesStoreKey = 'favorites_articles_store';
  static const String encyclopediaFavoritesStoreKey =
      'favorites_encyclopedia_store';
  static const String downloadsStoreKey = 'downloads_store';

  final OwnershipRegistryStore _registryStore;
  final GuestInstallIdentity _guestIdentity;
  final ProjectPersistenceGateway _projectGateway;
  final SavedReferenceStore _savedReferenceStore;
  final LocalFavoritesGateway _favoritesGateway;

  Future<ClaimOutcome>? _inFlight;

  /// Runs the claim for [userId]. Concurrent calls coalesce onto the same run.
  Future<ClaimOutcome> claimFor(String userId) {
    final pending = _inFlight;
    if (pending != null) return pending;
    final run = _claimFor(userId).whenComplete(() => _inFlight = null);
    _inFlight = run;
    return run;
  }

  Future<ClaimOutcome> _claimFor(String userId) async {
    final state = await _registryStore.load();

    // FAIL CLOSED: a corrupt registry may hold the only proof that local
    // records belong to a specific account. Never treat it as empty (that
    // could let another user claim this device's data), never overwrite the
    // payload, never re-bind. Auth already succeeded; only the claim is
    // blocked.
    if (state is RegistryCorrupt) {
      debugPrint(
        'A5.5 ownership registry is corrupt; local data claim blocked '
        '(${state.reason}).',
      );
      return ClaimOutcome.registryCorrupt(userId: userId);
    }

    // The only other stored states are legitimate: missing (first-run) → empty
    // unbound registry, or a fully valid registry.
    final registry =
        state is RegistryValid ? state.registry : OwnershipRegistry();

    if (registry.isBound && registry.boundUserId != userId) {
      final guestId = await _guestIdentity.resolveGuestId();
      return ClaimOutcome.refusedBoundToOther(
        userId: userId,
        guestId: guestId,
        boundUserId: registry.boundUserId!,
      );
    }

    final guestId = await _guestIdentity.resolveGuestId();
    final keys = await _enumerateClaimableKeys();

    var claimed = 0;
    var alreadyOwned = 0;
    var preservedOther = 0;
    final claimedKeys = <String>[];

    var working = registry.copyWithBoundAccount(
      userId: userId,
      guestId: guestId,
    );
    for (final key in keys) {
      final owner = working.ownerOf(key);
      if (owner == null || owner.isGuest) {
        working = working.claimKey(key, userId);
        claimed++;
        claimedKeys.add(key);
      } else if (owner.ownedBy(userId)) {
        alreadyOwned++;
      } else {
        preservedOther++;
      }
    }
    working = working.withClaimRecord(guestId, userId);

    await _registryStore.save(working);

    return ClaimOutcome.completed(
      userId: userId,
      guestId: guestId,
      claimedRecordCount: claimed,
      alreadyOwnedCount: alreadyOwned,
      preservedOwnedByOtherCount: preservedOther,
      claimedKeys: claimedKeys,
    );
  }

  /// Enumerates every claimable stable record/store key on this device.
  ///
  /// Keys are domain-qualified, sorted for determinism, and keyed by stable
  /// record ids — never by display text/title.
  Future<List<String>> _enumerateClaimableKeys() async {
    final keys = <String>{};

    final projects = await _projectGateway.readProjects();
    for (final project in projects) {
      keys.add('project:${project.id}');

      final notes = await _projectGateway.readProjectNotes(project.id);
      for (final note in notes) {
        keys.add('note:${note.noteId}');
      }

      final calculations = await _projectGateway.readProjectCalculations(
        project.id,
      );
      for (final record in calculations) {
        keys.add('calculation:${record.id}');
      }

      final executions = await _projectGateway.readProjectChecklistExecutions(
        project.id,
      );
      for (final execution in executions) {
        keys.add('checklist_execution:${execution.executionId}');
      }

      final worksheet = await _projectGateway.readProjectChecklist(project.id);
      if (worksheet != null && worksheet.isNotEmpty) {
        keys.add('checklist_worksheet:${project.id}');
      }
    }

    final savedRefs = await _savedReferenceStore.loadAll();
    for (final reference in savedRefs) {
      keys.add('saved:${reference.id}');
    }

    final favorites = await _favoritesGateway.snapshot();
    if (favorites.articleFavorites.isNotEmpty) {
      keys.add(articleFavoritesStoreKey);
    }
    if (favorites.encyclopediaFavorites.isNotEmpty) {
      keys.add(encyclopediaFavoritesStoreKey);
    }
    if (favorites.downloads.isNotEmpty) {
      keys.add(downloadsStoreKey);
    }

    return keys.toList()..sort();
  }
}