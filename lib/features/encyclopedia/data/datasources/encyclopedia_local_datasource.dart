import '../../domain/entities/code_reference.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/engineering_topic.dart';
import '../../domain/entities/topic_section.dart';

class EncyclopediaLocalDataSource {
  Future<List<EngineeringTopic>> fetchAllTopics() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockTopics;
  }

  Future<List<EngineeringTopic>> fetchTopicsByCategory(
      String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _mockTopics.where((t) => t.categoryId == categoryId).toList();
  }

  Future<EngineeringTopic?> fetchTopicById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _mockTopics.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<EngineeringTopic>> searchTopics(String query) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final q = query.toLowerCase();
    return _mockTopics
        .where((t) =>
            t.titleAr.contains(q) ||
            t.titleEn?.toLowerCase().contains(q) == true ||
            t.tags.any((tag) => tag.contains(q)) ||
            t.summary.contains(q))
        .toList();
  }

  Future<List<TopicSection>> fetchSectionsForTopic(String topicId) async {
    await Future.delayed(const Duration(milliseconds: 30));
    final sections = _topicSectionMap[topicId] ?? [];
    return sections;
  }

  Future<List<ContentBlock>> fetchBlocksForSection(String sectionId) async {
    await Future.delayed(const Duration(milliseconds: 30));
    final blocks = _mockBlocks[sectionId] ?? [];
    return blocks;
  }
}

// ───────────── Mock Data ─────────────

final List<EngineeringTopic> _mockTopics = [
  // ── 1. Concrete Pouring ──
  EngineeringTopic(
    id: 'concrete-pouring',
    titleAr: 'صب الخرسانة',
    titleEn: 'Concrete Pouring and Placement',
    categoryId: 'concrete',
    summary:
        'إجراءات صب الخرسانة الطازجة في العناصر الخرسانية المسلحة وفقاً لمتطلبات ACI 304R',
    featuredImageUrl: null,
    tags: ['خرسانة', 'صب', 'دمك', 'معالجة', 'ACI 304'],
    relatedTopicIds: ['rebar-inspection', 'conc-columns'],
    createdAt: DateTime(2025, 1, 10),
    updatedAt: DateTime(2025, 4, 15),
  ),
  // ── 2. Reinforcement Inspection ──
  EngineeringTopic(
    id: 'rebar-inspection',
    titleAr: 'استلام حديد التسليح',
    titleEn: 'Reinforcement Steel Inspection',
    categoryId: 'concrete',
    summary:
        'إجراءات فحص واستلام حديد التسليح قبل الصب وفقاً لمتطلبات ACI 318-19',
    featuredImageUrl: null,
    tags: ['حديد تسليح', 'استلام', 'تغطية', 'ACI 318', 'كانات'],
    relatedTopicIds: ['concrete-pouring', 'aci-tolerances'],
    createdAt: DateTime(2025, 1, 12),
    updatedAt: DateTime(2025, 4, 10),
  ),
  // ── 3. ACI 318 Tolerances ──
  EngineeringTopic(
    id: 'aci-tolerances',
    titleAr: 'السماحيات حسب ACI 318',
    titleEn: 'Construction Tolerances per ACI 318',
    categoryId: 'concrete',
    summary:
        'جدول السماحيات المسموح بها في تنفيذ العناصر الخرسانية وفقاً لكود ACI 117 و ACI 318',
    featuredImageUrl: null,
    tags: ['سماحيات', 'تفاوتات', 'ACI 318', 'ACI 117', 'جودة'],
    relatedTopicIds: ['rebar-inspection', 'concrete-pouring', 'conc-columns'],
    createdAt: DateTime(2025, 2, 1),
    updatedAt: DateTime(2025, 4, 20),
  ),
  // ── 4. Concrete Column Execution (enhanced) ──
  EngineeringTopic(
    id: 'conc-columns',
    titleAr: 'تنفيذ الأعمدة الخرسانية',
    titleEn: 'Concrete Column Execution',
    categoryId: 'concrete',
    summary:
        'إجراءات تنفيذ الأعمدة الخرسانية المسلحة من النجارة والتسليح إلى الصب والمعالجة',
    featuredImageUrl: null,
    tags: ['أعمدة', 'خرسانة', 'تنفيذ', 'فرم', 'دمك'],
    relatedTopicIds: ['conc-beams', 'concrete-pouring', 'rebar-inspection'],
    createdAt: DateTime(2025, 1, 15),
    updatedAt: DateTime(2025, 3, 1),
  ),
  // ── 5. Concrete Beam Execution ──
  EngineeringTopic(
    id: 'conc-beams',
    titleAr: 'تنفيذ الكمرات الخرسانية',
    titleEn: 'Concrete Beam Execution',
    categoryId: 'concrete',
    summary: 'إجراءات تنفيذ الكمرات الخرسانية المسلحة والتسليح والشدات',
    featuredImageUrl: null,
    tags: ['كمرات', 'خرسانة', 'تنفيذ', 'شدات', 'حديد تسليح'],
    relatedTopicIds: ['conc-columns', 'concrete-pouring'],
    createdAt: DateTime(2025, 1, 20),
    updatedAt: DateTime(2025, 3, 5),
  ),
  // ── 6. Soil Testing ──
  EngineeringTopic(
    id: 'soil-testing',
    titleAr: 'اختبارات التربة',
    titleEn: 'Soil Testing Methods',
    categoryId: 'soil',
    summary: 'أنواع اختبارات التربة الموقعية والمخبرية وتفسير النتائج للأساسات',
    featuredImageUrl: null,
    tags: ['تربة', 'اختبارات', 'أساسات', 'SPT', 'جيوتقني'],
    relatedTopicIds: [],
    createdAt: DateTime(2025, 2, 1),
    updatedAt: DateTime(2025, 2, 15),
  ),
  // ── 7. Asphalt Testing ──
  EngineeringTopic(
    id: 'asphalt-testing',
    titleAr: 'اختبارات الأسفلت',
    titleEn: 'Asphalt Testing',
    categoryId: 'asphalt',
    summary: 'إجراءات اختبارات الأسفلت للطرق وضبط الجودة حسب المواصفات',
    featuredImageUrl: null,
    tags: ['أسفلت', 'اختبارات', 'طرق', 'مارشال', 'جودة'],
    relatedTopicIds: [],
    createdAt: DateTime(2025, 2, 10),
    updatedAt: DateTime(2025, 3, 1),
  ),
];

