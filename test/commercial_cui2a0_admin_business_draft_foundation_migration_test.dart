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

// Exact literal prospective Owner/Architect record, not a live-file oracle.
const r10PresentationAppend = '\n' r'''# V1-R10.5-D CONDITIONAL PRESENTATION EXECUTION AUTHORIZATION

This is a prospective decision, effective only after explicit Owner adoption and an authorized Owner commit. It asserts no previous production implementation authority.

R10.5-D_CONTRACT_STATUS: ACCEPTED / FROZEN
IMPLEMENTATION_AUTHORIZED: YES — R10.5-D PRESENTATION ONLY, CONDITIONAL ON ALL EXECUTION GATES BELOW
R10.5-D_IMPLEMENTATION_STATE: NOT STARTED
R10.5-D_EXECUTION_STATE: BLOCKED UNTIL COMMITTED COMPATIBILITY GREEN, BASELINE/ANALYSIS DISPOSITION AND SEPARATE OWNER RELEASE
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
CUI2A1_IMPLEMENTATION_AUTHORIZED: NO
M4_STATE: NOT AUTHORIZED
M5_STATE: NOT AUTHORIZED
CUI1_STATE: CLOSED
CUI2A0_STATE: CLOSED
M3_STATE: CLOSED
R10.5-E/F_R10.6_R10.7: LOCKED
BACKEND_PUBLICATION_ENTITLEMENT_PAYMENT_AUTHORITY_DELTA: ZERO
COMMIT_PUSH_AUTHORIZED_TO_AGENTS: NO

## Exact existing authority and documentary boundary

Entry baseline: main at 48004703c8afe633a487f7612f07aecb459c7e7e.
Frozen contract: docs/architecture/contracts/V1-R10_5D_PROFILE_USER_AREA_PRESENTATION_IMPLEMENTATION_CONTRACT.md, Git blob 0c8f38c87248d31a5aef23a4cfe9f20a546b1329.
Roadmap prefix: docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md, Git blob d8a6511e1237efeebe62f745923550ce94609abc.
Readiness document remains at blob ee696d6a4054fd5476f81f3d7c2c9b6e6e8cd7ab.

Preserve every preceding roadmap byte and every frozen contract requirement. This later record supersedes only R10.5-D's ordinary UI implementation-NO/audit-only execution control, and only subject to the gates below. Historical records remain intact. No commercial phase is activated and no CUI-2A1 gate is satisfied or waived.

## Exclusive future UI write boundary

M lib/features/profile/presentation/profile_screen.dart
M lib/features/profile/presentation/screens/profile_setup_screen.dart
M lib/features/profile/presentation/screens/profile_edit_screen.dart
M lib/features/profile/presentation/screens/authenticated_profile_edit_screen.dart
M lib/features/user_area/presentation/user_area_screen.dart
A test/v1_r10_5d_profile_user_area_visual_test.dart

Only the new visual test may be untracked/added; once present it may be modified within the same authorized implementation. No deletion, rename, type change, seventh path, shared-component/provider/data/route/dependency/localization/native/SQL/Supabase change is permitted. Existing 17 regression files in frozen contract §F remain read-only. Preserve all eight literal raw Git identities in §O, including the existing three dirty tests and three untracked artifacts.

## Frozen behavior and presentation requirements

Implement §§A–E of the frozen R10.5-D contract without changing AuthProvider/Supabase authority, cloud-profile SSOT, local/guest fields and payloads, two-step setup/back/persistence, cloud save/single-flight/uncertain-save/manual retry, dirty/pending back protection, routes/destinations, whole-body Profile conflict versus header-only User Area conflict, five ordinary User Area entries and staff capability gates. No recovery parity redesign, new field, automatic retry, additional destination, backup-operation change or Google Play destination change.

Reuse CivilAppBar, CivilSurfaceCard and existing theme/tokens, true-black dark hierarchy, Arabic RTL and representative dormant English LTR compatibility. Apply 16/24/32 gutters at 600/840 breakpoints, centered 760 logical-pixel content cap, readable 320×568/2.0 text-scale layouts, effective 48×48 hit targets and exactly one shell-safe bottom clearance. Replace only raw backup failure interpolation with the established localized failure text.

## One coordinated compatibility pass, separately instructed

The Owner/Architect must separately approve and instruct the exact coordinated activation pass before any edits. Its exclusive write boundary is this single roadmap append plus:
test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
test/commercial_harden1_public_plans_exposure_migration_test.dart
test/commercial_m1b_catalog_reference_data_migration_test.dart
test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart

That pass performs zero UI implementation. It must implement one separately named shared R10.5-D recognition design for (a) the exact pending review pair, with live production execution disabled; (b) the committed authorization with zero UI changes; and (c) permitted partial and committed UI changes limited to the six paths above. A pending pair is review evidence only and cannot enable production execution. Preserve old exact historical/freeze-only fixtures, every security/hash predicate and independent committed/staged/unstaged/untracked inventories. Keep the three consumers and M1B's independently authored, unique-anchor HARDEN1 source oracle exact. Never derive expected source from the live file or accept arbitrary document suffixes, caller/environment bypass flags, directory exceptions or HEAD as expected authority.

Observe actual authorization/guard commit and document/source blob identities only after the accepted coordinated commit exists. Do not invent future hashes or require a guard's own future hash inside its source. During UI work, the approved committed guards, all documents and unrelated sources are immutable; only the six UI paths and exact protected entry dirt may differ. Final UI identities are recorded after accepted Owner Git closure. Closure-document recognition remains a separate later decision.

## Mandatory execution and acceptance gates

1. Owner/Architect accepts this exact record and finite-stage compatibility design. Any genuine frozen-contract/gate change requires its own formal accepted amendment; this record silently amends none.
2. Independently validate/review the exact coordinated roadmap/four-guard candidate, including meaningful positive/adversarial recognition. Owner separately authorizes and commits only its five paths, with entry baseline as parent. No UI edits occur in this pass.
3. Verify the actual committed identities and run the four guards plus unchanged commercial_m1a_private_catalog_migration_test.dart and v1_r09q_security_matrix_test.dart sequentially with flutter test --no-pub. Require zero failures/skips and live committed preimplementation GREEN with zero UI changes. Pending-candidate GREEN cannot substitute for this committed gate.
4. Satisfy frozen §G's 17-file baseline and targeted five-file analysis requirement. Reuse earlier test evidence only when exact source/test/toolchain inputs and composition traceability are verified and explicitly accepted; otherwise rerun the required baseline. The recorded internal Enum analyzer crash is not PASS; an explicit Architect tooling disposition or separately authorized successful analysis resolution is required. No SDK/dependency/global-cache patch is authorized.
5. Owner issues a separate UI release instruction naming the actual committed execution/guard baseline and accepted prerequisite evidence. Only then may the designated UI implementer edit the six UI paths.
6. After UI work, run the mandatory new visual suite, all 17 unchanged regressions and the same six security suites sequentially; require zero failures/skips, preserved raw identities and no new analyzer diagnostics under the accepted tooling disposition. Complete independent ordinary UI review and Owner Android visual acceptance with actual revision/device/settings evidence.
7. Keep R10.5-D-IOS-01 mandatory before iOS launch and UNVERIFIED until native iPhone evidence exists. Android/widget results certify no native iOS readiness.
8. Final Architect acceptance and separate Owner Git authorization are required. Stage only the accepted six-path UI scope, preserve unrelated dirt, inspect complete staged diff, run git diff --cached --check, verify actual parent and resulting source/test blobs, and use only normal expressly authorized Git publication. No automatic next-slice advancement.

Guard compatibility requires independent Big Pickle review. The prior fresh-Codex substitution applied to the closed freeze-only acceptance gate and does not silently extend here; any new substitution must be explicitly named and scoped by the Owner. Routine UI implementation/review follows the Operating Model with independent implementer and reviewer.

STOP for a missing/altered/uncommitted authority, failed required gate, protected-byte or source drift, unexpected path/status, weakened historical predicate, source-oracle mismatch, unresolved blocking review finding, missing analysis disposition, premature implementation or scope expansion. Report the exact required Owner/Architect decision; do not bypass, retry mutations blindly or edit protected tests.
''';

// Explicit fixed freeze-only fixture, never a live activation fallback.
bool hasR10FreezeFixtureBoundary({
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
}) => hasR10FreezeBoundary(
  sources: sources ?? _r10Sources,
  libDocsChanges: libDocsChanges ?? [cui2a0RoadmapPath, cui2a0ClosureReportPath,
    cui2a1ContractPath, ownerPlanningReadinessPath, r10ContractPath],
  migrationNames: migrationNames, predecessorChanges: predecessorChanges,
  backendChanges: backendChanges, untrackedAuthorityPaths: untrackedAuthorityPaths ?? const [],
  repositoryChanges: repositoryChanges ?? _cui2a1DirtyPaths,
  committedChanges: committedChanges ?? cui2a1CompatibilityPaths,
  stagedChanges: stagedChanges ?? const [],
  unstagedChanges: unstagedChanges ?? _cui2a1DirtyPaths,
  untrackedPaths: untrackedPaths ?? _cui2a1UntrackedPaths,
  preservedBlobs: preservedBlobs, pins: pins,
  executionCommit: executionCommit ?? r10PresentationEntry,
  committedStatus: committedStatus ?? cui2a1CompatibilityPaths.map((p) => 'M\t$p').join('\n'),
  stagedStatus: stagedStatus ?? '',
  unstagedStatus: unstagedStatus ?? _cui2a1DirtyPaths.map((p) => 'M\t$p').join('\n'),
  implementationCommit: implementationCommit, closureCommit: closureCommit,
  freezeCommit: freezeCommit, compatibilityCommit: compatibilityCommit,
);

// Separate ordinary R10.5-D compatibility classification. This is never an
// Owner release authority: release/baseline/analysis/review evidence is procedural.
const r10PresentationEntry = '48004703c8afe633a487f7612f07aecb459c7e7e';
const _r10EntryGuardBlobs = <String, String>{
  'test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart': 'f667537445effe110f2ee583d7831aec6ad36088',
  'test/commercial_harden1_public_plans_exposure_migration_test.dart': '3174905cbecec1bff8dc8d2fcad5d1eb5ea37be8',
  'test/commercial_m1b_catalog_reference_data_migration_test.dart': 'b4074a57cd6f59fbedf1ed5795f81542169ec975',
  'test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart': '4ce5e11dcd11b160db7bc819fe01da9192289dea',
};
const _r10VisualPath = 'test/v1_r10_5d_profile_user_area_visual_test.dart';
final _r10PresentationSources = <String, String>{
  ..._r10Sources, cui2a0RoadmapPath: r10AuthorizedRoadmap + r10PresentationAppend,
};
final _r10PresentationDocuments = <String, String>{
  for (final e in _r10PresentationSources.entries)
    if (e.key.startsWith('docs/')) e.key: e.value,
};
final _r10EntryDocuments = <String, String>{
  for (final e in _r10Sources.entries)
    if (e.key.startsWith('docs/')) e.key: e.value,
};

enum R10PresentationStage { rejected, pendingReview, committedZeroUi, boundedUi }
class R10PresentationRecognition {
  final R10PresentationStage stage;
  final String? observedAuthorizationCommit;
  final Map<String, String> observedGuardBlobs;
  final String maintenanceState;
  final String? observedMaintenanceCommit;
  final String decisionState;
  final String? observedDecisionCommit;
  const R10PresentationRecognition(this.stage, [this.observedAuthorizationCommit,
    this.observedGuardBlobs = const {}, this.maintenanceState = 'none',
    this.observedMaintenanceCommit, this.decisionState = 'none', this.observedDecisionCommit]);
  bool get compatible => stage != R10PresentationStage.rejected;
  bool get committedAuthorityObserved => observedAuthorizationCommit != null;
  // Git proves composition, never the separate human UI-release instruction.
  bool get separateOwnerUiReleaseRequired => true;
  bool get productionExecutionAuthorized => false;
}
class _R10Revision {
  final String id, parents, raw;
  final Map<String, String> documents, guards;
  const _R10Revision(this.id, this.parents, this.raw, this.documents, this.guards);
}
class _R10PresentationEvidence {
  final String branch, head, indexRaw, workRaw;
  final _R10Revision entry;
  final List<_R10Revision> revisions;
  final Map<String, String> sources, protected;
  final List<String> untracked;
  final Set<String> nonRegularPaths;
  final String roadmapRawBlob;
  const _R10PresentationEvidence({required this.branch, required this.head,
    required this.entry, required this.revisions, required this.sources,
    required this.protected, required this.indexRaw, required this.workRaw,
    required this.untracked, this.nonRegularPaths = const {}, this.roadmapRawBlob = ''});
}
bool _r10SameMap(Map<String, String> actual, Map<String, String> expected) =>
    actual.length == expected.length &&
    expected.entries.every((e) => actual[e.key] == e.value);

// Git --raw supplies modes independently of name-status. No symlink, executable,
// rename/copy, deletion, duplicate path, or malformed status can become an M.
List<({String path, String status})>? _r10RawChanges(String raw) {
  final result = <({String path, String status})>[];
  for (final line in _paths(raw)) {
    final m = RegExp(r'^:(000000|100644) (000000|100644) [a-f0-9]{40} [a-f0-9]{40} ([AM])\t([^\t]+)$').firstMatch(line);
    if (m == null || m[2] != '100644' ||
        (m[3] == 'A' ? m[1] != '000000' : m[1] != '100644')) return null;
    result.add((path: m[4]!, status: m[3]!));
  }
  if (result.map((e) => e.path).toSet().length != result.length) return null;
  return result;
}
bool _r10UiLayer(List<({String path, String status})> changes,
    {required bool visualPresent, Set<String> extraModified = const {}}) =>
    changes.every((e) {
      if (extraModified.contains(e.path)) return e.status == 'M';
      if (!r10PresentationPaths.contains(e.path)) return false;
      if (e.path != _r10VisualPath) return e.status == 'M';
      return e.status == (visualPresent ? 'M' : 'A');
    });

