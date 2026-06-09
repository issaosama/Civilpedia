import 'package:flutter/material.dart';

class AdBanner {
  final String id;
  final String imageUrl;
  final String? actionUrl;
  final String title;
  final String? subtitle;
  final String? badgeText;
  final Color? badgeColor;

  const AdBanner({
    required this.id,
    required this.imageUrl,
    this.actionUrl,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.badgeColor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'actionUrl': actionUrl,
        'title': title,
        'subtitle': subtitle,
        'badgeText': badgeText,
      };

  factory AdBanner.fromJson(Map<String, dynamic> json) => AdBanner(
        id: json['id'] as String,
        imageUrl: json['imageUrl'] as String,
        actionUrl: json['actionUrl'] as String?,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        badgeText: json['badgeText'] as String?,
      );
}
