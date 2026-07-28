import 'package:flutter/material.dart';
import '../../domain/entities/content_block.dart';
import 'text_block_widget.dart';
import 'execution_step_widget.dart';
import 'inspection_point_widget.dart';
import 'safety_note_widget.dart';
import 'code_reference_widget.dart';
import 'checklist_widget.dart';
import 'table_block_widget.dart';
import 'equipment_widget.dart';
import 'image_block_widget.dart';
import 'common_mistakes_block_widget.dart';
import 'acceptance_criteria_block_widget.dart';
import 'rejection_criteria_block_widget.dart';

class ContentBlockWidget extends StatelessWidget {
  final ContentBlock block;

  const ContentBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      TextBlock b => TextBlockWidget(block: b),
      ExecutionStepBlock b => ExecutionStepWidget(block: b),
      InspectionPointBlock b => InspectionPointWidget(block: b),
      SafetyNoteBlock b => SafetyNoteWidget(block: b),
      CodeReferenceBlock b => CodeReferenceWidget(block: b),
      ChecklistBlock b => ChecklistWidget(block: b),
      TableBlock b => TableBlockWidget(block: b),
      EquipmentBlock b => EquipmentWidget(block: b),
      ImageBlock b => ImageBlockWidget(block: b),
      CommonMistakesBlock b => CommonMistakesBlockWidget(block: b),
      AcceptanceCriteriaBlock b => AcceptanceCriteriaBlockWidget(block: b),
      RejectionCriteriaBlock b => RejectionCriteriaBlockWidget(block: b),
    };
  }
}
