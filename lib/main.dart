import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';

import 'core/constants/sentry_config.dart';
import 'core/services/theme_provider.dart';
import 'core/services/language_provider.dart';
import 'core/services/connectivity_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/encyclopedia/presentation/providers/encyclopedia_provider.dart';
import 'features/profile/presentation/providers/user_profile_provider.dart';

import 'core/di/app_dependencies.dart';
import 'data/local/hive_helper.dart';
import 'data/local/preferences_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PreferencesHelper.init();
  await HiveHelper.init();
  await AppDependencies.init();

  if (SentryConfig.isEnabled) {
    await SentryFlutter.init(
      (options) {
        options.dsn = SentryConfig.dsn;
        options.tracesSampleRate = 0.0;
        options.attachScreenshot = false;
        options.attachViewHierarchy = false;
      },
      appRunner: () => _runApp(),
    );
  } else {
    _runApp();
  }
}

void _runApp() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),

        ChangeNotifierProvider(create: (_) => LanguageProvider()),

        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),

        ChangeNotifierProvider(create: (_) => EncyclopediaProvider(
          repository: AppDependencies.encyclopediaRepo,
        )),

        ChangeNotifierProvider(create: (_) => UserProfileProvider(
          repository: AppDependencies.userProfileRepo,
        )),
      ],

      child: CivilpediaApp(),
    ),
  );
}
