import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/civil_app_bar.dart';
import '../../../../core/widgets/civil_surface_card.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../localization/ar.dart';
import '../../domain/business_application_gateway.dart';
import '../../domain/business_claim_target.dart';
import '../providers/business_application_provider.dart';
import '../providers/business_claim_target_provider.dart';
import '../widgets/business_claim_verification_labels.dart';
import '../widgets/business_sign_in_required_view.dart';
import '../widgets/directory_entity_type_labels.dart';

/// V1-R04 — CLAIM application selector at `/business/applications/claim`.
///
/// Presents only the currently claimable active targets (claim_status =
/// 'unclaimed') from the authoritative PostgREST read seam. Selecting a target
/// files a CLAIM draft using the canonical `directory_entities.id` via
/// `createClaimDraft` — NEVER a local `ServiceBusinessProfile.id`.
class ApplicationClaimFormScreen extends StatefulWidget {
  const ApplicationClaimFormScreen({super.key});

  @override
  State<ApplicationClaimFormScreen> createState() =>
      _ApplicationClaimFormScreenState();
}

class _ApplicationClaimFormScreenState extends State<ApplicationClaimFormScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<BusinessApplicationProvider>();
      if (!mounted || !appProvider.isAuthenticated) return;
      context.read<BusinessClaimTargetProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessClaimTargetProvider>();
    final appProvider = context.watch<BusinessApplicationProvider>();

    return Scaffold(
      appBar: CivilAppBar(
        title: const Text(Ar.businessClaimApplicationTitle),
        showBackButton: true,
      ),
      body: appProvider.isAuthenticated
          ? _ClaimBody(
              state: provider.state,
              targets: provider.targets,
              error: provider.error,
              onRetry: () =>
                  context.read<BusinessClaimTargetProvider>().reload(),
              appProvider: appProvider,
            )
          : const BusinessSignInRequiredView(),
    );
  }
}

class _ClaimBody extends StatelessWidget {
  final BusinessClaimTargetState state;
  final List<BusinessClaimTarget> targets;
  final String? error;
  final VoidCallback onRetry;
  final BusinessApplicationProvider appProvider;

  const _ClaimBody({
    required this.state,
    required this.targets,
    required this.appProvider,
    required this.onRetry,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case BusinessClaimTargetState.loading:
        return const Center(child: CircularProgressIndicator());
      case BusinessClaimTargetState.error:
        return ErrorStateWidget(
          message: error ?? Ar.businessClaimTargetsError,
          onRetry: onRetry,
        );
      case BusinessClaimTargetState.empty:
        return _EmptyClaimState(onRefresh: onRetry);
      case BusinessClaimTargetState.data:
        return _TargetList(targets: targets, appProvider: appProvider);
    }
  }
}

class _EmptyClaimState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyClaimState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const EmptyStateWidget(
            icon: Icons.business_center_outlined,
            message: Ar.businessClaimTargetsEmpty,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text(Ar.businessRefresh),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetList extends StatefulWidget {
  final List<BusinessClaimTarget> targets;
  final BusinessApplicationProvider appProvider;

  const _TargetList({required this.targets, required this.appProvider});

  @override
  State<_TargetList> createState() => _TargetListState();
}

class _TargetListState extends State<_TargetList> {
  String _query = '';

  List<BusinessClaimTarget> get _filtered {
    if (_query.isEmpty) return widget.targets;
    final q = _query.toLowerCase();
    return widget.targets.where((t) {
      return t.name.toLowerCase().contains(q) ||
          t.entityType.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  Future<void> _onClaim(BusinessClaimTarget target) async {
    if (widget.appProvider.isBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(Ar.businessClaimTarget),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(target.name),
            const SizedBox(height: 8),
            Text(
              DirectoryEntityTypeLabels.labelFor(
                target.entityType,
                isArabic: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(Ar.businessCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(Ar.businessClaimTarget),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await widget.appProvider.createClaimDraft(
      // V1-R04 §6: target.id is the canonical directory_entities.id —
      // NEVER a local service-business profile id.
      targetEntityId: target.id,
    );
    if (!mounted) return;
    if (result is BusinessApplicationCreated) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    if (result is BusinessApplicationCreateDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            BusinessApplicationCauseMessages.messageFor(result.cause),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = true;
    final filtered = _filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: Ar.directorySearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<BusinessClaimTargetProvider>().reload(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final target = filtered[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: CivilSurfaceCard(
                    onTap: () => _onClaim(target),
                    hasBorder: true,
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          target.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          DirectoryEntityTypeLabels.labelFor(
                            target.entityType,
                            isArabic: isArabic,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (target.verificationStatus != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${Ar.businessVerificationStatus}: '
                            '${BusinessClaimVerificationLabels.labelFor(target.verificationStatus)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}