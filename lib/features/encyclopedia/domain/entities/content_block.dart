import 'code_reference.dart';

// ───────────── Enums ─────────────

enum TextVariant { paragraph, note, tip, warning }

enum SafetySeverity { none, low, medium, high, critical }

// ───────────── Shared sub-entities ─────────────

class ChecklistItem {
  final String id;
  final String text;
  final bool isRequired;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.isRequired = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isRequired': isRequired,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        id: json['id'] as String,
        text: json['text'] as String,
        isRequired: json['isRequired'] as bool? ?? true,
      );
}

class TableRowData {
  final List<String> cells;

  const TableRowData({required this.cells});

  Map<String, dynamic> toJson() => {'cells': cells};

  factory TableRowData.fromJson(Map<String, dynamic> json) =>
      TableRowData(cells: (json['cells'] as List<dynamic>).cast<String>());
}

class TableData {
  final String? caption;
  final List<String> headers;
  final List<TableRowData> rows;

  const TableData({this.caption, required this.headers, required this.rows});

  Map<String, dynamic> toJson() => {
        'caption': caption,
        'headers': headers,
        'rows': rows.map((r) => r.toJson()).toList(),
      };

  factory TableData.fromJson(Map<String, dynamic> json) => TableData(
        caption: json['caption'] as String?,
        headers: (json['headers'] as List<dynamic>).cast<String>(),
        rows: (json['rows'] as List<dynamic>)
            .map((r) => TableRowData.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}

class EquipmentItem {
  final String name;
  final String? purpose;
  final String? specification;

  const EquipmentItem({required this.name, this.purpose, this.specification});

  Map<String, dynamic> toJson() => {
        'name': name,
        'purpose': purpose,
        'specification': specification,
      };

  factory EquipmentItem.fromJson(Map<String, dynamic> json) => EquipmentItem(
        name: json['name'] as String,
        purpose: json['purpose'] as String?,
        specification: json['specification'] as String?,
      );
}

class InspectionPoint {
  final String criteria;
  final String? acceptableTolerance;
  final String? method;
  final bool isCritical;
  final String? markerStyle;
  final String? markerColorMode;

  const InspectionPoint({
    required this.criteria,
    this.acceptableTolerance,
    this.method,
    this.isCritical = false,
    this.markerStyle,
    this.markerColorMode,
  });

  Map<String, dynamic> toJson() => {
        'criteria': criteria,
        'acceptableTolerance': acceptableTolerance,
        'method': method,
        'isCritical': isCritical,
        'markerStyle': markerStyle,
        'markerColorMode': markerColorMode,
      };

  factory InspectionPoint.fromJson(Map<String, dynamic> json) =>
      InspectionPoint(
        criteria: json['criteria'] as String,
        acceptableTolerance: json['acceptableTolerance'] as String?,
        method: json['method'] as String?,
        isCritical: json['isCritical'] as bool? ?? false,
        markerStyle: json['markerStyle'] as String?,
        markerColorMode: json['markerColorMode'] as String?,
      );

  String get effectiveMarkerStyle => markerStyle ?? (isCritical ? 'critical' : 'inspection');
  String get effectiveMarkerColorMode => markerColorMode ?? 'theme';
}

class ExecutionStep {
  final int stepNumber;
  final String description;
  final String? imageUrl;
  final String? notes;

  const ExecutionStep({
    required this.stepNumber,
    required this.description,
    this.imageUrl,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'stepNumber': stepNumber,
        'description': description,
        'imageUrl': imageUrl,
        'notes': notes,
      };

  factory ExecutionStep.fromJson(Map<String, dynamic> json) => ExecutionStep(
        stepNumber: json['stepNumber'] as int,
        description: json['description'] as String,
        imageUrl: json['imageUrl'] as String?,
        notes: json['notes'] as String?,
      );
}

class SafetyNote {
  final String message;
  final SafetySeverity severity;

  const SafetyNote({
    required this.message,
    this.severity = SafetySeverity.medium,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'severity': severity.name,
      };

  factory SafetyNote.fromJson(Map<String, dynamic> json) => SafetyNote(
        message: json['message'] as String,
        severity: SafetySeverity.values.byName(json['severity'] as String),
      );
}

// ───────────── Content Block Hierarchy ─────────────

sealed class ContentBlock {
  const ContentBlock();
  Map<String, dynamic> toJson();
  String get type;
}

class TextBlock extends ContentBlock {
  final String content;
  final TextVariant variant;

  const TextBlock({required this.content, this.variant = TextVariant.paragraph});

  @override
  String get type => 'text';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'content': content,
        'variant': variant.name,
      };

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    TextVariant parsed;
    final raw = json['variant'] as String?;
    if (raw == null || raw.isEmpty) {
      parsed = TextVariant.paragraph;
    } else {
      try {
        parsed = TextVariant.values.byName(raw);
      } catch (_) {
        parsed = TextVariant.note;
      }
    }
    return TextBlock(content: json['content'] as String, variant: parsed);
  }
}

class ChecklistBlock extends ContentBlock {
  final String? title;
  final List<ChecklistItem> items;

  const ChecklistBlock({this.title, required this.items});

  @override
  String get type => 'checklist';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory ChecklistBlock.fromJson(Map<String, dynamic> json) => ChecklistBlock(
        title: json['title'] as String?,
        items: (json['items'] as List<dynamic>)
            .map((i) => ChecklistItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class TableBlock extends ContentBlock {
  final TableData data;

  const TableBlock({required this.data});

  @override
  String get type => 'table';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'data': data.toJson(),
      };

  factory TableBlock.fromJson(Map<String, dynamic> json) =>
      TableBlock(data: TableData.fromJson(json['data'] as Map<String, dynamic>));
}

class CodeReferenceBlock extends ContentBlock {
  final CodeReference reference;

  const CodeReferenceBlock({required this.reference});

  @override
  String get type => 'code_reference';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'reference': reference.toJson(),
      };

  factory CodeReferenceBlock.fromJson(Map<String, dynamic> json) =>
      CodeReferenceBlock(
        reference:
            CodeReference.fromJson(json['reference'] as Map<String, dynamic>),
      );
}

class EquipmentBlock extends ContentBlock {
  final String? title;
  final List<EquipmentItem> items;

  const EquipmentBlock({this.title, required this.items});

  @override
  String get type => 'equipment';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory EquipmentBlock.fromJson(Map<String, dynamic> json) => EquipmentBlock(
        title: json['title'] as String?,
        items: (json['items'] as List<dynamic>)
            .map((i) => EquipmentItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class ImageBlock extends ContentBlock {
  final String imageUrl;
  final String? caption;

  const ImageBlock({required this.imageUrl, this.caption});

  @override
  String get type => 'image';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'imageUrl': imageUrl,
        'caption': caption,
      };

  factory ImageBlock.fromJson(Map<String, dynamic> json) => ImageBlock(
        imageUrl: json['imageUrl'] as String,
        caption: json['caption'] as String?,
      );
}

class SafetyNoteBlock extends ContentBlock {
  final SafetyNote note;

  const SafetyNoteBlock({required this.note});

  @override
  String get type => 'safety_note';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'note': note.toJson(),
      };

  factory SafetyNoteBlock.fromJson(Map<String, dynamic> json) =>
      SafetyNoteBlock(
        note: SafetyNote.fromJson(json['note'] as Map<String, dynamic>),
      );
}

class InspectionPointBlock extends ContentBlock {
  final InspectionPoint point;

  const InspectionPointBlock({required this.point});

  @override
  String get type => 'inspection_point';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'point': point.toJson(),
      };

  factory InspectionPointBlock.fromJson(Map<String, dynamic> json) =>
      InspectionPointBlock(
        point:
            InspectionPoint.fromJson(json['point'] as Map<String, dynamic>),
      );
}

class CalloutItem {
  final String text;

  const CalloutItem({required this.text});

  Map<String, dynamic> toJson() => {'text': text};

  factory CalloutItem.fromJson(Map<String, dynamic> json) =>
      CalloutItem(text: json['text'] as String);
}

class CommonMistakesBlock extends ContentBlock {
  final String? title;
  final List<CalloutItem> items;

  const CommonMistakesBlock({this.title, required this.items});

  @override
  String get type => 'common_mistakes';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory CommonMistakesBlock.fromJson(Map<String, dynamic> json) =>
      CommonMistakesBlock(
        title: json['title'] as String?,
        items: (json['items'] as List<dynamic>)
            .map((i) => CalloutItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class AcceptanceCriteriaBlock extends ContentBlock {
  final String? title;
  final List<CalloutItem> items;

  const AcceptanceCriteriaBlock({this.title, required this.items});

  @override
  String get type => 'acceptance_criteria';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory AcceptanceCriteriaBlock.fromJson(Map<String, dynamic> json) =>
      AcceptanceCriteriaBlock(
        title: json['title'] as String?,
        items: (json['items'] as List<dynamic>)
            .map((i) => CalloutItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class RejectionCriteriaBlock extends ContentBlock {
  final String? title;
  final List<CalloutItem> items;

  const RejectionCriteriaBlock({this.title, required this.items});

  @override
  String get type => 'rejection_criteria';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory RejectionCriteriaBlock.fromJson(Map<String, dynamic> json) =>
      RejectionCriteriaBlock(
        title: json['title'] as String?,
        items: (json['items'] as List<dynamic>)
            .map((i) => CalloutItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class ExecutionStepBlock extends ContentBlock {
  final ExecutionStep step;

  const ExecutionStepBlock({required this.step});

  @override
  String get type => 'execution_step';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'step': step.toJson(),
      };

  factory ExecutionStepBlock.fromJson(Map<String, dynamic> json) =>
      ExecutionStepBlock(
        step: ExecutionStep.fromJson(json['step'] as Map<String, dynamic>),
      );
}

// ───────────── Deserialization helper ─────────────

ContentBlock contentBlockFromJson(Map<String, dynamic> json) {
  return switch (json['type'] as String) {
    'text' => TextBlock.fromJson(json),
    'checklist' => ChecklistBlock.fromJson(json),
    'table' => TableBlock.fromJson(json),
    'code_reference' => CodeReferenceBlock.fromJson(json),
    'equipment' => EquipmentBlock.fromJson(json),
    'image' => ImageBlock.fromJson(json),
    'safety_note' => SafetyNoteBlock.fromJson(json),
    'inspection_point' => InspectionPointBlock.fromJson(json),
    'execution_step' => ExecutionStepBlock.fromJson(json),
    'common_mistakes' => CommonMistakesBlock.fromJson(json),
    'acceptance_criteria' => AcceptanceCriteriaBlock.fromJson(json),
    'rejection_criteria' => RejectionCriteriaBlock.fromJson(json),
    _ => throw ArgumentError('Unknown content block type: ${json['type']}'),
  };
}
