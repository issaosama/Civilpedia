import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../theme/encyclopedia_card_colors.dart';

class TextBlockWidget extends StatelessWidget {
  final TextBlock block;

  const TextBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final text = block.content.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    if (block.variant == TextVariant.paragraph) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.7,
              ),
        ),
      );
    }
    return _buildVariantCard(context, text);
  }

  Widget _buildVariantCard(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (Color color, IconData icon, String label) = switch (block.variant) {
      TextVariant.note => (EncyclopediaCardColors.noteVariant, Icons.info_outline, 'ملاحظة'),
      TextVariant.tip => (EncyclopediaCardColors.tipVariant, Icons.lightbulb_outline, 'نصيحة'),
      TextVariant.warning => (EncyclopediaCardColors.warningVariant, Icons.warning_amber_rounded, 'تنبيه'),
      _ => (EncyclopediaCardColors.noteVariant, Icons.info_outline, 'ملاحظة'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      color: color.withValues(alpha: isDark ? 1.0 : 0.9),
                      height: 1.7,
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
