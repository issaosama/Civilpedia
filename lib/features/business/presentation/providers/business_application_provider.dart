import 'package:flutter/foundation.dart';

import '../../../../localization/ar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/business_application.dart';
import '../../domain/business_application_gateway.dart';
import '../../domain/business_application_policy.dart';
import '../../domain/business_application_status.dart';
import '../../domain/business_remote_read.dart';

typedef _ApplicationListReadKey = ({
  String userId,
  int authGeneration,
  int applicationRevision,
});
typedef _ApplicationDetailReadKey = ({
  String userId,
  int authGeneration,
  String applicationId,
  int applicationRevision,
});

enum BusinessApplicationState { signInRequired, loading, data, error, empty }

enum _ApplicationReadLane { list, detail }

/// Applicant-owned application state with independent list/detail read lanes.
class BusinessApplicationProvider extends ChangeNotifier {
  BusinessApplicationProvider({
    required BusinessApplicationGateway gateway,
    required AuthProvider auth,
  }) : _gateway = gateway,
       _auth = auth;

  final BusinessApplicationGateway _gateway;
  final AuthProvider _auth;

  List<BusinessApplication> _applications = const [];
  BusinessApplication? _current;
  String? _detailApplicationId;
  String? _error;

  BusinessApplicationState _listState = BusinessApplicationState.loading;
  BusinessApplicationState _detailState = BusinessApplicationState.loading;
  BusinessRemoteReadPhase _listReadPhase = BusinessRemoteReadPhase.idle;
  BusinessRemoteReadPhase _detailReadPhase = BusinessRemoteReadPhase.idle;
  BusinessRemoteReadFailureKind? _listReadFailure;
  BusinessRemoteReadFailureKind? _detailReadFailure;
  _ApplicationReadLane _activeLane = _ApplicationReadLane.list;

  _ApplicationListReadKey? _listDataKey;
  _ApplicationDetailReadKey? _detailDataKey;
  bool _hasListResult = false;
  bool _hasDetailResult = false;

  int _sessionEpoch = 0;
  int _applicationRevision = 0;
  int _listReadEpoch = 0;
  int _detailReadEpoch = 0;
  final Map<_ApplicationListReadKey, Future<void>> _activeListReads = {};
  final Map<_ApplicationDetailReadKey, Future<void>> _activeDetailReads = {};

  bool _busy = false;
  bool _disposed = false;

  List<BusinessApplication> get applications => _applications;
  BusinessApplication? get current => _current;
  String? get currentApplicationId => _detailApplicationId;

  /// Compatibility lens for the currently active route. The underlying list
  /// and detail states remain independent.
  BusinessApplicationState get state =>
      _activeLane == _ApplicationReadLane.list ? _listState : _detailState;
  BusinessApplicationState get listState => _listState;
  BusinessApplicationState get detailState => _detailState;
  BusinessRemoteReadPhase get listReadPhase => _listReadPhase;
  BusinessRemoteReadPhase get detailReadPhase => _detailReadPhase;
  BusinessRemoteReadFailureKind? get listReadFailure => _listReadFailure;
  BusinessRemoteReadFailureKind? get detailReadFailure => _detailReadFailure;
  String? get error => _error;
  bool get isBusy => _busy;
  int get applicationRevision => _applicationRevision;
  int get activeListReadCount => _activeListReads.length;
  int get activeDetailReadCount => _activeDetailReads.length;

  String? get _currentUserId => _auth.session?.userId;
  bool get isAuthenticated =>
      _auth.isLoggedIn && (_currentUserId?.isNotEmpty ?? false);

  Future<void> loadApplications() {
    _activeLane = _ApplicationReadLane.list;
    final userId = _currentUserId;
    if (!isAuthenticated || userId == null || userId.isEmpty) {
      _clearAccountData();
      _listState = BusinessApplicationState.signInRequired;
      _detailState = BusinessApplicationState.signInRequired;
      _notifyIfAlive();
      return Future.value();
    }

    final key = (
      userId: userId,
      authGeneration: _auth.generation,
      applicationRevision: _applicationRevision,
    );
    final active = _activeListReads[key];
    if (active != null) return active;

    final hasMatchingKnownGood = _hasListResult && _listDataKey == key;
    if (!hasMatchingKnownGood) {
      _applications = const [];
      _listDataKey = null;
      _hasListResult = false;
    }
    _error = null;
    _listReadFailure = null;
    _listReadPhase = hasMatchingKnownGood
        ? BusinessRemoteReadPhase.refreshing
        : BusinessRemoteReadPhase.loading;
    _listState = hasMatchingKnownGood
        ? (_applications.isEmpty
              ? BusinessApplicationState.empty
              : BusinessApplicationState.data)
        : BusinessApplicationState.loading;
    _notifyIfAlive();

    final requestEpoch = ++_listReadEpoch;
    late final Future<void> operation;
    operation = _performListRead(key, requestEpoch).whenComplete(() {
      if (identical(_activeListReads[key], operation)) {
        _activeListReads.remove(key);
      }
    });
    _activeListReads[key] = operation;
    return operation;
  }

