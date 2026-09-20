import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../localization/ar.dart';
import '../../localization/en.dart';
import '../services/connectivity_provider.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import '../theme/spacing.dart';

/// One canonical non-blocking transport status surface.
///
/// Consumes [ConnectivityProvider] and displays a compact persistent notice
/// only when transport state is [TransportState.unavailable].
///
/// - UNAVAILABLE: shows the compact banner
/// - AVAILABLE: no banner (hidden)
/// - UNKNOWN: no banner (no false online, no false offline assertion)
///
/// This banner:
/// - does not block navigation
/// - does not block local tools/content
/// - does not use modal dialogs
/// - does not produce repeated snackbars
/// - does not stack duplicates
/// - works in RTL and LTR
/// - works in light/dark
/// - supports narrow screens
/// - provides localized accessibility text
class TransportStatusBanner extends StatelessWidget {
  const TransportStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider?>(
      builder: (context, connectivity, _) {
        if (connectivity == null ||
            connectivity.state != TransportState.unavailable) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        final title = isArabic
            ? Ar.transportUnavailableTitle
            : En.transportUnavailableTitle;
        final message = isArabic
            ? Ar.transportUnavailableMessage
            : En.transportUnavailableMessage;
        final accessibility = isArabic
            ? Ar.transportUnavailableAccessibility
            : En.transportUnavailableAccessibility;

        return Semantics(
          container: true,
          label: accessibility,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkWarningSoft : AppColors.warningSoft,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              border: Border.all(
                color: isDark ? AppColors.darkWarning : AppColors.warning,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 18,
                  color: isDark ? AppColors.darkWarning : AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.mainText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
