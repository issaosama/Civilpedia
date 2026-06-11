import 'dart:convert';

import '../../domain/checklist/checklist_repository.dart';
import '../../presentation/screens/checklist/models/inspection_status.dart';
import 'checklist_item_state.dart';
import 'checklist_local_data_source.dart';

class LocalChecklistRepository implements ChecklistRepository {
  final ChecklistLocalDataSource _dataSource;
  Map<String, ChecklistItemState>? _cache;
  Map<String, Map<String, ChecklistItemState>>? _projectCaches;

  LocalChecklistRepository(this._dataSource);

  @override
  Future<Map<String, ChecklistItemData>> loadItemStates() async {
    if (_cache != null) return _fromCache();
    final json = await _dataSource.readChecklistData();
    if (json == null) return {};
    _cache = _deserialize(json);
    return _fromCache();
  }

  @override
  Future<void> saveItemStatus(String itemId, InspectionStatus status) async {
    await _ensureCache();
    _cache![itemId] = ChecklistItemState(
      status: status.name,
      notes: _cache![itemId]?.notes,
    );
    await _flush();
  }

  @override
  Future<void> saveItemNotes(String itemId, String? notes) async {
    await _ensureCache();
    final existingStatus = _cache![itemId]?.status ?? 'pending';
    _cache![itemId] = ChecklistItemState(
      status: existingStatus,
      notes: notes,
    );
    await _flush();
  }

  @override
  Future<void> clearAll() async {
    _cache = {};
    await _dataSource.clearChecklistData();
  }

  @override
  Future<Map<String, ChecklistItemData>> loadProjectItemStates(
      String projectId) async {
    if (_projectCaches != null && _projectCaches!.containsKey(projectId)) {
      return _convertCache(_projectCaches![projectId]!);
    }
    final json = await _dataSource.readProjectChecklistData(projectId);
    final cache = json != null ? _deserialize(json) : <String, ChecklistItemState>{};
    _projectCaches ??= <String, Map<String, ChecklistItemState>>{};
    _projectCaches![projectId] = cache;
    return _convertCache(cache);
  }

  @override
  Future<void> saveProjectItemStatus(
      String projectId, String itemId, InspectionStatus status) async {
    await _ensureProjectCache(projectId);
    _projectCaches![projectId]![itemId] = ChecklistItemState(
      status: status.name,
      notes: _projectCaches![projectId]![itemId]?.notes,
    );
    await _flushProject(projectId);
  }

  @override
  Future<void> saveProjectItemNotes(
      String projectId, String itemId, String? notes) async {
    await _ensureProjectCache(projectId);
    final existingStatus =
        _projectCaches![projectId]![itemId]?.status ?? 'pending';
    _projectCaches![projectId]![itemId] = ChecklistItemState(
      status: existingStatus,
      notes: notes,
    );
    await _flushProject(projectId);
  }

  @override
  Future<void> clearProject(String projectId) async {
    _projectCaches?.remove(projectId);
    await _dataSource.clearProjectChecklistData(projectId);
  }

  Map<String, ChecklistItemData> _fromCache() {
    return _convertCache(_cache ?? {});
  }

  Map<String, ChecklistItemData> _convertCache(
      Map<String, ChecklistItemState> cache) {
    return cache.map((k, v) => MapEntry(
          k,
          ChecklistItemData(
            status: InspectionStatus.values.firstWhere(
              (s) => s.name == v.status,
              orElse: () => InspectionStatus.pending,
            ),
            notes: v.notes,
          ),
        ));
  }

  Future<void> _ensureCache() async {
    if (_cache != null) return;
    final json = await _dataSource.readChecklistData();
    _cache = json != null ? _deserialize(json) : {};
  }

  Future<void> _ensureProjectCache(String projectId) async {
    if (_projectCaches != null && _projectCaches!.containsKey(projectId)) return;
    final json = await _dataSource.readProjectChecklistData(projectId);
    final cache = json != null ? _deserialize(json) : <String, ChecklistItemState>{};
    _projectCaches ??= <String, Map<String, ChecklistItemState>>{};
    _projectCaches![projectId] = cache;
  }

  Future<void> _flush() async {
    final json = _serialize(_cache ?? {});
    await _dataSource.writeChecklistData(json);
  }

  Future<void> _flushProject(String projectId) async {
    final cache = _projectCaches?[projectId];
    if (cache == null) return;
    final json = _serialize(cache);
    await _dataSource.writeProjectChecklistData(projectId, json);
  }

  Map<String, ChecklistItemState> _deserialize(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(
          k,
          ChecklistItemState.fromJson(v as Map<String, dynamic>),
        ));
  }

  String _serialize(Map<String, ChecklistItemState> data) {
    return jsonEncode(data.map((k, v) => MapEntry(k, v.toJson())));
  }
}