  Future<void> _performListRead(
    _ApplicationListReadKey key,
    int requestEpoch,
  ) async {
    try {
      final loaded = await _gateway.listOwnApplications(key.userId);
      if (!_canPublishList(key, requestEpoch)) return;
      _applications = List.unmodifiable(loaded);
      _listDataKey = key;
      _hasListResult = true;
      _listReadFailure = null;
      _listReadPhase = loaded.isEmpty
          ? BusinessRemoteReadPhase.authoritativeEmpty
          : BusinessRemoteReadPhase.loaded;
      _listState = loaded.isEmpty
          ? BusinessApplicationState.empty
          : BusinessApplicationState.data;
    } catch (error) {
      if (!_canPublishList(key, requestEpoch)) return;
      _publishListFailure(
        key,
        error is BusinessRemoteReadException
            ? error.kind
            : BusinessRemoteReadFailureKind.unexpected,
      );
    }
    _notifyIfAlive();
  }

  Future<void> loadApplication(String applicationId) {
    _activeLane = _ApplicationReadLane.detail;
    final userId = _currentUserId;
    if (!isAuthenticated || userId == null || userId.isEmpty) {
      _clearAccountData();
      _listState = BusinessApplicationState.signInRequired;
      _detailState = BusinessApplicationState.signInRequired;
      _notifyIfAlive();
      return Future.value();
    }

    final key = (
      userId: userId,
      authGeneration: _auth.generation,
      applicationId: applicationId,
      applicationRevision: _applicationRevision,
    );
    final active = _activeDetailReads[key];
    if (active != null) return active;

    final hasMatchingKnownGood = _hasDetailResult && _detailDataKey == key;
    _detailApplicationId = applicationId;
    if (!hasMatchingKnownGood) {
      _current = null;
      _detailDataKey = null;
      _hasDetailResult = false;
    }
    _error = null;
    _detailReadFailure = null;
    _detailReadPhase = hasMatchingKnownGood
        ? BusinessRemoteReadPhase.refreshing
        : BusinessRemoteReadPhase.loading;
    _detailState = hasMatchingKnownGood
        ? (_current == null
              ? BusinessApplicationState.empty
              : BusinessApplicationState.data)
        : BusinessApplicationState.loading;
    _notifyIfAlive();

    final requestEpoch = ++_detailReadEpoch;
    late final Future<void> operation;
    operation = _performDetailRead(key, requestEpoch).whenComplete(() {
      if (identical(_activeDetailReads[key], operation)) {
        _activeDetailReads.remove(key);
      }
    });
    _activeDetailReads[key] = operation;
    return operation;
  }

  Future<void> _performDetailRead(
    _ApplicationDetailReadKey key,
    int requestEpoch,
  ) async {
    try {
      final loaded = await _gateway.getOwnApplication(
        key.userId,
        key.applicationId,
      );
      if (!_canPublishDetail(key, requestEpoch)) return;
      if (loaded != null &&
          (loaded.id != key.applicationId || !loaded.belongsTo(key.userId))) {
        _publishDetailFailure(
          key,
          BusinessRemoteReadFailureKind.malformedResponse,
        );
        _notifyIfAlive();
        return;
      }
      _current = loaded;
      _detailApplicationId = key.applicationId;
      _detailDataKey = key;
      _hasDetailResult = true;
      _detailReadFailure = null;
      _detailReadPhase = loaded == null
          ? BusinessRemoteReadPhase.authoritativeNotFound
          : BusinessRemoteReadPhase.loaded;
      _detailState = loaded == null
          ? BusinessApplicationState.empty
          : BusinessApplicationState.data;
    } catch (error) {
      if (!_canPublishDetail(key, requestEpoch)) return;
      _publishDetailFailure(
        key,
        error is BusinessRemoteReadException
            ? error.kind
            : BusinessRemoteReadFailureKind.unexpected,
      );
    }
    _notifyIfAlive();
  }

  void _publishListFailure(
    _ApplicationListReadKey key,
    BusinessRemoteReadFailureKind cause,
  ) {
    _listReadFailure = cause;
    _listReadPhase = BusinessRemoteReadPhase.failed;
    if (_hasListResult && _listDataKey == key) {
      _listState = _applications.isEmpty
          ? BusinessApplicationState.empty
          : BusinessApplicationState.data;
    } else {
      _applications = const [];
      _listState = BusinessApplicationState.error;
    }
  }

