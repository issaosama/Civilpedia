function esc(str) {
  if (str === null || str === undefined) return '';
  const div = document.createElement('div');
  div.textContent = String(str);
  return div.innerHTML;
}

function options(values, selected) {
  return values.map(v =>
    `<option value="${esc(v)}"${v === selected ? ' selected' : ''}>${esc(v)}</option>`
  ).join('');
}

const SCHEMA_VERSION = '1.0.0';

const VALID_LEVELS = ['basic', 'intermediate', 'advanced'];

const VALID_PLAN_KEYS = ['free', 'pro'];

const VALID_TOPIC_STATUSES = ['draft', 'review', 'approved', 'published', 'archived'];

const VALID_REVIEW_STATUSES = ['draft', 'in_review', 'changes_requested', 'approved', 'rejected'];

const VALID_SECTION_TYPES = ['general', 'execution', 'inspection', 'safety', 'equipment', 'codeReference'];

const VALID_BLOCK_TYPES = ['text', 'execution_step', 'safety_note', 'table', 'checklist', 'inspection_point', 'code_reference', 'equipment', 'image'];

const VALID_TEXT_VARIANTS = ['paragraph', 'note', 'warning', 'tip'];

const VALID_SEVERITIES = ['low', 'medium', 'high', 'critical'];

const REQUIRED_TOP_LEVEL = ['_meta', 'topic', 'sections', 'review'];

const REQUIRED_META = ['schemaVersion', 'version', 'createdAt', 'updatedAt', 'source', 'id'];

const REQUIRED_TOPIC = ['id', 'titleAr', 'categoryId', 'summaryAr', 'level', 'planKey', 'status'];

const REQUIRED_SECTION = ['id', 'title', 'type', 'order', 'blocks'];

const REQUIRED_BLOCK = ['type', 'order'];

const BLOCK_TYPES_SIMPLE = ['text', 'execution_step', 'safety_note', 'table', 'image', 'checklist', 'inspection_point', 'code_reference', 'equipment'];

const ADDABLE_BLOCK_OPTIONS = [
  { type: 'text', label: 'نص' },
  { type: 'execution_step', label: 'خطوة تنفيذ' },
  { type: 'safety_note', label: 'ملاحظة سلامة' },
  { type: 'table', label: 'جدول' },
  { type: 'image', label: 'صورة' },
  { type: 'checklist', label: 'قائمة فحص' },
  { type: 'inspection_point', label: 'نقطة فحص' },
  { type: 'code_reference', label: 'مرجع كودي' },
  { type: 'equipment', label: 'معدات / أدوات' },
];

function addableBlockOptions() {
  return ADDABLE_BLOCK_OPTIONS.map(o =>
    `<option value="${esc(o.type)}">${esc(o.label)}</option>`
  ).join('');
}

function addableSectionOptions() {
  return Object.entries(SECTION_TYPE_LABELS).map(([key, label]) =>
    `<option value="${esc(key)}">${esc(label)}</option>`
  ).join('');
}

const BLOCK_DISPLAY_NAMES = {
  text: 'نص',
  execution_step: 'خطوة تنفيذية',
  safety_note: 'ملاحظة سلامة',
  table: 'جدول',
  checklist: 'قائمة فحص',
  inspection_point: 'نقطة فحص',
  code_reference: 'مرجع كود',
  equipment: 'معدات',
  image: 'صورة'
};

const SECTION_TYPE_LABELS = {
  general: 'عام',
  execution: 'تنفيذي',
  inspection: 'فحص',
  safety: 'سلامة',
  equipment: 'معدات',
  codeReference: 'مرجع كود'
};

const SEVERITY_LABELS = {
  low: 'منخفضة',
  medium: 'متوسطة',
  high: 'عالية',
  critical: 'حرجة'
};

const THEME_OPTIONS = [
  { label: 'افتراضي / رصاصي أسمنتي', value: 'cement_gray' },
  { label: 'كحلي هندسي', value: 'navy' },
  { label: 'بترولي', value: 'teal' },
  { label: 'زيتي', value: 'olive' },
  { label: 'كهرماني ترابي', value: 'amber' },
  { label: 'عنابي', value: 'maroon' },
  { label: 'أزرق فولاذي', value: 'steel_blue' },
  { label: 'جرافيتي', value: 'graphite' },
  { label: 'رملي', value: 'sand' },
  { label: 'طوبي', value: 'brick' },
  { label: 'زمردي', value: 'emerald' },
  { label: 'نيلي', value: 'indigo' },
  { label: 'نحاسي', value: 'copper' },
  { label: 'أسفلتي', value: 'asphalt' },
];

const VALID_THEME_KEYS = THEME_OPTIONS.map(o => o.value);

const MARKER_STYLE_LABELS = {
  neutral: 'عادي',
  inspection: 'فحص',
  info: 'معلومة',
  warning: 'تحذير',
  critical: 'حرج',
  success: 'قبول / صحيح'
};

const MARKER_STYLE_OPTIONS = ['neutral', 'inspection', 'info', 'warning', 'critical', 'success'];

const LEGACY_BODY_FIELDS = [
  'simpleExplanation', 'beforeWork', 'duringWork', 'afterWork',
  'commonMistakes', 'acceptRejectItems', 'codeNotes', 'siteNotes',
  'reportWording', 'featuredImageUrl'
];

function themeOptions(selectedKey) {
  const sel = selectedKey || 'cement_gray';
  return THEME_OPTIONS.map(o =>
    `<option value="${esc(o.value)}"${o.value === sel ? ' selected' : ''}>${esc(o.label)}</option>`
  ).join('');
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    esc, options, addableBlockOptions, addableSectionOptions, themeOptions,
    SCHEMA_VERSION, VALID_LEVELS, VALID_PLAN_KEYS, VALID_TOPIC_STATUSES,
    VALID_REVIEW_STATUSES, VALID_SECTION_TYPES, VALID_BLOCK_TYPES,
    VALID_TEXT_VARIANTS, VALID_SEVERITIES, REQUIRED_TOP_LEVEL, REQUIRED_META,
    REQUIRED_TOPIC, REQUIRED_SECTION, REQUIRED_BLOCK, BLOCK_TYPES_SIMPLE,
    ADDABLE_BLOCK_OPTIONS, BLOCK_DISPLAY_NAMES, SECTION_TYPE_LABELS,
    SEVERITY_LABELS, THEME_OPTIONS, VALID_THEME_KEYS, LEGACY_BODY_FIELDS,
    MARKER_STYLE_OPTIONS, MARKER_STYLE_LABELS
  };
}
