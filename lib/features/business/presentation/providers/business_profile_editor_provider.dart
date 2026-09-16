import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../features/directory/domain/cloud_directory_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/service_business_profile.dart';
import '../../domain/business_contact_type.dart';
import '../../domain/business_profile_management_gateway.dart';
import '../../domain/business_profile_validator.dart';
import '../../domain/business_remote_read.dart';
import '../../domain/managed_business_profile.dart';
import '../../domain/managed_business_profile_draft.dart';
import '../../domain/managed_selectable_options.dart';

typedef _ManagedProfileReadKey = ({
  String userId,
  int authGeneration,
  String entityId,
  int profileRevision,
});
typedef _EditorAuxiliaryReadKey = ({
  String userId,
  int authGeneration,
  String entityId,
});

/// V1-R06 — UI lifecycle for the public business-profile editor.
enum BusinessProfileEditorState {
  /// Initial / not yet asked to load.
  initial,

  /// Sign-in required before any management authority can be inferred.
  signInRequired,

  /// Backend unavailable (guest/offline/unconfigured).
  unavailable,

  /// Authoritative profile + taxonomy in flight.
  loading,

  /// Editable state is ready.
  data,

  /// Save in flight.
  saving,

  /// Last save succeeded (server-authoritative profile installed).
  saveSuccess,

  /// Load or mutation failed with a typed cause.
  error,
}

/// V1-R06 — Provider for editing a single public business profile.
///
/// The server is the only authority. The provider holds a working
/// [ManagedBusinessProfileDraft] and exposes dirty detection, client
/// validation, save with optimistic-concurrency, conflict handling, and
/// post-save Directory cache refresh.
class BusinessProfileEditorProvider extends ChangeNotifier {
  BusinessProfileEditorProvider({
    required BusinessProfileManagementGateway gateway,
    required CloudDirectoryRepository directoryRepository,
    required AuthProvider auth,
  }) : _gateway = gateway,
       _directoryRepository = directoryRepository,
       _auth = auth;

  final BusinessProfileManagementGateway _gateway;
  final CloudDirectoryRepository _directoryRepository;
  final AuthProvider _auth;

  String? _entityId;
  BusinessProfileEditorState _state = BusinessProfileEditorState.initial;

  ManagedBusinessProfile? _profile;
  ManagedBusinessProfileDraft? _draft;
  ManagedBusinessProfileDraft? _originalDraft;

  BusinessProfileManagementCause? _lastErrorCause;
  BusinessProfileValidationResult? _lastValidation;

  List<ManagedSelectableCategory> _selectableCategories = const [];
  bool _categoriesCatalogError = false;
  List<ManagedSelectableRegion> _selectableRegions = const [];
  bool _regionsCatalogError = false;

  bool _directoryRefreshFailed = false;

  BusinessRemoteReadPhase _profileReadPhase = BusinessRemoteReadPhase.idle;
  BusinessRemoteReadFailureKind? _profileReadFailure;
  BusinessRemoteReadPhase _auxiliaryReadPhase = BusinessRemoteReadPhase.idle;
  BusinessRemoteReadFailureKind? _auxiliaryReadFailure;
  _ManagedProfileReadKey? _profileDataKey;
  _EditorAuxiliaryReadKey? _auxiliaryDataKey;
  bool _hasProfileResult = false;
  bool _hasAuxiliaryResult = false;

  int _profileRevision = 0;
  int _profileReadEpoch = 0;
  int _auxiliaryReadEpoch = 0;
  final Map<_ManagedProfileReadKey, Future<void>> _activeProfileReads = {};
  final Map<_EditorAuxiliaryReadKey, Future<void>> _activeAuxiliaryReads = {};
  bool _disposed = false;

  /// Canonical session epoch (V1-R08 final pass, finding 1). Advanced on every
  /// account-bound reset so a load/save/directory refresh captured under the
  /// old session is dropped on arrival and can never publish into the new
  /// (or a guest) session.
  int _sessionEpoch = 0;

