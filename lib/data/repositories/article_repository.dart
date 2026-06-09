import '../../models/article_model.dart';
import '../../models/category_model.dart';
import '../../models/tool_model.dart';
import 'package:flutter/material.dart';

class ArticleRepository {
  static final List<CategoryModel> categories = [
    CategoryModel(
      id: '1',
      name: 'خرسانة',
      icon: Icons.architecture,
      color: const Color(0xFF1565C0),
    ),
    CategoryModel(
      id: '2',
      name: 'حديد',
      icon: Icons.build,
      color: const Color(0xFFE53935),
    ),
    CategoryModel(
      id: '3',
      name: 'تربة',
      icon: Icons.terrain,
      color: const Color(0xFF8D6E63),
    ),
    CategoryModel(
      id: '4',
      name: 'طرق',
      icon: Icons.route,
      color: const Color(0xFF2E7D32),
    ),
    CategoryModel(
      id: '5',
      name: 'إدارة مشاريع',
      icon: Icons.analytics,
      color: const Color(0xFF6A1B9A),
    ),
    CategoryModel(
      id: '6',
      name: 'مساحة',
      icon: Icons.straighten,
      color: const Color(0xFFF57F17),
    ),
  ];

  static final List<ToolModel> tools = [
    ToolModel(
      id: 'concrete',
      name: 'حاسبة الخرسانة',
      description: 'حساب حجم الخرسانة لعناصر متعددة',
      icon: Icons.architecture,
      route: 'calculator/concrete',
    ),
    ToolModel(
      id: 'steel',
      name: 'حاسبة وزن الحديد',
      description: 'حساب وزن أسياخ الحديد',
      icon: Icons.build,
      route: 'calculator/steel',
    ),
    ToolModel(
      id: 'brick',
      name: 'حاسبة الطابوق',
      description: 'تقدير عدد الطابوق',
      icon: Icons.grid_view,
      route: 'calculator/brick',
    ),
    ToolModel(
      id: 'checklist',
      name: 'قائمة التفتيش',
      description: 'قائمة تحقق موقعية',
      icon: Icons.checklist,
      route: 'calculator/checklist',
    ),
  ];

