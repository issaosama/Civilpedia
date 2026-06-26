import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';

class TableBlockWidget extends StatelessWidget {
  final TableBlock block;

  const TableBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final data = block.data;
    if (data.headers.isEmpty || data.rows.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.primary.withValues(alpha: 0.06),
            ),
            headingTextStyle: textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            dataTextStyle: textTheme.bodySmall?.copyWith(height: 1.4),
            columnSpacing: 16,
            horizontalMargin: 10,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 80,
            columns: data.headers
                .map((h) => DataColumn(label: Text(h)))
                .toList(),
            rows: data.rows
                .map(
                  (row) => DataRow(
                    cells: row.cells
                        .map((c) => DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 160),
                                child: Text(c, softWrap: true),
                              ),
                            ))
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
