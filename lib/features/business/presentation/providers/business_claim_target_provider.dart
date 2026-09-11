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

  Future<void> reload() async {
    _state = BusinessClaimTargetState.loading;
    _error = null;
    notifyListeners();
    try {
      final loaded = await _gateway.listUnclaimedTargets();
      final unclaimed =
          loaded.where((t) => t.isUnclaimed).toList(growable: false);
      _targets = unclaimed;
      _state = unclaimed.isEmpty
          ? BusinessClaimTargetState.empty
          : BusinessClaimTargetState.data;
    } catch (_) {
      _targets = const [];
      _state = BusinessClaimTargetState.error;
    }
    notifyListeners();
  }

  Future<void> load() async {
    if (_state == BusinessClaimTargetState.data) return;
    await reload();
  }
}