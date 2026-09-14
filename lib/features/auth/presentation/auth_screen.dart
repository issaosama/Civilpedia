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
import '../../auth/domain/auth_return_destination.dart';
import '../../auth/domain/entities/auth_error.dart';
import '../../auth/domain/repositories/auth_gateway.dart';
import 'providers/auth_provider.dart';
import 'widgets/ownership_conflict_view.dart';

/// A5.4 — Google Sign-In surface (replaces the legacy plaintext
/// login/register forms on the same `/auth` route).
///
/// Reachable only from the User/Profile area — there is no login wall, the
/// app stays fully usable as a guest. This screen:
/// * explains the guest state,
/// * offers native "Continue with Google",
/// * maps [AuthError] to localized, non-blocking messages,
/// * surfaces the typed post-auth claim/bootstrap lifecycle as an explicit
///   seam (retryable → retry, provisioning → go to profile),
/// * blocks sign-in while a second-account ownership conflict is active,
/// * returns to the profile area only when the post-auth pipeline has settled.
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
    // V1-R08 — navigate only after the post-auth claim/bootstrap pipeline has
    // FULLY settled. A retryable/provisioning seam must not be skipped.
    if (auth.isLoggedIn &&
        auth.postAuthState == PostAuthLifecycleState.success) {
      context.go(_returnDestination() ?? AppRoutes.userProfile);
    }
  }

  Future<void> _retrySetup() async {
    final auth = context.read<AuthProvider>();
    await auth.retryPostAuth();
    if (!mounted) return;
    if (auth.isLoggedIn &&
        auth.postAuthState == PostAuthLifecycleState.success) {
      context.go(_returnDestination() ?? AppRoutes.userProfile);
    }
  }

  /// The `?return=` path captured by the protected-route redirect, validated
  /// through the single [AuthReturnDestination] allowlist so sign-in can only
  /// resume a vetted protected destination (never an external/open URL).
  String? _returnDestination() {
    final state = GoRouterState.of(context);
    final raw = state.uri.queryParameters['return'];
    return AuthReturnDestination.resolve(raw);
  }

  String? _signInErrorMessage(
    AuthProvider auth,
    String Function(String, String) tr,
  ) {
    final error = auth.error;
    if (error == null) return null;
    return switch (error) {
      AuthError.unavailable => tr(
        Ar.googleSignInUnavailable,
        En.googleSignInUnavailable,
      ),
      AuthError.retryableNetwork => tr(
        Ar.authErrorRetryable,
        En.authErrorRetryable,
      ),
      AuthError.signInFailed => tr(
        Ar.googleSignInFailed,
        En.googleSignInFailed,
      ),
      AuthError.unexpected => tr(
        Ar.authErrorUnexpected,
        En.authErrorUnexpected,
      ),
      AuthError.sessionLost => tr(Ar.authSessionLost, En.authSessionLost),
      // Cancellation returns to the quiet guest state (no error row).
      AuthError.signInCancelled ||
      AuthError.signOutFailed ||
      AuthError.sessionExpired ||
      AuthError.ownershipConflict ||
      // C1 — recovery-blocked authority is surfaced by suppressing auth, not
      // by presenting a message that could be mistaken for a transient error.
      AuthError.recoveryBlocked => null,
    };
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
        title: Text(
          tr(Ar.login, En.login),
          style: const TextStyle(fontWeight: FontWeight.bold),
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
            Icon(Icons.account_circle, size: 88, color: theme.primaryColor),
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
            // V1-R08 correction (finding 3) — fail closed on ANY conflict-bound
            // state while no session is present (stuck, restore-in-flight,
            // neutralized). The shared view offers the accepted recovery
            // actions; a raw Google sign-in is never available while the
            // device is still conflict-bound.
            if (auth.error == AuthError.ownershipConflict && !auth.isLoggedIn)
              const OwnershipConflictView()
            else if (auth.isLoggedIn)
              _buildPostAuthArea(context, auth, tr)
            else if (auth.isCleanupBlocked)
              _CleanupRequiredNotice(tr: tr)
            else if (auth.isAuthObservationUnavailable)
              const _RestartRequiredNotice()
            else if (!auth.isAvailable)
              _UnavailableNotice(tr: tr)
            else ...[
              _GoogleSignInButton(
                label: tr(Ar.continueWithGoogle, En.continueWithGoogle),
                onPressed: auth.isRestoring ? null : () => _signIn(),
                restoring: auth.isRestoring,
              ),
              if (_signInErrorMessage(auth, tr) case final message?)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    message,
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

  Widget _buildPostAuthArea(
    BuildContext context,
    AuthProvider auth,
    String Function(String ar, String en) tr,
  ) {
    final theme = Theme.of(context);
    switch (auth.postAuthState) {
      case PostAuthLifecycleState.running:
        return _PostAuthProgress(tr: tr);
      case PostAuthLifecycleState.retryableFailure:
        return _PostAuthRetryable(tr: tr, onRetry: _retrySetup);
      case PostAuthLifecycleState.provisioningFailure:
        return _PostAuthProvisioning(tr: tr);
      case PostAuthLifecycleState.permissionDenied:
        return Text(
          tr(Ar.profileCausePermissionDenied, En.profileCausePermissionDenied),
        );
      case PostAuthLifecycleState.invalidData:
        return Text(tr(Ar.profileCauseInvalidData, En.profileCauseInvalidData));
      case PostAuthLifecycleState.malformedResponse:
        return Text(tr(Ar.profileCauseMalformed, En.profileCauseMalformed));
      case PostAuthLifecycleState.authFailure:
        return Text(tr(Ar.profileCauseAuthFailure, En.profileCauseAuthFailure));
      case PostAuthLifecycleState.unexpected:
        return Text(tr(Ar.profileCauseUnexpected, En.profileCauseUnexpected));
      case PostAuthLifecycleState.ownershipConflict:
      case PostAuthLifecycleState.corruptOwnershipRegistry:
        return const OwnershipConflictView();
      case PostAuthLifecycleState.idle:
      case PostAuthLifecycleState.success:
        return _buildSignedInCard(context, auth, tr);
    }
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

/// V1-R08 — post-auth claim/bootstrap in flight after a successful Google
/// sign-in. The user must not be dumped into the app before their account row
/// is ready; show progress with a way forward.
class _PostAuthProgress extends StatelessWidget {
  const _PostAuthProgress({required this.tr});

  final String Function(String ar, String en) tr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox.square(
          dimension: 32,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        AppSpacing.gapLg,
        Text(
          tr(Ar.authPostSetupRunning, En.authPostSetupRunning),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

/// V1-R08 — the claim/bootstrap pipeline failed transiently. Authentication is
/// authoritative; the user may safely retry from here or proceed to the
/// profile area (the profile seam shows the same lifecycle).
class _PostAuthRetryable extends StatelessWidget {
  const _PostAuthRetryable({required this.tr, required this.onRetry});

  final String Function(String ar, String en) tr;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.cloud_off, size: 40, color: theme.colorScheme.error),
        AppSpacing.gapLg,
        Text(
          tr(Ar.authPostSetupRetryable, En.authPostSetupRetryable),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        AppSpacing.gapXl,
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: onRetry,
            child: Text(tr(Ar.retry, En.retry)),
          ),
        ),
        AppSpacing.gapMd,
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => context.go(AppRoutes.userProfile),
            child: Text(tr(Ar.goToProfile, En.goToProfile)),
          ),
        ),
      ],
    );
  }
}

