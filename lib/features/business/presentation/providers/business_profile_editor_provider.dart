import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../features/directory/domain/cloud_directory_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/domain/service_business_profile.dart';
import '../../domain/business_contact_type.dart';
import '../../domain/business_profile_management_gateway.dart';
import '../../domain/business_profile_validator.dart';
import '../../domain/managed_business_profile.dart';
import '../../domain/managed_business_profile_draft.dart';
import '../../domain/managed_selectable_options.dart';

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
  })  : _gateway = gateway,
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

  String? get entityId => _entityId;
  BusinessProfileEditorState get state => _state;
  BusinessProfileManagementCause? get lastErrorCause => _lastErrorCause;

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

  /// Loads the authoritative profile + taxonomy for [entityId].
  Future<void> load(String entityId) async {
    _entityId = entityId;

    if (!_isAuthenticated) {
      _state = BusinessProfileEditorState.signInRequired;
      _clearData();
      notifyListeners();
      return;
    }

    if (!_gateway.isAvailable) {
      _state = BusinessProfileEditorState.unavailable;
      _clearData();
      notifyListeners();
      return;
    }

    _state = BusinessProfileEditorState.loading;
    _lastErrorCause = null;
    _clearData();
    notifyListeners();

    // Parallel authoritative profile + taxonomy reads. Selector failures are
    // non-fatal to keep the editable profile available.
    ManagedProfileReadResult? profileResult;
    List<ManagedSelectableCategory>? categories;
    List<ManagedSelectableRegion>? regions;
    try {
      final results = await Future.wait([
        _gateway.readManagedProfile(entityId),
        _gateway.loadActiveCategories().then<List<ManagedSelectableCategory>?>(
          (value) => value,
        ).catchError((_) => null),
        _gateway.loadActiveRegions().then<List<ManagedSelectableRegion>?>(
          (value) => value,
        ).catchError((_) => null),
      ]);
      profileResult = results[0] as ManagedProfileReadResult?;
      categories = results[1] as List<ManagedSelectableCategory>?;
      regions = results[2] as List<ManagedSelectableRegion>?;
    } catch (_) {
      _state = BusinessProfileEditorState.error;
      _lastErrorCause = BusinessProfileManagementCause.network;
      notifyListeners();
      return;
    }

    _selectableCategories = categories ?? const [];
    _categoriesCatalogError = categories == null;
    _selectableRegions = regions ?? const [];
    _regionsCatalogError = regions == null;

    switch (profileResult) {
      case null:
        _state = BusinessProfileEditorState.error;
        _lastErrorCause = BusinessProfileManagementCause.unexpected;
      case ManagedProfileReadSuccess(:final profile):
        _profile = profile;
        _draft = ManagedBusinessProfileDraft.fromProfile(profile);
        _originalDraft = _draft;
        _state = BusinessProfileEditorState.data;
        _lastErrorCause = null;
        _validate();
      case ManagedProfileReadDenied(:final cause):
        _state = BusinessProfileEditorState.error;
        _lastErrorCause = cause;
      case ManagedProfileReadUnavailable():
        _state = BusinessProfileEditorState.unavailable;
    }
    notifyListeners();
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
    _draft = draft.copyWith(
      primaryLocation: () => cleared ? null : location,
    );
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
    final address = (trimmedForEmptyCheck == null ||
            trimmedForEmptyCheck.isEmpty)
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
    _draft = draft.copyWith(
      primaryLocation: () => next.isEmpty ? null : next,
    );
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
    _draft = draft.copyWith(
      primaryLocation: () => next.isEmpty ? null : next,
    );
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
    _draft = draft.copyWith(
      primaryLocation: () => next.isEmpty ? null : next,
    );
    _validate();
    notifyListeners();
  }

  void addCategory(ManagedSelectableCategory category, {bool isPrimary = false}) {
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
    _draft = draft.copyWith(
      categories: [...draft.categories, assignment],
    );
    _validate();
    notifyListeners();
  }

  void removeCategory(String categoryId) {
    final draft = _draft;
    if (draft == null || isSaving) return;
    _draft = draft.copyWith(
      categories: draft.categories.where((c) => c.categoryId != categoryId).toList(),
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
    if (draft == null || profile == null || entityId == null || isBusy) {
      return false;
    }

    final validation = _validate();
    if (!validation.isValid) {
      notifyListeners();
      return false;
    }

    _state = BusinessProfileEditorState.saving;
    _lastErrorCause = null;
    notifyListeners();

    final result = await _gateway.updateManagedProfile(
      entityId: entityId,
      expectedUpdatedAt: profile.updatedAt,
      draft: draft,
    );

    switch (result) {
      case ManagedProfileUpdateSuccess(:final profile):
        _profile = profile;
        _draft = ManagedBusinessProfileDraft.fromProfile(profile);
        _originalDraft = _draft;
        _lastValidation = null;
        _lastErrorCause = null;
        _directoryRefreshFailed = false;
        _state = BusinessProfileEditorState.saveSuccess;
        try {
          await _directoryRepository.refresh();
        } catch (_) {
          // Public Directory refresh is best-effort coherency. The management
          // save already succeeded and the authoritative projection is
          // installed; surface a non-blocking warning so the user can retry.
          _directoryRefreshFailed = true;
        }
        notifyListeners();
        return true;
      case ManagedProfileUpdateDenied(:final cause):
        _lastErrorCause = cause;
        _state = BusinessProfileEditorState.data;
        notifyListeners();
        return false;
    }
  }

  /// Retries the public Directory cache refresh. This does NOT resubmit the
  /// profile mutation; it only calls [CloudDirectoryRepository.refresh].
  Future<void> retryDirectoryRefresh() async {
    final entityId = _entityId;
    if (entityId == null) return;
    try {
      await _directoryRepository.refresh();
      _directoryRefreshFailed = false;
      notifyListeners();
    } catch (_) {
      _directoryRefreshFailed = true;
      notifyListeners();
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

  /// Resets the provider to its initial state (e.g. on sign-out).
  void reset() {
    _entityId = null;
    _state = BusinessProfileEditorState.initial;
    _clearData();
    notifyListeners();
  }
}
