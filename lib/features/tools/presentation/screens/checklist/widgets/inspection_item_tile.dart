import 'package:flutter/material.dart';
import '../models/inspection_item.dart';
import '../models/inspection_status.dart';
import '../inspection_localization.dart';
import 'inspection_status_chip.dart';
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
  final String criticalLabel;
  final String requiredLabel;
  final String notesHint;
  final String codeRefLabel;
  final ValueChanged<InspectionStatus> onStatusChanged;
  final ValueChanged<String> onNotesChanged;

  const InspectionItemTile({
    super.key,
    required this.item,
    required this.l10n,
    required this.passLabel,
    required this.failLabel,
    required this.pendingLabel,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          onTap: () {
            final next = switch (item.status) {
              InspectionStatus.pending => InspectionStatus.pass,
              InspectionStatus.pass => InspectionStatus.fail,
              InspectionStatus.fail => InspectionStatus.pending,
            };
            onStatusChanged(next);
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statusIndicator(item.status),
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
                    const SizedBox(width: AppSpacing.sm),
                    InspectionStatusChip(
                      status: item.status,
                      passLabel: passLabel,
                      failLabel: failLabel,
                      pendingLabel: pendingLabel,
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
                InspectionNotesField(
                  initialNotes: item.notes,
                  hintText: notesHint,
                  onChanged: onNotesChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusIndicator(InspectionStatus status) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (status) {
          InspectionStatus.pass => AppColors.success,
          InspectionStatus.fail => AppColors.error,
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
