import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/civil_app_bar.dart';
import '../../../../core/widgets/civil_surface_card.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../localization/ar.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/business_application.dart';
import '../../domain/business_application_type.dart';
import '../providers/business_application_provider.dart';
import '../widgets/business_application_status_chip.dart';
import '../widgets/directory_entity_type_labels.dart';

/// V1-R04 — My Applications list at `/business/applications`.
///
/// Renders the authoritative own-application list, plus the entry points to the
/// NEW ([/business/applications/new]) and CLAIM ([/business/applications/claim])
/// flows. Guests see the sign-in-required state; empty/states are honest.
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

    Widget body;
    switch (provider.state) {
      case BusinessApplicationState.signInRequired:
        body = _SignInRequired(onSignIn: () {
          context.push(AppRoutes.auth);
        });
      case BusinessApplicationState.loading:
        body = const Center(child: CircularProgressIndicator());
      case BusinessApplicationState.error:
        body = ErrorStateWidget(
          message: Ar.businessApplicationsError,
          onRetry: _reload,
        );
      case BusinessApplicationState.empty:
        body = RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: const [
              _CreationActions(),
              SizedBox(height: AppSpacing.xl),
              EmptyStateWidget(
                icon: Icons.business_center_outlined,
                message: Ar.businessNoApplications,
              ),
            ],
          ),
        );
      case BusinessApplicationState.data:
        body = _ApplicationList(
          applications: provider.applications,
          onRefresh: _onRefresh,
        );
    }

    return Scaffold(
      appBar: CivilAppBar(
        title: const Text(
          Ar.businessApplicationsTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
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
                Ar.businessSignInRequired,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onSignIn,
                icon: const Icon(Icons.login),
                label: const Text(Ar.businessSignInButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationList extends StatelessWidget {
  final List<BusinessApplication> applications;
  final Future<void> Function() onRefresh;

  const _ApplicationList({
    required this.applications,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const _CreationActions(),
          const SizedBox(height: AppSpacing.lg),
          for (final application in applications)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ApplicationCard(application: application),
            ),
        ],
      ),
    );
  }
}

class _CreationActions extends StatelessWidget {
  const _CreationActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.businessApplicationsNew),
            icon: const Icon(Icons.add_business_outlined),
            label: const Text(Ar.businessNewApplication),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.businessApplicationsClaim),
            icon: const Icon(Icons.handshake_outlined),
            label: const Text(Ar.businessTypeClaim),
          ),
        ),
      ],
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final BusinessApplication application;

  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isArabic = true;
    final rawName = application.metadata?['name'];
    final name = rawName is String ? rawName : null;
    final rawEntityType = application.metadata?['entity_type'];
    final entityType = rawEntityType is String ? rawEntityType : null;
    final label = name ??
        (application.type == BusinessApplicationType.newApplication
            ? Ar.businessTypeNew
            : Ar.businessTypeClaim);

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
            '${Ar.businessCreatedOn}: ${_formatDate(application.createdAt)}',
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