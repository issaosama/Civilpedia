import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/business_application_staff_gateway.dart';
import '../../domain/business_application_status.dart';
import '../../domain/staff_application_capabilities.dart';
import '../../domain/staff_application_detail.dart';
import '../../domain/staff_read_result.dart';

/// V1-R07 — Lifecycle states for staff application detail/review.
enum StaffDetailState {
  initial,
  loading,
  data,
  notFound,
  accessDenied,
  signInRequired,
  error,
  mutating,
  mutationError,
  refreshAfterMutationError,
}

/// V1-R07 — Provider for staff application detail and authoritative staff
/// actions.
///
/// Safety guarantees implemented for the V1-R07 correction pass:
/// - pending-mutation guard runs BEFORE any gateway RPC (finding 2): the
///   action methods defer the gateway call into a closure, so starting a second
///   mutation while one is in flight is a local no-op — exactly one mutation
///   RPC is ever issued per user action;
/// - stale read results are ignored via request sequencing (finding 8);
/// - a successful mutation triggers an authoritative detail reread followed by
///   a queue refresh through the normal provider path (finding 9);
/// - "Refresh details" performs a real authoritative reread — never a dismiss
///   (finding 7);
/// - permission loss (`P0PER`) — from reads, refreshes or mutations — clears
///   privileged detail, removes actions, transitions to a denied state, and
///   fires [onPermissionLost] (finding 1).
class StaffApplicationDetailProvider extends ChangeNotifier {
  StaffApplicationDetailProvider({
    required BusinessApplicationStaffGateway gateway,
    ValueChanged<BusinessApplicationStaffCause>? onPermissionLost,
    Future<void> Function()? onMutationCommitted,
  }) : _gateway = gateway,
       _onPermissionLost = onPermissionLost,
       _onMutationCommitted = onMutationCommitted;

  final BusinessApplicationStaffGateway _gateway;
  final ValueChanged<BusinessApplicationStaffCause>? _onPermissionLost;
  final Future<void> Function()? _onMutationCommitted;

  String? _applicationId;
  StaffDetailState _state = StaffDetailState.initial;
  StaffApplicationDetail? _detail;
  BusinessApplicationStaffCause? _lastErrorCause;
  bool _mutationSucceeded = false;

  int _requestSeq = 0;
  int _sessionGeneration = 0;

  StaffDetailState get state => _state;
  StaffApplicationDetail? get detail => _detail;
  BusinessApplicationStaffCause? get lastErrorCause => _lastErrorCause;
  bool get mutationSucceeded => _mutationSucceeded;

  String? get applicationId => _applicationId;

  /// Loads authoritative detail for [applicationId].
  Future<void> load(String applicationId) async {
    _applicationId = applicationId;
    final request = ++_requestSeq;
    _mutationSucceeded = false;
    _state = StaffDetailState.loading;
    _detail = null;
    _lastErrorCause = null;
    notifyListeners();

    final result = await _gateway.getApplicationDetail(applicationId);
    if (request != _requestSeq) return; // stale: a newer request superseded it
    _applyDetailResult(result);
  }

  /// Refreshes the current detail.
  Future<void> refresh() async {
    final id = _applicationId;
    if (id == null) return;
    final request = ++_requestSeq;
    _state = StaffDetailState.loading;
    _lastErrorCause = null;
    notifyListeners();

    final result = await _gateway.getApplicationDetail(id);
    if (request != _requestSeq) return;
    _applyDetailResult(result);
  }

  /// "Refresh details" — authoritative detail reread requested by the user from
  /// the recoverable post-mutation warning (finding 7). On success the new
  /// detail replaces the stale one and the warning clears; on failure the
  /// recoverable warning state is preserved and the mutation is never resent.
  Future<void> refreshDetail() async {
    final id = _applicationId;
    if (id == null) return;
    final request = ++_requestSeq;
    _lastErrorCause = null;
    notifyListeners();

    final result = await _gateway.getApplicationDetail(id);
    if (request != _requestSeq) return;
    switch (result) {
      case StaffReadSuccess(:final data):
        _detail = data;
        _mutationSucceeded = false;
        _lastErrorCause = null;
        _state = StaffDetailState.data;
      case StaffReadDenied(:final cause):
        _lastErrorCause = cause;
        if (cause == BusinessApplicationStaffCause.staffPermissionDenied ||
            cause == BusinessApplicationStaffCause.unauthenticated) {
          _applyPermissionLoss(cause);
        } else {
          _state = StaffDetailState.refreshAfterMutationError;
        }
      case StaffReadUnavailable():
        _lastErrorCause = BusinessApplicationStaffCause.unexpected;
        _state = StaffDetailState.refreshAfterMutationError;
    }
    notifyListeners();
  }