  String? get entityId => _entityId;
  BusinessProfileEditorState get state => _state;
  BusinessProfileManagementCause? get lastErrorCause => _lastErrorCause;
  BusinessRemoteReadPhase get profileReadPhase => _profileReadPhase;
  BusinessRemoteReadFailureKind? get profileReadFailure => _profileReadFailure;
  BusinessRemoteReadPhase get auxiliaryReadPhase => _auxiliaryReadPhase;
  BusinessRemoteReadFailureKind? get auxiliaryReadFailure =>
      _auxiliaryReadFailure;
  int get profileRevision => _profileRevision;
  int get activeProfileReadCount => _activeProfileReads.length;
  int get activeAuxiliaryReadCount => _activeAuxiliaryReads.length;

  ManagedBusinessProfile? get profile => _profile;
  ManagedBusinessProfileDraft? get draft => _draft;
  BusinessProfileValidationResult? get lastValidation => _lastValidation;

  List<ManagedSelectableCategory> get selectableCategories =>
      _selectableCategories;
  bool get categoriesCatalogError => _categoriesCatalogError;
  List<ManagedSelectableRegion> get selectableRegions => _selectableRegions;
  bool get regionsCatalogError => _regionsCatalogError;

  /// True when the management RPC save succeeded but the public Directory
  /// cache refresh failed. The save is still authoritative; this is a
  /// non-blocking warning with a Retry Public Refresh action.
  bool get directoryRefreshFailed => _directoryRefreshFailed;

  bool get isLoading => _state == BusinessProfileEditorState.loading;
  bool get isSaving => _state == BusinessProfileEditorState.saving;
  bool get isBusy => isLoading || isSaving;

  String? get _currentUserId => _auth.session?.userId;

  bool get _isAuthenticated =>
      _auth.isLoggedIn && (_currentUserId?.isNotEmpty ?? false);

  /// Whether the working draft differs from the loaded authoritative state in
  /// any editable field.
  bool get isDirty {
    final draft = _draft;
    final original = _originalDraft;
    if (draft == null || original == null) return false;
    return draft != original;
  }

  /// Whether the user has unsaved changes and should be warned before popping.
  bool get canPopSafely => _draft == null || _originalDraft == null || !isDirty;

  /// Whether the entity is currently visible through the public Directory RLS.
  bool get isPubliclyVisible => _profile?.isPubliclyVisible ?? false;

  /// True when the authoritative profile is verified and the current draft
  /// changes a verification-sensitive field (name, primary region, address,
  /// coordinates). The UI must surface a warning that saving may reset
  /// verification.
  bool get verificationResetWarningVisible {
    final profile = _profile;
    final draft = _draft;
    final original = _originalDraft;
    if (profile == null || draft == null || original == null) return false;
    if (profile.verificationStatus != VerificationStatus.verified) return false;

    if (draft.name.trim() != original.name.trim()) return true;

    final draftLoc = draft.primaryLocation;
    final originalLoc = original.primaryLocation;
    if ((draftLoc?.regionId ?? '') != (originalLoc?.regionId ?? '')) {
      return true;
    }
    if ((draftLoc?.address ?? '').trim() !=
        (originalLoc?.address ?? '').trim()) {
      return true;
    }
    if (draftLoc?.latitude != originalLoc?.latitude) return true;
    if (draftLoc?.longitude != originalLoc?.longitude) return true;

    return false;
  }

  /// Loads the profile and auxiliary taxonomies through independent lanes.
  Future<void> load(String entityId) async {
    final identityChanged = _entityId != entityId;
    _entityId = entityId;

    if (!_isAuthenticated) {
      _invalidateReadLanes();
      _state = BusinessProfileEditorState.signInRequired;
      _clearData();
      _notifyIfAlive();
      return;
    }

    if (identityChanged) {
      _invalidateReadLanes();
      _clearData();
    }

    final userId = _currentUserId!;
    final generation = _auth.generation;
    final profileKey = (
      userId: userId,
      authGeneration: generation,
      entityId: entityId,
      profileRevision: _profileRevision,
    );
    final auxiliaryKey = (
      userId: userId,
      authGeneration: generation,
      entityId: entityId,
    );

    await Future.wait<void>([
      _startProfileRead(profileKey),
      _startAuxiliaryRead(auxiliaryKey),
    ]);
  }