R10PresentationRecognition _classifyR10Presentation(_R10PresentationEvidence e) {
  const reject = R10PresentationRecognition(R10PresentationStage.rejected);
  final five = {...cui2a1CompatibilityPaths, cui2a0RoadmapPath};
  if (e.branch != 'main' || e.nonRegularPaths.isNotEmpty || e.entry.id != r10PresentationEntry ||
      e.entry.parents != r10AuthorizationCommit ||
      !_r10SameMap(e.entry.guards, _r10EntryGuardBlobs) ||
      !_r10SameMap(e.entry.documents, _r10EntryDocuments) ||
      !_r10SameMap(e.sources, _r10PresentationSources) ||
      !_r10SameMap(e.protected, _cui2a1ProtectedBlobs)) return reject;
  final index = _r10RawChanges(e.indexRaw), work = _r10RawChanges(e.workRaw);
  if (index == null || work == null ||
      !_samePaths(work.where((c) => _cui2a1DirtyPaths.contains(c.path)).map((c) => c.path), _cui2a1DirtyPaths)) return reject;
  if (e.head == r10PresentationEntry) {
    if (e.revisions.isNotEmpty || index.isNotEmpty ||
        !_samePaths(work.map((c) => c.path), {...five, ..._cui2a1DirtyPaths}) ||
        work.any((c) => c.status != 'M') ||
        !_samePaths(e.untracked, _cui2a1UntrackedPaths)) return reject;
    return const R10PresentationRecognition(R10PresentationStage.pendingReview);
  }
  if (e.revisions.isEmpty) return reject;
  final authorization = e.revisions.first;
  final first = _r10RawChanges(authorization.raw);
  if (authorization.parents != r10PresentationEntry ||
      !_r10SameMap(authorization.documents, _r10PresentationDocuments) ||
      !_samePaths(authorization.guards.keys, cui2a1CompatibilityPaths) ||
      authorization.guards.entries.any((g) =>
        !RegExp(r'^[a-f0-9]{40}$').hasMatch(g.value) ||
        g.value == _r10EntryGuardBlobs[g.key]) ||
      first == null || !_samePaths(first.map((c) => c.path), five) ||
      first.any((c) => c.status != 'M')) return reject;
  // Walk every commit, not just the net tree diff: a later restoration cannot
  // conceal an intervening unauthorized source/document/guard change or merge.
  var previous = r10PresentationEntry;
  var visualPresent = false;
  var hasUi = false;
  final seen = <String>{r10PresentationEntry};
  for (var i = 0; i < e.revisions.length; i++) {
    final revision = e.revisions[i];
    if (!RegExp(r'^[a-f0-9]{40}$').hasMatch(revision.id) ||
        !seen.add(revision.id) || revision.parents != previous ||
        !_r10SameMap(revision.documents, _r10PresentationDocuments) ||
        !_r10SameMap(revision.guards, authorization.guards)) return reject;
    if (i > 0) {
      final changes = _r10RawChanges(revision.raw);
      if (changes == null || !_r10UiLayer(changes, visualPresent: visualPresent)) return reject;
      hasUi |= changes.isNotEmpty;
      visualPresent |= changes.any((c) => c.path == _r10VisualPath);
    }
    previous = revision.id;
  }
  if (previous != e.head || !_r10UiLayer(index, visualPresent: visualPresent)) return reject;
  final visualInIndex = visualPresent || index.any((c) => c.path == _r10VisualPath);
  // Unstaged tracked changes cannot be A; only the exact new untracked test can
  // represent a file not yet in HEAD/index.
  if (work.any((c) => c.status != 'M') ||
      !_r10UiLayer(work, visualPresent: visualInIndex, extraModified: _cui2a1DirtyPaths)) return reject;
  final expectedUntracked = {..._cui2a1UntrackedPaths};
  if (!visualInIndex && e.untracked.contains(_r10VisualPath)) expectedUntracked.add(_r10VisualPath);
  if (!_samePaths(e.untracked, expectedUntracked)) return reject;
  hasUi |= index.isNotEmpty || work.any((c) => !_cui2a1DirtyPaths.contains(c.path)) ||
      expectedUntracked.contains(_r10VisualPath);
  return R10PresentationRecognition(hasUi ? R10PresentationStage.boundedUi :
    R10PresentationStage.committedZeroUi, authorization.id, Map.unmodifiable(authorization.guards));
}

String _r10Read(String path) => File(path).readAsStringSync().replaceAll('\r\n', '\n');
_R10Revision _r10Revision(String commit, String parent) => _R10Revision(
  commit, _git(['show', '-s', '--format=%P', commit]).trim(),
  _git(['diff', '--raw', '--no-abbrev', '--no-renames', parent, commit]),
  {for (final path in _r10EntryDocuments.keys) path: _git(['show', '$commit:$path'])},
  {for (final path in cui2a1CompatibilityPaths) path: _git(['rev-parse', '$commit:$path']).trim()},
);
final _r10PresentationEntryRevision = _r10Revision(r10PresentationEntry, r10AuthorizationCommit);
_R10PresentationEvidence _collectR10PresentationEvidence() {
  final head = _git(['rev-parse', 'HEAD']).trim();
  final descendants = _paths(_git(['rev-list', '--reverse', '--ancestry-path', '$r10PresentationEntry..$head']));
  final revisions = <_R10Revision>[];
  var parent = r10PresentationEntry;
  for (final commit in descendants) {
    revisions.add(_r10Revision(commit, parent));
    parent = commit;
  }
  return _R10PresentationEvidence(
    branch: _git(['branch', '--show-current']).trim(), head: head,
    entry: _r10PresentationEntryRevision, revisions: revisions,
    sources: {for (final path in _r10Sources.keys) path: _r10Read(path)},
    protected: {for (final path in _cui2a1ProtectedBlobs.keys)
      path: _git(['hash-object', '--no-filters', '--', path]).trim()},
    indexRaw: _git(['diff', '--cached', '--raw', '--no-abbrev', '--no-renames']),
    workRaw: _git(['diff', '--raw', '--no-abbrev', '--no-renames']),
    untracked: _paths(_git(['ls-files', '--others', '--exclude-standard'])),
    roadmapRawBlob: _git(['hash-object', '--no-filters', '--', cui2a0RoadmapPath]).trim(),
    nonRegularPaths: {
      for (final path in {..._r10Sources.keys, ...cui2a1CompatibilityPaths,
        ..._cui2a1ProtectedBlobs.keys, ...r10PresentationPaths})
        if (FileSystemEntity.typeSync(path, followLinks: false) != FileSystemEntityType.file &&
            (path != _r10VisualPath || FileSystemEntity.typeSync(path, followLinks: false) != FileSystemEntityType.notFound)) path,
    },
  );
}
R10PresentationRecognition recognizeR10PresentationStage() {
  const reject = R10PresentationRecognition(R10PresentationStage.rejected);
  try {
    if (!_r10PinsMatch ||
        _git(['merge-base', r10PresentationEntry, 'HEAD']).trim() != r10PresentationEntry ||
        !hasR10FreezeFixtureBoundary()) return reject;
    // The pending pair must preserve the exact entry raw prefix and verbatim append.
    if (_git(['rev-parse', 'HEAD']).trim() == r10PresentationEntry &&
        _git(['hash-object', '--no-filters', '--', cui2a0RoadmapPath]).trim() != 'b074b047ddff7b7c821933aa1b88d8e3b6666792') return reject;
    final evidence = _collectR10PresentationEvidence();
    final original = _classifyR10Presentation(evidence);
    if (original.compatible) return original;
    final maintenance = _recognizeR10FixtureMaintenance(evidence);
    return maintenance.compatible ? maintenance : _recognizeR10DecisionRecord(evidence);
  } on Object {
    return reject; // Missing objects, paths, malformed UTF-8 and Git failures fail closed.
  }
}
bool hasR10PresentationCompatibility() => recognizeR10PresentationStage().compatible;
bool matchesR10PresentationDocuments(String roadmap, String contract,
    String readiness, String r10Contract) =>
    _r10PinsMatch && roadmap == r10AuthorizedRoadmap + r10PresentationCurrentAppend &&
    contract == cui2a1FrozenContract && readiness == ownerPlanningReadiness &&
    r10Contract == r10FrozenContract;


// One exact fixture-maintenance transition; historical classifiers stay intact.
const r10FixtureMaintenanceEntry = '20fff015921ec6c55cf09258298c2a06c05f9d43';
const _r10MaintenanceCuiFingerprint = 'c3b282d86daa375e93801b88c3033a573602b6ba';
const _r10MaintenanceOtherGuardBlobs = <String, String>{
  'test/commercial_harden1_public_plans_exposure_migration_test.dart': '09215627742a979310d5a42d3330e37ff0153535',
  'test/commercial_m1b_catalog_reference_data_migration_test.dart': '9f92a04ba56d5ec0d482a34813bb17d348392701',
  'test/commercial_m3_entitlement_evaluator_shadow_migration_test.dart': '78bdb558bc46332a0c4dcac3103f9b1500c21c44',
};
// The completed maintenance is immutable. This correction is a separate step.
const _r10FixtureMaintenanceCommit = '47621d5b8a19ce88902bba4fa0d00e7393ac402d';
const _r10CuiPath = 'test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart';
const _r10HistoricalMaintenanceGuardBlobs = <String, String>{
  _r10CuiPath: 'aea8f8d53e2c75475e6f9836f98f593668dd5110',
  ..._r10MaintenanceOtherGuardBlobs,
};
const _r10MaintenancePaths = <String>{
  cui2a0RoadmapPath,
  'test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart',
  'test/commercial_harden1_public_plans_exposure_migration_test.dart',
  'test/commercial_m1b_catalog_reference_data_migration_test.dart',
};
const _r10MaintenanceUiBlobs = <String, String>{
  'lib/features/profile/presentation/profile_screen.dart': '48153fe3d36b59c122371f85215551e687a95cd7',
  'lib/features/profile/presentation/screens/profile_setup_screen.dart': '64da1f57fa4e6364c59b29c28c24256953460e7e',
  'lib/features/profile/presentation/screens/profile_edit_screen.dart': '9c2b3fea3e0f8c16f9eb79b7e02597a4ede9e043',
  'lib/features/profile/presentation/screens/authenticated_profile_edit_screen.dart': '8fa92706081297bd17cbeb95ff42d8448581470c',
  'lib/features/user_area/presentation/user_area_screen.dart': '8db72d58ae85d61c3c46ec099a686fb5db2f3c8b',
  'test/v1_r10_5d_profile_user_area_visual_test.dart': 'cfc81ef7be8d020771ccbebad07d31fffa01c782',
};
const r10FixtureMaintenanceAppend = '\n' r'''
# R10.5-D HISTORICAL FIXTURE REPAIR — BOUNDED SECURITY MAINTENANCE — 2026-10-18

This prospective record adopts the Owner/Architect's narrowly bounded maintenance instruction. It claims no earlier authority and grants no general guard-maintenance exception. UI implementation is PAUSED during this maintenance pass.

MAINTENANCE_BASELINE: main / 20fff015921ec6c55cf09258298c2a06c05f9d43
BASELINE_PARENT: 48004703c8afe633a487f7612f07aecb459c7e7e
BASELINE_ROADMAP_BLOB: e66690adbd7615f2a8300ad1b13560f3c82efda2
FROZEN_R10_5D_CONTRACT_BLOB: 0c8f38c87248d31a5aef23a4cfe9f20a546b1329
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
CUI2A1_M4_M5_IMPLEMENTATION_AUTHORIZED: NO
NEW_UI_IMPLEMENTATION_AUTHORIZED: NO
COMMIT_PUSH_AUTHORIZED: NO

The historical positive hasAuthorizedCui2a0Boundary assertion in _registerOwnerPlanningBoundaryTests omitted untrackedPaths and therefore combined historical inputs with today's untracked inventory. Its sole fixture correction is the explicit argument untrackedPaths: _cui2a1UntrackedPaths. The historical predicate, its literal three-path inventory and every negative outcome remain unchanged. Never filter the actual untracked inventory.

This one maintenance candidate may append only this literal record and change only technically necessary recognition/source-oracle coordination in the existing guards. The actual maintenance delta is exactly:
M docs/architecture/CIVILPEDIA_V1_MASTER_ROADMAP.md
M test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart
M test/commercial_harden1_public_plans_exposure_migration_test.dart
M test/commercial_m1b_catalog_reference_data_migration_test.dart
The M3 guard remains unchanged. No other repository path may change in this pass.

Preserve the current UI candidate's six raw Git identities:
lib/features/profile/presentation/profile_screen.dart: 48153fe3d36b59c122371f85215551e687a95cd7
lib/features/profile/presentation/screens/profile_setup_screen.dart: 64da1f57fa4e6364c59b29c28c24256953460e7e
lib/features/profile/presentation/screens/profile_edit_screen.dart: 9c2b3fea3e0f8c16f9eb79b7e02597a4ede9e043
lib/features/profile/presentation/screens/authenticated_profile_edit_screen.dart: 8fa92706081297bd17cbeb95ff42d8448581470c
lib/features/user_area/presentation/user_area_screen.dart: 8db72d58ae85d61c3c46ec099a686fb5db2f3c8b
test/v1_r10_5d_profile_user_area_visual_test.dart: cfc81ef7be8d020771ccbebad07d31fffa01c782

Recognition retains the original approved UI state and adds only this maintenance transition:
1. Pending review: HEAD is the exact baseline above; index is empty; the four maintenance paths are modified, with their exact approved contents; all six UI identities remain exact. This is review evidence only. No new functionality, UI work or Git publication is authorized.
2. Committed maintenance: observe the actual direct-child commit of that baseline, containing exactly the four maintenance modifications above, the exact literal append and approved guard sources. No future commit hash is invented.
3. Subsequent UI closure: require unchanged maintenance documents/guards in every descendant, single-parent ancestry and only the original six UI paths with their original permitted statuses/modes. This supplies no additional UI execution permission; any further work requires its existing procedural Owner release. Closure-document recognition remains a separate decision.

Verify every committed, indexed, unstaged and untracked layer independently. Only after the exact maintenance inputs are validated may this one transition be projected onto the unchanged original R10.5-D classifier. Do not remove or filter any untracked entry. Reject missing/altered authority, unexpected paths/modes/statuses, changed protected bytes, hidden/restored history drift and unrelated future maintenance.

Source identity is exact after CRLF-to-LF normalization, as in existing source oracles. HARDEN1/M1B/M3 are checked against fixed complete Git blob identities. To avoid a circular future hash, the CUI-2A0 source fingerprint is the Git blob hash of its complete UTF-8 LF source with exactly one declaration, const _r10MaintenanceCuiFingerprint = '<40 lowercase hex>'; replaced by the identical declaration with forty zeroes. Require one unique declaration and its literal value to equal the compiled fixed fingerprint. No other source region is excluded. Compute with git hash-object --no-filters, without -w; independently reproduce before review. This fingerprint is not a raw protected-file identity. Actual complete committed guard blobs are observed and checked at closure; subsequent guard edits fail closed.

Preserve all historical pins, fixtures and security predicates; CUI-1/CUI-2A0 closures; HARDEN1 public-plan restrictions; M1B catalog and independently authored unique-anchor HARDEN1 source oracle; M3 shadow entitlement isolation; unchanged M1a/R09q; RLS, actor/capability, ownership/publication, audit/receipt/SQL protections; every frozen policy and all eight literal contract §O raw identities. No contract, SQL/Supabase, Auth/provider, route, dependency or SDK change. No commercial capability expands.

First validate the repaired historical assertion. Then run CUI-2A0, HARDEN1, M1B, M3, unchanged M1a and unchanged R09q sequentially with flutter test --no-pub; require zero failures/skips and live positive/adversarial evidence for all maintenance states. Previous 43/43 visual and 401/401 regression results remain previous evidence only while their exact inputs are preserved.

Independent Big Pickle High acceptance is required. Any substitute requires a newly explicit Owner decision naming and scoping it. Final Owner acceptance and separate Git authorization are required; no staging/commit/push is granted here. After accepted maintenance closure, guards and documents are again immutable during ordinary UI work. The analyzer Enum failure remains NOT PASS; Android Owner visual acceptance and native iPhone QA remain separate gates.

STOP for a genuinely required frozen-contract amendment, insecure transition, weakened historical protection, unexpected drift, failed mandatory validation/review or another native compiler/runtime crash. Preserve existing crash evidence. No automatic next-slice advancement.
''';
final _r10MaintenanceDocuments = <String, String>{
  ..._r10PresentationDocuments,
  cui2a0RoadmapPath: _r10PresentationDocuments[cui2a0RoadmapPath]! + r10FixtureMaintenanceAppend,
};
final _r10MaintenanceSources = <String, String>{
  ..._r10PresentationSources, cui2a0RoadmapPath: _r10MaintenanceDocuments[cui2a0RoadmapPath]!,
};

