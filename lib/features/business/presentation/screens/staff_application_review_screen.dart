import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../../domain/business_application_staff_gateway.dart';
import '../../domain/business_application_status.dart';
import '../../domain/business_application_type.dart';
import '../../domain/staff_application_capabilities.dart';
import '../../domain/staff_application_detail.dart';
import '../../domain/staff_application_id.dart';
import '../../domain/staff_application_summary.dart';
import '../providers/staff_access_provider.dart';
import '../providers/staff_application_detail_provider.dart';
import '../staff_application_messages.dart';
import '../widgets/business_application_status_presentation.dart';

/// V1-R07 — Staff application review/detail screen at
/// `/staff/applications/:applicationId`.
///
/// Deep-link safety (finding 14): a malformed (non-UUID) `:applicationId` fails
/// safe — the screen shows the not-found state and NEVER invokes the detail RPC
/// with garbage.
class StaffApplicationReviewScreen extends StatefulWidget {
  const StaffApplicationReviewScreen({
    super.key,
    required this.applicationId,
  });

  final String applicationId;

  @override
  State<StaffApplicationReviewScreen> createState() =>
      _StaffApplicationReviewScreenState();
}

class _StaffApplicationReviewScreenState
    extends State<StaffApplicationReviewScreen> {
  bool? _invalidRouteId;

  bool get isArabic => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    if (!StaffApplicationId.isValidUuid(widget.applicationId)) {
      _invalidRouteId = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final access = context.read<StaffAccessProvider>();
      access.load().then((_) {
        if (!mounted || _invalidRouteId == true) return;
        if (access.isAuthorized) {
          context
              .read<StaffApplicationDetailProvider>()
              .load(widget.applicationId);
        }
      });
    });
  }

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
      body: _invalidRouteId == true
          ? _buildCenterMessage(
              icon: Icons.search_off_outlined,
              message: StaffApplicationMessages.localized(
                context,
                Ar.staffCauseNotFound,
                En.staffCauseNotFound,
              ),
            )
          : Consumer<StaffAccessProvider>(
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
                              isArabic: isArabic,
                            ),
                    ),
                  StaffAccessState.authorized => _buildDetailBody(theme),
                };
              },
            ),
    );
  }

  Widget _buildDetailBody(ThemeData theme) {
    return Consumer<StaffApplicationDetailProvider>(
      builder: (context, detail, _) {
        return switch (detail.state) {
          StaffDetailState.initial || StaffDetailState.loading =>
            _buildCenterMessage(
              icon: Icons.hourglass_empty_outlined,
              message: StaffApplicationMessages.localized(
                context,
                Ar.staffLoadingDetail,
                En.staffLoadingDetail,
              ),
            ),
          StaffDetailState.notFound => _buildCenterMessage(
              icon: Icons.search_off_outlined,
              message: StaffApplicationMessages.localized(
                context,
                Ar.staffCauseNotFound,
                En.staffCauseNotFound,
              ),
            ),
          StaffDetailState.accessDenied => _buildCenterMessage(
              icon: Icons.block_outlined,
              message: StaffApplicationMessages.localized(
                context,
                Ar.staffAccessDenied,
                En.staffAccessDenied,
              ),
            ),
          StaffDetailState.signInRequired => _buildCenterMessage(
              icon: Icons.lock_outline,
              message: StaffApplicationMessages.localized(
                context,
                Ar.staffSignInRequired,
                En.staffSignInRequired,
              ),
            ),
          StaffDetailState.error || StaffDetailState.mutationError =>
            _buildError(
              StaffApplicationMessages.messageForCause(
                detail.lastErrorCause ??
                    BusinessApplicationStaffCause.unexpected,
                isArabic: isArabic,
              ),
              onRetry: detail.refresh,
            ),
          StaffDetailState.refreshAfterMutationError => _buildDetailContent(
              theme,
              detail.detail!,
              showRefreshWarning: true,
            ),
          StaffDetailState.data || StaffDetailState.mutating =>
            _buildDetailContent(
              theme,
              detail.detail!,
              isMutating: detail.state == StaffDetailState.mutating,
            ),
        };
      },
    );
  }

  Widget _buildDetailContent(
    ThemeData theme,
    StaffApplicationDetail detail, {
    bool isMutating = false,
    bool showRefreshWarning = false,
  }) {
    final capabilities = context.watch<StaffAccessProvider>().capabilities ??
        const StaffApplicationCapabilities.empty();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        if (showRefreshWarning)
          _WarningBanner(
            message: StaffApplicationMessages.localized(
              context,
              Ar.staffRefreshAfterMutation,
              En.staffRefreshAfterMutation,
            ),
            actionLabel: StaffApplicationMessages.localized(
              context,
              Ar.staffRefreshDetail,
              En.staffRefreshDetail,
            ),
            onAction: () => context
                .read<StaffApplicationDetailProvider>()
                .refreshDetail(),
          ),
        _DetailHeader(detail: detail),
        const SizedBox(height: AppSpacing.md),
        _ApplicantCard(detail: detail),
        const SizedBox(height: AppSpacing.md),
        _ContextCard(detail: detail),
        const SizedBox(height: AppSpacing.md),
        _HistoryCard(detail: detail),
        const SizedBox(height: AppSpacing.md),
        _ActionsPanel(
          detail: detail,
          capabilities: capabilities,
          isMutating: isMutating,
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
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
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

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_problem_outlined, color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.warning),
            ),
          ),
          Flexible(
            child: TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.detail});

  final StaffApplicationDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                BusinessApplicationStatusPresentation.labelFor(
                  detail.status,
                  isArabic: isArabic,
                ),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: BusinessApplicationStatusPresentation.colorFor(
                      detail.status),
                ),
              ),
            ),
            _TypeChip(type: detail.type),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${StaffApplicationMessages.localized(context, Ar.staffApplicationId, En.staffApplicationId)}: ${detail.id}',
          style: theme.textTheme.bodySmall,
        ),
        Text(
          '${StaffApplicationMessages.localized(context, Ar.staffSubmittedAt, En.staffSubmittedAt)}: ${_formatDate(detail.createdAt)}',
          style: theme.textTheme.bodySmall,
        ),
        if (detail.reviewedAt != null)
          Text(
            '${StaffApplicationMessages.localized(context, Ar.staffReviewedAt, En.staffReviewedAt)}: ${_formatDate(detail.reviewedAt!)}',
            style: theme.textTheme.bodySmall,
          ),
        if (detail.approvedAt != null)
          Text(
            '${StaffApplicationMessages.localized(context, Ar.staffApprovedAt, En.staffApprovedAt)}: ${_formatDate(detail.approvedAt!)}',
            style: theme.textTheme.bodySmall,
          ),
        if (detail.activatedAt != null)
          Text(
            '${StaffApplicationMessages.localized(context, Ar.staffActivatedAt, En.staffActivatedAt)}: ${_formatDate(detail.activatedAt!)}',
            style: theme.textTheme.bodySmall,
          ),
        if (detail.returnReason != null && detail.returnReason!.isNotEmpty)
          _ReasonTile(
            title: StaffApplicationMessages.localized(
              context,
              Ar.staffReturnReason,
              En.staffReturnReason,
            ),
            reason: detail.returnReason!,
          ),
        if (detail.rejectionReason != null &&
            detail.rejectionReason!.isNotEmpty)
          _ReasonTile(
            title: StaffApplicationMessages.localized(
              context,
              Ar.staffRejectionReason,
              En.staffRejectionReason,
            ),
            reason: detail.rejectionReason!,
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final BusinessApplicationType type;

  @override
  Widget build(BuildContext context) {
    final label = StaffApplicationMessages.applicationTypeLabel(
      type,
      isArabic: Localizations.localeOf(context).languageCode == 'ar',
    );
    return Chip(
      label: Text(label),
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({required this.title, required this.reason});

  final String title;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            reason,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({required this.detail});

  final StaffApplicationDetail detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              StaffApplicationMessages.localized(
                context,
                Ar.staffApplicant,
                En.staffApplicant,
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(detail.applicantDisplayName),
            if (detail.applicantPhone != null)
              Text(
                '${StaffApplicationMessages.localized(context, Ar.staffApplicantPhone, En.staffApplicantPhone)}: ${detail.applicantPhone}',
              ),
          ],
        ),
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.detail});

  final StaffApplicationDetail detail;

  @override
  Widget build(BuildContext context) {
    final newBusiness = detail.newBusiness;
    final claimTarget = detail.claimTarget;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.type == BusinessApplicationType.newApplication
                  ? StaffApplicationMessages.localized(
                      context,
                      Ar.staffNewBusinessContext,
                      En.staffNewBusinessContext,
                    )
                  : StaffApplicationMessages.localized(
                      context,
                      Ar.staffClaimTargetContext,
                      En.staffClaimTargetContext,
                    ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (newBusiness != null) Text(newBusiness.name),
            if (claimTarget != null) ...[
              Text(claimTarget.name),
              Text(
                '${StaffApplicationMessages.localized(context, Ar.staffTargetEntityId, En.staffTargetEntityId)}: ${claimTarget.id}',
              ),
              if (claimTarget.lifecycleStatus != null)
                Text(
                  claimTarget.lifecycleStatus!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.detail});

  final StaffApplicationDetail detail;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              StaffApplicationMessages.localized(
                context,
                Ar.staffContactHistory,
                En.staffContactHistory,
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (detail.contacts.isEmpty)
              Text(
                StaffApplicationMessages.localized(
                  context,
                  Ar.staffHistoryEmpty,
                  En.staffHistoryEmpty,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...detail.contacts.map(
                (c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    StaffApplicationMessages.contactTypeLabel(
                      c.contactType,
                      isArabic: isArabic,
                    ),
                  ),
                  subtitle: Text(c.result ?? '—'),
                ),
              ),
            const Divider(),
            Text(
              StaffApplicationMessages.localized(
                context,
                Ar.staffVisitHistory,
                En.staffVisitHistory,
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (detail.visits.isEmpty)
              Text(
                StaffApplicationMessages.localized(
                  context,
                  Ar.staffHistoryEmpty,
                  En.staffHistoryEmpty,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...detail.visits.map(
                (v) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    StaffApplicationMessages.visitStatusLabel(
                      v.status,
                      isArabic: isArabic,
                    ),
                  ),
                  subtitle: Text(v.location ?? '—'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionsPanel extends StatelessWidget {
  const _ActionsPanel({
    required this.detail,
    required this.capabilities,
    required this.isMutating,
  });

  final StaffApplicationDetail detail;
  final StaffApplicationCapabilities capabilities;
  final bool isMutating;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<StaffApplicationDetailProvider>();
    final actions = StaffAction.values.where(
      (a) => provider.isActionAvailable(a, capabilities),
    );

    if (actions.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              StaffApplicationMessages.localized(
                context,
                Ar.staffConfirmAction,
                En.staffConfirmAction,
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map(
                (action) => _ActionButton(
                  action: action,
                  isMutating: isMutating,
                  onPressed: () => _handleAction(context, action),
                ),
              ).toList(),
            ),
            if (isMutating)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, StaffAction action) async {
    final provider = context.read<StaffApplicationDetailProvider>();
    switch (action) {
      case StaffAction.beginReview:
        final confirmed = await _confirm(
          context,
          StaffApplicationMessages.localized(
            context,
            Ar.staffConfirmBeginReview,
            En.staffConfirmBeginReview,
          ),
          confirmLabel: StaffApplicationMessages.localized(
            context,
            Ar.staffActionBeginReview,
            En.staffActionBeginReview,
          ),
        );
        if (confirmed == true) provider.beginReview();
      case StaffAction.approve:
        final confirmed = await _confirm(
          context,
          StaffApplicationMessages.localized(
            context,
            Ar.staffConfirmApprove,
            En.staffConfirmApprove,
          ),
          confirmLabel: StaffApplicationMessages.localized(
            context,
            Ar.staffActionApprove,
            En.staffActionApprove,
          ),
        );
        if (confirmed == true) provider.approve();
      case StaffAction.activate:
        final confirmed = await _confirm(
          context,
          StaffApplicationMessages.localized(
            context,
            Ar.staffConfirmActivate,
            En.staffConfirmActivate,
          ),
          confirmLabel: StaffApplicationMessages.localized(
            context,
            Ar.staffActionActivate,
            En.staffActionActivate,
          ),
        );
        if (confirmed == true) provider.activate();
      case StaffAction.returnForCorrection:
        final reason = await _promptReason(
          context,
          title: StaffApplicationMessages.localized(
            context,
            Ar.staffActionReturnForCorrection,
            En.staffActionReturnForCorrection,
          ),
          label: StaffApplicationMessages.localized(
            context,
            Ar.staffCorrectionReasonLabel,
            En.staffCorrectionReasonLabel,
          ),
          hint: StaffApplicationMessages.localized(
            context,
            Ar.staffCorrectionReasonHint,
            En.staffCorrectionReasonHint,
          ),
          confirmLabel: StaffApplicationMessages.localized(
            context,
            Ar.staffActionReturnForCorrection,
            En.staffActionReturnForCorrection,
          ),
        );
        if (reason != null && reason.isNotEmpty) {
          provider.returnForCorrection(reason);
        }
      case StaffAction.reject:
        final reason = await _promptReason(
          context,
          title: StaffApplicationMessages.localized(
            context,
            Ar.staffActionReject,
            En.staffActionReject,
          ),
          label: StaffApplicationMessages.localized(
            context,
            Ar.staffRejectionReasonLabel,
            En.staffRejectionReasonLabel,
          ),
          hint: StaffApplicationMessages.localized(
            context,
            Ar.staffRejectionReasonHint,
            En.staffRejectionReasonHint,
          ),
          confirmLabel: StaffApplicationMessages.localized(
            context,
            Ar.staffActionReject,
            En.staffActionReject,
          ),
        );
        if (reason != null && reason.isNotEmpty) {
          provider.reject(reason);
        }
      case StaffAction.markContacted:
        final inputs = await _promptContact(context);
        if (inputs != null) {
          provider.markContacted(
            contactType: inputs.contactType,
            result: inputs.result,
            notes: inputs.notes,
          );
        }
      case StaffAction.scheduleVisit:
        final inputs = await _promptVisit(context);
        if (inputs != null) {
          provider.scheduleVisit(
            scheduledAt: inputs.scheduledAt,
            location: inputs.location,
            notes: inputs.notes,
          );
        }
    }
  }

  Future<bool?> _confirm(
    BuildContext context,
    String message, {
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          StaffApplicationMessages.localized(
            context,
            Ar.staffConfirmAction,
            En.staffConfirmAction,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              StaffApplicationMessages.localized(
                context,
                Ar.businessCancel,
                En.businessCancel,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptReason(
    BuildContext context, {
    required String title,
    required String label,
    required String hint,
    required String confirmLabel,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              StaffApplicationMessages.localized(
                context,
                Ar.businessCancel,
                En.businessCancel,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return value?.isNotEmpty == true ? value : null;
  }

  Future<_ContactInputs?> _promptContact(BuildContext context) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    String contactType = 'phone';
    final resultController = TextEditingController();
    final notesController = TextEditingController();
    final value = await showDialog<_ContactInputs>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            StaffApplicationMessages.localized(
              context,
              Ar.staffActionMarkContacted,
              En.staffActionMarkContacted,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: contactType,
                decoration: InputDecoration(
                  labelText: StaffApplicationMessages.localized(
                    context,
                    Ar.staffContactTypeLabel,
                    En.staffContactTypeLabel,
                  ),
                ),
                items: ['phone', 'whatsapp', 'email', 'visit', 'other']
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          StaffApplicationMessages.contactTypeLabel(
                            type,
                            isArabic: isArabic,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => contactType = v);
                },
              ),
              TextField(
                controller: resultController,
                decoration: InputDecoration(
                  labelText: StaffApplicationMessages.localized(
                    context,
                    Ar.staffContactResultLabel,
                    En.staffContactResultLabel,
                  ),
                ),
              ),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: StaffApplicationMessages.localized(
                    context,
                    Ar.staffContactNotesLabel,
                    En.staffContactNotesLabel,
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                StaffApplicationMessages.localized(
                  context,
                  Ar.businessCancel,
                  En.businessCancel,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(_ContactInputs(
                contactType: contactType,
                result: resultController.text.trim().isEmpty
                    ? null
                    : resultController.text.trim(),
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              )),
              child: Text(
                StaffApplicationMessages.localized(
                  context,
                  Ar.staffActionMarkContacted,
                  En.staffActionMarkContacted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return value;
  }

  Future<_VisitInputs?> _promptVisit(BuildContext context) async {
    DateTime? scheduledAt;
    final locationController = TextEditingController();
    final notesController = TextEditingController();
    final value = await showDialog<_VisitInputs>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            StaffApplicationMessages.localized(
              context,
              Ar.staffActionScheduleVisit,
              En.staffActionScheduleVisit,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  scheduledAt == null
                      ? StaffApplicationMessages.localized(
                          context,
                          Ar.staffVisitScheduledAtLabel,
                          En.staffVisitScheduledAtLabel,
                        )
                      : scheduledAt!.toIso8601String(),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      scheduledAt = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
              ),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: StaffApplicationMessages.localized(
                    context,
                    Ar.staffVisitLocationLabel,
                    En.staffVisitLocationLabel,
                  ),
                ),
              ),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: StaffApplicationMessages.localized(
                    context,
                    Ar.staffVisitNotesLabel,
                    En.staffVisitNotesLabel,
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                StaffApplicationMessages.localized(
                  context,
                  Ar.businessCancel,
                  En.businessCancel,
                ),
              ),
            ),
            TextButton(
              onPressed: scheduledAt == null
                  ? null
                  : () => Navigator.of(context).pop(_VisitInputs(
                        scheduledAt: scheduledAt!,
                        location: locationController.text.trim().isEmpty
                            ? null
                            : locationController.text.trim(),
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      )),
              child: Text(
                StaffApplicationMessages.localized(
                  context,
                  Ar.staffActionScheduleVisit,
                  En.staffActionScheduleVisit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return value;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.isMutating,
    required this.onPressed,
  });

  final StaffAction action;
  final bool isMutating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final local = StaffApplicationMessages.localized;
    final label = switch (action) {
      StaffAction.beginReview =>
        local(context, Ar.staffActionBeginReview, En.staffActionBeginReview),
      StaffAction.returnForCorrection => local(
          context,
          Ar.staffActionReturnForCorrection,
          En.staffActionReturnForCorrection,
        ),
      StaffAction.markContacted => local(
          context,
          Ar.staffActionMarkContacted,
          En.staffActionMarkContacted,
        ),
      StaffAction.scheduleVisit => local(
          context,
          Ar.staffActionScheduleVisit,
          En.staffActionScheduleVisit,
        ),
      StaffAction.approve =>
        local(context, Ar.staffActionApprove, En.staffActionApprove),
      StaffAction.reject =>
        local(context, Ar.staffActionReject, En.staffActionReject),
      StaffAction.activate =>
        local(context, Ar.staffActionActivate, En.staffActionActivate),
    };
    return ElevatedButton(
      onPressed: isMutating ? null : onPressed,
      child: Text(label),
    );
  }
}

class _ContactInputs {
  const _ContactInputs({
    required this.contactType,
    this.result,
    this.notes,
  });

  final String contactType;
  final String? result;
  final String? notes;
}

class _VisitInputs {
  const _VisitInputs({
    required this.scheduledAt,
    this.location,
    this.notes,
  });

  final DateTime scheduledAt;
  final String? location;
  final String? notes;
}