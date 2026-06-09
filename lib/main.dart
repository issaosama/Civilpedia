import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';

import 'core/services/theme_provider.dart';
import 'core/services/language_provider.dart';
import 'core/services/connectivity_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/encyclopedia/presentation/providers/encyclopedia_provider.dart';

import 'data/local/hive_helper.dart';
import 'data/local/preferences_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PreferencesHelper.init();
  await HiveHelper.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),

        ChangeNotifierProvider(create: (_) => LanguageProvider()),

        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),

        ChangeNotifierProvider(create: (_) => EncyclopediaProvider()),
      ],

      child: CivilpediaApp(),
    ),
  );
}
