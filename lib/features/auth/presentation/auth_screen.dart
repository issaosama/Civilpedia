import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../localization/ar.dart';
import 'providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _registerName = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  final _registerConfirmPassword = TextEditingController();
  String? _loginError;
  String? _registerError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _loginError = null;
          _registerError = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _registerName.dispose();
    _registerEmail.dispose();
    _registerPassword.dispose();
    _registerConfirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Ar.appName)),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: Ar.login),
              Tab(text: Ar.register),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLoginForm(),
                _buildRegisterForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            const SizedBox(height: 32),
            Icon(Icons.account_circle, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 32),
            if (_loginError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_loginError!, style: const TextStyle(color: Colors.red)),
              ),
            TextFormField(
              controller: _loginEmail,
              decoration: const InputDecoration(
                labelText: Ar.email,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال البريد الإلكتروني' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loginPassword,
              decoration: const InputDecoration(
                labelText: Ar.password,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال كلمة المرور' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleLogin,
                child: const Text(Ar.login),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _registerFormKey,
        child: Column(
          children: [
            const SizedBox(height: 32),
            Icon(Icons.person_add, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 32),
            if (_registerError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_registerError!, style: const TextStyle(color: Colors.red)),
              ),
            TextFormField(
              controller: _registerName,
              decoration: const InputDecoration(
                labelText: Ar.fullName,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال الاسم' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerEmail,
              decoration: const InputDecoration(
                labelText: Ar.email,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال البريد الإلكتروني' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerPassword,
              decoration: const InputDecoration(
                labelText: Ar.password,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              validator: (v) => (v == null || v.isEmpty) ? 'يرجى إدخال كلمة المرور' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerConfirmPassword,
              decoration: const InputDecoration(
                labelText: Ar.confirmPassword,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'يرجى تأكيد كلمة المرور';
                if (v != _registerPassword.text) return 'كلمة المرور غير متطابقة';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleRegister,
                child: const Text(Ar.register),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final error = await auth.loginWithPassword(_loginEmail.text.trim(), _loginPassword.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _loginError = error);
    } else {
      context.go('/home');
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final error = await auth.register(
      _registerName.text.trim(),
      _registerEmail.text.trim(),
      _registerPassword.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _registerError = error);
    } else {
      context.go('/home');
    }
  }
}
