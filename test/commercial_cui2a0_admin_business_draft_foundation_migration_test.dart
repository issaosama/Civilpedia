import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

const cui2a0MigrationName = '00026_commercial_admin_business_draft_foundation.sql';
const cui2a0MigrationPath = 'supabase/migrations/$cui2a0MigrationName';
const cui2a0AuthorizationCommit = 'd9bc74d42e0d3ebc56455b928f2dbc57d8ca6fb8';
const cui2a0AcceptedImplementationCommit = '41276132ba6a1606cd779f5ce92473bacfbcc7c8';
const cui2a0AcceptedClosureCommit = '5642f329dc5dbf096847a08b1e5a30d3fc9d7c4f';
const cui2a0RoadmapPath = 'docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md';
const cui2a0ClosureReportPath = 'docs/architecture/reports/CIVILPEDIA_COMMERCIAL_CUI2A0_ADMIN_BUSINESS_DRAFT_AUTHORITY_FOUNDATION_CLOSURE.md';
const cui2a0RuntimePath = 'supabase/tests/commercial_cui2a0_admin_business_draft_foundation_test.sql';
const cui2a0ClosedDocumentBlobs = <String, String>{
  cui2a0RoadmapPath: '8fa8595cfe9cc21a00db8016f930b45cf76b52d2',
  cui2a0ClosureReportPath: '068307bb6e3d64a0cb479f127d1c162a155cb0cd',
  'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_ADMIN_BUSINESS_DRAFT_AUTHORITY_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md': 'ed23e9136a39f71d95f91da7dd22e087a59dfca8',
  'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A0_APPEND_AUDIT_LOG_ACL_SECURITY_ADDENDUM_V1.md': '38016765af82de2e5a25e3b2169536bcf5fab44b',
};
const _acceptedSourceBlobs = <String, String>{
  ...cui2a0ClosedDocumentBlobs,
  cui2a0MigrationPath: '0de3aef18e9687a24917442649e5ffe831f391e0',
  cui2a0RuntimePath: '96a2bd1f6cff8d2bbe9ad6433eb223267da96b4b',
};
const cui2a0ImplementationPaths = <String>{
  cui2a0MigrationPath,
  'supabase/tests/commercial_cui2a0_admin_business_draft_foundation_test.sql',
  'test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart',
  'test/v1_r09q_security_matrix_test.dart',
};
const _functions = <String>{
  'business_admin_private.has_staff_business_permission',
  'business_admin_private.normalize_draft_payload',
  'public.guard_claim_application_insert',
  'public.get_staff_business_capabilities',
  'public.list_staff_business_entities',
  'public.get_staff_business_entity_detail',
  'public.staff_create_business_draft',
  'public.staff_update_business_draft',
  'public.list_staff_business_entity_audit',
};
const _claimBody = r'''
DECLARE v_status text; v_protected boolean;
BEGIN
  IF NEW.application_type<>'CLAIM' OR NEW.target_entity_id IS NULL THEN
    RETURN NEW;
  END IF;
  SELECT de.claim_status INTO v_status FROM public.directory_entities AS de
    WHERE de.id=NEW.target_entity_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'claim target not found' USING ERRCODE='23503';
  END IF;
  SELECT EXISTS (
    SELECT 1 FROM business_admin_private.draft_create_requests AS receipt
    WHERE receipt.entity_id=NEW.target_entity_id
  ) INTO v_protected;
  IF v_status<>'unclaimed' OR v_protected THEN
    RAISE EXCEPTION 'target entity is not claimable' USING ERRCODE='P0CLM';
  END IF;
  RETURN NEW;
END;
''';
String _clean(String s) => s.replaceAll(RegExp(r'--[^\n]*'), '');
String _compact(String s) => _clean(s).replaceAll(RegExp(r'\s+'), ' ').trim();
String _git(List<String> args) {
  final r=Process.runSync('git',args,stdoutEncoding:utf8,stderrEncoding:utf8);
  if(r.exitCode!=0) throw StateError('Git source verification failed');
  return (r.stdout as String).replaceAll('\r\n','\n');
}
String _body(String s,String fn) {
  final m=RegExp('CREATE (?:OR REPLACE )?FUNCTION '+RegExp.escape(fn)+r'\s*\(').firstMatch(s);
  if(m==null) return '';
  final tail=s.substring(m.start);
  final a=tail.indexOf(r'AS $fn$');
  if(a<0) return '';
  final b=tail.indexOf(r'$fn$;',a+8);
  return b<0?'':tail.substring(a+8,b);
}
// Shared independent source gate; filename recognition alone is insufficient.
// Runtime/HTTP evidence is separate and never inferred from this predicate.
bool isAuthorizedCui2a0Sql(String source) {
  final sql=_clean(source);
  final auditRevoke = _compact(sql).indexOf('REVOKE EXECUTE ON FUNCTION public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text) FROM PUBLIC, anon, authenticated, service_role;');
  if (auditRevoke < 0 || auditRevoke >= _compact(sql).indexOf(r'DO $preflight$') ||
      !sql.contains(r'p.prosrc=$accepted_audit$') ||
      !sql.contains("p.proconfig=ARRAY['search_path=public, pg_temp']") ||
      RegExp(r'ALTER DEFAULT PRIVILEGES[^;]*IN SCHEMA public').hasMatch(sql)) return false;
  final names=RegExp(r'CREATE (?:OR REPLACE )?FUNCTION ([a-z_]+[.][a-z_]+)\s*\(')
    .allMatches(sql).map((m)=>m[1]!).toList();
  if(names.length!=9 || names.toSet().length!=9 ||
    names.toSet().difference(_functions).isNotEmpty) return false;
  for (final signature in [
    'CREATE FUNCTION public.get_staff_business_capabilities() RETURNS jsonb',
    'CREATE FUNCTION public.list_staff_business_entities( p_search text DEFAULT NULL, p_entity_type text DEFAULT NULL, p_lifecycle_status text DEFAULT NULL, p_limit integer DEFAULT 25, p_before_created_at timestamptz DEFAULT NULL, p_before_id uuid DEFAULT NULL ) RETURNS jsonb',
    'CREATE FUNCTION public.get_staff_business_entity_detail(p_entity_id uuid) RETURNS jsonb',
    'CREATE FUNCTION public.staff_create_business_draft( p_request_id uuid, p_payload jsonb, p_reason text ) RETURNS jsonb',
    'CREATE FUNCTION public.staff_update_business_draft( p_entity_id uuid, p_expected_updated_at timestamptz, p_request_id uuid, p_payload jsonb, p_reason text ) RETURNS jsonb',
    'CREATE FUNCTION public.list_staff_business_entity_audit( p_entity_id uuid, p_limit integer DEFAULT 25, p_before_created_at timestamptz DEFAULT NULL, p_before_id uuid DEFAULT NULL ) RETURNS jsonb',
  ]) { if (!_compact(sql).contains(signature)) return false; }
  if(_compact(_body(source,'public.guard_claim_application_insert'))!=_compact(_claimBody)) return false;
  if(RegExp(r'SET search_path = pg_catalog, pg_temp').allMatches(sql).length!=9 ||
    RegExp(r'OWNER TO postgres').allMatches(sql).length!=10 ||
    RegExp(r'CREATE TABLE ').allMatches(sql).length!=1 ||
    RegExp(r'CREATE (?:UNIQUE )?INDEX ').allMatches(sql).length!=3 ||
    RegExp(r'CREATE (?:TRIGGER|POLICY|VIEW|ROLE|TYPE)|ALTER TABLE public[.]|FORCE ROW LEVEL SECURITY').hasMatch(sql)) return false;
  final grants=RegExp(r'GRANT EXECUTE ON FUNCTION ([\s\S]*?) TO authenticated;').allMatches(sql).toList();
  if(grants.length!=1 || RegExp(r'\bGRANT\b').allMatches(sql).length!=1 ||
    _functions.where((f)=>f.startsWith('public.')&&!f.endsWith('guard_claim_application_insert'))
      .any((f)=>!grants.single[1]!.contains('$f('))) return false;
  for(final text in [
    'CREATE SCHEMA business_admin_private AUTHORIZATION postgres',
    'REVOKE ALL ON SCHEMA business_admin_private FROM PUBLIC, anon, authenticated, service_role',
    'ALTER TABLE business_admin_private.draft_create_requests ENABLE ROW LEVEL SECURITY',
    'PRIMARY KEY (actor_user_id,request_id)','created_updated_at=created_at',
    "'operation_version','cui2a0.create.v1'","'format_version','cui2a0.audit.v1'",
    "RAISE EXCEPTION 'draft_audit_write_failed' USING ERRCODE='P0AUD'",
    "RAISE EXCEPTION 'unsupported_draft_transaction_context' USING ERRCODE='P0CTX'",
    'ON CONFLICT (actor_user_id,request_id) DO NOTHING',
    r'DO $preflight$',r'DO $final_assertions$','public.append_audit_log',
    'pg_catalog.pg_default_acl','pg_catalog.has_function_privilege',
    'pg_catalog.pg_publication_tables','pg_catalog.has_any_column_privilege',
    'extensions.digest(pg_catalog.convert_to(pg_catalog.jsonb_build_object(',
  ]) { if(!sql.contains(text)) return false; }
  final normalizer=_compact(_body(source,'business_admin_private.normalize_draft_payload'));
  for(final text in [
    "v_type NOT IN ('company','contractor','supplier','store')",
    "pg_catalog.octet_length(pg_catalog.convert_to(p_payload::text,'UTF8'))>65536",
    'pg_catalog.jsonb_object_keys(p_payload))<>6',
    'v_lat<>pg_catalog.round(v_lat,6)','v_lon<>pg_catalog.round(v_lon,6)',
  ]) { if(!normalizer.contains(text)) return false; }
  final permission=_compact(_body(source,'business_admin_private.has_staff_business_permission'));
  for(final text in ['pg_catalog.clock_timestamp()','JOIN public.roles',
    'JOIN public.role_permissions','JOIN public.permissions','sm.effective_at<=v_time','sm.expires_at>v_time']) {
    if(!permission.contains(text)) return false;
  }
  final create=_compact(_body(source,'public.staff_create_business_draft'));
  final update=_compact(_body(source,'public.staff_update_business_draft'));
  final detail=_compact(_body(source,'public.get_staff_business_entity_detail'));
  if(!create.contains("'draft','unverified','unclaimed',v_time,v_time") ||
    create.indexOf('INSERT INTO business_admin_private.draft_create_requests')>=create.indexOf('INSERT INTO public.directory_entities') ||
    create.split("has_staff_business_permission('business_entities.create_draft')").length!=4) return false;
  for(final text in [
    'WHERE de.id=p_entity_id FOR UPDATE',"IF NOT v_origin OR v_entity.lifecycle_status<>'draft'",
    "v_entity.verification_status<>'unverified' OR v_entity.claim_status<>'unclaimed'",
    "v_entity.entity_type NOT IN ('company','contractor','supplier','store')",
    'public.business_memberships bm WHERE bm.entity_id=p_entity_id',
    'public.subscriptions s WHERE s.entity_id=p_entity_id',
    'public.entity_locations l WHERE l.entity_id=p_entity_id AND NOT l.is_primary',
    'v_entity.updated_at IS DISTINCT FROM p_expected_updated_at',
    'pg_catalog.transaction_timestamp()<=v_entity.updated_at','v_updated_at<=v_entity.updated_at',
    'IF v_old=v_payload THEN RETURN',
  ]) { if(!update.contains(text)) return false; }
  if(update.split("has_staff_business_permission('business_entities.edit_draft')").length!=4 ||
    update.indexOf("has_staff_business_permission('business_entities.edit_draft')")>=update.indexOf('WHERE de.id=p_entity_id FOR UPDATE') ||
    update.contains('draft_create_requests(') ||
    !detail.contains("'location_scope_complete',NOT EXISTS") ||
    !detail.contains('WHERE l.entity_id=de.id AND NOT l.is_primary') ||
    !detail.contains("has_staff_business_permission('business_entities.edit_draft')") ||
    !detail.contains("(v_blob->>'location_scope_complete')::boolean") ||
    RegExp(r'(INSERT INTO|UPDATE|DELETE FROM) public[.](business_memberships|subscriptions|business_applications|entity_media)').hasMatch(create+update)) return false;
  return true;
}
// Retained historical implementation boundary. Closure does not renew it.
bool hasHistoricalAuthorizedCui2a0Boundary() {
  final file=File(cui2a0MigrationPath);
  if(!file.existsSync() || !isAuthorizedCui2a0Sql(file.readAsStringSync())) return false;
  final historical=_git(['ls-tree','-r','--name-only',cui2a0AuthorizationCommit,'--','supabase/migrations']).trim().split('\n');
  final expected=[...historical.map((p)=>p.split('/').last),cui2a0MigrationName]..sort();
  final actual=Directory('supabase/migrations').listSync().whereType<File>().map((f)=>f.uri.pathSegments.last).toList()..sort();
  return hasAuthorizedCui2a0SecuritySupport() &&
    historical.length==25 && actual.join('\n')==expected.join('\n') &&
    _git(['diff','--name-only',cui2a0AuthorizationCommit,'--',...historical]).trim().isEmpty &&
    _git(['diff','--name-only',cui2a0AuthorizationCommit,'--','lib','docs']).trim().isEmpty;
}
final _acceptedSources = _acceptedSourceBlobs.map(
  (path, blob) => MapEntry(path, _git(['cat-file', 'blob', blob])),
);
final _acceptedCommitPinsMatch =
    _git(['merge-base', cui2a0AuthorizationCommit, cui2a0AcceptedImplementationCommit]).trim() == cui2a0AuthorizationCommit &&
    _git(['rev-parse', '$cui2a0AcceptedClosureCommit^']).trim() == cui2a0AcceptedImplementationCommit &&
    _git(['rev-parse', '$cui2a0AcceptedImplementationCommit:$cui2a0RoadmapPath']).trim() == 'a5586dfdea1770f58d2333bcabad26ea00d8e747' &&
    _acceptedSourceBlobs.entries.every((entry) =>
      _git(['rev-parse', '$cui2a0AcceptedClosureCommit:${entry.key}']).trim() == entry.value &&
      (entry.key == cui2a0RoadmapPath || entry.key == cui2a0ClosureReportPath ||
        _git(['rev-parse', '$cui2a0AcceptedImplementationCommit:${entry.key}']).trim() == entry.value));

