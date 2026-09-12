import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';

import 'core/constants/sentry_config.dart';
import 'core/services/theme_provider.dart';
import 'core/services/language_provider.dart';
import 'core/services/connectivity_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/business/presentation/providers/business_application_provider.dart';
import 'features/business/presentation/providers/business_claim_target_provider.dart';
import 'features/business/presentation/providers/business_profile_editor_provider.dart';
import 'features/business/presentation/providers/managed_businesses_provider.dart';
import 'features/encyclopedia/presentation/providers/encyclopedia_favorites_provider.dart';
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

        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            gateway: AppDependencies.authGateway,
            onAuthenticated: (session) async {
              // Deterministic order: A5.5 record-ownership claim first, then
              // A5.6 personal-profile bootstrap. Both run fire-and-forget
              // after authentication and never block the authenticated UI.
              await AppDependencies.ownershipClaimCoordinator
                  .claimFor(session.userId);
              await AppDependencies.personalProfileBootstrapCoordinator
                  .bootstrap(
                    userId: session.userId,
                    authDisplayName: session.displayName,
                    authPhotoUrl: session.photoUrl,
                  );
            },
          )..restoreSession(),
        ),

        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),

        ChangeNotifierProvider(create: (_) => EncyclopediaProvider(
          repository: AppDependencies.encyclopediaRepo,
        )),

        ChangeNotifierProvider(
          create: (_) => EncyclopediaFavoritesProvider()..load(),
        ),

        ChangeNotifierProvider(create: (_) => UserProfileProvider(
          repository: AppDependencies.userProfileRepo,
        )),

        ChangeNotifierProvider(
          create: (context) => BusinessApplicationProvider(
            gateway: AppDependencies.businessApplicationGateway,
            auth: context.read<AuthProvider>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => BusinessClaimTargetProvider(
            gateway: AppDependencies.businessClaimTargetGateway,
          ),
        ),

        // V1-R06 — My Managed Businesses + public profile editor.
        ChangeNotifierProvider(
          create: (context) => ManagedBusinessesProvider(
            membershipGateway: AppDependencies.businessMembershipGateway,
            auth: context.read<AuthProvider>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => BusinessProfileEditorProvider(
            gateway: AppDependencies.businessProfileManagementGateway,
            directoryRepository: AppDependencies.directoryRepo,
            auth: context.read<AuthProvider>(),
          ),
        ),
      ],

      child: CivilpediaApp(),
    ),
  );
}
