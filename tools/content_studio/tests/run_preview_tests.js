#!/usr/bin/env node
'use strict';

const path = require('path');
const fs = require('fs');
const BASE = path.join(__dirname, '..', 'js');

// Minimal document and window mocks for PreviewRenderer
global.window = { __csTempPreviews: null };
global.document = {
  getElementById: () => ({ innerHTML: '' }),
  createElement: (tag) => {
    if (tag === 'div') {
      return {
        textContent: '',
        innerHTML: '',
        set textContent(v) { this.innerHTML = String(v).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); },
      };
    }
    return {};
  },
};

// Load schema.js (provides globals like VALID_TEXT_VARIANTS, VALID_SEVERITIES, etc.)
const schemaMod = require(path.join(BASE, 'schema.js'));
Object.assign(global, schemaMod);

// Load preview.js (registers PreviewRenderer globally and exports via module.exports)
const { PreviewRenderer } = require(path.join(BASE, 'preview.js'));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
let passed = 0;
let failed = 0;

function assert(condition, msg) {
  if (!condition) {
    console.error(`  FAIL: ${msg}`);
    failed++;
  } else {
    console.log(`  PASS: ${msg}`);
    passed++;
  }
}

function assertsEqual(actual, expected, msg) {
  if (actual !== expected) {
    console.error(`  FAIL: ${msg} — expected "${expected}", got "${actual}"`);
    failed++;
  } else {
    console.log(`  PASS: ${msg}`);
    passed++;
  }
}

function assertIncludes(haystack, needle, msg) {
  if (!haystack.includes(needle)) {
    console.error(`  FAIL: ${msg} — expected to find "${needle}" in "${haystack.substring(0, 200)}..."`);
    failed++;
  } else {
    console.log(`  PASS: ${msg}`);
    passed++;
  }
}

function assertExcludes(haystack, needle, msg) {
  if (haystack.includes(needle)) {
    console.error(`  FAIL: ${msg} — found unexpected "${needle}"`);
    failed++;
  } else {
    console.log(`  PASS: ${msg}`);
    passed++;
  }
}

// Create a PreviewRenderer instance (constructor calls document.getElementById)
const renderer = new PreviewRenderer('test-container');

function renderSafe(fn, block) {
  try {
    return renderer[fn](block);
  } catch (e) {
    return `ERROR: ${e.message}`;
  }
}

// ---------------------------------------------------------------------------
// Preview contract tests
// ---------------------------------------------------------------------------

// 1. Empty checklist: must return empty string (no warning)
(() => {
  console.log('\n1. Empty checklist omitted from Preview');
  const html = renderSafe('_renderChecklist', { items: [] });
  assert(html === '', 'Empty checklist returns empty string');
  assertExcludes(html, 'قائمة الفحص فارغة', 'No empty-checklist warning in HTML');
})();

// 2. Empty equipment: must return empty string (no warning)
(() => {
  console.log('\n2. Empty equipment omitted from Preview');
  const html = renderSafe('_renderEquipment', { items: [] });
  assert(html === '', 'Empty equipment returns empty string');
  assertExcludes(html, 'معدات فارغة', 'No empty-equipment warning in HTML');
})();

// 3. Empty table: must return empty string (no warning)
(() => {
  console.log('\n3. Empty table omitted from Preview');
  // Both headers and rows empty
  let html = renderSafe('_renderTable', { headers: [], rows: [] });
  assert(html === '', 'Empty table (no headers, no rows) returns empty string');
  assertExcludes(html, 'جدول بدون بيانات', 'No empty-table warning in HTML');

  // Headers present but no rows
  html = renderSafe('_renderTable', { headers: ['A', 'B'], rows: [] });
  assert(html === '', 'Empty table (headers but no rows) returns empty string');

  // Rows present but no headers
  html = renderSafe('_renderTable', { headers: [], rows: [{ cells: ['1'] }] });
  assert(html === '', 'Empty table (no headers but rows) returns empty string');

  // Valid table renders normally
  html = renderSafe('_renderTable', { headers: ['A'], rows: [{ cells: ['1'] }] });
  assert(html !== '', 'Valid table renders HTML');
  assertIncludes(html, 'fp-table', 'Valid table includes fp-table class');
})();

