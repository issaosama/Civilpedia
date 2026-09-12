import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../localization/ar.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/business_membership_gateway.dart';
import '../../domain/business_profile_management_gateway.dart';
import '../business_profile_management_messages.dart';
import '../providers/managed_businesses_provider.dart';

/// V1-R06 — "My Managed Businesses" list screen.
///
/// Reached from the User Area hub. Renders the authenticated actor's
/// owner/admin-capable businesses and offers the public-profile edit entry
/// only when the centralized capability resolver allows it.
class ManagedBusinessesScreen extends StatefulWidget {
  const ManagedBusinessesScreen({super.key});

  @override
  State<ManagedBusinessesScreen> createState() =>
      _ManagedBusinessesScreenState();
}

class _ManagedBusinessesScreenState extends State<ManagedBusinessesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagedBusinessesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<ManagedBusinessesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          BusinessProfileManagementMessages.titleForList(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _Body(
        isDark: isDark,
        provider: provider,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.isDark,
    required this.provider,
  });

  final bool isDark;
  final ManagedBusinessesProvider provider;

  @override
  Widget build(BuildContext context) {
    switch (provider.state) {
      case ManagedBusinessesState.loading:
        return const Center(child: CircularProgressIndicator());
      case ManagedBusinessesState.signInRequired:
        return _MessageState(
          icon: Icons.lock_outline,
          message: Ar.businessManageSignInRequired,
          actionLabel: Ar.businessSignInButton,
          onAction: () => context.push(AppRoutes.auth),
        );
      case ManagedBusinessesState.empty:
        return _MessageState(
          icon: Icons.business_outlined,
          message: Ar.businessManageEmpty,
        );
      case ManagedBusinessesState.error:
        return _MessageState(
          icon: Icons.error_outline,
          message: Ar.businessManageError,
          detail: provider.errorCause == null
              ? null
              : BusinessProfileManagementMessages.messageForCause(
                  _mapReadCause(provider.errorCause!),
                ),
          actionLabel: Ar.businessRefresh,
          onAction: () => provider.load(),
        );
      case ManagedBusinessesState.unavailable:
        return _MessageState(
          icon: Icons.cloud_off_outlined,
          message: Ar.businessManageError,
          detail: Ar.businessProfileCauseUnavailable,
          actionLabel: Ar.businessRefresh,
          onAction: () => provider.load(),
        );
      case ManagedBusinessesState.data:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: provider.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final item = provider.items[index];
            return _BusinessCard(
              item: item,
              onTap: () {
                if (item.canManagePublicProfile) {
                  context.push(
                    AppRoutes.businessManageDetailFor(item.summary.entityId),
                  );
                }
              },
            );
          },
        );
    }
  }

  static BusinessProfileManagementCause _mapReadCause(
    BusinessManagementReadCause cause,
  ) {
    switch (cause) {
      case BusinessManagementReadCause.unauthenticated:
        return BusinessProfileManagementCause.unauthenticated;
      case BusinessManagementReadCause.permissionDenied:
        return BusinessProfileManagementCause.permissionDenied;
      case BusinessManagementReadCause.unexpected:
        return BusinessProfileManagementCause.unexpected;
    }
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({
    required this.item,
    required this.onTap,
  });

  final ManagedBusinessListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: DesignTokens.softShadow(theme.shadowColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: InkWell(
          onTap: item.canManagePublicProfile ? onTap : null,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.summary.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (item.canManagePublicProfile)
                      Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      )
                    else
                      _Chip(
                        label: Ar.businessManageNotEditable,
                        color: AppColors.warning,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${Ar.businessEntityTypeLabel}: ${item.summary.entityType}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _Chip(
                      label: '${Ar.businessClaimStatus}: '
                          '${item.summary.claimStatus}',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _Chip(
                      label: '${Ar.businessVerificationStatus}: '
                          '${item.summary.verificationStatus}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: (color ?? theme.primaryColor).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color ?? theme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
