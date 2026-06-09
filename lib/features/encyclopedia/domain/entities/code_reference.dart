class CodeReference {
  final String code;
  final String section;
  final String title;
  final String? description;

  const CodeReference({
    required this.code,
    required this.section,
    required this.title,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'section': section,
        'title': title,
        'description': description,
      };

  factory CodeReference.fromJson(Map<String, dynamic> json) => CodeReference(
        code: json['code'] as String,
        section: json['section'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
      );
}
