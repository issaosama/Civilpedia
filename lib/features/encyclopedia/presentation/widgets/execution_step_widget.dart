import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';

class ExecutionStepWidget extends StatelessWidget {
  final ExecutionStepBlock block;

  const ExecutionStepWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final step = block.step;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
            ),
            alignment: Alignment.center,
            child: Text(
              '${step.stepNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                      ),
                ),
                if (step.notes != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, size: 14, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            step.notes!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.warning.withValues(alpha: 0.8),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