List<String> _paths(String output) => output.trim().isEmpty ? [] : output.trim().split('\n');
bool _samePaths(Iterable<String> actual, Iterable<String> expected) {
  final left = actual.toList()..sort();
  final right = expected.toList()..sort();
  return left.join('\n') == right.join('\n');
}

// Current recognition is exact accepted closure evidence, never continuing
// implementation authority. Optional inputs are adversarial in-memory probes.
bool hasAuthorizedCui2a0Boundary({
  Map<String, String>? sources,
  Iterable<String>? libDocsChanges,
  Iterable<String>? migrationNames,
  Iterable<String>? predecessorChanges,
  Iterable<String>? backendChanges,
  Iterable<String>? untrackedAuthorityPaths,
  String implementationCommit = cui2a0AcceptedImplementationCommit,
  String closureCommit = cui2a0AcceptedClosureCommit,
}) {
  if (implementationCommit != cui2a0AcceptedImplementationCommit ||
      closureCommit != cui2a0AcceptedClosureCommit || !_acceptedCommitPinsMatch) return false;
  final actualSources = sources ?? {
    for (final path in _acceptedSources.keys)
      path: File(path).readAsStringSync().replaceAll('\r\n', '\n'),
  };
  if (actualSources.length != _acceptedSources.length ||
      !_acceptedSources.entries.every((entry) => actualSources[entry.key] == entry.value) ||
      !isAuthorizedCui2a0Sql(actualSources[cui2a0MigrationPath]!)) return false;
  final securityRoadmap = _git(['cat-file', 'blob', 'a5586dfdea1770f58d2333bcabad26ea00d8e747']);
  final closedRoadmap = actualSources[cui2a0RoadmapPath]!;
  if (!closedRoadmap.startsWith(securityRoadmap)) return false;
  final closureAppend = closedRoadmap.substring(securityRoadmap.length);
  for (final control in [
    'CUI2A0_STATE: CLOSED',
    'CUI2A0_IMPLEMENTATION_AUTHORIZED: NO — SLICE CLOSED',
    'COMMERCIAL_CURRENT_SLICE: NONE',
    'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO',
    'CUI2A1_STATE: NOT AUTHORIZED',
    'M4_STATE: NOT AUTHORIZED', 'M5_STATE: NOT AUTHORIZED',
    'R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO',
  ]) {
    if (!closureAppend.contains(control) ||
        !actualSources[cui2a0ClosureReportPath]!.contains(control)) return false;
  }
  final historical = _paths(_git(['ls-tree', '-r', '--name-only', cui2a0AuthorizationCommit, '--', 'supabase/migrations']));
  return historical.length == 25 && hasAuthorizedCui2a0SecuritySupport() &&
    _samePaths(migrationNames ?? Directory('supabase/migrations').listSync().whereType<File>().map((f) => f.uri.pathSegments.last),
      [...historical.map((p) => p.split('/').last), cui2a0MigrationName]) &&
    (predecessorChanges ?? _paths(_git(['diff', '--name-only', cui2a0AuthorizationCommit, '--', ...historical]))).isEmpty &&
    _samePaths(libDocsChanges ?? _paths(_git(['diff', '--name-only', cui2a0AuthorizationCommit, '--', 'lib', 'docs'])),
      [cui2a0RoadmapPath, cui2a0ClosureReportPath]) &&
    (backendChanges ?? _paths(_git(['diff', '--name-only', cui2a0AcceptedImplementationCommit, '--', 'supabase']))).isEmpty &&
    (untrackedAuthorityPaths ?? _paths(_git(['ls-files', '--others', '--exclude-standard', '--', 'lib', 'docs', 'supabase']))).isEmpty;
}
// The extra security-support path permits only this exact expectation change.
// Removing any unrelated RLS/actor/secret assertion is still rejected.
bool hasAuthorizedCui2a0SecuritySupport([String? candidate]) {
  const before = r'''      expect(
        mutations,
        contains(
          'REVOKE EXECUTE ON FUNCTION public.append_audit_log(\n'
          '  uuid, text, text, uuid, jsonb, jsonb, text\n'
          ') FROM PUBLIC;',
        ),
      );''';
  const after = r'''      expect(
        _readNormalized('supabase/migrations/00026_commercial_admin_business_draft_foundation.sql'),
        contains(
          'REVOKE EXECUTE ON FUNCTION\n'
          'public.append_audit_log(uuid,text,text,uuid,jsonb,jsonb,text)\n'
          'FROM PUBLIC, anon, authenticated, service_role;',
        ),
      );
      final runtime = _readNormalized('supabase/tests/commercial_cui2a0_admin_business_draft_foundation_test.sql');
      for (final marker in ['ACL-01', 'ACL-02', 'ACL-03', 'ACL-04', 'ACL-05', '42501', 'has_function_privilege', 'aclexplode']) {
        expect(runtime, contains(marker));
      }''';
  final baseline = _git(['show', '$cui2a0AuthorizationCommit:test/v1_r09q_security_matrix_test.dart']);
  final current = candidate ?? File('test/v1_r09q_security_matrix_test.dart').readAsStringSync();
  return before.allMatches(baseline).length==1 &&
    current.replaceAll('\r\n','\n')==baseline.replaceFirst(before,after);
}
void main() {
  final source=File(cui2a0MigrationPath).readAsStringSync();
  final sql=_clean(source);
  test('T01-T02 exact objects, four permissions, zero provisioning and immutable history',(){
    expect(hasAuthorizedCui2a0Boundary(),isTrue);
    for(final code in ['read','create_draft','edit_draft','read_audit']) {
      expect(sql,contains("'business_entities.$code'"));
    }
    for(final table in ['roles','role_permissions','staff_memberships']) {
      expect(sql,isNot(contains('INSERT INTO public.$table')));
    }
    expect(RegExp(r'SECURITY INVOKER').allMatches(sql),hasLength(2));
    expect(RegExp(r'SECURITY DEFINER').allMatches(sql),hasLength(7));
  });
  test('post-closure pins exact implementation and two-file documentary closure', () {
    expect(_acceptedCommitPinsMatch, isTrue);
    expect(hasAuthorizedCui2a0Boundary(), isTrue);
    expect(hasHistoricalAuthorizedCui2a0Boundary(), isFalse,
      reason: 'The historical implementation boundary must not become continuing authority');
    expect(_samePaths(_paths(_git(['diff', '--name-only', '$cui2a0AcceptedImplementationCommit^', cui2a0AcceptedImplementationCommit])), [
      ...cui2a0ImplementationPaths,
      'test/commercial_harden1_public_plans_exposure_migration_test.dart',
      'test/commercial_m1b_catalog_reference_data_migration_test.dart',
      'test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart',
    ]), isTrue);
    expect(_samePaths(_paths(_git(['diff', '--name-only', cui2a0AcceptedImplementationCommit, cui2a0AcceptedClosureCommit])),
      [cui2a0RoadmapPath, cui2a0ClosureReportPath]), isTrue);
    const wrong = '0000000000000000000000000000000000000000';
    expect(hasAuthorizedCui2a0Boundary(implementationCommit: wrong), isFalse);
    expect(hasAuthorizedCui2a0Boundary(closureCommit: wrong), isFalse);
  });
  for (final entry in _acceptedSources.entries) {
    test('post-closure rejects changed accepted source: ${entry.key}', () {
      expect(hasAuthorizedCui2a0Boundary(sources: {
        ..._acceptedSources, entry.key: '${entry.value}\n-- unauthorized bytes\n',
      }), isFalse);
    });
  }
  final securityRoadmap = _git(['cat-file', 'blob', 'a5586dfdea1770f58d2333bcabad26ea00d8e747']);
  final closureAppend = _acceptedSources[cui2a0RoadmapPath]!.substring(securityRoadmap.length);
  for (final mutation in <String, String>{
    'CUI2A0_STATE: CLOSED': 'CUI2A0_STATE: OPEN',
    'CUI2A0_IMPLEMENTATION_AUTHORIZED: NO — SLICE CLOSED': 'CUI2A0_IMPLEMENTATION_AUTHORIZED: YES',
    'CUI2A1_STATE: NOT AUTHORIZED': 'CUI2A1_STATE: IMPLEMENTATION AUTHORIZED',
    'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO': 'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES',
    'COMMERCIAL_CURRENT_SLICE: NONE': 'COMMERCIAL_CURRENT_SLICE: CUI-2A1',
    'M4_STATE: NOT AUTHORIZED': 'M4_STATE: AUTHORIZED',
    'M5_STATE: NOT AUTHORIZED': 'M5_STATE: AUTHORIZED',
    'R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO': 'R10.5-D_STATE: IMPLEMENTATION YES',
  }.entries) {
    test('post-closure rejects final control mutation: ${mutation.key}', () {
      expect(closureAppend, contains(mutation.key));
      expect(hasAuthorizedCui2a0Boundary(sources: {
        ..._acceptedSources,
        cui2a0RoadmapPath: securityRoadmap + closureAppend.replaceFirst(mutation.key, mutation.value),
      }), isFalse);
    });
  }
  test('post-closure rejects future A1 paths and arbitrary documentary suffixes', () {
    for (final path in [
      'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A1_ADMIN_BUSINESS_DRAFT_CONSOLE_IMPLEMENTATION_CONTRACT_V1.md',
      'docs/unauthorized.md',
      'lib/unauthorized.dart',
      'lib/features/business/data/supabase_commercial_admin_gateway.dart',
      'lib/features/business/presentation/providers/commercial_admin_provider.dart',
      'lib/features/business/presentation/screens/admin_businesses_screen.dart',
      'lib/features/business/presentation/screens/admin_business_draft_screen.dart',
    ]) {
      expect(hasAuthorizedCui2a0Boundary(libDocsChanges: [cui2a0RoadmapPath, cui2a0ClosureReportPath, path]), isFalse, reason: path);
      expect(hasAuthorizedCui2a0Boundary(untrackedAuthorityPaths: [path]), isFalse, reason: path);
    }
    expect(hasAuthorizedCui2a0Boundary(sources: {
      ..._acceptedSources, 'docs/extra.md': 'not authorized',
    }), isFalse);
    expect(hasAuthorizedCui2a0Boundary(sources: {
      ..._acceptedSources, cui2a0RoadmapPath: '${_acceptedSources[cui2a0RoadmapPath]}\n# Arbitrary future authority\n',
    }), isFalse);
  });
  test('post-closure rejects 00027, predecessor and arbitrary backend changes', () {
    final migrations = Directory('supabase/migrations').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toList();
    expect(hasAuthorizedCui2a0Boundary(migrationNames: [...migrations, '00027_unauthorized.sql']), isFalse);
    for (final name in migrations.where((name) => name != cui2a0MigrationName)) {
      expect(hasAuthorizedCui2a0Boundary(predecessorChanges: ['supabase/migrations/$name']), isFalse, reason: name);
    }
    expect(hasAuthorizedCui2a0Boundary(backendChanges: ['supabase/tests/arbitrary.sql']), isFalse);
  });
  test('T03-T05 exact permission in every public RPC, no membership/admin shortcut',(){
    for(final entry in <String,String>{
      'list_staff_business_entities':'read','get_staff_business_entity_detail':'read',
      'staff_create_business_draft':'create_draft','staff_update_business_draft':'edit_draft',
      'list_staff_business_entity_audit':'read_audit',
    }.entries) {
      expect(_body(source,'public.'+entry.key),contains("has_staff_business_permission('business_entities."+entry.value+"')"));
    }
    expect(_body(source,'business_admin_private.has_staff_business_permission'),isNot(contains('business_memberships')));
  });
  test('T06-T14 private minimal receipt and structural bounds',(){
    final receipt=sql.substring(sql.indexOf('CREATE TABLE business_admin_private'),sql.indexOf('ALTER TABLE business_admin_private'));
    expect(receipt,isNot(contains('REFERENCES')));
    expect(receipt,contains('pg_catalog.octet_length(payload_fingerprint)=32'));
    expect(receipt,contains('entity_id uuid NOT NULL UNIQUE'));
    final normalizer=_body(source,'business_admin_private.normalize_draft_payload');
    for(final text in ['NOT BETWEEN 1 AND 160','>2000','>10','>500','>254','>2048',
      r'^[0-9+(). /-]+$',"NOT IN ('phone','whatsapp','email','website','other')",
      'jsonb_object_keys(v_location))<>4','v_lat NOT BETWEEN -90 AND 90','v_lon NOT BETWEEN -180 AND 180']) {
      expect(normalizer,contains(text));
    }
  });
  test('T15-T18 version, no-op and frozen lock order',(){
    final update=_body(source,'public.staff_update_business_draft');
    final tiers=['WHERE de.id=p_entity_id FOR UPDATE','FROM public.directory_categories c',
      'FROM public.regions r','PERFORM c.id FROM public.entity_contacts',
      'PERFORM c.category_id FROM public.directory_entity_categories','SELECT l.id INTO v_location_id',
      'PERFORM public.append_audit_log'];
    for(var i=1;i<tiers.length;i++) expect(update.indexOf(tiers[i-1]),lessThan(update.indexOf(tiers[i])));
    expect(update.indexOf('IF v_old=v_payload THEN'),lessThan(update.indexOf('FROM public.directory_categories c')));
  });
  test('T19-T23 sanitized audit and bounded literal keyset reads',(){
    final list=_body(source,'public.list_staff_business_entities');
    expect(list,contains("E'\\\\%'")); expect(list,contains("E'\\\\_'"));
    expect(list,contains('ORDER BY de.created_at DESC,de.id DESC LIMIT p_limit+1'));
    final audit=_body(source,'public.list_staff_business_entity_audit');
    expect(audit,contains("action IN ('business_entity.draft_create','business_entity.draft_update')"));
    for(final forbidden in ["'before_data',","'after_data',","'payload_fingerprint',","'contact_value',"]) {
      expect(audit,isNot(contains(forbidden)));
    }
  });
  test('T24-T29 replay never locks or recreates the old entity',(){
    final create=_body(source,'public.staff_create_business_draft');
    final replay=create.substring(create.indexOf('IF NOT v_new THEN'),create.indexOf('INSERT INTO public.directory_entities'));
    expect(replay,isNot(contains('FOR UPDATE'))); expect(replay,isNot(contains('FOR SHARE')));
    expect(replay,contains("'outcome','REPLAY'")); expect(replay,contains("ERRCODE='P0INV'"));
  });
  test('T30-T32 sole canonical guard replacement and runner-owned atomicity',(){
    expect(_compact(_body(source,'public.guard_claim_application_insert')),_compact(_claimBody));
    expect(RegExp(r'CREATE OR REPLACE FUNCTION').allMatches(sql),hasLength(1));
    expect(sql,isNot(matches(RegExp(r'^\s*(COMMIT|ROLLBACK|START TRANSACTION)\b',multiLine:true))));
    expect(sql,contains(r'prosrc=$accepted_guard$'));
    expect(sql,contains("t.tgname='trigger_guard_claim_insert'"));
  });
  final mutations=<String,String>{
    'audit client ACL omission':source.replaceFirst('FROM PUBLIC, anon, authenticated, service_role;', 'FROM PUBLIC;'),
    'RPC parameter type':source.replaceFirst('get_staff_business_entity_detail(p_entity_id uuid)', 'get_staff_business_entity_detail(p_entity_id text)'),
    'seventh RPC':source+'\n'+r'CREATE FUNCTION public.seventh() RETURNS jsonb LANGUAGE sql AS $$ SELECT NULL::jsonb $$;',
    'receipt predicate':source.replaceFirst('WHERE receipt.entity_id=NEW.target_entity_id','WHERE false'),
    'empty-lock race':source.replaceFirst("RAISE EXCEPTION 'claim target not found' USING ERRCODE='23503';",'RETURN NEW;'),
    'row lock':source.replaceFirst('WHERE de.id=NEW.target_entity_id FOR UPDATE','WHERE de.id=NEW.target_entity_id'),
    'private ACL':source.replaceFirst('REVOKE ALL ON SCHEMA business_admin_private','GRANT USAGE ON SCHEMA business_admin_private'),
    'authoring types':source.replaceFirst("v_type NOT IN ('company','contractor','supplier','store')","v_type NOT IN ('company','contractor','supplier','store','technician')"),
    'location completeness':source.replaceFirst('AND NOT l.is_primary','AND false'),
    'timestamp advancement':source.replaceFirst('pg_catalog.transaction_timestamp()<=v_entity.updated_at','false'),
    'edit permission':source.replaceFirst("has_staff_business_permission('business_entities.edit_draft')","has_staff_business_permission('business_entities.read')"),
    'service-role grant':source.replaceFirst('TO authenticated;','TO authenticated,service_role;'),
  };
  for(final entry in mutations.entries) {
    test('T33 rejects '+entry.key,()=>expect(isAuthorizedCui2a0Sql(entry.value),isFalse));
  }
  test('T33 security support cannot remove unrelated assertions',(){
    expect(hasAuthorizedCui2a0SecuritySupport(),isTrue);
    final current=File('test/v1_r09q_security_matrix_test.dart').readAsStringSync();
    expect(hasAuthorizedCui2a0SecuritySupport(current.replaceFirst('all accepted protected tables have RLS enabled','weakened')),isFalse);
  });
  test('T34 runtime evidence is implemented separately; static is not HTTP PASS',(){
    final runtime=File('supabase/tests/commercial_cui2a0_admin_business_draft_foundation_test.sql').readAsStringSync();
    for(final marker in ['T01','T34','T32A','T32H','dblink_send_query','wait_event_type','P0CON','P0RPL','P0AUD']) {
      expect(runtime,contains(marker));
    }
  });
}

