import 'package:flutter/foundation.dart';

import '../../../../localization/ar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/business_application.dart';
import '../../domain/business_application_gateway.dart';
import '../../domain/business_application_policy.dart';
import '../../domain/business_application_status.dart';

/// V1-R04 — UI data state for a [BusinessApplication] collection/read.
enum BusinessApplicationState {
  /// No authenticated session; UI must render sign-in-required.
  signInRequired,

  /// Authoritative read in flight.
  loading,

  /// Authoritative list/detail is available.
  data,

  /// The authoritative read failed; a retry is available.
  error,

  /// The user has zero applications (official empty state).
  empty,
}

/// V1-R04 — rather than inventing state machine again, the provider drives a
/// small mutable view-state; read outcomes are authoritative and failures are
/// retryable. Mutations are server-authorized and exposed as typed results.
class BusinessApplicationProvider extends ChangeNotifier {
  BusinessApplicationProvider({
    required BusinessApplicationGateway gateway,
    required AuthProvider auth,
  })  : _gateway = gateway,
        _auth = auth;

  final BusinessApplicationGateway _gateway;
  final AuthProvider _auth;

  BusinessApplicationState _state = BusinessApplicationState.loading;
  List<BusinessApplication> _applications = const [];
  BusinessApplication? _current;
  String? _error;

  /// The current user's authoritative applications (list state).
  List<BusinessApplication> get applications => _applications;

  /// The currently selected application (detail state).
  BusinessApplication? get current => _current;

  BusinessApplicationState get state => _state;
  String? get error => _error;

  bool get isBusy => _busy;

  /// In-flight mutation guard (submit/resubmit/create).
  bool _busy = false;

  String? get _currentUserId => _auth.session?.userId;

  bool get isAuthenticated =>
      _auth.isLoggedIn && (_currentUserId?.isNotEmpty ?? false);

  /// Loads the authoritative list of the current user's applications.
  Future<void> loadApplications() async {
    final userId = _currentUserId;
    if (!isAuthenticated || userId == null || userId.isEmpty) {
      _state = BusinessApplicationState.signInRequired;
      _applications = const [];
      _error = null;
      notifyListeners();
      return;
    }
    _state = BusinessApplicationState.loading;
    _error = null;
    notifyListeners();
    try {
      _applications = await _gateway.listOwnApplications(userId);
      _state = _applications.isEmpty
          ? BusinessApplicationState.empty
          : BusinessApplicationState.data;
    } catch (_) {
      _applications = const [];
      _state = BusinessApplicationState.error;
    }
    notifyListeners();
  }

  /// Loads one authoritative application by id (only if owned by the user).
  Future<void> loadApplication(String applicationId) async {
    final userId = _currentUserId;
    if (!isAuthenticated || userId == null || userId.isEmpty) {
      _state = BusinessApplicationState.signInRequired;
      _current = null;
      notifyListeners();
      return;
    }
    _state = BusinessApplicationState.loading;
    _current = null;
    _error = null;
    notifyListeners();
    try {
      _current = await _gateway.getOwnApplication(userId, applicationId);
      _state = _current == null
          ? BusinessApplicationState.empty
          : BusinessApplicationState.data;
    } catch (_) {
      _current = null;
      _state = BusinessApplicationState.error;
    }
    notifyListeners();
  }

  /// Files a NEW DRAFT (server-authorized). Never auto-submits.
  Future<BusinessApplicationCreateResult?> createNewDraft({
    required Map<String, dynamic> metadata,
  }) async {
    if (_busy) return null;
    _busy = true;
    notifyListeners();
    try {
      final result = await _gateway.createNewDraft(
        currentUserId: _currentUserId ?? '',
        metadata: metadata,
      );
      if (result is BusinessApplicationCreated) {
        _applications = [result.application, ..._applications];
        _current = result.application;
        _state = BusinessApplicationState.data;
      }
      return result;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Files a CLAIM DRAFT for the canonical directory target id.
  Future<BusinessApplicationCreateResult?> createClaimDraft({
    required String targetEntityId,
  }) async {
    if (_busy) return null;
    _busy = true;
    notifyListeners();
    try {
      final result = await _gateway.createClaimDraft(
        currentUserId: _currentUserId ?? '',
        targetEntityId: targetEntityId,
      );
      if (result is BusinessApplicationCreated) {
        _applications = [result.application, ..._applications];
        _current = result.application;
        _state = BusinessApplicationState.data;
      }
      return result;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Submits the application (server-authorized). Replaces the held application
  /// with the authoritative returned row on success. No-op on any DRAFT/NULL
  /// mismatch (submit is valid only from DRAFT).
  Future<BusinessApplicationSubmitResult?> submit(BusinessApplication? app) async {
    if (_busy || app == null || app.status != BusinessApplicationStatus.draft) {
      return null;
    }
    _busy = true;
    notifyListeners();
    try {
      final result = await _gateway.submitApplication(app);
      if (result is BusinessApplicationSubmitted) {
        _replace(result.application);
      }
      return result;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Resubmits a NEEDS_CORRECTION application. Replaces with the authoritative
  /// returned row on success. No-op otherwise (valid only from
  /// NEEDS_CORRECTION).
  Future<BusinessApplicationSubmitResult?> resubmit(
    BusinessApplication? app,
  ) async {
    if (_busy ||
        app == null ||
        app.status != BusinessApplicationStatus.needsCorrection) {
      return null;
    }
    _busy = true;
    notifyListeners();
    try {
      final result = await _gateway.resubmitApplication(app);
      if (result is BusinessApplicationSubmitted) {
        _replace(result.application);
      }
      return result;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _replace(BusinessApplication authoritative) {
    final index = _applications.indexWhere((a) => a.id == authoritative.id);
    if (index >= 0) {
      _applications = [..._applications]..[index] = authoritative;
    }
    if (_current?.id == authoritative.id) {
      _current = authoritative;
    }
  }
}

/// V1-R04 — localized presentation resolution for a denial cause. Kept here
/// (presentation layer) rather than in a widget so tests can assert mapping
/// without building widgets. Arabic is the canonical UI language (the only
/// active locale today), so Arabic strings are resolved directly.
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