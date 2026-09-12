import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/business_application_staff_gateway.dart';
import '../../domain/business_application_status.dart';
import '../../domain/business_application_type.dart';
import '../../domain/staff_application_capabilities.dart';
import '../../domain/staff_application_summary.dart';
import '../../domain/staff_read_result.dart';

/// V1-R07 — Lifecycle states for the staff application queue.
enum StaffQueueState {
  initial,
  loading,
  loadingMore,

  /// A load-more (append) failure while earlier pages remain loaded and
  /// visible; retry re-requests the same next page (findings 6, 16).
  loadMoreError,
  data,
  empty,
  error,
  accessDenied,
  signInRequired,
}

/// V1-R07 — Provider for the bounded staff application queue.
///
/// The queue does not load automatically; the screen must call [loadInitial]
/// after capability resolution confirms read access.
///
/// Data-preservation (finding 6): a failed append keeps the already-loaded
/// items and enters [StaffQueueState.loadMoreError] with the cursor
/// unchanged, so [retryLoadMore] re-requests the same next page — never a
/// reset to page one.
///
/// Fail-closed (finding 1): a permission-loss (`P0PER`) response — on load or
/// append — clears privileged queue data, transitions to
/// [StaffQueueState.accessDenied], and fires [onPermissionLost] so sibling
/// privileged detail data is cleared too.
class StaffApplicationQueueProvider extends ChangeNotifier {
  StaffApplicationQueueProvider({
    required BusinessApplicationStaffGateway gateway,
    ValueChanged<BusinessApplicationStaffCause>? onPermissionLost,
  }) : _gateway = gateway,
       _onPermissionLost = onPermissionLost;

  final BusinessApplicationStaffGateway _gateway;
  final ValueChanged<BusinessApplicationStaffCause>? _onPermissionLost;

  StaffQueueState _state = StaffQueueState.initial;
  StaffApplicationQueueFilter _filter = const StaffApplicationQueueFilter();
  StaffApplicationPage? _page;
  BusinessApplicationStaffCause? _lastErrorCause;

  int _pendingRequest = 0;

  StaffQueueState get state => _state;
  StaffApplicationQueueFilter get filter => _filter;
  List<StaffApplicationSummary> get items => _page?.items ?? const [];
  bool get hasMore => _page?.hasMore ?? false;
  BusinessApplicationStaffCause? get lastErrorCause => _lastErrorCause;

  /// Loads the first page with [filter].
  Future<void> loadInitial({StaffApplicationQueueFilter? filter}) async {
    final request = ++_pendingRequest;
    _filter = filter ?? _filter;
    _page = null;
    _lastErrorCause = null;
    _state = StaffQueueState.loading;
    notifyListeners();

    final result = await _gateway.listApplications(
      statusFilter: _filter.status,
      typeFilter: _filter.type,
    );

    if (request != _pendingRequest) return;
    _applyPageResult(result);
  }

  /// Loads the next page using the current page's cursor. Allowed from
  /// [StaffQueueState.data], [StaffQueueState.empty] and — for retry after an
  /// append failure — [StaffQueueState.loadMoreError]; the next page is always
  /// requested with the current, unchanged cursor.
  Future<void> loadMore() async {
    if (_state != StaffQueueState.data &&
        _state != StaffQueueState.empty &&
        _state != StaffQueueState.loadMoreError) {
      return;
    }
    if (!hasMore) return;

    final cursor = _page?.nextCursor;
    final request = ++_pendingRequest;
    _state = StaffQueueState.loadingMore;
    _lastErrorCause = null;
    notifyListeners();

    final result = await _gateway.listApplications(
      statusFilter: _filter.status,
      typeFilter: _filter.type,
      cursor: cursor,
    );

    if (request != _pendingRequest) return;
    _applyAppendResult(result);
  }

  /// Retries the failed next page against the same cursor.
  Future<void> retryLoadMore() => loadMore();

  /// Refreshes the current filter from the first page.
  Future<void> refresh() {
    if (_state == StaffQueueState.loading) return Future.value();
    return loadInitial(filter: _filter);
  }

  /// Changes the filter and reloads from the first page.
  Future<void> setFilter(StaffApplicationQueueFilter filter) {
    if (filter == _filter) return Future.value();
    return loadInitial(filter: filter);
  }

  Future<void> retry() => loadInitial();

  /// Clears all privileged queue data (sign-out, session change, permission
  /// loss). Also invalidates any in-flight request.
  void clear() {
    _pendingRequest++;
    _page = null;
    _lastErrorCause = null;
    _state = StaffQueueState.initial;
    notifyListeners();
  }

  void _applyPageResult(StaffReadResult<StaffApplicationPage> result) {
    switch (result) {
      case StaffReadSuccess(:final data):
        _page = data;
        _lastErrorCause = null;
        _state = data.items.isEmpty
            ? StaffQueueState.empty
            : StaffQueueState.data;
      case StaffReadDenied(:final cause):
        _page = null;
        _lastErrorCause = cause;
        _applyDenied(cause);
      case StaffReadUnavailable():
        _page = null;
        _lastErrorCause = BusinessApplicationStaffCause.unexpected;
        _state = StaffQueueState.error;
    }
    notifyListeners();
  }

  /// Append (load-more) result handler. A non-permission failure keeps the
  /// already-loaded page and enters [StaffQueueState.loadMoreError]; permission
  /// loss clears privileged data.
  void _applyAppendResult(StaffReadResult<StaffApplicationPage> result) {
    switch (result) {
      case StaffReadSuccess(:final data):
        final existing = _page?.items ?? const <StaffApplicationSummary>[];
        final existingIds = existing.map((i) => i.id).toSet();
        final newItems = data.items
            .where((item) => !existingIds.contains(item.id))
            .toList();
        _page = StaffApplicationPage(
          items: [...existing, ...newItems],
          nextCursor: data.nextCursor,
        );
        _lastErrorCause = null;
        _state = _page!.items.isEmpty
            ? StaffQueueState.empty
            : StaffQueueState.data;
      case StaffReadDenied(:final cause):
        _lastErrorCause = cause;
        if (cause == BusinessApplicationStaffCause.staffPermissionDenied ||
            cause == BusinessApplicationStaffCause.unauthenticated) {
          _page = null;
          _state = cause == BusinessApplicationStaffCause.unauthenticated
              ? StaffQueueState.signInRequired
              : StaffQueueState.accessDenied;
          _signalPermissionLost(cause);
        } else {
          _state = StaffQueueState.loadMoreError;
        }
      case StaffReadUnavailable():
        _lastErrorCause = BusinessApplicationStaffCause.unexpected;
        _state = StaffQueueState.loadMoreError;
    }
    notifyListeners();
  }

  void _applyDenied(BusinessApplicationStaffCause cause) {
    _state = switch (cause) {
      BusinessApplicationStaffCause.unauthenticated =>
        StaffQueueState.signInRequired,
      BusinessApplicationStaffCause.staffPermissionDenied =>
        StaffQueueState.accessDenied,
      _ => StaffQueueState.error,
    };
    if (cause == BusinessApplicationStaffCause.staffPermissionDenied ||
        cause == BusinessApplicationStaffCause.unauthenticated) {
      _signalPermissionLost(cause);
    }
  }

  void _signalPermissionLost(BusinessApplicationStaffCause cause) {
    _onPermissionLost?.call(cause);
  }
}
