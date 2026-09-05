import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import '../theme/encyclopedia_card_colors.dart';
import 'image_unavailable_fallback.dart';

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
              errorBuilder: (_, __, ___) =>
                  const ImageUnavailableFallback(),
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