  Future<void> _startProfileRead(_ManagedProfileReadKey key) {
    final active = _activeProfileReads[key];
    if (active != null) return active;

    final hasMatchingKnownGood = _hasProfileResult && _profileDataKey == key;
    _profileReadFailure = null;
    _lastErrorCause = null;
    _profileReadPhase = hasMatchingKnownGood
        ? BusinessRemoteReadPhase.refreshing
        : BusinessRemoteReadPhase.loading;
    _state = hasMatchingKnownGood
        ? BusinessProfileEditorState.data
        : BusinessProfileEditorState.loading;
    _notifyIfAlive();

    final requestEpoch = ++_profileReadEpoch;
    late final Future<void> operation;
    operation = _performProfileRead(key, requestEpoch).whenComplete(() {
      if (identical(_activeProfileReads[key], operation)) {
        _activeProfileReads.remove(key);
      }
    });
    _activeProfileReads[key] = operation;
    return operation;
  }

  Future<void> _performProfileRead(
    _ManagedProfileReadKey key,
    int requestEpoch,
  ) async {
    ManagedProfileReadResult result;
    try {
      result = await _gateway.readManagedProfile(key.entityId);
    } catch (error) {
      result = ManagedProfileReadFailed(
        error is BusinessRemoteReadException
            ? error.kind
            : BusinessRemoteReadFailureKind.unexpected,
      );
    }
    if (!_canPublishProfile(key, requestEpoch)) return;

    switch (result) {
      case ManagedProfileReadSuccess(:final profile):
        if (profile.id != key.entityId) {
          _publishProfileFailure(
            key,
            BusinessRemoteReadFailureKind.malformedResponse,
          );
        } else {
          _profile = profile;
          _draft = ManagedBusinessProfileDraft.fromProfile(profile);
          _originalDraft = _draft;
          _profileDataKey = key;
          _hasProfileResult = true;
          _profileReadFailure = null;
          _profileReadPhase = BusinessRemoteReadPhase.loaded;
          _state = BusinessProfileEditorState.data;
          _lastErrorCause = null;
          _validate();
        }
      case ManagedProfileReadNotFound():
        _clearProfileOnly();
        _profileReadPhase = BusinessRemoteReadPhase.authoritativeNotFound;
        _lastErrorCause = BusinessProfileManagementCause.notFound;
        _state = BusinessProfileEditorState.error;
      case ManagedProfileReadFailed(:final cause):
        _publishProfileFailure(key, cause);
      case ManagedProfileReadDenied(:final cause):
        if (cause == BusinessProfileManagementCause.notFound) {
          _clearProfileOnly();
          _profileReadPhase = BusinessRemoteReadPhase.authoritativeNotFound;
          _lastErrorCause = BusinessProfileManagementCause.notFound;
          _state = BusinessProfileEditorState.error;
        } else {
          _publishProfileFailure(key, _readFailureForLegacyCause(cause));
        }
      case ManagedProfileReadUnavailable():
        _publishProfileFailure(
          key,
          BusinessRemoteReadFailureKind.serviceUnavailable,
        );
    }
    _notifyIfAlive();
  }

  Future<void> _startAuxiliaryRead(_EditorAuxiliaryReadKey key) {
    final active = _activeAuxiliaryReads[key];
    if (active != null) return active;

    final hasMatchingKnownGood =
        _hasAuxiliaryResult && _auxiliaryDataKey == key;
    _auxiliaryReadFailure = null;
    _auxiliaryReadPhase = hasMatchingKnownGood
        ? BusinessRemoteReadPhase.refreshing
        : BusinessRemoteReadPhase.loading;
    final requestEpoch = ++_auxiliaryReadEpoch;
    late final Future<void> operation;
    operation = _performAuxiliaryRead(key, requestEpoch).whenComplete(() {
      if (identical(_activeAuxiliaryReads[key], operation)) {
        _activeAuxiliaryReads.remove(key);
      }
    });
    _activeAuxiliaryReads[key] = operation;
    return operation;
  }

