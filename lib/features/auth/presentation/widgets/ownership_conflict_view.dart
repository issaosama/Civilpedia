import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../../domain/entities/auth_error.dart';
import '../providers/auth_provider.dart';

/// V1-R08 (correction finding 3) — ONE safe recovery UX for a second-account
/// ownership conflict (fail closed). Only accepted top-level operations are
/// surfaced:
/// * conflict still ACTIVE ([AuthStatus.ownershipConflict]) → Retry
///   ([AuthProvider.restoreSession] re-runs the authoritative resolution /
///   temporary-session cleanup; on success the device lands back in the
///   neutralized blocked state);
/// * temporary session NEUTRALIZED (guest + [AuthError.ownershipConflict]) →
///   "Return to sign in" ([AuthProvider.clearError] clears the blocking error
///   and [onCleared] may resume the authenticated surface, e.g. `/auth`).
///
/// No normal profile access, no unauthenticated sign-in, no A/B private data
/// and no auto-bootstrap are ever offered here.
class OwnershipConflictView extends StatefulWidget {
  const OwnershipConflictView({
    super.key,
    this.compact = false,
    this.onCleared,
  });

  /// Compact variant for embedding inside a carded hub surface.
  final bool compact;

  /// Invoked after [AuthProvider.clearError] returns the device to a settled
  /// guest state (e.g. navigate to the sign-in screen).
  final VoidCallback? onCleared;

  @override
  State<OwnershipConflictView> createState() => _OwnershipConflictViewState();
}

class _OwnershipConflictViewState extends State<OwnershipConflictView> {
  /// Local duplicate-callback protection ONLY. Canonical provider state stays
  /// authoritative; this merely swallows a rapid second recovery callback that
  /// can arrive before a rebuild disables the affordance.
  bool _isHandling = false;

  /// True while the device is conflict-bound with no session in place: the
  /// conflict still ACTIVE ([AuthStatus.ownershipConflict]), a retry restore in
  /// flight (the blocking error is retained — no guest/local flash), and the
  /// NEUTRALIZED state (guest + [AuthError.ownershipConflict] waiting to be
  /// cleared). This mirrors the surface-level fail-closed guards exactly.
  bool _isBlocked(AuthProvider auth) {
    return auth.error == AuthError.ownershipConflict && !auth.isLoggedIn;
  }

  Future<void> _handle() async {
    if (_isHandling) return;
    _isHandling = true;
    try {
      final auth = context.read<AuthProvider>();
      if (auth.status == AuthStatus.ownershipConflict) {
        if (auth.isRestoring) return;
        await auth.restoreSession();
        return;
      }
      auth.clearError();
      widget.onCleared?.call();
    } finally {
      _isHandling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!_isBlocked(auth)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tr = (String ar, String en) =>
        context.watch<LanguageProvider>().isArabic ? ar : en;

    final stuck = auth.status == AuthStatus.ownershipConflict;
    final restoreInFlight =
        auth.isRestoring && auth.error == AuthError.ownershipConflict;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.gpp_maybe,
          size: widget.compact ? 28 : 48,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(
          tr(Ar.authAccountConflictTitle, En.authAccountConflictTitle),
          textAlign: TextAlign.center,
          style: (widget.compact
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.titleLarge)
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          tr(Ar.authAccountConflictMessage, En.authAccountConflictMessage),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: widget.compact ? 40 : 48,
          child: FilledButton(
            onPressed: stuck || restoreInFlight
                ? (restoreInFlight ? null : _handle)
                : _handle,
            child: restoreInFlight
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    stuck
                        ? tr(Ar.retry, En.retry)
                        : tr(
                            Ar.ownershipConflictReturnToSignIn,
                            En.ownershipConflictReturnToSignIn,
                          ),
                  ),
          ),
        ),
      ],
    );

    if (widget.compact) return body;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: body,
    );
  }
}