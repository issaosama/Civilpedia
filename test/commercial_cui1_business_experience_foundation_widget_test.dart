import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
// The package explicitly exposes this asset manifest as a testing seam.
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as google_fonts_base;
import 'package:provider/provider.dart';

import 'package:civilpedia/core/navigation/shell_content_insets.dart';
import 'package:civilpedia/core/services/language_provider.dart';
import 'package:civilpedia/core/theme/app_theme.dart';
import 'package:civilpedia/core/widgets/remote_data_notice.dart';
import 'package:civilpedia/core/widgets/civil_surface_card.dart';
import 'package:civilpedia/features/auth/domain/auth_return_destination.dart';
import 'package:civilpedia/features/directory/domain/canonical_directory_entity.dart';
import 'package:civilpedia/features/directory/domain/cloud_directory_repository.dart';
import 'package:civilpedia/features/directory/presentation/directory_landing_screen.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_card.dart';
import 'package:civilpedia/features/directory/presentation/directory_provider_detail_screen.dart';
import 'package:civilpedia/features/directory/presentation/directory_search_screen.dart';
import 'package:civilpedia/features/directory/presentation/directory_verification_badge.dart';
import 'package:civilpedia/features/directory/presentation/services/directory_contact_launcher.dart';
import 'package:civilpedia/features/directory/presentation/widgets/directory_sponsored_provider_card.dart';
import 'package:civilpedia/features/monetization/domain/entities/sponsored_placement.dart';
import 'package:civilpedia/features/monetization/domain/monetization_reference.dart';
import 'package:civilpedia/features/monetization/domain/value_objects/campaign_destination.dart';
import 'package:civilpedia/features/profile/domain/service_business_profile.dart';
import 'package:civilpedia/features/saved/domain/saved_item_reference.dart';
import 'package:civilpedia/features/saved/domain/saved_reference_store.dart';
import 'package:civilpedia/routes/app_routes.dart';

// All entities, advertisements, stores and repositories below are test-only.
// No production Supabase, URL launcher, local persistence or campaign source
// is touched. PNGs and their manifest are written only to CUI1_VISUAL_DIR.
const _id = '00000000-0000-0000-0000-000000000101';
const _otherId = '00000000-0000-0000-0000-000000000102';
const _boundaryKey = Key('cui1-test-render-boundary');
const _managementAr = 'إدارة أعمالي';
const _managementEn = 'My businesses';
const _commercialAr = 'الخدمات التجارية';
const _commercialEn = 'Commercial services';
const _commercialExplanationAr =
    'لا تعرض هذه الصفحة حالة الاشتراك أو مزايا الخطة.';
const _commercialExplanationEn =
    'This page does not show subscription status or plan benefits.';
const _longName =
    'شركة الاختبار الهندسية Civil Test Engineering للإنشاءات والاستشارات والتوريد في العراق';
const _longDescription =
    'هذا وصف مطوّل من بيانات اختبار فقط، يعرض هوية منشأة هندسية ومعلوماتها العامة '
    'دون أي اعتماد تجاري أو اشتراك أو حقوق إدارة. Civil Test Engineering provides '
    'supplied public directory information for layout validation only. '
    'تُعرض الفئات والمواقع كما وردت من المصدر ولا تمثّل فروعاً تجارية أو حصصاً مدفوعة. '
    'تكرار الوصف لاختبار التفاف النص وإمكانية القراءة والوصول إلى الإجراءات الأخيرة.';

class _Case {
  const _Case(this.width, this.arabic, this.dark, this.scale);
  final double width;
  final bool arabic;
  final bool dark;
  final double scale;
  String get key =>
      '${width.toInt()}_${arabic ? 'ar' : 'en'}_${dark ? 'dark' : 'light'}_s${scale.toString().replaceAll('.', '_')}';
}

class _SavedStore implements SavedReferenceStore {
  final List<SavedItemReference> refs = [];
  bool failWrites = false;
  @override
  Future<List<SavedItemReference>> loadAll() async => List.of(refs);
  @override
  Future<bool> contains(String referenceId) async =>
      refs.any((r) => r.id == referenceId);
  @override
  Future<void> save(SavedItemReference reference) async {
    if (failWrites) throw StateError('TEST_ONLY_WRITE_FAILURE');
    if (!refs.any((r) => r.id == reference.id)) refs.add(reference);
  }

  @override
  Future<void> remove(String referenceId) async {
    if (failWrites) throw StateError('TEST_ONLY_WRITE_FAILURE');
    refs.removeWhere((r) => r.id == referenceId);
  }
}

class _Launcher implements DirectoryContactLauncher {
  final List<String> phones = [];
  final List<String> whatsApps = [];
  bool succeeds = true;
  bool throws = false;
  Completer<bool>? pending;
  @override
  Future<bool> launchPhone(String trimmedPhone) async {
    phones.add(trimmedPhone);
    if (throws) throw StateError('TEST_ONLY_CONTACT_EXCEPTION tel:private');
    return pending != null ? pending!.future : succeeds;
  }

  @override
  Future<bool> launchWhatsApp(String digits) async {
    whatsApps.add(digits);
    if (throws) {
      throw StateError('TEST_ONLY_CONTACT_EXCEPTION whatsapp:private');
    }
    return pending != null ? pending!.future : succeeds;
  }
}

class _Repository implements CloudDirectoryRepository {
  _Repository({
    this.entities = const [],
    this.cached,
    this.status = DirectoryRefreshStatus.success,
    this.gate,
  });
  final List<CanonicalDirectoryEntity> entities;
  final DirectoryCachedData? cached;
  DirectoryRefreshStatus status;
  final Completer<void>? gate;
  int refreshCalls = 0;
  @override
  bool get isAvailable => true;
  @override
  Future<DirectoryCachedData?> readCache() async => cached;
  @override
  Future<DirectoryRefreshResult> refresh() async {
    refreshCalls++;
    if (gate != null) await gate!.future;
    final actual = status == DirectoryRefreshStatus.success && entities.isEmpty
        ? DirectoryRefreshStatus.authoritativeEmpty
        : status;
    return DirectoryRefreshResult(
      status: actual,
      entities: actual == DirectoryRefreshStatus.success ? entities : const [],
      refreshedAt:
          actual == DirectoryRefreshStatus.success ||
              actual == DirectoryRefreshStatus.authoritativeEmpty
          ? DateTime.utc(2026, 10, 5)
          : null,
    );
  }

  @override
  Future<CanonicalDirectoryEntity?> loadByCanonicalId(String id) async {
    for (final entity in entities) {
      if (entity.id == id) return entity;
    }
    return null;
  }

  @override
  Future<DirectoryLoadResult> load() async => DirectoryLoadResult(
    state: entities.isEmpty
        ? DirectoryLoadState.empty
        : DirectoryLoadState.fresh,
    entities: entities,
  );
}

// A successful raw zero-row response is also authoritative empty content.
class _SuccessfulEmptyRepository extends _Repository {
  @override
  Future<DirectoryRefreshResult> refresh() async {
    refreshCalls++;
    return DirectoryRefreshResult(
      status: DirectoryRefreshStatus.success,
      refreshedAt: DateTime.utc(2026, 10, 6),
    );
  }
}

CanonicalDirectoryEntity _entity({
  String id = _id,
  String name = _longName,
  String? description = _longDescription,
  VerificationStatus verification = VerificationStatus.unverified,
  String claim = 'unclaimed',
  List<CanonicalDirectoryCategory>? categories,
  List<CanonicalDirectoryLocation>? locations,
  List<CanonicalDirectoryContact> contacts = const [],
  List<CanonicalDirectoryMedia> media = const [],
}) => CanonicalDirectoryEntity(
  id: id,
  name: name,
  entityType: 'company',
  description: description,
  verificationStatus: verification,
  claimStatus: claim,
  categories:
      categories ??
      const [
        CanonicalDirectoryCategory(
          id: 'c1',
          name: 'Structural design',
          nameAr: 'تصميم المنشآت والهياكل الخرسانية الطويلة',
          nameEn: 'Structural engineering and concrete design',
        ),
        CanonicalDirectoryCategory(
          id: 'c2',
          name: 'Materials',
          nameAr: 'مواد البناء والتوريد الهندسي',
          nameEn: 'Engineering materials and supplies',
        ),
        CanonicalDirectoryCategory(
          id: 'c3',
          name: 'Consultancy',
          nameAr: 'استشارات وإدارة المشاريع الهندسية',
          nameEn: 'Engineering consultancy and project management',
        ),
        CanonicalDirectoryCategory(
          id: 'c4',
          name: 'Laboratories',
          nameAr: 'الفحوصات المختبرية ومراقبة الجودة',
          nameEn: 'Laboratory testing and quality control',
        ),
        CanonicalDirectoryCategory(
          id: 'c5',
          name: 'Surveying',
          nameAr: 'المساحة وأعمال المواقع',
          nameEn: 'Surveying and site operations',
        ),
      ],
  locations:
      locations ??
      const [
        CanonicalDirectoryLocation(
          regionCode: 'BGD',
          regionName: 'Baghdad',
          regionNameAr: 'بغداد',
          regionNameEn: 'Baghdad',
          address:
              'شارع الاختبار الأول — Civil Test Street 101، قرب تقاطع هندسي طويل',
          isPrimary: true,
        ),
        CanonicalDirectoryLocation(
          regionCode: 'BSR',
          regionName: 'Basra',
          regionNameAr: 'البصرة',
          regionNameEn: 'Basra',
          address:
              'شارع الاختبار الثاني — Civil Test Street 202، موقع بيانات اختبار',
        ),
        CanonicalDirectoryLocation(
          regionCode: 'BGD',
          regionName: 'Baghdad',
          regionNameAr: 'بغداد',
          regionNameEn: 'Baghdad',
          address:
              'شارع الاختبار الأول — Civil Test Street 101، قرب تقاطع هندسي طويل',
        ),
      ],
  contacts: contacts,
  media: media,
);

// Owner-requested populated visual fixture. This private test-only constructor
// is never imported by production, seeded remotely, or used as a data fallback.
const _ownerBusinessId = '00000000-0000-0000-0000-000000000201';
CanonicalDirectoryEntity _ownerPopulatedEntity({
  bool arabic = true,
  VerificationStatus verification = VerificationStatus.verified,
  List<CanonicalDirectoryMedia> media = const [],
}) => CanonicalDirectoryEntity(
  id: _ownerBusinessId,
  name: arabic
      ? 'شركة الأفق الهندسية للمقاولات العامة'
      : 'Al-Ufuq Engineering General Contracting',
  entityType: 'company',
  description: arabic
      ? 'شركة متخصصة في أعمال المقاولات العامة والأعمال الإنشائية والمدنية.'
      : 'A company specializing in general contracting, structural and civil works.',
  verificationStatus: verification,
  claimStatus: 'unclaimed',
  media: media,
  categories: const [
    CanonicalDirectoryCategory(
      id: '00000000-0000-0000-0000-000000000901',
      name: 'Contracting',
      nameAr: 'مقاولات',
      nameEn: 'Contracting',
    ),
    CanonicalDirectoryCategory(
      id: '00000000-0000-0000-0000-000000000902',
      name: 'Construction',
      nameAr: 'إنشاءات',
      nameEn: 'Construction',
    ),
    CanonicalDirectoryCategory(
      id: '00000000-0000-0000-0000-000000000903',
      name: 'Concrete works',
      nameAr: 'أعمال خرسانية',
      nameEn: 'Concrete works',
    ),
  ],
  locations: const [
    CanonicalDirectoryLocation(
      regionCode: 'BGD',
      regionName: 'Baghdad',
      regionNameAr: 'بغداد',
      regionNameEn: 'Baghdad',
      address: 'بغداد — الجادرية',
      isPrimary: true,
    ),
    CanonicalDirectoryLocation(
      regionCode: 'BGD',
      regionName: 'Baghdad',
      regionNameAr: 'بغداد',
      regionNameEn: 'Baghdad',
      address: 'بغداد — الكرادة',
    ),
  ],
  contacts: const [
    CanonicalDirectoryContact(contactType: 'phone', value: '07701234567'),
    CanonicalDirectoryContact(
      contactType: 'whatsapp',
      value: '+964 780 123 4567',
    ),
    CanonicalDirectoryContact(
      contactType: 'email',
      value: 'visual@al-ufuq.example',
    ),
    CanonicalDirectoryContact(
      contactType: 'website',
      value: 'https://al-ufuq.example',
    ),
  ],
);

