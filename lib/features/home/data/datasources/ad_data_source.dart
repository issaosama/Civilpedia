import 'package:flutter/material.dart';
import '../models/ad_banner.dart';

abstract class AdDataSource {
  Future<List<AdBanner>> fetchActiveAds();
}

/// Production / default advertisement source.
///
/// F0.4 (honest ads): there is no real/current campaign source in production,
/// so this returns an EMPTY result. An ad exists only when a campaign supplies
/// one (W7 Monetization). Honest contract: no campaign => no ad => no blank slot.
///
/// This source NEVER auto-consumes mock ads.
class LocalAdDataSource implements AdDataSource {
  @override
  Future<List<AdBanner>> fetchActiveAds() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const [];
  }
}

/// Explicit DEVELOPMENT / PREVIEW / TEST ad source.
///
/// Provides sample [AdBanner]s so the existing ad carousel can still be
/// visually reviewed before a real campaign exists. This is an EXPLICIT
/// fixture only — it must never be the default production data contract.
class MockAdDataSource implements AdDataSource {
  @override
  Future<List<AdBanner>> fetchActiveAds() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockAds;
  }
}

const Color _gold = Color(0xFFFFD700);
const Color _bronze = Color(0xFFCD7F32);
const Color _steel = Color(0xFF4682B4);
const Color _indigo = Color(0xFF4B0082);

final List<AdBanner> _mockAds = [
  AdBanner(
    id: 'ad-1',
    imageUrl: 'https://images.unsplash.com/photo-1581578731546-c64695cc6942?w=800&q=80',
    actionUrl: 'https://example.com/concrete',
    title: 'خرسانة جاهزة',
    subtitle: 'أفضل خلطات الخرسانة الجاهزة لمشاريعك',
    badgeText: 'عرض خاص',
    badgeColor: _gold,
  ),
  AdBanner(
    id: 'ad-2',
    imageUrl: 'https://images.unsplash.com/photo-1614444442667-9e9d9c7a7a9a?w=800&q=80',
    actionUrl: 'https://example.com/steel',
    title: 'حديد تسليح عالي الجودة',
    subtitle: 'مقاومة عالية للشد تناسب جميع التصاميم',
    badgeText: 'مضمون',
    badgeColor: _steel,
  ),
  AdBanner(
    id: 'ad-3',
    imageUrl: 'https://images.unsplash.com/photo-1504917595217-d4dc5ebe6122?w=800&q=80',
    actionUrl: 'https://example.com/survey',
    title: 'أجهزة مساحة حديثة',
    subtitle: 'محطات رقمية متكاملة بدقة عالية',
    badgeText: 'جديد',
    badgeColor: _bronze,
  ),
  AdBanner(
    id: 'ad-4',
    imageUrl: 'https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=800&q=80',
    actionUrl: 'https://example.com/software',
    title: 'برامج إدارة المشاريع',
    subtitle: 'حلول متكاملة لإدارة المشاريع الهندسية',
    badgeText: 'خصم ٢٠٪',
    badgeColor: _indigo,
  ),
];