/// V1-R08 (F7) — Provisioning failed for a provisioning-specific reason. The
/// session is authoritative; the profile seam offers the typed recovery path.
class _PostAuthProvisioning extends StatelessWidget {
  const _PostAuthProvisioning({required this.tr});

  final String Function(String ar, String en) tr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.info_outline, size: 40, color: theme.colorScheme.primary),
        AppSpacing.gapLg,
        Text(
          tr(Ar.authPostSetupProvisioning, En.authPostSetupProvisioning),
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

/// V1-R08 — a second-account ownership conflict is active on this device.
/// Sign-in is blocked until the conflict is resolved; no new Google session is
/// allowed while blockingly bound to another account (fail closed). The
/// recovery actions live in the shared [OwnershipConflictView] (correction
/// finding 3).
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
      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
    );
  }
}

/// V1-R09 H1 — remote sign-out succeeded but owned local cleanup is pending,
/// blocked, or stalled. The profile/account areas are neutralized and only the
/// bounded cleanup retry is offered; a fresh sign-in must NOT be presented.
class _CleanupRequiredNotice extends StatelessWidget {
  const _CleanupRequiredNotice({required this.tr});

  final String Function(String ar, String en) tr;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final message = switch (auth.recoveryStatus) {
      AuthRecoveryStatus.remotePending => tr(
        Ar.authRemotePendingMessage,
        En.authRemotePendingMessage,
      ),
      AuthRecoveryStatus.restartRequired => tr(
        Ar.authRecoveryRestartMessage,
        En.authRecoveryRestartMessage,
      ),
      AuthRecoveryStatus.blockedCleanupFailure ||
      AuthRecoveryStatus.storageFailure => tr(
        Ar.authRecoveryBlockedMessage,
        En.authRecoveryBlockedMessage,
      ),
      AuthRecoveryStatus.exchangeBlockedUnattributed => tr(
        Ar.authUnattributedResetMessage,
        En.authUnattributedResetMessage,
      ),
      AuthRecoveryStatus.localResetRestartRequired => tr(
        Ar.authLocalResetRestartMessage,
        En.authLocalResetRestartMessage,
      ),
      AuthRecoveryStatus.exchangeTimedOutPending => tr(
        Ar.authExchangeTimedOutPendingMessage,
        En.authExchangeTimedOutPendingMessage,
      ),
      AuthRecoveryStatus.exchangeNeutralizing => tr(
        Ar.authExchangeNeutralizingMessage,
        En.authExchangeNeutralizingMessage,
      ),
      AuthRecoveryStatus.exchangeBlockedCleanupFailure => tr(
        Ar.authExchangeBlockedMessage,
        En.authExchangeBlockedMessage,
      ),
      _ => tr(Ar.authLogoutCleanupMessage, En.authLogoutCleanupMessage),
    };
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return Column(
      children: [
        Icon(Icons.shield_outlined, size: 40, color: theme.colorScheme.error),
        AppSpacing.gapLg,
        Text(
          tr(Ar.authRecoveryTitle, En.authRecoveryTitle),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        AppSpacing.gapSm,
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: muted),
        ),
        AppSpacing.gapXl,
        if (auth.recoveryStatus != AuthRecoveryStatus.restartRequired &&
            auth.recoveryStatus != AuthRecoveryStatus.localResetRestartRequired)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: auth.isRecoveryRetryBusy
                  ? null
                  : auth.recoveryStatus ==
                        AuthRecoveryStatus.exchangeBlockedUnattributed
                  ? auth.resetQuarantinedDeviceSignIn
                  : auth.retryAuthCleanup,
              child: Text(
                auth.recoveryStatus ==
                        AuthRecoveryStatus.exchangeBlockedUnattributed
                    ? tr(Ar.resetDeviceSignIn, En.resetDeviceSignIn)
                    : tr(Ar.retryAuthRecovery, En.retryAuthRecovery),
              ),
            ),
          ),
      ],
    );
  }
}

/// V1-R09 H2 — the canonical auth-state observation stream terminated
/// unexpectedly. Fresh authority stays latched off; the app must restart.
class _RestartRequiredNotice extends StatelessWidget {
  const _RestartRequiredNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = (String ar, String en) =>
        context.watch<LanguageProvider>().isArabic ? ar : en;
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return Column(
      children: [
        Icon(Icons.refresh, size: 40, color: theme.colorScheme.error),
        AppSpacing.gapLg,
        Text(
          tr(Ar.authRestartRequired, En.authRestartRequired),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: muted),
        ),
      ],
    );
  }
}
