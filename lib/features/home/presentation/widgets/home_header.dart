import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/services/theme_provider.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../../../../routes/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Compact Home header matching the approved final reference composition.
///
/// * Profile avatar at the physical left.
/// * Civilpedia logo/wordmark centered independently of the side controls.
/// * Theme capsule at the physical right.
/// * Transport status is owned by the canonical shell banner; no local
///   connectivity UI is rendered here.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider?>();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 16, 2),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _AvatarChip(
                key: const ValueKey('home-profile-button'),
                auth: auth,
                onTap: () => context.push(AppRoutes.user),
              ),
            ),
            const _BrandLockup(key: ValueKey('home-brand-lockup')),
            Align(
              alignment: Alignment.centerRight,
              child: _ThemeCapsule(
                key: const ValueKey('home-theme-toggle'),
                isDark: isDark,
                isArabic: isArabic,
                onTap: themeProvider?.toggleTheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: Ar.appName,
      image: true,
      child: Row(
        textDirection: TextDirection.ltr,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 31,
            child: ClipRect(
              child: Transform.scale(
                scale: 1.34,
                child: Image.asset(
                  'assets/branding/app_icon_adaptive_foreground.png',
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            Ar.appName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              color: isDark
                  ? theme.colorScheme.onSurface
                  : AppColors.brandBlueDark,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCapsule extends StatelessWidget {
  final bool isDark;
  final bool isArabic;
  final VoidCallback? onTap;

  const _ThemeCapsule({
    super.key,
    required this.isDark,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isDark
        ? (isArabic ? 'التبديل إلى الوضع الفاتح' : 'Switch to light mode')
        : (isArabic ? 'التبديل إلى الوضع الداكن' : 'Switch to dark mode');
    final capsuleColor = isDark
        ? AppColors.darkSurface
        : AppColors.brandAmberSoft;
    final borderColor = isDark
        ? AppColors.darkBorderStrong
        : AppColors.brandAmber.withValues(alpha: 0.36);
    final iconColor = isDark
        ? AppColors.darkBrandAmber
        : AppColors.brandAmberPressed;

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: 60,
          height: 48,
          child: Center(
            child: Material(
              color: capsuleColor,
              shape: StadiumBorder(side: BorderSide(color: borderColor)),
              elevation: isDark ? 0 : DesignTokens.elevation1,
              shadowColor: theme.shadowColor,
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onTap,
                child: SizedBox(
                  width: 52,
                  height: 34,
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                    size: 20,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  final AuthProvider auth;
  final VoidCallback? onTap;

  const _AvatarChip({super.key, required this.auth, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final initial = auth.isLoggedIn && auth.userName.trim().isNotEmpty
        ? auth.userName.trim().characters.first.toUpperCase()
        : 'Z';
    return Semantics(
      button: true,
      label: isArabic ? Ar.userArea : En.userArea,
      child: SizedBox.square(
        dimension: 48,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: CircleAvatar(
                radius: 18,
                backgroundColor: isDark
                    ? AppColors.darkWarningSoft
                    : AppColors.brandAmberSoft,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkBrandAmber
                        : AppColors.brandAmberPressed,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
