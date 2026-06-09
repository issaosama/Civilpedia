import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/content_block.dart';
import '../../../../core/theme/design_tokens.dart';

class ImageBlockWidget extends StatelessWidget {
  final ImageBlock block;

  const ImageBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CachedNetworkImage(
              imageUrl: block.imageUrl,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 200,
                color: Colors.grey.shade100,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 200,
                color: Colors.grey.shade100,
                child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
              ),
            ),
            if (block.caption != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade50,
                child: Text(
                  block.caption!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