// 4. Image without URL: must return empty string
(() => {
  console.log('\n4. Image without URL omitted from Preview');
  let html = renderSafe('_renderImage', { url: '', caption: { ar: 'Test caption' } });
  assert(html === '', 'Image without URL returns empty string (caption alone is not enough)');

  html = renderSafe('_renderImage', { url: '', caption: null });
  assert(html === '', 'Image without URL and no caption returns empty string');

  // Valid image still renders
  html = renderSafe('_renderImage', { url: 'assets/images/test.png', caption: { ar: 'Fig' } });
  assert(html !== '', 'Valid image renders HTML');
  assertIncludes(html, 'fp-image', 'Valid image includes fp-image wrapper');
})();

// 5. Inspection critical badge: حرج badge present when isCritical=true
(() => {
  console.log('\n5. Inspection critical badge in Preview');
  let html = renderSafe('_renderInspectionPoint', { criteriaAr: 'Test criteria', isCritical: true });
  assertIncludes(html, 'حرج', 'Critical inspection shows حرج badge');
  assertIncludes(html, 'fp-inspection-critical-badge', 'Badge uses correct CSS class');

  html = renderSafe('_renderInspectionPoint', { criteriaAr: 'Test criteria', isCritical: false });
  assertExcludes(html, 'حرج', 'Non-critical inspection hides حرج badge');
})();

// 6. Unknown text variant: falls back to note-style card with ملاحظة label
(() => {
  console.log('\n6. Unknown text variant in Preview');
  const html = renderSafe('_renderTextBlock', { content: { ar: 'Some note text' }, variant: 'unknown_variant' });
  assertIncludes(html, 'ملاحظة', 'Unknown variant shows ملاحظة label');
  assertIncludes(html, 'fp-variant-note', 'Unknown variant uses note CSS class');
  assertIncludes(html, 'Some note text', 'Unknown variant preserves text content');
  assertExcludes(html, 'fp-text', 'Unknown variant does NOT fall to plain-text div (uses note card)');
})();

// 7. Known text variants still work correctly
(() => {
  console.log('\n7. Known text variants unaffected');
  for (const v of ['note', 'tip', 'warning']) {
    const html = renderSafe('_renderTextBlock', { content: { ar: `Test ${v}` }, variant: v });
    assertIncludes(html, `fp-variant-${v}`, `Variant ${v} uses correct CSS class`);
    assertIncludes(html, `Test ${v}`, `Variant ${v} preserves text`);
  }
  // Paragraph = plain text
  const html = renderSafe('_renderTextBlock', { content: { ar: 'Plain' }, variant: 'paragraph' });
  assert(html === '<div class="fp-text">Plain</div>', 'Paragraph variant uses plain text div');
})();

// 8. Safety severity rendering (including none)
(() => {
  console.log('\n8. Safety severity rendering');

  // Explicit none — icon and label are hidden via CSS display:none
  const htmlNone = renderSafe('_renderSafetyNote', { message: { ar: 'Neutral note' }, severity: 'none' });
  assertIncludes(htmlNone, 'fp-safety-none', 'None severity uses none CSS class');
  assertIncludes(htmlNone, 'Neutral note', 'None severity renders message');
  assertIncludes(htmlNone, 'fp-safety-icon-none', 'None severity icon div uses none class');
  assertIncludes(htmlNone, 'fp-safety-label-none', 'None severity label div uses none class');

  const html = renderSafe('_renderSafetyNote', { message: { ar: 'Safety message' }, severity: 'high' });
  assertIncludes(html, 'Safety message', 'Safety note renders message');
  assertIncludes(html, 'fp-safety-high', 'Safety note uses high CSS class');
  assertIncludes(html, '✗', 'Safety note shows high severity icon');
  assertIncludes(html, 'عالي', 'Safety note shows high severity label');

  const htmlLow = renderSafe('_renderSafetyNote', { message: { ar: 'Low msg' }, severity: 'low' });
  assertIncludes(htmlLow, 'fp-safety-low', 'Low severity uses low CSS class');
  assertIncludes(htmlLow, '✓', 'Low severity shows low icon');
  assertIncludes(htmlLow, 'منخفض', 'Low severity shows low label');

  const htmlMed = renderSafe('_renderSafetyNote', { message: { ar: 'Med msg' }, severity: 'medium' });
  assertIncludes(htmlMed, 'fp-safety-medium', 'Medium severity uses medium CSS class');
  assertIncludes(htmlMed, '⚠', 'Medium severity shows medium icon');
  assertIncludes(htmlMed, 'متوسط', 'Medium severity shows medium label');

  const htmlCrit = renderSafe('_renderSafetyNote', { message: { ar: 'Crit msg' }, severity: 'critical' });
  assertIncludes(htmlCrit, 'fp-safety-critical', 'Critical severity uses critical CSS class');
  assertIncludes(htmlCrit, '!!', 'Critical severity shows critical icon');
  assertIncludes(htmlCrit, 'خطير', 'Critical severity shows critical label');

  const htmlDefault = renderSafe('_renderSafetyNote', { message: { ar: 'Default' } });
  assertIncludes(htmlDefault, 'fp-safety-medium', 'Missing severity defaults to medium CSS class');
  assertIncludes(htmlDefault, 'متوسط', 'Missing severity defaults to medium label');

  // Empty message omits block entirely
  const htmlEmpty = renderSafe('_renderSafetyNote', { message: {} });
  assertsEqual(htmlEmpty, '', 'Empty safety note message returns empty string');
})();