  Future<void> _performAuxiliaryRead(
    _EditorAuxiliaryReadKey key,
    int requestEpoch,
  ) async {
    try {
      final results = await Future.wait<Object>([
        _gateway.loadActiveCategories(),
        _gateway.loadActiveRegions(),
      ]);
      if (!_canPublishAuxiliary(key, requestEpoch)) return;
      _selectableCategories = List.unmodifiable(
        results[0] as List<ManagedSelectableCategory>,
      );
      _selectableRegions = List.unmodifiable(
        results[1] as List<ManagedSelectableRegion>,
      );
      _categoriesCatalogError = false;
      _regionsCatalogError = false;
      _auxiliaryDataKey = key;
      _hasAuxiliaryResult = true;
      _auxiliaryReadFailure = null;
      _auxiliaryReadPhase = BusinessRemoteReadPhase.loaded;
      if (_draft != null) _validate();
    } catch (error) {
      if (!_canPublishAuxiliary(key, requestEpoch)) return;
      _categoriesCatalogError = true;
      _regionsCatalogError = true;
      _auxiliaryReadFailure = error is BusinessRemoteReadException
          ? error.kind
          : BusinessRemoteReadFailureKind.unexpected;
      _auxiliaryReadPhase = BusinessRemoteReadPhase.failed;
      if (!(_hasAuxiliaryResult && _auxiliaryDataKey == key)) {
        _selectableCategories = const [];
        _selectableRegions = const [];
      }
    }
    _notifyIfAlive();
  }

  void _publishProfileFailure(
    _ManagedProfileReadKey key,
    BusinessRemoteReadFailureKind cause,
  ) {
    _profileReadFailure = cause;
    _profileReadPhase = BusinessRemoteReadPhase.failed;
    _lastErrorCause = _legacyCauseForReadFailure(cause);
    if (_hasProfileResult && _profileDataKey == key) {
      _state = BusinessProfileEditorState.data;
    } else {
      _clearProfileOnly();
      _state = cause == BusinessRemoteReadFailureKind.serviceUnavailable
          ? BusinessProfileEditorState.unavailable
          : BusinessProfileEditorState.error;
    }
  }

  bool _canPublishProfile(_ManagedProfileReadKey key, int requestEpoch) {
    return !_disposed &&
        requestEpoch == _profileReadEpoch &&
        _entityId == key.entityId &&
        _profileRevision == key.profileRevision &&
        _isCurrentAuth(key.userId, key.authGeneration);
  }

  bool _canPublishAuxiliary(_EditorAuxiliaryReadKey key, int requestEpoch) {
    return !_disposed &&
        requestEpoch == _auxiliaryReadEpoch &&
        _entityId == key.entityId &&
        _isCurrentAuth(key.userId, key.authGeneration);
  }

  bool _isCurrentAuth(String userId, int generation) {
    return _currentUserId == userId &&
        _auth.generation == generation &&
        _auth.isCurrentSession(userId: userId, generation: generation);
  }

  static BusinessRemoteReadFailureKind _readFailureForLegacyCause(
    BusinessProfileManagementCause cause,
  ) {
    return switch (cause) {
      BusinessProfileManagementCause.unauthenticated =>
        BusinessRemoteReadFailureKind.authRestricted,
      BusinessProfileManagementCause.permissionDenied =>
        BusinessRemoteReadFailureKind.permissionDenied,
      BusinessProfileManagementCause.network =>
        BusinessRemoteReadFailureKind.network,
      BusinessProfileManagementCause.unavailable =>
        BusinessRemoteReadFailureKind.serviceUnavailable,
      _ => BusinessRemoteReadFailureKind.unexpected,
    };
  }

  static BusinessProfileManagementCause _legacyCauseForReadFailure(
    BusinessRemoteReadFailureKind cause,
  ) {
    return switch (cause) {
      BusinessRemoteReadFailureKind.authRestricted =>
        BusinessProfileManagementCause.unauthenticated,
      BusinessRemoteReadFailureKind.permissionDenied =>
        BusinessProfileManagementCause.permissionDenied,
      BusinessRemoteReadFailureKind.network ||
      BusinessRemoteReadFailureKind.timeout =>
        BusinessProfileManagementCause.network,
      BusinessRemoteReadFailureKind.serviceUnavailable =>
        BusinessProfileManagementCause.unavailable,
      _ => BusinessProfileManagementCause.unexpected,
    };
  }

  void _clearProfileOnly() {
    _profile = null;
    _draft = null;
    _originalDraft = null;
    _lastValidation = null;
    _profileDataKey = null;
    _hasProfileResult = false;
  }

