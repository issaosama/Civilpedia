import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../theme/encyclopedia_card_colors.dart';

class ImageBlockWidget extends StatelessWidget {
  final ImageBlock block;

  const ImageBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    if (block.imageUrl.trim().isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              block.imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (_, __, ___) {
                if (kReleaseMode) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'تعذر تحميل الصورة\n${block.imageUrl}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade300 : Colors.grey),
                  ),
                );
              },
            ),
          ),
          if (block.caption != null && block.caption!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  block.caption!,
                  style: TextStyle(fontSize: 12, color: isDark ? EncyclopediaCardColors.darkTextSecondary : EncyclopediaCardColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
