import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../data/datasources/ad_data_source.dart';
import '../../data/models/ad_banner.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';

class AdCarouselWidget extends StatefulWidget {
  const AdCarouselWidget({super.key, this.dataSource});

  /// Optional [AdDataSource]. When null, the honest production
  /// [LocalAdDataSource] is used (no campaign => no ad => no blank slot).
  /// A [MockAdDataSource] may be injected explicitly for dev/preview/tests.
  final AdDataSource? dataSource;

  @override
  State<AdCarouselWidget> createState() => _AdCarouselWidgetState();
}

class _AdCarouselWidgetState extends State<AdCarouselWidget> {
  late final AdDataSource _dataSource =
      widget.dataSource ?? LocalAdDataSource();
  final _pageController = PageController(viewportFraction: 0.94);

  List<AdBanner> _ads = [];
  bool _isLoading = true;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    final ads = await _dataSource.fetchActiveAds();
    if (!mounted) return;
    setState(() {
      _ads = ads;
      _isLoading = false;
    });
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (_ads.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _ads.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _shimmerPlaceholder();

    // F0.4 (honest ads): no campaign => no ads => render nothing, reserving
    // no vertical gap on Home. Content below flows up into the freed space.
    if (_ads.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _ads.length,
                  itemBuilder: (context, index) {
                    final ad = _ads[index];
                    return _adCard(context, ad);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _indicatorRow(),
        ],
      ),
    );
  }

  Widget _adCard(BuildContext context, AdBanner ad) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: ad.imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.primary.withValues(alpha: 0.08),
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.primary.withValues(alpha: 0.08),
                child: const Icon(Icons.broken_image, size: 40, color: AppColors.textSecondary),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _badge(ad),
            ),
            Positioned(
              bottom: 14,
              left: 14,
              right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (ad.subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      ad.subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (ad.actionUrl != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${tr(Ar.openingAd, En.openingAd)}: ${ad.title}'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(AdBanner ad) {
    if (ad.badgeText == null) return const SizedBox.shrink();
    final color = ad.badgeColor ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        ad.badgeText!,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _indicatorRow() {
    if (_ads.length < 2) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_ads.length, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _shimmerPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
