import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/connectivity_provider.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/civil_app_bar.dart';
import '../../../../core/widgets/civil_surface_card.dart';
import '../../../../core/widgets/remote_data_notice.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';
import '../../domain/business_application.dart';
import '../../domain/business_application_capabilities.dart';
import '../../domain/business_application_capability_resolver.dart';
import '../../domain/business_application_gateway.dart';
import '../../domain/business_application_type.dart';
import '../../domain/business_remote_read.dart';
import '../providers/business_application_provider.dart';
import '../widgets/business_application_status_chip.dart';
import '../widgets/business_remote_read_notice.dart';
import '../widgets/directory_entity_type_labels.dart';

/// V1-R04 — Application detail at `/business/applications/:id`.
///
/// Displays the authoritative application snapshot, status chip, metadata for
/// NEW apps, a target reference for CLAIM apps, the return reason when the
/// status is NEEDS_CORRECTION, and the valid next action for the CURRENT
/// status only (submit / resubmit / none).
///
/// V1-R09 P2-D — typed detail read lanes: authoritative absence is a neutral
/// controlled state, failures are typed read notices, known-good data is
/// preserved with a compact notice.
class ApplicationDetailScreen extends StatefulWidget {
  final String applicationId;

  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context
            .read<BusinessApplicationProvider>()
            .loadApplication(widget.applicationId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessApplicationProvider>();
    final isArabic = context.watch<LanguageProvider?>()?.isArabic ?? true;
    final connectivityIsUnavailable =
        context.watch<ConnectivityProvider?>()?.isUnavailable ?? false;
    String l(String ar, String en) => isArabic ? ar : en;

    return Scaffold(
      appBar: CivilAppBar(
        title: Text(
          l(Ar.businessApplicationsTitle, En.businessApplicationsTitle),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        showBackButton: true,
      ),
      body: _DetailBody(
        state: provider.state,
        error: provider.error,
        application: provider.current,
        provider: provider,
        isArabic: isArabic,
        connectivityIsUnavailable: connectivityIsUnavailable,
        l: l,
        onRetry: () =>
            context.read<BusinessApplicationProvider>().loadApplication(
                  widget.applicationId,
                ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final BusinessApplicationState state;
  final String? error;
  final BusinessApplication? application;
  final BusinessApplicationProvider provider;
  final bool isArabic;
  final bool connectivityIsUnavailable;
  final String Function(String ar, String en) l;
  final VoidCallback onRetry;

  const _DetailBody({
    required this.state,
    required this.application,
    required this.provider,
    required this.isArabic,
    required this.connectivityIsUnavailable,
    required this.l,
    required this.onRetry,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case BusinessApplicationState.signInRequired:
        return _SignInRequired(isArabic: isArabic, l: l);
      case BusinessApplicationState.loading:
        return const Center(child: CircularProgressIndicator());
      case BusinessApplicationState.error:
        return BusinessRemoteReadNotice(
          failure:
              provider.detailReadFailure ??
              BusinessRemoteReadFailureKind.unexpected,
          connectivityIsUnavailable: connectivityIsUnavailable,
          mode: RemoteDataNoticeMode.noData,
          onRetry: onRetry,
        );
      case BusinessApplicationState.empty:
        // Authoritative absence within the current actor's scope: a neutral
        // controlled state. No retry offered for the not-found case, and no
        // mutation/redirect is ever triggered.
        return _MessageState(
          icon: Icons.search_off_outlined,
          message: l(
            Ar.businessCauseApplicationNotFound,
            En.businessCauseApplicationNotFound,
          ),
        );
      case BusinessApplicationState.data:
        final app = application;
        if (app == null) {
          return const SizedBox.shrink();
        }
        final detailFailed = provider.detailReadPhase ==
                BusinessRemoteReadPhase.failed &&
            provider.detailReadFailure != null;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (provider.detailReadPhase ==
                BusinessRemoteReadPhase.refreshing)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (detailFailed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BusinessRemoteReadNotice(
                  failure: provider.detailReadFailure!,
                  connectivityIsUnavailable: connectivityIsUnavailable,
                  mode: RemoteDataNoticeMode.compact,
                  onRetry: onRetry,
                ),
              ),
            _ApplicationContent(
              application: app,
              provider: provider,
              isArabic: isArabic,
              l: l,
            ),
          ],
        );
    }
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInRequired extends StatelessWidget {
  final bool isArabic;
  final String Function(String ar, String en) l;

  const _SignInRequired({required this.isArabic, required this.l});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: CivilSurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 56,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l(Ar.businessSignInRequired, En.businessSignInRequired),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationContent extends StatelessWidget {
  final BusinessApplication application;
  final BusinessApplicationProvider provider;
  final bool isArabic;
  final String Function(String ar, String en) l;

  const _ApplicationContent({
    required this.application,
    required this.provider,
    required this.isArabic,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final caps = BusinessApplicationCapabilityResolver.capabilitiesFor(application);
    final rawName = application.metadata?['name'];
    final name = rawName is String ? rawName : null;
    final rawEntityType = application.metadata?['entity_type'];
    final entityType = rawEntityType is String ? rawEntityType : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status chip (enlarged)
        Center(child: BusinessApplicationStatusChip(status: application.status, enlarged: true)),
        const SizedBox(height: AppSpacing.xl),

        // Application type card
        CivilSurfaceCard(
          hasBorder: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: l(Ar.businessTypeNew, En.businessTypeNew),
                value: application.type == BusinessApplicationType.newApplication
                    ? l(Ar.businessTypeNew, En.businessTypeNew)
                    : l(Ar.businessTypeClaim, En.businessTypeClaim),
                isDark: isDark,
              ),
              _InfoRow(
                label: l(Ar.businessCreatedOn, En.businessCreatedOn),
                value: _formatDate(application.createdAt),
                isDark: isDark,
              ),
              _InfoRow(
                label: l(Ar.businessUpdatedAt, En.businessUpdatedAt),
                value: _formatDate(application.updatedAt),
                isDark: isDark,
              ),
              if (application.reviewedAt != null)
                _InfoRow(
                  label: l(Ar.businessReviewedAt, En.businessReviewedAt),
                  value: _formatDate(application.reviewedAt!),
                  isDark: isDark,
                ),
              if (application.approvedAt != null)
                _InfoRow(
                  label: l(Ar.businessApprovedAt, En.businessApprovedAt),
                  value: _formatDate(application.approvedAt!),
                  isDark: isDark,
                ),
              if (application.activatedAt != null)
                _InfoRow(
                  label: l(Ar.businessActivatedAt, En.businessActivatedAt),
                  value: _formatDate(application.activatedAt!),
                  isDark: isDark,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Metadata (NEW) or Target (CLAIM)
        if (name != null || entityType != null) ...[
          CivilSurfaceCard(
            hasBorder: true,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name != null) ...[
                  Text(l(Ar.businessMetadata, En.businessMetadata), style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(name),
                  if (entityType != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${l(Ar.businessEntityTypeLabel, En.businessEntityTypeLabel)}: ${DirectoryEntityTypeLabels.labelFor(entityType, isArabic: isArabic)}',
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Return reason when NEEDS_CORRECTION
        if (caps.requiresCorrection && application.returnReason != null) ...[
          CivilSurfaceCard(
            warm: true,
            hasBorder: true,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l(Ar.businessReturnReasonTitle, En.businessReturnReasonTitle),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  application.returnReason!,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l(Ar.businessCorrectionNotice, En.businessCorrectionNotice),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Rejection reason when REJECTED
        if (caps.isRejected && application.rejectionReason != null) ...[
          CivilSurfaceCard(
            warm: true,
            hasBorder: true,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l(Ar.businessRejectionReason, En.businessRejectionReason),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  application.rejectionReason!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // APPROVED: approval complete, activation pending
        if (caps.isApproved) ...[
          CivilSurfaceCard(
            hasBorder: true,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(l(Ar.businessApprovedNote, En.businessApprovedNote)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ACTIVATED: activation successful
        if (caps.isActivated) ...[
          CivilSurfaceCard(
            hasBorder: true,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
            child: Row(
              children: [
                Icon(Icons.verified_outlined,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(l(Ar.businessActivatedNote, En.businessActivatedNote)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Actions for valid states only
        if (caps.isDraft || caps.requiresCorrection) ...[
          _ActionSection(caps: caps, application: application, provider: provider),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ActionSection extends StatefulWidget {
  final BusinessApplicationCapabilities caps;
  final BusinessApplication application;
  final BusinessApplicationProvider provider;

  const _ActionSection({
    required this.caps,
    required this.application,
    required this.provider,
  });

  @override
  State<_ActionSection> createState() => _ActionSectionState();
}

class _ActionSectionState extends State<_ActionSection> {
  Future<void> _confirmAndExecute({
    required Future<BusinessApplicationSubmitResult?> Function() action,
    required String title,
    required String message,
  }) async {
    if (widget.provider.isBusy) return;
    final isArabic = context.read<LanguageProvider?>()?.isArabic ?? true;
    String l(String ar, String en) => isArabic ? ar : en;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l(Ar.businessCancel, En.businessCancel)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isArabic ? Ar.businessSubmitConfirm : En.businessSubmitConfirm,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await action();
    if (!mounted) return;
    _handleResult(result);
  }

  void _handleResult(BusinessApplicationSubmitResult? result) {
    if (result == null) return;
    if (result is BusinessApplicationSubmitDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(BusinessApplicationCauseMessages.messageForSubmit(result.cause)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    // On BusinessApplicationSubmitted the provider rebuilds with the
    // authoritative returned application — no additional SnackBar needed.
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider?>()?.isArabic ?? true;
    String l(String ar, String en) => isArabic ? ar : en;
    final label = widget.caps.canResubmit
        ? l(Ar.businessResubmit, En.businessResubmit)
        : widget.caps.canSubmit
            ? l(Ar.businessSubmit, En.businessSubmit)
            : '';
    if (label.isEmpty) return const SizedBox.shrink();

    return CivilSurfaceCard(
      hasBorder: true,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.provider.isBusy
              ? null
              : () => _confirmAndExecute(
                    action: () async {
                      if (widget.caps.canResubmit) {
                        return widget.provider.resubmit(widget.application);
                      } else if (widget.caps.canSubmit) {
                        return widget.provider.submit(widget.application);
                      }
                      return null;
                    },
                    title: widget.caps.canResubmit
                        ? l(Ar.businessResubmit, En.businessResubmit)
                        : l(Ar.businessSubmitConfirm, En.businessSubmitConfirm),
                    message: widget.caps.canResubmit
                        ? l(Ar.businessResubmitPending, En.businessResubmitPending)
                        : l(Ar.businessSubmitPending, En.businessSubmitPending),
                  ),
          child: Text(label),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}