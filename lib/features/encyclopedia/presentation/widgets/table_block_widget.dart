import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../theme/encyclopedia_card_colors.dart';

class TableBlockWidget extends StatelessWidget {
  final TableBlock block;

  const TableBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = block.data;
    if (data.rows.isEmpty) return const SizedBox.shrink();
    final colCount = data.headers.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.caption != null && data.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                data.caption!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 24.0;
              const margin = 14.0;
              final minTableWidth = colCount * 130 + (colCount - 1) * spacing + 2 * margin;
              final needsScroll = colCount > 2 && constraints.maxWidth < minTableWidth;

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? EncyclopediaCardColors.darkBorder : EncyclopediaCardColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(isDark ? EncyclopediaCardColors.darkTableHeaderBg : EncyclopediaCardColors.tableHeaderBg),
                        headingTextStyle: TextStyle(
                          color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        dataTextStyle: TextStyle(
                          color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        columnSpacing: spacing,
                        horizontalMargin: margin,
                        dataRowMinHeight: 36,
                        columns: data.headers.map((h) => DataColumn(label: Text(h))).toList(),
                        rows: data.rows
                            .map((row) => DataRow(
                                  cells: row.cells
                                      .map((c) => DataCell(
                                            Text(c, softWrap: true),
                                          ))
                                      .toList(),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  if (needsScroll)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(Icons.swipe, size: 14, color: isDark ? EncyclopediaCardColors.darkTextMuted : EncyclopediaCardColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'اسحب الجدول أفقياً لعرض جميع الأعمدة',
                            style: TextStyle(fontSize: 12, color: isDark ? EncyclopediaCardColors.darkTextMuted : EncyclopediaCardColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
