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
    final primaryTextColor = isDark ? EncyclopediaCardColors.darkTextPrimary : EncyclopediaCardColors.textPrimary;
    final detailsColor = isDark ? EncyclopediaCardColors.darkTextMuted : EncyclopediaCardColors.textMuted;
    final acceptance = _trimmed(point.acceptableTolerance);
    final method = _trimmed(point.method);
    final detailsStyle = TextStyle(fontSize: 14, color: detailsColor, height: 1.6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
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
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 14, color: primaryTextColor, height: 1.6),
                    children: [
                      TextSpan(
                        text: point.criteria,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (point.isCritical)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: 4),
                            child: _criticalBadge(),
                          ),
                        ),
                    ],
                  ),
                ),
                if (acceptance != null)
                  Text('القبول: $acceptance', style: detailsStyle),
                if (method != null)
                  Text('الطريقة: $method', style: detailsStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _trimmed(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Widget _criticalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: EncyclopediaCardColors.calloutRejectBorder.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'حرج',
        style: TextStyle(
          color: EncyclopediaCardColors.calloutRejectBorder,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