  void _publishDetailFailure(
    _ApplicationDetailReadKey key,
    BusinessRemoteReadFailureKind cause,
  ) {
    _detailReadFailure = cause;
    _detailReadPhase = BusinessRemoteReadPhase.failed;
    if (_hasDetailResult && _detailDataKey == key) {
      _detailState = _current == null
          ? BusinessApplicationState.empty
          : BusinessApplicationState.data;
    } else {
      _current = null;
      _detailState = BusinessApplicationState.error;
    }
  }

  bool _canPublishList(_ApplicationListReadKey key, int requestEpoch) {
    return !_disposed &&
        requestEpoch == _listReadEpoch &&
        key.applicationRevision == _applicationRevision &&
        _isCurrentAuth(key.userId, key.authGeneration);
  }

  bool _canPublishDetail(_ApplicationDetailReadKey key, int requestEpoch) {
    return !_disposed &&
        requestEpoch == _detailReadEpoch &&
        key.applicationId == _detailApplicationId &&
        key.applicationRevision == _applicationRevision &&
        _isCurrentAuth(key.userId, key.authGeneration);
  }

  bool _isCurrentAuth(String userId, int generation) {
    return _currentUserId == userId &&
        _auth.generation == generation &&
        _auth.isCurrentSession(userId: userId, generation: generation);
  }

  Future<BusinessApplicationCreateResult?> createNewDraft({
    required Map<String, dynamic> metadata,
  }) async {
    if (_busy || _disposed) return null;
    _busy = true;
    final epoch = _sessionEpoch;
    _notifyIfAlive();
    try {
      final result = await _gateway.createNewDraft(
        currentUserId: _currentUserId ?? '',
        metadata: metadata,
      );
      if (!_canPublishMutation(epoch)) return null;
      if (result is BusinessApplicationCreated) {
        _acceptCreated(result.application);
      }
      return result;
    } finally {
      if (_canPublishMutation(epoch)) {
        _busy = false;
        _notifyIfAlive();
      }
    }
  }

  Future<BusinessApplicationCreateResult?> createClaimDraft({
    required String targetEntityId,
  }) async {
    if (_busy || _disposed) return null;
    _busy = true;
    final epoch = _sessionEpoch;
    _notifyIfAlive();
    try {
      final result = await _gateway.createClaimDraft(
        currentUserId: _currentUserId ?? '',
        targetEntityId: targetEntityId,
      );
      if (!_canPublishMutation(epoch)) return null;
      if (result is BusinessApplicationCreated) {
        _acceptCreated(result.application);
      }
      return result;
    } finally {
      if (_canPublishMutation(epoch)) {
        _busy = false;
        _notifyIfAlive();
      }
    }
  }

  Future<BusinessApplicationSubmitResult?> submit(
    BusinessApplication? app,
  ) async {
    if (_busy ||
        _disposed ||
        app == null ||
        app.status != BusinessApplicationStatus.draft) {
      return null;
    }
    _busy = true;
    final epoch = _sessionEpoch;
    _notifyIfAlive();
    try {
      final result = await _gateway.submitApplication(app);
      if (!_canPublishMutation(epoch)) return null;
      if (result is BusinessApplicationSubmitted) {
        _acceptReplacement(result.application);
      }
      return result;
    } finally {
      if (_canPublishMutation(epoch)) {
        _busy = false;
        _notifyIfAlive();
      }
    }
  }

  Future<BusinessApplicationSubmitResult?> resubmit(
    BusinessApplication? app,
  ) async {
    if (_busy ||
        _disposed ||
        app == null ||
        app.status != BusinessApplicationStatus.needsCorrection) {
      return null;
    }
    _busy = true;
    final epoch = _sessionEpoch;
    _notifyIfAlive();
    try {
      final result = await _gateway.resubmitApplication(app);
      if (!_canPublishMutation(epoch)) return null;
      if (result is BusinessApplicationSubmitted) {
        _acceptReplacement(result.application);
      }
      return result;
    } finally {
      if (_canPublishMutation(epoch)) {
        _busy = false;
        _notifyIfAlive();
      }
    }
  }

  void _acceptCreated(BusinessApplication authoritative) {
    _applicationRevision++;
    _applications = [
      authoritative,
      for (final app in _applications)
        if (app.id != authoritative.id) app,
    ];
    _current = authoritative;
    _detailApplicationId = authoritative.id;
    _stampMutationData(authoritative.id, listChanged: true);
  }

