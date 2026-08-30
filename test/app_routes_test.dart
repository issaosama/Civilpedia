import 'package:flutter_test/flutter_test.dart';

import 'package:civilpedia/core/navigation/app_shell.dart';
import 'package:civilpedia/routes/app_routes.dart';

void main() {
  group('AppRoutes — canonical current route paths', () {
    test('bootstrap/auth paths match production literals', () {
      expect(AppRoutes.splash, '/splash');
      expect(AppRoutes.onboarding, '/onboarding');
      expect(AppRoutes.profileSetup, '/profile-setup');
      expect(AppRoutes.auth, '/auth');
    });

    test('knowledge/encyclopedia paths match production literals', () {
      expect(AppRoutes.categories, '/categories');
      expect(AppRoutes.topicListPattern, '/encyclopedia/topics/:categoryId');
      expect(AppRoutes.topicDetailPattern, '/encyclopedia/topic/:topicId');
    });

    test('articles paths match production literals', () {
      expect(AppRoutes.articles, '/articles');
      expect(AppRoutes.articlesByCategoryPattern, '/articles/:category');
      expect(AppRoutes.articlePattern, '/article/:id');
    });

    test('shell destination paths match production literals', () {
      expect(AppRoutes.home, '/home');
      expect(AppRoutes.encyclopedia, '/encyclopedia');
      expect(AppRoutes.tools, '/tools');
      expect(AppRoutes.saved, '/saved');
      expect(AppRoutes.profile, '/profile');
    });

    test('calculator paths match production literals', () {
      expect(AppRoutes.calculatorConcrete, '/calculator/concrete');
      expect(AppRoutes.calculatorSteel, '/calculator/steel');
      expect(AppRoutes.calculatorBrick, '/calculator/brick');
      expect(AppRoutes.calculatorChecklist, '/calculator/checklist');
      expect(AppRoutes.calculatorTile, '/calculator/tile');
    });
  });

  group('AppRoutes — dynamic path builders', () {
    test('topicListFor builds a correct navigable path', () {
      expect(AppRoutes.topicListFor('cat-42'), '/encyclopedia/topics/cat-42');
    });

    test('topicDetailFor builds a correct navigable path', () {
      expect(
        AppRoutes.topicDetailFor('t-concrete-1'),
        '/encyclopedia/topic/t-concrete-1',
      );
    });

    test('articleFor builds a correct navigable path', () {
      expect(AppRoutes.articleFor('article-7'), '/article/article-7');
    });

    test('articlesFor builds a correct navigable path', () {
      expect(AppRoutes.articlesFor('خرسانة'), '/articles/خرسانة');
    });
  });

  group('AppRoutes — parameterized routes preserve ids', () {
    test('ids are interpolated verbatim (no encoding side effects)', () {
      const id = 'a1.topic/x';
      expect(AppRoutes.topicDetailFor(id), '/encyclopedia/topic/a1.topic/x');
      expect(AppRoutes.topicListFor(id), '/encyclopedia/topics/a1.topic/x');
      expect(AppRoutes.articleFor(id), '/article/a1.topic/x');
    });

    test('distinct ids never collide', () {
      expect(
        AppRoutes.topicDetailFor('one') == AppRoutes.topicDetailFor('two'),
        isFalse,
      );
      expect(AppRoutes.articleFor('1') == AppRoutes.articleFor('11'), isFalse);
    });
  });

  group('AppRoutes — shell destination linkage (AppShell adoption)', () {
    test('kShellDestinations still expose the exact production routes', () {
      expect(kShellDestinations[0].route, '/home');
      expect(kShellDestinations[1].route, '/encyclopedia');
      expect(kShellDestinations[2].route, '/tools');
      expect(kShellDestinations[3].route, '/saved');
      expect(kShellDestinations[4].route, '/profile');
    });

    test('shell destinations resolve to the canonical AppRoutes constants', () {
      final expected = [
        AppRoutes.home,
        AppRoutes.encyclopedia,
        AppRoutes.tools,
        AppRoutes.saved,
        AppRoutes.profile,
      ];
      for (var i = 0; i < kShellDestinations.length; i++) {
        expect(
          kShellDestinations[i].route,
          expected[i],
          reason: 'shell branch $i drifted from AppRoutes',
        );
      }
    });

    test('branch count and order are unchanged', () {
      expect(kShellDestinations.map((d) => d.route).toList(), [
        '/home',
        '/encyclopedia',
        '/tools',
        '/saved',
        '/profile',
      ]);
    });
  });

  group('AppRoutes — no future/unimplemented domain route', () {
    final declaredPaths = <String>[
      AppRoutes.splash,
      AppRoutes.onboarding,
      AppRoutes.profileSetup,
      AppRoutes.auth,
      AppRoutes.categories,
      AppRoutes.topicListPattern,
      AppRoutes.topicDetailPattern,
      AppRoutes.articles,
      AppRoutes.articlesByCategoryPattern,
      AppRoutes.articlePattern,
      AppRoutes.home,
      AppRoutes.encyclopedia,
      AppRoutes.tools,
      AppRoutes.saved,
      AppRoutes.profile,
      AppRoutes.user,
      AppRoutes.userProfile,
      AppRoutes.userProfileEdit,
      AppRoutes.userSaved,
      AppRoutes.userDownloads,
      AppRoutes.calculatorConcrete,
      AppRoutes.calculatorSteel,
      AppRoutes.calculatorBrick,
      AppRoutes.calculatorChecklist,
      AppRoutes.calculatorTile,
    ];

    test('no future domain route is declared', () {
      const futurePrefixes = [
        '/knowledge',
        '/projects',
        '/directory',
        '/search',
      ];
      for (final path in declaredPaths) {
        for (final prefix in futurePrefixes) {
          expect(
            path == prefix || path.startsWith('$prefix/'),
            isFalse,
            reason:
                'future route "$prefix" must not be reachable but found '
                '"$path"',
          );
        }
      }
    });

    test('helpers never produce a future route either', () {
      for (final built in [
        AppRoutes.topicListFor('x'),
        AppRoutes.topicDetailFor('x'),
        AppRoutes.articleFor('x'),
        AppRoutes.articlesFor('x'),
      ]) {
        expect(built.startsWith('/knowledge/'), isFalse);
        expect(built.startsWith('/projects'), isFalse);
        expect(built.startsWith('/directory'), isFalse);
        expect(built.startsWith('/user'), isFalse);
        expect(built.startsWith('/search'), isFalse);
      }
    });
  });
}
