import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/business_membership_capabilities.dart';
import '../../domain/business_membership_gateway.dart';
import '../../domain/managed_business_summary.dart';

/// V1-R06 — UI state for "My Managed Businesses".
enum ManagedBusinessesState {
  signInRequired,
  loading,
  data,
  empty,
  error,
  unavailable,
}

/// V1-R06 — View-model item for the managed businesses list. It layers the
/// centralized capability resolver over the server summary so widgets never do
/// role-string arithmetic.
class ManagedBusinessListItem {
  const ManagedBusinessListItem({
    required this.summary,
    required this.capabilities,
  });

  final ManagedBusinessSummary summary;
  final BusinessMembershipCapabilities capabilities;

  bool get canManagePublicProfile => capabilities.canManageEntity;
}

/// V1-R06 — Provider for the authenticated actor's manageable businesses.
///
/// Reads via [BusinessMembershipGateway.listMyBusinesses] (migration 00019 RPC),
/// which already filters by authenticated session authority. The provider only
/// adds presentation state and capability flags.
class ManagedBusinessesProvider extends ChangeNotifier {
  ManagedBusinessesProvider({
    required BusinessMembershipGateway membershipGateway,
    required AuthProvider auth,
  })  : _membershipGateway = membershipGateway,
        _auth = auth;

  final BusinessMembershipGateway _membershipGateway;
  final AuthProvider _auth;

  ManagedBusinessesState _state = ManagedBusinessesState.loading;
  List<ManagedBusinessListItem> _items = const [];
  BusinessManagementReadCause? _errorCause;

  ManagedBusinessesState get state => _state;
  List<ManagedBusinessListItem> get items => _items;
  BusinessManagementReadCause? get errorCause => _errorCause;
  bool get isBusy => _state == ManagedBusinessesState.loading;

  String? get _currentUserId => _auth.session?.userId;

  bool get _isAuthenticated =>
      _auth.isLoggedIn && (_currentUserId?.isNotEmpty ?? false);

  Future<void> load() async {
    if (!_isAuthenticated) {
      _state = ManagedBusinessesState.signInRequired;
      _items = const [];
      _errorCause = null;
      notifyListeners();
      return;
    }

    if (!_membershipGateway.isAvailable) {
      _state = ManagedBusinessesState.unavailable;
      _items = const [];
      _errorCause = null;
      notifyListeners();
      return;
    }

    _state = ManagedBusinessesState.loading;
    _errorCause = null;
    notifyListeners();

    final result = await _membershipGateway.listMyBusinesses();
    switch (result) {
      case ManagedBusinessListAvailable():
        final summaries = result.businesses;
        _items = [
          for (final summary in summaries)
            ManagedBusinessListItem(
              summary: summary,
              capabilities: summary.capabilities,
            ),
        ];
        _state = _items.isEmpty
            ? ManagedBusinessesState.empty
            : ManagedBusinessesState.data;
      case ManagedBusinessListDenied(:final cause):
        _items = const [];
        _errorCause = cause;
        _state = ManagedBusinessesState.error;
      case ManagedBusinessListUnavailable():
        _items = const [];
        _errorCause = null;
        _state = ManagedBusinessesState.unavailable;
    }
    notifyListeners();
  }

  /// Clears state on sign-out; public callers can invoke this from auth
  /// listeners if needed.
  void reset() {
    _state = ManagedBusinessesState.loading;
    _items = const [];
    _errorCause = null;
    notifyListeners();
  }
}
