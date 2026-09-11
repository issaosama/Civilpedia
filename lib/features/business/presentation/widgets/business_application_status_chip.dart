import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/language_provider.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/business_application_status.dart';
import 'business_application_status_presentation.dart';

/// V1-R04 — canonical reusable Business Application status chip.
///
/// Compact chip showing a semantic icon + Arabic-first localized text label for
/// one of the nine canonical [BusinessApplicationStatus] values. Presentation
/// only: it never reads/writes state and never renders actions. Unknown
/// statuses fail safe (neutral label, no action).
class BusinessApplicationStatusChip extends StatelessWidget {
  /// The application lifecycle status to display.
  final BusinessApplicationStatus status;

  /// Optional larger/standalone variant for the detail screen.
  final bool enlarged;

  const BusinessApplicationStatusChip({
    super.key,
    required this.status,
    this.enlarged = false,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    final label = BusinessApplicationStatusPresentation.labelFor(
      status,
      isArabic: isArabic,
    );
    final icon = BusinessApplicationStatusPresentation.iconFor(status);
    final color = BusinessApplicationStatusPresentation.colorFor(status);

    return Semantics(
      label: label,
      container: true,
      child: Container(
        padding: enlarged
            ? const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              )
            : const EdgeInsetsDirectional.symmetric(
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
            Icon(
              icon,
              size: enlarged ? AppSpacing.lg : 13,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: enlarged ? 13 : 11,
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