import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../data/home_content_source.dart';

/// Reference-style compact tool rail for Home.
///
/// Uses the real tool registry exposed through the Home read-facing boundary
/// ([HomeContentSource.tools]) and preserves all calculator/checklist
/// navigation contracts. Only presentation is adjusted to match the approved
/// Home reference layout.
class QuickToolsSection extends StatelessWidget {
  const QuickToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = const HomeContentSource().tools;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const horizontalPadding = AppConstants.paddingMedium;
    const gap = 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
        final cardWidth = (availableWidth - (gap * 3)) / 4;

        return SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            itemCount: tools.length,
            separatorBuilder: (_, __) => const SizedBox(width: gap),
            itemBuilder: (context, index) {
              final tool = tools[index];
              return _ToolCard(
                width: cardWidth,
                tool: tool,
                isDark: isDark,
              );
            },
          ),
        );
      },
    );
  }
}

class _ToolCard extends StatelessWidget {
  final double width;
  final dynamic tool;
  final bool isDark;

  const _ToolCard({
    required this.width,
    required this.tool,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        onTap: () => context.push('/${tool.route}'),
          child: Container(
          width: width,
          height: 108,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
            boxShadow: isDark ? null : DesignTokens.cardShadow(AppColors.cardShadow),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusIcon),
                ),
                child: Icon(tool.icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
                Text(
                  tool.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.mainText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  tool.description,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
