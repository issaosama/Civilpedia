import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';

class TableBlockWidget extends StatelessWidget {
  final TableBlock block;

  const TableBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = block.data;
    if (data.headers.isEmpty || data.rows.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final colCount = data.headers.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 24.0;
        const margin = 14.0;
        final minTableWidth = colCount * 130 + (colCount - 1) * spacing + 2 * margin;
        final needsScroll = colCount > 2 && constraints.maxWidth < minTableWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.primary.withValues(alpha: 0.15)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      isDark ? AppColors.darkSurface : AppColors.primary.withValues(alpha: 0.06),
                    ),
                    headingTextStyle: textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    dataTextStyle: textTheme.bodySmall?.copyWith(height: 1.4),
                    columnSpacing: spacing,
                    horizontalMargin: margin,
                    dataRowMinHeight: 36,
                    columns: data.headers.map((h) => DataColumn(label: Text(h))).toList(),
                    rows: data.rows
                        .map(
                          (row) => DataRow(
                            cells: row.cells
                                .map((c) => DataCell(
                                      Text(c, softWrap: true),
                                    ))
                                .toList(),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
            if (needsScroll)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.swipe, size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'اسحب الجدول أفقياً لعرض جميع الأعمدة',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
