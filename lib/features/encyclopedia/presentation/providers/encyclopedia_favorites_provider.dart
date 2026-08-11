import 'package:flutter/foundation.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../data/local/hive_helper.dart';

/// Persistence contract for Encyclopedia topic favorites.
abstract class EncyclopediaFavoritesStore {
  Future<List<String>> read();

  Future<void> add(String topicId);

  Future<void> remove(String topicId);
}

/// Default Hive-backed store for Encyclopedia favorites.
class HiveEncyclopediaFavoritesStore implements EncyclopediaFavoritesStore {
  const HiveEncyclopediaFavoritesStore();

  @override
  Future<List<String>> read() async => HiveHelper.getEncyclopediaFavorites();

  @override
  Future<void> add(String topicId) =>
      HiveHelper.addEncyclopediaFavorite(topicId);

  @override
  Future<void> remove(String topicId) =>
      HiveHelper.removeEncyclopediaFavorite(topicId);
}

class EncyclopediaFavoritesProvider extends ChangeNotifier {
  final EncyclopediaFavoritesStore _store;
  List<String> _savedIds = const [];
  late Set<String> _savedSet;
  bool _isLoaded = false;

  EncyclopediaFavoritesProvider({EncyclopediaFavoritesStore? store})
    : _store = store ?? const HiveEncyclopediaFavoritesStore() {
    _savedSet = _savedIds.toSet();
  }

  bool get isLoaded => _isLoaded;

  /// Saved topic ids, most recently saved first.
  List<String> get savedIds => List.unmodifiable(_savedIds);

  bool isFavorite(String topicId) => _savedSet.contains(topicId);

  Future<void> load() async {
    try {
      _savedIds = await _store.read();
    } catch (e) {
      LoggerService.error('Failed to load encyclopedia favorites', e);
      _savedIds = const [];
    }
    _savedSet = _savedIds.toSet();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> save(String topicId) async {
    if (isFavorite(topicId)) return;
    try {
      await _store.add(topicId);
    } catch (e) {
      LoggerService.error('Failed to save encyclopedia favorite', e);
      return;
    }
    _savedIds = [topicId, ..._savedIds];
    _savedSet = _savedIds.toSet();
    notifyListeners();
  }

  Future<void> remove(String topicId) async {
    if (!isFavorite(topicId)) return;
    try {
      await _store.remove(topicId);
    } catch (e) {
      LoggerService.error('Failed to remove encyclopedia favorite', e);
      return;
    }
    _savedIds = _savedIds.where((id) => id != topicId).toList();
    _savedSet = _savedIds.toSet();
    notifyListeners();
  }

  Future<void> toggle(String topicId) async {
    if (isFavorite(topicId)) {
      await remove(topicId);
    } else {
      await save(topicId);
    }
  }
}
