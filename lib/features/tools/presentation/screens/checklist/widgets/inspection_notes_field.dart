import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/design_tokens.dart';
import '../../../../../../core/theme/spacing.dart';

class InspectionNotesField extends StatefulWidget {
  final String? initialNotes;
  final String hintText;
  final ValueChanged<String> onChanged;

  const InspectionNotesField({
    super.key,
    this.initialNotes,
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<InspectionNotesField> createState() => _InspectionNotesFieldState();
}

class _InspectionNotesFieldState extends State<InspectionNotesField> {
  late final TextEditingController _controller;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasNotes = _controller.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _expanded ? Icons.expand_less : Icons.notes,
                size: 16,
                color: hasNotes ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
              const SizedBox(width: 4),
              Text(
                hasNotes ? _controller.text : widget.hintText,
                style: TextStyle(
                  fontSize: 12,
                  color: hasNotes ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary) : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          AppSpacing.gapSm,
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                borderSide: BorderSide(
                  color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                borderSide: BorderSide(
                  color: (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary).withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            style: const TextStyle(fontSize: 13),
            maxLines: 3,
            minLines: 1,
            onChanged: widget.onChanged,
          ),
        ],
      ],
    );
  }
}
