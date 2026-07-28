import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../theme/encyclopedia_card_colors.dart';

class EquipmentWidget extends StatelessWidget {
  final EquipmentBlock block;

  const EquipmentWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    if (block.items.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? EncyclopediaCardColors.darkSoftPanel : EncyclopediaCardColors.softPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? EncyclopediaCardColors.darkBorder : EncyclopediaCardColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (block.title != null) ...[
              Row(
                children: [
                  Icon(Icons.precision_manufacturing, size: 18, color: EncyclopediaCardColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    block.title!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            ...block.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 6, color: EncyclopediaCardColors.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (item.purpose != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 2),
                      child: Text(
                        'الغرض: ${item.purpose}',
                        style: TextStyle(fontSize: 13, color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary),
                      ),
                    ),
                  if (item.specification != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 2),
                      child: Text(
                        'المواصفة: ${item.specification}',
                        style: TextStyle(fontSize: 13, color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary),
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
