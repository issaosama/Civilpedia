import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';

class CodeReferenceWidget extends StatelessWidget {
  final CodeReferenceBlock block;

  const CodeReferenceWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final ref = block.reference;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFC62828).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(
          color: const Color(0xFFC62828).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                ),
                child: Text(
                  ref.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                ),
                child: Text(
                  'القسم ${ref.section}',
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ref.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
          ),
          if (ref.description != null) ...[
            const SizedBox(height: 4),
            Text(
              ref.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
