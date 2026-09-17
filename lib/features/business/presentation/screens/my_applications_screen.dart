import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
import '../../../../routes/app_routes.dart';
import '../../domain/business_application.dart';
import '../../domain/business_application_type.dart';
import '../../domain/business_remote_read.dart';
import '../providers/business_application_provider.dart';
import '../widgets/business_application_status_chip.dart';
import '../widgets/business_remote_read_notice.dart';
import '../widgets/directory_entity_type_labels.dart';

/// V1-R04 — My Applications list at `/business/applications`.
///
/// Renders the authoritative own-application list, plus the entry points to the
/// NEW ([/business/applications/new]) and CLAIM ([/business/applications/claim])
/// flows. Guests see the sign-in-required state; empty/states are honest.
///
/// V1-R09 P2-D — typed remote-read lanes: no-data failure is a typed read
/// notice, known-good data is preserved with a compact notice, refreshes show a
/// lightweight progress row.
class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BusinessApplicationProvider>().loadApplications();
    });
  }

  void _reload() => context.read<BusinessApplicationProvider>().loadApplications();

  Future<void> _onRefresh() async {
    await context.read<BusinessApplicationProvider>().loadApplications();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessApplicationProvider>();
    final isArabic = context.watch<LanguageProvider?>()?.isArabic ?? true;
    final connectivityIsUnavailable =
        context.watch<ConnectivityProvider?>()?.isUnavailable ?? false;
    String l(String ar, String en) => isArabic ? ar : en;

    Widget body;
    switch (provider.state) {
      case BusinessApplicationState.signInRequired:
        body = _SignInRequired(onSignIn: () {
          context.push(AppRoutes.auth);
        });
      case BusinessApplicationState.loading:
        body = const Center(child: CircularProgressIndicator());
      case BusinessApplicationState.error:
        body = BusinessRemoteReadNotice(
          failure:
              provider.listReadFailure ??
              BusinessRemoteReadFailureKind.unexpected,
          connectivityIsUnavailable: connectivityIsUnavailable,
          mode: RemoteDataNoticeMode.noData,
          onRetry: _reload,
        );
      case BusinessApplicationState.empty:
        final listFailed = provider.listReadPhase ==
                BusinessRemoteReadPhase.failed &&
            provider.listReadFailure != null;
        body = RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const _CreationActions(),
              const SizedBox(height: AppSpacing.xl),
              if (listFailed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BusinessRemoteReadNotice(
                    failure: provider.listReadFailure!,
                    connectivityIsUnavailable: connectivityIsUnavailable,
                    mode: RemoteDataNoticeMode.compact,
                    onRetry: _reload,
                  ),
                ),
              EmptyStateWidget(
                icon: Icons.business_center_outlined,
                message: l(
                  Ar.businessNoApplications,
                  En.businessNoApplications,
                ),
              ),
            ],
          ),
        );
      case BusinessApplicationState.data:
        final listFailed = provider.listReadPhase ==
                BusinessRemoteReadPhase.failed &&
            provider.listReadFailure != null;
        body = RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const _CreationActions(),
              const SizedBox(height: AppSpacing.lg),
              if (provider.listReadPhase ==
                  BusinessRemoteReadPhase.refreshing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (listFailed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BusinessRemoteReadNotice(
                    failure: provider.listReadFailure!,
                    connectivityIsUnavailable: connectivityIsUnavailable,
                    mode: RemoteDataNoticeMode.compact,
                    onRetry: _reload,
                  ),
                ),
              for (final application in provider.applications)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ApplicationCard(
                    application: application,
                    isArabic: isArabic,
                    l: l,
                  ),
                ),
            ],
          ),
        );
    }

    return Scaffold(
      appBar: CivilAppBar(
        title: Text(
          l(Ar.businessApplicationsTitle, En.businessApplicationsTitle),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        showBackButton: true,
      ),
      body: body,
    );
  }
}

class _SignInRequired extends StatelessWidget {
  final VoidCallback onSignIn;

  const _SignInRequired({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = context.watch<LanguageProvider?>()?.isArabic ?? true;
    String l(String ar, String en) => isArabic ? ar : en;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: CivilSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
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
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onSignIn,
                icon: const Icon(Icons.login),
                label: Text(l(Ar.businessSignInButton, En.businessSignInButton)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreationActions extends StatelessWidget {
  const _CreationActions();

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider?>()?.isArabic ?? true;
    String l(String ar, String en) => isArabic ? ar : en;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.businessApplicationsNew),
            icon: const Icon(Icons.add_business_outlined),
            label: Text(l(Ar.businessNewApplication, En.businessNewApplication)),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.businessApplicationsClaim),
            icon: const Icon(Icons.handshake_outlined),
            label: Text(l(Ar.businessTypeClaim, En.businessTypeClaim)),
          ),
        ),
      ],
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final BusinessApplication application;
  final bool isArabic;
  final String Function(String ar, String en) l;

  const _ApplicationCard({
    required this.application,
    required this.isArabic,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rawName = application.metadata?['name'];
    final name = rawName is String ? rawName : null;
    final rawEntityType = application.metadata?['entity_type'];
    final entityType = rawEntityType is String ? rawEntityType : null;
    final label = name ??
        (application.type == BusinessApplicationType.newApplication
            ? l(Ar.businessTypeNew, En.businessTypeNew)
            : l(Ar.businessTypeClaim, En.businessTypeClaim));

    return CivilSurfaceCard(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(
          AppRoutes.businessApplicationDetailFor(application.id),
        );
      },
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              BusinessApplicationStatusChip(status: application.status),
            ],
          ),
          if (entityType != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              DirectoryEntityTypeLabels.labelFor(entityType, isArabic: isArabic),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${l(Ar.businessCreatedOn, En.businessCreatedOn)}: ${_formatDate(application.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Localized-friendly date (no intl dependency in the repo).
String _formatDate(DateTime date) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}