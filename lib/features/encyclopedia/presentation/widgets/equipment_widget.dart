import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/content_block.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';

class EquipmentWidget extends StatelessWidget {
  final EquipmentBlock block;

  const EquipmentWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = context.watch<LanguageProvider>().isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF6A1B9A).withValues(alpha: 0.12) : const Color(0xFF6A1B9A).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(
          color: const Color(0xFF6A1B9A).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (block.title != null) ...[
            Row(
              children: [
                Icon(Icons.precision_manufacturing,
                    size: 20, color: const Color(0xFF6A1B9A)),
                const SizedBox(width: 8),
                Text(
                  block.title!,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF6A1B9A),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          ...block.items.map((item) => _itemCard(context, item, tr, isDark: isDark)),
        ],
      ),
    );
  }

  Widget _itemCard(BuildContext context, EquipmentItem item, String Function(String ar, String en) tr, {bool isDark = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 6, color: const Color(0xFF6A1B9A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          if (item.purpose != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                '${tr(Ar.equipmentPurpose, En.equipmentPurpose)}: ${item.purpose}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
              ),
            ),
          ],
          if (item.specification != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                '${tr(Ar.equipmentSpecification, En.equipmentSpecification)}: ${item.specification}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
