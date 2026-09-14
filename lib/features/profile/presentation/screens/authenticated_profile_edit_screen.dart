import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/navigation/shell_content_insets.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/cloud_profile.dart';
import '../../data/region_preference.dart';
import '../../domain/user_profile.dart';
import '../providers/profile_operation_result.dart';
import '../providers/user_profile_provider.dart';

/// V1-R08 (Part 2) — the AUTHENTICATED profile editor. Edits the canonical
/// cloud profile (role + region preference only) through the single
/// gated mutation [UserProfileProvider.saveRoleAndRegionPreference].
///
/// Rules enforced here:
/// * The cloud profile is the ONLY data source. There is no local fallback,
///   no fabricating display/phone inputs, no legacy Baghdad-area field.
/// * Values are preselected from the authoritative cloud row (role falls back
///   to the canonical `general_user` only when the row has none).
/// * A region is offered as "Not set" only as the INITIAL state; an already-set
///   region can be changed but never cleared (the provider treats a null
///   region as untouched).
/// * Save stays on-screen: on success the form re-baselines and clears dirty;
///   on failure the draft is preserved and a typed, localized cause is shown.
/// * Back with unsaved changes (or an in-flight save) is guarded by PopScope;
///   the user explicitly discards (direct [Navigator.pop]) or stays.
/// * A session loss, a pending cloud load, a settled-but-empty cloud state
///   (fail closed), and a load failure each render a dedicated non-editing
///   state.
class AuthenticatedProfileEditScreen extends StatefulWidget {
  const AuthenticatedProfileEditScreen({super.key});

  @override
  State<AuthenticatedProfileEditScreen> createState() =>
      _AuthenticatedProfileEditScreenState();
}

