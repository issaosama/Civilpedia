import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:civilpedia/features/directory/domain/canonical_directory_entity.dart';
import 'package:civilpedia/features/directory/domain/cloud_directory_repository.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_detail_screen.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/features/saved/domain/saved_reference_store.dart';

/// Canvases a [GoRouter] that registers the canonical V1-R05 detail route
/// `/directory/entity/:id`.
///
/// The detail destination is the production [DirectoryProviderDetailResolver]:
/// it ALWAYS resolves the canonical `directory_entities.id` through
/// [repository] (repository/cache authority). A whole-entity `extra` carried
/// by the caller is used only as a non-authoritative first-frame hint, exactly
/// like the production router builder. Tests asserting "tap navigates by
/// canonical ID" / "destination resolves repository/cache" use this harness.
GoRouter canonicalDirectoryDetailRouter({
  required Widget home,
  required CloudDirectoryRepository repository,
  SavedReferenceStore? savedReferenceStore,
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => home),
      GoRoute(
        path: '/directory/entity/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra;
          final seed = extra is CanonicalDirectoryEntity ? extra : null;
          return DirectoryProviderDetailResolver(
            entityId: id,
            repository: repository,
            seedEntity: (seed != null && seed.id == id) ? seed : null,
            savedReferenceStore: savedReferenceStore,
          );
        },
      ),
    ],
  );
}

/// Shared canonical Directory test helpers for V1-R05 test adaptation.
/// Provides a fake [CloudDirectoryRepository] and a [CanonicalDirectoryEntity]
/// factory so legacy W5.x/W6.x/W7.x tests can be adapted to canonical models
/// without duplicating fakes.

class FakeCloudDirectoryRepository implements CloudDirectoryRepository {
  int loadCalls = 0;
  int refreshCalls = 0;
  final List<CanonicalDirectoryEntity> entities;
  final Object? throwOnLoad;
  final bool unavailable;

  FakeCloudDirectoryRepository(
    this.entities, {
    this.throwOnLoad,
    this.unavailable = false,
  });

  @override
  bool get isAvailable => !unavailable;

  @override
  Future<DirectoryCachedData?> readCache() async => null;

  @override
  Future<DirectoryRefreshResult> refresh() async {
    refreshCalls++;
    if (throwOnLoad != null) {
      return const DirectoryRefreshResult(status: DirectoryRefreshStatus.failure);
    }
    return DirectoryRefreshResult(
      status: DirectoryRefreshStatus.success,
      entities: List<CanonicalDirectoryEntity>.from(entities),
      refreshedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<CanonicalDirectoryEntity?> loadByCanonicalId(String id) async {
    for (final e in entities) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<DirectoryLoadResult> load() async {
    loadCalls++;
    if (throwOnLoad != null) {
      return const DirectoryLoadResult(state: DirectoryLoadState.error);
    }
    if (entities.isEmpty) {
      return DirectoryLoadResult(
        state: DirectoryLoadState.empty,
        entities: const [],
        refreshedAt: DateTime.now().toUtc(),
      );
    }
    return DirectoryLoadResult(
      state: DirectoryLoadState.fresh,
      entities: List<CanonicalDirectoryEntity>.from(entities),
      refreshedAt: DateTime.now().toUtc(),
    );
  }
}

/// Creates a minimal [CanonicalDirectoryEntity] for testing.
CanonicalDirectoryEntity fakeEntity({
  required String id,
  String name = 'Test Entity',
  String entityType = 'company',
  String? description,
  String lifecycleStatus = 'active',
  VerificationStatus verificationStatus = VerificationStatus.unverified,
  String claimStatus = 'unclaimed',
  List<CanonicalDirectoryCategory> categories = const [],
  List<CanonicalDirectoryLocation> locations = const [],
  List<CanonicalDirectoryContact> contacts = const [],
  List<CanonicalDirectoryMedia> media = const [],
}) {
  return CanonicalDirectoryEntity(
    id: id,
    name: name,
    entityType: entityType,
    description: description,
    lifecycleStatus: lifecycleStatus,
    verificationStatus: verificationStatus,
    claimStatus: claimStatus,
    categories: categories,
    locations: locations,
    contacts: contacts,
    media: media,
  );
}

CanonicalDirectoryCategory fakeCategory(String name, {String? code}) {
  return CanonicalDirectoryCategory(
    id: name.toLowerCase().replaceAll(' ', '-'),
    name: name,
    code: code,
  );
}

CanonicalDirectoryLocation fakeLocation(
  String regionCode, {
  String? regionName,
  String? address,
}) {
  return CanonicalDirectoryLocation(
    regionCode: regionCode,
    regionName: regionName,
    address: address,
  );
}

CanonicalDirectoryContact fakePhone(String value) {
  return CanonicalDirectoryContact(contactType: 'phone', value: value);
}

CanonicalDirectoryContact fakeWhatsApp(String value) {
  return CanonicalDirectoryContact(contactType: 'whatsapp', value: value);
}
