import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_detail_screen.dart';
import 'package:civilpedia/features/directory/presentation/services/directory_contact_launcher.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/features/saved/domain/saved_item_reference.dart';
import 'package:civilpedia/features/saved/domain/saved_reference_store.dart';
import 'package:civilpedia/localization/ar.dart';

class _FakeLauncher implements DirectoryContactLauncher {
  @override
  Future<bool> launchPhone(String trimmedPhone) async => true;
  @override
  Future<bool> launchWhatsApp(String digits) async => true;
}

class FakeSavedStore implements SavedReferenceStore {
  final List<SavedItemReference> refs = [];
  bool failWrites = false;

  @override
  Future<List<SavedItemReference>> loadAll() async => List.of(refs);

  @override
  Future<bool> contains(String referenceId) async =>
      refs.any((r) => r.id == referenceId);

  @override
  Future<void> save(SavedItemReference reference) async {
    if (failWrites) throw Exception('persist failure');
    if (!refs.any((r) => r.id == reference.id)) refs.add(reference);
  }

  @override
  Future<void> remove(String referenceId) async {
    if (failWrites) throw Exception('persist failure');
    refs.removeWhere((r) => r.id == referenceId);
  }
}

ServiceBusinessProfile _p({
  required String id,
  String name = 'Alpha',
  VerificationStatus verificationStatus = VerificationStatus.unverified,
  List<String> phones = const [],
  String? whatsapp,
}) {
  return ServiceBusinessProfile(
    id: id,
    name: name,
    type: BusinessType.other,
    phones: phones,
    whatsapp: whatsapp,
    verificationStatus: verificationStatus,
  );
}

Future<FakeSavedStore> _pump(
  WidgetTester tester, {
  required ServiceBusinessProfile profile,
  FakeSavedStore? store,
}) async {
  final s = store ?? FakeSavedStore();
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: DirectoryProviderDetailScreen(
          profile: profile,
          contactLauncher: _FakeLauncher(),
          savedReferenceStore: s,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return s;
}

void main() {
  group('W5.6 DETAIL SAVE UI', () {
    testWidgets('24. unsaved provider shows bookmark_border', (tester) async {
      await _pump(tester, profile: _p(id: 'p-1'));
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsNothing);
    });

    testWidgets('25. saved provider shows bookmark', (tester) async {
      final store = FakeSavedStore();
      store.refs.add(
        SavedItemReference(
          ownerDomain: SavedReferenceOwners.directory,
          entityType: SavedReferenceEntityTypes.provider,
          entityId: 'p-1',
          savedAt: DateTime.utc(2026),
        ),
      );
      await _pump(tester, profile: _p(id: 'p-1'), store: store);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
    });

    testWidgets('26. unsaved tooltip is Save provider', (tester) async {
      await _pump(tester, profile: _p(id: 'p-1'));
      final icon = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.bookmark_border),
          matching: find.byType(IconButton),
        ),
      );
      expect(icon.tooltip, Ar.savedSaveProvider);
    });

    testWidgets('27. saved tooltip is Remove from saved', (tester) async {
      final store = FakeSavedStore();
      store.refs.add(
        SavedItemReference(
          ownerDomain: SavedReferenceOwners.directory,
          entityType: SavedReferenceEntityTypes.provider,
          entityId: 'p-1',
          savedAt: DateTime.utc(2026),
        ),
      );
      await _pump(tester, profile: _p(id: 'p-1'), store: store);
      final icon = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.bookmark),
          matching: find.byType(IconButton),
        ),
      );
      expect(icon.tooltip, Ar.savedRemoveFromSaved);
    });

    testWidgets('28. tapping unsaved saves the canonical ref', (tester) async {
      final store = await _pump(tester, profile: _p(id: 'p-7'));
      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pumpAndSettle();
      expect(store.refs, hasLength(1));
      expect(store.refs.single.ownerDomain, SavedReferenceOwners.directory);
      expect(store.refs.single.entityType, SavedReferenceEntityTypes.provider);
      expect(store.refs.single.entityId, 'p-7');
      expect(store.refs.single.id, 'directory:provider:p-7');
      expect(store.refs.single.savedAt, isNotNull);
    });

    testWidgets('29. UI changes to saved after successful write', (tester) async {
      await _pump(tester, profile: _p(id: 'p-7'));
      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
    });

    testWidgets('30. tapping saved removes the exact ref', (tester) async {
      final store = FakeSavedStore();
      store.refs.add(
        SavedItemReference(
          ownerDomain: SavedReferenceOwners.directory,
          entityType: SavedReferenceEntityTypes.provider,
          entityId: 'p-7',
          savedAt: DateTime.utc(2026),
        ),
      );
      await _pump(tester, profile: _p(id: 'p-7'), store: store);
      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pumpAndSettle();
      expect(store.refs, isEmpty);
    });

    testWidgets('31. UI changes to unsaved after remove', (tester) async {
      final store = FakeSavedStore();
      store.refs.add(
        SavedItemReference(
          ownerDomain: SavedReferenceOwners.directory,
          entityType: SavedReferenceEntityTypes.provider,
          entityId: 'p-7',
          savedAt: DateTime.utc(2026),
        ),
      );
      await _pump(tester, profile: _p(id: 'p-7'), store: store);
      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsNothing);
    });

    testWidgets('32. failed Save does not falsely show saved', (tester) async {
      final store = FakeSavedStore()..failWrites = true;
      await _pump(tester, profile: _p(id: 'p-7'), store: store);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      expect(find.byIcon(Icons.bookmark), findsNothing);
      expect(store.refs, isEmpty);
      expect(find.text(Ar.errorOccurred), findsOneWidget);
    });

    testWidgets('33. failed Remove does not falsely show unsaved', (tester) async {
      final store = FakeSavedStore();
      store.refs.add(
        SavedItemReference(
          ownerDomain: SavedReferenceOwners.directory,
          entityType: SavedReferenceEntityTypes.provider,
          entityId: 'p-7',
          savedAt: DateTime.utc(2026),
        ),
      );
      store.failWrites = true;
      await _pump(tester, profile: _p(id: 'p-7'), store: store);
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsNothing);
      expect(store.refs, hasLength(1));
    });

    testWidgets('34. save then remove then save creates one canonical ref',
        (tester) async {
      final store = await _pump(tester, profile: _p(id: 'p-7'));
      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pumpAndSettle();
      expect(store.refs, hasLength(1));
      expect(store.refs.single.id, 'directory:provider:p-7');
    });

    testWidgets('35. verification status does not gate the button',
        (tester) async {
      for (final status in VerificationStatus.values) {
        await _pump(
          tester,
          profile: _p(id: 'v-$status', verificationStatus: status),
        );
        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('36. phones/WhatsApp remain unchanged by save', (tester) async {
      final store = await _pump(
        tester,
        profile: _p(id: 'p-c', phones: ['0771111111'], whatsapp: '07801234567'),
      );
      expect(find.textContaining('0771111111'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pumpAndSettle();
      expect(store.refs.single.id, 'directory:provider:p-c');
      expect(find.textContaining('0771111111'), findsOneWidget);
      expect(find.textContaining('07801234567'), findsOneWidget);
    });
  });
}
