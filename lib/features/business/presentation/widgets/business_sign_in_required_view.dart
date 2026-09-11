import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/civil_surface_card.dart';
import '../../../../localization/ar.dart';
import '../../../../routes/app_routes.dart';

/// V1-R04 — Sign-in-required view for the direct NEW/CLAIM guest routes.
///
/// Guests must never render an actionable business application form or be able
/// to file a local draft. This replaces actionable UI with a clear
/// sign-in-required state for unauthenticated users.
class BusinessSignInRequiredView extends StatelessWidget {
  const BusinessSignInRequiredView({super.key});

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
                onPressed: () => context.push(AppRoutes.auth),
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