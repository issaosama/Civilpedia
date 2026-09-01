import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/connectivity_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Light, compact Home header matching the approved reference composition.
///
/// * Civilpedia identity/logo at the top-right (RTL trailing side).
/// * Compact user avatar/profile affordance on the opposite side.
/// * Greeting line directly underneath the logo row.
/// * Existing auth/connectivity behavior preserved; no new business logic.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final connectivity = context.watch<ConnectivityProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    String tr(String ar, String en) => isArabic ? ar : en;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Civilpedia identity at top-right.
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                    child: Image.asset(
                      'assets/branding/app_icon.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    Ar.appName,
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.mainText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Existing user/profile and connectivity affordances.
              _AvatarChip(
                auth: auth,
                onTap: () => context.push(AppRoutes.user),
              ),
              const SizedBox(width: 8),
              _ConnectivityDot(connectivity: connectivity),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            auth.isLoggedIn
                ? '${tr(Ar.welcome, En.welcome)}، ${auth.userName}'
                : tr(Ar.welcome, En.welcome),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  final AuthProvider auth;
  final VoidCallback? onTap;

  const _AvatarChip({required this.auth, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Semantics(
      button: true,
      label: isArabic ? Ar.userArea : En.userArea,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            auth.isLoggedIn ? auth.userName[0].toUpperCase() : 'Z',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectivityDot extends StatelessWidget {
  final ConnectivityProvider connectivity;

  const _ConnectivityDot({required this.connectivity});

  @override
  Widget build(BuildContext context) {
    return Icon(
      connectivity.isOnline ? Icons.wifi : Icons.wifi_off,
      size: 16,
      color: connectivity.isOnline ? Colors.green.shade600 : Colors.orange.shade400,
    );
  }
}
