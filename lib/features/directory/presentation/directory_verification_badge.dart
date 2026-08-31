import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/spacing.dart';
import '../../../localization/ar.dart';
import '../../../localization/en.dart';
import '../../profile/domain/service_business_profile.dart';

/// W5.5 — presentation-only metadata for a [VerificationStatus].
///
/// Resolves localized label, semantic icon and an existing semantic [AppColors]
/// accent per state. It is NOT a second data model, is NOT persisted, and is
/// used exclusively for display. Colors/icons are supplemental — the badge
/// always includes an icon AND a text label so state is never color-only.
abstract final class DirectoryVerificationPresentation {
  static String labelFor(VerificationStatus status, {required bool isArabic}) {
    switch (status) {
      case VerificationStatus.unverified:
        return isArabic ? Ar.verificationUnverified : En.verificationUnverified;
      case VerificationStatus.pending:
        return isArabic ? Ar.verificationPending : En.verificationPending;
      case VerificationStatus.verified:
        return isArabic ? Ar.verificationVerified : En.verificationVerified;
      case VerificationStatus.rejected:
        return isArabic ? Ar.verificationRejected : En.verificationRejected;
      case VerificationStatus.suspended:
        return isArabic ? Ar.verificationSuspended : En.verificationSuspended;
    }
  }

  static IconData iconFor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.unverified:
        return Icons.help_outline;
      case VerificationStatus.pending:
        return Icons.schedule;
      case VerificationStatus.verified:
        return Icons.verified;
      case VerificationStatus.rejected:
        return Icons.cancel_outlined;
      case VerificationStatus.suspended:
        return Icons.block;
    }
  }

  /// Existing semantic accent. Rejected and Suspended intentionally share the
  /// error family (allowed); they remain distinguishable via icon + text.
  static Color colorFor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.unverified:
        return AppColors.brandNeutral;
      case VerificationStatus.pending:
        return AppColors.warning;
      case VerificationStatus.verified:
        return AppColors.success;
      case VerificationStatus.rejected:
      case VerificationStatus.suspended:
        return AppColors.error;
    }
  }
}

/// W5.5 — canonical reusable Directory verification badge.
///
/// Compact chip showing a semantic icon + localized text label for one of the
/// five [VerificationStatus] states. Presentation-only: it never reads/writes
/// state, never filters and never ranks.
class DirectoryVerificationBadge extends StatelessWidget {
  /// The Directory-owned status to display.
  final VerificationStatus status;

  const DirectoryVerificationBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final label = DirectoryVerificationPresentation.labelFor(
      status,
      isArabic: isArabic,
    );
    final icon = DirectoryVerificationPresentation.iconFor(status);
    final color = DirectoryVerificationPresentation.colorFor(status);

    return Semantics(
      label: label,
      container: true,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
