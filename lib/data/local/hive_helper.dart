import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../models/article_model.dart';

class HiveHelper {
  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(AppConstants.hiveBoxName);
  }

  static List<String> getFavorites() {
    final data = _box.get(AppConstants.favoritesKey, defaultValue: <String>[]);
    return List<String>.from(data as List);
  }

  static Future<void> toggleFavorite(String articleId) async {
    final favorites = getFavorites();
    if (favorites.contains(articleId)) {
      favorites.remove(articleId);
    } else {
      favorites.add(articleId);
    }
    await _box.put(AppConstants.favoritesKey, favorites);
  }

  static bool isFavorite(String articleId) {
    return getFavorites().contains(articleId);
  }

  static List<String> getDownloads() {
    final data = _box.get(AppConstants.downloadsKey, defaultValue: <String>[]);
    return List<String>.from(data as List);
  }

  static Future<void> toggleDownload(String articleId, [ArticleModel? article]) async {
    final downloads = getDownloads();
    if (downloads.contains(articleId)) {
      downloads.remove(articleId);
      await _box.delete('offline_$articleId');
    } else {
      downloads.add(articleId);
      if (article != null) {
        await _box.put('offline_$articleId', article.toJson());
      }
    }
    await _box.put(AppConstants.downloadsKey, downloads);
  }

  static bool isDownloaded(String articleId) {
    return getDownloads().contains(articleId);
  }

  static ArticleModel? getOfflineArticle(String articleId) {
    final data = _box.get('offline_$articleId');
    if (data == null) return null;
    return ArticleModel.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
