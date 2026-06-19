import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/services/theme_provider.dart';
import '../../../core/services/language_provider.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/providers/user_profile_provider.dart';
import '../../profile/presentation/screens/profile_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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

  void _showEditDialog(BuildContext context, AuthProvider auth) {
    final nameCtrl = TextEditingController(text: auth.currentName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(Ar.editProfile),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: Ar.fullName,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Ar.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${Ar.editProfile}: ${nameCtrl.text}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text(Ar.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final profileProvider = context.watch<UserProfileProvider>();
    final lang = context.watch<LanguageProvider>();
    final isArabic = lang.isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Ar.profile,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        children: [
          Container(
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
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: theme.primaryColor,
                      child: Text(
                        // ✅ FIX هنا
                        auth.isLoggedIn &&
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
                    if (auth.isLoggedIn)
                      GestureDetector(
                        onTap: () => _showEditDialog(context, auth),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.primaryColor,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

    Text(
      auth.isLoggedIn && (auth.currentName?.isNotEmpty ?? false)
          ? auth.currentName!
          : tr(Ar.visitor, En.visitor),
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    ),

    const SizedBox(height: 4),

    Text(
      auth.isLoggedIn && (auth.currentEmail?.isNotEmpty ?? false)
          ? auth.currentEmail!
          : tr(Ar.notRegistered, En.notRegistered),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isDark ? Colors.white70 : Colors.black54,
      ),
    ),

                const SizedBox(height: 20),

                if (!auth.isLoggedIn)
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
                      label: const Text(Ar.login),
                    ),
                  ),

                if (auth.isLoggedIn)
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        auth.logout();
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.primaryColor.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(Ar.logout),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildProfileCard(context, profileProvider, isArabic, isDark, theme),

          const SizedBox(height: 24),

          _buildSettingsGroup(
            context,
            title: tr(Ar.generalSettings, En.generalSettings),
            children: [
              SwitchListTile(
                title: const Text(Ar.darkMode),
                subtitle: Text(themeProvider.isDarkMode
                    ? tr(Ar.enabled, En.enabled)
                    : tr(Ar.disabled, En.disabled)),
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
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.language, color: theme.primaryColor),
                title: const Text(Ar.language),
                subtitle: Text(lang.isArabic ? Ar.arabicLanguage : En.englishLanguage),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: () {
                  HapticFeedback.selectionClick();
                  lang.toggleLanguage();
                },
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
                title: const Text(Ar.shareApp),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: () => _shareApp(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.star, color: theme.primaryColor),
                title: const Text(Ar.rateApp),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: _rateApp,
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.headset_mic, color: theme.primaryColor),
                title: const Text(Ar.support),
                trailing: const Icon(Icons.chevron_left, size: 20),
                onTap: _contactSupport,
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.privacy_tip, color: theme.primaryColor),
                title: const Text(Ar.privacyPolicy),
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
                title: const Text(Ar.about),
                subtitle: const Text('Civilpedia v1.0.0'),
              ),
            ],
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
            color: isDark
                ? Theme.of(context).colorScheme.surface
                : Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow: DesignTokens.softShadow(Theme.of(context).shadowColor),
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

  Widget _buildProfileCard(
    BuildContext context,
    UserProfileProvider profileProvider,
    bool isArabic,
    bool isDark,
    ThemeData theme,
  ) {
    String tr(String ar, String en) => isArabic ? ar : en;
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
            Icon(Icons.person_outline, color: AppColors.textSecondary),
            AppSpacing.gapMd,
            Expanded(
              child: Text(
                tr(Ar.profileNotSet, En.profileNotSet),
                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final role = _userTypeName(isArabic, profile.userType);
    final area = isArabic ? profile.baghdadArea.arName : profile.baghdadArea.enName;

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
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileEditScreen(profile: profile),
            ),
          ),
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
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileEditScreen(profile: profile),
            ),
          ),
        ),
      ],
    );
  }
}