  void _clearData() {
    _profile = null;
    _draft = null;
    _originalDraft = null;
    _lastValidation = null;
    _selectableCategories = const [];
    _selectableRegions = const [];
    _categoriesCatalogError = false;
    _regionsCatalogError = false;
    _directoryRefreshFailed = false;
    _profileReadFailure = null;
    _auxiliaryReadFailure = null;
    _profileDataKey = null;
    _auxiliaryDataKey = null;
    _hasProfileResult = false;
    _hasAuxiliaryResult = false;
  }

  BusinessProfileValidationResult _validate() {
    final draft = _draft;
    final result = draft == null
        ? const BusinessProfileValidationResult([])
        : BusinessProfileValidator.validate(
            draft: draft,
            selectableCategories: _selectableCategories,
            selectableRegions: _selectableRegions,
          );
    _lastValidation = result;
    return result;
  }

  /// Re-runs client validation and notifies listeners. Call after bulk edits.
  void validateAndNotify() {
    _validate();
    notifyListeners();
  }

  void setName(String value) {
    final draft = _draft;
    if (draft == null || isSaving) return;
    _draft = draft.copyWith(name: value);
    _validate();
    notifyListeners();
  }

  void setDescription(String? value) {
    final draft = _draft;
    if (draft == null || isSaving) return;
    _draft = draft.copyWith(
      description: () => value == null || value.isEmpty ? null : value,
    );
    _validate();
    notifyListeners();
  }

  void addContact({
    required BusinessContactType type,
    required String value,
    bool isPrimary = false,
  }) {
    final draft = _draft;
    if (draft == null || isSaving) return;
    final newContact = ManagedBusinessContact(
      id: '',
      type: type,
      value: value.trim(),
      isPrimary: isPrimary,
    );
    _draft = draft.copyWith(contacts: [...draft.contacts, newContact]);
    _validate();
    notifyListeners();
  }

  void updateContact(int index, ManagedBusinessContact contact) {
    final draft = _draft;
    if (draft == null || isSaving) return;
    if (index < 0 || index >= draft.contacts.length) return;
    final updated = [...draft.contacts];
    updated[index] = contact;
    _draft = draft.copyWith(contacts: updated);
    _validate();
    notifyListeners();
  }

  void removeContact(int index) {
    final draft = _draft;
    if (draft == null || isSaving) return;
    if (index < 0 || index >= draft.contacts.length) return;
    final updated = [...draft.contacts]..removeAt(index);
    _draft = draft.copyWith(contacts: updated);
    _validate();
    notifyListeners();
  }

  /// Marks the contact at [index] as primary or not. When [isPrimary] is true,
  /// any existing primary contact of the SAME type is demoted first so that
  /// there is never more than one primary per contact type.
  void setContactPrimary(int index, bool isPrimary) {
    final draft = _draft;
    if (draft == null || isSaving) return;
    if (index < 0 || index >= draft.contacts.length) return;
    final target = draft.contacts[index];
    final updated = <ManagedBusinessContact>[
      for (var i = 0; i < draft.contacts.length; i++)
        ManagedBusinessContact(
          id: draft.contacts[i].id,
          type: draft.contacts[i].type,
          value: draft.contacts[i].value,
          isPrimary: i == index
              ? isPrimary
              : (draft.contacts[i].type == target.type
                    ? false
                    : draft.contacts[i].isPrimary),
        ),
    ];
    _draft = draft.copyWith(contacts: updated);
    _validate();
    notifyListeners();
  }

  /// Sets the primary location. Pass null or an empty [ManagedBusinessLocation]
  /// to CLEAR the primary location.
  void setPrimaryLocation(ManagedBusinessLocation? location) {
    final draft = _draft;
    if (draft == null || isSaving) return;
    final cleared = location == null || location.isEmpty;
    _draft = draft.copyWith(primaryLocation: () => cleared ? null : location);
    _validate();
    notifyListeners();
  }

