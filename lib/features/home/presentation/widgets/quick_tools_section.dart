import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/repositories/article_repository.dart';

class QuickToolsSection extends StatelessWidget {
  const QuickToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = ArticleRepository.tools;
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
            elevation: 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/${tool.route}'),
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(tool.icon, size: 24, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tool.name,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
