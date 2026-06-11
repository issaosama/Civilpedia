import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../core/theme/design_tokens.dart';
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Ar.tools,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Top introductory header banner
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(Ar.engineeringTools, En.engineeringTools),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(Ar.toolsDescription, En.toolsDescription),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tools Grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              16,
              24,
              16,
              100,
            ), // extra bottom padding for floating bar
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.95,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final tool = tools[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/${tool.route}'),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surface
                            : Colors.white,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMd,
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          width: 1,
                        ),
                        boxShadow: DesignTokens.softShadow(theme.shadowColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Icon container
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              tool.icon,
                              size: 28,
                              color: theme.primaryColor,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tool.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tool.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
