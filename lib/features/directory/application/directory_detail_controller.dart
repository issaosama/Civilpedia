import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/reconnect_generation_gate.dart';
import '../../../core/services/connectivity_provider.dart';
import '../../../core/widgets/remote_data_notice.dart';
import '../domain/canonical_directory_entity.dart';
import '../domain/cloud_directory_repository.dart';

/// Presentation state for the canonical Directory detail resolver.
enum DirectoryDetailState {
  /// A matching seed or cached entity is being shown; authority not yet settled.
  stale,

  /// A complete authoritative refresh succeeded for this ID.
  fresh,

  /// A complete authoritative refresh proved the entity is absent.
  notFound,

  /// The route ID is not a syntactically valid canonical UUID.
  invalidId,

  /// No usable seed/cache and no authoritative result yet.
  unresolved,
}

/// V1-R09 P2-B2 — Presentation controller for canonical Directory detail
/// resolution.
///
/// This controller is feature-owned and per-detail-screen. It does NOT own the
/// repository, cache, or single-flight refresh Future; it only orchestrates the
/// cache-first read and maps repository outcomes to presentation states.
///
/// Reconnect observation is owned by this controller (allowed for Detail).
class DirectoryDetailController extends ChangeNotifier {
  DirectoryDetailController({
    required CloudDirectoryRepository repository,
    required String entityId,
    ConnectivityProvider? connectivity,
    CanonicalDirectoryEntity? seedEntity,
  })  : _repository = repository,
        _entityId = entityId,
        _connectivity = connectivity {
    initialize(seedEntity: seedEntity);
  }

  final CloudDirectoryRepository _repository;
  final String _entityId;
  final ConnectivityProvider? _connectivity;
  final ReconnectGenerationGate _gate = ReconnectGenerationGate();

  CanonicalDirectoryEntity? _entity;
  bool _isLoading = true;
  DirectoryDetailState _state = DirectoryDetailState.unresolved;
  RemoteDataCause? _cause;
  int _requestEpoch = 0;
  bool _disposed = false;

  CanonicalDirectoryEntity? get entity => _entity;
  bool get isLoading => _isLoading;
  DirectoryDetailState get state => _state;
  RemoteDataCause? get cause => _cause;

  /// Resolves the detail surface in the required order:
  /// validate ID → accept matching seed → read cache → authoritative refresh.
  Future<void> initialize({CanonicalDirectoryEntity? seedEntity}) async {
    if (_disposed) return;
    if (!_isValidId(_entityId)) {
      _isLoading = false;
      _state = DirectoryDetailState.invalidId;
      notifyListeners();
      return;
    }

    if (seedEntity != null && seedEntity.id == _entityId) {
      _entity = seedEntity;
      _state = DirectoryDetailState.stale;
      notifyListeners();
    }

    await _readCache();
    if (_disposed) return;
    _bindConnectivity();
    // Reset the initial loading lock so the authoritative refresh can run.
    _isLoading = false;
    await _refresh();
  }

  Future<void> _readCache() async {
    final cached = await _repository.readCache();
    if (_disposed) return;
    final fromCache = cached?.byId(_entityId);
    if (fromCache != null) {
      _entity = fromCache;
      _state = DirectoryDetailState.stale;
      notifyListeners();
    }
  }

  Future<void> _refresh() async {
    if (_disposed || _isLoading) return;
    _isLoading = true;
    final epoch = ++_requestEpoch;
    notifyListeners();

    final result = await _repository.refresh();
    if (_disposed || epoch != _requestEpoch) return;
    _isLoading = false;

    if (result.succeeded) {
      final match = _findById(result.entities, _entityId);
      if (match != null) {
        _entity = match;
        _state = DirectoryDetailState.fresh;
        _cause = null;
      } else {
        _entity = null;
        _state = DirectoryDetailState.notFound;
        _cause = null;
      }
    } else {
      _cause = _mapCause(result.status);
      if (_entity != null) {
        _state = DirectoryDetailState.stale;
      } else {
        _state = DirectoryDetailState.unresolved;
      }
    }
    notifyListeners();
  }

  void retry() {
    unawaited(_refresh());
  }

  RemoteDataCause? _mapCause(DirectoryRefreshStatus status) {
    final confirmedOffline =
        _connectivity != null && _connectivity!.isUnavailable;
    return switch (status) {
      DirectoryRefreshStatus.network =>
        confirmedOffline ? RemoteDataCause.offline : RemoteDataCause.network,
      DirectoryRefreshStatus.timeout => RemoteDataCause.timeout,
      DirectoryRefreshStatus.serviceUnavailable =>
        RemoteDataCause.serviceUnavailable,
      DirectoryRefreshStatus.malformedResponse => RemoteDataCause.malformed,
      DirectoryRefreshStatus.unexpected => RemoteDataCause.unexpected,
      DirectoryRefreshStatus.unavailable =>
        confirmedOffline ? RemoteDataCause.offline : RemoteDataCause.network,
      DirectoryRefreshStatus.failure => RemoteDataCause.unexpected,
      DirectoryRefreshStatus.success ||
      DirectoryRefreshStatus.authoritativeEmpty =>
        null,
    };
  }

  void _bindConnectivity() {
    final connectivity = _connectivity;
    if (connectivity == null) return;
    _gate.bind(connectivity.reconnectGeneration);
    connectivity.addListener(_onConnectivityChanged);
  }

  void _onConnectivityChanged() {
    if (_disposed) return;
    final connectivity = _connectivity;
    if (connectivity == null) return;
    final generation = connectivity.reconnectGeneration;
    if (!_gate.claimCurrentGeneration(generation)) return;
    if (_canReconnect()) {
      unawaited(_refresh());
    }
  }

  bool _canReconnect() {
    if (!_isEligibleCause(_cause)) return false;
    return _state == DirectoryDetailState.stale ||
        _state == DirectoryDetailState.unresolved;
  }

  bool _isEligibleCause(RemoteDataCause? cause) {
    return cause == RemoteDataCause.offline ||
        cause == RemoteDataCause.network ||
        cause == RemoteDataCause.timeout ||
        cause == RemoteDataCause.serviceUnavailable;
  }

  bool _isValidId(String id) {
    return id.isNotEmpty && CanonicalDirectoryEntity.isValidUuid(id);
  }

  CanonicalDirectoryEntity? _findById(
    List<CanonicalDirectoryEntity> entities,
    String id,
  ) {
    for (final entity in entities) {
      if (entity.id == id) return entity;
    }
    return null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _requestEpoch++;
    _connectivity?.removeListener(_onConnectivityChanged);
    _gate.dispose();
    super.dispose();
  }
}