final List<TopicSection> _mockSections = [
  // ── Concrete Pouring sections ──
  TopicSection(id: 'pour-exec', title: 'مراحل الصب', type: SectionType.execution, order: 1),
  TopicSection(id: 'pour-insp', title: 'التحكم بالجودة', type: SectionType.inspection, order: 2),
  TopicSection(id: 'pour-safety', title: 'السلامة', type: SectionType.safety, order: 3),
  TopicSection(id: 'pour-equip', title: 'المعدات', type: SectionType.equipment, order: 4),
  TopicSection(id: 'pour-codes', title: 'مراجع الكودات', type: SectionType.codeReference, order: 5),
  // ── Rebar Inspection sections ──
  TopicSection(id: 'rebar-exec', title: 'خطوات الاستلام', type: SectionType.execution, order: 1),
  TopicSection(id: 'rebar-insp', title: 'نقاط الفحص', type: SectionType.inspection, order: 2),
  TopicSection(id: 'rebar-tables', title: 'جداول التسليح', type: SectionType.general, order: 3),
  TopicSection(id: 'rebar-codes', title: 'المراجع', type: SectionType.codeReference, order: 4),
  // ── ACI Tolerances sections ──
  TopicSection(id: 'tol-general', title: 'مقدمة عامة', type: SectionType.general, order: 1),
  TopicSection(id: 'tol-tables', title: 'جداول السماحيات', type: SectionType.general, order: 2),
  TopicSection(id: 'tol-insp', title: 'التحقق من السماحيات', type: SectionType.inspection, order: 3),
  TopicSection(id: 'tol-codes', title: 'مراجع الكودات', type: SectionType.codeReference, order: 4),
  // ── Column execution sections ──
  TopicSection(id: 'col-exec', title: 'خطوات التنفيذ', type: SectionType.execution, order: 1),
  TopicSection(id: 'col-insp', title: 'الفحص والتفتيش', type: SectionType.inspection, order: 2),
  TopicSection(id: 'col-safety', title: 'إجراءات السلامة', type: SectionType.safety, order: 3),
  TopicSection(id: 'col-equip', title: 'المعدات المطلوبة', type: SectionType.equipment, order: 4),
  TopicSection(id: 'col-codes', title: 'المراجع والكودات', type: SectionType.codeReference, order: 5),
  // ── Beam execution sections ──
  TopicSection(id: 'beam-exec', title: 'خطوات التنفيذ', type: SectionType.execution, order: 1),
  TopicSection(id: 'beam-codes', title: 'المراجع والكودات', type: SectionType.codeReference, order: 2),
  // ── Soil testing sections ──
  TopicSection(id: 'soil-gen', title: 'أنواع الاختبارات', type: SectionType.general, order: 1),
  TopicSection(id: 'soil-equip', title: 'الأجهزة والمعدات', type: SectionType.equipment, order: 2),
  // ── Asphalt sections ──
  TopicSection(id: 'asp-exec', title: 'إجراءات الاختبار', type: SectionType.execution, order: 1),
  TopicSection(id: 'asp-codes', title: 'المواصفات القياسية', type: SectionType.codeReference, order: 2),
];

final Map<String, List<TopicSection>> _topicSectionMap = {
  'concrete-pouring': _mockSections.where((s) =>
      ['pour-exec', 'pour-insp', 'pour-safety', 'pour-equip', 'pour-codes']
          .contains(s.id)).toList(),
  'rebar-inspection': _mockSections.where((s) =>
      ['rebar-exec', 'rebar-insp', 'rebar-tables', 'rebar-codes']
          .contains(s.id)).toList(),
  'aci-tolerances': _mockSections.where((s) =>
      ['tol-general', 'tol-tables', 'tol-insp', 'tol-codes']
          .contains(s.id)).toList(),
  'conc-columns': _mockSections.where((s) =>
      ['col-exec', 'col-insp', 'col-safety', 'col-equip', 'col-codes']
          .contains(s.id)).toList(),
  'conc-beams': _mockSections.where((s) =>
      ['beam-exec', 'beam-codes'].contains(s.id)).toList(),
  'soil-testing': _mockSections.where((s) =>
      ['soil-gen', 'soil-equip'].contains(s.id)).toList(),
  'asphalt-testing': _mockSections.where((s) =>
      ['asp-exec', 'asp-codes'].contains(s.id)).toList(),
};

