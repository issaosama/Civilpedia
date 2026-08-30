import 'package:hive_flutter/hive_flutter.dart';
import '../../core/storage/app_storage_keys.dart';
import '../../models/article_model.dart';

class HiveHelper {
  static late Box _box;

  static Future<void> init({String? boxName, String? path}) async {
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }
    _box = await Hive.openBox(boxName ?? AppStorageKeys.hiveBoxName);
  }

  static List<String> _asStringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return <String>[];
  }

  static List<String> getFavorites() {
    return _asStringList(_box.get(AppStorageKeys.favorites));
  }

  static Future<void> toggleFavorite(String articleId) async {
    final favorites = getFavorites();
    if (favorites.contains(articleId)) {
      favorites.remove(articleId);
    } else {
      favorites.add(articleId);
    }
    await _box.put(AppStorageKeys.favorites, favorites);
  }

  static bool isFavorite(String articleId) {
    return getFavorites().contains(articleId);
  }

  static List<String> getEncyclopediaFavorites() {
    return _asStringList(_box.get(AppStorageKeys.encyclopediaFavorites));
  }

  static Future<void> addEncyclopediaFavorite(String topicId) async {
    final favorites = getEncyclopediaFavorites();
    if (favorites.contains(topicId)) return;
    favorites.insert(0, topicId);
    await _box.put(AppStorageKeys.encyclopediaFavorites, favorites);
  }

  static Future<void> removeEncyclopediaFavorite(String topicId) async {
    final favorites = getEncyclopediaFavorites();
    if (!favorites.contains(topicId)) return;
    favorites.remove(topicId);
    await _box.put(AppStorageKeys.encyclopediaFavorites, favorites);
  }

  static bool isEncyclopediaFavorite(String topicId) {
    return getEncyclopediaFavorites().contains(topicId);
  }

  static List<String> getDownloads() {
    final data = _box.get(AppStorageKeys.downloads, defaultValue: <String>[]);
    return List<String>.from(data as List);
  }

  static Future<void> toggleDownload(String articleId, [ArticleModel? article]) async {
    final downloads = getDownloads();
    if (downloads.contains(articleId)) {
      downloads.remove(articleId);
      await _box.delete(AppStorageKeys.offlineArticle(articleId));
    } else {
      downloads.add(articleId);
      if (article != null) {
        await _box.put(AppStorageKeys.offlineArticle(articleId), article.toJson());
      }
    }
    await _box.put(AppStorageKeys.downloads, downloads);
  }

  static bool isDownloaded(String articleId) {
    return getDownloads().contains(articleId);
  }

  static ArticleModel? getOfflineArticle(String articleId) {
    final data = _box.get(AppStorageKeys.offlineArticle(articleId));
    if (data == null) return null;
    return ArticleModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Replaces the whole favorites list (used by Backup / Restore).
  static Future<void> restoreFavorites(List<String> ids) async {
    await _box.put(AppStorageKeys.favorites, List.of(ids));
  }

  /// Replaces the whole encyclopedia-favorites list (used by Backup /
  /// Restore).
  static Future<void> restoreEncyclopediaFavorites(List<String> ids) async {
    await _box.put(AppStorageKeys.encyclopediaFavorites, List.of(ids));
  }

  /// Replaces the whole downloads-reference list (used by Backup / Restore).
  ///
  /// Only the download *references* are restored. The offline article
  /// artifacts (the 'offline_' + articleId payloads) are re-acquirable and
  /// deferred per BACKUP-1A scope.
  static Future<void> restoreDownloads(List<String> ids) async {
    await _box.put(AppStorageKeys.downloads, List.of(ids));
  }
}