// Temporary source bytes are outside the repository; hash-object never uses -w.
String _r10SourceBlob(String source) {
  final scratch = Directory.systemTemp.createTempSync('civilpedia-r10-fixture-');
  try {
    final file = File(scratch.path + Platform.pathSeparator + 'source');
    file.writeAsBytesSync(utf8.encode(source));
    return _git(['hash-object', '--no-filters', '--', file.path]).trim();
  } finally {
    scratch.deleteSync(recursive: true);
  }
}
Map<String, String>? _r10ApprovedMaintenanceGuardBlobs(Map<String, String> sources) {
  if (!_samePaths(sources.keys, cui2a1CompatibilityPaths)) return null;
  final blobs = {for (final entry in sources.entries) entry.key: _r10SourceBlob(entry.value)};
  if (_r10SameMap(blobs, _r10HistoricalMaintenanceGuardBlobs)) return blobs;
  const path = 'test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart';
  final source = sources[path]!;
  final marker = RegExp(r"^const _r10MaintenanceCuiFingerprint = '[a-f0-9]{40}';$", multiLine: true);
  final anchors = marker.allMatches(source).toList();
  final declaration = "const _r10MaintenanceCuiFingerprint = '$_r10MaintenanceCuiFingerprint';";
  if (anchors.length != 1 || anchors.single.group(0) != declaration) return null;
  final canonical = source.replaceRange(anchors.single.start, anchors.single.end,
    "const _r10MaintenanceCuiFingerprint = '0000000000000000000000000000000000000000';");
  if (_r10SourceBlob(canonical) != _r10MaintenanceCuiFingerprint) return null;
  if (!_r10MaintenanceOtherGuardBlobs.entries.every((e) => blobs[e.key] == e.value)) return null;
  return blobs;
}

R10PresentationRecognition _classifyR10FixtureMaintenance(_R10PresentationEvidence e,
    Map<String, String> approvedGuards, Map<String, String> uiBlobs) {
  const reject = R10PresentationRecognition(R10PresentationStage.rejected);
  if (e.branch != 'main' || e.nonRegularPaths.isNotEmpty ||
      !_r10SameMap(e.sources, _r10MaintenanceSources) ||
      !_r10SameMap(e.protected, _cui2a1ProtectedBlobs) ||
      !_samePaths(approvedGuards.keys, cui2a1CompatibilityPaths) ||
      e.revisions.isEmpty || e.revisions.first.id != r10FixtureMaintenanceEntry) return reject;
  final work = _r10RawChanges(e.workRaw), index = _r10RawChanges(e.indexRaw);
  if (work == null || index == null) return reject;
  if (e.head == r10FixtureMaintenanceEntry) {
    if (e.revisions.length != 1 || index.isNotEmpty ||
        !_r10SameMap(uiBlobs, _r10MaintenanceUiBlobs) ||
        !_maintenanceChangesExact(work.where((c) => _r10MaintenancePaths.contains(c.path)).toList())) return reject;
    // Exact source/document checks precede projection; untracked is untouched.
    final projected = _r10Probe(e, sources: _r10PresentationSources,
      workRaw: _paths(e.workRaw).where((line) =>
        !_r10MaintenancePaths.contains(line.split('\t').last)).join('\n'));
    final base = _classifyR10Presentation(projected);
    if (base.stage != R10PresentationStage.boundedUi) return reject;
    return R10PresentationRecognition(base.stage, base.observedAuthorizationCommit,
      base.observedGuardBlobs, 'pendingReview');
  }
  if (e.revisions.length < 2) return reject;
  final maintenance = e.revisions[1];
  final changes = _r10RawChanges(maintenance.raw);
  if (maintenance.parents != r10FixtureMaintenanceEntry || changes == null ||
      !_maintenanceChangesExact(changes)) return reject;
  final revisions = <_R10Revision>[e.revisions.first];
  var previous = r10FixtureMaintenanceEntry;
  final seen = <String>{r10PresentationEntry, r10FixtureMaintenanceEntry};
  for (var i = 1; i < e.revisions.length; i++) {
    final revision = e.revisions[i];
    if (!RegExp(r'^[a-f0-9]{40}$').hasMatch(revision.id) || !seen.add(revision.id) ||
        revision.parents != previous ||
        !_r10SameMap(revision.documents, _r10MaintenanceDocuments) ||
        !_r10SameMap(revision.guards, approvedGuards)) return reject;
    if (i > 1) revisions.add(_R10Revision(revision.id,
      i == 2 ? r10FixtureMaintenanceEntry : revision.parents,
      revision.raw, _r10PresentationDocuments, e.revisions.first.guards));
    previous = revision.id;
  }
  if (previous != e.head) return reject;
  final projected = _r10Probe(e,
    head: revisions.length == 1 ? r10FixtureMaintenanceEntry : e.head,
    revisions: revisions, sources: _r10PresentationSources);
  final base = _classifyR10Presentation(projected);
  if (!base.compatible) return reject;
  return R10PresentationRecognition(base.stage, base.observedAuthorizationCommit,
    Map.unmodifiable(approvedGuards), 'committed', maintenance.id);
}
bool _maintenanceChangesExact(List<({String path, String status})> changes) =>
  _samePaths(changes.map((c) => c.path), _r10MaintenancePaths) &&
  changes.every((c) => c.status == 'M');

// Owner-authorized CUI-only repair at the fixed completed-maintenance anchor.
// Source approval still requires the complete canonical fingerprint above.
// Pending review and its one direct-child commit grant no production release.
R10PresentationRecognition _classifyR10CuiFixtureCorrection(
    _R10PresentationEvidence e, Map<String, String> approvedGuards,
    Map<String, String> uiBlobs) {
  const reject = R10PresentationRecognition(R10PresentationStage.rejected);
  if (!_samePaths(approvedGuards.keys, cui2a1CompatibilityPaths) ||
      !RegExp(r'^[a-f0-9]{40}$').hasMatch(approvedGuards[_r10CuiPath] ?? '') ||
      approvedGuards[_r10CuiPath] == _r10HistoricalMaintenanceGuardBlobs[_r10CuiPath] ||
      !_r10MaintenanceOtherGuardBlobs.entries.every((g) => approvedGuards[g.key] == g.value) ||
      e.revisions.length < 2 || e.revisions[1].id != _r10FixtureMaintenanceCommit ||
      !_r10SameMap(e.revisions[1].guards, _r10HistoricalMaintenanceGuardBlobs) ||
      !_r10SameMap(uiBlobs, _r10MaintenanceUiBlobs) ||
      !_samePaths(e.untracked, {..._cui2a1UntrackedPaths, _r10VisualPath})) return reject;
  final index = _r10RawChanges(e.indexRaw), work = _r10RawChanges(e.workRaw);
  if (index == null || index.isNotEmpty || work == null) return reject;
  final checkpointWork = {..._cui2a1DirtyPaths,
    ...r10PresentationPaths.where((p) => p != _r10VisualPath)};
  if (work.any((c) => c.status != 'M') ||
      !_samePaths(work.map((c) => c.path), {...checkpointWork,
        if (e.head == _r10FixtureMaintenanceCommit) _r10CuiPath})) return reject;
  bool onlyCui(List<({String path, String status})> changes) =>
    changes.length == 1 && changes.single.path == _r10CuiPath && changes.single.status == 'M';
  var projectedWork = e.workRaw;
  if (e.head == _r10FixtureMaintenanceCommit) {
    if (e.revisions.length != 2 || !onlyCui(work.where((c) => c.path == _r10CuiPath).toList())) return reject;
    // Remove only the independently approved CUI delta; preserve every inventory entry.
    projectedWork = _paths(e.workRaw).where((line) => line.split('\t').last != _r10CuiPath).join('\n');
  } else {
    if (e.revisions.length != 3 || work.any((c) => c.path == _r10CuiPath)) return reject;
    final correction = e.revisions.last;
    final changes = _r10RawChanges(correction.raw);
    if (!RegExp(r'^[a-f0-9]{40}$').hasMatch(correction.id) ||
        {r10PresentationEntry, r10FixtureMaintenanceEntry, _r10FixtureMaintenanceCommit}.contains(correction.id) ||
        correction.id != e.head || correction.parents != _r10FixtureMaintenanceCommit ||
        changes == null || !onlyCui(changes) ||
        !_r10SameMap(correction.documents, _r10MaintenanceDocuments) ||
        !_r10SameMap(correction.guards, approvedGuards)) return reject;
  }
  final base = _classifyR10FixtureMaintenance(_r10Probe(e,
    head: _r10FixtureMaintenanceCommit, revisions: e.revisions.take(2).toList(),
    workRaw: projectedWork), _r10HistoricalMaintenanceGuardBlobs, uiBlobs);
  if (!base.compatible) return reject;
  return R10PresentationRecognition(base.stage, base.observedAuthorizationCommit,
    Map.unmodifiable(approvedGuards), base.maintenanceState, base.observedMaintenanceCommit);
}

R10PresentationRecognition _recognizeR10FixtureMaintenance(_R10PresentationEvidence evidence) {
  const reject = R10PresentationRecognition(R10PresentationStage.rejected);
  final guards = _r10ApprovedMaintenanceGuardBlobs({
    for (final path in cui2a1CompatibilityPaths) path: _r10Read(path),
  });
  if (guards == null) return reject;
  final ui = {
    for (final path in r10PresentationPaths)
      path: _git(['hash-object', '--no-filters', '--', path]).trim(),
  };
  return _r10SameMap(guards, _r10HistoricalMaintenanceGuardBlobs)
    ? _classifyR10FixtureMaintenance(evidence, guards, ui)
    : _classifyR10CuiFixtureCorrection(evidence, guards, ui);
}
String get r10PresentationCurrentAppend {
  final recognition = recognizeR10PresentationStage();
  return r10PresentationAppend + (recognition.maintenanceState == 'none'
    ? '' : r10FixtureMaintenanceAppend) + (recognition.decisionState == 'none'
      ? '' : r10DecisionRecordAppend);
}

const r10FixtureMaintenanceHardenEdits = <(String, String)>[
  (r'''              ? _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend + cui2a0.ownerPlanningDocumentaryAppend + cui2a0.r10FreezeAppend + cui2a0.r10AuthorizationAppend + cui2a0.r10PresentationAppend''', r'''              ? _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend + cui2a0.ownerPlanningDocumentaryAppend + cui2a0.r10FreezeAppend + cui2a0.r10AuthorizationAppend + cui2a0.r10PresentationCurrentAppend'''),
  (r'''    expect(roadmap.substring(checkpoint.length), _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend + cui2a0.ownerPlanningDocumentaryAppend + cui2a0.r10FreezeAppend + cui2a0.r10AuthorizationAppend + cui2a0.r10PresentationAppend);''', r'''    expect(roadmap.substring(checkpoint.length), _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend + cui2a0.ownerPlanningDocumentaryAppend + cui2a0.r10FreezeAppend + cui2a0.r10AuthorizationAppend + cui2a0.r10PresentationCurrentAppend);'''),
];
String compatibleR10FixtureMaintenanceHardenSourceFromPresentation(String presentation) {
  var expected = presentation;
  for (final edit in r10FixtureMaintenanceHardenEdits) {
    expected = _replaceOwnerPlanningAnchor(expected, edit.$1, edit.$2);
  }
  return expected;
}
String compatibleR10FixtureMaintenanceHardenSource(String historical) =>
  compatibleR10FixtureMaintenanceHardenSourceFromPresentation(compatibleR10PresentationHardenSource(historical));


