const supportedBlockTypes = <String>{
  'text',
  'checklist',
  'table',
  'code_reference',
  'equipment',
  'image',
  'safety_note',
  'inspection_point',
  'execution_step',
};

const supportedSectionTypes = <String>{
  'execution',
  'inspection',
  'safety',
  'equipment',
  'codeReference',
  'general',
};

const supportedLevels = <String>{
  'basic',
  'intermediate',
  'advanced',
};

const supportedStatuses = <String>{
  'Draft',
  'Engineering Review',
  'Approved',
  'Ready for App',
};

const supportedTextVariants = <String>{
  'paragraph',
  'note',
  'tip',
  'warning',
};

const supportedSafetySeverities = <String>{
  'low',
  'medium',
  'high',
  'critical',
};

const supportedPlanKeys = <String>{
  'free',
  'pro',
  'company',
  'supplier',
};

const allowedToolRoutes = <String>{
  '/calculator/concrete',
  '/calculator/steel',
  '/calculator/brick',
  '/calculator/tile',
};

const allowedCategories = <String>{
  'concrete',
  'steel',
  'soil',
  'asphalt',
  'general',
  'finishing',
};

const validTrueFalse = <String>{'TRUE', 'FALSE'};

Map<String, List<String>> blockRequiredFields = {
  'text': ['text_content', 'text_variant'],
  'execution_step': ['step_number', 'step_description'],
  'inspection_point': ['point_criteria', 'point_critical'],
  'safety_note': ['safety_message', 'safety_severity'],
  'code_reference': ['code_code', 'code_title'],
  'checklist': [],
  'table': [],
  'equipment': [],
  'image': ['image_url'],
};