  void _acceptReplacement(BusinessApplication authoritative) {
    _applicationRevision++;
    final index = _applications.indexWhere((app) => app.id == authoritative.id);
    final listChanged = index >= 0;
    if (index >= 0) {
      _applications = [..._applications]..[index] = authoritative;
    }
    if (_current?.id == authoritative.id) {
      _current = authoritative;
      _detailApplicationId = authoritative.id;
    }
    _stampMutationData(authoritative.id, listChanged: listChanged);
  }

  void _stampMutationData(String applicationId, {required bool listChanged}) {
    final userId = _currentUserId;
    if (userId == null) return;
    final generation = _auth.generation;
    if (listChanged) {
      _listDataKey = (
        userId: userId,
        authGeneration: generation,
        applicationRevision: _applicationRevision,
      );
      _hasListResult = true;
      _listState = _applications.isEmpty
          ? BusinessApplicationState.empty
          : BusinessApplicationState.data;
      _listReadPhase = _applications.isEmpty
          ? BusinessRemoteReadPhase.authoritativeEmpty
          : BusinessRemoteReadPhase.loaded;
      _listReadFailure = null;
    }

    if (_current?.id == applicationId) {
      _detailDataKey = (
        userId: userId,
        authGeneration: generation,
        applicationId: applicationId,
        applicationRevision: _applicationRevision,
      );
      _hasDetailResult = true;
      _detailState = BusinessApplicationState.data;
      _detailReadPhase = BusinessRemoteReadPhase.loaded;
      _detailReadFailure = null;
    }
  }

  bool _canPublishMutation(int epoch) => !_disposed && epoch == _sessionEpoch;

  void _clearAccountData() {
    _listReadEpoch++;
    _detailReadEpoch++;
    _activeListReads.clear();
    _activeDetailReads.clear();
    _applications = const [];
    _current = null;
    _detailApplicationId = null;
    _error = null;
    _listReadFailure = null;
    _detailReadFailure = null;
    _listDataKey = null;
    _detailDataKey = null;
    _hasListResult = false;
    _hasDetailResult = false;
    _listReadPhase = BusinessRemoteReadPhase.idle;
    _detailReadPhase = BusinessRemoteReadPhase.idle;
  }

  void resetForIdentityChange() {
    if (_disposed) return;
    _sessionEpoch++;
    _applicationRevision = 0;
    _clearAccountData();
    _listState = BusinessApplicationState.loading;
    _detailState = BusinessApplicationState.loading;
    _activeLane = _ApplicationReadLane.list;
    _busy = false;
    notifyListeners();
  }

  void _notifyIfAlive() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _sessionEpoch++;
    _listReadEpoch++;
    _detailReadEpoch++;
    _activeListReads.clear();
    _activeDetailReads.clear();
    super.dispose();
  }
}

abstract final class BusinessApplicationCauseMessages {
  static String messageFor(BusinessApplicationRejectionCause cause) {
    switch (cause) {
      case BusinessApplicationRejectionCause.guestUser:
        return Ar.businessCauseGuestUser;
      case BusinessApplicationRejectionCause.missingTarget:
        return Ar.businessCauseMissingTarget;
      case BusinessApplicationRejectionCause.invalidMetadata:
        return Ar.businessCauseInvalidMetadata;
      case BusinessApplicationRejectionCause.targetNotFound:
        return Ar.businessCauseTargetNotFound;
      case BusinessApplicationRejectionCause.targetNotClaimable:
        return Ar.businessCauseTargetNotClaimable;
      case BusinessApplicationRejectionCause.alreadyOwner:
        return Ar.businessCauseAlreadyOwner;
      case BusinessApplicationRejectionCause.duplicateClaim:
        return Ar.businessCauseDuplicateClaim;
      case BusinessApplicationRejectionCause.applicantMismatch:
        return Ar.businessCauseApplicantMismatch;
    }
  }

  static String messageForSubmit(BusinessApplicationSubmitCause cause) {
    switch (cause) {
      case BusinessApplicationSubmitCause.unauthenticated:
        return Ar.businessCauseUnauthenticated;
      case BusinessApplicationSubmitCause.notApplicant:
        return Ar.businessCauseNotApplicant;
      case BusinessApplicationSubmitCause.applicationNotFound:
        return Ar.businessCauseApplicationNotFound;
      case BusinessApplicationSubmitCause.invalidTransition:
        return Ar.businessCauseInvalidTransition;
      case BusinessApplicationSubmitCause.phoneRequired:
        return Ar.businessCausePhoneRequired;
      case BusinessApplicationSubmitCause.requiredDataMissing:
        return Ar.businessCauseRequiredDataMissing;
      case BusinessApplicationSubmitCause.targetNotClaimable:
        return Ar.businessCauseTargetNotClaimable;
      case BusinessApplicationSubmitCause.unexpected:
        return Ar.businessCauseUnexpected;
    }
  }
}
