import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/app_storage_keys.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  String _userName = 'Civil Engineer';
  String _userEmail = 'guest@civilpedia.com';

  // الجديد (حتى ما يخرب الكود القديم)
  String? get currentName => _userName;
  String? get currentEmail => _userEmail;

  // الموجود سابقًا (نخليه)
  String get userName => _userName;
  String get userEmail => _userEmail;

  void login({
    String name = 'Civil Engineer',
    String email = 'user@civilpedia.com',
  }) {
    _isLoggedIn = true;
    _userName = name;
    _userEmail = email;

    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userName = 'Guest';
    _userEmail = 'guest@civilpedia.com';

    notifyListeners();
  }

  Future<String?> loginWithPassword(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString(AppStorageKeys.registerEmail(email));
    if (storedPassword == null) return 'البريد الإلكتروني غير مسجل';
    if (storedPassword != password) return 'كلمة المرور غير صحيحة';

    final name = prefs.getString(AppStorageKeys.registerEmailName(email)) ?? 'مستخدم';
    _isLoggedIn = true;
    _userName = name;
    _userEmail = email;
    notifyListeners();
    return null;
  }

  Future<String?> register(String name, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final existingEmail = prefs.getString(AppStorageKeys.registerEmail(email));
    if (existingEmail != null) return 'البريد الإلكتروني مستخدم بالفعل';

    await prefs.setString(AppStorageKeys.registerEmail(email), password);
    await prefs.setString(AppStorageKeys.registerEmailName(email), name);
    _isLoggedIn = true;
    _userName = name;
    _userEmail = email;
    notifyListeners();
    return null;
  }
}
