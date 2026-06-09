import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/services/theme_provider.dart';
import 'core/services/language_provider.dart';
import 'core/services/logger_service.dart';

import 'routes/app_router.dart';
import 'localization/ar.dart';

class CivilpediaApp extends StatelessWidget {
  const CivilpediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    LoggerService.info('App initialized');

    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp.router(
          title: Ar.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: appRouter,
          locale: languageProvider.locale,
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            for (final supported in supportedLocales) {
              if (supported.languageCode == locale?.languageCode) {
                return supported;
              }
            }

            return const Locale('ar');
          },
        );
      },
    );
  }
}
