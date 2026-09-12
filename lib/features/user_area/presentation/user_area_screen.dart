import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/services/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../../routes/app_routes.dart';
import '../../auth/domain/entities/auth_error.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/presentation/widgets/ownership_conflict_view.dart';
import '../../business/presentation/providers/staff_access_provider.dart';
import '../../business/presentation/staff_application_messages.dart';
import '../../profile/data/cloud_profile.dart';
import '../../profile/data/region_preference.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/providers/user_profile_provider.dart';

/// W3.4 — full-screen User Area hub at `/user`.
///
/// A navigation/aggregation surface (M8 §11; per the User Area constraint it
/// owns no domain entities): it lists only the nested destinations that W3.4
/// actually ships — Profile, Saved, Downloads — and delegates to the existing
/// domain screens. The visible Avatar→`/user` entry and any Bottom Navigation
/// transition are W6.3; this hub is a target surface, reachable by route only.
///
/// V1-R08 (Part 2) — the hub leads with an identity/profile header
/// ([_UserAreaHeader]): signed-in sessions see their identity, cloud profile
/// state, an Edit-profile push and a sign-out action; guests get a sign-in
/// prompt; a second-account ownership conflict blocks the whole hub (fail
/// closed). The header deliberately renders no [ListTile]s so the hub keeps
/// its exact navigation-card ListTile inventory.
///
/// Inventory-only destinations (`/user/activity`, `/user/preferences`,
/// `/user/theme`, `/user/language`, `/user/backup`, `/user/account`) are
/// deliberately NOT surfaced here — NOT READY → NOT EXPOSED.
class UserAreaScreen extends StatelessWidget {
  const UserAreaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tr = (String ar, String en) =>
        context.watch<LanguageProvider>().isArabic ? ar : en;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(Ar.userArea, En.userArea),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          const _UserAreaHeader(),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
              boxShadow: DesignTokens.softShadow(theme.shadowColor),
            ),
            child: Column(
              children: [
                _EntryTile(
                  icon: Icons.storefront_outlined,
                  label: tr(
                    Ar.businessManageMyBusinesses,
                    En.businessManageMyBusinesses,
                  ),
                  onTap: () => context.push(AppRoutes.businessManage),
                ),
                const Divider(height: 1),
                _EntryTile(
                  icon: Icons.business_center_outlined,
                  label: tr(
                    Ar.businessMyApplications,
                    En.businessMyApplications,
                  ),
                  onTap: () => context.push(AppRoutes.businessApplications),
                ),
                const Divider(height: 1),
                const _StaffEntryTile(),
                const Divider(height: 1),
                _EntryTile(
                  icon: Icons.person_outline,
                  label: tr(Ar.profile, En.profile),
                  onTap: () => context.push(AppRoutes.userProfile),
                ),
                const Divider(height: 1),
                _EntryTile(
                  icon: Icons.bookmark_outline,
                  label: tr(Ar.saved, En.saved),
                  onTap: () => context.push(AppRoutes.userSaved),
                ),
                const Divider(height: 1),
                _EntryTile(
                  icon: Icons.download_outlined,
                  label: tr(Ar.downloads, En.downloads),
                  onTap: () => context.push(AppRoutes.userDownloads),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// V1-R08 (Part 2) — identity + cloud-profile header for the User Area hub.
///
/// Deliberately ListTile-free: every hub ListTile assertion counts the
/// navigation-card entries, and the header must never change that inventory.
class _UserAreaHeader extends StatefulWidget {
  const _UserAreaHeader();

  @override
  State<_UserAreaHeader> createState() => _UserAreaHeaderState();
}

class _UserAreaHeaderState extends State<_UserAreaHeader> {
  Future<void> _confirmAndSignOut(
    BuildContext context,
    String Function(String, String) tr,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(Ar.signOutConfirmTitle, En.signOutConfirmTitle)),
        content: Text(tr(Ar.signOutConfirmMessage, En.signOutConfirmMessage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(Ar.cancel, En.cancel)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(Ar.logout, En.logout)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    await _performSignOut(context, tr);
  }

  Future<void> _performSignOut(
    BuildContext context,
    String Function(String, String) tr,
  ) async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await auth.signOut();
    if (!mounted) return;
    if (auth.error == AuthError.signOutFailed) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(tr(Ar.signOutFailed, En.signOutFailed)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: tr(Ar.retry, En.retry),
              onPressed: () => _performSignOut(context, tr),
            ),
          ),
        );
    }
  }

  String _roleLabel(String? code, {required bool isArabic}) {
    String tr(String ar, String en) => isArabic ? ar : en;
    if (code == null || code.isEmpty) return tr(Ar.profileNotSet, En.profileNotSet);
    switch (roleCodeToCivilUserType(code)) {
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

  String _regionLabel(String? code, {required bool isArabic}) {
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
        return isArabic ? Ar.profileNotSet : En.profileNotSet;
    }
  }

  Widget _buildCloudLine(
    BuildContext context,
    UserProfileProvider provider,
    String Function(String, String) tr,
  ) {
    final theme = Theme.of(context);
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final cloud = provider.authenticatedProfile;
    if (cloud != null) {
      final role = _roleLabel(cloud.roleCode, isArabic: isArabic);
      final region = _regionLabel(
        provider.authenticatedRegionPreferenceCode,
        isArabic: isArabic,
      );
      return Text(
        '$role · $region',
        style: theme.textTheme.bodyMedium?.copyWith(color: muted),
      );
    }
    if (provider.cloudLoadFailed) {
      return Row(
        children: [
          const Icon(Icons.cloud_off, size: 18, color: AppColors.error),
          AppSpacing.gapSm,
          Expanded(
            child: Text(
              tr(Ar.profileCloudLoadFailed, En.profileCloudLoadFailed),
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => provider.ensureCloudProfileLoaded(),
            child: Text(tr(Ar.retry, En.retry)),
          ),
        ],
      );
    }
    if (provider.isCloudProfileLoading) {
      return Row(
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          AppSpacing.gapSm,
          Text(
            tr(Ar.profileCloudLoading, En.profileCloudLoading),
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      );
    }
    return Text(
      tr(Ar.profileNotAvailable, En.profileNotAvailable),
      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<UserProfileProvider>();
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final isDark = theme.brightness == Brightness.dark;
    String tr(String ar, String en) => isArabic ? ar : en;

    // V1-R08 correction (finding 1/3) — fail closed on ANY conflict-bound
    // state while no session is present: stuck (blocked resolution),
    // restore-in-flight (the blocking error is retained) and neutralized
    // (guest + conflict error). Only the accepted recovery actions render.
    final conflictBlocked =
        auth.error == AuthError.ownershipConflict && !auth.isLoggedIn;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: DesignTokens.softShadow(theme.shadowColor),
      ),
      child: conflictBlocked
          ? OwnershipConflictView(
              compact: true,
              onCleared: () => context.go(AppRoutes.auth),
            )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.primaryColor,
                child: Text(
                  auth.session != null && (auth.currentName?.isNotEmpty ?? false)
                      ? auth.currentName![0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppSpacing.gapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.session != null &&
                              (auth.currentName?.isNotEmpty ?? false)
                          ? auth.currentName!
                          : tr(Ar.visitor, En.visitor),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      auth.session != null &&
                              (auth.currentEmail?.isNotEmpty ?? false)
                          ? auth.currentEmail!
                          : tr(Ar.notRegistered, En.notRegistered),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (auth.session != null) ...[
            _buildCloudLine(context, provider, tr),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.userProfileEdit),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.primaryColor.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(tr(Ar.editProfile, En.editProfile)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: auth.isSigningOut
                          ? null
                          : () => _confirmAndSignOut(context, tr),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: auth.isSigningOut
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout),
                      label: Text(
                        auth.isSigningOut
                            ? tr(
                                Ar.signOutPendingLabel,
                                En.signOutPendingLabel,
                              )
                            : tr(Ar.logout, En.logout),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              tr(Ar.userAreaSignInPrompt, En.userAreaSignInPrompt),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                onPressed: () => context.go(AppRoutes.auth),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.login),
                label: Text(tr(Ar.login, En.login)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StaffEntryTile extends StatefulWidget {
  const _StaffEntryTile();

  @override
  State<_StaffEntryTile> createState() => _StaffEntryTileState();
}

/// Staff entry tile shown only to sessions with staff read permission.
///
/// The provider is always supplied by the production composition root
/// (`StaffOperationsScope`); resolution failures are assert-time bugs, never a
/// silent hide (findings 11, 19).
class _StaffEntryTileState extends State<_StaffEntryTile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StaffAccessProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffAccessProvider>(
      builder: (context, access, _) {
        if (!access.isAuthorized) return const SizedBox.shrink();
        return _EntryTile(
          icon: Icons.admin_panel_settings_outlined,
          label: StaffApplicationMessages.localized(
            context,
            Ar.staffOperations,
            En.staffOperations,
          ),
          onTap: () => context.push(AppRoutes.staffApplications),
        );
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EntryTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Icon(icon, color: theme.primaryColor),
      trailing: Icon(
        Icons.chevron_left,
        size: 20,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
      ),
      title: Text(label),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      onTap: onTap,
    );
  }
}