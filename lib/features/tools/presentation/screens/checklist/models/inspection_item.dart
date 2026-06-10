import 'inspection_status.dart';

class InspectionItem {
  final String id;
  final String categoryId;
  final String titleKey;
  final String? descriptionKey;
  final bool isRequired;
  final bool isCritical;
  final String? codeRef;

  InspectionStatus status;
  String? notes;

  InspectionItem({
    required this.id,
    required this.categoryId,
    required this.titleKey,
    this.descriptionKey,
    this.isRequired = false,
    this.isCritical = false,
    this.codeRef,
    this.status = InspectionStatus.pending,
    this.notes,
  });
}
