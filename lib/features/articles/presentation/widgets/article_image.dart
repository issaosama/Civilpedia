import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';

/// A small, reusable article image that loads a remote/cached image and falls
/// back to a clean local placeholder when the image is unavailable.
///
/// Never shows broken-image icons, raw errors, or blank areas.
/// Empty or whitespace-only URLs render the fallback immediately without
/// attempting a network request.
class ArticleImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ArticleImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkSurface : AppColors.surface;
    final iconColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final trimmedUrl = imageUrl.trim();
    if (trimmedUrl.isEmpty) {
      return _fallback(backgroundColor, iconColor);
    }

    return CachedNetworkImage(
      imageUrl: trimmedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: backgroundColor,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: iconColor,
          ),
        ),
      ),
      errorWidget: (_, __, ___) => _fallback(backgroundColor, iconColor),
    );
  }

  Widget _fallback(Color backgroundColor, Color iconColor) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Center(
        child: Icon(
          Icons.article_outlined,
          color: iconColor,
          size: _fallbackIconSize,
        ),
      ),
    );
  }

  double get _fallbackIconSize {
    final dimensions = <double>[
      if (width != null && width != double.infinity) width!,
      if (height != null && height != double.infinity) height!,
    ];
    if (dimensions.isEmpty) return 32;
    final smallest = dimensions.reduce((a, b) => a < b ? a : b);
    return (smallest * 0.35).clamp(16.0, 48.0);
  }
}
