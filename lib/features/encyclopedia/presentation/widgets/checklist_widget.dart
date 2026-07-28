import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../theme/encyclopedia_card_colors.dart';

class ChecklistWidget extends StatelessWidget {
  final ChecklistBlock block;

  const ChecklistWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final validItems = block.items.where((i) => i.text.trim().isNotEmpty).toList();
    if (validItems.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? EncyclopediaCardColors.darkBorder : EncyclopediaCardColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (block.title != null && block.title!.trim().isNotEmpty) ...[
              Text(
                block.title!,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary),
              ),
              const SizedBox(height: 10),
            ],
            ...validItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_box_outline_blank, size: 18, color: isDark ? EncyclopediaCardColors.darkTextMuted : EncyclopediaCardColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.text,
                          style: TextStyle(fontSize: 13, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
