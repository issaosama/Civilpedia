import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/marker_style.dart';
import '../theme/encyclopedia_card_colors.dart';

class InspectionPointWidget extends StatelessWidget {
  final InspectionPointBlock block;

  const InspectionPointWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final point = block.point;
    if (point.criteria.trim().isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ms = MarkerStyle.fromInspectionPoint(point);
    final useTheme = point.effectiveMarkerColorMode != 'semantic';
    final markerBg = useTheme ? EncyclopediaCardColors.accent : ms.semanticFgColor(isDark);
    final markerSymbolColor = useTheme ? Colors.white : ms.symbolColor(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: markerBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              ms.symbol,
              style: TextStyle(
                color: markerSymbolColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary, height: 1.6),
                children: [
                  TextSpan(
                    text: point.criteria,
                    style: TextStyle(fontWeight: point.isCritical ? FontWeight.w600 : FontWeight.normal),
                  ),
                  if (point.acceptableTolerance != null && point.acceptableTolerance!.isNotEmpty)
                    TextSpan(
                      text: ' — ${point.acceptableTolerance}',
                      style: TextStyle(color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary),
                    ),
                  if (point.method != null && point.method!.isNotEmpty)
                    TextSpan(
                      text: ' | ${point.method}',
                      style: TextStyle(color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
          if (point.isCritical)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: EncyclopediaCardColors.calloutRejectBorder.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'حرج',
                  style: TextStyle(
                    color: EncyclopediaCardColors.calloutRejectBorder,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