// This documentary transition has its own full-source fingerprint. The older
// maintenance/correction oracle remains unchanged and is checked on fixed blobs.
const _r10DecisionEntry = 'bd9ffd5363df2691580851a61956c7231120188f';
const _r10DecisionCuiFingerprint = 'c107f45d4cdc4fc3044af34c4e5806aa6bc8d7d4';
const _r10DecisionRoadmapRawBlob = 'be522c3b259577e65b57415c2cb7d09fc6f58848';
const _r10DecisionEntryGuardBlobs = <String, String>{
  _r10CuiPath: 'e74e8a7e6ad41925092e48059531f56ff47f1402',
  ..._r10MaintenanceOtherGuardBlobs,
};
const _r10DecisionPaths = <String>{cui2a0RoadmapPath, _r10CuiPath};
const r10DecisionRecordAppend = '\n' r'''
# V1-R10.5-D ACCEPTANCE EVIDENCE / TOOLING DISPOSITION STATUS — 2026-10-22

The original Master Roadmap remains the phase/status authority. This record preserves all preceding bytes and frozen requirements. It records supplied Owner/Architect facts and prior evidence; it grants no implementation, final acceptance, Git publication or next-slice authority.

R10.5-D_STATUS: CURRENT — EXISTING CANDIDATE UNDER ACCEPTANCE REVIEW / NOT CLOSED
UI_CANDIDATE: FIVE MODIFIED PRESENTATION SCREENS + ONE UNTRACKED VISUAL TEST
INDEPENDENT_UI_REVIEW: OWNER-REPORTED BIG PICKLE HIGH — PASS WITH NONBLOCKING FINDINGS / READY FOR OWNER ANDROID QA; NO HIGH OR MEDIUM IMPLEMENTATION DEFECTS REPORTED
PREVIOUS_EVIDENCE: VISUAL 43/43; FUNCTIONAL 401/401; POST-CUI SECURITY 220/220; SEPARATE 2026-10-21 EMULATOR OBSERVATIONS 16/16 — ALL PREVIOUS PASS RESULTS, NOT RERUN FOR THIS RECORD
OWNER_VISUAL_APPROVAL: PROVISIONAL ONLY — NOT FINAL OWNER ACCEPTANCE
ANALYZER_STATUS: NOT PASS — INTERNAL ANALYSIS TOOLING FAILURE
FINAL_ARCHITECT_TOOLING_DISPOSITION: PENDING EXPLICIT ACCEPTANCE
NATIVE_FLUTTER_DART_CRASH_ROOT_CAUSE: UNKNOWN
R10.5-D-IOS-01: UNVERIFIED / REQUIRED BEFORE IOS LAUNCH
ROADMAP_UI_CLOSURE: NOT COMPLETED
UI_GIT_CLOSURE: NOT COMPLETED
PRODUCTION_EXECUTION_AUTHORIZED: NO
COMMERCIAL_CURRENT_SLICE: NONE
COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO
R10.5-E: LOCKED / NOT AUTHORIZED
COMMIT_PUSH_AUTHORIZED: NO

Owner provisional visual approval covers Profile, User Area, Profile Setup and Local Profile Edit on Pixel_9_Pro, Android 17/API 37. Future observations remain open and are not presumed cosmetic. Authenticated Profile Edit has independent code-review and previous widget evidence, but authenticated/cloud emulator runtime inspection was unavailable because the QA launch lacked configured Supabase. This is an evidence limitation, not an established cloud-feature defect.

LOW findings: F1/F2 — Architect recommends deferring protected-test hygiene; Owner approval of that recommendation remains pending. F3 — existing roadmap UI pins establish checkpoint provenance, not final committed UI closure. F4 — representative responsive combinations are permitted by frozen contract §E; required assertions remain mandatory.

Frozen §§G/P and the conditional execution record permit an explicit Architect tooling disposition. Proposed alternative, not yet accepted: retain Analyzer NOT PASS; accept only a bounded alternative evidence package for the exact reviewed candidate and toolchain, comprising independent review, successful Android compilation, preserved visual/functional/security results and emulator observations. Accept explicitly the residual absence of complete analyzer diagnostics, lint coverage and a verified no-new-diagnostics comparison. Tests and compilation do not prove analyzer cleanliness or resolve native crashes.

Final acceptance still requires explicit tooling disposition or separately authorized successful analysis, LOW-finding dispositions, completion or formally authorized adjudication of outstanding §H Android evidence, final Owner visual acceptance and final Architect acceptance. UI Git closure requires separate Owner authority and actual resulting identities. No emulator evidence certifies physical Android or native iPhone readiness.

Separate observations: Home image HTTP 404 responses, debug-emulator startup skipped-frame warnings and Android OnBackInvokedCallback warnings. No R10.5-D blocking attribution or root cause is established for them.

Arabic-only RTL remains active. No frozen requirement, protected identity, Auth/Supabase authority, commercial restriction or later-slice lock is waived.
''';
final _r10DecisionSources = <String, String>{
  ..._r10MaintenanceSources,
  cui2a0RoadmapPath: _r10MaintenanceSources[cui2a0RoadmapPath]! + r10DecisionRecordAppend,
};
final _r10DecisionDocuments = <String, String>{
  for (final e in _r10DecisionSources.entries)
    if (e.key.startsWith('docs/')) e.key: e.value,
};
Map<String, String>? _r10ApprovedDecisionGuardBlobs(Map<String, String> sources) {
  if (!_samePaths(sources.keys, cui2a1CompatibilityPaths)) return null;
  final source = sources[_r10CuiPath]!;
  final marker = RegExp(r"^const _r10DecisionCuiFingerprint = '[a-f0-9]{40}';$", multiLine: true);
  final anchors = marker.allMatches(source).toList();
  final declaration = "const _r10DecisionCuiFingerprint = '$_r10DecisionCuiFingerprint';";
  if (anchors.length != 1 || anchors.single.group(0) != declaration) return null;
  final canonical = source.replaceRange(anchors.single.start, anchors.single.end,
    "const _r10DecisionCuiFingerprint = '0000000000000000000000000000000000000000';");
  if (_r10SourceBlob(canonical) != _r10DecisionCuiFingerprint) return null;
  final blobs = {for (final e in sources.entries) e.key: _r10SourceBlob(e.value)};
  if (!_r10MaintenanceOtherGuardBlobs.entries.every((e) => blobs[e.key] == e.value) ||
      blobs[_r10CuiPath] == _r10DecisionEntryGuardBlobs[_r10CuiPath]) return null;
  return blobs;
}
R10PresentationRecognition _classifyR10DecisionRecord(
    _R10PresentationEvidence e, Map<String, String> approvedGuards,
    Map<String, String> uiBlobs) {
  const reject = R10PresentationRecognition(R10PresentationStage.rejected);
  if (e.branch != 'main' || e.nonRegularPaths.isNotEmpty ||
      e.roadmapRawBlob != _r10DecisionRoadmapRawBlob ||
      !_r10SameMap(e.sources, _r10DecisionSources) ||
      !_r10SameMap(e.protected, _cui2a1ProtectedBlobs) ||
      !_r10SameMap(uiBlobs, _r10MaintenanceUiBlobs) ||
      !_samePaths(e.untracked, {..._cui2a1UntrackedPaths, _r10VisualPath}) ||
      !_samePaths(approvedGuards.keys, cui2a1CompatibilityPaths) ||
      !_r10MaintenanceOtherGuardBlobs.entries.every((g) => approvedGuards[g.key] == g.value) ||
      !RegExp(r'^[a-f0-9]{40}$').hasMatch(approvedGuards[_r10CuiPath] ?? '') ||
      {_r10HistoricalMaintenanceGuardBlobs[_r10CuiPath],
        _r10DecisionEntryGuardBlobs[_r10CuiPath]}.contains(approvedGuards[_r10CuiPath])) return reject;
  final pending = e.head == _r10DecisionEntry;
  if (e.revisions.length != (pending ? 3 : 4) ||
      e.revisions[2].id != _r10DecisionEntry) return reject;
  final work = _r10RawChanges(e.workRaw), index = _r10RawChanges(e.indexRaw);
  final checkpoint = {..._cui2a1DirtyPaths,
    ...r10PresentationPaths.where((p) => p != _r10VisualPath)};
  if (work == null || index == null || index.isNotEmpty ||
      work.any((c) => c.status != 'M') ||
      !_samePaths(work.map((c) => c.path),
        {...checkpoint, if (pending) ..._r10DecisionPaths})) return reject;
  if (!pending) {
    final decision = e.revisions.last;
    final changes = _r10RawChanges(decision.raw);
    if (!RegExp(r'^[a-f0-9]{40}$').hasMatch(decision.id) ||
        decision.id == '0' * 40 || decision.id != e.head ||
        {r10PresentationEntry, ...e.revisions.take(3).map((r) => r.id)}.contains(decision.id) ||
        decision.parents != _r10DecisionEntry || changes == null ||
        !_samePaths(changes.map((c) => c.path), _r10DecisionPaths) ||
        changes.any((c) => c.status != 'M') ||
        !_r10SameMap(decision.documents, _r10DecisionDocuments) ||
        !_r10SameMap(decision.guards, approvedGuards)) return reject;
  }
  // Validate the complete fixed predecessor using its original sources and
  // predicates. Projection removes only this independently checked two-path pair.
  final priorWork = _paths(e.workRaw).where((line) =>
    !_r10DecisionPaths.contains(line.split('\t').last)).join('\n');
  final predecessor = _r10Probe(e, head: _r10DecisionEntry,
    revisions: e.revisions.take(3).toList(), sources: _r10MaintenanceSources,
    workRaw: priorWork);
  final base = _classifyR10CuiFixtureCorrection(predecessor,
    _r10DecisionEntryGuardBlobs, uiBlobs);
  if (!base.compatible) return reject;
  return R10PresentationRecognition(base.stage, base.observedAuthorizationCommit,
    Map.unmodifiable(approvedGuards), base.maintenanceState,
    base.observedMaintenanceCommit, pending ? 'pendingReview' : 'committed',
    pending ? null : e.head);
}
R10PresentationRecognition _recognizeR10DecisionRecord(_R10PresentationEvidence evidence) {
  final guards = _r10ApprovedDecisionGuardBlobs({
    for (final path in cui2a1CompatibilityPaths) path: _r10Read(path),
  });
  if (guards == null) return const R10PresentationRecognition(R10PresentationStage.rejected);
  return _classifyR10DecisionRecord(evidence, guards, {
    for (final path in r10PresentationPaths)
      path: _git(['hash-object', '--no-filters', '--', path]).trim(),
  });
}
void _registerR10DecisionRecordTests() {
  final sources = {for (final path in cui2a1CompatibilityPaths) path: _r10Read(path)};
  final guards = _r10ApprovedDecisionGuardBlobs(sources)!;
  final uiWork = _cui2a1DirtyPaths.followedBy(r10PresentationPaths.where((p) => p != _r10VisualPath))
    .map((p) => _r10ProbeRaw(p)).join();
  final pair = _r10DecisionPaths.map((p) => _r10ProbeRaw(p)).join();
  final pending = _R10PresentationEvidence(
    branch: 'main', head: _r10DecisionEntry, entry: _r10PresentationEntryRevision,
    revisions: [
      _r10Revision(r10FixtureMaintenanceEntry, r10PresentationEntry),
      _r10Revision(_r10FixtureMaintenanceCommit, r10FixtureMaintenanceEntry),
      _r10Revision(_r10DecisionEntry, _r10FixtureMaintenanceCommit),
    ], sources: _r10DecisionSources, protected: _cui2a1ProtectedBlobs,
    indexRaw: '', workRaw: uiWork + pair,
    untracked: [..._cui2a1UntrackedPaths, _r10VisualPath],
    roadmapRawBlob: _r10DecisionRoadmapRawBlob);
  // This ID is a synthetic fixture, not an invented future commit authority.
  final decision = _R10Revision('e' * 40, _r10DecisionEntry, pair,
    _r10DecisionDocuments, guards);
  final committed = _r10Probe(pending, head: decision.id,
    revisions: [...pending.revisions, decision], workRaw: uiWork);
  R10PresentationRecognition recognize(_R10PresentationEvidence e,
      {Map<String, String>? candidateSources, Map<String, String>? ui}) {
    final approved = _r10ApprovedDecisionGuardBlobs(candidateSources ?? sources);
    return approved == null ? const R10PresentationRecognition(R10PresentationStage.rejected)
      : _classifyR10DecisionRecord(e, approved, ui ?? _r10MaintenanceUiBlobs);
  }
  const no = R10PresentationStage.rejected;
  test('R10 decision preserves the exact historical source oracles', () {
    final entrySources = {for (final e in _r10DecisionEntryGuardBlobs.entries)
      e.key: _git(['cat-file', 'blob', e.value])};
    expect(_r10ApprovedMaintenanceGuardBlobs(entrySources), _r10DecisionEntryGuardBlobs);
    expect(_r10ApprovedMaintenanceGuardBlobs(sources), isNull);
    expect(_r10ApprovedDecisionGuardBlobs(entrySources), isNull);
    expect(_git(['rev-parse', _r10DecisionEntry + ':' + cui2a0RoadmapPath]).trim(),
      'a6e60e72806694b812bdd5cec4866d7c31a50814');
    expect(_git(['rev-parse', _r10DecisionEntry + '^']).trim(), _r10FixtureMaintenanceCommit);
  });
  test('R10 decision exact pending pair is review only and never production release', () {
    final result = recognize(pending);
    expect(result.stage, R10PresentationStage.boundedUi);
    expect(result.decisionState, 'pendingReview');
    expect(result.observedDecisionCommit, isNull);
    expect(result.observedGuardBlobs, guards);
    expect(result.productionExecutionAuthorized, isFalse);
    expect(result.separateOwnerUiReleaseRequired, isTrue);
  });
  test('R10 decision exact committed direct child grants no execution or UI closure', () {
    final result = recognize(committed);
    expect(result.stage, R10PresentationStage.boundedUi);
    expect(result.decisionState, 'committed');
    expect(result.observedDecisionCommit, decision.id);
    expect(result.productionExecutionAuthorized, isFalse);
    expect(result.separateOwnerUiReleaseRequired, isTrue);
  });
  test('R10 decision live composition is independently recognized', () {
    final live = recognizeR10PresentationStage();
    expect(live.compatible, isTrue);
    expect(live.stage, R10PresentationStage.boundedUi);
    expect(live.maintenanceState, 'committed');
    expect(live.observedMaintenanceCommit, _r10FixtureMaintenanceCommit);
    expect(live.decisionState, isIn(['pendingReview', 'committed']));
    if (live.decisionState == 'pendingReview') {
      expect(_git(['rev-parse', 'HEAD']).trim(), _r10DecisionEntry);
      expect(live.observedDecisionCommit, isNull);
    } else {
      expect(_git(['rev-parse', 'HEAD^']).trim(), _r10DecisionEntry);
      expect(live.observedDecisionCommit, _git(['rev-parse', 'HEAD']).trim());
    }
    expect(live.productionExecutionAuthorized, isFalse);
    expect(live.separateOwnerUiReleaseRequired, isTrue);
    expect(matchesR10PresentationDocuments(_r10Read(cui2a0RoadmapPath),
      _r10Read(cui2a1ContractPath), _r10Read(ownerPlanningReadinessPath),
      _r10Read(r10ContractPath)), isTrue);
  });
  test('R10 decision rejects altered missing extra or commercially expanded documents', () {
    for (final base in [pending, committed]) {
      for (final e in _r10DecisionSources.entries) {
        expect(recognize(_r10Probe(base, sources: {...base.sources,
          e.key: e.value + '\nunauthorized'})).stage, no);
        expect(recognize(_r10Probe(base, sources: Map.from(base.sources)..remove(e.key))).stage, no);
      }
      for (final text in [
        _r10MaintenanceSources[cui2a0RoadmapPath]!,
        base.sources[cui2a0RoadmapPath]! + r10DecisionRecordAppend,
        base.sources[cui2a0RoadmapPath]!.replaceFirst(
          'PRODUCTION_EXECUTION_AUTHORIZED: NO', 'PRODUCTION_EXECUTION_AUTHORIZED: YES'),
        base.sources[cui2a0RoadmapPath]!.replaceFirst(
          'FINAL_ARCHITECT_TOOLING_DISPOSITION: PENDING EXPLICIT ACCEPTANCE',
          'FINAL_ARCHITECT_TOOLING_DISPOSITION: PASS'),
      ]) {
        expect(recognize(_r10Probe(base, sources: {...base.sources, cui2a0RoadmapPath: text})).stage, no);
      }
      expect(recognize(_r10Probe(base, sources: {...base.sources, 'docs/forged.md': 'authority'})).stage, no);
      expect(recognize(_r10Probe(base, roadmapRawBlob: '0' * 40)).stage, no);
    }
  });
  test('R10 decision rejects source drift wrong fingerprints and duplicate declarations', () {
    for (final e in sources.entries) {
      expect(_r10ApprovedDecisionGuardBlobs({...sources,
        e.key: e.value + '\n// unauthorized source\n'}), isNull);
    }
    final declaration = "const _r10DecisionCuiFingerprint = '$_r10DecisionCuiFingerprint';";
    for (final replacement in ['', declaration + '\n' + declaration,
      "const _r10DecisionCuiFingerprint = '0000000000000000000000000000000000000000';"]) {
      expect(_r10ApprovedDecisionGuardBlobs({...sources, _r10CuiPath:
        sources[_r10CuiPath]!.replaceFirst(declaration, replacement)}), isNull);
    }
    expect(_r10ApprovedDecisionGuardBlobs(Map.from(sources)..remove(_r10CuiPath)), isNull);
  });
  test('R10 decision rejects staged missing duplicate or unauthorized working paths', () {
    for (final base in [pending, committed]) {
      for (final path in {..._r10DecisionPaths, ...r10PresentationPaths,
        'docs/forged.md', 'test/unauthorized_test.dart', 'supabase/config.toml'}) {
        expect(recognize(_r10Probe(base, indexRaw: _r10ProbeRaw(path))).stage, no);
        expect(recognize(_r10Probe(base, workRaw: base.workRaw + _r10ProbeRaw(path))).stage, no);
      }
      for (final path in _cui2a1DirtyPaths) {
        expect(recognize(_r10Probe(base,
          workRaw: base.workRaw.replaceFirst(_r10ProbeRaw(path), ''))).stage, no);
      }
    }
    for (final path in _r10DecisionPaths) {
      expect(recognize(_r10Probe(pending,
        workRaw: pending.workRaw.replaceFirst(_r10ProbeRaw(path), ''))).stage, no);
    }
  });
  test('R10 decision rejects path status mode rename deletion and duplicate commit drift', () {
    final invalid = [
      '', pair + _r10ProbeRaw(cui2a0RoadmapPath),
      for (final path in _r10DecisionPaths)
        for (final status in ['A', 'D', 'T', 'R100'])
          pair.replaceFirst(_r10ProbeRaw(path), _r10ProbeRaw(path, status: status)),
      for (final path in _r10DecisionPaths)
        for (final mode in ['100755', '120000'])
          pair.replaceFirst(_r10ProbeRaw(path), _r10ProbeRaw(path, newMode: mode)),
      pair + _r10ProbeRaw('docs/forged.md'),
    ];
    for (final raw in invalid) {
      expect(recognize(_r10Probe(pending, workRaw: uiWork + raw)).stage, no);
      expect(recognize(_r10Probe(committed, revisions: [...pending.revisions,
        _r10RevisionProbe(decision, raw: raw)])).stage, no);
    }
  });
  test('R10 decision rejects wrong ancestry revision counts merges and restored history', () {
    for (final base in [pending, committed]) {
      expect(recognize(_r10Probe(base, revisions: base.revisions.skip(1).toList())).stage, no);
      for (var i = 0; i < 3; i++) {
        final revisions = base.revisions.toList();
        revisions[i] = _r10RevisionProbe(revisions[i], parents: 'a' * 40);
        expect(recognize(_r10Probe(base, revisions: revisions)).stage, no);
      }
      expect(recognize(_r10Probe(base, head: '0' * 40)).stage, no);
    }
    for (final parent in [r10FixtureMaintenanceEntry, _r10DecisionEntry + ' ' + 'a' * 40]) {
      expect(recognize(_r10Probe(committed, revisions: [...pending.revisions,
        _r10RevisionProbe(decision, parents: parent)])).stage, no);
    }
    final drift = _R10Revision('d' * 40, decision.id,
      _r10ProbeRaw(cui2a0RoadmapPath), _r10DecisionDocuments, guards);
    final restore = _R10Revision('f' * 40, drift.id,
      _r10ProbeRaw(cui2a0RoadmapPath), _r10DecisionDocuments, guards);
    expect(recognize(_r10Probe(committed, head: restore.id,
      revisions: [...committed.revisions, drift, restore])).stage, no);
    for (final path in r10PresentationPaths) {
      final ui = _R10Revision('d' * 40, decision.id,
        _r10ProbeRaw(path, status: path == _r10VisualPath ? 'A' : 'M'),
        _r10DecisionDocuments, guards);
      expect(recognize(_r10Probe(committed, head: ui.id,
        revisions: [...committed.revisions, ui])).stage, no);
    }
  });
  test('R10 decision rejects changed committed sources and documents', () {
    for (final path in guards.keys) {
      expect(recognize(_r10Probe(committed, revisions: [...pending.revisions,
        _r10RevisionProbe(decision, guards: {...guards, path: '0' * 40})])).stage, no);
    }
    for (var i = 0; i < 3; i++) {
      final revisions = committed.revisions.toList();
      revisions[i] = _r10RevisionProbe(revisions[i],
        documents: _r10DecisionDocuments);
      expect(recognize(_r10Probe(committed, revisions: revisions)).stage, no);
    }
    expect(recognize(_r10Probe(committed, revisions: [...pending.revisions,
      _r10RevisionProbe(decision, documents: _r10MaintenanceDocuments)])).stage, no);
  });
  test('R10 decision rejects protected UI branch file-type and untracked inventory drift', () {
    for (final base in [pending, committed]) {
      for (final path in _cui2a1ProtectedBlobs.keys) {
        expect(recognize(_r10Probe(base,
          protected: {...base.protected, path: '0' * 40})).stage, no);
      }
      for (final path in _r10MaintenanceUiBlobs.keys) {
        expect(recognize(base, ui: {..._r10MaintenanceUiBlobs, path: '0' * 40}).stage, no);
      }
      for (final inventory in [base.untracked.skip(1).toList(),
        [...base.untracked, 'docs/forged.md'], [...base.untracked, _r10VisualPath]]) {
        expect(recognize(_r10Probe(base, untracked: inventory)).stage, no);
      }
      for (final path in {..._r10DecisionPaths, ...cui2a1CompatibilityPaths, ...r10PresentationPaths}) {
        expect(recognize(_r10Probe(base, nonRegularPaths: {path})).stage, no);
      }
      expect(recognize(_r10Probe(base, branch: 'unauthorized')).stage, no);
    }
  });
}

