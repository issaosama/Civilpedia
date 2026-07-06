import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';

class ChecklistWidget extends StatefulWidget {
  final ChecklistBlock block;

  const ChecklistWidget({super.key, required this.block});

  @override
  State<ChecklistWidget> createState() => _ChecklistWidgetState();
}

class _ChecklistWidgetState extends State<ChecklistWidget> {
  late final Map<String, bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = {
      for (final item in widget.block.items) item.id: false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.block.title != null) ...[
            Row(
              children: [
                Icon(Icons.checklist, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  widget.block.title!,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          ...widget.block.items.map(
            (item) => _buildItem(context, item),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, ChecklistItem item) {
    final checked = _checked[item.id] ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _checked[item.id] = !checked);
            },
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: checked ? AppColors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                border: Border.all(
                  color: checked ? AppColors.success : AppColors.textSecondary,
                  width: checked ? 0 : 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: checked ? TextDecoration.lineThrough : null,
                    color: checked ? AppColors.textSecondary : null,
                    height: 1.5,
                  ),
            ),
          ),
          if (item.isRequired && !checked)
            const Text(
              ' *',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
