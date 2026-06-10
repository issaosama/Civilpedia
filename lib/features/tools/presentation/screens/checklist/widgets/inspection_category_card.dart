import 'package:flutter/material.dart';
import '../models/inspection_category.dart';
import '../models/inspection_item.dart';
import '../models/inspection_status.dart';
import '../inspection_localization.dart';
import 'inspection_item_tile.dart';
import 'inspection_progress_card.dart';
import '../../../../../../core/widgets/custom_card.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/design_tokens.dart';
import '../../../../../../core/theme/spacing.dart';

class InspectionCategoryCard extends StatelessWidget {
  final InspectionCategory category;
  final List<InspectionItem> items;
  final bool isExpanded;
  final L10n l10n;
  final String passLabel;
  final String failLabel;
  final String pendingLabel;
  final String criticalLabel;
  final String requiredLabel;
  final String notesHint;
  final String codeRefLabel;
  final VoidCallback onToggle;
  final ValueChanged<String> onItemStatusChanged;
  final void Function(String itemId, String notes) onItemNotesChanged;

  const InspectionCategoryCard({
    super.key,
    required this.category,
    required this.items,
    required this.isExpanded,
    required this.l10n,
    required this.passLabel,
    required this.failLabel,
    required this.pendingLabel,
    required this.criticalLabel,
    required this.requiredLabel,
    required this.notesHint,
    required this.codeRefLabel,
    required this.onToggle,
    required this.onItemStatusChanged,
    required this.onItemNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = items.where((i) => i.status != InspectionStatus.pending).length;
    final progress = items.isEmpty ? 0.0 : done / items.length;

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: InspectionProgressCard(
                          progress: progress,
                          color: category.accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: DesignTokens.durationFast,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                children: items.map((item) {
                  return InspectionItemTile(
                    item: item,
                    l10n: l10n,
                    passLabel: passLabel,
                    failLabel: failLabel,
                    pendingLabel: pendingLabel,
                    criticalLabel: criticalLabel,
                    requiredLabel: requiredLabel,
                    notesHint: notesHint,
                    codeRefLabel: codeRefLabel,
                    onStatusChanged: (_) => onItemStatusChanged(item.id),
                    onNotesChanged: (notes) => onItemNotesChanged(item.id, notes),
                  );
                }).toList(),
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: DesignTokens.durationNormal,
          ),
        ],
      ),
    );
  }
}
