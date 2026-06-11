import 'dart:convert';

import '../../domain/checklist/checklist_repository.dart';
import '../../presentation/screens/checklist/models/inspection_status.dart';
import 'checklist_item_state.dart';
import 'checklist_local_data_source.dart';

class LocalChecklistRepository implements ChecklistRepository {
  final ChecklistLocalDataSource _dataSource;
  Map<String, ChecklistItemState>? _cache;

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

  Map<String, ChecklistItemData> _fromCache() {
    return (_cache ?? {}).map((k, v) => MapEntry(
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

  Future<void> _flush() async {
    final json = _serialize(_cache ?? {});
    await _dataSource.writeChecklistData(json);
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
