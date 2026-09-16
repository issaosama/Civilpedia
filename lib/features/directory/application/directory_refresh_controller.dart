import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/reconnect_generation_gate.dart';
import '../../../core/services/connectivity_provider.dart';
import '../../../core/widgets/remote_data_notice.dart';
import '../domain/canonical_directory_entity.dart';
import '../domain/cloud_directory_repository.dart';

/// V1-R09 P2-B2 — Presentation controller for cache-first Directory reads with
/// reconnect-aware refresh.
///
/// Owns the cache-first sequence (`readCache` then `refresh`), maps repository
/// outcomes to the shared [RemoteDataCause] surface, and gates reconnect
/// refreshes through [ReconnectGenerationGate].
///
/// The controller may observe [ConnectivityProvider] to translate request-level
/// `network` failures into `offline` only when canonical transport state is
/// confirmed unavailable. The data layer never performs this mapping.
class DirectoryRefreshController extends ChangeNotifier {
  DirectoryRefreshController({
    required CloudDirectoryRepository repository,
    ConnectivityProvider? connectivity,
  })  : _repository = repository,
        _connectivity = connectivity;

  final CloudDirectoryRepository _repository;
  final ConnectivityProvider? _connectivity;
  final ReconnectGenerationGate _gate = ReconnectGenerationGate();

  List<CanonicalDirectoryEntity> _entities = const [];
  DateTime? _refreshedAt;
  bool _isLoading = true;
  DirectoryLoadState _loadState = DirectoryLoadState.error;
  RemoteDataCause? _cause;
  bool _disposed = false;
  bool _hasSnapshot = false;
  int _operationEpoch = 0;

  List<CanonicalDirectoryEntity> get entities => _entities;
  DateTime? get refreshedAt => _refreshedAt;
  bool get isLoading => _isLoading;
  DirectoryLoadState get loadState => _loadState;
  RemoteDataCause? get cause => _cause;

  /// Whether a valid cached or authoritative snapshot is present (empty or
  /// non-empty). A valid cached empty snapshot is distinct from "no snapshot".
  bool get hasSnapshot => _hasSnapshot;

  /// Initializes the controller: reads cache fast, binds reconnect gating, then
  /// attempts a cloud refresh.
  Future<void> initialize() async {
    await _readCache();
    if (_disposed) return;
    _bindConnectivity();
    // Reset the initial loading lock so refresh() can actually run.
    _isLoading = false;
    await refresh(userInitiated: false);
  }

  /// Performs a cache-first read without a cloud round-trip.
  Future<void> _readCache() async {
    final cached = await _repository.readCache();
    if (_disposed || cached == null) return;
    _hasSnapshot = true;
    _entities = cached.entities;
    _refreshedAt = cached.refreshedAt;
    _loadState = DirectoryLoadState.stale;
    notifyListeners();
  }

  /// Refreshes from cloud. On failure the last cached dataset is preserved and
  /// a typed [RemoteDataCause] is published.
  Future<void> refresh({bool userInitiated = false}) async {
    if (_disposed || _isLoading) return;
    _isLoading = true;
    final epoch = ++_operationEpoch;
    notifyListeners();

    final result = await _repository.refresh();
    if (_disposed || epoch != _operationEpoch) return;
    _isLoading = false;

    if (result.succeeded) {
      _entities = result.entities;
      _refreshedAt = result.refreshedAt;
      _hasSnapshot = true;
      _loadState = result.entities.isEmpty
          ? DirectoryLoadState.empty
          : DirectoryLoadState.fresh;
      _cause = null;
    } else {
      _cause = _mapCause(result.status);
      _loadState = _hasSnapshot
          ? DirectoryLoadState.stale
          : DirectoryLoadState.error;
    }
    notifyListeners();
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
    if (_isEligibleForReconnect(_cause)) {
      unawaited(refresh(userInitiated: false));
    }
  }

  bool _isEligibleForReconnect(RemoteDataCause? cause) {
    return cause == RemoteDataCause.offline ||
        cause == RemoteDataCause.network ||
        cause == RemoteDataCause.timeout ||
        cause == RemoteDataCause.serviceUnavailable;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _operationEpoch++;
    _connectivity?.removeListener(_onConnectivityChanged);
    _gate.dispose();
    super.dispose();
  }
}
