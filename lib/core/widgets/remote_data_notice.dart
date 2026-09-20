import 'package:flutter/material.dart';

import '../../localization/ar.dart';
import '../../localization/en.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import '../theme/spacing.dart';

/// Typed presentation causes for remote data issues.
///
/// Never accepts Exception, raw error, SQLSTATE, stack trace, or arbitrary
/// technical messages. Features map their internal errors to these causes
/// before passing them to this widget.
enum RemoteDataCause {
  offline,
  network,
  timeout,
  serviceUnavailable,
  malformed,
  permissionDenied,
  authRestricted,
  invalidState,
  conflict,
  unexpected,
}

/// A presentation-mode indicator for the remote data notice.
enum RemoteDataNoticeMode {
  /// Compact notice that preserves surrounding content.
  compact,

  /// Full-state notice that replaces the content area.
  noData,
}

/// Presentation primitive for remote data issues.
///
/// This widget MUST NOT accept exceptions, raw backend errors, SQLSTATE codes,
/// stack traces, or arbitrary technical messages. Callers map their errors to
/// [RemoteDataCause] before passing them here.
///
/// Supports two modes:
/// - [RemoteDataNoticeMode.compact]: a small inline notice
/// - [RemoteDataNoticeMode.noData]: a centered full-state notice
class RemoteDataNotice extends StatelessWidget {
  const RemoteDataNotice({
    super.key,
    required this.cause,
    this.mode = RemoteDataNoticeMode.compact,
    this.onRetry,
  });

  /// The typed presentation cause. Never a raw error.
  final RemoteDataCause cause;

  /// Presentation mode: compact preserves content, noData replaces it.
  final RemoteDataNoticeMode mode;

  /// Optional retry callback. Only visible when explicitly provided.
  /// The widget never decides retryability itself.
  final VoidCallback? onRetry;

  String _localizedTitle(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    switch (cause) {
      case RemoteDataCause.offline:
        return isArabic ? Ar.noticeOffline : En.noticeOffline;
      case RemoteDataCause.network:
        return isArabic ? Ar.noticeNetwork : En.noticeNetwork;
      case RemoteDataCause.timeout:
        return isArabic ? Ar.noticeTimeout : En.noticeTimeout;
      case RemoteDataCause.serviceUnavailable:
        return isArabic
            ? Ar.noticeServiceUnavailable
            : En.noticeServiceUnavailable;
      case RemoteDataCause.malformed:
        return isArabic ? Ar.noticeMalformed : En.noticeMalformed;
      case RemoteDataCause.permissionDenied:
        return isArabic ? Ar.noticePermissionDenied : En.noticePermissionDenied;
      case RemoteDataCause.authRestricted:
        return isArabic ? Ar.noticeAuthRestricted : En.noticeAuthRestricted;
      case RemoteDataCause.invalidState:
        return isArabic ? Ar.noticeInvalidState : En.noticeInvalidState;
      case RemoteDataCause.conflict:
        return isArabic ? Ar.noticeConflict : En.noticeConflict;
      case RemoteDataCause.unexpected:
        return isArabic ? Ar.noticeUnexpected : En.noticeUnexpected;
    }
  }

  String _localizedRetry(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? Ar.retry : En.retry;
  }

  String _localizedRetryAccessibility(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? Ar.noticeRetryAccessibility : En.noticeRetryAccessibility;
  }

  IconData _iconForCause() {
    switch (cause) {
      case RemoteDataCause.offline:
        return Icons.wifi_off_rounded;
      case RemoteDataCause.network:
        return Icons.signal_wifi_bad_rounded;
      case RemoteDataCause.timeout:
        return Icons.timer_off_rounded;
      case RemoteDataCause.serviceUnavailable:
        return Icons.cloud_off_rounded;
      case RemoteDataCause.malformed:
        return Icons.broken_image_rounded;
      case RemoteDataCause.permissionDenied:
        return Icons.lock_rounded;
      case RemoteDataCause.authRestricted:
        return Icons.no_accounts_rounded;
      case RemoteDataCause.invalidState:
        return Icons.error_outline_rounded;
      case RemoteDataCause.conflict:
        return Icons.sync_problem_rounded;
      case RemoteDataCause.unexpected:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (mode == RemoteDataNoticeMode.compact) {
      return _buildCompact(context, isDark);
    }
    return _buildNoData(context, isDark);
  }

  Widget _buildCompact(BuildContext context, bool isDark) {
    final title = _localizedTitle(context);
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: title,
      child: Container(
        width: double.infinity,
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
              _iconForCause(),
              size: 18,
              color: isDark ? AppColors.darkWarning : AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                button: true,
                label: _localizedRetryAccessibility(context),
                child: TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _localizedRetry(context),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkBrandBlue
                          : AppColors.brandBlue,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoData(BuildContext context, bool isDark) {
    final title = _localizedTitle(context);
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: title,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconForCause(),
                size: 40,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.mainText,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  button: true,
                  label: _localizedRetryAccessibility(context),
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(_localizedRetry(context)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