// The root implementation may update the English management label to an
// existing accepted localized equivalent. The Arabic and information-shell
// literals above are independently pinned by the frozen contract.
Widget _detail(
  CanonicalDirectoryEntity entity, {
  _SavedStore? store,
  _Launcher? launcher,
  RemoteDataCause? cause,
  VoidCallback? retry,
  bool updating = false,
}) => DirectoryProviderDetailScreen(
  entity: entity,
  savedReferenceStore: store ?? _SavedStore(),
  contactLauncher: launcher ?? _Launcher(),
  noticeCause: cause,
  onRetryCause: retry,
  isUpdating: updating,
);

Future<void> _pump(
  WidgetTester tester,
  Widget home,
  _Case c, {
  bool settle = true,
  bool shell = false,
  GoRouter? router,
  double keyboardInset = 0,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(c.width, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  Widget builder(BuildContext context, Widget? child) => RepaintBoundary(
    key: _boundaryKey,
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: Size(c.width, 1000),
        devicePixelRatio: 1,
        textScaler: TextScaler.linear(c.scale),
        padding: const EdgeInsets.only(bottom: 24),
        viewPadding: const EdgeInsets.only(bottom: 24),
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
      ),
      child: shell
          ? ShellContentInsets(bottomObstruction: 92, child: child!)
          : child!,
    ),
  );
  final theme = c.dark ? AppTheme.darkTheme : AppTheme.lightTheme;
  await tester.pumpWidget(
    ChangeNotifierProvider(
      key: UniqueKey(),
      create: (_) => LanguageProvider(isArabic: c.arabic),
      child: router == null
          ? MaterialApp(
              theme: theme,
              locale: Locale(c.arabic ? 'ar' : 'en'),
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: builder,
              home: home,
            )
          : MaterialApp.router(
              theme: theme,
              locale: Locale(c.arabic ? 'ar' : 'en'),
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: builder,
              routerConfig: router,
            ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }
  _assertNoOverflow(tester, c);
}

void _assertNoOverflow(WidgetTester tester, _Case c) {
  expect(
    tester.takeException(),
    isNull,
    reason: 'No render/async exception at ${c.key}',
  );
  for (final element in find.byType(Scrollable).evaluate()) {
    final scrollable = element.widget as Scrollable;
    final isHorizontal =
        scrollable.axisDirection == AxisDirection.left ||
        scrollable.axisDirection == AxisDirection.right;
    if (isHorizontal) {
      // A single-line editable token/input may scroll within its own field;
      // that is independent of the frozen no-horizontal-page-scroll rule.
      expect(
        find.ancestor(
          of: find.byWidget(scrollable),
          matching: find.byType(EditableText),
        ),
        findsWidgets,
        reason: 'Only editable text may own horizontal scrolling.',
      );
    }
  }
  for (final element in find.byType(Text).evaluate()) {
    final box = element.renderObject;
    if (box is! RenderBox || !box.hasSize || box.size.isEmpty) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect.bottom <= 0 || rect.top >= 1000) continue;
    expect(
      rect.left,
      greaterThanOrEqualTo(-0.1),
      reason: 'Left edge: ${(element.widget as Text).data}',
    );
    expect(
      rect.right,
      lessThanOrEqualTo(c.width + 0.1),
      reason: 'Right edge: ${(element.widget as Text).data}',
    );
  }
  // Requests already own their injected client. Restore the debug hook before
  // Flutter verifies each widget-test body's invariants, not after teardown.
  debugNetworkImageHttpClientProvider = null;
}

void _assertTargets(WidgetTester tester) {
  for (final element
      in find
          .byWidgetPredicate(
            (w) => w is IconButton || w is ButtonStyleButton || w is InkWell,
          )
          .evaluate()) {
    final widget = element.widget;
    final enabled = widget is IconButton
        ? widget.onPressed != null
        : widget is InkWell
        ? widget.onTap != null
        : (widget as ButtonStyleButton).onPressed != null;
    if (!enabled) continue;
    final box = element.renderObject;
    if (box is! RenderBox || !box.hasSize) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect.bottom <= 0 || rect.top >= 1000) continue;
    expect(
      box.size.width,
      greaterThanOrEqualTo(48),
      reason: '$widget target width',
    );
    expect(
      box.size.height,
      greaterThanOrEqualTo(48),
      reason: '$widget target height',
    );
  }
}

void _assertDetailGeometry(WidgetTester tester, _Case c) {
  final gutter = c.width < 600
      ? 16.0
      : c.width < 840
      ? 24.0
      : 32.0;
  final innerWidth = (c.width - 2 * gutter).clamp(0.0, 1120.0);
  final columns = c.width >= 840 && innerWidth >= 760 && c.scale < 1.3;
  final cap = columns ? 1120.0 : 760.0;
  final expectedWidth = innerWidth.clamp(0.0, cap);
  final content = tester.getRect(find.byKey(const Key('cui1-detail-content')));
  expect(content.width, closeTo(expectedWidth, 0.1));
  expect(content.left, closeTo((c.width - expectedWidth) / 2, 0.1));
  final locations = tester.getRect(
    find.byKey(const Key('cui1-detail-locations')),
  );
  final contacts = tester.getRect(
    find.byKey(const Key('cui1-detail-contacts')),
  );
  if (columns) {
    expect(contacts.width, closeTo(300, 0.1));
    expect(locations.width, greaterThanOrEqualTo(400));
    expect(
      c.arabic
          ? locations.left - contacts.right
          : contacts.left - locations.right,
      closeTo(20, 0.1),
    );
    expect(contacts.top, lessThan(locations.top));
  } else {
    expect(contacts.width, closeTo(content.width, 0.1));
    expect(contacts.top, greaterThan(locations.bottom));
  }
}

void _assertLandingGeometry(WidgetTester tester, _Case c) {
  final gutter = c.width < 600
      ? 16.0
      : c.width < 840
      ? 24.0
      : 32.0;
  final expectedColumns = c.width < 600
      ? 2
      : c.width < 840
      ? 3
      : 4;
  final grid = tester.getRect(find.byKey(const Key('cui1-landing-grid')));
  expect(grid.width, closeTo((c.width - 2 * gutter).clamp(0, 1120), 0.1));
  final cards = find
      .byType(CivilSurfaceCard)
      .evaluate()
      .map((e) => tester.getRect(find.byWidget(e.widget)))
      .toList();
  expect(cards, hasLength(9));
  expect(
    cards.where((rect) => (rect.top - cards.first.top).abs() < 0.1),
    hasLength(expectedColumns),
  );
  for (final rect in cards) {
    expect(rect.width, greaterThanOrEqualTo(48));
    expect(rect.height, greaterThanOrEqualTo(48));
  }
}

void _assertOwnerPolish(WidgetTester tester, _Case c) {
  if (c.width >= 600) return;
  final locations = find.byKey(const Key('cui1-detail-locations'));
  final cards = find.descendant(
    of: locations,
    matching: find.byType(CivilSurfaceCard),
  );
  expect(cards, findsNWidgets(2));
  final first = tester.getRect(cards.first);
  final second = tester.getRect(cards.last);
  expect(first.width, closeTo(tester.getRect(locations).width - 24, 0.1));
  expect(second.width, closeTo(first.width, 0.1));
  expect(second.top, greaterThan(first.bottom));
  final contacts = find.byKey(const Key('cui1-detail-contacts'));
  final rows = find.descendant(
    of: contacts,
    matching: find.byType(OutlinedButton),
  );
  expect(rows, findsNWidgets(2));
  final phone = tester.getRect(rows.first);
  final whatsapp = tester.getRect(rows.last);
  expect(phone.width, closeTo(tester.getRect(contacts).width - 24, 0.1));
  expect(whatsapp.width, closeTo(phone.width, 0.1));
  final email = find.byType(SelectableText).at(0);
  final website = find.byType(SelectableText).at(1);
  expect(whatsapp.top, greaterThan(phone.bottom));
  expect(tester.getRect(email).top, greaterThan(whatsapp.bottom));
  expect(
    tester.getRect(website).top,
    greaterThan(tester.getRect(email).bottom),
  );
  expect(Directionality.of(tester.element(email)), TextDirection.ltr);
  expect(Directionality.of(tester.element(website)), TextDirection.ltr);
  final manage = tester.getRect(
    find.byKey(const Key('cui1-detail-management')),
  );
  final info = tester.getRect(
    find.byKey(const Key('cui1-detail-commercial-info')),
  );
  expect(manage.width, closeTo(tester.getRect(contacts).width, 0.1));
  expect(info.width, closeTo(manage.width, 0.1));
  expect(info.top, greaterThan(manage.bottom));
}

void _assertFilterLabelGeometry(WidgetTester tester, _Case c) {
  final labels = c.arabic
      ? ['نوع الجهة', 'المنطقة', 'الفئة']
      : ['Entity type', 'Location', 'Category'];
  final fields = find.byType(DropdownButtonFormField<String?>);
  for (var index = 0; index < fields.evaluate().length; index++) {
    final field = tester.getRect(fields.at(index));
    final label = tester.getRect(
      find.byKey(ValueKey('cui1-filter-label-${labels[index]}')),
    );
    expect(
      field.top - label.bottom,
      closeTo(4, 0.1),
      reason: 'The label has breathing room above the field border.',
    );
    expect(label.left, greaterThanOrEqualTo(field.left));
    expect(label.right, lessThanOrEqualTo(field.right));
    expect(field.height, greaterThanOrEqualTo(48));
    expect(
      c.arabic ? field.right - label.right : label.left - field.left,
      closeTo(12, 0.1),
      reason: 'Label inset follows the actual text direction.',
    );
  }
}

final _records = <Map<String, Object?>>[];
String? get _visualDir => Platform.environment['CUI1_VISUAL_DIR'];

Future<void> _capture(
  WidgetTester tester,
  String surface,
  _Case c, {
  String state = 'fresh',
  String fixture = 'cui1-stress-valid-uuid',
}) async {
  final target = _visualDir;
  if (target == null || target.isEmpty) return;
  final normalized = Directory(target).absolute.path.toLowerCase();
  expect(
    normalized.startsWith(Directory.current.absolute.path.toLowerCase()),
    isFalse,
    reason: 'Visual evidence must stay outside the repository.',
  );
  await tester.pump(Duration(milliseconds: state == 'loading' ? 350 : 16));
  final filename = '${surface}_${state}_${c.key}.png';
  final path = '$target${Platform.pathSeparator}$filename';
  await tester.runAsync(() async {
    await Directory(target).create(recursive: true);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundaryKey),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('PNG encoding returned no bytes.');
    await File(path).writeAsBytes(data.buffer.asUint8List());
    image.dispose();
    _records.add({
      'file': path,
      'surface': surface,
      'state': state,
      'fixture': fixture,
      'fixture_label': 'بيانات تجريبية للتصميم — غير مرجعية',
      'width_dp': c.width,
      'height_dp': 1000,
      'dpr': 1.0,
      'locale': c.arabic ? 'ar' : 'en',
      'direction': c.arabic ? 'rtl' : 'ltr',
      'theme': c.dark ? 'dark' : 'light',
      'text_scale': c.scale,
      'test_font': 'Flutter SDK Ahem; logical assertions, not Cairo visual QA',
      'automated_overflow_check': 'PASS',
      'human_visual_review': 'PENDING',
    });
    await File(
      '$target${Platform.pathSeparator}render_manifest.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(_records));
  });
}

Future<void> _bottom(WidgetTester tester) async {
  final scrollables = find.byType(Scrollable).evaluate().toList();
  for (final element in scrollables) {
    final state = (element as StatefulElement).state as ScrollableState;
    if (state.position.hasContentDimensions &&
        state.position.maxScrollExtent > 0) {
      state.position.jumpTo(state.position.maxScrollExtent);
    }
  }
  await tester.pumpAndSettle();
}

