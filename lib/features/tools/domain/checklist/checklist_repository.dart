import '../../presentation/screens/checklist/models/inspection_status.dart';

class ChecklistItemData {
  final InspectionStatus status;
  final String? notes;

  const ChecklistItemData({
    required this.status,
    this.notes,
  });
}

abstract class ChecklistRepository {
  Future<Map<String, ChecklistItemData>> loadItemStates();

  Future<void> saveItemStatus(String itemId, InspectionStatus status);

  Future<void> saveItemNotes(String itemId, String? notes);

  Future<void> clearAll();
}
