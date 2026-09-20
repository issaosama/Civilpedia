import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../localization/ar.dart';
import '../../localization/en.dart';
import '../theme/spacing.dart';

class ErrorStateWidget extends StatelessWidget {
  /// Legacy compatibility input. Its value is deliberately never rendered.
  /// Use [safeMessage] for explicitly authored, localized presentation copy.
  @Deprecated('Use safeMessage for explicitly authored user-safe copy.')
  final String? message;

  /// Explicit, localized, user-safe copy.
  ///
  /// Never pass exception text, backend messages, SQLSTATE values, stack
  /// traces, or `error.toString()` through this presentation seam.
  final String? safeMessage;

  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.message,
    this.safeMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final presentationMessage =
        safeMessage ?? (isArabic ? Ar.errorOccurred : En.errorOccurred);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              presentationMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onRetry!();
                },
                icon: const Icon(Icons.refresh),
                label: Text(isArabic ? Ar.retry : En.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String? message;

  const EmptyStateWidget({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final presentationMessage =
        message ?? (isArabic ? Ar.emptyHere : En.emptyHere);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(
              presentationMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
