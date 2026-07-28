class CategoryInfo {
  final String id;
  final String titleAr;
  final String titleEn;

  const CategoryInfo({
    required this.id,
    required this.titleAr,
    required this.titleEn,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final title = json['title'] as Map<String, dynamic>?;
    return CategoryInfo(
      id: id,
      titleAr: title?['ar'] as String? ?? id,
      titleEn: title?['en'] as String? ?? id,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': {'ar': titleAr, 'en': titleEn},
  };
}
