import 'package:flutter/material.dart';

enum SectionType {
  execution,
  inspection,
  safety,
  equipment,
  codeReference,
  general;

  String get labelAr {
    return switch (this) {
      SectionType.execution => 'خطوات التنفيذ',
      SectionType.inspection => 'الفحص والتفتيش',
      SectionType.safety => 'إجراءات السلامة',
      SectionType.equipment => 'المعدات والأجهزة',
      SectionType.codeReference => 'المراجع والكودات',
      SectionType.general => 'معلومات عامة',
    };
  }

  Color get accentColor {
    return switch (this) {
      SectionType.execution => const Color(0xFF1565C0),
      SectionType.inspection => const Color(0xFFEF6C00),
      SectionType.safety => const Color(0xFF2E7D32),
      SectionType.equipment => const Color(0xFF6A1B9A),
      SectionType.codeReference => const Color(0xFFC62828),
      SectionType.general => const Color(0xFF455A64),
    };
  }

  IconData get icon {
    return switch (this) {
      SectionType.execution => Icons.construction,
      SectionType.inspection => Icons.search,
      SectionType.safety => Icons.shield,
      SectionType.equipment => Icons.precision_manufacturing,
      SectionType.codeReference => Icons.book,
      SectionType.general => Icons.info_outline,
    };
  }
}

class TopicSection {
  final String id;
  final String title;
  final SectionType type;
  final int order;

  const TopicSection({
    required this.id,
    required this.title,
    required this.type,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'order': order,
      };

  factory TopicSection.fromJson(Map<String, dynamic> json) => TopicSection(
        id: json['id'] as String,
        title: json['title'] as String,
        type: SectionType.values.byName(json['type'] as String),
        order: json['order'] as int,
      );
}
