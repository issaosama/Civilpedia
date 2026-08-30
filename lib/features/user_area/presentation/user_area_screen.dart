import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../localization/ar.dart';
import '../../../routes/app_routes.dart';

/// W3.4 — full-screen User Area hub at `/user`.
///
/// A navigation/aggregation surface (M8 §11; per the User Area constraint it
/// owns no domain entities): it lists only the nested destinations that W3.4
/// actually ships — Profile, Saved, Downloads — and delegates to the existing
/// domain screens. The visible Avatar→`/user` entry and any Bottom Navigation
/// transition are W6.3; this hub is a target surface, reachable by route only.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Ar.userArea,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        children: [
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
                  icon: Icons.person_outline,
                  label: Ar.profile,
                  onTap: () => context.push(AppRoutes.userProfile),
                ),
                const Divider(height: 1),
                _EntryTile(
                  icon: Icons.bookmark_outline,
                  label: Ar.saved,
                  onTap: () => context.push(AppRoutes.userSaved),
                ),
                const Divider(height: 1),
                _EntryTile(
                  icon: Icons.download_outlined,
                  label: Ar.downloads,
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