void _registerR10FixtureMaintenanceTests() {
  // Preserve the original historical source input independently of later live edits.
  final sources = {for (final e in _r10DecisionEntryGuardBlobs.entries)
    e.key: _git(['cat-file', 'blob', e.value])};
  const guards = _r10HistoricalMaintenanceGuardBlobs;
  final uiWork = _cui2a1DirtyPaths.followedBy(r10PresentationPaths.where((p) => p != _r10VisualPath))
    .map((p) => _r10ProbeRaw(p)).join();
  final raw = _r10MaintenancePaths.map((p) => _r10ProbeRaw(p)).join();
  // Historical evidence is independent of live HEAD, index and working inventory.
  final pending = _R10PresentationEvidence(
    branch: 'main', head: r10FixtureMaintenanceEntry, entry: _r10PresentationEntryRevision,
    revisions: [_r10Revision(r10FixtureMaintenanceEntry, r10PresentationEntry)],
    sources: _r10MaintenanceSources, protected: _cui2a1ProtectedBlobs,
    indexRaw: '', workRaw: uiWork + raw,
    untracked: [..._cui2a1UntrackedPaths, _r10VisualPath]);
  // Synthetic commits below are in-memory adversarial fixtures, never authority pins.
  final maintenance = _R10Revision(_r10FixtureMaintenanceCommit, r10FixtureMaintenanceEntry, raw,
    _r10MaintenanceDocuments, guards);
  final committed = _r10Probe(pending, head: maintenance.id,
    revisions: [pending.revisions.first, maintenance],
    workRaw: uiWork);
  R10PresentationRecognition recognize(_R10PresentationEvidence e,
      {Map<String, String>? ui}) => _classifyR10FixtureMaintenance(e, guards, ui ?? _r10MaintenanceUiBlobs);
  const no = R10PresentationStage.rejected;
  test('R10 fixture maintenance historical pending review preserves UI and grants no release', () {
    final historical = recognize(pending);
    expect(historical.compatible, isTrue);
    expect(historical.stage, R10PresentationStage.boundedUi);
    expect(historical.maintenanceState, 'pendingReview');
    expect(historical.observedMaintenanceCommit, isNull);
    expect(historical.productionExecutionAuthorized, isFalse);
    expect(historical.separateOwnerUiReleaseRequired, isTrue);
    expect(recognize(pending).maintenanceState, 'pendingReview');
    final original = _r10Probe(committed, head: r10FixtureMaintenanceEntry,
      revisions: [pending.revisions.first], sources: _r10PresentationSources);
    expect(_classifyR10Presentation(original).stage, R10PresentationStage.boundedUi);
  });
  test('R10 fixture maintenance live committed composition is independently recognized', () {
    final live = recognizeR10PresentationStage();
    expect(live.stage, R10PresentationStage.boundedUi);
    expect(live.maintenanceState, 'committed');
    expect(live.observedMaintenanceCommit, _r10FixtureMaintenanceCommit);
    expect(live.observedAuthorizationCommit, r10FixtureMaintenanceEntry);
    expect(live.productionExecutionAuthorized, isFalse);
    expect(live.separateOwnerUiReleaseRequired, isTrue);
  });
  test('R10 historical fixture inventory stays literal and rejects the UI test', () {
    expect(hasFrozenCui2a1FixtureBoundary(), isTrue);
    expect(hasFrozenCui2a1FixtureBoundary(
      untrackedPaths: [..._cui2a1UntrackedPaths, _r10VisualPath]), isFalse);
    expect(hasOwnerPlanningFixtureBoundary(
      untrackedPaths: [..._cui2a1UntrackedPaths, _r10VisualPath]), isFalse);
  });
  test('R10 maintenance direct child observes actual sources and supports later six-path UI closure', () {
    final result = recognize(committed);
    expect(result.stage, R10PresentationStage.boundedUi);
    expect(result.maintenanceState, 'committed');
    expect(result.observedMaintenanceCommit, maintenance.id);
    expect(result.observedGuardBlobs, guards);
    expect(result.productionExecutionAuthorized, isFalse);
    for (final path in r10PresentationPaths) {
      final revision = _R10Revision('d' * 40, maintenance.id,
        _r10ProbeRaw(path, status: path == _r10VisualPath ? 'A' : 'M'),
        _r10MaintenanceDocuments, guards);
      final next = _r10Probe(committed, head: revision.id,
        revisions: [...committed.revisions, revision],
        untracked: path == _r10VisualPath ? _cui2a1UntrackedPaths.toList() : committed.untracked);
      expect(recognize(next).stage, R10PresentationStage.boundedUi, reason: path);
    }
  });
  test('R10 maintenance rejects missing altered or commercially expanded authority and protected bytes', () {
    for (final base in [pending, committed]) {
      for (final entry in _r10MaintenanceSources.entries) {
        expect(recognize(_r10Probe(base, sources: {...base.sources,
          entry.key: entry.value + '\nunauthorized'})).stage, no);
        expect(recognize(_r10Probe(base, sources: Map.from(base.sources)..remove(entry.key))).stage, no);
      }
      expect(recognize(_r10Probe(base, sources: _r10PresentationSources)).stage, no);
      expect(recognize(_r10Probe(base, sources: {...base.sources, cui2a0RoadmapPath:
        base.sources[cui2a0RoadmapPath]!.replaceFirst(
          'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO', 'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES')})).stage, no);
      for (final entry in _cui2a1ProtectedBlobs.entries) {
        expect(recognize(_r10Probe(base, protected: {...base.protected, entry.key: '0' * 40})).stage, no);
      }
    }
  });
  test('R10 maintenance rejects source drift and nonunique fingerprint declarations', () {
    for (final entry in sources.entries) {
      expect(_r10ApprovedMaintenanceGuardBlobs({...sources,
        entry.key: entry.value + '\n// unauthorized drift\n'}), isNull);
    }
    const path = 'test/commercial_cui2a0_admin_business_draft_foundation_migration_test.dart';
    final declaration = "const _r10MaintenanceCuiFingerprint = '$_r10MaintenanceCuiFingerprint';";
    for (final replacement in ['', declaration + '\n' + declaration,
      "const _r10MaintenanceCuiFingerprint = '0';"]) {
      expect(_r10ApprovedMaintenanceGuardBlobs({...sources,
        path: sources[path]!.replaceFirst(declaration, replacement)}), isNull);
    }
  });
  test('R10 maintenance rejects extra untracked paths index drift modes and altered UI', () {
    for (final base in [pending, committed]) {
      for (final path in ['test/unauthorized_test.dart', _r10VisualPath + '.bak',
        'docs/unauthorized.md', 'supabase/config.toml']) {
        expect(recognize(_r10Probe(base, untracked: [...base.untracked, path])).stage, no);
        expect(recognize(_r10Probe(base, workRaw: base.workRaw + _r10ProbeRaw(path))).stage, no);
        expect(recognize(_r10Probe(base, indexRaw: _r10ProbeRaw(path))).stage, no);
      }
      expect(recognize(_r10Probe(base, nonRegularPaths: {_r10VisualPath})).stage, no);
    }
    expect(recognize(_r10Probe(pending, indexRaw: _r10ProbeRaw(r10PresentationPaths.first))).stage, no);
    for (final entry in _r10MaintenanceUiBlobs.entries) {
      expect(recognize(pending, ui: {..._r10MaintenanceUiBlobs, entry.key: '0' * 40}).stage, no);
    }
    for (final status in ['D', 'A', 'T', 'R100']) {
      expect(recognize(_r10Probe(committed, revisions: [pending.revisions.first,
        _r10RevisionProbe(maintenance, raw: raw.replaceFirst(
          _r10ProbeRaw(cui2a0RoadmapPath), _r10ProbeRaw(cui2a0RoadmapPath, status: status)))])).stage, no);
    }
  });
  test('R10 maintenance rejects invalid ancestry changed guards documents and post-maintenance drift', () {
    for (final parent in [r10PresentationEntry, r10FixtureMaintenanceEntry + ' ' + 'a' * 40]) {
      expect(recognize(_r10Probe(committed, revisions: [pending.revisions.first,
        _r10RevisionProbe(maintenance, parents: parent)])).stage, no);
    }
    for (final path in _r10MaintenancePaths) {
      final drift = _R10Revision('d' * 40, maintenance.id, _r10ProbeRaw(path),
        _r10MaintenanceDocuments, guards);
      final restore = _R10Revision('e' * 40, drift.id, _r10ProbeRaw(path),
        _r10MaintenanceDocuments, guards);
      expect(recognize(_r10Probe(committed, head: restore.id,
        revisions: [...committed.revisions, drift, restore])).stage, no);
    }
    for (final path in cui2a1CompatibilityPaths) {
      expect(recognize(_r10Probe(committed, revisions: [pending.revisions.first,
        _r10RevisionProbe(maintenance, guards: {...guards, path: '0' * 40})])).stage, no);
    }
    expect(recognize(_r10Probe(committed, revisions: [pending.revisions.first,
      _r10RevisionProbe(maintenance, documents: _r10PresentationDocuments)])).stage, no);
    expect(recognize(_r10Probe(committed, branch: 'other')).stage, no);
  });
  final correctedGuards = _r10ApprovedMaintenanceGuardBlobs(sources)!;
  final correctionPending = _r10Probe(committed,
    workRaw: committed.workRaw + _r10ProbeRaw(_r10CuiPath));
  final correction = _R10Revision('f' * 40, _r10FixtureMaintenanceCommit,
    _r10ProbeRaw(_r10CuiPath), _r10MaintenanceDocuments, correctedGuards);
  final correctionCommitted = _r10Probe(committed, head: correction.id,
    revisions: [...committed.revisions, correction]);
  R10PresentationRecognition corrected(_R10PresentationEvidence e,
      {Map<String, String>? candidateSources, Map<String, String>? ui}) {
    final approved = _r10ApprovedMaintenanceGuardBlobs(candidateSources ?? sources);
    return approved == null ? const R10PresentationRecognition(R10PresentationStage.rejected)
      : _classifyR10CuiFixtureCorrection(e, approved, ui ?? _r10MaintenanceUiBlobs);
  }
  test('R10 CUI correction preserves the exact historical source and fingerprint oracle', () {
    final historicalSources = {...sources,
      _r10CuiPath: _git(['cat-file', 'blob', guards[_r10CuiPath]!])};
    expect(_r10ApprovedMaintenanceGuardBlobs(historicalSources), guards);
    expect(correctedGuards[_r10CuiPath], isNot(guards[_r10CuiPath]));
    for (final entry in _r10MaintenanceOtherGuardBlobs.entries) {
      expect(correctedGuards[entry.key], entry.value);
    }
    for (final base in [correctionPending, correctionCommitted]) {
      for (final entry in sources.entries) {
        expect(corrected(base, candidateSources: {...sources,
          entry.key: entry.value + '\n// unauthorized correction\n'}).stage, no);
      }
    }
  });
  test('R10 CUI correction exact unstaged candidate preserves committed maintenance without release', () {
    final result = corrected(correctionPending);
    expect(result.stage, R10PresentationStage.boundedUi);
    expect(result.maintenanceState, 'committed');
    expect(result.observedMaintenanceCommit, _r10FixtureMaintenanceCommit);
    expect(result.observedGuardBlobs, correctedGuards);
    expect(result.productionExecutionAuthorized, isFalse);
    expect(result.separateOwnerUiReleaseRequired, isTrue);
    expect(corrected(pending).stage, no);
    expect(corrected(committed).stage, no); // Corrected source cannot masquerade as the old tree.
  });
  test('R10 CUI correction exact direct child remains testable independently of live HEAD', () {
    final result = corrected(correctionCommitted);
    expect(result.stage, R10PresentationStage.boundedUi);
    expect(result.maintenanceState, 'committed');
    expect(result.observedMaintenanceCommit, _r10FixtureMaintenanceCommit);
    expect(result.observedGuardBlobs, correctedGuards);
    expect(result.productionExecutionAuthorized, isFalse);
    expect(result.separateOwnerUiReleaseRequired, isTrue);
    expect(corrected(_r10Probe(correctionCommitted,
      workRaw: correctionPending.workRaw)).stage, no);
  });
  test('R10 CUI correction rejects authorization protected UI and independent inventory drift', () {
    for (final base in [correctionPending, correctionCommitted]) {
      expect(corrected(_r10Probe(base, branch: 'other')).stage, no);
      expect(corrected(_r10Probe(base, nonRegularPaths: {_r10CuiPath})).stage, no);
      for (final entry in _r10MaintenanceSources.entries) {
        expect(corrected(_r10Probe(base, sources: {...base.sources,
          entry.key: entry.value + '\nunauthorized'})).stage, no);
        expect(corrected(_r10Probe(base,
          sources: Map.from(base.sources)..remove(entry.key))).stage, no);
      }
      expect(corrected(_r10Probe(base, sources: {...base.sources, cui2a0RoadmapPath:
        base.sources[cui2a0RoadmapPath]!.replaceFirst(
          'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO', 'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: YES')})).stage, no);
      for (final entry in _cui2a1ProtectedBlobs.entries) {
        expect(corrected(_r10Probe(base,
          protected: {...base.protected, entry.key: '0' * 40})).stage, no);
      }
      for (final entry in _r10MaintenanceUiBlobs.entries) {
        expect(corrected(base, ui: {..._r10MaintenanceUiBlobs, entry.key: '0' * 40}).stage, no);
      }
      for (final path in ['test/unauthorized_test.dart', _r10VisualPath + '.bak',
        'docs/unauthorized.md', 'supabase/config.toml',
        ..._r10MaintenanceOtherGuardBlobs.keys, cui2a0RoadmapPath]) {
        expect(corrected(_r10Probe(base, untracked: [...base.untracked, path])).stage, no);
        expect(corrected(_r10Probe(base, workRaw: base.workRaw + _r10ProbeRaw(path))).stage, no);
      }
      for (final path in [_r10CuiPath, ...r10PresentationPaths, cui2a0RoadmapPath]) {
        expect(corrected(_r10Probe(base, indexRaw: _r10ProbeRaw(path))).stage, no);
      }
      expect(corrected(_r10Probe(base,
        untracked: base.untracked.where((p) => p != _r10VisualPath).toList())).stage,
        no);
      expect(corrected(_r10Probe(base,
        untracked: base.untracked.where((p) => p != _cui2a1UntrackedPaths.first).toList())).stage, no);
      for (final parent in [r10PresentationEntry, r10FixtureMaintenanceEntry + ' ' + 'a' * 40]) {
        expect(corrected(_r10Probe(base, revisions: [base.revisions.first,
          _r10RevisionProbe(maintenance, parents: parent), ...base.revisions.skip(2)])).stage, no);
      }
      for (final path in cui2a1CompatibilityPaths) {
        expect(corrected(_r10Probe(base, revisions: [base.revisions.first,
          _r10RevisionProbe(maintenance, guards: {...guards, path: '0' * 40}),
          ...base.revisions.skip(2)])).stage, no);
      }
    }
  });
  test('R10 CUI correction rejects extra paths modes source mismatches and unrelated successors', () {
    for (final raw in ['', _r10ProbeRaw(_r10CuiPath) + _r10ProbeRaw(_r10CuiPath),
      _r10ProbeRaw(_r10CuiPath) + _r10ProbeRaw(cui2a0RoadmapPath),
      for (final status in ['A', 'D', 'T', 'R100']) _r10ProbeRaw(_r10CuiPath, status: status),
      _r10ProbeRaw(_r10CuiPath, newMode: '100755'),
      _r10ProbeRaw(_r10CuiPath, newMode: '120000')]) {
      expect(corrected(_r10Probe(correctionPending, workRaw: uiWork + raw)).stage, no);
      expect(corrected(_r10Probe(correctionCommitted,
        revisions: [...committed.revisions, _r10RevisionProbe(correction, raw: raw)])).stage, no);
    }
    for (final parent in [r10FixtureMaintenanceEntry,
      _r10FixtureMaintenanceCommit + ' ' + 'a' * 40]) {
      expect(corrected(_r10Probe(correctionCommitted, revisions: [...committed.revisions,
        _r10RevisionProbe(correction, parents: parent)])).stage, no);
    }
    for (final path in cui2a1CompatibilityPaths) {
      expect(corrected(_r10Probe(correctionCommitted, revisions: [...committed.revisions,
        _r10RevisionProbe(correction, guards: {...correctedGuards, path: '0' * 40})])).stage, no);
    }
    expect(corrected(_r10Probe(correctionCommitted, revisions: [...committed.revisions,
      _r10RevisionProbe(correction, documents: _r10PresentationDocuments)])).stage, no);
    expect(corrected(_r10Probe(correctionPending, head: 'e' * 40)).stage, no);
    final unrelated = _R10Revision('e' * 40, correction.id, _r10ProbeRaw(_r10CuiPath),
      _r10MaintenanceDocuments, correctedGuards);
    expect(corrected(_r10Probe(correctionCommitted, head: unrelated.id,
      revisions: [...correctionCommitted.revisions, unrelated])).stage, no);
    expect(corrected(_r10Probe(correctionCommitted, head: _r10FixtureMaintenanceCommit)).stage, no);
  });
}

