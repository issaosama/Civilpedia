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
