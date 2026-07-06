import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../data/repositories/article_repository.dart';

class QuickToolsSection extends StatelessWidget {
  const QuickToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = ArticleRepository.tools;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final tool = tools[index];
          return Material(
            borderRadius: BorderRadius.circular(16),
            elevation: isDark ? 0 : 1,
            color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/${tool.route}'),
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusIcon),
                      ),
                      child: Icon(tool.icon, size: 24, color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tool.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.mainText,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