// Synthetic IDs here are in-memory fixtures, never future authority pins.
String _r10ProbeRaw(String path, {String status = 'M',
  String oldMode = '100644', String newMode = '100644'}) =>
    ':' + (status == 'A' ? '000000' : oldMode) + ' ' + newMode +
    ' ' + '1' * 40 + ' ' + '2' * 40 + ' ' + status + '\t' + path + '\n';
_R10PresentationEvidence _r10Probe(_R10PresentationEvidence e, {
  String? branch, String? head, String? indexRaw, String? workRaw,
  _R10Revision? entry, List<_R10Revision>? revisions,
  Map<String, String>? sources, Map<String, String>? protected, List<String>? untracked,
  Set<String>? nonRegularPaths, String? roadmapRawBlob,
}) => _R10PresentationEvidence(branch: branch ?? e.branch, head: head ?? e.head,
  entry: entry ?? e.entry, revisions: revisions ?? e.revisions,
  sources: sources ?? e.sources, protected: protected ?? e.protected,
  indexRaw: indexRaw ?? e.indexRaw, workRaw: workRaw ?? e.workRaw,
  untracked: untracked ?? e.untracked, nonRegularPaths: nonRegularPaths ?? e.nonRegularPaths,
  roadmapRawBlob: roadmapRawBlob ?? e.roadmapRawBlob);
_R10Revision _r10RevisionProbe(_R10Revision r, {String? parents, String? raw,
  Map<String, String>? documents, Map<String, String>? guards}) =>
    _R10Revision(r.id, parents ?? r.parents, raw ?? r.raw,
      documents ?? r.documents, guards ?? r.guards);