  void setAddress(String? value) {
    final draft = _draft;
    final location = draft?.primaryLocation;
    if (draft == null || isSaving) return;
    // Preserve raw typed text (including interior/trailing spaces) while still
    // treating an all-whitespace value as "no address".
    final trimmedForEmptyCheck = value?.trim();
    final address =
        (trimmedForEmptyCheck == null || trimmedForEmptyCheck.isEmpty)
        ? null
        : value;
    final next = ManagedBusinessLocation(
      id: location?.id ?? '',
      regionId: location?.regionId,
      regionCode: location?.regionCode,
      regionNameAr: location?.regionNameAr,
      regionNameEn: location?.regionNameEn,
      address: address,
      latitude: location?.latitude,
      longitude: location?.longitude,
    );
    _draft = draft.copyWith(primaryLocation: () => next.isEmpty ? null : next);
    _validate();
    notifyListeners();
  }

  void setRegion(String? regionId) {
    final draft = _draft;
    final location = draft?.primaryLocation;
    if (draft == null || isSaving) return;
    final region = regionId == null || regionId.isEmpty
        ? null
        : _selectableRegions.cast<ManagedSelectableRegion?>().firstWhere(
            (r) => r?.id == regionId,
            orElse: () => null,
          );
    final next = ManagedBusinessLocation(
      id: location?.id ?? '',
      regionId: region?.id,
      regionCode: region?.code,
      regionNameAr: region?.nameAr,
      regionNameEn: region?.nameEn,
      address: location?.address,
      latitude: location?.latitude,
      longitude: location?.longitude,
    );
    _draft = draft.copyWith(primaryLocation: () => next.isEmpty ? null : next);
    _validate();
    notifyListeners();
  }

  void setCoordinates(double? latitude, double? longitude) {
    final draft = _draft;
    final location = draft?.primaryLocation;
    if (draft == null || isSaving) return;
    final next = ManagedBusinessLocation(
      id: location?.id ?? '',
      regionId: location?.regionId,
      regionCode: location?.regionCode,
      regionNameAr: location?.regionNameAr,
      regionNameEn: location?.regionNameEn,
      address: location?.address,
      latitude: latitude,
      longitude: longitude,
    );
    _draft = draft.copyWith(primaryLocation: () => next.isEmpty ? null : next);
    _validate();
    notifyListeners();
  }

  void addCategory(
    ManagedSelectableCategory category, {
    bool isPrimary = false,
  }) {
    final draft = _draft;
    if (draft == null || isSaving) return;
    if (draft.categories.any((c) => c.categoryId == category.id)) return;
    final assignment = ManagedBusinessCategory(
      categoryId: category.id,
      code: category.code,
      nameAr: category.nameAr,
      nameEn: category.nameEn,
      isPrimary: isPrimary,
    );
    _draft = draft.copyWith(categories: [...draft.categories, assignment]);
    _validate();
    notifyListeners();
  }

  void removeCategory(String categoryId) {
    final draft = _draft;
    if (draft == null || isSaving) return;
    _draft = draft.copyWith(
      categories: draft.categories
          .where((c) => c.categoryId != categoryId)
          .toList(),
    );
    _validate();
    notifyListeners();
  }

  void setCategoryPrimary(String categoryId, bool isPrimary) {
    final draft = _draft;
    if (draft == null || isSaving) return;
    _draft = draft.copyWith(
      categories: [
        for (final category in draft.categories)
          ManagedBusinessCategory(
            categoryId: category.categoryId,
            code: category.code,
            nameAr: category.nameAr,
            nameEn: category.nameEn,
            isPrimary: category.categoryId == categoryId && isPrimary,
          ),
      ],
    );
    _validate();
    notifyListeners();
  }

  /// Discards local changes and restores the authoritative draft.
  void discardChanges() {
    final original = _originalDraft;
    if (original == null || isSaving) return;
    _draft = original;
    _lastErrorCause = null;
    _validate();
    notifyListeners();
  }

