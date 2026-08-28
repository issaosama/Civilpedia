import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/storage/app_storage_keys.dart';
import '../../../models/user_model.dart';

class AuthRepositoryImpl {
  UserModel? _user;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  String get userName => _user?.name ?? 'Guest';
  String get userEmail => _user?.email ?? '';

  String? get currentName => _user?.name;
  String? get currentEmail => _user?.email;

  AuthRepositoryImpl() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(AppStorageKeys.authEmail);
    final name = prefs.getString(AppStorageKeys.authName);
    if (email != null && name != null) {
      _user = UserModel(name: name, email: email);
    }
  }

  Future<void> login({required String name, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppStorageKeys.authEmail, email);
    await prefs.setString(AppStorageKeys.authName, name);
    _user = UserModel(name: name, email: email);
  }

  Future<String?> loginWithPassword(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString(AppStorageKeys.registerEmail(email));
    if (storedPassword == null) return 'البريد الإلكتروني غير مسجل';
    if (storedPassword != password) return 'كلمة المرور غير صحيحة';

    final name = prefs.getString(AppStorageKeys.registerEmailName(email)) ?? 'مستخدم';
    await prefs.setString(AppStorageKeys.authEmail, email);
    await prefs.setString(AppStorageKeys.authName, name);
    _user = UserModel(name: name, email: email);
    return null;
  }

  Future<String?> register(String name, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final existingEmail = prefs.getString(AppStorageKeys.registerEmail(email));
    if (existingEmail != null) return 'البريد الإلكتروني مستخدم بالفعل';

    await prefs.setString(AppStorageKeys.registerEmail(email), password);
    await prefs.setString(AppStorageKeys.registerEmailName(email), name);
    await prefs.setString(AppStorageKeys.authEmail, email);
    await prefs.setString(AppStorageKeys.authName, name);
    _user = UserModel(name: name, email: email);
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppStorageKeys.authEmail);
    await prefs.remove(AppStorageKeys.authName);
    _user = null;
  }
}
