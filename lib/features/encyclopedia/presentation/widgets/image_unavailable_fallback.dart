import 'package:flutter/material.dart';

import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';

class ImageUnavailableFallback extends StatelessWidget {
  final double height;
  final double borderRadius;

  const ImageUnavailableFallback({
    super.key,
    this.height = 140,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        isArabic ? Ar.imageUnavailable : En.imageUnavailable,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
      ),
    );
  }
}