import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/civil_app_bar.dart';
import '../../../../core/widgets/civil_surface_card.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../localization/ar.dart';
import '../../domain/business_application.dart';
import '../../domain/business_application_capabilities.dart';
import '../../domain/business_application_capability_resolver.dart';
import '../../domain/business_application_gateway.dart';
import '../../domain/business_application_type.dart';
import '../providers/business_application_provider.dart';
import '../widgets/business_application_status_chip.dart';
import '../widgets/directory_entity_type_labels.dart';

/// V1-R04 — Application detail at `/business/applications/:id`.
///
/// Displays the authoritative application snapshot, status chip, metadata for
/// NEW apps, a target reference for CLAIM apps, the return reason when the
/// status is NEEDS_CORRECTION, and the valid next action for the CURRENT
/// status only (submit / resubmit / none).
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
    final app = provider.current;

    return Scaffold(
      appBar: CivilAppBar(
        title: const Text(
          Ar.businessApplicationsTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        showBackButton: true,
      ),
      body: _DetailBody(
        state: provider.state,
        error: provider.error,
        application: app,
        provider: provider,
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
  final VoidCallback onRetry;

  const _DetailBody({
    required this.state,
    required this.application,
    required this.provider,
    required this.onRetry,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case BusinessApplicationState.signInRequired:
        return const _SignInRequired();
      case BusinessApplicationState.loading:
        return const Center(child: CircularProgressIndicator());
      case BusinessApplicationState.error:
        return ErrorStateWidget(
          message: error ?? Ar.businessApplicationsError,
          onRetry: onRetry,
        );
      case BusinessApplicationState.empty:
        return ErrorStateWidget(
          message: Ar.businessCauseApplicationNotFound,
          onRetry: null,
        );
      case BusinessApplicationState.data:
        final app = application;
        if (app == null) {
          return const SizedBox.shrink();
        }
        return _ApplicationContent(
          application: app,
          provider: provider,
        );
    }
  }
}

class _SignInRequired extends StatelessWidget {
  const _SignInRequired();

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
                Ar.businessSignInRequired,
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

  const _ApplicationContent({
    required this.application,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = true;
    final caps = BusinessApplicationCapabilityResolver.capabilitiesFor(application);
    final rawName = application.metadata?['name'];
    final name = rawName is String ? rawName : null;
    final rawEntityType = application.metadata?['entity_type'];
    final entityType = rawEntityType is String ? rawEntityType : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                label: Ar.businessTypeNew,
                value: application.type == BusinessApplicationType.newApplication
                    ? Ar.businessTypeNew
                    : Ar.businessTypeClaim,
                isDark: isDark,
              ),
              _InfoRow(
                label: Ar.businessCreatedOn,
                value: _formatDate(application.createdAt),
                isDark: isDark,
              ),
              _InfoRow(
                label: Ar.businessUpdatedAt,
                value: _formatDate(application.updatedAt),
                isDark: isDark,
              ),
              if (application.reviewedAt != null)
                _InfoRow(
                  label: Ar.businessReviewedAt,
                  value: _formatDate(application.reviewedAt!),
                  isDark: isDark,
                ),
              if (application.approvedAt != null)
                _InfoRow(
                  label: Ar.businessApprovedAt,
                  value: _formatDate(application.approvedAt!),
                  isDark: isDark,
                ),
              if (application.activatedAt != null)
                _InfoRow(
                  label: Ar.businessActivatedAt,
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
                  Text(Ar.businessMetadata, style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(name),
                  if (entityType != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${Ar.businessEntityTypeLabel}: ${DirectoryEntityTypeLabels.labelFor(entityType, isArabic: isArabic)}',
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
                  Ar.businessReturnReasonTitle,
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
                  Ar.businessCorrectionNotice,
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
                  Ar.businessRejectionReason,
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
                  child: Text(Ar.businessApprovedNote),
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
                  child: Text(Ar.businessActivatedNote),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(Ar.businessCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(Ar.businessSubmitConfirm),
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
    final label = widget.caps.canResubmit
        ? Ar.businessResubmit
        : widget.caps.canSubmit
            ? Ar.businessSubmit
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
                        ? Ar.businessResubmit
                        : Ar.businessSubmitConfirm,
                    message: widget.caps.canResubmit
                        ? Ar.businessResubmitPending
                        : Ar.businessSubmitPending,
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