Future<void> _assertScrollReachable(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  final pageScroll = find
      .ancestor(of: target, matching: find.byType(SingleChildScrollView))
      .last;
  expect(
    pageScroll,
    findsOneWidget,
    reason: 'Content belongs to the page scroll.',
  );
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pumpAndSettle();
  final viewport = tester.getRect(pageScroll);
  final rect = tester.getRect(target);
  final context = tester.element(target);
  final obstruction =
      ShellContentInsets.maybeOf(context)?.bottomObstruction ?? 0;
  final deviceInset = MediaQuery.paddingOf(context).bottom;
  expect(rect.top, greaterThanOrEqualTo(viewport.top - 0.1));
  expect(
    rect.bottom,
    lessThanOrEqualTo(
      viewport.bottom -
          (obstruction > deviceInset ? obstruction : deviceInset) +
          0.1,
    ),
    reason:
        'Each content/action is reachable above the actual shell/device inset.',
  );
  expect(target.hitTestable(), findsOneWidget);
}

Finder _buttonWith(String label) => find
    .ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    )
    .first;

void _assertPublicAuthorityOnly(WidgetTester tester) {
  final visible = tester
      .widgetList<Text>(find.byType(Text))
      .map((w) => w.data ?? '')
      .join('\n');
  for (final forbidden in [
    'Business Pro',
    'Business Plus',
    'Corporate',
    'Grace',
    'IQD',
    'الترقية',
    'اشترك الآن',
    'شراء خطة',
    'حصة الفروع',
    'الفروع المتبقية',
    'Upgrade',
    'Subscribe',
    'Buy plan',
    'Branch quota',
  ]) {
    expect(
      visible,
      isNot(contains(forbidden)),
      reason: 'No commercial catalog/authority: $forbidden',
    );
  }
}

class _FontManifest implements AssetManifest {
  _FontManifest(this.keys);
  final List<String> keys;
  @override
  List<String> listAssets() => keys;
  @override
  List<AssetMetadata>? getAssetVariants(String key) => keys.contains(key)
      ? [AssetMetadata(key: key, targetDevicePixelRatio: null, main: true)]
      : null;
}

Future<void> _useStandardTestFonts(TestWidgetsFlutterBinding binding) async {
  // Use the font shipped with Flutter's test environment, resolved through the
  // installed package URI. No Cairo download, private font, local path/variable
  // or machine font cache participates in correctness. This is deliberately
  // Ahem under the requested style aliases, not evidence of Cairo visual QA.
  final configFile = File('.dart_tool/package_config.json').absolute;
  final packages =
      (jsonDecode(await configFile.readAsString()) as Map)['packages'] as List;
  final testPackage = packages.cast<Map>().singleWhere(
    (package) => package['name'] == 'flutter_test',
  );
  final testRoot = Directory.fromUri(
    configFile.uri.resolve(testPackage['rootUri'] as String),
  ).uri;
  final data = ByteData.sublistView(
    await File.fromUri(
      testRoot.resolve('../flutter_tools/static/Ahem.ttf'),
    ).readAsBytes(),
  );
  final dataByAsset = <String, ByteData>{};
  const names = {
    'regular': 'Regular',
    '500': 'Medium',
    '600': 'SemiBold',
    '700': 'Bold',
  };
  for (final entry in names.entries) {
    dataByAsset['cui1-test-fonts/Cairo-${entry.value}.ttf'] = data;
    final loader = FontLoader('Cairo_${entry.key}')
      ..addFont(Future.value(data));
    await loader.load();
  }
  final familyLoader = FontLoader('Cairo')..addFont(Future.value(data));
  await familyLoader.load();
  // Google Fonts' exposed test asset seam resolves every requested variant to
  // that standard test font. Missing configuration fails, never skips a test.
  google_fonts_base.assetManifest = _FontManifest(dataByAsset.keys.toList());
  GoogleFonts.config.allowRuntimeFetching = false;
  binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
    message,
  ) async {
    if (message == null) return null;
    final name = utf8.decode(
      message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
    );
    return dataByAsset[name];
  });
}

SponsoredPlacement _placement(CanonicalDirectoryEntity entity, bool arabic) {
  final subject = MonetizationReference(
    ownerDomain: MonetizationOwners.directory,
    entityType: 'provider',
    entityId: entity.id,
  );
  return SponsoredPlacement(
    placementKey: 'directory_sponsored',
    campaignId: 'CUI1_TEST_ONLY_CAMPAIGN',
    subject: subject,
    destination: CampaignDestination.internal(subject),
    sponsorshipType: 'sponsorship',
    disclosureLabel: arabic
        ? 'إعلان ممول — بيانات اختبار'
        : 'Sponsored — test fixture',
    servedAt: DateTime.utc(2026, 10, 5),
  );
}

// Reference photos are displayed only by test/QA fakes. The source is the
// Owner's supplied reference; these are not published business brand assets.
final _referenceBytes = <String, Uint8List>{};
final _mediaRequests = <String>[];
final _controlledMedia = <String, Completer<Uint8List?>>{};
List<CanonicalDirectoryMedia> get _referenceMedia => [
  const CanonicalDirectoryMedia(
    mediaType: 'cover',
    url: 'https://owner-qa.invalid/cover',
  ),
  const CanonicalDirectoryMedia(
    mediaType: 'logo',
    url: 'https://owner-qa.invalid/logo',
  ),
  for (var i = 0; i < 15; i++)
    CanonicalDirectoryMedia(
      mediaType: 'gallery',
      url: 'https://owner-qa.invalid/gallery-$i',
    ),
];

Future<void> _prepareReferenceMedia() async {
  final path = Platform.environment['CUI1_OWNER_QA_REFERENCE_PATH'];
  if (path == null) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 64, 64),
      Paint()..color = const Color(0xff637e99),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(64, 64);
    final bytes = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    for (final name in [
      'cover',
      'logo',
      'gallery-0',
      'gallery-1',
      'gallery-2',
    ]) {
      _referenceBytes[name] = bytes;
    }
    image.dispose();
    picture.dispose();
    return;
  }
  final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
  final source = (await codec.getNextFrame()).image;
  const regions = {
    // Crop within the actual image content, excluding device controls/frames.
    'cover': Rect.fromLTWH(340, 100, 335, 196),
    'logo': Rect.fromLTWH(140, 242, 178, 164),
    'gallery-0': Rect.fromLTWH(596, 775, 205, 141),
    'gallery-1': Rect.fromLTWH(375, 775, 205, 141),
    'gallery-2': Rect.fromLTWH(146, 775, 208, 92),
  };
  for (final entry in regions.entries) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      source,
      entry.value,
      Rect.fromLTWH(0, 0, entry.value.width, entry.value.height),
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      entry.value.width.round(),
      entry.value.height.round(),
    );
    _referenceBytes[entry.key] = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    image.dispose();
    picture.dispose();
  }
  source.dispose();
  codec.dispose();
  final definePath = Platform.environment['CUI1_OWNER_QA_DEFINE_FILE'];
  if (definePath != null) {
    final body = jsonEncode(
      _referenceBytes.map((name, bytes) => MapEntry(name, base64Encode(bytes))),
    );
    await File(
      definePath,
    ).writeAsString(jsonEncode({'CUI1_OWNER_QA_MEDIA': body}));
  }
}

