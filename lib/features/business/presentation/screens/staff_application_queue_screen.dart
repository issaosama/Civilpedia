import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/business_application_staff_gateway.dart';
import '../../domain/business_application_status.dart';
import '../../domain/business_application_type.dart';
import '../../domain/staff_application_capabilities.dart';
import '../../domain/staff_application_summary.dart';
import '../providers/staff_access_provider.dart';
import '../providers/staff_application_queue_provider.dart';
import '../staff_application_messages.dart';
import '../widgets/business_application_status_presentation.dart';

/// V1-R07 — Staff application queue screen at `/staff/applications`.
class StaffApplicationQueueScreen extends StatefulWidget {
  const StaffApplicationQueueScreen({super.key});

  @override
  State<StaffApplicationQueueScreen> createState() =>
      _StaffApplicationQueueScreenState();
}

class _StaffApplicationQueueScreenState
    extends State<StaffApplicationQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final access = context.read<StaffAccessProvider>();
      access.load().then((_) {
        if (!mounted) return;
        if (access.isAuthorized) {
          context.read<StaffApplicationQueueProvider>().loadInitial();
        }
      });
    });
  }

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          StaffApplicationMessages.localized(
            context,
            Ar.staffApplicationsTitle,
            En.staffApplicationsTitle,
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Consumer<StaffAccessProvider>(
        builder: (context, access, _) {
          return switch (access.state) {
            StaffAccessState.initial || StaffAccessState.resolving =>
              _buildCenterMessage(
                icon: Icons.hourglass_empty_outlined,
                message: StaffApplicationMessages.localized(
                  context,
                  Ar.staffLoadingAccess,
                  En.staffLoadingAccess,
                ),
              ),
            StaffAccessState.signInRequired => _buildCenterMessage(
                icon: Icons.lock_outline,
                message: StaffApplicationMessages.localized(
                  context,
                  Ar.staffSignInRequired,
                  En.staffSignInRequired,
                ),
              ),
            StaffAccessState.noReadPermission || StaffAccessState.error =>
              _buildCenterMessage(
                icon: Icons.block_outlined,
                message: access.state == StaffAccessState.noReadPermission
                    ? StaffApplicationMessages.localized(
                        context,
                        Ar.staffAccessDenied,
                        En.staffAccessDenied,
                      )
                    : StaffApplicationMessages.messageForCause(
                        access.lastErrorCause ??
                            BusinessApplicationStaffCause.unexpected,
                        isArabic: _isArabic,
                      ),
              ),
            StaffAccessState.authorized => _buildQueueBody(context, theme),
          };
        },
      ),
    );
  }

  Widget _buildQueueBody(BuildContext context, ThemeData theme) {
    return Consumer<StaffApplicationQueueProvider>(
      builder: (context, queue, _) {
        return Column(
          children: [
            _FilterBar(filter: queue.filter, onChanged: queue.setFilter),
            Expanded(
              child: switch (queue.state) {
                StaffQueueState.initial || StaffQueueState.loading =>
                  _buildCenterMessage(
                    icon: Icons.hourglass_empty_outlined,
                    message: StaffApplicationMessages.localized(
                      context,
                      Ar.staffLoadingQueue,
                      En.staffLoadingQueue,
                    ),
                  ),
                StaffQueueState.error ||
                StaffQueueState.accessDenied ||
                StaffQueueState.signInRequired =>
                  _buildError(
                    queue.state == StaffQueueState.accessDenied
                        ? StaffApplicationMessages.localized(
                            context,
                            Ar.staffAccessDenied,
                            En.staffAccessDenied,
                          )
                        : queue.state == StaffQueueState.signInRequired
                            ? StaffApplicationMessages.localized(
                                context,
                                Ar.staffSignInRequired,
                                En.staffSignInRequired,
                              )
                            : StaffApplicationMessages.messageForCause(
                                queue.lastErrorCause ??
                                    BusinessApplicationStaffCause.unexpected,
                                isArabic: _isArabic,
                              ),
                    onRetry: queue.retry,
                  ),
                StaffQueueState.empty => _buildCenterMessage(
                    icon: Icons.inbox_outlined,
                    message: StaffApplicationMessages.localized(
                      context,
                      Ar.staffEmptyQueue,
                      En.staffEmptyQueue,
                    ),
                  ),
                StaffQueueState.data ||
                StaffQueueState.loadingMore ||
                StaffQueueState.loadMoreError =>
                  _buildList(context, queue),
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(BuildContext context, StaffApplicationQueueProvider queue) {
    final items = queue.items;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: items.length + (queue.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: switch (queue.state) {
              StaffQueueState.loadingMore => const Center(
                  child: CircularProgressIndicator(),
                ),
              StaffQueueState.loadMoreError => _buildLoadMoreError(context, queue),
              _ => Center(
                  child: TextButton(
                    onPressed: queue.loadMore,
                    child: Text(
                      StaffApplicationMessages.localized(
                        context,
                        Ar.staffLoadMore,
                        En.staffLoadMore,
                      ),
                    ),
                  ),
                ),
            },
          );
        }
        return _QueueCard(
          item: items[index],
          onTap: () => context.push(
            AppRoutes.staffApplicationDetailFor(items[index].id),
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreError(
    BuildContext context,
    StaffApplicationQueueProvider queue,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          StaffApplicationMessages.messageForCause(
            queue.lastErrorCause ?? BusinessApplicationStaffCause.unexpected,
            isArabic: _isArabic,
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.error,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: queue.retryLoadMore,
          child: Text(
            StaffApplicationMessages.localized(
              context,
              Ar.staffRetry,
              En.staffRetry,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterMessage({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message, {required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(
                StaffApplicationMessages.localized(
                  context,
                  Ar.staffRetry,
                  En.staffRetry,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.onChanged,
  });

  final StaffApplicationQueueFilter filter;
  final ValueChanged<StaffApplicationQueueFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final localized = StaffApplicationMessages.localized;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: localized(context, Ar.staffFilterDefault, En.staffFilterDefault),
            selected: filter.status == null,
            onSelected: (_) => onChanged(
              const StaffApplicationQueueFilter(),
            ),
          ),
          _FilterChip(
            label: localized(context, Ar.staffFilterApproved, En.staffFilterApproved),
            selected: filter.status == BusinessApplicationStatus.approved,
            onSelected: (_) => onChanged(
              StaffApplicationQueueFilter(
                status: BusinessApplicationStatus.approved,
                type: filter.type,
              ),
            ),
          ),
          _FilterChip(
            label: localized(context, Ar.staffFilterNeedsCorrection,
                En.staffFilterNeedsCorrection),
            selected: filter.status == BusinessApplicationStatus.needsCorrection,
            onSelected: (_) => onChanged(
              StaffApplicationQueueFilter(
                status: BusinessApplicationStatus.needsCorrection,
                type: filter.type,
              ),
            ),
          ),
          _FilterChip(
            label: localized(context, Ar.staffFilterRejected, En.staffFilterRejected),
            selected: filter.status == BusinessApplicationStatus.rejected,
            onSelected: (_) => onChanged(
              StaffApplicationQueueFilter(
                status: BusinessApplicationStatus.rejected,
                type: filter.type,
              ),
            ),
          ),
          _FilterChip(
            label: localized(context, Ar.staffFilterActivated, En.staffFilterActivated),
            selected: filter.status == BusinessApplicationStatus.activated,
            onSelected: (_) => onChanged(
              StaffApplicationQueueFilter(
                status: BusinessApplicationStatus.activated,
                type: filter.type,
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          _FilterChip(
            label: localized(context, Ar.staffFilterAllTypes, En.staffFilterAllTypes),
            selected: filter.type == null,
            onSelected: (_) => onChanged(
              StaffApplicationQueueFilter(status: filter.status),
            ),
          ),
          _FilterChip(
            label: localized(context, Ar.staffFilterNew, En.staffFilterNew),
            selected: filter.type == BusinessApplicationType.newApplication,
            onSelected: (_) => onChanged(
              StaffApplicationQueueFilter(
                status: filter.status,
                type: BusinessApplicationType.newApplication,
              ),
            ),
          ),
          _FilterChip(
            label: localized(context, Ar.staffFilterClaim, En.staffFilterClaim),
            selected: filter.type == BusinessApplicationType.claim,
            onSelected: (_) => onChanged(
              StaffApplicationQueueFilter(
                status: filter.status,
                type: BusinessApplicationType.claim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.item,
    required this.onTap,
  });

  final StaffApplicationSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final targetSummary = item.type == BusinessApplicationType.newApplication
        ? item.newBusiness?.name ??
              StaffApplicationMessages.localized(
                context,
                Ar.staffNewBusinessContext,
                En.staffNewBusinessContext,
              )
        : item.claimTarget?.name ??
              StaffApplicationMessages.localized(
                context,
                Ar.staffClaimTargetContext,
                En.staffClaimTargetContext,
              );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      targetSummary,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusBadge(status: item.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${StaffApplicationMessages.applicationTypeLabel(item.type, isArabic: isArabic)} • ${_formatDate(item.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              if (item.reviewedByUserId != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    '${StaffApplicationMessages.localized(context, Ar.staffReviewedAt, En.staffReviewedAt)}: ${_formatDate(item.updatedAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BusinessApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = BusinessApplicationStatusPresentation.colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Text(
        BusinessApplicationStatusPresentation.labelFor(
          status,
          isArabic: Localizations.localeOf(context).languageCode == 'ar',
        ),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}