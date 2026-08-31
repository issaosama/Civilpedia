import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/core/theme/spacing.dart';
import 'package:civilpedia/core/widgets/state_widgets.dart';
import 'package:civilpedia/features/directory/domain/directory_repository.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_card.dart';
import 'package:civilpedia/features/directory/presentation/directory_search_screen.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';

class _FakeDirectoryRepository implements DirectoryRepository {
  final List<ServiceBusinessProfile> profiles;

  _FakeDirectoryRepository(this.profiles);

  @override
  Future<List<ServiceBusinessProfile>> loadAll() async =>
      List<ServiceBusinessProfile>.from(profiles);

  @override
  Future<ServiceBusinessProfile?> loadById(String id) async => null;

  @override
  Future<void> save(ServiceBusinessProfile profile) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> clearAll() async {}
}

ServiceBusinessProfile _p(String id, {String name = '', VerificationStatus v = VerificationStatus.unverified}) {
  return ServiceBusinessProfile(
    id: id,
    name: name == '' ? 'Provider $id' : name,
    type: BusinessType.other,
    verificationStatus: v,
  );
}

Widget _searchApp(List<ServiceBusinessProfile> profiles, {double? bottomContentPadding}) {
  return ChangeNotifierProvider(
    create: (_) => LanguageProvider(),
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: DirectorySearchScreen(
        repository: _FakeDirectoryRepository(profiles),
        bottomContentPadding: bottomContentPadding ?? AppSpacing.huge,
      ),
    ),
  );
}

void main() {
  group('W5.5 search bottom scroll clearance — seam', () {
    testWidgets('1. default bottomContentPadding equals AppSpacing.huge + inset', (tester) async {
      final profiles = [_p('a')];
      await tester.pumpWidget(_searchApp(profiles, bottomContentPadding: AppSpacing.huge));
      await tester.pumpAndSettle();
      final list = tester.widget<ListView>(find.byType(ListView));
      final padding = list.padding as EdgeInsetsDirectional;
      final bottomInset = MediaQuery.paddingOf(tester.element(find.byType(ListView))).bottom;
      expect(padding.bottom, AppSpacing.huge + bottomInset);
    });

    testWidgets('2. explicit custom bottomContentPadding value is applied', (tester) async {
      final profiles = [_p('a')];
      const custom = 96.0;
      await tester.pumpWidget(_searchApp(profiles, bottomContentPadding: custom));
      await tester.pumpAndSettle();
      final list = tester.widget<ListView>(find.byType(ListView));
      final padding = list.padding as EdgeInsetsDirectional;
      final bottomInset = MediaQuery.paddingOf(tester.element(find.byType(ListView))).bottom;
      expect(padding.bottom, custom + bottomInset);
    });
  });

  group('W5.5 search bottom scroll clearance — final card reachable', () {
    testWidgets('3. list is scrollable with enough results', (tester) async {
      final profiles = [for (var i = 0; i < 30; i++) _p('p$i')];
      await tester.pumpWidget(_searchApp(profiles));
      await tester.pumpAndSettle();
      final scrollable = find.byType(Scrollable).last;
      final position = tester.state<ScrollableState>(scrollable).position;
      // Content exceeds the viewport, so scroll extent exists.
      expect(position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('4. final provider card can be scrolled fully into view', (tester) async {
      final profiles = [for (var i = 0; i < 30; i++) _p('p$i', name: 'Provider $i')];
      await tester.pumpWidget(_searchApp(profiles));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final target = find.text('Provider 29');
      await tester.scrollUntilVisible(
        target,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(target, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. card content padding is larger than the plain list padding (clearance exists)', (tester) async {
      final profiles = [_p('a')];
      await tester.pumpWidget(_searchApp(profiles));
      await tester.pumpAndSettle();
      final list = tester.widget<ListView>(find.byType(ListView));
      final padding = list.padding as EdgeInsetsDirectional;
      // There must be explicit bottom clearance beyond a bare 0.
      expect(padding.bottom, greaterThanOrEqualTo(AppSpacing.huge));
    });
  });

  group('W5.5 search bottom scroll clearance — unchanged semantics', () {
    testWidgets('6. empty state unchanged', (tester) async {
      await tester.pumpWidget(_searchApp([]));
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(EmptyStateWidget), findsOneWidget);
    });

    testWidgets('7. result order preserved', (tester) async {
      final profiles = [
        _p('a', name: 'Alpha', v: VerificationStatus.unverified),
        _p('b', name: 'Beta', v: VerificationStatus.verified),
      ];
      await tester.pumpWidget(_searchApp(profiles));
      await tester.pumpAndSettle();
      final cards = tester.widgetList<DirectoryProviderCard>(
        find.byType(DirectoryProviderCard),
      );
      expect(cards.map((c) => c.profile.name).toList(), ['Alpha', 'Beta']);
    });

    testWidgets('8. no layout overflow with many results', (tester) async {
      final profiles = [for (var i = 0; i < 40; i++) _p('p$i')];
      await tester.pumpWidget(_searchApp(profiles));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
