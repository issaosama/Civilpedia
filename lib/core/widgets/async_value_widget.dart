import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../localization/ar.dart';
import '../../localization/en.dart';
import '../theme/spacing.dart';

class AsyncValueWidget extends StatelessWidget {
  final bool isLoading;

  /// Opaque error-state signal. Its value is never rendered or forwarded to
  /// presentation builders, so exceptions and backend details remain private.
  final Object? error;

  /// Explicit, localized, user-safe copy for the error state.
  ///
  /// Callers must never pass exception text, backend messages, SQLSTATE values,
  /// stack traces, or `error.toString()` here.
  final String? safeMessage;

  final bool isEmpty;
  final Widget Function() onData;
  final Widget Function()? onLoading;

  /// Builds a custom error state from user-safe presentation copy only.
  final Widget Function(String safeMessage, VoidCallback? onRetry)? onError;

  final Widget Function()? onEmpty;
  final VoidCallback? onRetry;

  const AsyncValueWidget({
    super.key,
    this.isLoading = false,
    this.error,
    this.safeMessage,
    this.isEmpty = false,
    required this.onData,
    this.onLoading,
    this.onError,
    this.onEmpty,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return onLoading?.call() ??
          const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      final presentationMessage =
          safeMessage ?? _localizedErrorFallback(context);
      return onError?.call(presentationMessage, onRetry) ??
          _defaultError(context, presentationMessage, onRetry);
    }

    if (isEmpty) {
      return onEmpty?.call() ?? _defaultEmpty(context);
    }

    return onData();
  }

  String _localizedErrorFallback(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? Ar.errorOccurred : En.errorOccurred;
  }

  String _localizedEmptyFallback(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? Ar.emptyHere : En.emptyHere;
  }

  String _localizedRetry(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? Ar.retry : En.retry;
  }

  Widget _defaultError(
    BuildContext context,
    String presentationMessage,
    VoidCallback? retry,
  ) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            if (retry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  retry();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(_localizedRetry(context)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _defaultEmpty(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _localizedEmptyFallback(context),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
