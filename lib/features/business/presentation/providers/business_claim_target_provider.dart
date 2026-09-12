import 'package:flutter/foundation.dart';

import '../../domain/business_claim_target.dart';
import '../../domain/business_claim_target_gateway.dart';

/// V1-R04 — declarative state lens for the CLAIM-target read seam.
///
/// Presentation states for the claim selector. The authoritative unclaimed set
/// is re-read on [reload] — the server (trigger 00014) stays the claimability
/// backstop, so this list is a UX candidate set only.
enum BusinessClaimTargetState {
  loading,
  data,
  error,
  empty,
}

class BusinessClaimTargetProvider extends ChangeNotifier {
  BusinessClaimTargetProvider({required BusinessClaimTargetGateway gateway})
      : _gateway = gateway;

  final BusinessClaimTargetGateway _gateway;

  BusinessClaimTargetState _state = BusinessClaimTargetState.loading;
  List<BusinessClaimTarget> _targets = const [];
  String? _error;

  BusinessClaimTargetState get state => _state;
  List<BusinessClaimTarget> get targets => _targets;
  String? get error => _error;

  /// Canonical session epoch (V1-R08 final pass, finding 1). Advanced on every
  /// account-bound reset so an in-flight candidate read that resolves after the
  /// reset is dropped instead of publishing old-session candidates.
  int _sessionEpoch = 0;

  Future<void> reload() async {
    final epoch = _sessionEpoch;
    _state = BusinessClaimTargetState.loading;
    _error = null;
    notifyListeners();
    try {
      final loaded = await _gateway.listUnclaimedTargets();
      if (epoch != _sessionEpoch) return; // reset during in-flight read
      final unclaimed =
          loaded.where((t) => t.isUnclaimed).toList(growable: false);
      _targets = unclaimed;
      _state = unclaimed.isEmpty
          ? BusinessClaimTargetState.empty
          : BusinessClaimTargetState.data;
    } catch (_) {
      if (epoch != _sessionEpoch) return;
      _targets = const [];
      _state = BusinessClaimTargetState.error;
    }
    notifyListeners();
  }

  Future<void> load() async {
    if (_state == BusinessClaimTargetState.data) return;
    await reload();
  }

  /// V1-R08 (finding 8 + final pass 1) — resets the candidate list on a
  /// canonical identity change and advances the session epoch so no
  /// claim-candidate state from a previous session survives (including a read
  /// that is still in flight when the reset fires).
  void resetForIdentityChange() {
    _sessionEpoch++;
    _state = BusinessClaimTargetState.loading;
    _targets = const [];
    _error = null;
    notifyListeners();
  }
}