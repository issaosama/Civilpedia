import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';

import 'core/constants/sentry_config.dart';
import 'core/services/theme_provider.dart';
import 'core/services/language_provider.dart';
import 'core/services/connectivity_provider.dart';
import 'core/di/staff_operations_scope.dart';
import 'features/auth/presentation/auth_refresh_listenable.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/business/presentation/providers/business_application_provider.dart';
import 'features/business/presentation/providers/business_claim_target_provider.dart';
import 'features/business/presentation/providers/business_profile_editor_provider.dart';
import 'features/business/presentation/providers/managed_businesses_provider.dart';
import 'features/business/presentation/providers/staff_access_provider.dart';
import 'features/business/presentation/providers/staff_application_detail_provider.dart';
import 'features/business/presentation/providers/staff_application_queue_provider.dart';
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
    await SentryFlutter.init((options) {
      options.dsn = SentryConfig.dsn;
      options.tracesSampleRate = 0.0;
      options.attachScreenshot = false;
      options.attachViewHierarchy = false;
    }, appRunner: () => _runApp());
  } else {
    _runApp();
  }
}

void _runApp() {
  // V1-R08 (finding 8/9/10/16) — account-bound providers are built exactly
  // once and reset together on any canonical identity change so no
  // privileged/account-bound state (profile, applications, managed businesses,
  // staff capabilities/queues) ever survives a session replacement.
  late final UserProfileProvider userProfileProvider;
  late final BusinessApplicationProvider businessApplicationProvider;
  late final BusinessClaimTargetProvider businessClaimTargetProvider;
  late final ManagedBusinessesProvider managedBusinessesProvider;
  late final BusinessProfileEditorProvider businessProfileEditorProvider;
  late final StaffOperationsScope staffOperationsScope;

  void resetAccountBoundState() {
    userProfileProvider.resetForIdentityChange();
    businessApplicationProvider.resetForIdentityChange();
    businessClaimTargetProvider.resetForIdentityChange();
    managedBusinessesProvider.reset();
    businessProfileEditorProvider.reset();
    staffOperationsScope.resetForAuthChange();
  }

  late final AuthProvider auth;
  auth = AuthProvider(
    gateway: AppDependencies.authGateway,
    onPostAuth: (session) {
      final generation = auth.generation;
      return AppDependencies.runPostAuthPipeline(
        session,
        canContinue: () =>
            !auth.isAuthorityBlocked &&
            AppDependencies.authGateway.canAccountAuthorityBeGranted &&
            auth.session?.userId == session.userId &&
            auth.generation == generation,
      );
    },
    onAccountBoundReset: resetAccountBoundState,
    onSessionRefresh: AuthRefreshListenable.instance.refresh,
  );
  final authBootstrap = auth.restoreSession();

  userProfileProvider = UserProfileProvider(
    repository: AppDependencies.userProfileRepo,
    cloudProfileGateway: AppDependencies.cloudProfileGateway,
    regionPreferenceGateway: AppDependencies.regionPreferenceGateway,
    auth: auth,
  );
  final profileBootstrap = userProfileProvider.loadProfile();
  final startupReady = Future.wait<void>([authBootstrap, profileBootstrap]);

  businessApplicationProvider = BusinessApplicationProvider(
    gateway: AppDependencies.businessApplicationGateway,
    auth: auth,
  );

  businessClaimTargetProvider = BusinessClaimTargetProvider(
    gateway: AppDependencies.businessClaimTargetGateway,
    auth: auth,
  );

  managedBusinessesProvider = ManagedBusinessesProvider(
    membershipGateway: AppDependencies.businessMembershipGateway,
    auth: auth,
  );

  businessProfileEditorProvider = BusinessProfileEditorProvider(
    gateway: AppDependencies.businessProfileManagementGateway,
    directoryRepository: AppDependencies.directoryRepo,
    auth: auth,
  );

  staffOperationsScope = StaffOperationsScope(
    gateway: AppDependencies.businessApplicationStaffGateway,
    auth: auth,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),

        ChangeNotifierProvider(create: (_) => LanguageProvider()),

        ChangeNotifierProvider.value(value: auth),

        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),

        ChangeNotifierProvider(
          create: (_) => EncyclopediaProvider(
            repository: AppDependencies.encyclopediaRepo,
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => EncyclopediaFavoritesProvider()..load(),
        ),

        ChangeNotifierProvider.value(value: userProfileProvider),

        ChangeNotifierProvider.value(value: businessApplicationProvider),

        ChangeNotifierProvider.value(value: businessClaimTargetProvider),

        // V1-R06 — My Managed Businesses + public profile editor.
        ChangeNotifierProvider.value(value: managedBusinessesProvider),

        ChangeNotifierProvider.value(value: businessProfileEditorProvider),

        // V1-R07 — Staff Operations providers, composed through a single
        // scope so permission-loss and post-mutation signals stay coherent
        // across access/queue/detail.
        ChangeNotifierProvider.value(value: staffOperationsScope),
        ChangeNotifierProvider<StaffAccessProvider>(
          lazy: false,
          create: (context) => context.read<StaffOperationsScope>().access,
        ),
        ChangeNotifierProvider<StaffApplicationQueueProvider>(
          lazy: false,
          create: (context) => context.read<StaffOperationsScope>().queue,
        ),
        ChangeNotifierProvider<StaffApplicationDetailProvider>(
          lazy: false,
          create: (context) => context.read<StaffOperationsScope>().detail,
        ),
      ],

      child: CivilpediaApp(startupReady: startupReady),
    ),
  );
}