class _ReferenceImageClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    _mediaRequests.add(url.toString());
    var name = url.path.substring(1);
    if (name.startsWith('gallery-')) {
      final index = int.tryParse(name.substring(8));
      if (index != null) name = 'gallery-${index % 3}';
    }
    final bytes = url.host == 'owner-qa.invalid' ? _referenceBytes[name] : null;
    return _ReferenceImageRequest(
      _controlledMedia[url.toString()]?.future ?? Future.value(bytes),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReferenceImageRequest implements HttpClientRequest {
  _ReferenceImageRequest(this.bytes);
  final Future<Uint8List?> bytes;
  @override
  Future<HttpClientResponse> close() async =>
      _ReferenceImageResponse(await bytes);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReferenceImageResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _ReferenceImageResponse(this.bytes);
  final Uint8List? bytes;
  @override
  int get statusCode => bytes == null ? 404 : 200;
  @override
  int get contentLength => bytes?.length ?? 0;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(bytes ?? Uint8List(0)).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settleReferenceImages(
  WidgetTester tester, {
  Iterable<String>? urls,
}) async {
  await tester.runAsync(() async {
    // Await only requests already started by production. Attaching to pending
    // streams does not start probes or retry failures evicted from the cache.
    await Future.wait([
      for (final url in (urls ?? _mediaRequests).toSet())
        if (PaintingBinding.instance.imageCache
            .statusForKey(NetworkImage(url))
            .pending)
          precacheImage(
            NetworkImage(url),
            tester.element(find.byType(MaterialApp).first),
            onError: (error, stack) {},
          ),
    ]);
  });
  await tester.pumpAndSettle();
}

Future<void> _captureFullReference(WidgetTester tester, _Case c) async {
  if (_visualDir == null) return;
  final scroll = tester.state<ScrollableState>(
    find
        .descendant(
          of: find.byType(DirectoryProviderDetailScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  final height =
      scroll.position.maxScrollExtent + scroll.position.viewportDimension + 32;
  tester.view.physicalSize = Size(c.width, height);
  await tester.pumpAndSettle();
  await _capture(
    tester,
    'reference-full-detail',
    c,
    fixture: 'OWNER_REFERENCE_PHOTOS_TEST_ONLY_15_GALLERY_ROWS',
  );
  tester.view.physicalSize = Size(c.width, 1000);
  await tester.pumpAndSettle();
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await _useStandardTestFonts(binding);
    await _prepareReferenceMedia();
  });
  tearDownAll(() {
    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      null,
    );
    google_fonts_base.assetManifest = null;
    GoogleFonts.config.allowRuntimeFetching = true;
  });

  group('CUI-1 Owner reference media and quick-action redesign', () {
    setUp(() {
      _mediaRequests.clear();
      _controlledMedia.clear();
      debugNetworkImageHttpClientProvider = () => _ReferenceImageClient();
    });
    tearDown(() {
      debugNetworkImageHttpClientProvider = null;
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    });
    List<String> galleryUrls(WidgetTester tester) => tester
        .widgetList<Image>(
          find.descendant(
            of: find.byKey(const Key('cui1-detail-gallery')),
            matching: find.byType(Image),
          ),
        )
        .map((image) => (image.image as NetworkImage).url)
        .toList();
    CanonicalDirectoryMedia gallery(String name) => CanonicalDirectoryMedia(
      mediaType: 'gallery',
      url: 'https://owner-qa.invalid/$name',
    );

    for (final width in [390.0, 600.0, 839.0, 840.0, 1280.0]) {
      for (final arabic in [true, false]) {
        for (final dark in [false, true]) {
          for (final scale in [1.0, 1.3]) {
            final c = _Case(width, arabic, dark, scale);
            testWidgets('mixed media failures and usable count ${c.key}', (
              tester,
            ) async {
              await _pump(
                tester,
                _detail(
                  _ownerPopulatedEntity(
                    arabic: arabic,
                    media: [
                      const CanonicalDirectoryMedia(
                        mediaType: 'cover',
                        url: 'https://owner-qa.invalid/failed-cover',
                      ),
                      const CanonicalDirectoryMedia(
                        mediaType: 'logo',
                        url: 'https://owner-qa.invalid/failed-logo',
                      ),
                      gallery('failed-gallery-0'),
                      gallery('gallery-0'),
                      gallery('gallery-1'),
                      gallery('failed-gallery-1'),
                      gallery('gallery-2'),
                      gallery('gallery-3'),
                      gallery('gallery-4'),
                      gallery('gallery-0'),
                    ],
                  ),
                ),
                c,
                shell: true,
              );
              await _settleReferenceImages(tester);
              expect(
                find.byKey(const Key('cui1-detail-hero-fallback')),
                findsOneWidget,
              );
              expect(
                find.descendant(
                  of: find.byKey(const Key('cui1-detail-avatar')),
                  matching: find.byIcon(Icons.apartment),
                ),
                findsOneWidget,
                reason: 'Failed logo falls back to the supplied company type.',
              );
              expect(galleryUrls(tester), [
                'https://owner-qa.invalid/gallery-0',
                'https://owner-qa.invalid/gallery-1',
                'https://owner-qa.invalid/gallery-2',
              ]);
              expect(
                find.text('+2'),
                findsOneWidget,
                reason:
                    'Five decoded unique items, three visible; failures/duplicates excluded.',
              );
              expect(find.text('+4'), findsNothing);
              expect(find.byIcon(Icons.image_outlined), findsNothing);
              expect(_mediaRequests, hasLength(9));
              expect(_mediaRequests.toSet(), hasLength(9));
              _assertDetailGeometry(tester, c);
              _assertOwnerPolish(tester, c);
              _assertPublicAuthorityOnly(tester);
              await _assertScrollReachable(
                tester,
                find.byKey(const Key('cui1-detail-gallery')),
              );
              _assertNoOverflow(tester, c);
              await _bottom(tester);
              await _assertScrollReachable(
                tester,
                find.byKey(const Key('cui1-detail-management')),
              );
              _assertTargets(tester);
              _assertNoOverflow(tester, c);
              await tester.pump();
              expect(
                _mediaRequests,
                hasLength(9),
                reason: 'Failure state does not retry on later builds.',
              );
            });
          }
        }
      }
    }

    for (final c in const [
      _Case(390, true, true, 1.3),
      _Case(1280, false, false, 1.0),
    ]) {
      testWidgets('all gallery failures omit section ${c.key}', (tester) async {
        await _pump(
          tester,
          _detail(
            _ownerPopulatedEntity(
              media: [
                const CanonicalDirectoryMedia(
                  mediaType: 'cover',
                  url: 'https://owner-qa.invalid/cover',
                ),
                const CanonicalDirectoryMedia(
                  mediaType: 'logo',
                  url: 'https://owner-qa.invalid/logo',
                ),
                gallery('failed-gallery-0'),
                gallery('failed-gallery-1'),
              ],
            ),
          ),
          c,
        );
        await _settleReferenceImages(tester);
        expect(find.byKey(const Key('cui1-detail-gallery')), findsNothing);
        expect(
          find.text(c.arabic ? 'معرض الصور' : 'Photo gallery'),
          findsNothing,
        );
        expect(find.byIcon(Icons.photo_library_outlined), findsNothing);
        expect(find.byIcon(Icons.image_outlined), findsNothing);
        expect(
          find.byKey(const Key('cui1-detail-hero-fallback')),
          findsNothing,
        );
        expect(
          tester
              .widgetList<Image>(find.byType(Image))
              .map((image) => (image.image as NetworkImage).url),
          ['https://owner-qa.invalid/cover', 'https://owner-qa.invalid/logo'],
        );
        expect(_mediaRequests, hasLength(4));
        _assertNoOverflow(tester, c);
      });
    }

    testWidgets(
      'three decoded gallery items retain supplied order without overflow badge',
      (tester) async {
        const c = _Case(600, false, true, 1.3);
        await _pump(
          tester,
          _detail(
            _entity(
              media: [
                gallery('gallery-2'),
                gallery('gallery-0'),
                gallery('gallery-1'),
              ],
            ),
          ),
          c,
        );
        await _settleReferenceImages(tester);
        expect(galleryUrls(tester), [
          'https://owner-qa.invalid/gallery-2',
          'https://owner-qa.invalid/gallery-0',
          'https://owner-qa.invalid/gallery-1',
        ]);
        expect(find.textContaining('+'), findsNothing);
        expect(_mediaRequests, hasLength(3));
        _assertNoOverflow(tester, c);
      },
    );

    testWidgets(
      'duplicate typed URLs are loaded/countable once and remain unambiguous',
      (tester) async {
        const c = _Case(840, true, false, 1.0);
        final media = [
          const CanonicalDirectoryMedia(
            mediaType: 'cover',
            url: 'https://owner-qa.invalid/cover',
          ),
          const CanonicalDirectoryMedia(
            mediaType: 'logo',
            url: 'https://owner-qa.invalid/logo',
          ),
          gallery('gallery-0'),
          gallery('gallery-1'),
          gallery('gallery-2'),
        ];
        await _pump(tester, _detail(_entity(media: [...media, ...media])), c);
        await _settleReferenceImages(tester);
        expect(galleryUrls(tester), hasLength(3));
        expect(
          find.byKey(const Key('cui1-detail-hero-fallback')),
          findsNothing,
        );
        expect(_mediaRequests, hasLength(5));
        expect(_mediaRequests.toSet(), hasLength(5));
        expect(find.textContaining('+'), findsNothing);
        _assertNoOverflow(tester, c);
      },
    );

    testWidgets(
      'HTTP success with undecodable media uses only honest fallback',
      (tester) async {
        const c = _Case(390, true, false, 1.3);
        const url = 'https://owner-qa.invalid/corrupt-image';
        _controlledMedia[url] = Completer<Uint8List?>();
        await _pump(
          tester,
          _detail(
            _entity(
              media: [
                for (final role in ['cover', 'logo', 'gallery'])
                  CanonicalDirectoryMedia(mediaType: role, url: url),
              ],
            ),
          ),
          c,
        );
        _controlledMedia[url]!.complete(Uint8List.fromList([0, 1, 2]));
        await _settleReferenceImages(tester);
        expect(find.byKey(const Key('cui1-detail-gallery')), findsNothing);
        expect(
          find.byKey(const Key('cui1-detail-hero-fallback')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('cui1-detail-avatar')),
            matching: find.byIcon(Icons.apartment),
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.image_outlined), findsNothing);
        expect(
          _mediaRequests,
          [url],
          reason: 'The normal image cache coalesces the shared URL.',
        );
        _assertNoOverflow(tester, c);
      },
    );

    testWidgets(
      'pending/changed gallery input ignores removed stream completion',
      (tester) async {
        const c = _Case(390, true, true, 1.3);
        const first = 'https://owner-qa.invalid/delayed-first';
        const second = 'https://owner-qa.invalid/delayed-second';
        _controlledMedia[first] = Completer<Uint8List?>();
        _controlledMedia[second] = Completer<Uint8List?>();
        var entity = _entity(
          media: [gallery('delayed-first'), gallery('delayed-second')],
        );
        late StateSetter change;
        await _pump(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              change = setState;
              return _detail(entity);
            },
          ),
          c,
        );
        expect(find.byKey(const Key('cui1-detail-gallery')), findsNothing);
        _controlledMedia[first]!.complete(_referenceBytes['gallery-0']);
        await _settleReferenceImages(tester, urls: [first]);
        expect(galleryUrls(tester), [first]);
        expect(
          find.textContaining('+'),
          findsNothing,
          reason: 'Pending media is not counted.',
        );
        debugNetworkImageHttpClientProvider = () => _ReferenceImageClient();
        change(() => entity = _entity(media: [gallery('gallery-2')]));
        await tester.pump();
        _controlledMedia[second]!.complete(null);
        await _settleReferenceImages(tester);
        expect(galleryUrls(tester), ['https://owner-qa.invalid/gallery-2']);
        expect(_mediaRequests, hasLength(3));
        _assertNoOverflow(tester, c);
      },
    );

    testWidgets(
      'entity replacement cannot publish an old pending gallery image',
      (tester) async {
        const c = _Case(1280, false, false, 1.0);
        const oldUrl = 'https://owner-qa.invalid/delayed-old-entity';
        _controlledMedia[oldUrl] = Completer<Uint8List?>();
        var entity = _entity(media: [gallery('delayed-old-entity')]);
        late StateSetter change;
        await _pump(
          tester,
          StatefulBuilder(
            builder: (context, setState) {
              change = setState;
              return _detail(entity);
            },
          ),
          c,
        );
        debugNetworkImageHttpClientProvider = () => _ReferenceImageClient();
        change(
          () => entity = _entity(id: _otherId, media: [gallery('gallery-1')]),
        );
        await tester.pump();
        _controlledMedia[oldUrl]!.complete(_referenceBytes['gallery-0']);
        await _settleReferenceImages(tester);
        expect(galleryUrls(tester), ['https://owner-qa.invalid/gallery-1']);
        expect(
          tester
              .widget<DirectoryProviderDetailScreen>(
                find.byType(DirectoryProviderDetailScreen),
              )
              .entity
              .id,
          _otherId,
        );
        _assertNoOverflow(tester, c);
      },
    );

    for (final succeeds in [true, false]) {
      testWidgets(
        'pending gallery disposed before completion succeeds=$succeeds',
        (tester) async {
          const c = _Case(390, true, true, 1.3);
          const url = 'https://owner-qa.invalid/delayed-dispose';
          _controlledMedia[url] = Completer<Uint8List?>();
          await _pump(
            tester,
            _detail(_entity(media: [gallery('delayed-dispose')])),
            c,
          );
          await tester.pumpWidget(
            const MaterialApp(home: Scaffold(body: Text('disposed fixture'))),
          );
          _controlledMedia[url]!.complete(
            succeeds ? _referenceBytes['gallery-0'] : null,
          );
          await _settleReferenceImages(tester);
          expect(find.byType(DirectoryProviderDetailScreen), findsNothing);
          expect(find.byKey(const Key('cui1-detail-gallery')), findsNothing);
          expect(tester.takeException(), isNull);
          expect(_mediaRequests, [url]);
        },
      );
    }

    testWidgets(
      'successful supplied media confers no verification sponsorship or paid ownership',
      (tester) async {
        const c = _Case(390, false, true, 1.3);
        final store = _SavedStore();
        await _pump(
          tester,
          _detail(_entity(media: _referenceMedia), store: store),
          c,
        );
        await _settleReferenceImages(tester);
        expect(galleryUrls(tester), hasLength(3));
        expect(
          tester
              .widget<DirectoryVerificationBadge>(
                find.byType(DirectoryVerificationBadge),
              )
              .status,
          VerificationStatus.unverified,
        );
        expect(find.byIcon(Icons.verified), findsNothing);
        expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
        expect(find.byIcon(Icons.ads_click_outlined), findsNothing);
        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
        expect(store.refs, isEmpty);
        _assertPublicAuthorityOnly(tester);
        await _bottom(tester);
        expect(find.text(_managementEn), findsOneWidget);
        expect(find.text(_commercialExplanationEn), findsOneWidget);
        _assertNoOverflow(tester, c);
      },
    );

    test('Owner media fixtures and runtime hooks remain absent from production', () {
      for (final path in [
        'lib/features/directory/presentation/directory_landing_screen.dart',
        'lib/features/directory/presentation/directory_search_screen.dart',
        'lib/features/directory/presentation/directory_provider_card.dart',
        'lib/features/directory/presentation/directory_provider_detail_screen.dart',
        'lib/features/directory/presentation/directory_verification_badge.dart',
        'lib/features/directory/presentation/widgets/directory_sponsored_provider_card.dart',
        'lib/localization/ar.dart',
        'lib/localization/en.dart',
      ]) {
        final source = File(path).readAsStringSync();
        for (final marker in [
          'owner-qa.invalid',
          'CIVILPEDIA_DIRECTORY_DEMO',
          'CUI1_OWNER_QA',
          'visual@al-ufuq.example',
          'al-ufuq.example',
          'Al-Ufuq Engineering General Contracting',
        ]) {
          expect(
            source,
            isNot(contains(marker)),
            reason: '$path contains no $marker fixture.',
          );
        }
      }
      expect(File('tool/cui1_directory_owner_demo.dart').existsSync(), isFalse);
    });
    for (final width in [390.0, 600.0, 839.0, 840.0, 1280.0]) {
      for (final arabic in [true, false]) {
        for (final dark in [false, true]) {
          for (final scale in [1.0, 1.3]) {
            final c = _Case(width, arabic, dark, scale);
            testWidgets('reference media ${c.key}', (tester) async {
              final store = _SavedStore();
              final launcher = _Launcher();
              await _pump(
                tester,
                _detail(
                  _ownerPopulatedEntity(arabic: arabic, media: _referenceMedia),
                  store: store,
                  launcher: launcher,
                ),
                c,
                shell: true,
              );
              await _settleReferenceImages(tester);
              final images = tester
                  .widgetList<Image>(find.byType(Image))
                  .toList();
              expect(images, hasLength(5));
              expect(images.map((image) => (image.image as NetworkImage).url), [
                'https://owner-qa.invalid/cover',
                'https://owner-qa.invalid/logo',
                'https://owner-qa.invalid/gallery-0',
                'https://owner-qa.invalid/gallery-1',
                'https://owner-qa.invalid/gallery-2',
              ]);
              expect(
                find.text('+12'),
                findsOneWidget,
                reason:
                    'Fifteen supplied QA rows; exactly three thumbnails are visible.',
              );
              expect(
                find.byKey(const Key('cui1-detail-hero-fallback')),
                findsNothing,
              );
              expect(
                find.byKey(const Key('cui1-detail-gallery')),
                findsOneWidget,
              );
              expect(find.byType(DirectoryVerificationBadge), findsOneWidget);
              expect(find.byIcon(Icons.ads_click_outlined), findsNothing);
              _assertDetailGeometry(tester, c);
              _assertOwnerPolish(tester, c);
              _assertTargets(tester);
              _assertNoOverflow(tester, c);
              await _capture(
                tester,
                'reference-hero-identity-actions',
                c,
                fixture: 'OWNER_REFERENCE_PHOTOS_TEST_ONLY',
              );
              if (scale == 1.0 && arabic && (width == 390 || width == 1280)) {
                await _captureFullReference(tester, c);
              }
              for (final section in [
                'about',
                'gallery',
                'specialties',
                'locations',
                'contacts',
              ]) {
                await tester.ensureVisible(
                  find.byKey(ValueKey('cui1-detail-$section')),
                );
                await tester.pumpAndSettle();
                _assertNoOverflow(tester, c);
                await _capture(
                  tester,
                  'reference-$section',
                  c,
                  fixture: 'OWNER_REFERENCE_PHOTOS_TEST_ONLY',
                );
              }
              await _bottom(tester);
              _assertTargets(tester);
              _assertNoOverflow(tester, c);
              await _capture(
                tester,
                'reference-management-commercial',
                c,
                fixture: 'OWNER_REFERENCE_PHOTOS_TEST_ONLY',
              );
              expect(launcher.phones, isEmpty);
              expect(launcher.whatsApps, isEmpty);
              expect(store.refs, isEmpty);
            });
          }
        }
      }
    }
    for (final arabic in [true, false]) {
      testWidgets(
        'compact contact presentation puts email before website arabic=$arabic',
        (tester) async {
          await _pump(
            tester,
            _detail(
              _entity(
                name: 'TEST POLISH',
                contacts: const [
                  CanonicalDirectoryContact(
                    contactType: 'website',
                    value: 'https://owner-polish.example/long-page',
                  ),
                  CanonicalDirectoryContact(
                    contactType: 'email',
                    value: 'owner-polish@example.invalid',
                  ),
                ],
              ),
            ),
            _Case(390, arabic, true, 1.3),
          );
          final email = find.text('owner-polish@example.invalid');
          final website = find.text('https://owner-polish.example/long-page');
          expect(email, findsOneWidget);
          expect(website, findsOneWidget);
          expect(
            tester.getRect(email).top,
            lessThan(tester.getRect(website).top),
          );
          expect(find.byKey(const Key('cui1-quick-call')), findsNothing);
          expect(find.byKey(const Key('cui1-quick-whatsapp')), findsNothing);
          _assertNoOverflow(tester, _Case(390, arabic, true, 1.3));
        },
      );
    }
    for (final media in <List<CanonicalDirectoryMedia>>[
      const [],
      const [CanonicalDirectoryMedia(mediaType: 'gallery', url: '')],
      const [
        CanonicalDirectoryMedia(mediaType: 'cover', url: 'https:///cover'),
      ],
      const [CanonicalDirectoryMedia(mediaType: 'logo', url: 'https://[')],
      const [CanonicalDirectoryMedia(url: 'https://owner-qa.invalid/cover')],
      const [
        CanonicalDirectoryMedia(
          mediaType: 'video',
          url: 'https://owner-qa.invalid/cover',
        ),
      ],
      const [
        CanonicalDirectoryMedia(
          mediaType: 'cover',
          url: 'http://owner-qa.invalid/cover',
        ),
      ],
      const [
        CanonicalDirectoryMedia(
          mediaType: 'logo',
          url: 'https://user:secret@owner-qa.invalid/logo',
        ),
      ],
      const [
        CanonicalDirectoryMedia(
          mediaType: 'gallery',
          url: 'file:///tmp/photo.png',
        ),
      ],
      const [
        CanonicalDirectoryMedia(
          mediaType: 'gallery',
          url: 'https://owner-qa.invalid/gallery-0#fragment',
        ),
      ],
    ]) {
      testWidgets(
        'unusable media omitted ${jsonEncode(media.map((m) => m.toJson()).toList())}',
        (tester) async {
          const c = _Case(390, true, false, 1.3);
          await _pump(tester, _detail(_ownerPopulatedEntity(media: media)), c);
          expect(find.byType(Image), findsNothing);
          expect(_mediaRequests, isEmpty);
          expect(
            find.byKey(const Key('cui1-detail-hero-fallback')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('cui1-detail-gallery')), findsNothing);
          _assertPublicAuthorityOnly(tester);
          await _capture(
            tester,
            'reference-no-media',
            c,
            state:
                'safe-fallback-${media.isEmpty ? 'empty' : media.first.mediaType ?? 'untyped'}',
          );
        },
      );
    }
    testWidgets(
      'multiple distinct logos/covers do not imply a brand selection',
      (tester) async {
        const c = _Case(390, true, false, 1.0);
        await _pump(
          tester,
          _detail(
            _ownerPopulatedEntity(
              media: const [
                CanonicalDirectoryMedia(
                  mediaType: 'cover',
                  url: 'https://owner-qa.invalid/cover',
                ),
                CanonicalDirectoryMedia(
                  mediaType: 'cover',
                  url: 'https://owner-qa.invalid/second-cover',
                ),
                CanonicalDirectoryMedia(
                  mediaType: 'logo',
                  url: 'https://owner-qa.invalid/logo',
                ),
                CanonicalDirectoryMedia(
                  mediaType: 'logo',
                  url: 'https://owner-qa.invalid/second-logo',
                ),
              ],
            ),
          ),
          c,
        );
        expect(find.byType(Image), findsNothing);
        expect(_mediaRequests, isEmpty);
        expect(
          find.byKey(const Key('cui1-detail-hero-fallback')),
          findsOneWidget,
        );
      },
    );
    testWidgets(
      'network image failures retain the layout without raw errors or Retry',
      (tester) async {
        const c = _Case(390, true, true, 1.3);
        await _pump(
          tester,
          _detail(
            _ownerPopulatedEntity(
              media: const [
                CanonicalDirectoryMedia(
                  mediaType: 'cover',
                  url: 'https://owner-qa.invalid/missing',
                ),
                CanonicalDirectoryMedia(
                  mediaType: 'gallery',
                  url: 'https://owner-qa.invalid/missing-photo',
                ),
              ],
            ),
          ),
          c,
        );
        await _settleReferenceImages(tester);
        expect(
          find.byKey(const Key('cui1-detail-hero-fallback')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('cui1-detail-gallery')), findsNothing);
        expect(find.byIcon(Icons.image_outlined), findsNothing);
        expect(find.textContaining('404'), findsNothing);
        expect(find.textContaining('owner-qa.invalid'), findsNothing);
        expect(find.byIcon(Icons.refresh), findsNothing);
        _assertNoOverflow(tester, c);
      },
    );
    for (final arabic in [true, false]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets(
          'quick actions preserve direction, payloads and local Saved arabic=$arabic scale=$scale',
          (tester) async {
            final c = _Case(390, arabic, false, scale);
            final launcher = _Launcher();
            final store = _SavedStore();
            await _pump(
              tester,
              _detail(
                _ownerPopulatedEntity(arabic: arabic),
                launcher: launcher,
                store: store,
              ),
              c,
            );
            final call = find.byKey(const Key('cui1-quick-call'));
            final whatsapp = find.byKey(const Key('cui1-quick-whatsapp'));
            final save = find.byKey(const Key('cui1-detail-save'));
            final callRect = tester.getRect(call);
            final whatsappRect = tester.getRect(whatsapp);
            final saveRect = tester.getRect(save);
            expect(callRect.top, closeTo(saveRect.top, 0.1));
            expect(callRect.height, closeTo(whatsappRect.height, 0.1));
            expect(callRect.height, closeTo(saveRect.height, 0.1));
            expect(
              arabic ? callRect.left : saveRect.left,
              greaterThan(whatsappRect.right),
            );
            expect(
              whatsappRect.left,
              greaterThan(arabic ? saveRect.right : callRect.right),
            );
            await tester.tap(call);
            await tester.tap(whatsapp);
            await tester.tap(save);
            await tester.pumpAndSettle();
            expect(launcher.phones, ['07701234567']);
            expect(launcher.whatsApps, ['9647801234567']);
            expect(store.refs.single.entityId, _ownerBusinessId);
            expect(find.byIcon(Icons.bookmark), findsOneWidget);
            _assertTargets(tester);
          },
        );
      }
    }
  });

  group('CUI-1 mandatory public-detail rendering grid', () {
    for (final arabic in [true, false]) {
      testWidgets('loaded detail Back scrolls with hero arabic=$arabic', (
        tester,
      ) async {
        final entity = _ownerPopulatedEntity(arabic: arabic);
        final router = GoRouter(
          initialLocation: '/directory/entity/$_ownerBusinessId',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) =>
                  const Scaffold(body: Text('TEST_BACK_DESTINATION')),
              routes: [
                GoRoute(
                  path: 'directory/entity/:id',
                  builder: (_, state) => DirectoryProviderDetailResolver(
                    entityId: state.pathParameters['id']!,
                    repository: _Repository(entities: [entity]),
                    savedReferenceStore: _SavedStore(),
                  ),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await _pump(
          tester,
          const SizedBox.shrink(),
          _Case(390, arabic, false, 1.3),
          router: router,
        );
        final back = find.byType(BackButton);
        final hero = find.byKey(const Key('cui1-detail-hero'));
        expect(back.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(hero).contains(tester.getRect(back).center),
          isTrue,
        );
        await _bottom(tester);
        expect(back.hitTestable(), findsNothing);
        expect(find.byType(AppBar), findsNothing);
        await tester.ensureVisible(hero);
        await tester.pumpAndSettle();
        await tester.tap(back);
        await tester.pumpAndSettle();
        expect(find.text('TEST_BACK_DESTINATION'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
    for (final width in [390.0, 600.0, 839.0, 840.0, 1280.0]) {
      for (final arabic in [true, false]) {
        for (final dark in [false, true]) {
          for (final scale in [1.0, 1.3]) {
            final c = _Case(width, arabic, dark, scale);
            testWidgets('detail stress ${c.key}', (tester) async {
              await _pump(tester, _detail(_entity()), c, shell: true);
              expect(
                Directionality.of(
                  tester.element(find.byType(DirectoryProviderDetailScreen)),
                ),
                arabic ? TextDirection.rtl : TextDirection.ltr,
              );
              expect(find.text(_longName), findsAtLeastNWidgets(1));
              expect(find.byType(DirectoryVerificationBadge), findsOneWidget);
              expect(
                find.text(
                  arabic
                      ? 'حالة التوثيق المسجّلة في الدليل؛ لا تعني ضمان جودة العمل أو حالة الاشتراك.'
                      : 'The verification status recorded in the Directory does not guarantee work quality or indicate subscription status.',
                ),
                findsOneWidget,
              );
              _assertTargets(tester);
              _assertDetailGeometry(tester, c);
              _assertPublicAuthorityOnly(tester);
              await _capture(tester, 'detail', c);
              await tester.ensureVisible(
                find.byKey(const Key('cui1-detail-locations')),
              );
              await tester.pumpAndSettle();
              _assertNoOverflow(tester, c);
              await _capture(tester, 'detail-locations', c);
              await _bottom(tester);
              expect(
                find.text(arabic ? _managementAr : _managementEn),
                findsOneWidget,
              );
              expect(
                find.text(arabic ? _commercialAr : _commercialEn),
                findsOneWidget,
              );
              expect(
                find.text(
                  arabic ? _commercialExplanationAr : _commercialExplanationEn,
                ),
                findsOneWidget,
              );
              final manageRect = tester.getRect(
                _buttonWith(arabic ? _managementAr : _managementEn),
              );
              expect(
                manageRect.bottom,
                lessThanOrEqualTo(1000 - 92),
                reason: 'Final management action clears shell obstruction.',
              );
              expect(manageRect.top, greaterThanOrEqualTo(0));
              _assertTargets(tester);
              _assertNoOverflow(tester, c);
              await _capture(tester, 'detail-final-actions', c);
            });
          }
        }
      }
    }
  });

  group('CUI-1 landing and organic search rendering matrix', () {
    for (final width in [390.0, 600.0, 839.0, 840.0, 1280.0]) {
      for (final arabic in [true, if (width == 390 || width == 1280) false]) {
        for (final dark in [false, true]) {
          final c = _Case(width, arabic, dark, 1.3);
          testWidgets('landing ${c.key}', (tester) async {
            await _pump(
              tester,
              DirectoryLandingScreen(onCategorySelected: (_) {}),
              c,
              shell: true,
            );
            expect(find.byType(DirectoryProviderCard), findsNothing);
            expect(find.byType(DirectoryVerificationBadge), findsNothing);
            _assertTargets(tester);
            _assertLandingGeometry(tester, c);
            await _capture(
              tester,
              'landing',
              c,
              fixture: 'canonical-nine-taxonomy-types',
            );
            await _bottom(tester);
            _assertNoOverflow(tester, c);
          });
          testWidgets('organic search ${c.key}', (tester) async {
            final first = _entity(
              name: 'TEST FIRST — شركة الاختبار الأولى',
              description: null,
            );
            final second = _entity(
              id: _otherId,
              name: 'TEST SECOND — شركة الاختبار الثانية',
              description: null,
              verification: VerificationStatus.verified,
            );
            await _pump(
              tester,
              DirectorySearchScreen(
                repository: _Repository(entities: [first, second]),
              ),
              c,
            );
            expect(
              find.byType(DirectorySponsoredProviderCard),
              findsNothing,
              reason:
                  'Production search remains organic and empty campaigns stay empty.',
            );
            final cards = tester
                .widgetList<DirectoryProviderCard>(
                  find.byType(DirectoryProviderCard),
                )
                .toList();
            expect(cards.map((e) => e.entity.id).toList(), [_id, _otherId]);
            final filters = find.byType(DropdownButtonFormField<String?>);
            _assertFilterLabelGeometry(tester, c);
            final firstHeight = tester.getSize(filters.first).height;
            for (var index = 1; index < filters.evaluate().length; index++) {
              expect(
                tester.getSize(filters.at(index)).height,
                closeTo(firstHeight, 0.1),
                reason:
                    'Unselected long options do not inflate closed All fields.',
              );
            }
            for (final card in find.byType(DirectoryProviderCard).evaluate()) {
              expect(
                tester.getSize(find.byWidget(card.widget)).width,
                lessThanOrEqualTo(760),
              );
            }
            _assertTargets(tester);
            await _capture(
              tester,
              'organic-search',
              c,
              fixture: 'two-canonical-organic-entities-order-pinned',
            );
          });
        }
      }
    }
  });

  group('CUI-1 Owner correction empty/error/no-match separation', () {
    for (final width in [390.0, 840.0]) {
      for (final arabic in [true, false]) {
        for (final dark in [false, true]) {
          final c = _Case(width, arabic, dark, 1.3);
          for (final outcome in [
            'authoritative-empty',
            'success-empty',
            'service-failure',
            'no-match',
          ]) {
            testWidgets('$outcome ${c.key}', (tester) async {
              final _Repository repository = outcome == 'success-empty'
                  ? _SuccessfulEmptyRepository()
                  : _Repository(
                      entities: outcome == 'no-match'
                          ? [_entity(name: 'OWNER_CORRECTION_ENTITY')]
                          : [],
                      status: outcome == 'service-failure'
                          ? DirectoryRefreshStatus.serviceUnavailable
                          : outcome == 'authoritative-empty'
                          ? DirectoryRefreshStatus.authoritativeEmpty
                          : DirectoryRefreshStatus.success,
                    );
              await _pump(
                tester,
                DirectorySearchScreen(repository: repository),
                c,
              );
              if (outcome == 'no-match') {
                await tester.enterText(
                  find.byType(TextField),
                  'NO_MATCH_OWNER_CORRECTION',
                );
                await tester.pump(const Duration(milliseconds: 300));
              }
              final emptyCopy = arabic
                  ? 'لا توجد جهات مضافة حاليًا'
                  : 'No entries have been added yet';
              final noMatchCopy = arabic
                  ? 'لا توجد نتائج مطابقة'
                  : 'No matching results';
              final retryCopy = arabic ? 'إعادة المحاولة' : 'Retry';
              if (outcome.endsWith('empty')) {
                expect(find.text(emptyCopy), findsOneWidget);
                expect(
                  find.byKey(const Key('cui1-directory-empty')),
                  findsOneWidget,
                );
                expect(find.text(noMatchCopy), findsNothing);
                expect(find.text(retryCopy), findsNothing);
                expect(find.byType(RemoteDataNotice), findsNothing);
                expect(find.byIcon(Icons.refresh_rounded), findsNothing);
              } else if (outcome == 'no-match') {
                expect(find.text(noMatchCopy), findsOneWidget);
                expect(
                  find.byKey(const Key('cui1-directory-no-match')),
                  findsOneWidget,
                );
                expect(find.text(emptyCopy), findsNothing);
                expect(find.text(retryCopy), findsNothing);
                expect(find.byType(RemoteDataNotice), findsNothing);
                expect(find.byType(DirectoryProviderCard), findsNothing);
              } else {
                expect(find.byType(RemoteDataNotice), findsOneWidget);
                expect(
                  tester
                      .widget<RemoteDataNotice>(find.byType(RemoteDataNotice))
                      .cause,
                  RemoteDataCause.serviceUnavailable,
                );
                expect(
                  find.text(
                    arabic
                        ? 'الخدمة غير متاحة مؤقتاً'
                        : 'Service temporarily unavailable',
                  ),
                  findsOneWidget,
                );
                expect(find.text(retryCopy), findsOneWidget);
                expect(find.text(emptyCopy), findsNothing);
                expect(find.text(noMatchCopy), findsNothing);
                await tester.tap(find.text(retryCopy));
                await tester.pumpAndSettle();
                expect(repository.refreshCalls, 2);
                expect(find.byType(RemoteDataNotice), findsOneWidget);
              }
              _assertFilterLabelGeometry(tester, c);
              _assertTargets(tester);
              _assertNoOverflow(tester, c);
              expect(
                tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
                isNull,
              );
              await _capture(
                tester,
                'owner-correction-search-state',
                c,
                state: outcome,
                fixture: 'existing-typed-directory-outcomes-test-only',
              );
            });
          }
        }
      }
    }
  });

  group('CUI-1 distinct verification and Sponsored render evidence', () {
    const labelsAr = {
      VerificationStatus.unverified: 'غير موثّق',
      VerificationStatus.pending: 'قيد المراجعة',
      VerificationStatus.verified: 'موثّق',
      VerificationStatus.rejected: 'مرفوض',
      VerificationStatus.suspended: 'موقوف',
    };
    const labelsEn = {
      VerificationStatus.unverified: 'Unverified',
      VerificationStatus.pending: 'Pending review',
      VerificationStatus.verified: 'Verified',
      VerificationStatus.rejected: 'Rejected',
      VerificationStatus.suspended: 'Suspended',
    };
    for (final width in [390.0, 840.0]) {
      for (final dark in [false, true]) {
        final c = _Case(width, true, dark, 1.3);
        for (final status in VerificationStatus.values) {
          testWidgets('verification ${status.name} ${c.key}', (tester) async {
            await _pump(
              tester,
              _detail(
                _entity(name: 'اختبار حالة الدليل', verification: status),
              ),
              c,
            );
            expect(find.text(labelsAr[status]!), findsOneWidget);
            expect(
              find.byIcon(Icons.verified),
              status == VerificationStatus.verified
                  ? findsOneWidget
                  : findsNothing,
            );
            _assertTargets(tester);
            await _capture(
              tester,
              'detail-verification',
              c,
              state: status.name,
            );
          });
        }
      }
    }
    for (final width in [390.0, 840.0, 1280.0]) {
      for (final dark in [false, true]) {
        final c = _Case(width, width != 1280, dark, 1.3);
        for (final sponsored in [false, true]) {
          for (final verified in [false, true]) {
            final state =
                '${sponsored ? 'sponsored' : 'organic'}_${verified ? 'verified' : 'unverified'}';
            testWidgets('$state ${c.key}', (tester) async {
              final entity = _entity(
                name: 'CUI1 اختبار استقلال الإعلان والتوثيق',
                verification: verified
                    ? VerificationStatus.verified
                    : VerificationStatus.unverified,
              );
              final placement = _placement(entity, c.arabic);
              await _pump(
                tester,
                Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: sponsored
                            ? DirectorySponsoredProviderCard(
                                entity: entity,
                                placement: placement,
                                onTap: () {},
                              )
                            : DirectoryProviderCard(
                                entity: entity,
                                onTap: () {},
                              ),
                      ),
                    ),
                  ),
                ),
                c,
              );
              expect(
                find.text(
                  (c.arabic ? labelsAr : labelsEn)[entity.verificationStatus]!,
                ),
                findsOneWidget,
              );
              expect(
                find.text(placement.disclosureLabel),
                sponsored ? findsOneWidget : findsNothing,
              );
              expect(
                find.byIcon(Icons.ads_click_outlined),
                sponsored ? findsOneWidget : findsNothing,
              );
              expect(
                find.byIcon(Icons.verified),
                verified ? findsOneWidget : findsNothing,
              );
              _assertPublicAuthorityOnly(tester);
              await _capture(
                tester,
                'advertisement-independence',
                c,
                state: state,
                fixture: 'isolated-wrapper-only-not-production-campaign',
              );
            });
          }
        }
      }
    }
  });

  group('CUI-1 typed state render evidence', () {
    for (final width in [390.0, 840.0]) {
      for (final dark in [false, true]) {
        final c = _Case(width, true, dark, 1.3);
        for (final state in [
          'loading',
          'empty',
          'no-match',
          'error',
          'stale',
          'cache-pending',
        ]) {
          testWidgets('search $state ${c.key}', (tester) async {
            final gate = (state == 'loading' || state == 'cache-pending')
                ? Completer<void>()
                : null;
            final entity = _entity(name: 'CUI1 cached public identity');
            final repo = _Repository(
              entities:
                  state == 'empty' || state == 'loading' || state == 'error'
                  ? []
                  : [entity],
              cached: state == 'stale' || state == 'cache-pending'
                  ? DirectoryCachedData(
                      entities: [entity],
                      refreshedAt: DateTime.utc(2026, 10, 1),
                    )
                  : null,
              status: state == 'error' || state == 'stale'
                  ? DirectoryRefreshStatus.network
                  : DirectoryRefreshStatus.success,
              gate: gate,
            );
            await _pump(
              tester,
              DirectorySearchScreen(repository: repo),
              c,
              settle: gate == null,
            );
            if (state == 'no-match') {
              await tester.enterText(
                find.byType(TextField).first,
                'UNMATCHED_CUI1_TOKEN',
              );
              await tester.pump(const Duration(milliseconds: 300));
              expect(find.text('لا توجد نتائج مطابقة'), findsOneWidget);
            } else if (state == 'empty') {
              expect(find.text('لا توجد جهات مضافة حاليًا'), findsOneWidget);
            } else if (state == 'loading') {
              expect(find.byType(CircularProgressIndicator), findsOneWidget);
            } else if (state == 'stale' || state == 'error') {
              expect(find.byType(RemoteDataNotice), findsOneWidget);
              expect(
                tester
                    .widget<RemoteDataNotice>(find.byType(RemoteDataNotice))
                    .cause,
                RemoteDataCause.network,
              );
              expect(
                find.byType(DirectoryProviderCard),
                state == 'stale' ? findsOneWidget : findsNothing,
              );
            } else if (state == 'cache-pending') {
              expect(find.text(entity.name), findsOneWidget);
              expect(find.byType(CircularProgressIndicator), findsNothing);
              expect(find.text('جاري تحديث بيانات الدليل'), findsOneWidget);
            }
            _assertTargets(tester);
            _assertNoOverflow(tester, c);
            await _capture(tester, 'search-state', c, state: state);
            gate?.complete();
            await tester.pumpAndSettle();
          });
        }
        for (final state in [
          'loading',
          'pending-seed',
          'authoritative-unavailable',
          'invalid-id',
          'unresolved-error',
        ]) {
          testWidgets('detail resolver $state ${c.key}', (tester) async {
            final gate = state == 'pending-seed' || state == 'loading'
                ? Completer<void>()
                : null;
            final entity = _entity(name: 'TEST SEED IDENTITY');
            final repo = _Repository(
              gate: gate,
              status: state == 'unresolved-error'
                  ? DirectoryRefreshStatus.timeout
                  : DirectoryRefreshStatus.success,
            );
            await _pump(
              tester,
              DirectoryProviderDetailResolver(
                entityId: state == 'invalid-id' ? 'invalid-id' : _id,
                repository: repo,
                seedEntity:
                    state == 'pending-seed' ||
                        state == 'authoritative-unavailable'
                    ? entity
                    : null,
                savedReferenceStore: _SavedStore(),
              ),
              c,
              settle: gate == null,
            );
            if (state == 'loading') {
              expect(find.byType(CircularProgressIndicator), findsOneWidget);
              expect(find.byType(AppBar), findsOneWidget);
            } else if (state == 'pending-seed') {
              expect(find.text(entity.name), findsAtLeastNWidgets(1));
              expect(
                tester
                    .widget<DirectoryProviderDetailScreen>(
                      find.byType(DirectoryProviderDetailScreen),
                    )
                    .isUpdating,
                isTrue,
              );
              expect(find.text('جاري تحديث بيانات الدليل'), findsOneWidget);
            } else if (state == 'authoritative-unavailable') {
              expect(
                find.text(entity.name),
                findsNothing,
                reason: 'Authority removes stale seed identity.',
              );
              expect(find.byType(DirectoryProviderDetailScreen), findsNothing);
            } else if (state == 'invalid-id') {
              expect(repo.refreshCalls, 0);
              expect(find.text('معرّف غير صالح'), findsOneWidget);
            } else {
              expect(find.byType(RemoteDataNotice), findsOneWidget);
              expect(
                tester
                    .widget<RemoteDataNotice>(find.byType(RemoteDataNotice))
                    .cause,
                RemoteDataCause.timeout,
              );
            }
            _assertTargets(tester);
            await _capture(tester, 'detail-state', c, state: state);
            gate?.complete();
            await tester.pumpAndSettle();
          });
        }
        testWidgets(
          'detail stale failure retains snapshot and reachable retry ${c.key}',
          (tester) async {
            final entity = _entity(name: 'TEST STALE DETAIL');
            final repo = _Repository(
              entities: [entity],
              cached: DirectoryCachedData(
                entities: [entity],
                refreshedAt: DateTime.utc(2026, 10, 1),
              ),
              status: DirectoryRefreshStatus.network,
            );
            await _pump(
              tester,
              DirectoryProviderDetailResolver(
                entityId: _id,
                repository: repo,
                savedReferenceStore: _SavedStore(),
              ),
              c,
            );
            expect(find.text(entity.name), findsAtLeastNWidgets(1));
            expect(
              find.text('قد تكون البيانات المعروضة غير محدثة'),
              findsOneWidget,
            );
            expect(
              tester
                  .widget<RemoteDataNotice>(find.byType(RemoteDataNotice))
                  .cause,
              RemoteDataCause.network,
            );
            _assertTargets(tester);
            await _capture(
              tester,
              'detail-state',
              c,
              state: 'stale-failed-refresh',
            );
            repo.status = DirectoryRefreshStatus.success;
            await tester.tap(find.text('إعادة المحاولة'));
            await tester.pumpAndSettle();
            expect(repo.refreshCalls, 2);
            expect(find.byType(RemoteDataNotice), findsNothing);
          },
        );
        testWidgets('partial and repeated locations ${c.key}', (tester) async {
          await _pump(
            tester,
            _detail(
              _entity(
                description: null,
                categories: [],
                locations: const [
                  CanonicalDirectoryLocation(
                    regionCode: '',
                    address: 'Repeated test address',
                  ),
                  CanonicalDirectoryLocation(
                    regionCode: '',
                    address: 'Repeated test address',
                  ),
                  CanonicalDirectoryLocation(
                    regionCode: 'BGD',
                    regionNameAr: 'بغداد',
                    isPrimary: true,
                  ),
                  CanonicalDirectoryLocation(regionCode: ''),
                ],
              ),
            ),
            c,
          );
          expect(find.text('المواقع'), findsOneWidget);
          expect(find.text('Repeated test address'), findsNWidgets(2));
          expect(find.text('الموقع الرئيسي'), findsOneWidget);
          expect(find.text('الفروع'), findsNothing);
          expect(find.byIcon(Icons.phone), findsNothing);
          expect(find.byIcon(Icons.chat), findsNothing);
          await _capture(
            tester,
            'detail-partial-locations',
            c,
            state: 'missing-contacts-and-description',
          );
          await _bottom(tester);
          _assertNoOverflow(tester, c);
          _assertTargets(tester);
          await _capture(
            tester,
            'detail-partial-final',
            c,
            state: 'missing-contacts-and-description',
          );
        });
      }
    }
  });

  group('CUI-1 Owner populated business visual fixture', () {
    const detailCases = [
      _Case(390, true, false, 1.0),
      _Case(390, true, true, 1.0),
      _Case(390, true, false, 1.3),
      _Case(390, true, true, 1.3),
      _Case(1280, true, false, 1.0),
      _Case(1280, true, true, 1.0),
      _Case(1280, true, false, 1.3),
      _Case(1280, true, true, 1.3),
      _Case(390, false, false, 1.3),
      _Case(390, false, true, 1.3),
      _Case(1280, false, false, 1.3),
      _Case(1280, false, true, 1.3),
    ];
    for (final c in detailCases) {
      testWidgets('populated detail ${c.key}', (tester) async {
        final entity = _ownerPopulatedEntity(arabic: c.arabic);
        final store = _SavedStore();
        final launcher = _Launcher();
        await _pump(
          tester,
          _detail(entity, store: store, launcher: launcher),
          c,
          shell: true,
        );
        expect(find.text(entity.name), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.verified), findsOneWidget);
        expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
        expect(find.byIcon(Icons.ads_click_outlined), findsNothing);
        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
        _assertDetailGeometry(tester, c);
        _assertOwnerPolish(tester, c);
        _assertTargets(tester);
        _assertPublicAuthorityOnly(tester);
        await _capture(
          tester,
          'owner-business-detail',
          c,
          state: 'organic-verified-unsaved',
          fixture: 'owner-al-ufuq-test-only',
        );

        var saved = false;
        if (c.arabic && c.width == 390 && c.scale == 1.0) {
          await tester.tap(find.byKey(const Key('cui1-detail-save')));
          await tester.pumpAndSettle();
          expect(store.refs, hasLength(1));
          expect(store.refs.single.entityId, _ownerBusinessId);
          expect(store.refs.single.ownerDomain, SavedReferenceOwners.directory);
          expect(find.byIcon(Icons.bookmark), findsOneWidget);
          saved = true;
          await _capture(
            tester,
            'owner-business-detail',
            c,
            state: 'organic-verified-saved',
            fixture: 'owner-al-ufuq-test-only',
          );
        }
        final sectionState = 'organic-verified-${saved ? 'saved' : 'unsaved'}';
        for (final address in ['بغداد — الجادرية', 'بغداد — الكرادة']) {
          await _assertScrollReachable(tester, find.text(address));
        }
        _assertNoOverflow(tester, c);
        await _capture(
          tester,
          'owner-business-locations',
          c,
          state: sectionState,
          fixture: 'owner-al-ufuq-two-supplied-locations',
        );

        await tester.ensureVisible(
          find.byKey(const Key('cui1-detail-contacts')),
        );
        await tester.pumpAndSettle();
        expect(find.text('07701234567'), findsOneWidget);
        expect(find.text('9647801234567'), findsOneWidget);
        expect(find.text('visual@al-ufuq.example'), findsOneWidget);
        expect(find.text('https://al-ufuq.example'), findsOneWidget);
        expect(launcher.phones, isEmpty);
        expect(launcher.whatsApps, isEmpty);
        _assertTargets(tester);
        _assertNoOverflow(tester, c);
        await _capture(
          tester,
          'owner-business-contacts',
          c,
          state: sectionState,
          fixture: 'owner-al-ufuq-injected-contacts-only',
        );

        for (final value in [
          '07701234567',
          '9647801234567',
          'visual@al-ufuq.example',
          'https://al-ufuq.example',
        ]) {
          await _assertScrollReachable(tester, find.text(value));
        }
        for (final value in ['07701234567', '9647801234567']) {
          final button = find.ancestor(
            of: find.text(value),
            matching: find.byType(OutlinedButton),
          );
          await _assertScrollReachable(tester, button);
          await tester.tap(button);
          await tester.pumpAndSettle();
        }
        expect(launcher.phones, ['07701234567']);
        expect(launcher.whatsApps, ['9647801234567']);

        await _bottom(tester);
        await _assertScrollReachable(
          tester,
          find.byKey(const Key('cui1-detail-management')),
        );
        expect(
          find.text(c.arabic ? _managementAr : _managementEn),
          findsOneWidget,
        );
        expect(
          find.text(
            c.arabic ? _commercialExplanationAr : _commercialExplanationEn,
          ),
          findsOneWidget,
        );
        _assertTargets(tester);
        _assertNoOverflow(tester, c);
        await _capture(
          tester,
          'owner-business-final-actions',
          c,
          state: sectionState,
          fixture: 'owner-al-ufuq-viewer-management-neutral-info',
        );
      });
    }

    for (final c in const [
      _Case(390, true, false, 1.0),
      _Case(390, true, true, 1.0),
      _Case(1280, true, false, 1.3),
      _Case(390, false, false, 1.3),
    ]) {
      testWidgets('populated organic search ${c.key}', (tester) async {
        final entity = _ownerPopulatedEntity(arabic: c.arabic);
        await _pump(
          tester,
          DirectorySearchScreen(repository: _Repository(entities: [entity])),
          c,
        );
        expect(
          tester
              .widget<DirectoryProviderCard>(find.byType(DirectoryProviderCard))
              .entity
              .id,
          _ownerBusinessId,
        );
        expect(find.byIcon(Icons.verified), findsOneWidget);
        expect(find.byType(DirectorySponsoredProviderCard), findsNothing);
        expect(find.byIcon(Icons.ads_click_outlined), findsNothing);
        _assertFilterLabelGeometry(tester, c);
        _assertTargets(tester);
        _assertNoOverflow(tester, c);
        await _capture(
          tester,
          'owner-business-search',
          c,
          state: 'organic-verified',
          fixture: 'owner-al-ufuq-organic-only',
        );
      });
    }

    for (final dark in [false, true]) {
      final cardCase = _Case(390, true, dark, 1.0);
      testWidgets('populated organic provider card ${cardCase.key}', (
        tester,
      ) async {
        await _pump(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DirectoryProviderCard(
                entity: _ownerPopulatedEntity(),
                onTap: () {},
              ),
            ),
          ),
          cardCase,
        );
        expect(find.byIcon(Icons.verified), findsOneWidget);
        expect(find.byIcon(Icons.ads_click_outlined), findsNothing);
        _assertTargets(tester);
        await _capture(
          tester,
          'owner-business-card',
          cardCase,
          state: 'organic-verified',
          fixture: 'owner-al-ufuq-organic-only',
        );
      });
      for (final verification in [
        VerificationStatus.unverified,
        VerificationStatus.verified,
      ]) {
        final c = _Case(390, true, dark, 1.3);
        testWidgets('populated Sponsored ${verification.name} ${c.key}', (
          tester,
        ) async {
          final entity = _ownerPopulatedEntity(verification: verification);
          final placement = _placement(entity, true);
          await _pump(
            tester,
            Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DirectorySponsoredProviderCard(
                  entity: entity,
                  placement: placement,
                  onTap: () {},
                ),
              ),
            ),
            c,
          );
          expect(find.text(placement.disclosureLabel), findsOneWidget);
          expect(find.text('إعلان مدفوع'), findsOneWidget);
          expect(
            find.text(
              verification == VerificationStatus.verified
                  ? 'موثّق'
                  : 'غير موثّق',
            ),
            findsOneWidget,
          );
          expect(
            find.byIcon(Icons.verified),
            verification == VerificationStatus.verified
                ? findsOneWidget
                : findsNothing,
          );
          _assertTargets(tester);
          _assertNoOverflow(tester, c);
          await _capture(
            tester,
            'owner-business-sponsored-variant',
            c,
            state: 'sponsored-${verification.name}',
            fixture: 'owner-al-ufuq-isolated-paid-wrapper-test-only',
          );
        });
      }
    }
  });

  group('CUI-1 contact, Saved and management behavioral boundaries', () {
    test(
      'generic management route is accepted by the existing auth-return allowlist',
      () {
        expect(
          AuthReturnDestination.resolve(AppRoutes.businessManage),
          '/business/manage',
        );
      },
    );

    testWidgets(
      'last nonempty WhatsApp value controls availability without country inference',
      (tester) async {
        const c = _Case(390, true, false, 1.3);
        await _pump(
          tester,
          _detail(
            _entity(
              description: null,
              categories: [],
              locations: [],
              contacts: const [
                CanonicalDirectoryContact(
                  contactType: 'whatsapp',
                  value: '07801234567',
                ),
                CanonicalDirectoryContact(
                  contactType: 'whatsapp',
                  value: 'no ASCII digits',
                ),
                CanonicalDirectoryContact(
                  contactType: 'whatsapp',
                  value: '   ',
                ),
              ],
            ),
          ),
          c,
        );
        expect(find.byIcon(Icons.chat), findsNothing);
        expect(find.text('لا تتوفر معلومات اتصال'), findsOneWidget);
      },
    );

    testWidgets(
      'seedless detail loading retains pushed-route back navigation',
      (tester) async {
        final gate = Completer<void>();
        final repo = _Repository(gate: gate);
        final router = GoRouter(
          initialLocation: '/directory/entity/$_id',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) =>
                  const Scaffold(body: Text('TEST_BACK_DESTINATION')),
              routes: [
                GoRoute(
                  path: 'directory/entity/:id',
                  builder: (_, state) => DirectoryProviderDetailResolver(
                    entityId: state.pathParameters['id']!,
                    repository: repo,
                    savedReferenceStore: _SavedStore(),
                  ),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await _pump(
          tester,
          const SizedBox.shrink(),
          const _Case(390, true, false, 1.3),
          router: router,
          settle: false,
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('TEST_BACK_DESTINATION'), findsOneWidget);
        gate.complete();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'plain email website other remain selectable text; exact phone/WhatsApp projections',
      (tester) async {
        final launcher = _Launcher();
        final entity = _entity(
          name: 'Contact Test',
          description: null,
          categories: [],
          locations: [],
          contacts: const [
            CanonicalDirectoryContact(
              contactType: 'phone',
              value: ' 0770 123 4567 ',
            ),
            CanonicalDirectoryContact(
              contactType: 'telephone',
              value: '+964 780 123 4567',
            ),
            CanonicalDirectoryContact(contactType: 'phone', value: '   '),
            CanonicalDirectoryContact(
              contactType: 'whatsapp',
              value: 'old 123',
            ),
            CanonicalDirectoryContact(
              contactType: 'whatsapp',
              value: '+964 (781) 234 5678',
            ),
            CanonicalDirectoryContact(
              contactType: 'email',
              value: 'engineer@example.test',
            ),
            CanonicalDirectoryContact(
              contactType: 'website',
              value: 'javascript:TEST_ONLY_SCHEME',
            ),
            CanonicalDirectoryContact(
              contactType: 'other',
              value: 'Civil Test contact value',
            ),
          ],
        );
        const c = _Case(390, true, false, 1.3);
        await _pump(tester, _detail(entity, launcher: launcher), c);
        for (final value in [
          'engineer@example.test',
          'javascript:TEST_ONLY_SCHEME',
          'Civil Test contact value',
        ]) {
          expect(
            find.byWidgetPredicate(
              (w) => w is SelectableText && w.data == value,
            ),
            findsOneWidget,
          );
        }
        await tester.ensureVisible(find.textContaining('0770 123 4567'));
        await tester.tap(find.textContaining('0770 123 4567'));
        await tester.pumpAndSettle();
        expect(launcher.phones, ['0770 123 4567']);
        await tester.ensureVisible(find.textContaining('9647812345678'));
        await tester.tap(find.textContaining('9647812345678'));
        await tester.pumpAndSettle();
        expect(launcher.whatsApps, ['9647812345678']);
        expect(find.textContaining('old 123'), findsNothing);
        for (final value in [
          'engineer@example.test',
          'javascript:TEST_ONLY_SCHEME',
          'Civil Test contact value',
        ]) {
          final finder = find.byWidgetPredicate(
            (w) => w is SelectableText && w.data == value,
          );
          await tester.ensureVisible(finder);
          await tester.tap(finder);
          await tester.pump();
        }
        expect(launcher.phones, hasLength(1));
        expect(launcher.whatsApps, hasLength(1));
        _assertNoOverflow(tester, c);
      },
    );

    for (final width in [390.0, 840.0]) {
      for (final dark in [false, true]) {
        for (final phone in [true, false]) {
          for (final throws in [false, true]) {
            final c = _Case(width, true, dark, 1.3);
            testWidgets(
              '${phone ? 'phone' : 'WhatsApp'} ${throws ? 'exception' : 'false'} is localized and safe ${c.key}',
              (tester) async {
                final launcher = _Launcher()
                  ..succeeds = false
                  ..throws = throws;
                final entity = _entity(
                  name: 'Failure Test',
                  description: null,
                  categories: [],
                  locations: [],
                  contacts: [
                    CanonicalDirectoryContact(
                      contactType: phone ? 'phone' : 'whatsapp',
                      value: '+964 780 123 4567',
                    ),
                  ],
                );
                await _pump(tester, _detail(entity, launcher: launcher), c);
                final finder = find.textContaining(
                  phone ? '+964 780 123 4567' : '9647801234567',
                );
                await tester.ensureVisible(finder);
                await tester.tap(finder);
                await tester.pumpAndSettle();
                expect(find.text('تعذر فتح وسيلة الاتصال.'), findsOneWidget);
                expect(
                  find.textContaining('TEST_ONLY_CONTACT_EXCEPTION'),
                  findsNothing,
                );
                expect(find.textContaining('tel:private'), findsNothing);
                _assertNoOverflow(tester, c);
                _assertTargets(tester);
                await _capture(
                  tester,
                  'contact-failure',
                  c,
                  state:
                      '${phone ? 'phone' : 'whatsapp'}-${throws ? 'exception' : 'false'}',
                );
              },
            );
          }
        }
      }
    }

    testWidgets(
      'Saved and management preserve keyboard focus order and button semantics',
      (tester) async {
        const c = _Case(390, true, false, 1.3);
        await _pump(
          tester,
          _detail(
            _entity(
              name: 'Focus Test',
              description: null,
              categories: [],
              locations: [],
              contacts: const [
                CanonicalDirectoryContact(
                  contactType: 'phone',
                  value: '07701234567',
                ),
                CanonicalDirectoryContact(
                  contactType: 'whatsapp',
                  value: '07801234567',
                ),
              ],
            ),
          ),
          c,
        );
        final semantics = tester.ensureSemantics();
        try {
          final save = find.byKey(const Key('cui1-detail-save'));
          expect(
            tester.getSemantics(save).hasFlag(ui.SemanticsFlag.isButton),
            isTrue,
          );
          final encountered = <String>[];
          for (var i = 0; i < 12; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pumpAndSettle();
            final focusContext = FocusManager.instance.primaryFocus?.context;
            focusContext?.visitAncestorElements((element) {
              final key = element.widget.key;
              String? action;
              if (key == const Key('cui1-detail-save')) action = 'save';
              if (key == const Key('cui1-detail-management')) {
                action = 'management';
              }
              if (element.widget is OutlinedButton) {
                for (final value in ['07701234567', '07801234567']) {
                  if (find
                      .descendant(
                        of: find.byWidget(element.widget),
                        matching: find.text(value),
                      )
                      .evaluate()
                      .isNotEmpty) {
                    action = value;
                  }
                }
              }
              if (action != null) {
                if (!encountered.contains(action)) encountered.add(action);
                return false;
              }
              return true;
            });
            if (encountered.length == 4) break;
          }
          expect(encountered, [
            'save',
            '07701234567',
            '07801234567',
            'management',
          ]);
          final pointer = await tester.createGesture(
            kind: ui.PointerDeviceKind.mouse,
          );
          await pointer.addPointer(location: tester.getCenter(save));
          await pointer.moveTo(tester.getCenter(save));
          await tester.pumpAndSettle();
          await pointer.removePointer();
          _assertNoOverflow(tester, c);
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('late contact completion after dispose publishes no failure', (
      tester,
    ) async {
      final launcher = _Launcher()..pending = Completer<bool>();
      const c = _Case(390, true, false, 1);
      await _pump(
        tester,
        _detail(
          _entity(
            name: 'Dispose Test',
            description: null,
            categories: [],
            locations: [],
            contacts: const [
              CanonicalDirectoryContact(
                contactType: 'phone',
                value: '07701234567',
              ),
            ],
          ),
          launcher: launcher,
        ),
        c,
      );
      await tester.ensureVisible(find.textContaining('07701234567'));
      await tester.tap(find.textContaining('07701234567'));
      await tester.pumpWidget(const SizedBox.shrink());
      launcher.pending!.complete(false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
      'Saved stays local and management routes only to viewer list without entity authority',
      (tester) async {
        final store = _SavedStore();
        final entity = _entity(
          name: 'Claimed Public Test',
          claim: 'claimed',
          verification: VerificationStatus.verified,
          description: null,
          categories: [],
          locations: [],
        );
        String? destination;
        Object? routeExtra;
        final home = _detail(entity, store: store);
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => home),
            GoRoute(
              path: '/business/manage',
              builder: (_, state) {
                destination = state.uri.toString();
                routeExtra = state.extra;
                return const Scaffold(body: Text('TEST_VIEWER_MANAGED_LIST'));
              },
            ),
          ],
        );
        addTearDown(router.dispose);
        const c = _Case(390, true, false, 1.3);
        await _pump(tester, home, c, router: router);
        final save = find.byTooltip('حفظ المزود');
        expect(save, findsOneWidget);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(store.refs, hasLength(1));
        expect(store.refs.single.ownerDomain, SavedReferenceOwners.directory);
        expect(
          store.refs.single.entityType,
          SavedReferenceEntityTypes.provider,
        );
        expect(store.refs.single.entityId, _id);
        store.failWrites = true;
        await tester.tap(find.byTooltip('إزالة من المحفوظات'));
        await tester.pumpAndSettle();
        expect(store.refs, hasLength(1));
        expect(find.byIcon(Icons.bookmark), findsOneWidget);
        await _bottom(tester);
        await tester.tap(find.text(_managementAr));
        await tester.pumpAndSettle();
        expect(destination, '/business/manage');
        expect(destination, AppRoutes.businessManage);
        expect(destination, isNot(contains(_id)));
        expect(routeExtra, isNull);
        expect(find.text('TEST_VIEWER_MANAGED_LIST'), findsOneWidget);
      },
    );

    for (final width in [320.0, 599.0, 1024.0, 1440.0]) {
      testWidgets('supplementary scale2 long-content stress ${width.toInt()}', (
        tester,
      ) async {
        final c = _Case(width, true, true, 2);
        await _pump(tester, _detail(_entity()), c, shell: true);
        await _bottom(tester);
        _assertTargets(tester);
        _assertNoOverflow(tester, c);
      });
    }

    testWidgets(
      'keyboard-visible search retains its input and has no layout exception',
      (tester) async {
        const c = _Case(390, true, true, 1.3);
        await _pump(
          tester,
          DirectorySearchScreen(
            repository: _Repository(entities: [_entity(name: 'Search Test')]),
          ),
          c,
          keyboardInset: 300,
        );
        await tester.tap(find.byType(TextField).first);
        await tester.enterText(find.byType(TextField).first, 'Search');
        await tester.pump(const Duration(milliseconds: 300));
        _assertNoOverflow(tester, c);
        await _capture(
          tester,
          'organic-search',
          c,
          state: 'simulated-keyboard-inset-300',
          fixture: 'keyboard-inset-only-not-native-platform-keyboard',
        );
      },
    );
  });
}
