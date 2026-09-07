import '../../data/local/hive_helper.dart';

/// A5.5 — Read-only snapshot of the Hive-backed local lists that are claimed
/// as whole stores (article favorites, encyclopedia favorites, downloads).
///
/// Contents are only counted/referenced for ownership: claiming never modifies
/// them.
class LocalFavoritesSnapshot {
  const LocalFavoritesSnapshot({
    required this.articleFavorites,
    required this.encyclopediaFavorites,
    required this.downloads,
  });

  final List<String> articleFavorites;
  final List<String> encyclopediaFavorites;
  final List<String> downloads;

  bool get isEmpty =>
      articleFavorites.isEmpty &&
      encyclopediaFavorites.isEmpty &&
      downloads.isEmpty;
}

/// Read boundary the claim coordinator uses to learn about local favorites /
/// downloads without coupling to Hive itself.
abstract interface class LocalFavoritesGateway {
  Future<LocalFavoritesSnapshot> snapshot();
}

/// Production [LocalFavoritesGateway] over [HiveHelper].
class HiveLocalFavoritesGateway implements LocalFavoritesGateway {
  const HiveLocalFavoritesGateway();

  @override
  Future<LocalFavoritesSnapshot> snapshot() async {
    return LocalFavoritesSnapshot(
      articleFavorites: HiveHelper.getFavorites(),
      encyclopediaFavorites: HiveHelper.getEncyclopediaFavorites(),
      downloads: HiveHelper.getDownloads(),
    );
  }
}