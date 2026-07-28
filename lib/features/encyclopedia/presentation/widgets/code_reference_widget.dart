import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../theme/encyclopedia_card_colors.dart';

class CodeReferenceWidget extends StatelessWidget {
  final CodeReferenceBlock block;

  const CodeReferenceWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ref = block.reference;
    final headerText = ref.title.isNotEmpty ? ref.title : ref.code;
    final codeStr = ref.code;
    final refs = codeStr.split('/').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final isMulti = refs.length > 1;
    final hasRefs = refs.isNotEmpty;
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.10);

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary,
                    height: 1.5,
                  ),
                ),
                if (ref.section.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'القسم ${ref.section}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasRefs) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: dividerColor),
              const SizedBox(height: 10),
              if (isMulti) ...[
                Text(
                  '🏷 المراجع',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: refs.map((r) => Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? EncyclopediaCardColors.chipDarkBg : EncyclopediaCardColors.chipBg,
                      border: Border.all(color: isDark ? EncyclopediaCardColors.chipDarkBorder : EncyclopediaCardColors.chipBorder),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      r,
                      textDirection: TextDirection.ltr,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? EncyclopediaCardColors.chipDarkText : EncyclopediaCardColors.chipText,
                        height: 1.4,
                      ),
                    ),
                  )).toList(),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: EncyclopediaCardColors.calloutRejectBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    codeStr,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
            if (ref.description != null) ...[
              const SizedBox(height: 16),
              Text(
                ref.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
