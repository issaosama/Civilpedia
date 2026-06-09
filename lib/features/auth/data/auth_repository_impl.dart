import 'package:shared_preferences/shared_preferences.dart';
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
    final email = prefs.getString('auth_email');
    final name = prefs.getString('auth_name');
    if (email != null && name != null) {
      _user = UserModel(name: name, email: email);
    }
  }

  Future<void> login({required String name, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_email', email);
    await prefs.setString('auth_name', name);
    _user = UserModel(name: name, email: email);
  }

  Future<String?> loginWithPassword(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString('register_$email');
    if (storedPassword == null) return 'البريد الإلكتروني غير مسجل';
    if (storedPassword != password) return 'كلمة المرور غير صحيحة';

    final name = prefs.getString('register_${email}_name') ?? 'مستخدم';
    await prefs.setString('auth_email', email);
    await prefs.setString('auth_name', name);
    _user = UserModel(name: name, email: email);
    return null;
  }

  Future<String?> register(String name, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final existingEmail = prefs.getString('register_$email');
    if (existingEmail != null) return 'البريد الإلكتروني مستخدم بالفعل';

    await prefs.setString('register_$email', password);
    await prefs.setString('register_${email}_name', name);
    await prefs.setString('auth_email', email);
    await prefs.setString('auth_name', name);
    _user = UserModel(name: name, email: email);
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_email');
    await prefs.remove('auth_name');
    _user = null;
  }
}
