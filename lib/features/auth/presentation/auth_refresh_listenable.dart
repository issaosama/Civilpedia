import 'package:flutter/foundation.dart';

/// V1-R08 (finding 11) — Singleton [Listenable] fed synchronously by
/// [AuthProvider] identity transitions so the app-level [GoRouter] can
/// re-evaluate its redirects immediately on a live session loss/replacement
/// (not only when the widget tree happens to rebuild).
///
/// Wired once in [AppDependencies]/`main.dart` as the router's
/// `refreshListenable`; harmless when no GoRouter listens.
class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable._internal();

  static final AuthRefreshListenable instance = AuthRefreshListenable._internal();

  /// Notifies the router that the session/identity may have changed.
  void refresh() => notifyListeners();
}