  void _notifyMutationCommitted() {
    final callback = _onMutationCommitted;
    if (callback == null) return;
    unawaited(callback());
  }

  /// Clears all privileged review state (sign-out, session change, permission
  /// loss). The current application id is retained so a re-entered screen can
  /// reload it, but all privileged data and actions are cleared immediately.
  void clear() {
    _requestSeq++;
    _sessionGeneration++;
    _detail = null;
    _mutationSucceeded = false;
    _lastErrorCause = null;
    _state = StaffDetailState.initial;
    notifyListeners();
  }

  void _applyDetailResult(StaffReadResult<StaffApplicationDetail> result) {
    switch (result) {
      case StaffReadSuccess(:final data):
        _detail = data;
        _lastErrorCause = null;
        _state = StaffDetailState.data;
        _mutationSucceeded = false;
      case StaffReadDenied(:final cause):
        _detail = null;
        _lastErrorCause = cause;
        if (cause == BusinessApplicationStaffCause.staffPermissionDenied ||
            cause == BusinessApplicationStaffCause.unauthenticated) {
          _applyPermissionLoss(cause);
        } else {
          _state = switch (cause) {
            BusinessApplicationStaffCause.applicationNotFound =>
              StaffDetailState.notFound,
            _ => StaffDetailState.error,
          };
        }
      case StaffReadUnavailable():
        _detail = null;
        _lastErrorCause = BusinessApplicationStaffCause.unexpected;
        _state = StaffDetailState.error;
    }
    notifyListeners();
  }

  /// Computes whether [action] is available given [capabilities] and the
  /// authoritative current status.
  bool isActionAvailable(
    StaffAction action,
    StaffApplicationCapabilities capabilities,
  ) {
    final status = _detail?.status;
    if (status == null) return false;
    return _actionPermitted(action, capabilities) &&
        _actionValidForStatus(action, status);
  }

  /// Post-mutation authoritative reread. Failure keeps the recoverable
  /// [StaffDetailState.refreshAfterMutationError]; permission loss clears.
  void _applyPostMutationDetailResult(
    StaffReadResult<StaffApplicationDetail> result,
  ) {
    switch (result) {
      case StaffReadSuccess(:final data):
        _detail = data;
        _lastErrorCause = null;
        _state = StaffDetailState.data;
      case StaffReadDenied(:final cause):
        _lastErrorCause = cause;
        if (cause == BusinessApplicationStaffCause.staffPermissionDenied ||
            cause == BusinessApplicationStaffCause.unauthenticated) {
          _applyPermissionLoss(cause);
        } else {
          _state = StaffDetailState.refreshAfterMutationError;
        }
      case StaffReadUnavailable():
        _lastErrorCause = BusinessApplicationStaffCause.unexpected;
        _state = StaffDetailState.refreshAfterMutationError;
    }
    _mutationSucceeded = false;
    notifyListeners();
  }

  static bool _actionPermitted(
    StaffAction action,
    StaffApplicationCapabilities capabilities,
  ) {
    return switch (action) {
      StaffAction.beginReview => capabilities.canBeginReview,
      StaffAction.returnForCorrection => capabilities.canReturnForCorrection,
      StaffAction.markContacted => capabilities.canMarkContacted,
      StaffAction.scheduleVisit => capabilities.canScheduleVisit,
      StaffAction.approve => capabilities.canApprove,
      StaffAction.reject => capabilities.canReject,
      StaffAction.activate => capabilities.canActivate,
    };
  }

