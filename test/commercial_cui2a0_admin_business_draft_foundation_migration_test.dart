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
bool hasClosedCui2a0Boundary({
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
// Owner-committed documentary inputs. Neither HEAD nor pending text is a pin.
const cui2a1FreezeCommit = 'e767add487034171b0e8512ee6cfc8d56484004e';
const cui2a1CompatibilityCommit = 'acbcf9af85da749328b672234ce258b00cbb5c23';
const cui2a1ContractPath = 'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A1_ADMIN_BUSINESS_DRAFT_CONSOLE_IMPLEMENTATION_CONTRACT_V1.md';
const cui2a1ContractBlob = '8071f951ff336714c420a5216504d0d49183e055';
const cui2a1FreezeRoadmapBlob = '049dfcff25091616d80132c6db9402f095e02c56';
const cui2a1CompatibilityRoadmapBlob = '4da132714f60b7f10c02d5732acc1646b549632d';
const cui2a1CompatibilityPaths = <String>{
  'test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart',
  'test/commercial_harden1_public_plans_exposure_migration_test.dart',
  'test/commercial_m1b_catalog_reference_data_migration_test.dart',
  'test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart',
};
// Exact entry bytes, not permission to alter dirty files or add artifacts.
const _cui2a1ProtectedBlobs = <String, String>{
  'test/a5_6_profile_bootstrap_test.dart': '3bf84c06d8de648c793b93168832dd3f4557f6c4',
  'test/v1_r08_cloud_profile_foundation_test.dart': 'ed2fdfeace5d815d6c6a36df01bcf828c69e2e20',
  'test/v1_r08_profile_edit_screen_widget_test.dart': '8044513a653f601c37c6c91d55638254b82554cc',
  'OpenCode_Usage_Report.txt': 'e0c432a4b8bd72e94d3db203b59ba260597dd601',
  'artifacts/r10_4a/home_dark.png': '45e4ba795bbcffbf283b282e48ff0d436ecb6e20',
  'artifacts/r10_4a/home_light.png': 'c35bb2314dd916f64cba5794d729aa12bd7a8247',
  'test/commercial_m1a_private_catalog_migration_test.dart': '2f73cf52711fb78969741470724f2aa2567995a5',
  'test/v1_r09q_security_matrix_test.dart': '8dcd0a3089833354fa49174b5db2a3d8c26318b9',
};
const _cui2a1DirtyPaths = <String>{
  'test/a5_6_profile_bootstrap_test.dart',
  'test/v1_r08_cloud_profile_foundation_test.dart',
  'test/v1_r08_profile_edit_screen_widget_test.dart',
};
const _cui2a1UntrackedPaths = <String>{
  'OpenCode_Usage_Report.txt',
  'artifacts/r10_4a/home_dark.png',
  'artifacts/r10_4a/home_light.png',
};
final cui2a1FrozenContract = _git(['cat-file', 'blob', cui2a1ContractBlob]);
final cui2a1CompatibilityRoadmap = _git(['cat-file', 'blob', cui2a1CompatibilityRoadmapBlob]);
final cui2a1DocumentaryAppend = cui2a1CompatibilityRoadmap.substring(
  _acceptedSources[cui2a0RoadmapPath]!.length,
);
final _cui2a1Sources = <String, String>{
  ..._acceptedSources,
  cui2a0RoadmapPath: cui2a1CompatibilityRoadmap,
  cui2a1ContractPath: cui2a1FrozenContract,
};
final _cui2a1PinsMatch =
    _git(['rev-parse', '$cui2a1FreezeCommit^']).trim() == '3f4ce87381ea97b0f3f6a772827c4d77b58aee66' &&
    _git(['merge-base', cui2a0AcceptedClosureCommit, cui2a1FreezeCommit]).trim() == cui2a0AcceptedClosureCommit &&
    _git(['rev-parse', '$cui2a1CompatibilityCommit^']).trim() == cui2a1FreezeCommit &&
    _git(['merge-base', cui2a1CompatibilityCommit, 'HEAD']).trim() == cui2a1CompatibilityCommit &&
    _git(['rev-parse', '$cui2a1FreezeCommit:$cui2a1ContractPath']).trim() == cui2a1ContractBlob &&
    _git(['rev-parse', '$cui2a1CompatibilityCommit:$cui2a1ContractPath']).trim() == cui2a1ContractBlob &&
    _git(['rev-parse', '$cui2a1FreezeCommit:$cui2a0RoadmapPath']).trim() == cui2a1FreezeRoadmapBlob &&
    _git(['rev-parse', '$cui2a1CompatibilityCommit:$cui2a0RoadmapPath']).trim() == cui2a1CompatibilityRoadmapBlob &&
    _samePaths(_paths(_git(['diff', '--name-only', '--no-renames',
      '$cui2a1FreezeCommit^', cui2a1FreezeCommit])),
      [cui2a0RoadmapPath, cui2a1ContractPath]) &&
    _samePaths(_paths(_git(['diff', '--name-only', '--no-renames',
      cui2a1FreezeCommit, cui2a1CompatibilityCommit])), [cui2a0RoadmapPath]) &&
    _git(['cat-file', 'blob', cui2a1FreezeRoadmapBlob]).startsWith(
      _acceptedSources[cui2a0RoadmapPath]!) &&
    cui2a1CompatibilityRoadmap.startsWith(
      _git(['cat-file', 'blob', cui2a1FreezeRoadmapBlob]));

bool matchesFrozenCui2a1Documents(String roadmap, String contract) =>
    _cui2a1PinsMatch && roadmap == cui2a1CompatibilityRoadmap &&
    contract == cui2a1FrozenContract;

// The historical CLOSED predicate above remains exact. This separate live
// branch recognizes only committed documentation, never AUTHORIZED A1 UI.
bool hasAuthorizedCui2a0Boundary({
  Map<String, String>? sources,
  Iterable<String>? libDocsChanges,
  Iterable<String>? migrationNames,
  Iterable<String>? predecessorChanges,
  Iterable<String>? backendChanges,
  Iterable<String>? untrackedAuthorityPaths,
  Iterable<String>? repositoryChanges,
  Iterable<String>? committedChanges,
  Iterable<String>? stagedChanges,
  Iterable<String>? untrackedPaths,
  Map<String, String>? preservedBlobs,
  String implementationCommit = cui2a0AcceptedImplementationCommit,
  String closureCommit = cui2a0AcceptedClosureCommit,
  String freezeCommit = cui2a1FreezeCommit,
  String compatibilityCommit = cui2a1CompatibilityCommit,
}) {
  if (freezeCommit != cui2a1FreezeCommit ||
      compatibilityCommit != cui2a1CompatibilityCommit || !_cui2a1PinsMatch) return false;
  final actual = sources ?? {
    for (final path in _cui2a1Sources.keys)
      path: File(path).readAsStringSync().replaceAll('\r\n', '\n'),
  };
  if (actual.length != _cui2a1Sources.length ||
      !_cui2a1Sources.entries.every((e) => actual[e.key] == e.value) ||
      !matchesFrozenCui2a1Documents(actual[cui2a0RoadmapPath]!,
        actual[cui2a1ContractPath]!)) return false;
  // Check committed and index deltas separately: a restored working copy
  // must not hide an unauthorized committed or staged document/source.
  final committed = committedChanges ?? _paths(_git([
    'diff', '--name-only', '--no-renames', cui2a1CompatibilityCommit, 'HEAD',
  ]));
  final staged = stagedChanges ?? _paths(_git([
    'diff', '--cached', '--name-only', '--no-renames',
  ]));
  if ([...committed, ...staged].any(
      (p) => !cui2a1CompatibilityPaths.contains(p))) return false;
  final changes = repositoryChanges ?? _paths(_git([
    'diff', '--name-only', '--no-renames', cui2a1CompatibilityCommit,
  ]));
  if (!_cui2a1DirtyPaths.every(changes.contains) ||
      changes.any((p) => !cui2a1CompatibilityPaths.contains(p) &&
        !_cui2a1DirtyPaths.contains(p)) ||
      !_samePaths(untrackedPaths ?? _paths(_git([
        'ls-files', '--others', '--exclude-standard',
      ])), _cui2a1UntrackedPaths)) return false;
  final protected = preservedBlobs ?? {
    for (final path in _cui2a1ProtectedBlobs.keys)
      path: _git(['hash-object', '--no-filters', '--', path]).trim(),
  };
  if (protected.length != _cui2a1ProtectedBlobs.length ||
      !_cui2a1ProtectedBlobs.entries.every((e) => protected[e.key] == e.value)) return false;
  final docsChanges = libDocsChanges ?? _paths(_git([
    'diff', '--name-only', '--no-renames', cui2a0AuthorizationCommit, '--', 'lib', 'docs',
  ]));
  if (!_samePaths(docsChanges, [
    cui2a0RoadmapPath, cui2a0ClosureReportPath, cui2a1ContractPath,
  ])) return false;
  // Project the exact documentary extension onto the retained closed fixture;
  // validate the same SQL, ACL, source/commit and inventory protections.
  return hasClosedCui2a0Boundary(
    sources: {
      for (final path in _acceptedSources.keys)
        path: path == cui2a0RoadmapPath ? _acceptedSources[path]! : actual[path]!,
    },
    libDocsChanges: docsChanges.where((p) => p != cui2a1ContractPath),
    migrationNames: migrationNames, predecessorChanges: predecessorChanges,
    backendChanges: backendChanges, untrackedAuthorityPaths: untrackedAuthorityPaths,
    implementationCommit: implementationCommit, closureCommit: closureCommit,
  );
}


// Exact successive documentary authority, observed after the Owner's commit.
// All historical predicates and pins above remain unchanged.
const ownerPlanningCommit = 'ac64cd6275888fd2768db2a890e98fbfc9819ab1';
const ownerPlanningParent = 'ed9840084eb67b1bb295459b420093a37d8bccbb';
const ownerPlanningAuthorizationCommit = '2cbed9f81d9346ac4b16c00e9c20282aaddc97eb';
const ownerPlanningRoadmapBlob = 'e2e239e08f14350b910ab22185c095387e5a2301';
const ownerPlanningAuthorizationRoadmapBlob = 'dba35363152429ca78933e1669e80758cfaba48c';
const ownerPlanningReadinessPath = 'docs/architecture/CIVILPEDIA_IMPLEMENTATION_READINESS_AND_ROADMAP.md';
const ownerPlanningReadinessBlob = 'ee696d6a4054fd5476f81f3d7c2c9b6e6e8cd7ab';
const _ownerPlanningParentReadinessBlob = '62d61b26fc3a32940b0f3b64058fd63c69eca74c';
const _ownerPlanningGuardBlobs = <String, String>{
  'test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart': '3f57d0df207f7625d3d5a66e15ade3133d61b0ca',
  'test/commercial_harden1_public_plans_exposure_migration_test.dart': '489a7975a095ba0d194fa52c7079651f32c4fb95',
  'test/commercial_m1b_catalog_reference_data_migration_test.dart': 'be632a82938259ba068ba3492691115d092f2871',
  'test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart': '93a46d1a4a36bbab6374e50470aac244cde66723',
};
const _ownerPlanningPins = <String, String>{
  'planningCommit': ownerPlanningCommit, 'planningParent': ownerPlanningParent,
  'authorizationCommit': ownerPlanningAuthorizationCommit,
  'planningRoadmap': ownerPlanningRoadmapBlob,
  'authorizationRoadmap': ownerPlanningAuthorizationRoadmapBlob,
  'readiness': ownerPlanningReadinessBlob, 'parentReadiness': _ownerPlanningParentReadinessBlob,
};
final ownerPlanningRoadmap = _git(['cat-file', 'blob', ownerPlanningAuthorizationRoadmapBlob]);
final ownerPlanningReadiness = _git(['cat-file', 'blob', ownerPlanningReadinessBlob]);
final ownerPlanningDocumentaryAppend = ownerPlanningRoadmap.substring(cui2a1CompatibilityRoadmap.length);
final _ownerPlanningSources = <String, String>{
  ..._cui2a1Sources, cui2a0RoadmapPath: ownerPlanningRoadmap,
  ownerPlanningReadinessPath: ownerPlanningReadiness,
};
final _ownerPlanningPinsMatch =
    _cui2a1PinsMatch &&
    _git(['rev-parse', '$ownerPlanningParent^']).trim() == cui2a1CompatibilityCommit &&
    _git(['rev-parse', '$ownerPlanningCommit^']).trim() == ownerPlanningParent &&
    _git(['rev-parse', '$ownerPlanningAuthorizationCommit^']).trim() == ownerPlanningCommit &&
    _git(['rev-parse', '$ownerPlanningParent:$cui2a0RoadmapPath']).trim() == cui2a1CompatibilityRoadmapBlob &&
    _git(['rev-parse', '$ownerPlanningParent:$ownerPlanningReadinessPath']).trim() == _ownerPlanningParentReadinessBlob &&
    _git(['rev-parse', '$ownerPlanningCommit:$cui2a0RoadmapPath']).trim() == ownerPlanningRoadmapBlob &&
    _git(['rev-parse', '$ownerPlanningCommit:$ownerPlanningReadinessPath']).trim() == ownerPlanningReadinessBlob &&
    _git(['rev-parse', '$ownerPlanningAuthorizationCommit:$cui2a0RoadmapPath']).trim() == ownerPlanningAuthorizationRoadmapBlob &&
    _git(['rev-parse', '$ownerPlanningAuthorizationCommit:$ownerPlanningReadinessPath']).trim() == ownerPlanningReadinessBlob &&
    _samePaths(_paths(_git(['diff', '--name-only', '--no-renames', cui2a1CompatibilityCommit, ownerPlanningParent])), cui2a1CompatibilityPaths) &&
    _samePaths(_paths(_git(['diff', '--name-only', '--no-renames', ownerPlanningParent, ownerPlanningCommit])), [cui2a0RoadmapPath, ownerPlanningReadinessPath]) &&
    _samePaths(_paths(_git(['diff', '--name-only', '--no-renames', ownerPlanningCommit, ownerPlanningAuthorizationCommit])), [cui2a0RoadmapPath]) &&
    _ownerPlanningGuardBlobs.entries.every((e) =>
      [ownerPlanningParent, ownerPlanningCommit, ownerPlanningAuthorizationCommit].every(
        (commit) => _git(['rev-parse', '$commit:${e.key}']).trim() == e.value)) &&
    _git(['rev-parse', '$ownerPlanningAuthorizationCommit:$cui2a1ContractPath']).trim() == cui2a1ContractBlob &&
    _git(['cat-file', 'blob', ownerPlanningRoadmapBlob]).startsWith(cui2a1CompatibilityRoadmap) &&
    ownerPlanningRoadmap.startsWith(_git(['cat-file', 'blob', ownerPlanningRoadmapBlob]));

bool matchesOwnerPlanningDocuments(String roadmap, String contract, String readiness) =>
    _ownerPlanningPinsMatch && roadmap == ownerPlanningRoadmap &&
    contract == cui2a1FrozenContract && readiness == ownerPlanningReadiness;

// A filename alone cannot authorize additions, deletions, renames or type changes.
bool _onlyModifiedPaths(String output, Set<String> allowed) => _paths(output).every((line) {
  final fields = line.split('\t');
  return fields.length == 2 && fields[0] == 'M' && allowed.contains(fields[1]);
});

bool hasOwnerPlanningDocumentaryBoundary({
  Map<String, String>? sources,
  Iterable<String>? libDocsChanges, Iterable<String>? migrationNames,
  Iterable<String>? predecessorChanges, Iterable<String>? backendChanges,
  Iterable<String>? untrackedAuthorityPaths, Iterable<String>? repositoryChanges,
  Iterable<String>? committedChanges, Iterable<String>? stagedChanges,
  Iterable<String>? unstagedChanges, Iterable<String>? untrackedPaths,
  Map<String, String>? preservedBlobs, Map<String, String>? pins,
  String? executionCommit, String? committedStatus, String? stagedStatus, String? unstagedStatus,
  String implementationCommit = cui2a0AcceptedImplementationCommit,
  String closureCommit = cui2a0AcceptedClosureCommit,
  String freezeCommit = cui2a1FreezeCommit,
  String compatibilityCommit = cui2a1CompatibilityCommit,
}) {
  final candidatePins = pins ?? _ownerPlanningPins;
  if (candidatePins.length != _ownerPlanningPins.length ||
      !_ownerPlanningPins.entries.every((e) => candidatePins[e.key] == e.value) ||
      freezeCommit != cui2a1FreezeCommit || compatibilityCommit != cui2a1CompatibilityCommit ||
      !_ownerPlanningPinsMatch || _git(['branch', '--show-current']).trim() != 'main') return false;
  // HEAD is the actual side of ancestry/delta verification, never an expected pin.
  final actualHead = executionCommit ?? _git(['rev-parse', 'HEAD']).trim();
  if (_git(['merge-base', ownerPlanningAuthorizationCommit, actualHead]).trim() != ownerPlanningAuthorizationCommit) return false;
  final actual = sources ?? {
    for (final path in _ownerPlanningSources.keys) path: File(path).readAsStringSync().replaceAll('\r\n', '\n'),
  };
  if (actual.length != _ownerPlanningSources.length ||
      !_ownerPlanningSources.entries.every((e) => actual[e.key] == e.value) ||
      !matchesOwnerPlanningDocuments(actual[cui2a0RoadmapPath]!, actual[cui2a1ContractPath]!, actual[ownerPlanningReadinessPath]!)) return false;
  final committed = committedChanges ?? _paths(_git(['diff', '--name-only', '--no-renames', ownerPlanningAuthorizationCommit, actualHead]));
  final staged = stagedChanges ?? _paths(_git(['diff', '--cached', '--name-only', '--no-renames']));
  final unstaged = unstagedChanges ?? _paths(_git(['diff', '--name-only', '--no-renames']));
  final changes = repositoryChanges ?? _paths(_git(['diff', '--name-only', '--no-renames', ownerPlanningAuthorizationCommit]));
  final workingPaths = <String>{...cui2a1CompatibilityPaths, ..._cui2a1DirtyPaths};
  if ([...committed, ...staged].any((p) => !cui2a1CompatibilityPaths.contains(p)) ||
      unstaged.any((p) => !workingPaths.contains(p)) ||
      !_cui2a1DirtyPaths.every(changes.contains) || changes.any((p) => !workingPaths.contains(p)) ||
      !_samePaths(untrackedPaths ?? _paths(_git(['ls-files', '--others', '--exclude-standard'])), _cui2a1UntrackedPaths) ||
      !_onlyModifiedPaths(committedStatus ?? _git(['diff', '--name-status', '--no-renames', ownerPlanningAuthorizationCommit, actualHead]), cui2a1CompatibilityPaths) ||
      !_onlyModifiedPaths(stagedStatus ?? _git(['diff', '--cached', '--name-status', '--no-renames']), cui2a1CompatibilityPaths) ||
      !_onlyModifiedPaths(unstagedStatus ?? _git(['diff', '--name-status', '--no-renames']), workingPaths)) return false;
  final protected = preservedBlobs ?? {
    for (final path in _cui2a1ProtectedBlobs.keys) path: _git(['hash-object', '--no-filters', '--', path]).trim(),
  };
  if (protected.length != _cui2a1ProtectedBlobs.length ||
      !_cui2a1ProtectedBlobs.entries.every((e) => protected[e.key] == e.value)) return false;
  final docsChanges = libDocsChanges ?? _paths(_git(['diff', '--name-only', '--no-renames', cui2a0AuthorizationCommit, '--', 'lib', 'docs']));
  if (!_samePaths(docsChanges, [cui2a0RoadmapPath, cui2a0ClosureReportPath, cui2a1ContractPath, ownerPlanningReadinessPath])) return false;
  // Only after all new identities and independent inventories pass, project
  // onto the unchanged A1 predicate and its retained closed SQL/security gate.
  return hasAuthorizedCui2a0Boundary(
    sources: {
      for (final path in _cui2a1Sources.keys)
        path: path == cui2a0RoadmapPath ? cui2a1CompatibilityRoadmap : actual[path]!,
    },
    libDocsChanges: docsChanges.where((p) => p != ownerPlanningReadinessPath),
    repositoryChanges: _cui2a1DirtyPaths, committedChanges: const [], stagedChanges: const [],
    untrackedPaths: untrackedPaths, preservedBlobs: protected,
    migrationNames: migrationNames, predecessorChanges: predecessorChanges,
    backendChanges: backendChanges, untrackedAuthorityPaths: untrackedAuthorityPaths,
    implementationCommit: implementationCommit, closureCommit: closureCommit,
    freezeCommit: freezeCommit, compatibilityCommit: compatibilityCommit,
  );
}

// Exact committed R10.5-D freeze only; never production execution authority.
const r10FreezeCommit = 'bb59c7425527eed16a219c2043172ee9e523acfc';
const r10FreezeParent = '0ceb646621027e2ab902b13302c452038154ab11';
const r10ContractPath = 'docs/architecture/contracts/V1-R10_5D_PROFILE_USER_AREA_PRESENTATION_IMPLEMENTATION_CONTRACT.md';
const r10ContractBlob = '0c8f38c87248d31a5aef23a4cfe9f20a546b1329';
const r10RoadmapBlob = '7a2e58253ddd9a9795dde59da864019931d3c5ee';
const r10AuthorizationCommit = '0f4085882786b0ac588e61c892048e162e76a243';
const r10AuthorizedRoadmapBlob = 'd8a6511e1237efeebe62f745923550ce94609abc';
const _r10GuardBlobs = <String, String>{
  'test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart': 'fef6a5cc7fb3866a8ac99fcaf3a11943da443a1b',
  'test/commercial_harden1_public_plans_exposure_migration_test.dart': '9c2687969ec27f96362264c470db3080281b377b',
  'test/commercial_m1b_catalog_reference_data_migration_test.dart': 'c28a02599e431b0e7331cb2713ef74e634787027',
  'test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart': '06452fdbeda3d043a3f386d969b91e9e6aa5d7de',
};
const _r10Pins = <String, String>{
  'freeze': r10FreezeCommit, 'parent': r10FreezeParent,
  'contract': r10ContractBlob, 'roadmap': r10RoadmapBlob,
  'authorization': r10AuthorizationCommit, 'authorizedRoadmap': r10AuthorizedRoadmapBlob,
};
const r10PresentationPaths = <String>{
  'lib/features/profile/presentation/profile_screen.dart',
  'lib/features/profile/presentation/screens/profile_setup_screen.dart',
  'lib/features/profile/presentation/screens/profile_edit_screen.dart',
  'lib/features/profile/presentation/screens/authenticated_profile_edit_screen.dart',
  'lib/features/user_area/presentation/user_area_screen.dart',
  'test/v1_r10_5d_profile_user_area_visual_test.dart',
};
final r10FrozenContract = _git(['cat-file', 'blob', r10ContractBlob]);
final r10FrozenRoadmap = _git(['cat-file', 'blob', r10RoadmapBlob]);
final r10FreezeAppend = r10FrozenRoadmap.substring(ownerPlanningRoadmap.length);
final r10AuthorizedRoadmap = _git(['cat-file', 'blob', r10AuthorizedRoadmapBlob]);
// Literal Owner-approved append; expected authority is never read from live source.
const r10AuthorizationAppend = '\n' r'''# R10.5-D FREEZE-ONLY FOUR-GUARD COMPATIBILITY AUTHORIZATION

The Owner prospectively authorizes completion of freeze-only commercial
guard compatibility. This record does not assert that committed
authorization existed when the current candidate was prepared.

Exact frozen inputs:
Freeze commit: bb59c7425527eed16a219c2043172ee9e523acfc
Parent: 0ceb646621027e2ab902b13302c452038154ab11
R10.5-D contract blob: 0c8f38c87248d31a5aef23a4cfe9f20a546b1329
Freeze roadmap blob: 7a2e58253ddd9a9795dde59da864019931d3c5ee
Unchanged readiness blob: ee696d6a4054fd5476f81f3d7c2c9b6e6e8cd7ab

The authorization-persistence commit must have the freeze commit as
parent and change only the Master Roadmap by this exact append.

After that commit exists and a separate Owner execution instruction is
issued, only the four guard paths enumerated at lines 4832–4835 of the
freeze commit's Master Roadmap may change.

Preserve the reviewed candidate except for the narrowly necessary
recognition and enforcement of this exact committed authorization.
Observe and pin its actual commit, parent and resulting roadmap blob.
Verify the preserved prefix and exact append. Missing, pending,
altered or mismatched authorization must fail live recognition.
No future hash is supplied or invented.

Retain the shared recognizer, all historical pins/security predicates,
negative tests, exact HARDEN1 source oracle, independent repository-layer
checks and all eight protected raw-byte identities. No broad exceptions,
live-derived expected source, skipped assertions or historical fallback
may admit unauthorized current states.

Run CUI-2A0, HARDEN1, M1B, M3, unchanged M1a and unchanged R09q
sequentially using flutter test --no-pub. Require zero failures,
meaningful live positive/adversarial evidence, git diff --check and
independent Big Pickle acceptance of the resulting exact composition.
Reviewer substitution requires an explicit Owner decision naming it.

STOP for any identity, scope, preservation, validation or review failure.
Existing 193/193 and independent PASS remain prior candidate evidence;
changed sources/composition require renewed focused validation/review.

R10.5-D remains ACCEPTED / FROZEN, AUDIT-ONLY / IMPLEMENTATION NO.
Commercial implementation remains NO; CUI-2A1/M4/M5 remain unauthorized.
No UI, visual-test, SQL/Supabase, policy, contract or other-file changes.
Git closure requires separate explicit Owner authorization.
''';
final _r10Sources = <String, String>{
  ..._ownerPlanningSources, cui2a0RoadmapPath: r10AuthorizedRoadmap,
  r10ContractPath: r10FrozenContract,
};
final _r10PinsMatch = _ownerPlanningPinsMatch &&
    _git(['rev-parse', r10AuthorizationCommit + '^']).trim() == r10FreezeCommit &&
    _samePaths(_paths(_git(['diff', '--name-status', '--no-renames',
      r10FreezeCommit, r10AuthorizationCommit])), ['M\t' + cui2a0RoadmapPath]) &&
    _git(['rev-parse', r10AuthorizationCommit + ':' + cui2a0RoadmapPath]).trim() == r10AuthorizedRoadmapBlob &&
    _git(['rev-parse', r10AuthorizationCommit + ':' + r10ContractPath]).trim() == r10ContractBlob &&
    _git(['rev-parse', r10AuthorizationCommit + ':' + ownerPlanningReadinessPath]).trim() == ownerPlanningReadinessBlob &&
    _git(['rev-parse', r10AuthorizationCommit + ':' + cui2a1ContractPath]).trim() == cui2a1ContractBlob &&
    r10AuthorizedRoadmap == r10FrozenRoadmap + r10AuthorizationAppend &&
    _git(['rev-parse', r10FreezeCommit + '^']).trim() == r10FreezeParent &&
    _git(['rev-parse', r10FreezeParent + '^']).trim() == ownerPlanningAuthorizationCommit &&
    _samePaths(_paths(_git(['diff', '--name-status', '--no-renames',
      ownerPlanningAuthorizationCommit, r10FreezeParent])),
      cui2a1CompatibilityPaths.map((p) => 'M\t' + p)) &&
    _samePaths(_paths(_git(['diff', '--name-status', '--no-renames',
      r10FreezeParent, r10FreezeCommit])),
      ['M\t' + cui2a0RoadmapPath, 'A\t' + r10ContractPath]) &&
    _git(['rev-parse', r10FreezeParent + ':' + cui2a0RoadmapPath]).trim() == ownerPlanningAuthorizationRoadmapBlob &&
    _git(['rev-parse', r10FreezeCommit + ':' + cui2a0RoadmapPath]).trim() == r10RoadmapBlob &&
    _git(['rev-parse', r10FreezeCommit + ':' + r10ContractPath]).trim() == r10ContractBlob &&
    _git(['rev-parse', r10FreezeCommit + ':' + ownerPlanningReadinessPath]).trim() == ownerPlanningReadinessBlob &&
    _git(['rev-parse', r10FreezeCommit + ':' + cui2a1ContractPath]).trim() == cui2a1ContractBlob &&
    _r10GuardBlobs.entries.every((e) => [r10FreezeParent, r10FreezeCommit, r10AuthorizationCommit].every(
      (commit) => _git(['rev-parse', commit + ':' + e.key]).trim() == e.value)) &&
    r10FrozenRoadmap.startsWith(ownerPlanningRoadmap) &&
    RegExp(r'^STATUS: ACCEPTED / FROZEN$', multiLine: true).hasMatch(r10FrozenContract) &&
    RegExp(r'^IMPLEMENTATION_AUTHORIZED: NO$', multiLine: true).hasMatch(r10FrozenContract) &&
    [
      'R10.5-D_CONTRACT_STATUS: ACCEPTED / FROZEN',
      'R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO',
      'IMPLEMENTATION_AUTHORIZED: NO', 'COMMERCIAL_CURRENT_SLICE: NONE',
      'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO', 'CUI2A1_IMPLEMENTATION_AUTHORIZED: NO',
      'M4_STATE: NOT AUTHORIZED', 'M5_STATE: NOT AUTHORIZED',
    ].every(r10FreezeAppend.contains);

bool matchesR10FreezeDocuments(String roadmap, String contract,
    String readiness, String r10Contract) =>
    _r10PinsMatch && roadmap == r10AuthorizedRoadmap &&
    contract == cui2a1FrozenContract && readiness == ownerPlanningReadiness &&
    r10Contract == r10FrozenContract;

bool hasR10FreezeBoundary({
  Map<String, String>? sources,
  Iterable<String>? libDocsChanges, Iterable<String>? migrationNames,
  Iterable<String>? predecessorChanges, Iterable<String>? backendChanges,
  Iterable<String>? untrackedAuthorityPaths, Iterable<String>? repositoryChanges,
  Iterable<String>? committedChanges, Iterable<String>? stagedChanges,
  Iterable<String>? unstagedChanges, Iterable<String>? untrackedPaths,
  Map<String, String>? preservedBlobs, Map<String, String>? pins,
  String? executionCommit, String? committedStatus, String? stagedStatus, String? unstagedStatus,
  String implementationCommit = cui2a0AcceptedImplementationCommit,
  String closureCommit = cui2a0AcceptedClosureCommit,
  String freezeCommit = cui2a1FreezeCommit,
  String compatibilityCommit = cui2a1CompatibilityCommit,
}) {
  final candidatePins = pins ?? _r10Pins;
  if (candidatePins.length != _r10Pins.length ||
      !_r10Pins.entries.every((e) => candidatePins[e.key] == e.value) ||
      freezeCommit != cui2a1FreezeCommit || compatibilityCommit != cui2a1CompatibilityCommit ||
      !_r10PinsMatch || _git(['branch', '--show-current']).trim() != 'main') return false;
  // HEAD is the actual side of ancestry/delta verification, never an expected pin.
  final actualHead = executionCommit ?? _git(['rev-parse', 'HEAD']).trim();
  if (_git(['merge-base', r10AuthorizationCommit, actualHead]).trim() != r10AuthorizationCommit) return false;
  final actual = sources ?? {
    for (final path in _r10Sources.keys) path: File(path).readAsStringSync().replaceAll('\r\n', '\n'),
  };
  if (actual.length != _r10Sources.length ||
      !_r10Sources.entries.every((e) => actual[e.key] == e.value) ||
      !matchesR10FreezeDocuments(actual[cui2a0RoadmapPath]!, actual[cui2a1ContractPath]!, actual[ownerPlanningReadinessPath]!, actual[r10ContractPath]!)) return false;
  final committed = committedChanges ?? _paths(_git(['diff', '--name-only', '--no-renames', r10AuthorizationCommit, actualHead]));
  final staged = stagedChanges ?? _paths(_git(['diff', '--cached', '--name-only', '--no-renames']));
  final unstaged = unstagedChanges ?? _paths(_git(['diff', '--name-only', '--no-renames']));
  final changes = repositoryChanges ?? _paths(_git(['diff', '--name-only', '--no-renames', r10AuthorizationCommit]));
  final workingPaths = <String>{...cui2a1CompatibilityPaths, ..._cui2a1DirtyPaths};
  if ([...committed, ...staged].any((p) => !cui2a1CompatibilityPaths.contains(p)) ||
      unstaged.any((p) => !workingPaths.contains(p)) ||
      !_cui2a1DirtyPaths.every(changes.contains) || changes.any((p) => !workingPaths.contains(p)) ||
      !_samePaths(untrackedPaths ?? _paths(_git(['ls-files', '--others', '--exclude-standard'])), _cui2a1UntrackedPaths) ||
      !_onlyModifiedPaths(committedStatus ?? _git(['diff', '--name-status', '--no-renames', r10AuthorizationCommit, actualHead]), cui2a1CompatibilityPaths) ||
      !_onlyModifiedPaths(stagedStatus ?? _git(['diff', '--cached', '--name-status', '--no-renames']), cui2a1CompatibilityPaths) ||
      !_onlyModifiedPaths(unstagedStatus ?? _git(['diff', '--name-status', '--no-renames']), workingPaths)) return false;
  final protected = preservedBlobs ?? {
    for (final path in _cui2a1ProtectedBlobs.keys) path: _git(['hash-object', '--no-filters', '--', path]).trim(),
  };
  if (protected.length != _cui2a1ProtectedBlobs.length ||
      !_cui2a1ProtectedBlobs.entries.every((e) => protected[e.key] == e.value)) return false;
  final docsChanges = libDocsChanges ?? _paths(_git(['diff', '--name-only', '--no-renames', cui2a0AuthorizationCommit, '--', 'lib', 'docs']));
  if (!_samePaths(docsChanges, [cui2a0RoadmapPath, cui2a0ClosureReportPath, cui2a1ContractPath, ownerPlanningReadinessPath, r10ContractPath])) return false;
  // Validate the live freeze and every independent inventory before projecting
  // onto the unchanged Owner-planning recognizer and its historical SQL gate.
  return hasOwnerPlanningDocumentaryBoundary(
    sources: {
      for (final path in _ownerPlanningSources.keys)
        path: path == cui2a0RoadmapPath ? ownerPlanningRoadmap : actual[path]!,
    },
    libDocsChanges: docsChanges.where((p) => p != r10ContractPath),
    repositoryChanges: _cui2a1DirtyPaths,
    committedChanges: const [], stagedChanges: const [], unstagedChanges: const [],
    committedStatus: '', stagedStatus: '', unstagedStatus: '',
    executionCommit: r10FreezeParent,
    untrackedPaths: untrackedPaths, preservedBlobs: protected,
    migrationNames: migrationNames, predecessorChanges: predecessorChanges,
    backendChanges: backendChanges, untrackedAuthorityPaths: untrackedAuthorityPaths,
    implementationCommit: implementationCommit, closureCommit: closureCommit,
    freezeCommit: freezeCommit, compatibilityCommit: compatibilityCommit,
  );
}

bool hasOwnerPlanningFixtureBoundary({
  Map<String, String>? sources,
  Iterable<String>? libDocsChanges, Iterable<String>? migrationNames,
  Iterable<String>? predecessorChanges, Iterable<String>? backendChanges,
  Iterable<String>? untrackedAuthorityPaths, Iterable<String>? repositoryChanges,
  Iterable<String>? committedChanges, Iterable<String>? stagedChanges,
  Iterable<String>? unstagedChanges, Iterable<String>? untrackedPaths,
  Map<String, String>? preservedBlobs, Map<String, String>? pins,
  String? executionCommit, String? committedStatus, String? stagedStatus, String? unstagedStatus,
  String implementationCommit = cui2a0AcceptedImplementationCommit,
  String closureCommit = cui2a0AcceptedClosureCommit,
  String freezeCommit = cui2a1FreezeCommit,
  String compatibilityCommit = cui2a1CompatibilityCommit,
}) => hasOwnerPlanningDocumentaryBoundary(
  sources: sources ?? _ownerPlanningSources,
  libDocsChanges: libDocsChanges ?? [cui2a0RoadmapPath, cui2a0ClosureReportPath, cui2a1ContractPath, ownerPlanningReadinessPath],
  migrationNames: migrationNames,
  predecessorChanges: predecessorChanges,
  backendChanges: backendChanges,
  untrackedAuthorityPaths: untrackedAuthorityPaths,
  repositoryChanges: repositoryChanges ?? _cui2a1DirtyPaths,
  committedChanges: committedChanges ?? const [],
  stagedChanges: stagedChanges ?? const [],
  unstagedChanges: unstagedChanges,
  untrackedPaths: untrackedPaths,
  preservedBlobs: preservedBlobs,
  pins: pins,
  executionCommit: executionCommit ?? r10FreezeParent,
  committedStatus: committedStatus ?? '',
  stagedStatus: stagedStatus ?? '',
  unstagedStatus: unstagedStatus,
  implementationCommit: implementationCommit,
  closureCommit: closureCommit,
  freezeCommit: freezeCommit,
  compatibilityCommit: compatibilityCommit,
);

void _registerR10FreezeBoundaryTests() {
  test('R10 freeze live recognition is distinct from historical documentary fixtures', () {
    expect(_r10PinsMatch, isTrue);
    expect(hasR10FreezeBoundary(), isTrue);
    expect(hasOwnerPlanningFixtureBoundary(), isTrue);
    expect(hasOwnerPlanningDocumentaryBoundary(), isFalse);
    expect(hasR10FreezeBoundary(sources: _ownerPlanningSources), isFalse);
    expect(hasR10FreezeBoundary(executionCommit: r10FreezeCommit), isFalse);
    expect(hasR10FreezeBoundary(executionCommit: r10FreezeParent), isFalse);
    expect(hasR10FreezeBoundary(executionCommit: ownerPlanningCommit), isFalse);
  });
  test('R10 freeze requires the exact committed prospective authorization', () {
    expect(_git(['rev-parse', r10AuthorizationCommit + '^']).trim(), r10FreezeCommit);
    expect(r10AuthorizedRoadmap, r10FrozenRoadmap + r10AuthorizationAppend);
    expect(hasR10FreezeBoundary(), isTrue);
    expect(hasR10FreezeBoundary(sources: {..._r10Sources, cui2a0RoadmapPath: r10FrozenRoadmap}), isFalse);
    expect(hasR10FreezeBoundary(executionCommit: r10FreezeCommit), isFalse,
      reason: 'A pending working-copy authorization cannot replace a committed ancestor');
    expect(hasR10FreezeBoundary(pins: {..._r10Pins, 'authorization': r10FreezeCommit}), isFalse);
    expect(hasR10FreezeBoundary(pins: {..._r10Pins, 'authorizedRoadmap': r10RoadmapBlob}), isFalse);
    for (final key in [
      r10FreezeCommit, r10FreezeParent, r10ContractBlob, r10RoadmapBlob, ownerPlanningReadinessBlob,
      'prospectively authorizes', 'separate Owner execution instruction',
      'lines 4832–4835', 'Missing, pending,', 'independent Big Pickle acceptance',
      'all eight protected raw-byte identities', 'Commercial implementation remains NO',
      'CUI-2A1/M4/M5 remain unauthorized', 'IMPLEMENTATION NO',
    ]) {
      expect(r10AuthorizationAppend, contains(key));
      final changed = r10FrozenRoadmap + r10AuthorizationAppend.replaceFirst(key, 'unauthorized');
      expect(changed, isNot(r10AuthorizedRoadmap));
      expect(hasR10FreezeBoundary(sources: {..._r10Sources, cui2a0RoadmapPath: changed}), isFalse, reason: key);
    }
  });
  test('R10 freeze rejects wrong and missing pins and retained authority pins', () {
    for (final pin in _r10Pins.entries) {
      expect(hasR10FreezeBoundary(pins: {..._r10Pins, pin.key: '0000000000000000000000000000000000000000'}), isFalse);
      expect(hasR10FreezeBoundary(pins: Map.from(_r10Pins)..remove(pin.key)), isFalse);
    }
    expect(hasR10FreezeBoundary(pins: {..._r10Pins, 'future': r10FreezeCommit}), isFalse);
    expect(hasR10FreezeBoundary(freezeCommit: ownerPlanningCommit), isFalse);
    expect(hasR10FreezeBoundary(compatibilityCommit: ownerPlanningCommit), isFalse);
  });
  test('R10 freeze rejects altered missing or extra documentary and security sources', () {
    for (final entry in _r10Sources.entries) {
      expect(hasR10FreezeBoundary(sources: {..._r10Sources, entry.key: entry.value + '\nunauthorized'}), isFalse, reason: entry.key);
      expect(hasR10FreezeBoundary(sources: Map.from(_r10Sources)..remove(entry.key)), isFalse, reason: entry.key);
    }
    expect(hasR10FreezeBoundary(sources: {..._r10Sources, r10ContractPath + '.bak': r10FrozenContract}), isFalse);
    for (final key in ['STATUS: ACCEPTED / FROZEN', 'IMPLEMENTATION_AUTHORIZED: NO',
      'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO', 'CUI2A1_IMPLEMENTATION_AUTHORIZED: NO',
      'M4_STATE: NOT AUTHORIZED', 'M5_STATE: NOT AUTHORIZED']) {
      expect(r10FrozenContract, contains(key));
      final changed = r10FrozenContract.replaceFirst(key, 'unauthorized');
      expect(changed, isNot(r10FrozenContract));
      expect(hasR10FreezeBoundary(sources: {..._r10Sources, r10ContractPath: changed}), isFalse, reason: key);
    }
  });
  test('R10 freeze rejects premature authority future records and altered historical prefix', () {
    for (final key in [
      'R10.5-D_CONTRACT_STATUS: ACCEPTED / FROZEN',
      'R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO', 'IMPLEMENTATION_AUTHORIZED: NO',
      'COMMERCIAL_CURRENT_SLICE: NONE', 'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO',
      'CUI2A1_IMPLEMENTATION_AUTHORIZED: NO', 'CUI2A0_STATE: CLOSED',
      'CUI1_STATE: CLOSED', 'M3_STATE: CLOSED', 'M4_STATE: NOT AUTHORIZED', 'M5_STATE: NOT AUTHORIZED',
      'BACKEND_AUTHORITY_DELTA: ZERO', 'PUBLICATION_AUTHORITY_DELTA: ZERO',
      'ENTITLEMENT_AUTHORITY_DELTA: ZERO', 'PAYMENT_AUTHORITY_DELTA: ZERO',
    ]) {
      expect(r10FreezeAppend, contains(key));
      final changed = ownerPlanningRoadmap + r10FreezeAppend.replaceFirst(key, 'unauthorized') + r10AuthorizationAppend;
      expect(changed, isNot(r10AuthorizedRoadmap));
      expect(hasR10FreezeBoundary(sources: {..._r10Sources, cui2a0RoadmapPath: changed}), isFalse, reason: key);
    }
    for (final changed in [
      ownerPlanningRoadmap, r10FrozenRoadmap,
      r10FrozenRoadmap.substring(0, r10FrozenRoadmap.length - 1),
      r10FrozenRoadmap + '\n# Future execution authorization\n',
      r10FrozenRoadmap.replaceFirst('ROADMAP_VERSION: 1', 'ROADMAP_VERSION: 2'),
      r10AuthorizedRoadmap + '\n# Future execution authorization\n',
      r10AuthorizedRoadmap.substring(0, r10AuthorizedRoadmap.length - 1),
      r10AuthorizedRoadmap.replaceFirst('ROADMAP_VERSION: 1', 'ROADMAP_VERSION: 2'),
    ]) {
      expect(hasR10FreezeBoundary(sources: {..._r10Sources, cui2a0RoadmapPath: changed}), isFalse);
    }
  });
  test('R10 freeze rejects independent repository-layer drift and wrong path status', () {
    for (final path in [
      ..._r10Sources.keys, ...r10PresentationPaths, ..._cui2a1ProtectedBlobs.keys,
      r10ContractPath + '.bak', 'docs/unauthorized.md', 'test/unauthorized_test.dart',
      'lib/features/business/presentation/screens/admin_business_draft_screen.dart',
      'supabase/migrations/00027_unauthorized.sql', 'supabase/config.toml', 'pubspec.yaml',
    ]) {
      expect(hasR10FreezeBoundary(committedChanges: [path]), isFalse, reason: 'Committed ' + path);
      expect(hasR10FreezeBoundary(stagedChanges: [path]), isFalse, reason: 'Staged ' + path);
      if (!_cui2a1DirtyPaths.contains(path)) {
        expect(hasR10FreezeBoundary(unstagedChanges: [path]), isFalse, reason: 'Unstaged ' + path);
        expect(hasR10FreezeBoundary(repositoryChanges: [..._cui2a1DirtyPaths, path]), isFalse);
      }
      expect(hasR10FreezeBoundary(untrackedPaths: [..._cui2a1UntrackedPaths, path]), isFalse);
    }
    for (final path in cui2a1CompatibilityPaths) {
      for (final status in ['A', 'D', 'T', 'R100', 'C100']) {
        final delta = status + '\t' + path + '\n';
        expect(hasR10FreezeBoundary(committedStatus: delta), isFalse);
        expect(hasR10FreezeBoundary(stagedStatus: delta), isFalse);
        expect(hasR10FreezeBoundary(unstagedStatus: delta), isFalse);
      }
    }
    expect(hasR10FreezeBoundary(repositoryChanges: []), isFalse);
    expect(hasR10FreezeBoundary(untrackedPaths: []), isFalse);
    expect(hasR10FreezeBoundary(libDocsChanges: [cui2a0RoadmapPath, cui2a0ClosureReportPath,
      cui2a1ContractPath, ownerPlanningReadinessPath]), isFalse);
  });
  test('R10 freeze preserves every protected byte and retained SQL gate', () {
    for (final entry in _cui2a1ProtectedBlobs.entries) {
      expect(hasR10FreezeBoundary(preservedBlobs: {..._cui2a1ProtectedBlobs,
        entry.key: '0000000000000000000000000000000000000000'}), isFalse);
      expect(hasR10FreezeBoundary(preservedBlobs: Map.from(_cui2a1ProtectedBlobs)..remove(entry.key)), isFalse);
    }
    final names = Directory('supabase/migrations').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toList();
    expect(hasR10FreezeBoundary(migrationNames: [...names, '00027_unauthorized.sql']), isFalse);
    expect(hasR10FreezeBoundary(predecessorChanges: ['supabase/migrations/00001_initial_schema.sql']), isFalse);
    expect(hasR10FreezeBoundary(backendChanges: ['supabase/config.toml']), isFalse);
  });
}

void _registerOwnerPlanningBoundaryTests() {
  test('Owner planning live branch and historical A1 fixture remain distinct', () {
    expect(_ownerPlanningPinsMatch, isTrue);
    expect(hasOwnerPlanningFixtureBoundary(), isTrue);
    expect(hasAuthorizedCui2a0Boundary(
      sources: _cui2a1Sources,
      libDocsChanges: [cui2a0RoadmapPath, cui2a0ClosureReportPath, cui2a1ContractPath],
      repositoryChanges: _cui2a1DirtyPaths, committedChanges: [], stagedChanges: [],
    ), isTrue);
    expect(hasOwnerPlanningFixtureBoundary(sources: _cui2a1Sources), isFalse);
    expect(hasAuthorizedCui2a0Boundary(), isFalse);
    expect(hasOwnerPlanningFixtureBoundary(executionCommit: ownerPlanningCommit), isFalse,
      reason: 'Pending/uncommitted authorization must not enable the live branch');
  });
  test('Owner planning live branch rejects each wrong or missing pin', () {
    for (final pin in _ownerPlanningPins.entries) {
      expect(hasOwnerPlanningFixtureBoundary(pins: {..._ownerPlanningPins, pin.key: '0000000000000000000000000000000000000000'}), isFalse);
      expect(hasOwnerPlanningFixtureBoundary(pins: Map.from(_ownerPlanningPins)..remove(pin.key)), isFalse);
    }
  });
  test('Owner planning live branch rejects every missing or changed source', () {
    for (final source in _ownerPlanningSources.entries) {
      expect(hasOwnerPlanningFixtureBoundary(sources: {..._ownerPlanningSources, source.key: '${source.value}\nunauthorized'}), isFalse, reason: source.key);
      expect(hasOwnerPlanningFixtureBoundary(sources: Map.from(_ownerPlanningSources)..remove(source.key)), isFalse);
    }
    expect(hasOwnerPlanningFixtureBoundary(sources: {..._ownerPlanningSources, 'docs/extra.md': 'extra'}), isFalse);
  });
  test('Owner planning live branch rejects final authority mutations and future records', () {
    final planning = _git(['cat-file', 'blob', ownerPlanningRoadmapBlob]);
    final authorization = ownerPlanningRoadmap.substring(planning.length);
    for (final mutation in <String, String>{
      'OWNER_PLANNING_STATIC_COMPATIBILITY_MODIFICATIONS_AUTHORIZED: YES': 'OWNER_PLANNING_STATIC_COMPATIBILITY_MODIFICATIONS_AUTHORIZED: NO',
      'IMPLEMENTATION_AUTHORIZED: NO': 'IMPLEMENTATION_AUTHORIZED: YES',
      'R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO': 'R10.5-D_STATE: IMPLEMENTATION YES',
      'R10.5-D_CONTRACT_FREEZE: NOT AUTHORIZED BY THIS RECORD': 'R10.5-D_CONTRACT_FREEZE: FROZEN',
      'COMMERCIAL_CURRENT_SLICE: NONE': 'COMMERCIAL_CURRENT_SLICE: CUI-2A1',
      'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO': 'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES',
      'CUI2A1_IMPLEMENTATION_AUTHORIZED: NO': 'CUI2A1_IMPLEMENTATION_AUTHORIZED: YES',
      'CUI2A0_STATE: CLOSED': 'CUI2A0_STATE: OPEN', 'CUI1_STATE: CLOSED': 'CUI1_STATE: OPEN',
      'M3_STATE: CLOSED': 'M3_STATE: OPEN', 'M4_STATE: NOT AUTHORIZED': 'M4_STATE: AUTHORIZED',
      'M5_STATE: NOT AUTHORIZED': 'M5_STATE: AUTHORIZED',
      'BACKEND_AUTHORITY_DELTA: ZERO': 'BACKEND_AUTHORITY_DELTA: NONZERO',
      'PUBLICATION_AUTHORITY_DELTA: ZERO': 'PUBLICATION_AUTHORITY_DELTA: NONZERO',
      'ENTITLEMENT_AUTHORITY_DELTA: ZERO': 'ENTITLEMENT_AUTHORITY_DELTA: NONZERO',
      'PAYMENT_AUTHORITY_DELTA: ZERO': 'PAYMENT_AUTHORITY_DELTA: NONZERO',
    }.entries) {
      expect(authorization, contains(mutation.key));
      expect(hasOwnerPlanningFixtureBoundary(sources: {..._ownerPlanningSources,
        cui2a0RoadmapPath: planning + authorization.replaceFirst(mutation.key, mutation.value),
      }), isFalse, reason: mutation.key);
    }
    for (final roadmap in [
      planning, cui2a1CompatibilityRoadmap,
      ownerPlanningRoadmap.substring(0, ownerPlanningRoadmap.length - 1),
      '$ownerPlanningRoadmap\n# Arbitrary future record\n', '$ownerPlanningRoadmap\n# R10.5-D CONTRACT FROZEN\n',
      ownerPlanningRoadmap.replaceFirst('ROADMAP_VERSION: 1', 'ROADMAP_VERSION: 2'),
    ]) {
      expect(hasOwnerPlanningFixtureBoundary(sources: {..._ownerPlanningSources, cui2a0RoadmapPath: roadmap}), isFalse);
    }
  });
  test('Owner planning live branch rejects hidden drift across repository layers', () {
    for (final path in [
      cui2a0RoadmapPath, ownerPlanningReadinessPath, cui2a1ContractPath, '$ownerPlanningReadinessPath.bak',
      'docs/unauthorized.md', 'test/unauthorized_test.dart', 'test/new_guard_test.dart',
      'lib/features/profile/presentation/profile_screen.dart', 'lib/features/profile/presentation/user_area_screen.dart',
      'test/v1_r10_5d_profile_user_area_visual_test.dart',
      'lib/features/business/presentation/screens/admin_business_draft_screen.dart',
      'test/commercial_cui2a1_admin_business_draft_boundary_test.dart',
      'supabase/migrations/00027_unauthorized.sql', cui2a0MigrationPath, cui2a0RuntimePath,
      'supabase/config.toml', 'pubspec.yaml', ..._cui2a1ProtectedBlobs.keys,
    ]) {
      expect(hasOwnerPlanningFixtureBoundary(committedChanges: [path]), isFalse, reason: 'Committed $path');
      expect(hasOwnerPlanningFixtureBoundary(stagedChanges: [path]), isFalse, reason: 'Staged $path');
      if (!_cui2a1DirtyPaths.contains(path)) {
        expect(hasOwnerPlanningFixtureBoundary(unstagedChanges: [path]), isFalse, reason: 'Unstaged $path');
        expect(hasOwnerPlanningFixtureBoundary(repositoryChanges: [..._cui2a1DirtyPaths, path]), isFalse);
      }
      expect(hasOwnerPlanningFixtureBoundary(untrackedPaths: [..._cui2a1UntrackedPaths, path]), isFalse);
    }
    for (final path in cui2a1CompatibilityPaths) {
      for (final status in ['A', 'D', 'T', 'R100', 'C100']) {
        final delta = '$status\t$path\n';
        expect(hasOwnerPlanningFixtureBoundary(committedStatus: delta), isFalse);
        expect(hasOwnerPlanningFixtureBoundary(stagedStatus: delta), isFalse);
        expect(hasOwnerPlanningFixtureBoundary(unstagedStatus: delta), isFalse);
      }
    }
    expect(hasOwnerPlanningFixtureBoundary(repositoryChanges: []), isFalse);
    expect(hasOwnerPlanningFixtureBoundary(untrackedPaths: []), isFalse);
    expect(hasOwnerPlanningFixtureBoundary(libDocsChanges: [cui2a0RoadmapPath, cui2a0ClosureReportPath, cui2a1ContractPath]), isFalse);
  });
  test('Owner planning live branch preserves protected bytes and retained SQL gates', () {
    for (final source in _cui2a1ProtectedBlobs.entries) {
      expect(hasOwnerPlanningFixtureBoundary(preservedBlobs: {..._cui2a1ProtectedBlobs,
        source.key: '0000000000000000000000000000000000000000'}), isFalse);
    }
    final names = Directory('supabase/migrations').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toList();
    expect(hasOwnerPlanningFixtureBoundary(migrationNames: [...names, '00027_unauthorized.sql']), isFalse);
    expect(hasOwnerPlanningFixtureBoundary(predecessorChanges: ['supabase/migrations/00001_initial_schema.sql']), isFalse);
    expect(hasOwnerPlanningFixtureBoundary(backendChanges: ['supabase/config.toml']), isFalse);
  });
}

// Explicit historical fixture adapter; never selected to certify live state.
bool hasFrozenCui2a1FixtureBoundary({
  Map<String, String>? sources,
  Iterable<String>? libDocsChanges, Iterable<String>? migrationNames,
  Iterable<String>? predecessorChanges, Iterable<String>? backendChanges,
  Iterable<String>? untrackedAuthorityPaths, Iterable<String>? repositoryChanges,
  Iterable<String>? committedChanges, Iterable<String>? stagedChanges,
  Iterable<String>? untrackedPaths, Map<String, String>? preservedBlobs,
  String implementationCommit = cui2a0AcceptedImplementationCommit,
  String closureCommit = cui2a0AcceptedClosureCommit,
  String freezeCommit = cui2a1FreezeCommit,
  String compatibilityCommit = cui2a1CompatibilityCommit,
}) => hasAuthorizedCui2a0Boundary(
  sources: sources ?? _cui2a1Sources,
  libDocsChanges: libDocsChanges ?? [cui2a0RoadmapPath, cui2a0ClosureReportPath, cui2a1ContractPath],
  repositoryChanges: repositoryChanges ?? _cui2a1DirtyPaths,
  committedChanges: committedChanges ?? const [],
  stagedChanges: stagedChanges ?? const [],
  migrationNames: migrationNames, predecessorChanges: predecessorChanges,
  backendChanges: backendChanges, untrackedAuthorityPaths: untrackedAuthorityPaths,
  untrackedPaths: untrackedPaths, preservedBlobs: preservedBlobs,
  implementationCommit: implementationCommit, closureCommit: closureCommit,
  freezeCommit: freezeCommit, compatibilityCommit: compatibilityCommit,
);
const cui2a1GuardCompositionSource = r'''// Exact frozen documentary recognition; this is not A1 implementation authority.
bool _allowsFrozenCui2a1Composition(
  Iterable<String> changedPaths,
  String roadmap,
  Map<String, String> documents,
  Iterable<String> postClosureImplementationChanges,
) =>
    cui2a0.matchesFrozenCui2a1Documents(
      roadmap, documents[cui2a0.cui2a1ContractPath] ?? '',
    ) &&
    documents.length == _closedCommittedDocuments.length + 1 &&
    _allowsClosedCui2a0Composition(
      changedPaths.where((path) => path != cui2a0.cui2a1ContractPath),
      _cui2a0ClosedRoadmap,
      Map.fromEntries(documents.entries.where(
        (entry) => entry.key != cui2a0.cui2a1ContractPath,
      )),
      postClosureImplementationChanges,
    );

void _registerFrozenCui2a1Tests() {
  final paths = _cui1ChangedPaths(_git([
    'diff', '--name-only', '--no-renames', _cui1BaselineCommit,
  ]));
  final documents = <String, String>{
    for (final path in _closedCommittedDocuments.keys) path: _read(path),
    cui2a0.cui2a1ContractPath: _read(cui2a0.cui2a1ContractPath),
  };
  final roadmap = _read(_cui1RoadmapPath);
  bool accepts({String? candidateRoadmap, Map<String, String>? candidateDocs,
    Iterable<String>? candidatePaths}) => _allowsFrozenCui2a1Composition(
      candidatePaths ?? paths, candidateRoadmap ?? roadmap,
      candidateDocs ?? documents, [],
    );
  test('CUI-2A1 exact committed documentary composition preserves closed fixture', () {
    expect(accepts(), isTrue);
    expect(_allowsClosedCui2a0Composition(
      paths.where((p) => p != cui2a0.cui2a1ContractPath),
      _cui2a0ClosedRoadmap, _closedCommittedDocuments, [],
    ), isTrue);
    expect(_allowsClosedCui2a0Composition(
      [...paths, cui2a0.cui2a1ContractPath],
      _cui2a0ClosedRoadmap, _closedCommittedDocuments, [],
    ), isFalse, reason: 'Historical closure still rejects the later A1 path');
  });
  test('CUI-2A1 live documentary predicate rejects missing or changed source', () {
    for (final entry in documents.entries) {
      expect(accepts(candidateDocs: {
        ...documents, entry.key: '${entry.value}\nunauthorized',
      }), isFalse, reason: entry.key);
      expect(accepts(candidateDocs: Map.from(documents)..remove(entry.key)),
        isFalse, reason: 'Missing ${entry.key}');
    }
  });
  test('CUI-2A1 live documentary predicate rejects suffix and premature authority', () {
    for (final altered in [
      roadmap + '\n# Arbitrary future authorization\n',
      roadmap.substring(0, roadmap.length - 1),
      roadmap.replaceAll('CUI2A1_IMPLEMENTATION_AUTHORIZED: NO',
        'CUI2A1_IMPLEMENTATION_AUTHORIZED: YES'),
      roadmap.replaceAll('COMMERCIAL_CURRENT_SLICE: NONE',
        'COMMERCIAL_CURRENT_SLICE: CUI-2A1'),
      roadmap.replaceAll('CUI2A1_STATIC_COMPATIBILITY_MODIFICATIONS_AUTHORIZED: YES',
        'CUI2A1_STATIC_COMPATIBILITY_MODIFICATIONS_AUTHORIZED: NO'),
    ]) {
      expect(accepts(candidateRoadmap: altered), isFalse);
    }
  });
  test('CUI-2A1 live documentary predicate rejects extra and lookalike paths', () {
    for (final path in [
      '${cui2a0.cui2a1ContractPath}.bak',
      cui2a0.cui2a1ContractPath.replaceFirst('_V1.md', '_V2.md'),
      'docs/unauthorized.md', 'test/unauthorized_test.dart',
      'lib/features/business/presentation/screens/admin_business_draft_screen.dart',
      'supabase/migrations/00027_unauthorized.sql',
    ]) {
      expect(accepts(candidatePaths: [...paths, path]), isFalse, reason: path);
    }
  });
}

''';
// Mechanical source expectation for the retained M1b -> HARDEN historical pin.
// The immutable historical oracle remains checked at the authorization commit.
String compatibleFrozenHardenSource(String historical) => historical
    .replaceFirst('bool _matchesCui1MediaAuthority',
      cui2a1GuardCompositionSource + 'bool _matchesCui1MediaAuthority')
    .replaceFirst(
      'for (final path in _closedCommittedDocuments.keys) path: _read(path),\n      };',
      'for (final path in _closedCommittedDocuments.keys) path: _read(path),\n'
      '        cui2a0.cui2a1ContractPath: _read(cui2a0.cui2a1ContractPath),\n      };')
    .replaceFirst('}) => _allowsClosedCui2a0Composition(',
      '}) => _allowsFrozenCui2a1Composition(')
    .replaceFirst(
      '        \'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A1_ADMIN_BUSINESS_DRAFT_CONSOLE_IMPLEMENTATION_CONTRACT_V1.md\',',
      '        \'docs/architecture/contracts/CIVILPEDIA_COMMERCIAL_CUI2A1_ADMIN_BUSINESS_DRAFT_CONSOLE_IMPLEMENTATION_CONTRACT_V2.md\',')
    .replaceFirst('void main() {', 'void main() {\n  _registerFrozenCui2a1Tests();')
    .replaceFirst(
      '? _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions\n',
      '? _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend\n')
    .replaceFirst(
      'expect(roadmap.substring(checkpoint.length), _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions);',
      'expect(roadmap.substring(checkpoint.length), _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend);');

const ownerPlanningGuardCompositionSource = r'''// Exact Owner planning extension. No historical fallback selects this live state.
bool _allowsOwnerPlanningComposition(
  Iterable<String> changedPaths,
  String roadmap,
  Map<String, String> documents,
  Iterable<String> postClosureImplementationChanges,
) =>
    cui2a0.matchesOwnerPlanningDocuments(
      roadmap, documents[cui2a0.cui2a1ContractPath] ?? '',
      documents[cui2a0.ownerPlanningReadinessPath] ?? '',
    ) &&
    documents.length == _closedCommittedDocuments.length + 2 &&
    _allowsFrozenCui2a1Composition(
      changedPaths.where((path) => path != cui2a0.ownerPlanningReadinessPath),
      cui2a0.cui2a1CompatibilityRoadmap,
      Map.fromEntries(documents.entries.where(
        (entry) => entry.key != cui2a0.ownerPlanningReadinessPath,
      )),
      postClosureImplementationChanges,
    );

void _registerOwnerPlanningTests() {
  final paths = _cui1ChangedPaths(_git([
    'diff', '--name-only', '--no-renames', _cui1BaselineCommit,
  ]));
  final documents = <String, String>{
    for (final path in _closedCommittedDocuments.keys) path: _read(path),
    cui2a0.cui2a1ContractPath: _read(cui2a0.cui2a1ContractPath),
    cui2a0.ownerPlanningReadinessPath: _read(cui2a0.ownerPlanningReadinessPath),
  };
  final roadmap = _read(_cui1RoadmapPath);
  bool accepts({String? candidateRoadmap, Map<String, String>? candidateDocs,
    Iterable<String>? candidatePaths, Iterable<String>? implementationChanges}) =>
      _allowsOwnerPlanningComposition(
        candidatePaths ?? paths, candidateRoadmap ?? roadmap,
        candidateDocs ?? documents, implementationChanges ?? [],
      );
  test('Owner planning exact live consumer and historical rejection are distinct', () {
    expect(accepts(), isTrue);
    expect(cui2a0.hasOwnerPlanningDocumentaryBoundary(), isTrue);
    expect(_allowsFrozenCui2a1Composition(paths, roadmap, documents, []), isFalse);
    expect(accepts(candidateRoadmap: cui2a0.cui2a1CompatibilityRoadmap), isFalse);
  });
  test('Owner planning consumer rejects missing or altered documentary identities', () {
    for (final entry in documents.entries) {
      expect(accepts(candidateDocs: {...documents, entry.key: '${entry.value}\nunauthorized'}), isFalse);
      expect(accepts(candidateDocs: Map.from(documents)..remove(entry.key)), isFalse);
    }
    for (final altered in [
      '$roadmap\n# Arbitrary future authorization\n', '$roadmap\n# R10.5-D CONTRACT FROZEN\n',
      roadmap.substring(0, roadmap.length - 1),
      roadmap.replaceAll('IMPLEMENTATION_AUTHORIZED: NO', 'IMPLEMENTATION_AUTHORIZED: YES'),
      roadmap.replaceAll('COMMERCIAL_CURRENT_SLICE: NONE', 'COMMERCIAL_CURRENT_SLICE: CUI-2A1'),
      roadmap.replaceAll('M4_STATE: NOT AUTHORIZED', 'M4_STATE: AUTHORIZED'),
      roadmap.replaceAll('M5_STATE: NOT AUTHORIZED', 'M5_STATE: AUTHORIZED'),
    ]) {
      expect(accepts(candidateRoadmap: altered), isFalse);
    }
  });
  test('Owner planning consumer rejects extra paths and premature implementation', () {
    for (final path in [
      '${cui2a0.ownerPlanningReadinessPath}.bak', 'docs/unauthorized.md', 'test/unauthorized_test.dart',
      'lib/features/profile/presentation/profile_screen.dart', 'lib/features/profile/presentation/user_area_screen.dart',
      'test/v1_r10_5d_profile_user_area_visual_test.dart',
      'lib/features/business/presentation/screens/admin_business_draft_screen.dart',
      'supabase/migrations/00027_unauthorized.sql',
    ]) {
      expect(accepts(candidatePaths: [...paths, path]), isFalse, reason: path);
      expect(accepts(implementationChanges: [path]), isFalse, reason: path);
    }
  });
}

''';

// Hand-authored exact source extension of the retained HARDEN1 oracle.
// Every anchor must occur exactly once; no live source is used as expected.
String _replaceOwnerPlanningAnchor(String source, String before, String after) {
  if (RegExp(RegExp.escape(before)).allMatches(source).length != 1) {
    throw StateError('Owner planning source anchor mismatch');
  }
  return source.replaceFirst(before, after);
}
String compatibleOwnerPlanningHardenSource(String historical) {
  var source = compatibleFrozenHardenSource(historical);
  source = _replaceOwnerPlanningAnchor(source,
    'postClosureImplementationChanges.isEmpty && cui2a0.hasAuthorizedCui2a0Boundary();',
    'postClosureImplementationChanges.isEmpty && cui2a0.hasOwnerPlanningDocumentaryBoundary();');
  source = _replaceOwnerPlanningAnchor(source,
    'void _registerFrozenCui2a1Tests() {\n  final paths = _cui1ChangedPaths(_git([\n    \'diff\', \'--name-only\', \'--no-renames\', _cui1BaselineCommit,\n  ]));\n  final documents = <String, String>{\n    for (final path in _closedCommittedDocuments.keys) path: _read(path),\n    cui2a0.cui2a1ContractPath: _read(cui2a0.cui2a1ContractPath),\n  };\n  final roadmap = _read(_cui1RoadmapPath);',
    'void _registerFrozenCui2a1Tests() {\n  // Preserve the old branch\'s exact positive and adversarial fixtures.\n  final paths = _cui1ChangedPaths(_git([\n    \'diff\', \'--name-only\', \'--no-renames\', _cui1BaselineCommit, cui2a0.ownerPlanningParent,\n  ]));\n  final documents = <String, String>{\n    ..._closedCommittedDocuments,\n    cui2a0.cui2a1ContractPath: cui2a0.cui2a1FrozenContract,\n  };\n  final roadmap = cui2a0.cui2a1CompatibilityRoadmap;');
  source = _replaceOwnerPlanningAnchor(source,
    '        cui2a0.cui2a1ContractPath: _read(cui2a0.cui2a1ContractPath),\n      };',
    '        cui2a0.cui2a1ContractPath: _read(cui2a0.cui2a1ContractPath),\n        cui2a0.ownerPlanningReadinessPath: _read(cui2a0.ownerPlanningReadinessPath),\n      };');
  source = _replaceOwnerPlanningAnchor(source,
    '      }) => _allowsFrozenCui2a1Composition(',
    '      }) => _allowsOwnerPlanningComposition(');
  source = _replaceOwnerPlanningAnchor(source,
    '? _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend\n',
    '? _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend + cui2a0.ownerPlanningDocumentaryAppend\n');
  source = _replaceOwnerPlanningAnchor(source,
    'expect(roadmap.substring(checkpoint.length), _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend);',
    'expect(roadmap.substring(checkpoint.length), _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend + cui2a0.ownerPlanningDocumentaryAppend);');
  source = _replaceOwnerPlanningAnchor(source,
    '  _registerFrozenCui2a1Tests();',
    '  _registerFrozenCui2a1Tests();\n  _registerOwnerPlanningTests();');
  return _replaceOwnerPlanningAnchor(source,
    'bool _matchesCui1MediaAuthority',
    ownerPlanningGuardCompositionSource + 'bool _matchesCui1MediaAuthority');
}

const r10FreezeGuardCompositionSource = r'''// Exact R10.5-D freeze extension; historical branches remain distinct.
bool _allowsR10FreezeComposition(
  Iterable<String> changedPaths,
  String roadmap,
  Map<String, String> documents,
  Iterable<String> postClosureImplementationChanges,
) =>
    cui2a0.matchesR10FreezeDocuments(
      roadmap, documents[cui2a0.cui2a1ContractPath] ?? '',
      documents[cui2a0.ownerPlanningReadinessPath] ?? '',
      documents[cui2a0.r10ContractPath] ?? '',
    ) &&
    documents.length == _closedCommittedDocuments.length + 3 &&
    _allowsOwnerPlanningComposition(
      changedPaths.where((path) => path != cui2a0.r10ContractPath),
      cui2a0.ownerPlanningRoadmap,
      Map.fromEntries(documents.entries.where(
        (entry) => entry.key != cui2a0.r10ContractPath,
      )),
      postClosureImplementationChanges,
    );

void _registerR10FreezeTests() {
  final paths = _cui1ChangedPaths(_git([
    'diff', '--name-only', '--no-renames', _cui1BaselineCommit,
  ]));
  final documents = <String, String>{
    for (final path in _closedCommittedDocuments.keys) path: _read(path),
    cui2a0.cui2a1ContractPath: _read(cui2a0.cui2a1ContractPath),
    cui2a0.ownerPlanningReadinessPath: _read(cui2a0.ownerPlanningReadinessPath),
    cui2a0.r10ContractPath: _read(cui2a0.r10ContractPath),
  };
  final roadmap = _read(_cui1RoadmapPath);
  bool accepts({String? candidateRoadmap, Map<String, String>? candidateDocs,
    Iterable<String>? candidatePaths, Iterable<String>? implementationChanges}) =>
      _allowsR10FreezeComposition(
        candidatePaths ?? paths, candidateRoadmap ?? roadmap,
        candidateDocs ?? documents, implementationChanges ?? [],
      );
  test('R10 freeze exact live consumer rejects historical fallback', () {
    expect(accepts(), isTrue);
    expect(cui2a0.hasR10FreezeBoundary(), isTrue);
    expect(_allowsOwnerPlanningComposition(paths, roadmap, documents, []), isFalse);
    expect(accepts(candidateRoadmap: cui2a0.ownerPlanningRoadmap), isFalse);
    expect(accepts(candidateRoadmap: cui2a0.r10FrozenRoadmap), isFalse);
    expect(cui2a0.hasR10FreezeBoundary(executionCommit: cui2a0.r10FreezeCommit), isFalse);
  });
  test('R10 freeze consumer rejects changed missing or extra documents', () {
    for (final entry in documents.entries) {
      expect(accepts(candidateDocs: {...documents, entry.key: entry.value + '\nunauthorized'}), isFalse);
      expect(accepts(candidateDocs: Map.from(documents)..remove(entry.key)), isFalse);
    }
    expect(accepts(candidateDocs: {...documents, cui2a0.r10ContractPath + '.bak': cui2a0.r10FrozenContract}), isFalse);
    for (final key in ['STATUS: ACCEPTED / FROZEN', 'IMPLEMENTATION_AUTHORIZED: NO']) {
      expect(cui2a0.r10FrozenContract, contains(key));
      final changed = cui2a0.r10FrozenContract.replaceFirst(key, 'unauthorized');
      expect(changed, isNot(cui2a0.r10FrozenContract));
      expect(accepts(candidateDocs: {...documents, cui2a0.r10ContractPath: changed}), isFalse);
    }
  });
  test('R10 freeze consumer rejects future authority and extra source paths', () {
    for (final changed in [
      roadmap + '\n# Future authorization\n', roadmap.substring(0, roadmap.length - 1),
      roadmap.replaceAll('IMPLEMENTATION_AUTHORIZED: NO', 'IMPLEMENTATION_AUTHORIZED: YES'),
      roadmap.replaceAll('COMMERCIAL_CURRENT_SLICE: NONE', 'COMMERCIAL_CURRENT_SLICE: CUI-2A1'),
      roadmap.replaceAll('M4_STATE: NOT AUTHORIZED', 'M4_STATE: AUTHORIZED'),
      roadmap.replaceAll('M5_STATE: NOT AUTHORIZED', 'M5_STATE: AUTHORIZED'),
    ]) {
      expect(changed, isNot(roadmap));
      expect(accepts(candidateRoadmap: changed), isFalse);
    }
    for (final path in [
      ...cui2a0.r10PresentationPaths, cui2a0.r10ContractPath + '.bak',
      'docs/unauthorized.md', 'test/unauthorized_test.dart',
      'supabase/migrations/00027_unauthorized.sql',
    ]) {
      expect(accepts(candidatePaths: [...paths, path]), isFalse, reason: path);
      expect(accepts(implementationChanges: [path]), isFalse, reason: path);
    }
  });
}

''';

// Exact hand-authored extension of the retained Owner-planning HARDEN1 oracle.
String compatibleR10FreezeHardenSource(String historical) {
  return compatibleR10FreezeHardenSourceFromPlanning(compatibleOwnerPlanningHardenSource(historical));
}
String compatibleR10FreezeHardenSourceFromPlanning(String planning) {
  var source = planning;
  source = _replaceOwnerPlanningAnchor(source,
    r'''postClosureImplementationChanges.isEmpty && cui2a0.hasOwnerPlanningDocumentaryBoundary();''',
    r'''postClosureImplementationChanges.isEmpty && cui2a0.hasR10FreezeBoundary();''');
  source = _replaceOwnerPlanningAnchor(source,
    r'''void _registerOwnerPlanningTests() {
  final paths = _cui1ChangedPaths(_git([
    'diff', '--name-only', '--no-renames', _cui1BaselineCommit,
  ]));
  final documents = <String, String>{
    for (final path in _closedCommittedDocuments.keys) path: _read(path),
    cui2a0.cui2a1ContractPath: _read(cui2a0.cui2a1ContractPath),
    cui2a0.ownerPlanningReadinessPath: _read(cui2a0.ownerPlanningReadinessPath),
  };
  final roadmap = _read(_cui1RoadmapPath);
''',
    r'''void _registerOwnerPlanningTests() {
  final paths = _cui1ChangedPaths(_git([
    'diff', '--name-only', '--no-renames', _cui1BaselineCommit, cui2a0.r10FreezeParent,
  ]));
  final documents = <String, String>{
    ..._closedCommittedDocuments,
    cui2a0.cui2a1ContractPath: cui2a0.cui2a1FrozenContract,
    cui2a0.ownerPlanningReadinessPath: cui2a0.ownerPlanningReadiness,
  };
  final roadmap = cui2a0.ownerPlanningRoadmap;
''');
  source = _replaceOwnerPlanningAnchor(source,
    r'''    expect(cui2a0.hasOwnerPlanningDocumentaryBoundary(), isTrue);''',
    r'''    expect(cui2a0.hasOwnerPlanningFixtureBoundary(), isTrue);''');
  source = _replaceOwnerPlanningAnchor(source,
    r'''        cui2a0.ownerPlanningReadinessPath: _read(cui2a0.ownerPlanningReadinessPath),
      };''',
    r'''        cui2a0.ownerPlanningReadinessPath: _read(cui2a0.ownerPlanningReadinessPath),
        cui2a0.r10ContractPath: _read(cui2a0.r10ContractPath),
      };''');
  source = _replaceOwnerPlanningAnchor(source,
    r'''      }) => _allowsOwnerPlanningComposition(''',
    r'''      }) => _allowsR10FreezeComposition(''');
  source = _replaceOwnerPlanningAnchor(source,
    r'''  _registerOwnerPlanningTests();''',
    r'''  _registerOwnerPlanningTests();
  _registerR10FreezeTests();''');
  source = _replaceOwnerPlanningAnchor(source,
    r'''              ? _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend + cui2a0.ownerPlanningDocumentaryAppend''',
    r'''              ? _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend + cui2a0.ownerPlanningDocumentaryAppend + cui2a0.r10FreezeAppend + cui2a0.r10AuthorizationAppend''');
  source = _replaceOwnerPlanningAnchor(source,
    r'''    expect(roadmap.substring(checkpoint.length), _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend + cui2a0.ownerPlanningDocumentaryAppend);''',
    r'''    expect(roadmap.substring(checkpoint.length), _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend + cui2a0.ownerPlanningDocumentaryAppend + cui2a0.r10FreezeAppend + cui2a0.r10AuthorizationAppend);''');
  return _replaceOwnerPlanningAnchor(source, 'bool _matchesCui1MediaAuthority',
    r10FreezeGuardCompositionSource + 'bool _matchesCui1MediaAuthority');
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
  _registerOwnerPlanningBoundaryTests();
  _registerR10FreezeBoundaryTests();

  test('CUI-2A1 committed documentary pins and historical CLOSED positive', () {
    expect(_cui2a1PinsMatch, isTrue);
    expect(hasFrozenCui2a1FixtureBoundary(), isTrue);
    expect(hasClosedCui2a0Boundary(sources: _acceptedSources,
      libDocsChanges: [cui2a0RoadmapPath, cui2a0ClosureReportPath]), isTrue);
    const wrong = '0000000000000000000000000000000000000000';
    expect(hasFrozenCui2a1FixtureBoundary(freezeCommit: wrong), isFalse);
    expect(hasFrozenCui2a1FixtureBoundary(compatibilityCommit: wrong), isFalse);
    expect(hasFrozenCui2a1FixtureBoundary(sources: _acceptedSources), isFalse,
      reason: 'Historical fallback cannot certify the live A1 composition');
  });
  for (final entry in _cui2a1Sources.entries) {
    test('CUI-2A1 live rejects changed or missing exact source: ${entry.key}', () {
      expect(hasFrozenCui2a1FixtureBoundary(sources: {
        ..._cui2a1Sources, entry.key: '${entry.value}\nunauthorized',
      }), isFalse);
      expect(hasFrozenCui2a1FixtureBoundary(
        sources: Map.from(_cui2a1Sources)..remove(entry.key)), isFalse);
    });
  }
  test('CUI-2A1 live rejects altered authorization and arbitrary suffixes', () {
    final freezeRoadmap = _git(['cat-file', 'blob', cui2a1FreezeRoadmapBlob]);
    final append = cui2a1CompatibilityRoadmap.substring(freezeRoadmap.length);
    for (final mutation in <String, String>{
      'CUI2A1_STATIC_COMPATIBILITY_MODIFICATIONS_AUTHORIZED: YES': 'CUI2A1_STATIC_COMPATIBILITY_MODIFICATIONS_AUTHORIZED: NO',
      'CUI2A1_IMPLEMENTATION_AUTHORIZED: NO': 'CUI2A1_IMPLEMENTATION_AUTHORIZED: YES',
      'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO': 'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES',
      'COMMERCIAL_CURRENT_SLICE: NONE': 'COMMERCIAL_CURRENT_SLICE: CUI-2A1',
      'CUI2A0_STATE: CLOSED': 'CUI2A0_STATE: OPEN',
      'CUI1_STATE: CLOSED': 'CUI1_STATE: OPEN',
      'M3_STATE: CLOSED': 'M3_STATE: OPEN',
      'M4_STATE: NOT AUTHORIZED': 'M4_STATE: AUTHORIZED',
      'M5_STATE: NOT AUTHORIZED': 'M5_STATE: AUTHORIZED',
      'R10.5-D_STATE: AUDIT-ONLY / IMPLEMENTATION NO': 'R10.5-D_STATE: IMPLEMENTATION YES',
      'BACKEND_AUTHORITY_DELTA: ZERO': 'BACKEND_AUTHORITY_DELTA: NONZERO',
    }.entries) {
      expect(append, contains(mutation.key));
      expect(hasFrozenCui2a1FixtureBoundary(sources: {
        ..._cui2a1Sources, cui2a0RoadmapPath:
          freezeRoadmap + append.replaceFirst(mutation.key, mutation.value),
      }), isFalse, reason: mutation.key);
    }
    for (final roadmap in [
      freezeRoadmap,
      cui2a1CompatibilityRoadmap + '\n# Arbitrary future record\n',
      cui2a1CompatibilityRoadmap.replaceFirst('ROADMAP_VERSION: 1', 'ROADMAP_VERSION: 2'),
    ]) {
      expect(hasFrozenCui2a1FixtureBoundary(sources: {
        ..._cui2a1Sources, cui2a0RoadmapPath: roadmap,
      }), isFalse);
    }
  });
  test('CUI-2A1 live rejects all extra tracked and untracked path classes', () {
    for (final path in [
      cui2a1ContractPath, cui2a0RoadmapPath, '$cui2a1ContractPath.bak',
      'lib/features/business/presentation/screens/admin_business_draft_screen.dart',
      'test/commercial_cui2a1_admin_business_draft_boundary_test.dart',
      'test/unrelated_test.dart', 'docs/unauthorized.md',
      'supabase/migrations/00027_unauthorized.sql', cui2a0MigrationPath,
      cui2a0RuntimePath, 'supabase/config.toml', 'pubspec.yaml',
      'artifacts/unauthorized.png', 'test/v1_r09q_security_matrix_test.dart',
      'test/commercial_m1a_private_catalog_migration_test.dart',
    ]) {
      expect(hasFrozenCui2a1FixtureBoundary(repositoryChanges: [
        ..._cui2a1DirtyPaths, path,
      ]), isFalse, reason: path);
      expect(hasFrozenCui2a1FixtureBoundary(untrackedPaths: [
        ..._cui2a1UntrackedPaths, path,
      ]), isFalse, reason: path);
    }
  });
  test('CUI-2A1 live rejects changed protected bytes and missing dirty artifacts', () {
    for (final entry in _cui2a1ProtectedBlobs.entries) {
      expect(hasFrozenCui2a1FixtureBoundary(preservedBlobs: {
        ..._cui2a1ProtectedBlobs, entry.key: '0000000000000000000000000000000000000000',
      }), isFalse, reason: entry.key);
    }
    expect(hasFrozenCui2a1FixtureBoundary(repositoryChanges: []), isFalse);
    expect(hasFrozenCui2a1FixtureBoundary(untrackedPaths: []), isFalse);
  });
  test('CUI-2A1 live rejects committed or staged drift hidden by working-copy restoration', () {
    for (final path in [
      cui2a0RoadmapPath, cui2a1ContractPath, cui2a0MigrationPath,
      'lib/unauthorized.dart', 'test/unauthorized_test.dart',
      ..._cui2a1ProtectedBlobs.keys,
    ]) {
      expect(hasFrozenCui2a1FixtureBoundary(committedChanges: [path]),
        isFalse, reason: 'Committed $path');
      expect(hasFrozenCui2a1FixtureBoundary(stagedChanges: [path]),
        isFalse, reason: 'Staged $path');
    }
  });
  final source=File(cui2a0MigrationPath).readAsStringSync();
  final sql=_clean(source);
  test('T01-T02 exact objects, four permissions, zero provisioning and immutable history',(){
    expect(hasR10FreezeBoundary(),isTrue);
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
    expect(hasR10FreezeBoundary(), isTrue);
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
    expect(hasR10FreezeBoundary(implementationCommit: wrong), isFalse);
    expect(hasR10FreezeBoundary(closureCommit: wrong), isFalse);
  });
  for (final entry in _acceptedSources.entries) {
    test('post-closure rejects changed accepted source: ${entry.key}', () {
      expect(hasClosedCui2a0Boundary(
        libDocsChanges: [cui2a0RoadmapPath, cui2a0ClosureReportPath], sources: {
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
      expect(hasClosedCui2a0Boundary(
        libDocsChanges: [cui2a0RoadmapPath, cui2a0ClosureReportPath], sources: {
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
      expect(hasClosedCui2a0Boundary(sources: _acceptedSources, libDocsChanges: [cui2a0RoadmapPath, cui2a0ClosureReportPath, path]), isFalse, reason: path);
      expect(hasR10FreezeBoundary(untrackedAuthorityPaths: [path]), isFalse, reason: path);
    }
    expect(hasClosedCui2a0Boundary(
      libDocsChanges: [cui2a0RoadmapPath, cui2a0ClosureReportPath], sources: {
      ..._acceptedSources, 'docs/extra.md': 'not authorized',
    }), isFalse);
    expect(hasClosedCui2a0Boundary(
      libDocsChanges: [cui2a0RoadmapPath, cui2a0ClosureReportPath], sources: {
      ..._acceptedSources, cui2a0RoadmapPath: '${_acceptedSources[cui2a0RoadmapPath]}\n# Arbitrary future authority\n',
    }), isFalse);
  });
  test('post-closure rejects 00027, predecessor and arbitrary backend changes', () {
    final migrations = Directory('supabase/migrations').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toList();
    expect(hasR10FreezeBoundary(migrationNames: [...migrations, '00027_unauthorized.sql']), isFalse);
    for (final name in migrations.where((name) => name != cui2a0MigrationName)) {
      expect(hasR10FreezeBoundary(predecessorChanges: ['supabase/migrations/$name']), isFalse, reason: name);
    }
    expect(hasR10FreezeBoundary(backendChanges: ['supabase/tests/arbitrary.sql']), isFalse);
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

