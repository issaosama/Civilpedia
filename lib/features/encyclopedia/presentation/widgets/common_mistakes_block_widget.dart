import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../theme/encyclopedia_card_colors.dart';

class CommonMistakesBlockWidget extends StatelessWidget {
  final CommonMistakesBlock block;

  const CommonMistakesBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final validItems = block.items.where((i) => i.text.trim().isNotEmpty).toList();
    if (validItems.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = EncyclopediaCardColors.calloutMistakeBorder;
    final titleColor = EncyclopediaCardColors.calloutMistakeLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? borderColor.withValues(alpha: 0.12) : const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            right: BorderSide(color: borderColor, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              block.title ?? 'الأخطاء الشائعة',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: titleColor),
            ),
            const SizedBox(height: 8),
            ...validItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✕', style: TextStyle(fontSize: 12, color: borderColor, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.text,
                      style: TextStyle(fontSize: 14, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.6),
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
