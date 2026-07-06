import 'package:flutter/material.dart';
import 'models/inspection_category.dart';
import 'models/inspection_item.dart';
import 'models/inspection_status.dart';
import 'inspection_localization.dart';
import 'widgets/inspection_item_tile.dart';
import '../../../../../core/widgets/custom_card.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/spacing.dart';

class ChecklistCategoryDetailScreen extends StatefulWidget {
  final InspectionCategory category;
  final List<InspectionItem> items;
  final L10n l10n;
  final String passLabel;
  final String failLabel;
  final String pendingLabel;
  final String criticalLabel;
  final String requiredLabel;
  final String notesHint;
  final String codeRefLabel;
  final ValueChanged<String> onItemStatusChanged;
  final void Function(String itemId, String notes) onItemNotesChanged;

  const ChecklistCategoryDetailScreen({
    super.key,
    required this.category,
    required this.items,
    required this.l10n,
    required this.passLabel,
    required this.failLabel,
    required this.pendingLabel,
    required this.criticalLabel,
    required this.requiredLabel,
    required this.notesHint,
    required this.codeRefLabel,
    required this.onItemStatusChanged,
    required this.onItemNotesChanged,
  });

  @override
  State<ChecklistCategoryDetailScreen> createState() =>
      _ChecklistCategoryDetailScreenState();
}

class _ChecklistCategoryDetailScreenState
    extends State<ChecklistCategoryDetailScreen> {
  void _onItemStatusChanged(String itemId) {
    widget.onItemStatusChanged(itemId);
    setState(() {});
  }

  void _onItemNotesChanged(String itemId, String notes) {
    widget.onItemNotesChanged(itemId, notes);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = widget.items;
    final done = items.where((i) => i.status != InspectionStatus.pending).length;
    final progress = items.isEmpty ? 0.0 : done / items.length;
    final allPassed = items.isNotEmpty && items.every((i) => i.status == InspectionStatus.pass);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.l10n(widget.category.titleKey)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CustomCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.category.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: Icon(
                    widget.category.icon,
                    size: 20,
                    color: widget.category.accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$done / ${items.length}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (allPassed) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: AppColors.success,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.category.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InspectionItemTile(
                item: item,
                l10n: widget.l10n,
                passLabel: widget.passLabel,
                failLabel: widget.failLabel,
                pendingLabel: widget.pendingLabel,
                criticalLabel: widget.criticalLabel,
                requiredLabel: widget.requiredLabel,
                notesHint: widget.notesHint,
                codeRefLabel: widget.codeRefLabel,
                onStatusChanged: (_) => _onItemStatusChanged(item.id),
                onNotesChanged: (notes) => _onItemNotesChanged(item.id, notes),
              ),
            );
          }),
        ],
      ),
    );
  }
}