void _registerR10PresentationBoundaryTests() {
  final dirtyRaw = _cui2a1DirtyPaths.map((p) => _r10ProbeRaw(p)).join();
  final fiveRaw = {...cui2a1CompatibilityPaths, cui2a0RoadmapPath}.map((p) => _r10ProbeRaw(p)).join();
  final entry = _r10PresentationEntryRevision;
  final pending = _R10PresentationEvidence(
    branch: 'main', head: r10PresentationEntry, entry: entry, revisions: const [],
    sources: _r10PresentationSources, protected: _cui2a1ProtectedBlobs,
    indexRaw: '', workRaw: fiveRaw + dirtyRaw, untracked: _cui2a1UntrackedPaths.toList());
  final authorization = _R10Revision('b' * 40, r10PresentationEntry, fiveRaw,
    _r10PresentationDocuments, {
      for (var i = 0; i < cui2a1CompatibilityPaths.length; i++)
        cui2a1CompatibilityPaths.elementAt(i): (i + 1).toString() * 40,
    });
  final committed = _r10Probe(pending, head: authorization.id,
    revisions: [authorization], workRaw: dirtyRaw);
  R10PresentationStage stage(_R10PresentationEvidence e) => _classifyR10Presentation(e).stage;
  const no = R10PresentationStage.rejected;
  test('R10 actual stage proves compatibility only, never procedural Owner UI release', () {
    final live = recognizeR10PresentationStage();
    expect(live.compatible, isTrue);
    expect(live.productionExecutionAuthorized, isFalse);
    expect(live.separateOwnerUiReleaseRequired, isTrue);
    if (_git(['rev-parse', 'HEAD']).trim() == r10PresentationEntry) {
      expect(live.stage, R10PresentationStage.pendingReview);
      expect(live.committedAuthorityObserved, isFalse);
      expect(live.observedAuthorizationCommit, isNull);
      expect(hasR10FreezeBoundary(), isFalse);
    } else {
      expect(live.committedAuthorityObserved, isTrue);
      expect(live.observedGuardBlobs.keys.toSet(), cui2a1CompatibilityPaths);
    }
    expect(hasR10FreezeFixtureBoundary(), isTrue);
  });
  test('R10 pending exact five-path pair is unstaged, zero UI, review only', () {
    expect(stage(pending), R10PresentationStage.pendingReview);
    for (final path in r10PresentationPaths) {
      expect(stage(_r10Probe(pending, workRaw: pending.workRaw + _r10ProbeRaw(path))), no);
      expect(stage(_r10Probe(pending, indexRaw: _r10ProbeRaw(path))), no);
      expect(stage(_r10Probe(pending, untracked: [...pending.untracked, path])), no);
    }
    for (final path in {...cui2a1CompatibilityPaths, cui2a0RoadmapPath}) {
      expect(stage(_r10Probe(pending, workRaw: pending.workRaw.replaceFirst(_r10ProbeRaw(path), ''))), no);
      expect(stage(_r10Probe(pending, indexRaw: _r10ProbeRaw(path))), no);
    }
    expect(stage(_r10Probe(pending, branch: 'unauthorized')), no);
    expect(stage(_r10Probe(pending, head: r10AuthorizationCommit)), no);
  });
  test('R10 committed zero UI requires exact five-path direct-child authority', () {
    final result = _classifyR10Presentation(committed);
    expect(result.stage, R10PresentationStage.committedZeroUi);
    expect(result.observedAuthorizationCommit, authorization.id);
    expect(result.observedGuardBlobs, authorization.guards);
    expect(result.productionExecutionAuthorized, isFalse);
    expect(result.separateOwnerUiReleaseRequired, isTrue);
    expect(stage(_r10Probe(committed, revisions: [])), no);
    for (final parent in [r10AuthorizationCommit, r10PresentationEntry + ' ' + 'a' * 40]) {
      expect(stage(_r10Probe(committed, revisions: [
        _r10RevisionProbe(authorization, parents: parent)])), no);
    }
    expect(stage(_r10Probe(committed, revisions: [
      _r10RevisionProbe(authorization, raw: fiveRaw + _r10ProbeRaw(r10PresentationPaths.first))])), no);
    expect(stage(_r10Probe(committed, revisions: [
      _r10RevisionProbe(authorization, guards: _r10EntryGuardBlobs)])), no);
  });
  test('R10 permits exact partial UI at each layer and visual A then M only', () {
    for (final path in r10PresentationPaths) {
      final delta = _r10ProbeRaw(path, status: path == _r10VisualPath ? 'A' : 'M');
      expect(stage(_r10Probe(committed, indexRaw: delta)), R10PresentationStage.boundedUi, reason: 'Index ' + path);
      if (path != _r10VisualPath) {
        expect(stage(_r10Probe(committed, workRaw: dirtyRaw + delta)), R10PresentationStage.boundedUi, reason: 'Work ' + path);
      }
      final revision = _R10Revision('c' * 40, authorization.id, delta,
        _r10PresentationDocuments, authorization.guards);
      final ui = _r10Probe(committed, head: revision.id, revisions: [authorization, revision]);
      expect(stage(ui), R10PresentationStage.boundedUi, reason: 'Commit ' + path);
      if (path == _r10VisualPath) {
        expect(stage(_r10Probe(ui, indexRaw: _r10ProbeRaw(path),
          workRaw: dirtyRaw + _r10ProbeRaw(path))), R10PresentationStage.boundedUi);
        expect(stage(_r10Probe(committed, indexRaw: delta,
          workRaw: dirtyRaw + _r10ProbeRaw(path))), R10PresentationStage.boundedUi);
      }
    }
    expect(stage(_r10Probe(committed, untracked: [...committed.untracked, _r10VisualPath])),
      R10PresentationStage.boundedUi);
    expect(stage(_r10Probe(committed, indexRaw: _r10ProbeRaw(_r10VisualPath))), no);
    expect(stage(_r10Probe(committed, workRaw: dirtyRaw + _r10ProbeRaw(_r10VisualPath))), no);
  });
  test('R10 extra paths fail independently in commit, index, work and untracked', () {
    for (final path in {...cui2a1CompatibilityPaths, ..._r10Sources.keys,
      ..._cui2a1ProtectedBlobs.keys, 'lib/unauthorized.dart', 'pubspec.yaml',
      'supabase/config.toml', 'supabase/migrations/00027_unauthorized.sql',
      'test/unauthorized_test.dart', 'docs/unauthorized.md', 'artifacts/new.png',
      _r10VisualPath + '.bak'}) {
      final raw = _r10ProbeRaw(path);
      expect(stage(_r10Probe(committed, indexRaw: raw)), no, reason: 'Index ' + path);
      if (!_cui2a1DirtyPaths.contains(path)) {
        expect(stage(_r10Probe(committed, workRaw: dirtyRaw + raw)), no, reason: 'Work ' + path);
      }
      expect(stage(_r10Probe(committed, untracked: [...committed.untracked, path])), no, reason: 'Untracked ' + path);
      final revision = _R10Revision('c' * 40, authorization.id, raw,
        _r10PresentationDocuments, authorization.guards);
      expect(stage(_r10Probe(committed, head: revision.id, revisions: [authorization, revision])), no,
        reason: 'Committed ' + path);
    }
  });
  test('R10 rejects unauthorized statuses, file modes, duplicate paths and new screens', () {
    for (final path in r10PresentationPaths) {
      expect(stage(_r10Probe(committed, nonRegularPaths: {path})), no,
        reason: 'Reject nonregular files, including dangling untracked links: ' + path);
      for (final status in ['D', 'T', 'R100', 'C100', '??']) {
        final raw = _r10ProbeRaw(path, status: status);
        expect(stage(_r10Probe(committed, indexRaw: raw)), no);
        expect(stage(_r10Probe(committed, workRaw: dirtyRaw + raw)), no);
      }
      for (final mode in ['120000', '100755', '160000']) {
        expect(stage(_r10Probe(committed, indexRaw: _r10ProbeRaw(path, newMode: mode))), no);
        expect(stage(_r10Probe(committed, indexRaw: _r10ProbeRaw(path, oldMode: mode))), no);
      }
      if (path != _r10VisualPath) {
        expect(stage(_r10Probe(committed, indexRaw: _r10ProbeRaw(path, status: 'A'))), no);
        expect(stage(_r10Probe(committed, untracked: [...committed.untracked, path])), no);
      }
    }
    expect(stage(_r10Probe(committed, indexRaw: _r10ProbeRaw(r10PresentationPaths.first) * 2)), no);
    expect(stage(_r10Probe(committed, indexRaw: 'malformed')), no);
  });
  test('R10 rejects missing or changed documents, entry identities and authorization', () {
    for (final e in _r10PresentationSources.entries) {
      final changed = {..._r10PresentationSources, e.key: e.value + '\nunauthorized'};
      expect(changed[e.key], isNot(e.value));
      for (final base in [pending, committed]) {
        expect(stage(_r10Probe(base, sources: changed)), no);
        expect(stage(_r10Probe(base, sources: Map.from(_r10PresentationSources)..remove(e.key))), no);
      }
    }
    for (final e in _r10EntryGuardBlobs.entries) {
      expect(stage(_r10Probe(committed, entry: _r10RevisionProbe(entry,
        guards: {...entry.guards, e.key: '0' * 40}))), no);
    }
    expect(stage(_r10Probe(committed, entry: _r10RevisionProbe(entry, parents: r10FreezeCommit))), no);
    for (final path in _r10PresentationDocuments.keys) {
      expect(stage(_r10Probe(committed, revisions: [
        _r10RevisionProbe(authorization, documents: {..._r10PresentationDocuments, path: 'unauthorized'})])), no);
    }
  });
  test('R10 exact eight raw hashes, dirty paths and untracked inventory are mandatory', () {
    for (final e in _cui2a1ProtectedBlobs.entries) {
      for (final base in [pending, committed]) {
        expect(stage(_r10Probe(base, protected: {...base.protected, e.key: '0' * 40})), no);
        expect(stage(_r10Probe(base, protected: Map.from(base.protected)..remove(e.key))), no);
      }
    }
    expect(stage(_r10Probe(committed, untracked: [])), no);
    expect(stage(_r10Probe(committed, workRaw: '')), no);
    expect(stage(_r10Probe(committed, untracked: [...committed.untracked, committed.untracked.first])), no);
  });
  test('R10 per-commit history rejects restored drift and mutable approved guards', () {
    for (final path in [cui2a0RoadmapPath, cui2a1CompatibilityPaths.first,
      'lib/unauthorized.dart', 'supabase/config.toml']) {
      final drift = _R10Revision('c' * 40, authorization.id, _r10ProbeRaw(path),
        _r10PresentationDocuments, authorization.guards);
      final restored = _R10Revision('d' * 40, drift.id, _r10ProbeRaw(path),
        _r10PresentationDocuments, authorization.guards);
      expect(stage(_r10Probe(committed, head: restored.id,
        revisions: [authorization, drift, restored])), no);
    }
    final later = _R10Revision('c' * 40, authorization.id,
      _r10ProbeRaw(r10PresentationPaths.first), _r10PresentationDocuments,
      {...authorization.guards, cui2a1CompatibilityPaths.first: 'e' * 40});
    expect(stage(_r10Probe(committed, head: later.id, revisions: [authorization, later])), no);
    expect(stage(_r10Probe(committed, head: 'e' * 40)), no);
  });
  test('R10 exact append preserves commercial restrictions and procedural release gates', () {
    for (final token in ['IMPLEMENTATION_AUTHORIZED: YES — R10.5-D PRESENTATION ONLY',
      'R10.5-D_EXECUTION_STATE: BLOCKED', 'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO',
      'CUI2A1_IMPLEMENTATION_AUTHORIZED: NO', 'M4_STATE: NOT AUTHORIZED',
      'M5_STATE: NOT AUTHORIZED', 'R10.5-E/F_R10.6_R10.7: LOCKED',
      'COMMIT_PUSH_AUTHORIZED_TO_AGENTS: NO', 'separate UI release instruction',
      'independent Big Pickle review']) {
      expect(r10PresentationAppend, contains(token));
      final altered = (r10AuthorizedRoadmap + r10PresentationAppend).replaceFirst(token, 'unauthorized');
      expect(altered, isNot(_r10PresentationSources[cui2a0RoadmapPath]));
      expect(stage(_r10Probe(committed, sources: {...committed.sources, cui2a0RoadmapPath: altered})), no);
    }
    for (final roadmap in [r10AuthorizedRoadmap, committed.sources[cui2a0RoadmapPath]! + '\n# Future authority']) {
      expect(stage(_r10Probe(committed, sources: {...committed.sources, cui2a0RoadmapPath: roadmap})), no);
    }
  });
}