  static final List<ArticleModel> articles = [
    ArticleModel(
      id: '1',
      title: 'أنواع الخرسانة المسلحة',
      image: 'https://images.unsplash.com/photo-1581578731546-c64695cc6942?w=600',
      category: 'خرسانة',
      content:
          'الخرسانة المسلحة هي خرسانة تحتوي على أسياخ حديد تزيد من مقاومتها للشد. '
          'تستخدم في معظم المنشآت الخرسانية مثل الكمرات والأعمدة والأسقف. '
          'هناك عدة أنواع: الخرسانة العادية، الخرسانة المسلحة، الخرسانة سابقة الإجهاد، '
          'والخرسانة عالية المقاومة. تتراوح مقاومة الخرسانة المسلحة بين 20-40 ميجا باسكال '
          'في التطبيقات العادية، ويمكن أن تصل إلى 80 ميجا باسكال في الخرسانة عالية المقاومة.',
    ),
    ArticleModel(
      id: '2',
      title: 'أساسيات تصميم الأساسات',
      image: 'https://images.unsplash.com/photo-1541888946425-d81bb004c622?w=600',
      category: 'خرسانة',
      content:
          'الأساسات هي الجزء السفلي من المنشأ الذي ينقل الأحمال إلى التربة. '
          'تنقسم إلى أساسات سطحية (منفردة، شريطية، لبشة) وأساسات عميقة (ركائز). '
          'يعتمد اختيار نوع الأساس على طبيعة التربة وحجم الأحمال. '
          'يجب أن تجري اختبارات التربة قبل تصميم الأساسات لتحديد قدرة تحمل التربة.',
    ),
    ArticleModel(
      id: '3',
      title: 'أنواع حديد التسليح',
      image: 'https://images.unsplash.com/photo-1614444442667-9e9d9c7a7a9a?w=600',
      category: 'حديد',
      content:
          'حديد التسليح هو العنصر الأساسي في الخرسانة المسلحة. '
          'يوجد بعدة أنواع: حديد أملس (Grade 240) وحديد مشرشر (Grade 360, 420, 520). '
          'أقطار الحديد تبدأ من 6 مم حتى 32 مم. كلما زاد رقم Grade زادت مقاومة الحديد للشد. '
          'يجب تخزين الحديد في مكان جاف ومنع الصدأ باستخدام التغطية المناسبة.',
    ),
    ArticleModel(
      id: '4',
      title: 'اختبارات التربة الأساسية',
      image: 'https://images.unsplash.com/photo-1531834685032-c34bf0d84c77?w=600',
      category: 'تربة',
      content:
          'اختبارات التربة ضرورية قبل بدء أي مشروع إنشائي. '
          'تشمل الاختبارات الأساسية: اختبار الاختراق القياسي (SPT)، '
          'اختبار القص المباشر، اختبار الضغط غير المحصور، واختبار حد أتربيرج. '
          'تساعد هذه الاختبارات في تحديد قدرة تحمل التربة ونوع الأساس المناسب.',
    ),
    ArticleModel(
      id: '5',
      title: 'طبقات الرصف للطرق',
      image: 'https://images.unsplash.com/photo-1574362848149-11496d93a7c7?w=600',
      category: 'طرق',
      content:
          'يتكون الرصف المرن للطرق من عدة طبقات: طبقة الأساس (Sub-base)، '
          'طبقة القاعدة (Base)، طبقة الربط (Binder)، والطبقة السطحية (Wearing Course). '
          'سمك كل طبقة يعتمد على حجم المرور المتوقع ونوع التربة. '
          'الأسفلت الساخن هو المادة الأكثر استخداماً للطبقة السطحية.',
    ),
    ArticleModel(
      id: '6',
      title: 'إدارة الجودة في المشاريع',
      image: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=600',
      category: 'إدارة مشاريع',
      content:
          'إدارة الجودة في المشاريع الهندسية تشمل تخطيط الجودة، ضمان الجودة، '
          'ومراقبة الجودة. تهدف إلى ضمان أن المشروع يلبي المواصفات المطلوبة. '
          'تستخدم أدوات مثل مخططات التدفق، قوائم الفحص، والرسوم البيانية الإحصائية. '
          'ISO 9001 هو المعيار العالمي لإدارة الجودة في المشاريع.',
    ),
    ArticleModel(
      id: '7',
      title: 'المساحة بالمجسات الإلكترونية',
      image: 'https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=600',
      category: 'مساحة',
      content:
          'المجسات الإلكترونية (Total Station) هي أجهزة مساحية متطورة تجمع بين '
          'قياس المسافات والزوايا إلكترونياً. تستخدم في تحديد المواقع بدقة عالية. '
          'يمكن استخدامها في أعمال الرفع المساحي، توقيع المباني، ورصد التشوهات. '
          'دقة القياس تصل إلى 1-2 مم في المسافات القصيرة.',
    ),
    ArticleModel(
      id: '8',
      title: 'مقاومة الخرسانة للضغط',
      image: 'https://images.unsplash.com/photo-1558618666-fcd25c85f82e?w=600',
      category: 'خرسانة',
      content:
          'مقاومة الخرسانة للضغط هي أهم خواصها الميكانيكية. تقاس بعد 7 و 28 يوماً '
          'من الصب باستخدام مكعبات 15×15×15 سم أو أسطوانات 15×30 سم. '
          'الخرسانة العادية مقاومتها 20-30 ميجا باسكال، والخرسانة عالية المقاومة تصل إلى 80 ميجا باسكال. '
          'عوامل تؤثر على المقاومة: نسبة الماء للأسمنت، نوع الركام، وظروف المعالجة.',
    ),
  ];

  List<ArticleModel> getFeaturedArticles() {
    return articles.take(3).toList();
  }

  List<ArticleModel> getLatestArticles() {
    return articles.reversed.take(4).toList();
  }

  List<ArticleModel> getArticlesByCategory(String category) {
    return articles.where((a) => a.category == category).toList();
  }

  ArticleModel? getArticleById(String id) {
    try {
      return articles.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