// 9. Common Mistakes redesign
(() => {
  console.log('\n9. Common Mistakes redesign');

  // Valid block renders
  const html = renderSafe('_renderCommonMistakes', { items: [{ textAr: 'خطأ شائع' }] });
  assert(html !== '', 'Common mistakes block renders HTML');
  assertIncludes(html, 'fp-mistakes-block', 'Block uses fp-mistakes-block class');
  assertIncludes(html, 'fp-mistakes-title', 'Block has title element');
  assertIncludes(html, 'الأخطاء الشائعة', 'Block shows default title');
  assertIncludes(html, 'خطأ شائع', 'Block renders item text');
  assertExcludes(html, '❌', 'Block does not use emoji in header');
  assertExcludes(html, 'fp-callout', 'Block does not use shared callout classes');

  // Custom title renders
  const htmlCustom = renderSafe('_renderCommonMistakes', { title: 'عنوان مخصص', items: [{ textAr: 'خطأ' }] });
  assertIncludes(htmlCustom, 'عنوان مخصص', 'Custom title renders');

  // Multiple items render in order
  const htmlMulti = renderSafe('_renderCommonMistakes', {
    items: [{ textAr: 'الأول' }, { textAr: 'الثاني' }, { textAr: 'الثالث' }]
  });
  const firstIdx = htmlMulti.indexOf('الأول');
  const secondIdx = htmlMulti.indexOf('الثاني');
  const thirdIdx = htmlMulti.indexOf('الثالث');
  assert(firstIdx >= 0 && secondIdx > firstIdx && thirdIdx > secondIdx, 'Multiple items render in order');

  // Empty items returns empty string
  const htmlEmpty = renderSafe('_renderCommonMistakes', {});
  assertsEqual(htmlEmpty, '', 'Empty common mistakes returns empty string');

  // Long Arabic text renders
  const longText = 'هذا نص طويل جداً لاختبار كيفية تعامل الواجهة مع المحتوى العربي الطويل الذي قد يتجاوز عرض الشاشة';
  const htmlLong = renderSafe('_renderCommonMistakes', { items: [{ textAr: longText }] });
  assertIncludes(htmlLong, longText, 'Long Arabic text renders');
})();

// 9b. Equipment block — Flutter EquipmentWidget parity
(() => {
  console.log('\n9b. Equipment block unified container');
  const html = renderSafe('_renderEquipment', {
    title: 'المعدات المطلوبة',
    items: [{ nameAr: 'قوالب مكعبات', purpose: 'لتشكيل المكعبات', specification: '150 مم' }]
  });
  assert(html !== '', 'Equipment block renders HTML');
  assertIncludes(html, 'fp-equipment', 'Uses fp-equipment unified container');
  assertIncludes(html, 'fp-equipment-list', 'Uses fp-equipment-list container');
  assertIncludes(html, 'fp-equipment-item', 'Uses fp-equipment-item class');
  assertIncludes(html, 'fp-equipment-item-row', 'Uses fp-equipment-item-row layout');
  assertIncludes(html, 'fp-equipment-marker', 'Uses fp-equipment-marker bullet');
  assertIncludes(html, 'fp-equipment-name', 'Uses fp-equipment-name class');
  assertExcludes(html, '<strong>', 'No obsolete flat-row <strong> layout');
})();