// Independently authored exact transformation of the fixed 48004703 HARDEN1.
// Each anchor is unique; the expected result is never copied from the live file.
const r10PresentationHardenEdits = <(String, String)>[
  (r'''postClosureImplementationChanges.isEmpty && cui2a0.hasR10FreezeBoundary();''', r'''postClosureImplementationChanges.isEmpty && cui2a0.hasR10PresentationCompatibility();'''),
  (r'''void _registerR10FreezeTests() {
  final paths = _cui1ChangedPaths(_git([
    'diff', '--name-only', '--no-renames', _cui1BaselineCommit,
  ]));
  final documents = <String, String>{
    for (final path in _closedCommittedDocuments.keys) path: _read(path),
    cui2a0.cui2a1ContractPath: _read(cui2a0.cui2a1ContractPath),
    cui2a0.ownerPlanningReadinessPath: _read(cui2a0.ownerPlanningReadinessPath),
    cui2a0.r10ContractPath: _read(cui2a0.r10ContractPath),
  };
  final roadmap = _read(_cui1RoadmapPath);''', r'''void _registerR10FreezeTests() {
  // Immutable freeze fixture; no pending activation is continuing freeze authority.
  final paths = _cui1ChangedPaths(_git([
    'diff', '--name-only', '--no-renames', _cui1BaselineCommit, cui2a0.r10PresentationEntry,
  ]));
  final documents = <String, String>{
    ..._closedCommittedDocuments,
    cui2a0.cui2a1ContractPath: cui2a0.cui2a1FrozenContract,
    cui2a0.ownerPlanningReadinessPath: cui2a0.ownerPlanningReadiness,
    cui2a0.r10ContractPath: cui2a0.r10FrozenContract,
  };
  final roadmap = cui2a0.r10AuthorizedRoadmap;'''),
  (r'''expect(cui2a0.hasR10FreezeBoundary(), isTrue);''', r'''expect(cui2a0.hasR10FreezeFixtureBoundary(), isTrue);'''),
  (r'''      }) => _allowsR10FreezeComposition(''', r'''      }) => _allowsR10PresentationComposition('''),
  (r'''bool _matchesCui1MediaAuthority''', r'''// Ordinary R10.5-D stage projection, after the shared live layer checks.
// This source boundary never proves the separate procedural Owner UI release.
bool _allowsR10PresentationComposition(
  Iterable<String> changedPaths,
  String roadmap,
  Map<String, String> documents,
  Iterable<String> postClosureImplementationChanges,
) {
  final recognition = cui2a0.recognizeR10PresentationStage();
  final uiPaths = recognition.stage == cui2a0.R10PresentationStage.boundedUi
      ? cui2a0.r10PresentationPaths : const <String>{};
  return recognition.compatible &&
    cui2a0.matchesR10PresentationDocuments(
      roadmap, documents[cui2a0.cui2a1ContractPath] ?? '',
      documents[cui2a0.ownerPlanningReadinessPath] ?? '',
      documents[cui2a0.r10ContractPath] ?? '',
    ) &&
    postClosureImplementationChanges.every(uiPaths.contains) &&
    _allowsR10FreezeComposition(
      changedPaths.where((path) => !uiPaths.contains(path)),
      cui2a0.r10AuthorizedRoadmap, documents,
      const [],
    );
}

void _registerR10PresentationTests() {
  test('R10 presentation consumer uses shared stage and requires procedural release', () {
    final recognition = cui2a0.recognizeR10PresentationStage();
    expect(recognition.compatible, isTrue);
    expect(recognition.productionExecutionAuthorized, isFalse);
    expect(recognition.separateOwnerUiReleaseRequired, isTrue);
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
    expect(_allowsR10PresentationComposition(paths, roadmap, documents, []), isTrue);
    expect(_allowsR10FreezeComposition(paths, roadmap, documents, []), isFalse);
    for (final altered in [cui2a0.r10AuthorizedRoadmap, roadmap + '\nunauthorized',
      roadmap.replaceFirst('COMMERCIAL_CURRENT_SLICE: NONE', 'COMMERCIAL_CURRENT_SLICE: M4')]) {
      expect(altered, isNot(roadmap));
      expect(_allowsR10PresentationComposition(paths, altered, documents, []), isFalse);
    }
    for (final entry in documents.entries) {
      expect(_allowsR10PresentationComposition(paths, roadmap,
        {...documents, entry.key: entry.value + '\nunauthorized'}, []), isFalse);
    }
    for (final path in ['lib/unauthorized.dart', 'test/unauthorized_test.dart',
      'supabase/config.toml', 'docs/unauthorized.md']) {
      expect(_allowsR10PresentationComposition([...paths, path], roadmap, documents, []), isFalse);
      expect(_allowsR10PresentationComposition(paths, roadmap, documents, [path]), isFalse);
    }
  });
}

bool _matchesCui1MediaAuthority'''),
  (r'''  _registerR10FreezeTests();''', r'''  _registerR10FreezeTests();
  _registerR10PresentationTests();'''),
  (r'''              ? _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend + cui2a0.ownerPlanningDocumentaryAppend + cui2a0.r10FreezeAppend + cui2a0.r10AuthorizationAppend''', r'''              ? _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend + cui2a0.ownerPlanningDocumentaryAppend + cui2a0.r10FreezeAppend + cui2a0.r10AuthorizationAppend + cui2a0.r10PresentationAppend'''),
  (r'''    expect(roadmap.substring(checkpoint.length), _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend + cui2a0.ownerPlanningDocumentaryAppend + cui2a0.r10FreezeAppend + cui2a0.r10AuthorizationAppend);''', r'''    expect(roadmap.substring(checkpoint.length), _authorizedCommercialTrackControl + _cui1MediaReconciliation + _closedRoadmapAdditions + cui2a0.cui2a1DocumentaryAppend + cui2a0.ownerPlanningDocumentaryAppend + cui2a0.r10FreezeAppend + cui2a0.r10AuthorizationAppend + cui2a0.r10PresentationAppend);'''),
];
String compatibleR10PresentationHardenSourceFromFreeze(String freeze) {
  var expected = freeze;
  for (final edit in r10PresentationHardenEdits) {
    expected = _replaceOwnerPlanningAnchor(expected, edit.$1, edit.$2);
  }
  return expected;
}
String compatibleR10PresentationHardenSource(String historical) =>
    compatibleR10PresentationHardenSourceFromFreeze(compatibleR10FreezeHardenSource(historical));

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
  unstagedChanges: unstagedChanges ?? _cui2a1DirtyPaths,
  untrackedPaths: untrackedPaths ?? _cui2a1UntrackedPaths,
  preservedBlobs: preservedBlobs,
  pins: pins,
  executionCommit: executionCommit ?? r10FreezeParent,
  committedStatus: committedStatus ?? '',
  stagedStatus: stagedStatus ?? '',
  unstagedStatus: unstagedStatus ?? _cui2a1DirtyPaths.map((p) => 'M\t$p').join('\n'),
  implementationCommit: implementationCommit,
  closureCommit: closureCommit,
  freezeCommit: freezeCommit,
  compatibilityCommit: compatibilityCommit,
);

void _registerR10FreezeBoundaryTests() {
  test('R10 freeze live recognition is distinct from historical documentary fixtures', () {
    expect(_r10PinsMatch, isTrue);
    expect(hasR10FreezeFixtureBoundary(), isTrue);
    expect(hasOwnerPlanningFixtureBoundary(), isTrue);
    expect(hasOwnerPlanningDocumentaryBoundary(), isFalse);
    expect(hasR10FreezeFixtureBoundary(sources: _ownerPlanningSources), isFalse);
    expect(hasR10FreezeFixtureBoundary(executionCommit: r10FreezeCommit), isFalse);
    expect(hasR10FreezeFixtureBoundary(executionCommit: r10FreezeParent), isFalse);
    expect(hasR10FreezeFixtureBoundary(executionCommit: ownerPlanningCommit), isFalse);
  });
  test('R10 freeze requires the exact committed prospective authorization', () {
    expect(_git(['rev-parse', r10AuthorizationCommit + '^']).trim(), r10FreezeCommit);
    expect(r10AuthorizedRoadmap, r10FrozenRoadmap + r10AuthorizationAppend);
    expect(hasR10FreezeFixtureBoundary(), isTrue);
    expect(hasR10FreezeFixtureBoundary(sources: {..._r10Sources, cui2a0RoadmapPath: r10FrozenRoadmap}), isFalse);
    expect(hasR10FreezeFixtureBoundary(executionCommit: r10FreezeCommit), isFalse,
      reason: 'A pending working-copy authorization cannot replace a committed ancestor');
    expect(hasR10FreezeFixtureBoundary(pins: {..._r10Pins, 'authorization': r10FreezeCommit}), isFalse);
    expect(hasR10FreezeFixtureBoundary(pins: {..._r10Pins, 'authorizedRoadmap': r10RoadmapBlob}), isFalse);
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
      expect(hasR10FreezeFixtureBoundary(sources: {..._r10Sources, cui2a0RoadmapPath: changed}), isFalse, reason: key);
    }
  });
  test('R10 freeze rejects wrong and missing pins and retained authority pins', () {
    for (final pin in _r10Pins.entries) {
      expect(hasR10FreezeFixtureBoundary(pins: {..._r10Pins, pin.key: '0000000000000000000000000000000000000000'}), isFalse);
      expect(hasR10FreezeFixtureBoundary(pins: Map.from(_r10Pins)..remove(pin.key)), isFalse);
    }
    expect(hasR10FreezeFixtureBoundary(pins: {..._r10Pins, 'future': r10FreezeCommit}), isFalse);
    expect(hasR10FreezeFixtureBoundary(freezeCommit: ownerPlanningCommit), isFalse);
    expect(hasR10FreezeFixtureBoundary(compatibilityCommit: ownerPlanningCommit), isFalse);
  });
  test('R10 freeze rejects altered missing or extra documentary and security sources', () {
    for (final entry in _r10Sources.entries) {
      expect(hasR10FreezeFixtureBoundary(sources: {..._r10Sources, entry.key: entry.value + '\nunauthorized'}), isFalse, reason: entry.key);
      expect(hasR10FreezeFixtureBoundary(sources: Map.from(_r10Sources)..remove(entry.key)), isFalse, reason: entry.key);
    }
    expect(hasR10FreezeFixtureBoundary(sources: {..._r10Sources, r10ContractPath + '.bak': r10FrozenContract}), isFalse);
    for (final key in ['STATUS: ACCEPTED / FROZEN', 'IMPLEMENTATION_AUTHORIZED: NO',
      'COMMERCIAL_IMPLEMENTATION_AUTHORIZED: NO', 'CUI2A1_IMPLEMENTATION_AUTHORIZED: NO',
      'M4_STATE: NOT AUTHORIZED', 'M5_STATE: NOT AUTHORIZED']) {
      expect(r10FrozenContract, contains(key));
      final changed = r10FrozenContract.replaceFirst(key, 'unauthorized');
      expect(changed, isNot(r10FrozenContract));
      expect(hasR10FreezeFixtureBoundary(sources: {..._r10Sources, r10ContractPath: changed}), isFalse, reason: key);
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
      expect(hasR10FreezeFixtureBoundary(sources: {..._r10Sources, cui2a0RoadmapPath: changed}), isFalse, reason: key);
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
      expect(hasR10FreezeFixtureBoundary(sources: {..._r10Sources, cui2a0RoadmapPath: changed}), isFalse);
    }
  });
  test('R10 freeze rejects independent repository-layer drift and wrong path status', () {
    for (final path in [
      ..._r10Sources.keys, ...r10PresentationPaths, ..._cui2a1ProtectedBlobs.keys,
      r10ContractPath + '.bak', 'docs/unauthorized.md', 'test/unauthorized_test.dart',
      'lib/features/business/presentation/screens/admin_business_draft_screen.dart',
      'supabase/migrations/00027_unauthorized.sql', 'supabase/config.toml', 'pubspec.yaml',
    ]) {
      expect(hasR10FreezeFixtureBoundary(committedChanges: [path]), isFalse, reason: 'Committed ' + path);
      expect(hasR10FreezeFixtureBoundary(stagedChanges: [path]), isFalse, reason: 'Staged ' + path);
      if (!_cui2a1DirtyPaths.contains(path)) {
        expect(hasR10FreezeFixtureBoundary(unstagedChanges: [path]), isFalse, reason: 'Unstaged ' + path);
        expect(hasR10FreezeFixtureBoundary(repositoryChanges: [..._cui2a1DirtyPaths, path]), isFalse);
      }
      expect(hasR10FreezeFixtureBoundary(untrackedPaths: [..._cui2a1UntrackedPaths, path]), isFalse);
    }
    for (final path in cui2a1CompatibilityPaths) {
      for (final status in ['A', 'D', 'T', 'R100', 'C100']) {
        final delta = status + '\t' + path + '\n';
        expect(hasR10FreezeFixtureBoundary(committedStatus: delta), isFalse);
        expect(hasR10FreezeFixtureBoundary(stagedStatus: delta), isFalse);
        expect(hasR10FreezeFixtureBoundary(unstagedStatus: delta), isFalse);
      }
    }
    expect(hasR10FreezeFixtureBoundary(repositoryChanges: []), isFalse);
    expect(hasR10FreezeFixtureBoundary(untrackedPaths: []), isFalse);
    expect(hasR10FreezeFixtureBoundary(libDocsChanges: [cui2a0RoadmapPath, cui2a0ClosureReportPath,
      cui2a1ContractPath, ownerPlanningReadinessPath]), isFalse);
  });
  test('R10 freeze preserves every protected byte and retained SQL gate', () {
    for (final entry in _cui2a1ProtectedBlobs.entries) {
      expect(hasR10FreezeFixtureBoundary(preservedBlobs: {..._cui2a1ProtectedBlobs,
        entry.key: '0000000000000000000000000000000000000000'}), isFalse);
      expect(hasR10FreezeFixtureBoundary(preservedBlobs: Map.from(_cui2a1ProtectedBlobs)..remove(entry.key)), isFalse);
    }
    final names = Directory('supabase/migrations').listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toList();
    expect(hasR10FreezeFixtureBoundary(migrationNames: [...names, '00027_unauthorized.sql']), isFalse);
    expect(hasR10FreezeFixtureBoundary(predecessorChanges: ['supabase/migrations/00001_initial_schema.sql']), isFalse);
    expect(hasR10FreezeFixtureBoundary(backendChanges: ['supabase/config.toml']), isFalse);
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
      untrackedPaths: _cui2a1UntrackedPaths,
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
  untrackedPaths: untrackedPaths ?? _cui2a1UntrackedPaths, preservedBlobs: preservedBlobs,
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
  _registerR10PresentationBoundaryTests();
  _registerR10FixtureMaintenanceTests();
  _registerR10DecisionRecordTests();

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
    expect(hasR10PresentationCompatibility(),isTrue);
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
    expect(hasR10FreezeFixtureBoundary(), isTrue);
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
    expect(hasR10FreezeFixtureBoundary(implementationCommit: wrong), isFalse);
    expect(hasR10FreezeFixtureBoundary(closureCommit: wrong), isFalse);
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
      expect(hasR10FreezeFixtureBoundary(untrackedAuthorityPaths: [path]), isFalse, reason: path);
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
    expect(hasR10FreezeFixtureBoundary(migrationNames: [...migrations, '00027_unauthorized.sql']), isFalse);
    for (final name in migrations.where((name) => name != cui2a0MigrationName)) {
      expect(hasR10FreezeFixtureBoundary(predecessorChanges: ['supabase/migrations/$name']), isFalse, reason: name);
    }
    expect(hasR10FreezeFixtureBoundary(backendChanges: ['supabase/tests/arbitrary.sql']), isFalse);
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

