import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../theme/encyclopedia_card_colors.dart';

class ExecutionStepWidget extends StatelessWidget {
  final ExecutionStepBlock block;

  const ExecutionStepWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = block.step;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: EncyclopediaCardColors.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '${step.stepNumber}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
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
                  style: TextStyle(fontSize: 14, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.6),
                ),
                if (step.notes != null && step.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    step.notes!,
                    style: TextStyle(fontSize: 12, color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary, height: 1.5),
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
