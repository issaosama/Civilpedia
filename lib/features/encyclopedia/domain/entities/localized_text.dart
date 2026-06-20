class LocalizedText {
  final String ar;
  final String en;

  const LocalizedText({required this.ar, required this.en});

  Map<String, dynamic> toJson() => {'ar': ar, 'en': en};

  factory LocalizedText.fromJson(Map<String, dynamic> json) => LocalizedText(
        ar: json['ar'] as String,
        en: json['en'] as String,
      );
}
