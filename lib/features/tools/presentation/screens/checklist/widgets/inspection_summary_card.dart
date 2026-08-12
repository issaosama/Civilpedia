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
  final String naLabel;
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
    required this.naLabel,
    required this.criticalLabel,
    required this.requiredLabel,
    required this.totalItemsLabel,
    required this.resetLabel,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                '${summary.inspected} / ${summary.totalItems}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          InspectionProgressCard(progress: summary.progressPercent),
          AppSpacing.gapSm,
          Row(
            children: [
              Expanded(child: _stat(AppColors.success, passLabel, '${summary.passed}', isDark: isDark)),
              Expanded(child: _stat(AppColors.error, failLabel, '${summary.failed}', isDark: isDark)),
              Expanded(child: _stat(isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, naLabel, '${summary.na}', isDark: isDark)),
              Expanded(child: _stat(isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, pendingLabel, '${summary.pending}', isDark: isDark)),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(child: _stat(AppColors.error, criticalLabel, '${summary.criticalPassed}/${summary.criticalTotal}', isDark: isDark)),
              Expanded(child: _stat(AppColors.warning, requiredLabel, '${summary.requiredPassed}/${summary.requiredTotal}', isDark: isDark)),
              Expanded(child: _stat(isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, totalItemsLabel, '${summary.totalItems}', isDark: isDark)),
            ],
          ),
          AppSpacing.gapSm,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onReset,
              icon: Icon(Icons.refresh, size: 16, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              label: Text(
                resetLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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

  Widget _stat(Color color, String label, String value, {required bool isDark}) {
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
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