// 9c. Equipment internal header
(() => {
  console.log('\n9c. Equipment internal header');
  const html = renderSafe('_renderEquipment', {
    title: 'أدوات ذات صلة',
    items: [{ nameAr: 'ميزان' }]
  });
  assertIncludes(html, 'fp-equipment-header', 'Internal header renders when title present');
  assertIncludes(html, 'fp-equipment-header-title', 'Header title element present');
  assertIncludes(html, 'fp-equipment-header-icon', 'Header icon element present');
  assertIncludes(html, 'أدوات ذات صلة', 'Header title text renders');

  const htmlNoTitle = renderSafe('_renderEquipment', { items: [{ nameAr: 'ميزان' }] });
  assertExcludes(htmlNoTitle, 'fp-equipment-header', 'No internal header when title absent');
})();

// 9d. Equipment name renders (nameAr draft field + name fallback)
(() => {
  console.log('\n9d. Equipment name rendering');
  const htmlDraft = renderSafe('_renderEquipment', { items: [{ nameAr: 'هزاز داخلي' }] });
  assertIncludes(htmlDraft, 'هزاز داخلي', 'Draft nameAr field renders');

  const htmlApp = renderSafe('_renderEquipment', { items: [{ name: 'قضيب دمك' }] });
  assertIncludes(htmlApp, 'قضيب دمك', 'App-ready name field renders as fallback');

  const htmlNeither = renderSafe('_renderEquipment', { items: [{ purpose: 'فقط غرض' }] });
  assertIncludes(htmlNeither, 'فقط غرض', 'Item without name still renders its other fields');
})();

// 9e. Equipment purpose renders only when present (before specification, Flutter order)
(() => {
  console.log('\n9e. Equipment purpose rendering');
  const html = renderSafe('_renderEquipment', { items: [{ nameAr: 'مغرفة', purpose: 'لنقل الخرسانة' }] });
  assertIncludes(html, 'الغرض: لنقل الخرسانة', 'Purpose renders with label when present');
  assertIncludes(html, 'fp-equipment-purpose', 'Purpose uses fp-equipment-purpose class');

  const htmlNoPurpose = renderSafe('_renderEquipment', { items: [{ nameAr: 'مغرفة', specification: 'محددة' }] });
  assertExcludes(htmlNoPurpose, 'الغرض:', 'Purpose label omitted when absent');
})();

// 9f. Equipment specification renders only when present
(() => {
  console.log('\n9f. Equipment specification rendering');
  const html = renderSafe('_renderEquipment', { items: [{ nameAr: 'ماكينة فحص', specification: 'معايرة حسب المواصفة' }] });
  assertIncludes(html, 'المواصفة: معايرة حسب المواصفة', 'Specification renders with label when present');
  assertIncludes(html, 'fp-equipment-spec', 'Specification uses fp-equipment-spec class');

  const htmlNoSpec = renderSafe('_renderEquipment', { items: [{ nameAr: 'ماكينة فحص', purpose: 'لكسر المكعبات' }] });
  assertExcludes(htmlNoSpec, 'المواصفة:', 'Specification label omitted when absent');
})();

// 9g. Equipment field order matches Flutter: name → purpose → specification
(() => {
  console.log('\n9g. Equipment field order');
  const html = renderSafe('_renderEquipment', { items: [{ nameAr: 'اسم', purpose: 'غرض', specification: 'مواصفة' }] });
  const nameIdx = html.indexOf('اسم');
  const purposeIdx = html.indexOf('الغرض: غرض');
  const specIdx = html.indexOf('المواصفة: مواصفة');
  assert(nameIdx >= 0 && purposeIdx > nameIdx && specIdx > purposeIdx, 'Purpose renders after name and before specification');
})();

// 9h. Multiple equipment items preserve order
(() => {
  console.log('\n9h. Multiple equipment items preserve order');
  const html = renderSafe('_renderEquipment', {
    items: [{ nameAr: 'الأولى' }, { nameAr: 'الثانية' }, { nameAr: 'الثالثة' }]
  });
  const firstIdx = html.indexOf('الأولى');
  const secondIdx = html.indexOf('الثانية');
  const thirdIdx = html.indexOf('الثالثة');
  assert(firstIdx >= 0 && secondIdx > firstIdx && thirdIdx > secondIdx, 'Items render in original order');
})();

// 9i. Empty equipment items are filtered/omitted
(() => {
  console.log('\n9i. Empty equipment items filtered');
  const html = renderSafe('_renderEquipment', {
    items: [
      { nameAr: 'قوالب' },
      { nameAr: '   ', purpose: '  ', specification: '' },
      {},
      { nameAr: '', purpose: '', specification: '' },
      { nameAr: 'هزاز' }
    ]
  });
  assertIncludes(html, 'قوالب', 'First valid item renders');
  assertIncludes(html, 'هزاز', 'Last valid item renders');
  assert(html.split('fp-equipment-item-row').length - 1 === 2, 'Only the 2 valid items render (empty items filtered)');
})();

