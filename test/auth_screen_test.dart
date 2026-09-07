import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/features/auth/presentation/auth_screen.dart';
import 'package:civilpedia/features/auth/presentation/providers/auth_provider.dart';
import 'package:civilpedia/localization/ar.dart';
import 'package:civilpedia/routes/app_routes.dart';

import 'fakes/fake_auth_gateway.dart';

/// A fresh router per test — GoRouter keeps its last location on a shared
/// instance, which would leak navigation state between tests.
GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.auth,
    routes: [
      GoRoute(path: AppRoutes.auth, builder: (_, __) => const AuthScreen()),
      GoRoute(
        path: AppRoutes.userProfile,
        builder: (_, __) => const Scaffold(body: Text('profile-target')),
      ),
    ],
  );
}

Widget _app(AuthProvider auth) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider.value(value: auth),
    ],
    child: MaterialApp.router(routerConfig: _buildRouter()),
  );
}

void main() {
  testWidgets('guest + unavailable gateway shows the notice, not the button',
      (tester) async {
    final auth = AuthProvider(gateway: FakeAuthGateway(available: false));
    await tester.pumpWidget(_app(auth));

    expect(find.text(Ar.googleSignInGuestNotice), findsOneWidget);
    expect(find.text(Ar.continueWithGoogle), findsNothing);
    expect(find.text(Ar.googleSignInUnavailable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest + available gateway shows Continue with Google',
      (tester) async {
    final auth = AuthProvider(gateway: FakeAuthGateway());
    await tester.pumpWidget(_app(auth));

    expect(find.text(Ar.continueWithGoogle), findsOneWidget);
    expect(find.text(Ar.googleSignInUnavailable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap triggers the gateway and navigates to the profile',
      (tester) async {
    final gateway = FakeAuthGateway(signInResult: fakeSession);
    final auth = AuthProvider(gateway: gateway);
    await tester.pumpWidget(_app(auth));

    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(gateway.signInCalls, 1);
    expect(auth.isLoggedIn, isTrue);
    expect(find.text('profile-target'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-in failure surfaces a localized error and stays usable',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final failing = AuthProvider(
      gateway: FakeAuthGateway(signInError: Exception('network')),
    );
    await tester.pumpWidget(_app(failing));

    await failing.signInWithGoogle();
    await tester.pumpAndSettle();

    expect(failing.isLoggedIn, isFalse);
    expect(find.text(Ar.googleSignInFailed), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}