class _AuthenticatedProfileEditScreenState
    extends State<AuthenticatedProfileEditScreen> {
  String? _selectedRoleCode;
  String? _selectedRegionCode;
  String? _initialRoleCode;
  String? _initialRegionCode;

  bool _pending = false;
  ProfileOperationCause? _lastSaveCause;

  CloudProfile? _lastSyncedCloud;
  String? _lastSyncedRegionCode;

  String tr(String ar, String en) =>
      context.read<LanguageProvider>().isArabic ? ar : en;

  bool get _dirty =>
      _selectedRoleCode != _initialRoleCode ||
      _selectedRegionCode != _initialRegionCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<UserProfileProvider>();
    final cloud = provider.authenticatedProfile;
    final regionCode = provider.authenticatedRegionPreferenceCode;
    // Sync the form whenever a NEW authoritative cloud row becomes visible —
    // including an identity switch that ends up on a different account's row.
    if (cloud != null && !identical(_lastSyncedCloud, cloud)) {
      _syncFromCloud(cloud, regionCode);
      _lastSyncedCloud = cloud;
      _lastSyncedRegionCode = regionCode;
    }
  }

  void _syncFromCloud(CloudProfile cloud, String? regionCode) {
    final roleCode = (cloud.roleCode == null || cloud.roleCode!.isEmpty)
        ? CivilUserType.generalUser.roleCodeValue
        : cloud.roleCode;
    setState(() {
      _selectedRoleCode = roleCode;
      _initialRoleCode = roleCode;
      _selectedRegionCode = regionCode;
      _initialRegionCode = regionCode;
      _pending = false;
      _lastSaveCause = null;
    });
  }

  void _pickRole() {
    final isArabic = context.read<LanguageProvider>().isArabic;
    final roles = canonicalRoleCodes.toList()..sort();

    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr(Ar.profileChangeRole, En.profileChangeRole)),
        children: roles.map((code) {
          final isSelected = _selectedRoleCode == code;
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedRoleCode = code);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _roleName(code, isArabic: isArabic),
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: AppColors.primary, size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _pickRegion() {
    final isArabic = context.read<LanguageProvider>().isArabic;
    // Canonical frozen zones only. "Not set" is NEVER offered as a selectable
    // choice here: it exists only as the initial null state and a set region
    // can be changed but not cleared.
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          tr(
            Ar.profileChangeRegionPreference,
            En.profileChangeRegionPreference,
          ),
        ),
        children: RegionPreferenceCode.all.map((code) {
          final isSelected = _selectedRegionCode == code;
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedRegionCode = code);
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _regionName(code, isArabic: isArabic),
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: AppColors.primary, size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _roleName(String code, {required bool isArabic}) {
    String tr(String ar, String en) => isArabic ? ar : en;
    return _userTypeName(roleCodeToCivilUserType(code), tr);
  }

  String _userTypeName(CivilUserType type, String Function(String, String) tr) {
    switch (type) {
      case CivilUserType.siteEngineer:
        return tr(Ar.siteEngineer, En.siteEngineer);
      case CivilUserType.consultantEngineer:
        return tr(Ar.consultantEngineer, En.consultantEngineer);
      case CivilUserType.structuralEngineer:
        return tr(Ar.structuralEngineer, En.structuralEngineer);
      case CivilUserType.contractor:
        return tr(Ar.contractorName, En.contractorName);
      case CivilUserType.engineeringStudent:
        return tr(Ar.engineeringStudent, En.engineeringStudent);
      case CivilUserType.technicianSupervisor:
        return tr(Ar.technicianSupervisor, En.technicianSupervisor);
      case CivilUserType.supplierShopOwner:
        return tr(Ar.supplierShopOwner, En.supplierShopOwner);
      case CivilUserType.engineeringOffice:
        return tr(Ar.engineeringOffice, En.engineeringOffice);
      case CivilUserType.constructionCompany:
        return tr(Ar.constructionCompany, En.constructionCompany);
      case CivilUserType.buildingOffice:
        return tr(Ar.buildingOffice, En.buildingOffice);
      case CivilUserType.generalUser:
        return tr(Ar.generalUser, En.generalUser);
    }
  }

  String _regionName(String? code, {required bool isArabic}) {
    switch (code) {
      case RegionPreferenceCode.baghdadKarkh:
        return isArabic ? Ar.regionBaghdadKarkh : En.regionBaghdadKarkh;
      case RegionPreferenceCode.baghdadRusafa:
        return isArabic ? Ar.regionBaghdadRusafa : En.regionBaghdadRusafa;
      case RegionPreferenceCode.north:
        return isArabic ? Ar.regionNorth : En.regionNorth;
      case RegionPreferenceCode.central:
        return isArabic ? Ar.regionCentral : En.regionCentral;
      case RegionPreferenceCode.south:
        return isArabic ? Ar.regionSouth : En.regionSouth;
      case RegionPreferenceCode.allIraq:
        return isArabic ? Ar.regionAllIraq : En.regionAllIraq;
      default:
        return tr(Ar.profileNotSet, En.profileNotSet);
    }
  }

  Future<void> _save() async {
    if (_pending || !_dirty) return;
    setState(() {
      _pending = true;
      _lastSaveCause = null;
    });
    final provider = context.read<UserProfileProvider>();
    final result = await provider.saveRoleAndRegionPreference(
      roleCode: _selectedRoleCode ?? CivilUserType.generalUser.roleCodeValue,
      regionPreferenceCode: _selectedRegionCode,
    );
    if (!mounted) return;
    setState(() => _pending = false);
    final messenger = ScaffoldMessenger.of(context);
    if (result.succeeded) {
      // Successful authoritative re-read installed new cloud state. Re-baseline
      // so the form stays put, clean, and consistent with the SSOT.
      final freshRole = result.profile?.roleCode ?? _selectedRoleCode;
      setState(() {
        _initialRoleCode = freshRole;
        _selectedRoleCode = freshRole;
        _initialRegionCode = _selectedRegionCode;
      });
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(tr(Ar.profileUpdated, En.profileUpdated)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
    } else {
      // Draft preserved; typed cause → localized, recoverable message.
      setState(() => _lastSaveCause = result.cause);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_causeMessage(result.cause)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
            action: result.cause == ProfileOperationCause.retryableFailure
                ? SnackBarAction(
                    label: tr(Ar.retry, En.retry),
                    onPressed: _save,
                  )
                : null,
          ),
        );
    }
  }

  String _causeMessage(ProfileOperationCause? cause) {
    switch (cause) {
      case ProfileOperationCause.unauthenticated:
        return tr(
          Ar.profileCauseUnauthenticated,
          En.profileCauseUnauthenticated,
        );
      case ProfileOperationCause.sessionLost:
        return tr(Ar.authSessionLost, En.authSessionLost);
      case ProfileOperationCause.authorityBlocked:
        return tr(
          Ar.profileCauseAuthorityBlocked,
          En.profileCauseAuthorityBlocked,
        );
      case ProfileOperationCause.authFailure:
        return tr(Ar.profileCauseAuthFailure, En.profileCauseAuthFailure);
      case ProfileOperationCause.profileConflict:
        return tr(Ar.profileCauseRegionConflict, En.profileCauseRegionConflict);
      case ProfileOperationCause.permissionDenied:
        return tr(
          Ar.profileCausePermissionDenied,
          En.profileCausePermissionDenied,
        );
      case ProfileOperationCause.provisioningFailure:
        return tr(Ar.profileCauseProvisioning, En.profileCauseProvisioning);
      case ProfileOperationCause.invalidData:
        return tr(Ar.profileCauseInvalidData, En.profileCauseInvalidData);
      case ProfileOperationCause.malformedResponse:
        return tr(Ar.profileCauseMalformed, En.profileCauseMalformed);
      case ProfileOperationCause.retryableFailure:
        return tr(Ar.profileCauseRetryable, En.profileCauseRetryable);
      case ProfileOperationCause.ownershipConflict:
        return tr(
          Ar.profileCauseOwnershipConflict,
          En.profileCauseOwnershipConflict,
        );
      case ProfileOperationCause.unexpected:
      case null:
        return tr(Ar.profileCauseUnexpected, En.profileCauseUnexpected);
    }
  }

  Future<void> _showDiscardDialog() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(Ar.profileUnsavedTitle, En.profileUnsavedTitle)),
        content: Text(tr(Ar.profileUnsavedMessage, En.profileUnsavedMessage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(Ar.profileStay, En.profileStay)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(Ar.profileDiscard, En.profileDiscard)),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      // Direct pop: PopScope(canPop:false) only intercepts maybePop/back-gesture.
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<UserProfileProvider>();
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    if (!auth.isLoggedIn) {
      return _buildStaticScaffold(
        context,
        icon: Icons.lock_clock_outlined,
        title: tr(Ar.authSessionLost, En.authSessionLost),
        message: tr(
          Ar.profileCauseUnauthenticated,
          En.profileCauseUnauthenticated,
        ),
        action: FilledButton(
          onPressed: () => context.go(AppRoutes.userProfile),
          child: Text(tr(Ar.login, En.login)),
        ),
      );
    }
    if (provider.cloudLoadFailed) {
      return _buildStaticScaffold(
        context,
        icon: Icons.cloud_off,
        title: tr(Ar.profileCloudLoadFailed, En.profileCloudLoadFailed),
        message: tr(Ar.profileNotAvailable, En.profileNotAvailable),
        action: FilledButton(
          onPressed: () => provider.ensureCloudProfileLoaded(),
          child: Text(tr(Ar.retry, En.retry)),
        ),
      );
    }
    final cloud = provider.authenticatedProfile;
    if (provider.isCloudProfileLoading) {
      return _buildStaticScaffold(
        context,
        icon: null,
        title: tr(Ar.profileCloudLoading, En.profileCloudLoading),
        message: null,
        action: null,
        showSpinner: true,
      );
    }
    if (cloud == null) {
      // Settled with no cloud row — fail closed: never show a form for a
      // profile that does not exist on the SSOT.
      return _buildStaticScaffold(
        context,
        icon: Icons.person_off_outlined,
        title: tr(Ar.profileNotAvailable, En.profileNotAvailable),
        message: null,
        action: FilledButton(
          onPressed: () => context.go(AppRoutes.userProfile),
          child: Text(tr(Ar.goToProfile, En.goToProfile)),
        ),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final subtitleColor = isDarkMode
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    return PopScope(
      canPop: !_pending && !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showDiscardDialog();
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.background,
        appBar: AppBar(
          title: Text(tr(Ar.profileEditCloudTitle, En.profileEditCloudTitle)),
          elevation: 0,
        ),
        body: ListView(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: shellSafeBottomPadding(context),
          ),
          children: [
            _buildSection(
              context: context,
              icon: Icons.badge_outlined,
              label: tr(Ar.profileRole, En.profileRole),
              value: _roleName(
                _selectedRoleCode ?? CivilUserType.generalUser.roleCodeValue,
                isArabic: isArabic,
              ),
              subtitleColor: subtitleColor,
              textColor: textColor,
              isDark: isDark,
              onTap: _pending ? null : _pickRole,
            ),
            AppSpacing.gapMd,
            _buildSection(
              context: context,
              icon: Icons.public_outlined,
              label: tr(Ar.profileRegionPreference, En.profileRegionPreference),
              value: _regionName(_selectedRegionCode, isArabic: isArabic),
              subtitleColor: subtitleColor,
              textColor: textColor,
              isDark: isDark,
              onTap: _pending ? null : _pickRegion,
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_pending || !_dirty) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: _pending
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        tr(Ar.profileSaveChanges, En.profileSaveChanges),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticScaffold(
    BuildContext context, {
    required IconData? icon,
    required String? title,
    required String? message,
    required Widget? action,
    bool showSpinner = false,
  }) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(tr(Ar.profileEditCloudTitle, En.profileEditCloudTitle)),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showSpinner)
                const SizedBox.square(
                  dimension: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
              if (title != null) ...[
                AppSpacing.gapLg,
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
              if (message != null) ...[
                AppSpacing.gapMd,
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
              if (action != null) ...[
                AppSpacing.gapXl,
                SizedBox(width: double.infinity, child: action),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color subtitleColor,
    required Color textColor,
    required bool isDark,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: ListTile(
        enabled: onTap != null,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        subtitle: Text(value, style: TextStyle(color: subtitleColor)),
        trailing: const Icon(Icons.chevron_left, size: 20),
        onTap: onTap,
      ),
    );
  }
}

extension on CivilUserType {
  String get roleCodeValue => civilUserTypeToRoleCode(this);
}