// 9j. Empty equipment block omitted entirely
(() => {
  console.log('\n9j. Empty equipment block omitted');
  assert(renderSafe('_renderEquipment', {}) === '', 'Block without items returns empty string');
  assert(renderSafe('_renderEquipment', { items: [] }) === '', 'Block with empty items array returns empty string');
  assert(renderSafe('_renderEquipment', { title: 'عنوان', items: [{ nameAr: ' ' }] }) === '', 'Block with only empty items returns empty string');
})();

// 9k. Long Arabic text renders safely
(() => {
  console.log('\n9k. Long Arabic text renders safely');
  const longName = 'جهاز قياس الهبوط للخرسانة الطازجة وفق متطلبات الاختبار القياسي العراقي المعتمد في المشاريع الإنشائية الكبيرة';
  const longPurpose = 'لقياس الهبوط وتحديد قابلية تشغيل الخرسانة الطازجة بصورة صحيحة قبل الصب في جميع عناصر المنشأ الخرسانية المسلحة';
  const html = renderSafe('_renderEquipment', { items: [{ nameAr: longName, purpose: longPurpose }] });
  assertIncludes(html, longName, 'Long Arabic name preserved intact');
  assertIncludes(html, longPurpose, 'Long Arabic purpose preserved intact');
  assertExcludes(html, 'ERROR', 'Long text renders without error');
})();

// 9l. Mixed Arabic/English content remains intact
(() => {
  console.log('\n9l. Mixed Arabic/English equipment content');
  const html = renderSafe('_renderEquipment', {
    items: [{
      nameAr: 'مادة Curing Compound للعناية بالخرسانة',
      purpose: 'تقليل فقدان الرطوبة وفق ASTM C309',
      specification: 'نسبة مادة صلبة لا تقل عن 25%'
    }]
  });
  assertIncludes(html, 'مادة Curing Compound للعناية بالخرسانة', 'Mixed Arabic/English name intact');
  assertIncludes(html, 'وفق ASTM C309', 'Mixed Arabic/English purpose intact');
  assertIncludes(html, 'نسبة مادة صلبة لا تقل عن 25%', 'Mixed Arabic/English specification intact');
})();

// 9m. No obsolete flat-row separator layout remains
(() => {
  console.log('\n9m. No obsolete flat-row separator layout');
  const html = renderSafe('_renderEquipment', {
    title: 'معدات',
    items: [{ nameAr: 'ميزان', purpose: 'للقياس', specification: 'دقيق' }]
  });
  assertExcludes(html, '<strong>', 'No flat-row <strong> name markup');
  assertExcludes(html, '— ', 'No inline dash-prefixed specification');
  assertExcludes(html, '<br>', 'No flat-row <br> purpose concatenation');
  assertExcludes(html, 'border-bottom', 'No flat-row separator style attribute');
})();

// 10. Report section rendering (normal blocks within section)
(() => {
  console.log('\n10. Report section through normal blocks');

  // Report section with text block — rendered through normal block dispatcher
  const section = { type: 'report', title: 'تقرير', id: 's1', order: 1, blocks: [
    { type: 'text', order: 1, content: { ar: 'محتوى التقرير' }, variant: 'paragraph' }
  ]};
  const data = { topic: { id: 't1', titleAr: 'موضوع', sections: [section] } };
  // Reuse existing _renderBlock machinery — a text block inside any section
  const html = renderSafe('_renderBlock', section.blocks[0], data);
  assertIncludes(html, 'محتوى التقرير', 'Report text block renders content');
  assertIncludes(html, 'fp-text', 'Report text block uses standard text renderer');

  // Report section with checklist block
  const checklistHtml = renderSafe('_renderBlock', {
    type: 'checklist', order: 1, title: { ar: 'قائمة التقرير' }, items: [{ text: 'بند 1', isRequired: true }]
  }, data);
  assertIncludes(checklistHtml, 'بند 1', 'Report checklist block renders item');
})();

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------
console.log(`\n${'='.repeat(50)}`);
console.log(`Preview contract tests: ${passed} passed, ${failed} failed`);
console.log(`${'='.repeat(50)}`);
process.exit(failed > 0 ? 1 : 0);
