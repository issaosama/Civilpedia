class EngineeringTopic {
  final String id;
  final String titleAr;
  final String? titleEn;
  final String categoryId;
  final String summary;
  final String? featuredImageUrl;
  final List<String> tags;
  final List<String> relatedTopicIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EngineeringTopic({
    required this.id,
    required this.titleAr,
    this.titleEn,
    required this.categoryId,
    required this.summary,
    this.featuredImageUrl,
    this.tags = const [],
    this.relatedTopicIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleAr': titleAr,
        'titleEn': titleEn,
        'categoryId': categoryId,
        'summary': summary,
        'featuredImageUrl': featuredImageUrl,
        'tags': tags,
        'relatedTopicIds': relatedTopicIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory EngineeringTopic.fromJson(Map<String, dynamic> json) =>
      EngineeringTopic(
        id: json['id'] as String,
        titleAr: json['titleAr'] as String,
        titleEn: json['titleEn'] as String?,
        categoryId: json['categoryId'] as String,
        summary: json['summary'] as String,
        featuredImageUrl: json['featuredImageUrl'] as String?,
        tags: (json['tags'] as List<dynamic>).cast<String>(),
        relatedTopicIds:
            (json['relatedTopicIds'] as List<dynamic>).cast<String>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
