import 'package:flutter/foundation.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/business/domain/business_application_staff_gateway.dart';
import '../../features/business/presentation/providers/staff_access_provider.dart';
import '../../features/business/presentation/providers/staff_application_detail_provider.dart';
import '../../features/business/presentation/providers/staff_application_queue_provider.dart';

/// V1-R07 — Composition root for the three staff operations providers.
///
/// Owning a single instance and wiring the cross-provider callbacks here keeps
/// app-level coherence rules in one place (finding 9, 10):
/// - a permission-loss signal from [access] clears BOTH privileged queues
///   (queue + detail);
/// - a permission-loss signal from the queue clears the detail provider and
///   vice versa, so no privileged review data survives revocation;
/// - a committed mutation refreshes the queue through the normal provider path.
class StaffOperationsScope extends ChangeNotifier {
  StaffOperationsScope({
    required BusinessApplicationStaffGateway gateway,
    required AuthProvider auth,
  }) {
    queue = StaffApplicationQueueProvider(
      gateway: gateway,
      onPermissionLost: _onPrivilegedPermissionLost,
    );
    detail = StaffApplicationDetailProvider(
      gateway: gateway,
      onPermissionLost: _onPrivilegedPermissionLost,
      onMutationCommitted: () => queue.refresh(),
    );
    access = StaffAccessProvider(
      gateway: gateway,
      auth: auth,
      onPermissionLost: _onAccessPermissionLost,
    );
  }

  late final StaffAccessProvider access;
  late final StaffApplicationQueueProvider queue;
  late final StaffApplicationDetailProvider detail;

  void _onAccessPermissionLost() {
    queue.clear();
    detail.clear();
  }

  void _onPrivilegedPermissionLost(BusinessApplicationStaffCause cause) {
    access.applyPrivilegedDenial(cause);
    queue.clear();
    detail.clear();
  }

  @override
  void dispose() {
    // Child ChangeNotifierProviders in main.dart are the single disposal
    // owners. This scope only coordinates their instances.
    super.dispose();
  }
}
