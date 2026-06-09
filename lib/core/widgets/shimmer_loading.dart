import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_constants.dart';

class ShimmerArticleCard extends StatelessWidget {
  const ShimmerArticleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.cardRadius)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 120, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 80, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerCategoryCard extends StatelessWidget {
  const ShimmerCategoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 110,
        height: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
      ),
    );
  }
}

class ShimmerSection extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const ShimmerSection({super.key, this.itemCount = 3, this.itemHeight = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const ShimmerArticleCard(),
      ),
    );
  }
}