  /// Saves the working draft using the loaded authoritative `updatedAt` as the
  /// optimistic-concurrency token. On success the server returns the new
  /// authoritative projection; the provider refreshes the public Directory
  /// cache and resets dirty. On denial the draft is preserved and the typed
  /// cause is exposed for the UI.
  Future<bool> save() async {
    final draft = _draft;
    final profile = _profile;
    final entityId = _entityId;
    final userId = _currentUserId;
    final generation = _auth.generation;
    if (draft == null ||
        profile == null ||
        entityId == null ||
        userId == null ||
        isBusy ||
        _disposed) {
      return false;
    }

    final validation = _validate();
    if (!validation.isValid) {
      notifyListeners();
      return false;
    }

    final epoch = _sessionEpoch;
    _state = BusinessProfileEditorState.saving;
    _lastErrorCause = null;
    notifyListeners();

    final result = await _gateway.updateManagedProfile(
      entityId: entityId,
      expectedUpdatedAt: profile.updatedAt,
      draft: draft,
    );

    if (!_canPublishMutation(epoch, userId, generation, entityId)) return false;

    switch (result) {
      case ManagedProfileUpdateSuccess(:final profile):
        // Advance before publishing the accepted projection so every older
        // read is stale even while the best-effort Directory refresh awaits.
        _profileRevision++;
        _profile = profile;
        _draft = ManagedBusinessProfileDraft.fromProfile(profile);
        _originalDraft = _draft;
        _profileDataKey = (
          userId: userId,
          authGeneration: generation,
          entityId: entityId,
          profileRevision: _profileRevision,
        );
        _hasProfileResult = true;
        _profileReadPhase = BusinessRemoteReadPhase.loaded;
        _profileReadFailure = null;
        _lastValidation = null;
        _lastErrorCause = null;
        _directoryRefreshFailed = false;
        _state = BusinessProfileEditorState.saveSuccess;
        var refreshFailed = false;
        try {
          await _directoryRepository.refresh();
        } catch (_) {
          refreshFailed = true;
        }
        if (_canPublishMutation(epoch, userId, generation, entityId)) {
          _directoryRefreshFailed = refreshFailed;
          _notifyIfAlive();
        }
        return true;
      case ManagedProfileUpdateDenied(:final cause):
        _lastErrorCause = cause;
        _state = BusinessProfileEditorState.data;
        _notifyIfAlive();
        return false;
    }
  }

  bool _canPublishMutation(
    int epoch,
    String userId,
    int generation,
    String entityId,
  ) {
    return !_disposed &&
        epoch == _sessionEpoch &&
        _entityId == entityId &&
        _isCurrentAuth(userId, generation);
  }

  /// Retries the public Directory cache refresh. This does NOT resubmit the
  /// profile mutation; it only calls [CloudDirectoryRepository.refresh].
  Future<void> retryDirectoryRefresh() async {
    final epoch = _sessionEpoch;
    final entityId = _entityId;
    if (entityId == null) return;
    try {
      await _directoryRepository.refresh();
      if (_disposed || epoch != _sessionEpoch || entityId != _entityId) return;
      _directoryRefreshFailed = false;
      _notifyIfAlive();
    } catch (_) {
      if (_disposed || epoch != _sessionEpoch || entityId != _entityId) return;
      _directoryRefreshFailed = true;
      _notifyIfAlive();
    }
  }

  /// Reloads the authoritative profile after a conflict (P0CON) or any other
  /// denial where the UI wants to reset to server state.
  Future<void> reloadAuthoritative() async {
    final entityId = _entityId;
    if (entityId == null) return;
    await load(entityId);
  }

  /// Acknowledges a save-success state so the UI can return to [data].
  void acknowledgeSuccess() {
    if (_state == BusinessProfileEditorState.saveSuccess) {
      _state = BusinessProfileEditorState.data;
      notifyListeners();
    }
  }

  /// Resets the provider to its initial state (e.g. on sign-out). Advances the
  /// session epoch so in-flight loads/saves never publish after the reset
  /// (V1-R08 final pass, finding 1).
  void reset() {
    if (_disposed) return;
    _sessionEpoch++;
    _profileRevision = 0;
    _invalidateReadLanes();
    _entityId = null;
    _state = BusinessProfileEditorState.initial;
    _clearData();
    notifyListeners();
  }

  void _invalidateReadLanes() {
    _profileReadEpoch++;
    _auxiliaryReadEpoch++;
    _activeProfileReads.clear();
    _activeAuxiliaryReads.clear();
    _profileReadPhase = BusinessRemoteReadPhase.idle;
    _auxiliaryReadPhase = BusinessRemoteReadPhase.idle;
  }

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _sessionEpoch++;
    _profileReadEpoch++;
    _auxiliaryReadEpoch++;
    _activeProfileReads.clear();
    _activeAuxiliaryReads.clear();
    super.dispose();
  }
}
