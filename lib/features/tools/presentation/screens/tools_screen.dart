import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../core/navigation/shell_content_insets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/civil_app_bar.dart';
import '../../../../core/widgets/civil_surface_card.dart';
import '../../../../data/repositories/article_repository.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    final tools = ArticleRepository.tools;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CivilAppBar(
        title: Text(Ar.tools),
        showBackButton: false,
      ),
      body: CustomScrollView(
        slivers: [
          // Lightweight intro surface explaining the Tools area.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: CivilSurfaceCard(
                warm: true,
                padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusIcon,
                            ),
                          ),
                          child: const Icon(
                            Icons.architecture,
                            size: 22,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            tr(Ar.engineeringTools, En.engineeringTools),
                            textAlign: TextAlign.start,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      tr(Ar.toolsDescription, En.toolsDescription),
                      textAlign: TextAlign.start,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tools grid
          SliverPadding(
            padding: EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              shellSafeBottomPadding(context),
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.95,
                crossAxisSpacing: AppSpacing.lg,
                mainAxisSpacing: AppSpacing.lg,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final tool = tools[index];
                return CivilSurfaceCard(
                  onTap: () => context.push('/${tool.route}'),
                  padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusIcon,
                          ),
                        ),
                        child: Icon(
                          tool.icon,
                          size: 24,
                          color: AppColors.primary,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tool.name,
                            textAlign: TextAlign.start,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            tool.description,
                            textAlign: TextAlign.start,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }, childCount: tools.length),
            ),
          ),
        ],
      ),
    );
  }
}
