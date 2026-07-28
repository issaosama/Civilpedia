import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../theme/encyclopedia_card_colors.dart';

class SafetyNoteWidget extends StatelessWidget {
  final SafetyNoteBlock block;

  const SafetyNoteWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    if (block.note.message.trim().isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final note = block.note;
    final (Color fg, IconData icon, String severityLabel) = switch (note.severity) {
      SafetySeverity.none => (EncyclopediaCardColors.textSecondary, Icons.info_outline, ''),
      SafetySeverity.low => (const Color(0xFF2E7D32), Icons.check_circle_outline, 'منخفض'),
      SafetySeverity.medium => (EncyclopediaCardColors.warningVariant, Icons.warning_amber_rounded, 'متوسط'),
      SafetySeverity.high => (EncyclopediaCardColors.calloutRejectBorder, Icons.gpp_bad, 'عالي'),
      SafetySeverity.critical => (const Color(0xFFC62828), Icons.dangerous, 'خطير'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: fg.withValues(alpha: isDark ? 0.15 : 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            right: BorderSide(color: fg, width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (severityLabel.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 16, color: fg),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (severityLabel.isNotEmpty) ...[
                    Text(
                      severityLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    note.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
