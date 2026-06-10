import 'package:flutter/material.dart';
import '../models/inspection_summary.dart';
import 'inspection_progress_card.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../../../../../core/theme/app_colors.dart';

import '../../../../../../core/theme/spacing.dart';

class InspectionSummaryCard extends StatelessWidget {
  final InspectionSummary summary;
  final bool isArabic;
  final String title;
  final String passLabel;
  final String failLabel;
  final String pendingLabel;
  final String criticalLabel;
  final String requiredLabel;
  final String totalItemsLabel;
  final String resetLabel;
  final VoidCallback onReset;

  const InspectionSummaryCard({
    super.key,
    required this.summary,
    required this.isArabic,
    required this.title,
    required this.passLabel,
    required this.failLabel,
    required this.pendingLabel,
    required this.criticalLabel,
    required this.requiredLabel,
    required this.totalItemsLabel,
    required this.resetLabel,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rtl, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${summary.passed + summary.failed} / ${summary.totalItems}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          InspectionProgressCard(progress: summary.progressPercent),
          AppSpacing.gapSm,
          Row(
            children: [
              _stat(Colors.green, passLabel, '${summary.passed}'),
              const SizedBox(width: 16),
              _stat(AppColors.error, failLabel, '${summary.failed}'),
              const SizedBox(width: 16),
              _stat(AppColors.textSecondary, pendingLabel, '${summary.pending}'),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _stat(AppColors.error, criticalLabel, '${summary.criticalPassed}/${summary.criticalTotal}'),
              const SizedBox(width: 16),
              _stat(AppColors.warning, requiredLabel, '${summary.requiredPassed}/${summary.requiredTotal}'),
              const Spacer(),
              _stat(AppColors.textSecondary, totalItemsLabel, '${summary.totalItems}'),
            ],
          ),
          AppSpacing.gapSm,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.textSecondary),
              label: Text(
                resetLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(Color color, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
