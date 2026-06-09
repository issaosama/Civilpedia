import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../../../../core/theme/design_tokens.dart';

class SafetyNoteWidget extends StatelessWidget {
  final SafetyNoteBlock block;

  const SafetyNoteWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final note = block.note;
    final (Color bg, Color fg, IconData icon) = switch (note.severity) {
      SafetySeverity.low => (const Color(0xFFE8F5E9), const Color(0xFF2E7D32), Icons.check_circle_outline),
      SafetySeverity.medium => (const Color(0xFFFFF3E0), const Color(0xFFEF6C00), Icons.warning_amber_rounded),
      SafetySeverity.high => (const Color(0xFFFFEBEE), const Color(0xFFC62828), Icons.gpp_bad),
      SafetySeverity.critical => (const Color(0xFF4A0000), const Color(0xFFFF1744), Icons.dangerous),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note.message,
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: note.severity == SafetySeverity.critical
                    ? FontWeight.bold
                    : FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
