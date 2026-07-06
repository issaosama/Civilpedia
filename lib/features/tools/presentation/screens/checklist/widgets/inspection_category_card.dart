import 'package:flutter/material.dart';
import '../models/inspection_category.dart';
import '../models/inspection_item.dart';
import '../models/inspection_status.dart';
import '../inspection_localization.dart';
import 'inspection_progress_card.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/design_tokens.dart';
import '../../../../../../core/theme/spacing.dart';

class InspectionCategoryCard extends StatelessWidget {
  final InspectionCategory category;
  final List<InspectionItem> items;
  final L10n l10n;
  final VoidCallback onTap;

  const InspectionCategoryCard({
    super.key,
    required this.category,
    required this.items,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final done = items.where((i) => i.status != InspectionStatus.pending).length;
    final progress = items.isEmpty ? 0.0 : done / items.length;
    final allPassed = items.isNotEmpty && items.every((i) => i.status == InspectionStatus.pass);

    return CustomCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: category.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Icon(category.icon, size: 20, color: category.accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n(category.titleKey),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$done / ${items.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 60,
                child: InspectionProgressCard(
                  progress: progress,
                  color: category.accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                allPassed ? Icons.check_circle : Icons.chevron_right,
                size: 20,
                color: allPassed ? AppColors.success : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
