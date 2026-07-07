import 'localized_text.dart';
import 'accept_reject_item.dart';

enum TopicLevel {
  basic,
  intermediate,
  advanced;

  String toJsonValue() => name;

  static TopicLevel? fromJson(String? value) {
    if (value == null) return null;
    try {
      return TopicLevel.values.byName(value);
    } catch (_) {
      return null;
    }
  }
}

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

  final TopicLevel? level;
  final String? planKey;
  final LocalizedText? simpleExplanation;
  final LocalizedText? beforeWork;
  final LocalizedText? duringWork;
  final LocalizedText? afterWork;
  final List<LocalizedText> commonMistakes;
  final LocalizedText? codeNotes;
  final LocalizedText? siteNotes;
  final LocalizedText? reportWording;
  final String? coverImageUrl;
  final String? visualTheme;
  final List<String> relatedToolRoutes;
  final List<String> relatedChecklistIds;
  final List<AcceptRejectItem> acceptRejectItems;

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
    this.level,
    this.planKey,
    this.simpleExplanation,
    this.beforeWork,
    this.duringWork,
    this.afterWork,
    this.commonMistakes = const [],
    this.codeNotes,
    this.siteNotes,
    this.reportWording,
    this.coverImageUrl,
    this.visualTheme,
    this.relatedToolRoutes = const [],
    this.relatedChecklistIds = const [],
    this.acceptRejectItems = const [],
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
        'level': level?.toJsonValue(),
        'planKey': planKey,
        'simpleExplanation': simpleExplanation?.toJson(),
        'beforeWork': beforeWork?.toJson(),
        'duringWork': duringWork?.toJson(),
        'afterWork': afterWork?.toJson(),
        'commonMistakes': commonMistakes.map((e) => e.toJson()).toList(),
        'codeNotes': codeNotes?.toJson(),
        'siteNotes': siteNotes?.toJson(),
        'reportWording': reportWording?.toJson(),
        'coverImageUrl': coverImageUrl,
        'visualTheme': visualTheme != null ? {'accent': visualTheme} : null,
        'relatedToolRoutes': relatedToolRoutes,
        'relatedChecklistIds': relatedChecklistIds,
        'acceptRejectItems':
            acceptRejectItems.map((e) => e.toJson()).toList(),
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
        level: TopicLevel.fromJson(json['level'] as String?),
        planKey: json['planKey'] as String?,
        simpleExplanation: json['simpleExplanation'] != null
            ? LocalizedText.fromJson(
                json['simpleExplanation'] as Map<String, dynamic>)
            : null,
        beforeWork: json['beforeWork'] != null
            ? LocalizedText.fromJson(json['beforeWork'] as Map<String, dynamic>)
            : null,
        duringWork: json['duringWork'] != null
            ? LocalizedText.fromJson(json['duringWork'] as Map<String, dynamic>)
            : null,
        afterWork: json['afterWork'] != null
            ? LocalizedText.fromJson(json['afterWork'] as Map<String, dynamic>)
            : null,
        commonMistakes: (json['commonMistakes'] as List<dynamic>?)
                ?.map((e) =>
                    LocalizedText.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        codeNotes: json['codeNotes'] != null
            ? LocalizedText.fromJson(json['codeNotes'] as Map<String, dynamic>)
            : null,
        siteNotes: json['siteNotes'] != null
            ? LocalizedText.fromJson(json['siteNotes'] as Map<String, dynamic>)
            : null,
        reportWording: json['reportWording'] != null
            ? LocalizedText.fromJson(
                json['reportWording'] as Map<String, dynamic>)
            : null,
        coverImageUrl: json['coverImageUrl'] as String?,
        visualTheme: (() {
          final vt = json['visual_theme'];
          final accent = vt is Map<String, dynamic> ? vt['accent'] : null;
          return accent is String ? accent : null;
        })(),
        relatedToolRoutes: (json['relatedToolRoutes'] as List<dynamic>?)
                ?.cast<String>() ??
            const [],
        relatedChecklistIds: (json['relatedChecklistIds'] as List<dynamic>?)
                ?.cast<String>() ??
            const [],
        acceptRejectItems: (json['acceptRejectItems'] as List<dynamic>?)
                ?.map((e) =>
                    AcceptRejectItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
