import 'package:flutter/material.dart';
import '../../domain/entities/topic_section.dart';
import '../../../../core/theme/design_tokens.dart';

class SectionHeaderWidget extends StatelessWidget {
  final TopicSection section;

  const SectionHeaderWidget({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final accent = section.type.accentColor;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Icon(section.type.icon, size: 22, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: accent,
                  ),
            ),
          ),
          if (section.type == SectionType.codeReference)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
              ),
              child: Text(
                section.type.labelAr,
                style: TextStyle(
                  fontSize: 11,
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
