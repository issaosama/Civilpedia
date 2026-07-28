import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../theme/encyclopedia_card_colors.dart';

class RejectionCriteriaBlockWidget extends StatelessWidget {
  final RejectionCriteriaBlock block;

  const RejectionCriteriaBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final validItems = block.items.where((i) => i.text.trim().isNotEmpty).toList();
    if (validItems.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? EncyclopediaCardColors.darkCalloutRejectBg : EncyclopediaCardColors.calloutRejectBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: EncyclopediaCardColors.calloutRejectBorder.withValues(alpha: isDark ? 0.35 : 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⛔', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  block.title ?? 'معايير الرفض',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EncyclopediaCardColors.calloutRejectLabel),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...validItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⛔', style: TextStyle(fontSize: 14, color: EncyclopediaCardColors.calloutRejectBorder)),
                  const SizedBox(width: 10),
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
