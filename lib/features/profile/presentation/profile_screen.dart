import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/app_dependencies.dart';
import '../../../core/navigation/shell_content_insets.dart';
import '../../../core/services/connectivity_provider.dart';
import '../../../core/services/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/services/theme_provider.dart';
import '../../../core/widgets/remote_data_notice.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../../routes/app_routes.dart';
import '../../../features/auth/domain/entities/auth_error.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/auth/presentation/widgets/ownership_conflict_view.dart';
import '../../profile/data/cloud_profile.dart';
import '../../profile/data/region_preference.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/providers/user_profile_provider.dart';
import 'widgets/authenticated_profile_read_notice.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.profileEditRoute = AppRoutes.profileEdit,
  });

  /// W3.4 — canonical route pushed by both edit entry points, with the current
  /// [LocalUserProfile] passed as `state.extra`.
  ///
  /// Legacy `/profile` keeps the default ([AppRoutes.profileEdit] →
  /// `/profile/edit`). The User Area variant (`/user/profile`) supplies
  /// [AppRoutes.userProfileEdit] so the same screen navigates to the nested
  /// `/user/profile/edit` destination without any UI change or duplication.
  final String profileEditRoute;

  void _shareApp(BuildContext context) {
    Share.share(
      'Civilpedia - ${Ar.appName}\nhttps://play.google.com/store/apps/details?id=com.civilpedia',
    );
  }

  Future<void> _rateApp() async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.civilpedia',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _contactSupport() async {
    final uri = Uri.parse('mailto:support@civilpedia.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openPrivacy() async {
    final uri = Uri.parse('https://civilpedia.com/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
    if (!context.mounted) return;
    await _performSignOut(context, tr);
  }

  Future<void> _performSignOut(
    BuildContext context,
    String Function(String, String) tr,
  ) async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await auth.signOut();
    if (!context.mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final profileProvider = context.watch<UserProfileProvider>();
    final isArabic = context.watch<LanguageProvider>().isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final body = ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        shellSafeBottomPadding(context),
      ),
      children: [
        // V1-R08 correction (finding 1/3): the profile area fails closed on
        // ANY conflict-bound state while no session is present — stuck
        // (blocked resolution), restore-in-flight (blocking error retained) and
        // neutralized (guest + conflict error). Only the accepted recovery
        // actions are offered.
        if (auth.error == AuthError.ownershipConflict && !auth.isLoggedIn)
          _buildOwnershipBlocked(context, tr)
        else ...[
          _buildIdentityHeader(context, auth, isDark, theme, tr),
          const SizedBox(height: 24),
          _buildProfileCard(context, profileProvider, auth, isArabic, isDark, theme),
          const SizedBox(height: 24),
          _buildBackupCard(context, isArabic, isDark, theme),
          const SizedBox(height: 24),
          _buildSettingsGroup(
            context,
            title: tr(Ar.generalSettings, En.generalSettings),
            children: [
              SwitchListTile(
                title: Text(tr(Ar.darkMode, En.darkMode)),
                subtitle: Text(
                  themeProvider.isDarkMode
                      ? tr(Ar.enabled, En.enabled)
                      : tr(Ar.disabled, En.disabled),
                ),
                value: themeProvider.isDarkMode,
                onChanged: (_) {
                  HapticFeedback.selectionClick();
                  themeProvider.toggleTheme();
                },
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: theme.primaryColor,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsGroup(
            context,
            title: tr(Ar.supportSharing, En.supportSharing),
            children: [
              ListTile(
                leading: Icon(Icons.share, color: theme.primaryColor),
                title: Text(tr(Ar.shareApp, En.shareApp)),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: () => _shareApp(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.star, color: theme.primaryColor),
                title: Text(tr(Ar.rateApp, En.rateApp)),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: _rateApp,
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.headset_mic, color: theme.primaryColor),
                title: Text(tr(Ar.support, En.support)),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: _contactSupport,
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.privacy_tip, color: theme.primaryColor),
                title: Text(tr(Ar.privacyPolicy, En.privacyPolicy)),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: _openPrivacy,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsGroup(
            context,
            title: tr(Ar.aboutApp, En.aboutApp),
            children: [
              ListTile(
                leading: Icon(Icons.info_outline, color: theme.primaryColor),
                title: Text(tr(Ar.about, En.about)),
                subtitle: const Text('Civilpedia v1.0.0'),
              ),
            ],
          ),
        ],
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr(Ar.profile, En.profile),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SafeArea(child: body),
    );
  }

  /// V1-R08 correction (finding 3) — the whole profile area fails closed on a
  /// second-account ownership conflict and offers ONLY the accepted recovery
  /// actions (retry resolution / return to sign-in). No sign-out, no profile
  /// affordances, no A/B data.
  Widget _buildOwnershipBlocked(
    BuildContext context,
    String Function(String, String) tr,
  ) {
    return OwnershipConflictView(
      onCleared: () => context.go(AppRoutes.auth),
    );
  }

  Widget _buildIdentityHeader(
    BuildContext context,
    AuthProvider auth,
    bool isDark,
    ThemeData theme,
    String Function(String, String) tr,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
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
          CircleAvatar(
            radius: 46,
            backgroundColor: theme.primaryColor,
            child: Text(
              auth.session != null &&
                      (auth.currentName?.isNotEmpty ?? false)
                  ? auth.currentName![0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 36,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            auth.session != null && (auth.currentName?.isNotEmpty ?? false)
                ? auth.currentName!
                : tr(Ar.visitor, En.visitor),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            auth.session != null && (auth.currentEmail?.isNotEmpty ?? false)
                ? auth.currentEmail!
                : tr(Ar.notRegistered, En.notRegistered),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          if (auth.session == null)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go('/auth');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.login),
                label: Text(tr(Ar.login, En.login)),
              ),
            ),
          if (auth.session != null)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: auth.isSigningOut
                    ? null
                    : () => _confirmAndSignOut(context, tr),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: theme.primaryColor.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: auth.isSigningOut
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
                label: Text(
                  auth.isSigningOut
                      ? tr(Ar.signOutPendingLabel, En.signOutPendingLabel)
                      : tr(Ar.logout, En.logout),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow:
                DesignTokens.softShadow(Theme.of(context).shadowColor),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  String _userTypeName(bool isArabic, CivilUserType type) {
    String tr(String ar, String en) => isArabic ? ar : en;
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

  String _regionPreferenceName(String? code, {required bool isArabic}) {
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

  Widget _buildProfileCard(
    BuildContext context,
    UserProfileProvider profileProvider,
    AuthProvider auth,
    bool isArabic,
    bool isDark,
    ThemeData theme,
  ) {
    String tr(String ar, String en) => isArabic ? ar : en;

    if (auth.isLoggedIn) {
      // V1-R08 (Part 2) — AUTHORITY split for the signed-in session:
      // 1. Cloud bound → cloud card read-only (role/region) + separate Edit
      //    affordance pushing `profileEditRoute` (no extra — the authenticated
      //    editor reads the cloud SSOT itself; the role ListTile must NOT
      //    navigate, F2).
      // 2. Cloud load failed → typed error + retry (never a local fallback).
      // 3. Loading in flight → explicit loading row (never "not set").
      // 4. Settled without a cloud row → not-set row (fail closed).
      // 5. W3.4 auth-agnostic test world (`provider` not auth-wired) → the
      //    local profile card remains authoritative there; it is the ONLY
      //    reason a signed-in user ever sees a local-prop file.
      //
      // P2-C2 — the authenticated branch below now binds the exact
      // authenticated-profile READ lifecycle from the frozen P2-C1 state to the
      // shared typed RemoteDataNotice, with the canonical ConnectivityProvider
      // resolved once here (never inside the notice adapter).
      final cloud = profileProvider.authenticatedProfile;
      final phase = profileProvider.cloudReadPhase;
      final failure = profileProvider.cloudReadFailure;
      final connectivityIsUnavailable =
          context.watch<ConnectivityProvider?>()?.isUnavailable ?? false;

      if (cloud != null) {
        // P2-C2 — known-good cloud row stays authoritative through refresh
        // (with a lightweight indicator) and through an existing-profile read
        // failure (with ONE compact typed notice + manual retry; drafting the
        // card or navigating away is never required).
        final roleCode = cloud.roleCode;
        final role = (roleCode == null || roleCode.isEmpty)
            ? tr(Ar.profileNotSet, En.profileNotSet)
            : _userTypeName(isArabic, roleCodeToCivilUserType(roleCode));
        final regionName = _regionPreferenceName(
          profileProvider.authenticatedRegionPreferenceCode,
          isArabic: isArabic,
        );
        final children = <Widget>[
          ListTile(
            leading: Icon(Icons.badge_outlined, color: theme.primaryColor),
            title: Text(tr(Ar.profileRole, En.profileRole)),
            subtitle: Text(role),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.public_outlined, color: theme.primaryColor),
            title: Text(
              tr(Ar.profileRegionPreference, En.profileRegionPreference),
            ),
            subtitle: Text(regionName),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: _CloudProfileEditButton(
              profileEditRoute: profileEditRoute,
            ),
          ),
        ];
        if (phase == AuthenticatedProfileReadPhase.refreshing) {
          children.add(const _CloudProfileRefreshingRow());
        }
        if (phase == AuthenticatedProfileReadPhase.failed &&
            failure != null) {
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: AuthenticatedProfileReadNotice(
                failure: failure,
                connectivityIsUnavailable: connectivityIsUnavailable,
                mode: RemoteDataNoticeMode.compact,
                onRetry: () => profileProvider.ensureCloudProfileLoaded(),
              ),
            ),
          );
        }
        return _buildSettingsGroup(
          context,
          title:
              tr(Ar.profileMyCivilpediaProfile, En.profileMyCivilpediaProfile),
          children: children,
        );
      }

      switch (phase) {
        case AuthenticatedProfileReadPhase.loading:
          return _buildSettingsGroup(
            context,
            title: tr(
              Ar.profileMyCivilpediaProfile,
              En.profileMyCivilpediaProfile,
            ),
            children: const [
              _CloudProfileLoadingRow(),
            ],
          );
        case AuthenticatedProfileReadPhase.failed:
          if (failure != null) {
            // P2-C2 — typed controlled no-data state: the canonical
            // profileCloudLoadFailed label stays (existing V1-R08 contract)
            // with the existing LanguageProvider-driven Retry control (baseline
            // taps find.text(Ar.retry)), and the shared RemoteDataNotice adds
            // the exact typed cause. No local fallback is ever shown.
            return _buildSettingsGroup(
              context,
              title: tr(
                Ar.profileMyCivilpediaProfile,
                En.profileMyCivilpediaProfile,
              ),
              children: [
                ListTile(
                  leading: Icon(
                    Icons.cloud_off,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    tr(Ar.profileCloudLoadFailed, En.profileCloudLoadFailed),
                  ),
                  trailing: TextButton(
                    onPressed: () => profileProvider.ensureCloudProfileLoaded(),
                    child: Text(tr(Ar.retry, En.retry)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: AuthenticatedProfileReadNotice(
                    failure: failure,
                    connectivityIsUnavailable: connectivityIsUnavailable,
                    mode: RemoteDataNoticeMode.noData,
                  ),
                ),
              ],
            );
          }
          return _buildSettingsGroup(
            context,
            title: tr(
              Ar.profileMyCivilpediaProfile,
              En.profileMyCivilpediaProfile,
            ),
            children: [
              ListTile(
                leading: Icon(
                  Icons.cloud_off,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  tr(Ar.profileCloudLoadFailed, En.profileCloudLoadFailed),
                ),
                trailing: TextButton(
                  onPressed: () => profileProvider.ensureCloudProfileLoaded(),
                  child: Text(tr(Ar.retry, En.retry)),
                ),
              ),
            ],
          );
        case AuthenticatedProfileReadPhase.authoritativeNotFound:
          // P2-C2 — settled "no cloud row": authenticated not-set state
          // (fail closed), with a manual read retry (never a local fallback).
          // The frozen V1-R08 contract keeps the canonical `profileNotSet`
          // label for this state.
          return _buildSettingsGroup(
            context,
            title: tr(
              Ar.profileMyCivilpediaProfile,
              En.profileMyCivilpediaProfile,
            ),
            children: [
              ListTile(
                leading: Icon(
                  Icons.person_off_outlined,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  tr(Ar.profileNotSet, En.profileNotSet),
                ),
                trailing: TextButton(
                  onPressed: () => profileProvider.ensureCloudProfileLoaded(),
                  child: Text(tr(Ar.retry, En.retry)),
                ),
              ),
            ],
          );
        case AuthenticatedProfileReadPhase.idle:
        case AuthenticatedProfileReadPhase.loaded:
        case AuthenticatedProfileReadPhase.refreshing:
          break;
      }
    }

    final profile = profileProvider.profile;
    if (profile == null) {
      return Container(
        padding: AppSpacing.padLg,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_outline,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            AppSpacing.gapMd,
            Expanded(
              child: Text(
                tr(Ar.profileNotSet, En.profileNotSet),
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final role = _userTypeName(isArabic, profile.userType);
    final area =
        isArabic ? profile.baghdadArea.arName : profile.baghdadArea.enName;

    return _buildSettingsGroup(
      context,
      title: tr(Ar.profileMyCivilpediaProfile, En.profileMyCivilpediaProfile),
      children: [
        ListTile(
          leading: Icon(Icons.badge_outlined, color: theme.primaryColor),
          title: Text(tr(Ar.profileRole, En.profileRole)),
          subtitle: Text(role),
          trailing: Text(
            tr(Ar.profileEditPreferences, En.profileEditPreferences),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          onTap: () => context.push(profileEditRoute, extra: profile),
        ),
        const Divider(height: 1),
        ListTile(
          leading: Icon(Icons.location_on_outlined, color: theme.primaryColor),
          title: Text(tr(Ar.profileMainWorkArea, En.profileMainWorkArea)),
          subtitle: Text(area),
          trailing: Text(
            tr(Ar.profileEditPreferences, En.profileEditPreferences),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          onTap: () => context.push(profileEditRoute, extra: profile),
        ),
        const Divider(height: 1),
        ListTile(
          leading: Icon(Icons.public_outlined, color: theme.primaryColor),
          title: Text(
            tr(Ar.profileRegionPreference, En.profileRegionPreference),
          ),
          subtitle: Text(
            _regionPreferenceName(profile.regionPreferenceCode,
                isArabic: isArabic),
          ),
          trailing: Text(
            tr(Ar.profileEditPreferences, En.profileEditPreferences),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          onTap: () => context.push(profileEditRoute, extra: profile),
        ),
      ],
    );
  }

  Widget _buildBackupCard(
    BuildContext context,
    bool isArabic,
    bool isDark,
    ThemeData theme,
  ) {
    String tr(String ar, String en) => isArabic ? ar : en;

    return _buildSettingsGroup(
      context,
      title: tr(Ar.backupAndRestore, En.backupAndRestore),
      children: [
        ListTile(
          leading: Icon(Icons.backup, color: theme.primaryColor),
          title: Text(tr(Ar.backupExportButton, En.backupExportButton)),
          trailing: const Icon(Icons.chevron_left, size: 20),
          onTap: () => _exportBackup(context, isArabic),
        ),
      ],
    );
  }

  Future<void> _exportBackup(BuildContext context, bool isArabic) async {
    String tr(String ar, String en) => isArabic ? ar : en;
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(Ar.backupExportButton, En.backupExportButton)),
        content: Text(tr(Ar.backupExportConfirm, En.backupExportConfirm)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(Ar.backupCancel, En.backupCancel)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(Ar.backupConfirmExport, En.backupConfirmExport)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(tr(Ar.backupExporting, En.backupExporting)),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final fileName = 'Civilpedia_Backup_${dateStr}_$timeStr.json';

      final fullPath = await AppDependencies.backupService.exportToFile(
        fileName,
      );
      debugPrint('Backup exported: $fullPath');

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${tr(Ar.backupExportSuccess, En.backupExportSuccess)}\n$fileName\n$fullPath',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${tr(Ar.backupExportFailed, En.backupExportFailed)}: $e',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

/// V1-R08 (F2) — separate read-only cloud-card "Edit profile" affordance.
/// It pushes `profileEditRoute` WITHOUT an `extra`: the authenticated editor
/// reads the cloud single-source-of-truth itself. Kept as a dedicated widget
/// so the role/region ListTiles stay strictly non-navigating.
class _CloudProfileEditButton extends StatelessWidget {
  const _CloudProfileEditButton({required this.profileEditRoute});

  final String profileEditRoute;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () => context.push(profileEditRoute),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.edit_outlined),
        label: Text(tr(Ar.editProfile, En.editProfile)),
      ),
    );
  }
}

/// V1-R08 — explicit cloud-loading row for an authenticated session whose
/// authoritative profile read is in flight.
class _CloudProfileLoadingRow extends StatelessWidget {
  const _CloudProfileLoadingRow();

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    return Padding(
      padding: AppSpacing.padLg,
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Text(tr(Ar.profileCloudLoading, En.profileCloudLoading)),
          ),
        ],
      ),
    );
  }
}

/// P2-C2 — lightweight refresh indication shown inside the read-only cloud
/// card while a known-good cloud row stays visible during an in-flight
/// re-read ([AuthenticatedProfileReadPhase.refreshing]). Reuses the canonical
/// cloud-loading string; never hides the already-authoritative role/region.
class _CloudProfileRefreshingRow extends StatelessWidget {
  const _CloudProfileRefreshingRow();

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String tr(String ar, String en) => isArabic ? ar : en;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          AppSpacing.gapSm,
          Expanded(
            child: Text(
              tr(Ar.profileCloudLoading, En.profileCloudLoading),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}