  static bool _actionValidForStatus(
    StaffAction action,
    BusinessApplicationStatus status,
  ) {
    return switch (action) {
      StaffAction.beginReview => status == BusinessApplicationStatus.submitted,
      StaffAction.returnForCorrection =>
        status == BusinessApplicationStatus.underReview,
      StaffAction.markContacted =>
        status == BusinessApplicationStatus.underReview,
      StaffAction.scheduleVisit =>
        status == BusinessApplicationStatus.underReview,
      StaffAction.approve =>
        status == BusinessApplicationStatus.underReview ||
            status == BusinessApplicationStatus.contacted ||
            status == BusinessApplicationStatus.visitScheduled,
      StaffAction.reject =>
        status == BusinessApplicationStatus.underReview ||
            status == BusinessApplicationStatus.contacted ||
            status == BusinessApplicationStatus.visitScheduled,
      StaffAction.activate => status == BusinessApplicationStatus.approved,
    };
  }

  /// Runs one authoritative staff mutation.
  ///
  /// The pending guard runs BEFORE the [call] closure is invoked, so a second
  /// mutation requested while one is in flight never reaches the gateway —
  /// exactly one mutation RPC per user action (finding 2).
  Future<bool> _runMutation(
    Future<BusinessApplicationStaffResult> Function() call,
  ) async {
    final id = _applicationId;
    if (id == null || _state == StaffDetailState.mutating) return false;
    final sessionGeneration = _sessionGeneration;

    _state = StaffDetailState.mutating;
    _lastErrorCause = null;
    notifyListeners();

    final result = await call();
    if (sessionGeneration != _sessionGeneration) return false;
    switch (result) {
      case BusinessApplicationStaffSucceeded():
        _mutationSucceeded = true;
        final readRequest = ++_requestSeq;
        final read = await _gateway.getApplicationDetail(id);
        if (sessionGeneration == _sessionGeneration &&
            readRequest == _requestSeq) {
          final permissionLost =
              read is StaffReadDenied<StaffApplicationDetail> &&
              (read.cause ==
                      BusinessApplicationStaffCause.staffPermissionDenied ||
                  read.cause == BusinessApplicationStaffCause.unauthenticated);
          _applyPostMutationDetailResult(read);
          if (!permissionLost && sessionGeneration == _sessionGeneration) {
            _notifyMutationCommitted();
          }
        }
        return _state == StaffDetailState.data;
      case BusinessApplicationStaffDenied(:final cause):
        _lastErrorCause = cause;
        if (cause == BusinessApplicationStaffCause.staffPermissionDenied ||
            cause == BusinessApplicationStaffCause.unauthenticated) {
          _detail = null;
          _applyPermissionLoss(cause);
        } else {
          _state = switch (cause) {
            BusinessApplicationStaffCause.applicationNotFound =>
              StaffDetailState.notFound,
            _ => StaffDetailState.mutationError,
          };
        }
        notifyListeners();
        return false;
    }
  }

  void _applyPermissionLoss(BusinessApplicationStaffCause cause) {
    _detail = null;
    _mutationSucceeded = false;
    _state = cause == BusinessApplicationStaffCause.unauthenticated
        ? StaffDetailState.signInRequired
        : StaffDetailState.accessDenied;
    _signalPermissionLost();
  }

  Future<bool> beginReview() =>
      _runMutation(() => _gateway.beginReview(_applicationId!));

  Future<bool> returnForCorrection(String reason) => _runMutation(
    () => _gateway.returnForCorrection(_applicationId!, reason: reason),
  );

  Future<bool> markContacted({
    required String contactType,
    String? result,
    String? notes,
  }) => _runMutation(
    () => _gateway.markContacted(
      _applicationId!,
      contactType: contactType,
      result: result,
      notes: notes,
    ),
  );

  Future<bool> scheduleVisit({
    required DateTime scheduledAt,
    String? location,
    String? notes,
  }) => _runMutation(
    () => _gateway.scheduleVisit(
      _applicationId!,
      scheduledAt: scheduledAt,
      location: location,
      notes: notes,
    ),
  );

  Future<bool> approve() =>
      _runMutation(() => _gateway.approve(_applicationId!));

  Future<bool> reject(String reason) =>
      _runMutation(() => _gateway.reject(_applicationId!, reason: reason));

  Future<bool> activate() =>
      _runMutation(() => _gateway.activate(_applicationId!));

  void _signalPermissionLost() {
    final cause = _lastErrorCause;
    if (cause != null) _onPermissionLost?.call(cause);
  }
}

/// V1-R07 — Existing staff lifecycle actions.
enum StaffAction {
  beginReview,
  returnForCorrection,
  markContacted,
  scheduleVisit,
  approve,
  reject,
  activate,
}
