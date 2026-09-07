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
import 'providers/auth_provider.dart';

/// A5.4 — Google Sign-In surface (replaces the legacy plaintext
/// login/register forms on the same `/auth` route).
///
/// Reachable only from the User/Profile area — there is no login wall, the
/// app stays fully usable as a guest. This screen:
/// * explains the guest state,
/// * offers native "Continue with Google",
/// * maps [AuthError] to localized, non-blocking messages,
/// * returns to the profile area on success.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  Future<void> _signIn() async {
    final auth = context.read<AuthProvider>();
    await auth.signInWithGoogle();
    if (!mounted) return;
    if (auth.isLoggedIn) {
      context.go(AppRoutes.userProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isArabic = context.watch<LanguageProvider>().isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Ar.login,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 32,
          ),
          children: [
            Icon(
              Icons.account_circle,
              size: 88,
              color: theme.primaryColor,
            ),
            AppSpacing.gapLg,
            Text(
              tr(Ar.googleSignInGuestNotice, En.googleSignInGuestNotice),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapXl,
            if (auth.isLoggedIn)
              _buildSignedInCard(context, auth, tr)
            else if (!auth.isAvailable)
              _UnavailableNotice(tr: tr)
            else ...[
              _GoogleSignInButton(
                label: tr(Ar.continueWithGoogle, En.continueWithGoogle),
                onPressed:
                    auth.isRestoring ? null : () => _signIn(),
                restoring: auth.isRestoring,
              ),
              if (auth.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    auth.error == AuthError.unavailable
                        ? tr(
                            Ar.googleSignInUnavailable,
                            En.googleSignInUnavailable,
                          )
                        : tr(
                            Ar.googleSignInFailed,
                            En.googleSignInFailed,
                          ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignedInCard(
    BuildContext context,
    AuthProvider auth,
    String Function(String ar, String en) tr,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '${tr(Ar.signedInAs, En.signedInAs)}: ${auth.currentName ?? auth.currentEmail ?? ''}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        AppSpacing.gapXl,
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () => context.go(AppRoutes.userProfile),
            child: Text(tr(Ar.goToProfile, En.goToProfile)),
          ),
        ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.label,
    required this.onPressed,
    required this.restoring,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool restoring;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
        child: restoring
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _GoogleG(),
                  const SizedBox(width: 12),
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Minimal monochrome-bordered "G" mark (Google wordmark colors one letter).
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: AppColors.googleBlue,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice({required this.tr});

  final String Function(String ar, String en) tr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      tr(Ar.googleSignInUnavailable, En.googleSignInUnavailable),
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.error,
      ),
    );
  }
}