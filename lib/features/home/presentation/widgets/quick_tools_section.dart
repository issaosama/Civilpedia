import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/civil_surface_card.dart';
import '../../../../localization/en.dart';
import '../../data/home_content_source.dart';
import 'home_preview_layout.dart';

/// Adaptive Home preview of the existing engineering-tool registry.
///
/// Every item remains a launcher to its dedicated route; no calculator logic
/// or inputs are embedded on Home.
class QuickToolsSection extends StatelessWidget {
  const QuickToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = const HomeContentSource().tools.take(4);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gutter = width < 600
            ? 16.0
            : width < 840
            ? 24.0
            : 32.0;
        final columns = homePreviewColumns(context, width);
        const gap = 8.0;
        final cardWidth =
            (width - (gutter * 2) - (gap * (columns - 1))) / columns;

        return Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final tool in tools)
                SizedBox(
                  width: cardWidth,
                  child: _ToolCard(
                    name: isArabic ? tool.name : _englishToolName(tool.id),
                    description: isArabic
                        ? switch (tool.id) {
                            'concrete' => 'حجم الخرسانة',
                            'steel' => 'وزن الأسياخ',
                            'brick' => 'عدد الطابوق',
                            _ => 'تحقق موقعي',
                          }
                        : switch (tool.id) {
                            'concrete' => 'Concrete volume',
                            'steel' => 'Bar weight',
                            'brick' => 'Brick quantity',
                            _ => 'Site checks',
                          },
                    icon: tool.icon,
                    route: tool.route,
                    useAmber: tool.id == 'checklist',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _englishToolName(String id) {
    return switch (id) {
      'concrete' => En.concreteCalc,
      'steel' => En.steelWeightCalc,
      'brick' => En.brickCalc,
      'tile' => En.tileCalc,
      'checklist' => En.checklistItem,
      _ => En.tools,
    };
  }
}

class _ToolCard extends StatelessWidget {
  final String name;
  final String description;
  final IconData icon;
  final String route;
  final bool useAmber;

  const _ToolCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.route,
    required this.useAmber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = useAmber
        ? (isDark ? AppColors.darkBrandAmber : AppColors.brandAmberPressed)
        : (isDark ? AppColors.darkBrandBlue : AppColors.brandBlue);
    final iconSurface = useAmber
        ? (isDark ? AppColors.darkWarningSoft : AppColors.brandAmberSoft)
        : (isDark ? AppColors.darkInfoSoft : AppColors.brandBlueSoft);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 104),
      child: CivilSurfaceCard(
        hasBorder: true,
        padding: EdgeInsets.zero,
        onTap: () => context.push('/$route'),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
