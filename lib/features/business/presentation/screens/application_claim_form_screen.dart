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
import '../../domain/business_application_gateway.dart';
import '../../domain/business_claim_target.dart';
import '../../domain/business_remote_read.dart';
import '../providers/business_application_provider.dart';
import '../providers/business_claim_target_provider.dart';
import '../widgets/business_claim_verification_labels.dart';
import '../widgets/business_remote_read_notice.dart';
import '../widgets/business_sign_in_required_view.dart';
import '../widgets/directory_entity_type_labels.dart';

/// V1-R04 — CLAIM application selector at `/business/applications/claim`.
///
/// Presents only the currently claimable active targets (claim_status =
/// 'unclaimed') from the authoritative PostgREST read seam. Selecting a target
/// files a CLAIM draft using the canonical `directory_entities.id` via
/// `createClaimDraft` — NEVER a local `ServiceBusinessProfile.id`.
///
/// V1-R09 P2-D — typed claim read lanes: no-data failure is a typed read
/// notice, known-good targets are preserved with a compact notice.
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
    final isArabic = context.watch<LanguageProvider?>()?.isArabic ?? true;
    final connectivityIsUnavailable =
        context.watch<ConnectivityProvider?>()?.isUnavailable ?? false;
    String l(String ar, String en) => isArabic ? ar : en;

    return Scaffold(
      appBar: CivilAppBar(
        title: Text(l(Ar.businessClaimApplicationTitle, En.businessClaimApplicationTitle)),
        showBackButton: true,
      ),
      body: appProvider.isAuthenticated
          ? _ClaimBody(
              state: provider.state,
              targets: provider.targets,
              readFailure: provider.readFailure,
              isRefreshing: provider.isRefreshing,
              connectivityIsUnavailable: connectivityIsUnavailable,
              isArabic: isArabic,
              l: l,
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
  final BusinessRemoteReadFailureKind? readFailure;
  final bool isRefreshing;
  final bool connectivityIsUnavailable;
  final bool isArabic;
  final String Function(String ar, String en) l;
  final VoidCallback onRetry;
  final BusinessApplicationProvider appProvider;

  const _ClaimBody({
    required this.state,
    required this.targets,
    required this.readFailure,
    required this.isRefreshing,
    required this.connectivityIsUnavailable,
    required this.isArabic,
    required this.l,
    required this.onRetry,
    required this.appProvider,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case BusinessClaimTargetState.loading:
        return const Center(child: CircularProgressIndicator());
      case BusinessClaimTargetState.error:
        return BusinessRemoteReadNotice(
          failure: readFailure ?? BusinessRemoteReadFailureKind.unexpected,
          connectivityIsUnavailable: connectivityIsUnavailable,
          mode: RemoteDataNoticeMode.noData,
          onRetry: onRetry,
        );
      case BusinessClaimTargetState.empty:
        final failed = readFailure != null;
        return Column(
          children: [
            if (failed)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: BusinessRemoteReadNotice(
                  failure: readFailure!,
                  connectivityIsUnavailable: connectivityIsUnavailable,
                  mode: RemoteDataNoticeMode.compact,
                  onRetry: onRetry,
                ),
              ),
            Expanded(
              child: _EmptyClaimState(
                onRefresh: onRetry,
                isArabic: isArabic,
                l: l,
              ),
            ),
          ],
        );
      case BusinessClaimTargetState.data:
        return Column(
          children: [
            if (isRefreshing)
              const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (readFailure != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: BusinessRemoteReadNotice(
                  failure: readFailure!,
                  connectivityIsUnavailable: connectivityIsUnavailable,
                  mode: RemoteDataNoticeMode.compact,
                  onRetry: onRetry,
                ),
              ),
            Expanded(
              child: _TargetList(
                targets: targets,
                appProvider: appProvider,
                isArabic: isArabic,
                l: l,
              ),
            ),
          ],
        );
    }
  }
}

class _EmptyClaimState extends StatelessWidget {
  final VoidCallback onRefresh;
  final bool isArabic;
  final String Function(String ar, String en) l;

  const _EmptyClaimState({
    required this.onRefresh,
    required this.isArabic,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          EmptyStateWidget(
            icon: Icons.business_center_outlined,
            message: l(Ar.businessClaimTargetsEmpty, En.businessClaimTargetsEmpty),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(l(Ar.businessRefresh, En.businessRefresh)),
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
  final bool isArabic;
  final String Function(String ar, String en) l;

  const _TargetList({
    required this.targets,
    required this.appProvider,
    required this.isArabic,
    required this.l,
  });

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
    final isArabic = widget.isArabic;
    String l(String ar, String en) => isArabic ? ar : en;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l(Ar.businessClaimTarget, En.businessClaimTarget)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(target.name),
            const SizedBox(height: 8),
            Text(
              DirectoryEntityTypeLabels.labelFor(
                target.entityType,
                isArabic: isArabic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l(Ar.businessCancel, En.businessCancel)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l(Ar.businessClaimTarget, En.businessClaimTarget)),
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
    final isArabic = widget.isArabic;
    String l(String ar, String en) => isArabic ? ar : en;
    final filtered = _filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            decoration: InputDecoration(
              hintText: l(Ar.directorySearchHint, En.directorySearchHint),
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
                            '${l(Ar.businessVerificationStatus, En.businessVerificationStatus)}: '
                            '${BusinessClaimVerificationLabels.labelFor(target.verificationStatus, isArabic: isArabic)}',
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