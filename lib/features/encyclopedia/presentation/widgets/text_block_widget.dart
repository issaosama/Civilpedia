import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';

class TextBlockWidget extends StatelessWidget {
  final TextBlock block;

  const TextBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return switch (block.variant) {
      TextVariant.paragraph => _paragraph(context),
      TextVariant.note => _variantBox(context, AppColors.info, Icons.info_outline),
      TextVariant.tip => _variantBox(context, AppColors.success, Icons.lightbulb_outline),
      TextVariant.warning => _variantBox(context, AppColors.warning, Icons.warning_amber_rounded),
    };
  }

  Widget _paragraph(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        block.content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
      ),
    );
  }

  Widget _variantBox(BuildContext context, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              block.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color.withValues(alpha: 0.9),
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
