import 'package:flutter/material.dart';
import '../models/inspection_item.dart';
import '../models/inspection_status.dart';
import '../inspection_localization.dart';
import 'inspection_badge.dart';
import 'inspection_notes_field.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/design_tokens.dart';
import '../../../../../../core/theme/spacing.dart';

class InspectionItemTile extends StatelessWidget {
  final InspectionItem item;
  final L10n l10n;
  final String passLabel;
  final String failLabel;
  final String pendingLabel;
  final String naLabel;
  final String criticalLabel;
  final String requiredLabel;
  final String notesHint;
  final String codeRefLabel;
  final void Function(InspectionStatus status) onStatusChanged;
  final ValueChanged<String> onNotesChanged;

  const InspectionItemTile({
    super.key,
    required this.item,
    required this.l10n,
    required this.passLabel,
    required this.failLabel,
    required this.pendingLabel,
    required this.naLabel,
    required this.criticalLabel,
    required this.requiredLabel,
    required this.notesHint,
    required this.codeRefLabel,
    required this.onStatusChanged,
    required this.onNotesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(
          color: item.isCritical
              ? AppColors.error.withValues(alpha: 0.15)
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusDot(item.status),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n(item.titleKey),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          decoration: item.status == InspectionStatus.pass
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.status == InspectionStatus.pass
                              ? AppColors.textSecondary
                              : null,
                        ),
                      ),
                      if (item.codeRef != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$codeRefLabel: ${item.codeRef}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (item.descriptionKey != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          l10n(item.descriptionKey!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (item.isCritical || item.isRequired) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (item.isCritical)
                    InspectionBadge.critical(criticalLabel),
                  if (item.isRequired)
                    InspectionBadge.required(requiredLabel),
                ],
              ),
            ],
            const SizedBox(height: 6),
            // Status chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildStatusChip(InspectionStatus.pass, AppColors.success, passLabel),
                _buildStatusChip(InspectionStatus.fail, AppColors.error, failLabel),
                _buildStatusChip(InspectionStatus.na, AppColors.textSecondary, naLabel),
                _buildStatusChip(InspectionStatus.pending, AppColors.textSecondary, pendingLabel),
              ],
            ),
            const SizedBox(height: 6),
            InspectionNotesField(
              initialNotes: item.notes,
              hintText: notesHint,
              onChanged: onNotesChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(InspectionStatus status, Color color, String label) {
    final selected = item.status == status;
    return ChoiceChip(
      label: Text(label, style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : color,
      )),
      selected: selected,
      onSelected: (_) => onStatusChanged(status),
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.08),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  Widget _statusDot(InspectionStatus status) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (status) {
          InspectionStatus.pass => AppColors.success,
          InspectionStatus.fail => AppColors.error,
          InspectionStatus.na => AppColors.textSecondary.withValues(alpha: 0.4),
          InspectionStatus.pending => AppColors.textSecondary.withValues(alpha: 0.3),
        },
      ),
    );
  }

  Color get _backgroundColor {
    if (item.status == InspectionStatus.pass) {
      return AppColors.success.withValues(alpha: 0.03);
    }
    if (item.status == InspectionStatus.fail) {
      return AppColors.error.withValues(alpha: 0.03);
    }
    return Colors.transparent;
  }
}
