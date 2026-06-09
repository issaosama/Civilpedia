class ArticleModel {
  final String id;
  final String title;
  final String image;
  final String category;
  final String content;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.image,
    required this.category,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'image': image,
        'category': category,
        'content': content,
      };

  factory ArticleModel.fromJson(Map<String, dynamic> json) => ArticleModel(
        id: json['id'] as String,
        title: json['title'] as String,
        image: json['image'] as String,
        category: json['category'] as String,
        content: json['content'] as String,
      );
}