final Map<String, List<ContentBlock>> _mockBlocks = {
  // ═══════════════════════════════════════════
  //  1. CONCRETE POURING (صب الخرسانة)
  // ═══════════════════════════════════════════

  'pour-exec': [
    TextBlock(
      content:
          'عملية صب الخرسانة هي من أهم مراحل البناء وتتطلب تنسيقاً دقيقاً بين فريق الصب ومحطة الخلط لتجنب حدوث فواصل باردة (Cold Joints).',
      variant: TextVariant.paragraph,
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 1,
        description: 'التحقق من جاهزية الفرم والشدات ونظافتها من المخلفات',
        notes: 'يفضل غسل الفرم بالماء قبل الصب مباشرة',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 2,
        description:
            'ترطيب الفرم الخشبية بالماء لتقليل امتصاص الخرسانة للماء',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 3,
        description:
            'صب الخرسانة على دفعات منتظمة بارتفاع لا يتجاوز 1.5 متر لتجنب انفصال الحبيبات',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 4,
        description:
            'دمك الخرسانة بالهزاز الميكانيكي الغاطس (Immersion Vibrator)',
        notes:
            'سرعة الهزاز 8000-12000 دورة/دقيقة. مدة الدمك من 5-15 ثانية. المسافة بين نقاط الدمك لا تزيد عن 50 سم',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 5,
        description: 'تسوية السطح العلوي للخرسانة بالفرمجة (Screeding)',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 6,
        description: 'بدء عملية المعالجة (Curing) فور انتهاء الصب',
        notes:
            'المعالجة بالرش بالماء لمدة 7 أيام على الأقل للأسمنت البورتلاندي العادي',
      ),
    ),
    SafetyNoteBlock(
      note: const SafetyNote(
        message:
            'خطر انهيار الفرم: يجب التأكد من سلامة الشدات والدعامات قبل الصب. يراقب الفريق أي حركة أو تشوه أثناء الصب',
        severity: SafetySeverity.critical,
      ),
    ),
  ],

  'pour-insp': [
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'فحص هبوط الخرسانة (Slump Test) قبل الصب',
        acceptableTolerance: 'Slump = 75-100 مم للعناصر العادية',
        method: 'اختبار الهبوط المخروطي ASTM C143',
        isCritical: true,
      ),
    ),
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'درجة حرارة الخرسانة عند الصب',
        acceptableTolerance: '10°C - 32°C (حسب ACI 305R)',
        method: 'مقياس حرارة',
        isCritical: true,
      ),
    ),
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'عدد المكعبات الخرسانية للاختبار',
        acceptableTolerance: '6 مكعبات لكل 100 م³ صب',
        method: 'أخذ عينات مكعبات 150×150×150 مم',
        isCritical: true,
      ),
    ),
    TableBlock(
      data: TableData(
        caption: 'تصنيف الخرسانة حسب المقاومة (C20 - C50)',
        headers: ['التصنيف', 'المقاومة (MPa)', 'Slump (مم)', 'نسبة الماء/أسمنت'],
        rows: [
          const TableRowData(cells: ['C20', '20', '75-100', '0.55']),
          const TableRowData(cells: ['C25', '25', '75-100', '0.50']),
          const TableRowData(cells: ['C30', '30', '75-100', '0.45']),
          const TableRowData(cells: ['C35', '35', '75-100', '0.42']),
          const TableRowData(cells: ['C40', '40', '50-75', '0.38']),
          const TableRowData(cells: ['C50', '50', '50-75', '0.35']),
        ],
      ),
    ),
    ChecklistBlock(
      title: 'قائمة فحص ما قبل الصب',
      items: [
        const ChecklistItem(id: 'pp1', text: 'فحص نتائج اختبار الهبوط', isRequired: true),
        const ChecklistItem(id: 'pp2', text: 'التأكد من وجود المكعبات كافية', isRequired: true),
        const ChecklistItem(id: 'pp3', text: 'فحص جاهزية الهزاز الميكانيكي', isRequired: true),
        const ChecklistItem(id: 'pp4', text: 'التأكد من نظافة الفرم', isRequired: true),
        const ChecklistItem(id: 'pp5', text: 'فحص تثبيت الكفرات البلاستيكية', isRequired: true),
        const ChecklistItem(id: 'pp6', text: 'فحص توفر مصدر ماء للمعالجة', isRequired: false),
        const ChecklistItem(id: 'pp7', text: 'فحص ربط حديد التسليح وثباته', isRequired: true),
      ],
    ),
  ],

  'pour-safety': [
    SafetyNoteBlock(
      note: const SafetyNote(
        message:
            'يجب تثبيت جميع السقالات والدعامات بشكل آمن قبل بدء الصب. وجود مهندس سلامة في الموقع أثناء الصب إلزامي',
        severity: SafetySeverity.critical,
      ),
    ),
    SafetyNoteBlock(
      note: const SafetyNote(
        message:
            'تأمين مسارات واضحة لخروج العاملين في حالات الطوارئ حول منطقة الصب',
        severity: SafetySeverity.high,
      ),
    ),
    SafetyNoteBlock(
      note: const SafetyNote(
        message:
            'فحص الكابلات الكهربائية للهزازات والتأكد من عدم ملامستها للماء',
        severity: SafetySeverity.high,
      ),
    ),
    ChecklistBlock(
      title: 'قائمة السلامة أثناء الصب',
      items: [
        const ChecklistItem(id: 'ps1', text: 'جميع العاملين يرتدون الخوذ وأحذية السلامة'),
        const ChecklistItem(id: 'ps2', text: 'وجود طفاية حريق صالحة في الموقع'),
        const ChecklistItem(id: 'ps3', text: 'تأمين منطقة الصب بشرائط تحذيرية'),
        const ChecklistItem(id: 'ps4', text: 'فحص مقاومة الرياح (لا يزيد عن 40 كم/ساعة)'),
        const ChecklistItem(id: 'ps5', text: 'توفير الإضاءة الكافية إذا كان الصب ليلي'),
      ],
    ),
  ],

  'pour-equip': [
    EquipmentBlock(
      title: 'معدات الصب والدمك',
      items: [
        const EquipmentItem(
          name: 'هزاز خرسانة غاطس',
          purpose: 'دمك الخرسانة وإزالة الفراغات',
          specification: 'قطر الرأس 25-60 مم، طول الخرطوم 2-6 م',
        ),
        const EquipmentItem(
          name: 'مضخة خرسانة',
          purpose: 'نقل الخرسانة للمواقع المرتفعة',
          specification: 'سعة 30-60 م³/ساعة',
        ),
        const EquipmentItem(
          name: 'فرمجة (Screed)',
          purpose: 'تسوية السطح العلوي للخرسانة',
        ),
        const EquipmentItem(
          name: 'قادوم (Trowel)',
          purpose: 'تنعيم السطح بعد الفرمجة',
        ),
        const EquipmentItem(
          name: 'مكعبات اختبار',
          purpose: 'أخذ عينات لاختبار مقاومة الضغط',
          specification: '150×150×150 مم',
        ),
        const EquipmentItem(
          name: 'خرطوم ماء للمعالجة',
          purpose: 'رش الخرسانة بالماء للمعالجة',
        ),
      ],
    ),
  ],

  'pour-codes': [
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ACI 304R-00',
        section: '4.2',
        title: 'Guide for Measuring, Mixing, Transporting, and Placing Concrete',
        description:
            'إرشادات صب الخرسانة: أقصى ارتفاع حر للصب 1.5 متر لتجنب انفصال الحبيبات',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ACI 305R-20',
        section: '2.3',
        title: 'Hot Weather Concreting',
        description:
            'عند درجات حرارة أعلى من 32°C يجب تبريد الخرسانة باستخدام ماء مثلج أو النيتروجين السائل',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ACI 308R-16',
        section: '4.1',
        title: 'Curing Concrete',
        description: 'المعالجة تبدأ فور انتهاء الصب. المدة الدنيا 7 أيام للأسمنت العادي',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ASTM C143',
        section: '',
        title: 'Standard Test Method for Slump of Hydraulic-Cement Concrete',
        description: 'قياس هبوط الخرسانة الطازجة باستخدام المخروط القياسي',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ASTM C39',
        section: '',
        title: 'Compressive Strength of Cylindrical Concrete Specimens',
        description: 'اختبار مقاومة الضغط للمكعبات الخرسانية',
      ),
    ),
  ],

  // ═══════════════════════════════════════════
  //  2. REINFORCEMENT INSPECTION (استلام الحديد)
  // ═══════════════════════════════════════════

  'rebar-exec': [
    TextBlock(
      content:
          'استلام حديد التسليح يتم على مراحل: فحص شهادات المواد، قياس الأقطار، فحص الثني والربط، والتأكد من التغطية والمسافات قبل صب الخرسانة.',
      variant: TextVariant.note,
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 1,
        description:
            'فحص شهادات المنشأ (Mill Certificates) والتأكد من مطابقتها للمواصفات',
        notes: 'يجب أن تكون الشهادات مختومة ومصدقة من المختبر',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 2,
        description:
            'قياس أقطار أسياخ الحديد ومقارنتها مع الشهادات باستخدام القدمة (Vernier Caliper)',
        notes: 'التسامح المسموح به في القطر ± 0.5 مم',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 3,
        description:
            'فحص أسياخ الثني (Stirrups/Ties) من حيث الأبعاد وزوايا الثني',
        notes: 'زاوية الثني 135° للكانات المغلقة (Seismic Hooks)',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 4,
        description:
            'التحقق من التغطية الخرسانية (Concrete Cover) باستخدام الكفرات البلاستيكية',
        notes: 'التغطية لا تقل عن 20 مم للأسقف و 40 مم للقواعد',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 5,
        description:
            'فحص المسافات بين الأسياخ (Spacing) ومقارنتها مع المخططات',
      ),
    ),
  ],

  'rebar-insp': [
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'أقطار حديد التسليح',
        acceptableTolerance: '± 0.5 مم عن القطر الاسمي',
        method: 'القدمة (Vernier Caliper)',
        isCritical: true,
      ),
    ),
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'المسافة بين الأسياخ الطولية',
        acceptableTolerance: '± 10 مم',
        method: 'شريط قياس',
        isCritical: true,
      ),
    ),
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'التغطية الخرسانية (Cover)',
        acceptableTolerance: 'لا تقل عن القيمة التصميمية',
        method: 'قياس الكفرات البلاستيكية',
        isCritical: true,
      ),
    ),
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'عدد الأسياخ في المقطع',
        acceptableTolerance: 'حسب المخططات (لا يقل عن المطلوب)',
        method: 'العد المباشر',
        isCritical: true,
      ),
    ),
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'زاوية ثني الكانات',
        acceptableTolerance: '135° ± 5°',
        method: 'منقلة (Protractor)',
        isCritical: false,
      ),
    ),
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'طول الوصلة (Lap Splice)',
        acceptableTolerance: 'لا يقل عن 60 قطر للسيخ',
        method: 'شريط قياس',
        isCritical: true,
      ),
    ),
    ImageBlock(
      imageUrl: 'assets/images/rebar_cover.png',
      caption: 'فحص التغطية الخرسانية باستخدام الكفرات البلاستيكية',
    ),
  ],

  'rebar-tables': [
    TableBlock(
      data: TableData(
        caption: 'أقطار وأوزان حديد التسليح الشائعة',
        headers: ['القطر (مم)', 'الوزن (كجم/م)', 'مساحة المقطع (مم²)', 'الطول الشائع (م)'],
        rows: [
          const TableRowData(cells: ['8', '0.395', '50.3', '12']),
          const TableRowData(cells: ['10', '0.617', '78.5', '12']),
          const TableRowData(cells: ['12', '0.888', '113.1', '12']),
          const TableRowData(cells: ['14', '1.21', '153.9', '12']),
          const TableRowData(cells: ['16', '1.58', '201.1', '12']),
          const TableRowData(cells: ['18', '2.00', '254.5', '12']),
          const TableRowData(cells: ['20', '2.47', '314.2', '12']),
          const TableRowData(cells: ['25', '3.85', '490.9', '12']),
          const TableRowData(cells: ['32', '6.31', '804.2', '12']),
        ],
      ),
    ),
    TableBlock(
      data: TableData(
        caption: 'أقل تغطية خرسانية حسب ACI 318-19 (الجدول 20.6.1)',
        headers: ['نوع العنصر', 'التغطية (مم)', 'شرط إضافي'],
        rows: [
          const TableRowData(cells: ['قواعد وأساسات', '75', 'إذا كانت الخرسانة تصب على التربة']),
          const TableRowData(cells: ['قواعد وأساسات', '50', 'إذا كانت الخرسانة تصب على غشاء عازل']),
          const TableRowData(cells: ['جدران وأسقف داخلية', '20', 'لا تتعرض للعوامل الجوية']),
          const TableRowData(cells: ['جدران وأسقف خارجية', '40', 'تتعرض للعوامل الجوية']),
          const TableRowData(cells: ['أعمدة', '40', 'حديد رئيسي']),
           const TableRowData(cells: ['أعمدة', '30', 'كانات (Ties)']),
          const TableRowData(cells: ['كمرات', '25', 'حديد رئيسي']),
        ],
      ),
    ),
    ChecklistBlock(
      title: 'قائمة فحص استلام حديد التسليح',
      items: [
        const ChecklistItem(id: 'rb1', text: 'فحص شهادات المنشأ والمواصفات', isRequired: true),
        const ChecklistItem(id: 'rb2', text: 'قياس أقطار الحديد بالقدمة', isRequired: true),
        const ChecklistItem(id: 'rb3', text: 'فحص عدد الأسياخ في المقطع', isRequired: true),
        const ChecklistItem(id: 'rb4', text: 'فحص المسافات بين الأسياخ', isRequired: true),
        const ChecklistItem(id: 'rb5', text: 'فحص التغطية والكفرات', isRequired: true),
        const ChecklistItem(id: 'rb6', text: 'فحص الوصلات والأطوال', isRequired: true),
        const ChecklistItem(id: 'rb7', text: 'فحص زوايا الثني للكانات', isRequired: true),
        const ChecklistItem(id: 'rb8', text: 'فحص تربيط الحديد وثباته', isRequired: true),
        const ChecklistItem(id: 'rb9', text: 'فحص الفواصل الخرسانية إن وجدت', isRequired: false),
      ],
    ),
  ],

  'rebar-codes': [
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ACI 318-19',
        section: '25.2.1',
        title: 'Minimum Bend Diameters',
        description:
            'أقل قطر للثني: 6 أقطار للسيخ لأسياخ رقم 3-8، و 8 أقطار لأسياخ رقم 9-11',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ACI 318-19',
        section: '25.3.1',
        title: 'Hooks for Stirrups and Ties',
        description: 'الكانات المغلقة تتطلب ثني 135° مع امتداد طرف لا يقل عن 6 أقطار',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ACI 318-19',
        section: '20.6.1',
        title: 'Concrete Cover Requirements',
        description: 'جدول متطلبات التغطية الدنيا للخرسانة حسب نوع العنصر',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ACI 318-19',
        section: '25.5.2',
        title: 'Lap Splice Lengths',
        description: 'طول الوصلة لا يقل عن 60 قطر للسيخ في وصلات الشد Class B',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ASTM A615',
        section: '',
        title: 'Standard Specification for Deformed and Plain Carbon-Steel Bars',
        description: 'المواصفات القياسية لحديد التسليح المشوه',
      ),
    ),
  ],

  // ═══════════════════════════════════════════
  //  3. ACI 318 TOLERANCES (السماحيات)
  // ═══════════════════════════════════════════

  'tol-general': [
    TextBlock(
      content:
          'السماحيات (Tolerances) هي التفاوتات المسموح بها في الأبعاد والمواقع أثناء تنفيذ العناصر الخرسانية. تنقسم السماحيات إلى قسمين رئيسيين حسب ACI 117: سماحيات العناصر الخرسانية (Formwork Tolerances) وسماحيات حديد التسليح (Reinforcement Tolerances). الالتزام بالسماحيات يضمن أن المنشأ يعمل ضمن حدود الأمان التصميمية.',
      variant: TextVariant.paragraph,
    ),
    TextBlock(
      content:
          'الجدول التالي يلخص السماحيات الأساسية المسموح بها للعناصر الخرسانية المختلفة. هذه القيم مأخوذة من ACI 117-20 و ACI 318-19.',
      variant: TextVariant.note,
    ),
  ],

  'tol-tables': [
    TableBlock(
      data: TableData(
        caption: 'سماحيات العناصر الخرسانية الإنشائية',
        headers: ['العنصر', 'البعد', 'السماحية (مم)', 'المرجع'],
        rows: [
          const TableRowData(cells: ['عمود', 'أبعاد المقطع', '+12 / -6', 'ACI 117 4.1']),
          const TableRowData(cells: ['عمود', 'الرأسية (Plumb)', '± 6 لكل 3م ارتفاع', 'ACI 117 4.3.2']),
          const TableRowData(cells: ['عمود', 'الرأسية (كلي)', '± 25 كحد أقصى', 'ACI 117 4.3.2']),
          const TableRowData(cells: ['كمرة', 'أبعاد المقطع', '+12 / -6', 'ACI 117 4.1']),
          const TableRowData(cells: ['كمرة', 'التسوية (Level)', '± 6', 'ACI 117 4.4.1']),
          const TableRowData(cells: ['بلاطة', 'سماكة البلاطة', '+10 / -6', 'ACI 117 4.1']),
          const TableRowData(cells: ['بلاطة', 'التسوية', '± 6 تحت 2م', 'ACI 117 4.4.2']),
          const TableRowData(cells: ['جدار', 'سماكة الجدار', '+10 / -6', 'ACI 117 4.1']),
          const TableRowData(cells: ['جدار', 'الرأسية', '± 6 لكل 3م ارتفاع', 'ACI 117 4.3.1']),
          const TableRowData(cells: ['قاعدة', 'أبعاد القاعدة', '+50 / -0', 'ACI 117 4.1']),
          const TableRowData(cells: ['قاعدة', 'منسوب القاعدة', '± 12', 'ACI 117 4.5.1']),
        ],
      ),
    ),
    TableBlock(
      data: TableData(
        caption: 'سماحيات حديد التسليح',
        headers: ['العنصر', 'السماحية', 'ملاحظات'],
        rows: [
          const TableRowData(cells: ['تغطية الحديد (Cover)', '± 6 مم', 'للتغطية ≥ 50 مم']),
          const TableRowData(cells: ['تغطية الحديد (Cover)', '± 3 مم', 'للتغطية < 50 مم']),
          const TableRowData(cells: ['المسافة بين الأسياخ', '± 10 مم', 'التباعد التصميمي']),
          const TableRowData(cells: ['طول الوصلة', '+50 مم / -0', 'لا يقل عن 60 قطر']),
          const TableRowData(cells: ['وضع الحديد في المقطع', '± 12 مم', 'من الموقع التصميمي']),
          const TableRowData(cells: ['زاوية ثني الكانات', '± 5°', 'للكانات المغلقة']),
        ],
      ),
    ),
    TextBlock(
      content:
          'ملاحظة: السماحيات السالبة تعني أن البعد يمكن أن يكون أقل من التصميمي بالقيمة المذكورة، والموجبة تعني أكبر. تجاوز السماحيات يتطلب مراجعة الاستشاري المصمم.',
      variant: TextVariant.warning,
    ),
  ],

  'tol-insp': [
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'التحقق من رأسية الأعمدة والجدران',
        acceptableTolerance: '± 6 مم لكل 3م ارتفاع (ACI 117 4.3)',
        method: 'شاقول أو جهاز Total Station',
        isCritical: true,
      ),
    ),
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'فحص أبعاد العناصر الخرسانية',
        acceptableTolerance: '+12 / -6 مم للكمرات والأعمدة',
        method: 'شريط قياس',
        isCritical: true,
      ),
    ),
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'فحص تسوية البلاطات والأسقف',
        acceptableTolerance: '± 6 مم تحت 2م (ACI 117 4.4)',
        method: 'قاعدة مستوى (Level)',
        isCritical: false,
      ),
    ),
    ChecklistBlock(
      title: 'قائمة التحقق من السماحيات في الموقع',
      items: [
        const ChecklistItem(id: 'tl1', text: 'قياس أبعاد الأعمدة (عرض × عمق) ومقارنتها بالمخططات', isRequired: true),
        const ChecklistItem(id: 'tl2', text: 'فحص رأسية الأعمدة باستخدام الشاقول أو Total Station', isRequired: true),
        const ChecklistItem(id: 'tl3', text: 'قياس سماكة البلاطات في عدة نقاط', isRequired: true),
        const ChecklistItem(id: 'tl4', text: 'فحص أبعاد الكمرات (عرض × ارتفاع)', isRequired: true),
        const ChecklistItem(id: 'tl5', text: 'فحص تغطية الحديد قبل الصب', isRequired: true),
        const ChecklistItem(id: 'tl6', text: 'فحص مناسيب القواعد والأساسات', isRequired: true),
        const ChecklistItem(id: 'tl7', text: 'توثيق أي تجاوز للسماحيات وإبلاغ الاستشاري', isRequired: true),
      ],
    ),
  ],

  'tol-codes': [
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ACI 117-20',
        section: '4.1 - 4.6',
        title: 'Standard Tolerances for Concrete Construction',
        description:
            'المرجع الرئيسي لسماحيات التنفيذ في المنشآت الخرسانية. يغطي سماحيات الفرم، الحديد، والشدات',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ACI 318-19',
        section: '26.5',
        title: 'Construction Tolerances',
        description:
            'السماحيات العامة في ACI 318 تشير إلى ACI 117 كمصدر رئيسي للتفاوتات المسموح بها',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ASTM E1155',
        section: '',
        title: 'Standard Test Method for Floor Flatness (FF) and Levelness (FL)',
        description: 'اختبار تسوية واستواء البلاطات والأرضيات',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'SBC 304',
        section: '6.2',
        title: 'Construction Tolerances',
        description: 'الكود السعودي للبناء - متطلبات السماحيات في التنفيذ',
      ),
    ),
  ],

  // ═══════════════════════════════════════════
  //  4. COLUMN EXECUTION (تنفيذ الأعمدة)
  // ═══════════════════════════════════════════

  'col-exec': [
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 1,
        description:
            'تحديد محاور الأعمدة وتوقيعها على الفرم باستخدام الميزانية والشاقول',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 2,
        description:
            'تركيب فرامل الأعمدة (فورم الخشب الرقائقي) وتثبيت الجوايط والكلابات حسب المخططات',
        notes: 'يجب التأكد من أن الفرم نظيفة ومدهونة بزيت الفرم',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 3,
        description:
            'ربط حديد التسليح الرأسي والأفقي (كانات) وتثبيت الكفرات البلاستيكية',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 4,
        description:
            'صب الخرسانة على طبقات ودمكها بالهزاز الميكانيكي',
        notes: 'سرعة الهزاز بين 8000-12000 دورة/دقيقة، ودمك كل طبقة قبل صب التالية',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 5,
        description: 'معالجة الخرسانة بعد الصب لمدة 7 أيام على الأقل',
      ),
    ),
  ],

  'col-insp': [
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'التحقق من أبعاد المقطع العرضي للعمود',
        acceptableTolerance: '+12 / -6 مم',
        method: 'قياس باستخدام شريط القياس',
        isCritical: true,
      ),
    ),
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'التحقق من رأسية العمود (Plumb)',
        acceptableTolerance: '± 6 مم لكل 3 متر ارتفاع',
        method: 'استخدام الشاقول أو جهاز الميزانية',
        isCritical: true,
      ),
    ),
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'التأكد من تغطية الحديد (Concrete Cover)',
        acceptableTolerance: '± 3 مم',
        method: 'فحص الكفرات البلاستيكية',
        isCritical: false,
      ),
    ),
    InspectionPointBlock(
      point: const InspectionPoint(
        criteria: 'عدد وقُطر أسياخ الحديد الرئيسية',
        acceptableTolerance: 'حسب المخططات',
        method: 'العد والقياس ومقارنة مع جدول التسليح',
        isCritical: true,
      ),
    ),
  ],

  'col-safety': [
    SafetyNoteBlock(
      note: const SafetyNote(
        message: 'تأمين منطقة الصب بشرائط تحذيرية وإبعاد غير العاملين',
        severity: SafetySeverity.high,
      ),
    ),
    SafetyNoteBlock(
      note: const SafetyNote(
        message: 'فحص سلامة السقالات والفرم قبل الصب - خطر انهيار الفرم',
        severity: SafetySeverity.critical,
      ),
    ),
    ChecklistBlock(
      title: 'قائمة السلامة اليومية للأعمدة',
      items: [
        const ChecklistItem(id: 'cs1', text: 'فحص مهمات الوقاية الشخصية'),
        const ChecklistItem(id: 'cs2', text: 'التأكد من وجود طفاية حريق'),
        const ChecklistItem(id: 'cs3', text: 'فحص سلامة الكابلات الكهربائية للهزاز'),
        const ChecklistItem(id: 'cs4', text: 'تأمين منطقة العمل وتحديدها'),
        const ChecklistItem(id: 'cs5', text: 'فحص أحوال الطقس قبل الصب'),
      ],
    ),
  ],

  'col-equip': [
    EquipmentBlock(
      title: 'المعدات الأساسية',
      items: [
        const EquipmentItem(
          name: 'هزاز خرسانة ميكانيكي',
          purpose: 'دمك الخرسانة',
          specification: 'قطر الهزاز 25-50 مم',
        ),
        const EquipmentItem(
          name: 'فورم خشب رقائقي',
          purpose: 'تشكيل الخرسانة',
          specification: 'خشب بحري 18 مم',
        ),
        const EquipmentItem(
          name: 'ميزانية (Level)',
          purpose: 'ضبط المحاور والارتفاعات',
        ),
        const EquipmentItem(
          name: 'شاقول (Plumb bob)',
          purpose: 'التحقق من رأسية العمود',
        ),
        const EquipmentItem(
          name: 'خلاطة خرسانة',
          purpose: 'خلط مكونات الخرسانة',
          specification: 'سعة 0.5-1 م³',
        ),
      ],
    ),
  ],

  'col-codes': [
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ACI 318-19',
        section: '25.4.2',
        title: 'Development Length for Bars in Tension',
        description: 'تطويل حديد التسليح - يجب أن لا يقل عن القيم المحسوبة',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ACI 318-19',
        section: '10.7',
        title: 'Column Design',
        description: 'نسبة حديد التسليح الطولي في الأعمدة بين 1% و 8% من مساحة المقطع',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ACI 318-19',
        section: '25.7.2',
        title: 'Lateral Reinforcement for Columns',
        description: 'المسافة بين الكانات لا تزيد عن 16 قطر للسيخ الطولي أو 48 قطر للكانة أو أقل بُعد للعمود',
      ),
    ),
  ],

  // ═══════════════════════════════════════════
  //  5. BEAM EXECUTION (تنفيذ الكمرات)
  // ═══════════════════════════════════════════

  'beam-exec': [
    TextBlock(
      content:
          'تبدأ عملية تنفيذ الكمرات بعد الانتهاء من صب الأعمدة والتأكد من وصول الخرسانة للقوة المطلوبة.',
      variant: TextVariant.paragraph,
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 1,
        description: 'تركيب الشدات الأفقية (Soffit formwork) وتثبيت الدعامات',
        notes: 'المسافة الرأسية بين الدعامات لا تزيد عن 1 متر',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 2,
        description: 'تسليح الكمرة: الحديد الرئيسي السفلي والعلوي + أسياخ القص',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 3,
        description: 'صبة الخرسانة والدمك الجيد حول حديد التسليح',
      ),
    ),
    TableBlock(
      data: TableData(
        caption: 'أقل أبعاد الكمرات حسب الامتداد',
        headers: ['الامتداد (م)', 'ارتفاع الكمرة (مم)', 'عرض الكمرة (مم)'],
        rows: [
          const TableRowData(cells: ['4', '400', '200']),
          const TableRowData(cells: ['5', '500', '250']),
          const TableRowData(cells: ['6', '600', '300']),
          const TableRowData(cells: ['8', '800', '350']),
        ],
      ),
    ),
  ],

  'beam-codes': [
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ACI 318-19',
        section: '9.3.1',
        title: 'Minimum and Maximum Reinforcement Ratios for Beams',
        description: 'نسبة التسليح السفلي لا تقل عن 0.33% من مساحة المقطع',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ACI 318-19',
        section: '22.5',
        title: 'Shear Strength of Beams',
        description: 'مقاومة القص في الكمرات',
      ),
    ),
  ],

  // ═══════════════════════════════════════════
  //  6. SOIL TESTING (اختبارات التربة)
  // ═══════════════════════════════════════════

  'soil-gen': [
    TextBlock(
      content:
          'اختبارات التربة تنقسم إلى اختبارات موقعية واختبارات مخبرية. الاختبارات الموقعية تجري في الحقل مباشرة، أما المخبرية فتجري على عينات مأخوذة من الموقع.',
      variant: TextVariant.paragraph,
    ),
    TableBlock(
      data: TableData(
        caption: 'أنواع اختبارات التربة الشائعة',
        headers: ['الاختبار', 'الغرض', 'النوع'],
        rows: [
          const TableRowData(cells: ['اختبار الاختراق القياسي SPT', 'تحديد كثافة التربة وقوتها', 'موقعي']),
          const TableRowData(cells: ['اختبار القص المباشر', 'تحديد زاوية الاحتكاك والتماسك', 'مخبري']),
          const TableRowData(cells: ['اختبار الضغط المحصور Triaxial', 'تحديد مقاومة القص', 'مخبري']),
          const TableRowData(cells: ['اختبار الانضغاط (Consolidation)', 'حساب الهبوط تحت الأحمال', 'مخبري']),
          const TableRowData(cells: ['اختبار حدود أتربرغ', 'تحديد اللدونة', 'مخبري']),
          const TableRowData(cells: ['اختبار المحتوى المائي', 'نسبة الماء في التربة', 'موقعي/مخبري']),
        ],
      ),
    ),
    ChecklistBlock(
      title: 'قائمة الفحص الموقعي قبل الحفر الاستكشافي',
      items: [
        const ChecklistItem(id: 'st1', text: 'فحص التقرير الجيوتقني الأولي'),
        const ChecklistItem(id: 'st2', text: 'تحديد مواقع الاختبارات الجيوتقنية'),
        const ChecklistItem(id: 'st3', text: 'تجهيز معدات الحفر والأخذ العينات'),
        const ChecklistItem(id: 'st4', text: 'تأمين الموقع وإزالة العوائق'),
      ],
    ),
  ],

  'soil-equip': [
    EquipmentBlock(
      title: 'أجهزة اختبار التربة',
      items: [
        const EquipmentItem(
          name: 'جهاز SPT',
          purpose: 'اختبار الاختراق القياسي في الموقع',
        ),
        const EquipmentItem(
          name: 'جهاز القص المباشر',
          purpose: 'تحديد مقاومة القص للتربة',
        ),
        const EquipmentItem(
          name: 'جهاز Triaxial',
          purpose: 'اختبار الضغط ثلاثي المحاور',
        ),
        const EquipmentItem(
          name: 'جهاز الانضغاط (Oedometer)',
          purpose: 'قياس الانضغاطية والهبوط',
        ),
      ],
    ),
  ],

  // ═══════════════════════════════════════════
  //  7. ASPHALT TESTING (اختبارات الأسفلت)
  // ═══════════════════════════════════════════

  'asp-exec': [
    TextBlock(
      content:
          'اختبارات الأسفلت تجري للتأكد من مطابقة الخلطة الأسفلتية للمواصفات الفنية. أهم اختبار هو اختبار مارشال.',
      variant: TextVariant.paragraph,
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 1,
        description: 'أخذ عينات من الخلطة الأسفلتية من الموقع أثناء الرصف',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 2,
        description: 'تحضير عينات مارشال (Marshall Specimens) في المختبر',
      ),
    ),
    ExecutionStepBlock(
      step: const ExecutionStep(
        stepNumber: 3,
        description:
            'قياس الثبات (Stability) والتدفق (Flow) للتأكد من المطابقة',
      ),
    ),
    TableBlock(
      data: TableData(
        caption: 'مواصفات الخلطة الأسفلتية النموذجية',
        headers: ['الخاصية', 'القيمة المطلوبة'],
        rows: [
          const TableRowData(cells: ['الثبات (Stability)', 'أقل من 8 kN']),
          const TableRowData(cells: ['التدفق (Flow)', '2 - 4 مم']),
          const TableRowData(cells: ['الفراغات الهوائية (Air Voids)', '3 - 5%']),
          const TableRowData(cells: ['نسبة البيتومين', '4.5 - 6.5%']),
          const TableRowData(cells: ['الكثافة الظاهرية', '2.30 - 2.45 جم/سم³']),
        ],
      ),
    ),
  ],

  'asp-codes': [
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'AASHTO T 245',
        section: '',
        title: 'Resistance to Plastic Flow of Bituminous Mixtures Using Marshall',
      ),
    ),
    CodeReferenceBlock(
      reference: const CodeReference(
        code: 'ASTM D6927',
        section: '',
        title: 'Marshall Stability and Flow of Asphalt Mixtures',
      ),
    ),
  ],
};
