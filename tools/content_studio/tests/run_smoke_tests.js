#!/usr/bin/env node
'use strict';

const path = require('path');
const BASE = path.join(__dirname, '..', 'js');

// 1. Promote schema.js exports to globals so validation.js & exporter.js
//    can resolve `REQUIRED_TOP_LEVEL`, `VALID_BLOCK_TYPES`, etc.
const schemaMod = require(path.join(BASE, 'schema.js'));
Object.assign(global, schemaMod);

// 2. Now source files can be required (they find their deps via globals)
const { Draft } = require(path.join(BASE, 'draft.js'));
const { ValidationEngine } = require(path.join(BASE, 'validation.js'));
const { AppExporter } = require(path.join(BASE, 'exporter.js'));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function makeMinimalDraft() {
  return {
    _meta: {
      schemaVersion: '1.0.0', version: 1,
      createdAt: '2024-01-01T00:00:00Z', updatedAt: '2024-01-01T00:00:00Z',
      source: 'test', id: 'test'
    },
    topic: {
      id: 'test', titleAr: 'Test Title', categoryId: 'concrete',
      summaryAr: 'Test summary', level: 'basic', planKey: 'free', status: 'draft'
    },
    sections: [],
    review: { status: 'draft', reviewedBy: null, reviewedAt: null, reviewNotes: null, approvalStatus: null }
  };
}

function loadDraft(data) {
  const d = new Draft();
  d.load(JSON.stringify(data), 'test.draft.json');
  return d;
}

function validate(draft) {
  return new ValidationEngine(draft).validate();
}

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

// ---------------------------------------------------------------------------
// Test 1: Validation accepts a valid minimal draft
// ---------------------------------------------------------------------------
(() => {
  console.log('\n1. Validation accepts a valid draft');
  const draft = loadDraft(makeMinimalDraft());
  const result = validate(draft);
  assert(!result.hasErrors, 'Valid draft should have no errors');
  assert(result.hasWarnings === true, 'Valid draft with empty sections should have warnings (no sections)');
})();

// ---------------------------------------------------------------------------
// Test 2: Validation rejects missing required fields
// ---------------------------------------------------------------------------
(() => {
  console.log('\n2. Validation catches missing required fields');
  const bad = makeMinimalDraft();
  bad.topic.titleAr = '';
  bad.topic.summaryAr = '';
  const result = validate(loadDraft(bad));
  assert(result.hasErrors, 'Draft with empty titleAr/summaryAr should produce errors');
})();

// ---------------------------------------------------------------------------
// Test 3: Table validation
// ---------------------------------------------------------------------------
(() => {
  console.log('\n3. Table validation');

  // 3a: empty headers -> error
  const noH = makeMinimalDraft();
  noH.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{ type: 'table', order: 1, headers: [], rows: [{ cells: ['v1'] }] }] }];
  let r = validate(loadDraft(noH));
  assert(r.hasErrors, 'Table with empty headers should error');

  // 3b: empty rows -> warning
  const noR = makeMinimalDraft();
  noR.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{ type: 'table', order: 1, headers: ['Col1'], rows: [] }] }];
  r = validate(loadDraft(noR));
  assert(!r.hasErrors, 'Table with empty rows should not error');
  assert(r.hasWarnings, 'Table with empty rows should have warnings');

  // 3c: headersEn shorter than headers -> warning
  const enShort = makeMinimalDraft();
  enShort.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{ type: 'table', order: 1, headers: ['Col1', 'Col2'], headersEn: ['Col1'], rows: [{ cells: ['v1', 'v2'] }] }] }];
  r = validate(loadDraft(enShort));
  assert(!r.hasErrors, 'headersEn mismatch should not produce errors');
  assert(r.hasWarnings, 'headersEn mismatch should produce warnings');

  // 3d: headersEn longer than headers -> warning
  const enLong = makeMinimalDraft();
  enLong.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{ type: 'table', order: 1, headers: ['Col1'], headersEn: ['Col1', 'Col2'], rows: [{ cells: ['v1'] }] }] }];
  r = validate(loadDraft(enLong));
  assert(!r.hasErrors, 'headersEn longer than headers should not error');
  assert(r.hasWarnings, 'headersEn longer than headers should produce warnings');

  // 3e: headersEn same length as headers -> no warning
  const enGood = makeMinimalDraft();
  enGood.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{ type: 'table', order: 1, headers: ['Col1', 'Col2'], headersEn: ['EN1', 'EN2'], rows: [{ cells: ['v1', 'v2'] }] }] }];
  r = validate(loadDraft(enGood));
  assert(!r.hasErrors, 'headersEn matching should not error');
})();

// ---------------------------------------------------------------------------
// Test 4: Export produces correct shape
// ---------------------------------------------------------------------------
(() => {
  console.log('\n4. Export shape');
  const draft = loadDraft(makeMinimalDraft());
  const output = new AppExporter().export(draft);
  assert(output.topic !== undefined, 'Export should have topic');
  assert(output.topic.id === 'test', 'Topic id should be preserved');
  assert(output.topic.titleAr !== undefined, 'Topic should have titleAr');
  assert(Array.isArray(output.sections), 'Export should have sections array');
  assert(output.blocks !== undefined, 'Export should have blocks object');
})();

// ---------------------------------------------------------------------------
// Test 5: Table export drops headersEn but keeps Arabic headers
// ---------------------------------------------------------------------------
(() => {
  console.log('\n5. Table export shape (headersEn excluded)');
  const data = makeMinimalDraft();
  data.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{
      type: 'table', order: 1,
      caption: { ar: 'جدول', en: 'Table' },
      headers: ['عمود1', 'عمود2'],
      headersEn: ['Col1 EN', 'Col2 EN'],
      rows: [{ cells: ['v1', 'v2'] }]
    }]
  }];
  const output = new AppExporter().export(loadDraft(data));
  const block = output.blocks['s1'][0];
  assert(block.type === 'table', 'Table block should have type table');
  assert(block.data !== undefined, 'Table block should have data wrapper');
  assert(Array.isArray(block.data.headers), 'Table data should have headers array');
  assert(block.data.headers[0] === 'عمود1', 'First Arabic header should be preserved');
  assert(block.data.headersEn === undefined, 'headersEn should be absent from export');
  assert(block.data.rows !== undefined, 'Table should have rows in export');
  assert(block.data.rows.length === 1, 'Table should have 1 row in export');
})();

// ---------------------------------------------------------------------------
// Test 6: headersEn sync logic (pure algorithm test)
// ---------------------------------------------------------------------------
(() => {
  console.log('\n6. headersEn sync algorithm');

  function syncHeadersEn(oldHeadersEn, removedIndices, newHeadersLength) {
    const removedSet = new Set(removedIndices);
    let en = oldHeadersEn.filter((_, idx) => !removedSet.has(idx));
    while (en.length < newHeadersLength) en.push('');
    return en.slice(0, newHeadersLength);
  }

  assert(JSON.stringify(syncHeadersEn(['A','B','C'], [1], 2)) === JSON.stringify(['A','C']),
    'Remove index 1 from [A,B,C] => [A,C]');

  assert(JSON.stringify(syncHeadersEn(['A','B','C','D'], [1, 2], 2)) === JSON.stringify(['A','D']),
    'Remove [1,2] from [A,B,C,D] => [A,D]');

  assert(JSON.stringify(syncHeadersEn(['A','B','C','D'], [2, 1], 2)) === JSON.stringify(['A','D']),
    'Remove [2,1] (reverse order) from [A,B,C,D] => [A,D]');

  assert(JSON.stringify(syncHeadersEn(['A','B','C'], [], 3)) === JSON.stringify(['A','B','C']),
    'No removals => unchanged');

  assert(JSON.stringify(syncHeadersEn(['A','B','C'], [0, 1, 2], 0)) === JSON.stringify([]),
    'Remove all => []');

  assert(JSON.stringify(syncHeadersEn(['A','B'], [5], 2)) === JSON.stringify(['A','B']),
    'Remove out-of-range index (new column) => unchanged');

  assert(JSON.stringify(syncHeadersEn(['A','B','C'], [1], 3)) === JSON.stringify(['A','C','']),
    'Remove index 1, pad to 3 => [A,C,]');

  assert(JSON.stringify(syncHeadersEn(['A','B','C','D'], [0, 2], 3)) === JSON.stringify(['B','D','']),
    'Remove [0,2] from 4, pad to 3 => [B,D,]');
})();

// ---------------------------------------------------------------------------
// Test 7: Image block validation and export
// ---------------------------------------------------------------------------
(() => {
  console.log('\n7. Image block validation and export');

  // 7a: image block with url produces no errors
  const draftWithImage = loadDraft(Object.assign(makeMinimalDraft(), {
    sections: [{
      id: 'img-sec', title: 'Image Section', type: 'general', order: 1,
      blocks: [{ type: 'image', order: 1, url: 'assets/images/test.png', caption: { ar: 'صورة اختبار', en: 'Test image' } }]
    }]
  }));
  const r1 = validate(draftWithImage);
  const hasNoErrors = r1.errors.length === 0;
  assert(hasNoErrors, 'Image block with url should produce no errors');
  if (!hasNoErrors) console.log('  Errors:', r1.errors);

  // 7b: image block without url produces warning, not error
  const draftMissingUrl = loadDraft(Object.assign(makeMinimalDraft(), {
    sections: [{
      id: 'img-sec2', title: 'Image Section 2', type: 'general', order: 1,
      blocks: [{ type: 'image', order: 1, url: '', caption: { ar: '', en: '' } }]
    }]
  }));
  const r2 = validate(draftMissingUrl);
  assert(r2.errors.length === 0, 'Image block without url should have NO errors');
  assert(r2.warnings.length > 0, 'Image block without url should have warnings');
  assert(r2.warnings.some(w => w.includes('url')), 'Warning should mention missing url');

  // 7c: export image block
  const exporter = new AppExporter();
  const exported = exporter.export(draftWithImage);
  const secId = 'img-sec';
  const blocks = exported.blocks[secId];
  assert(blocks && blocks.length === 1, 'Exported should have 1 block');
  const imgBlock = blocks[0];
  assert(imgBlock.type === 'image', 'Exported block type should be image');
  assert(imgBlock.imageUrl === 'assets/images/test.png', 'Exported imageUrl should be preserved');
  assert(imgBlock.caption === 'صورة اختبار', 'Exported caption should be Arabic caption');
})();

// ---------------------------------------------------------------------------
// Test 8: Image path validation warnings
// ---------------------------------------------------------------------------
(() => {
  console.log('\n8. Image path validation warnings');

  function validateImageUrl(url, desc) {
    const draft = loadDraft(Object.assign(makeMinimalDraft(), {
      sections: [{
        id: 'img-sec', title: 'Image Section', type: 'general', order: 1,
        blocks: [{ type: 'image', order: 1, url, caption: { ar: '', en: '' } }]
      }]
    }));
    const result = validate(draft);
    const warns = result.warnings;
    return { result, warns };
  }

  function expectNoWarn(url, label) {
    const { warns } = validateImageUrl(url);
    const hasFormatWarn = warns.some(w => w.includes('صيغة') || w.includes('assets/images') || w.includes('مسار الحاسبة') || w.includes('بدلاً من') || w.includes('فراغات'));
    assert(!hasFormatWarn, `${label}: should have NO format warning for "${url}"`);
  }

  function expectWarn(url, label) {
    const { warns } = validateImageUrl(url);
    assert(warns.length > 0, `${label}: should produce warning(s) for "${url}"`);
    return warns;
  }

  // Supported extensions — no format warning
  expectNoWarn('assets/images/test.png', 'PNG');
  expectNoWarn('assets/images/test.jpg', 'JPG');
  expectNoWarn('assets/images/test.jpeg', 'JPEG');
  expectNoWarn('assets/images/test.webp', 'WEBP');

  // Unsupported extensions — format warning
  let w = expectWarn('assets/images/test.heic', 'HEIC');
  assert(w.some(x => x.includes('صيغة')), 'HEIC should warn about unsupported format');
  w = expectWarn('assets/images/test.svg', 'SVG');
  assert(w.some(x => x.includes('صيغة')), 'SVG should warn about unsupported format');

  // Absolute Windows path
  w = expectWarn('D:\\Civilpedia\\assets\\images\\test.png', 'Absolute Windows path');
  assert(w.some(x => x.includes('مسار الحاسبة')), 'Absolute path should warn about drive letter');

  // Backslash path
  w = expectWarn('assets\\images\\test.png', 'Backslash');
  assert(w.some(x => x.includes('بدلاً من')), 'Backslash path should warn');

  // Spaces in filename
  w = expectWarn('assets/images/test image.png', 'Spaces');
  assert(w.some(x => x.includes('فراغات')), 'Spaces should warn');

  // Missing assets/images/ prefix
  w = expectWarn('images/test.png', 'Missing prefix');
  assert(w.some(x => x.includes('assets/images')), 'Missing prefix should warn');

  console.log(`  PASS: All ${arguments.length || 'image path'} checks passed`);
})();

// ---------------------------------------------------------------------------
// Test 9: Section title persistence
// ---------------------------------------------------------------------------
(() => {
  console.log('\n9. Section title persistence');

  function makeDraftWithSection(title) {
    return loadDraft(Object.assign(makeMinimalDraft(), {
      sections: [{
        id: 'sec-1', title, type: 'general', order: 1, blocks: []
      }]
    }));
  }

  // 9a: Section title is stored correctly
  const d1 = makeDraftWithSection('أسباب التشققات');
  assert(d1.toJSON().sections[0].title === 'أسباب التشققات', 'Title should be stored as set');

  // 9b: Section title persists after setField + JSON round-trip
  const d2 = makeDraftWithSection('قسم جديد');
  d2.setField('sections.0.title', 'طرق المعالجة');
  const serialized = JSON.stringify(d2.toJSON());
  const d3 = new Draft();
  d3.load(serialized, 'test-roundtrip.draft.json');
  assert(d3.toJSON().sections[0].title === 'طرق المعالجة', 'Title should survive JSON round-trip');

  // 9c: Section title persists after sections array round-trip
  const data = d2.toJSON();
  data.sections[0].title = 'المعدات المطلوبة';
  d2.setField('sections', data.sections);
  assert(d2.toJSON().sections[0].title === 'المعدات المطلوبة', 'Title should persist after sections array reassignment');

  // 9d: Multiple sections each preserve their own title
  const d4 = makeDraftWithSection('القسم الأول');
  const sections = d4.toJSON().sections;
  sections.push({ id: 'sec-2', title: 'القسم الثاني', type: 'general', order: 2, blocks: [] });
  d4.setField('sections', sections);
  assert(d4.toJSON().sections.length === 2, 'Should have 2 sections');
  assert(d4.toJSON().sections[0].title === 'القسم الأول', 'Section 0 title preserved');
  assert(d4.toJSON().sections[1].title === 'القسم الثاني', 'Section 1 title preserved');

  // 9e: Section title is preserved after undo
  const d5 = makeDraftWithSection('العنوان الأصلي');
  d5.setField('sections.0.title', 'العنوان الجديد');
  const snapshot = d5.toJSON();
  // Simulate undo by restoring the previous snapshot
  const d6 = new Draft();
  d6.load(JSON.stringify(snapshot), 'test-undo.draft.json');
  // Re-set to original
  const originalData = JSON.parse(JSON.stringify(snapshot));
  originalData.sections[0].title = 'العنوان الأصلي';
  d6.load(JSON.stringify(originalData), 'test-undo.draft.json');
  assert(d6.toJSON().sections[0].title === 'العنوان الأصلي', 'Undo should restore previous title');

  // 9f: Validation still works after title change
  const d7 = makeDraftWithSection('قسم مع تعديل');
  const v1 = validate(d7);
  d7.setField('sections.0.title', 'عنوان معدل');
  const v2 = validate(d7);
  assert(v2.errors.length === v1.errors.length, 'Validation error count should not change after title edit');
  assert(v2.warnings.length === v1.warnings.length, 'Validation warning count should not change after title edit');

  console.log('  PASS: All section title checks passed');
})();

// ---------------------------------------------------------------------------
// Test 10: Legacy body field detection
// ---------------------------------------------------------------------------
(() => {
  console.log('\n10. Legacy body field detection');

  // 10a: Draft with legacy fields populated should give warnings
  const withLegacy = makeMinimalDraft();
  withLegacy.topic.simpleExplanation = { ar: 'شرح مبسط', en: 'Simple explanation' };
  withLegacy.topic.beforeWork = { ar: 'قبل العمل', en: 'Before work' };
  withLegacy.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1, blocks: [{ type: 'text', order: 1, content: { ar: 'محتوى' } }] }];
  let r = validate(loadDraft(withLegacy));
  const legacyWarns = r.warnings.filter(w => w.includes('يحتوي على بيانات'));
  assert(legacyWarns.length >= 2, `Legacy fields should produce warnings (got ${legacyWarns.length})`);
  assert(legacyWarns.some(w => w.includes('simpleExplanation')), 'simpleExplanation warning should mention field name');
  assert(legacyWarns.some(w => w.includes('beforeWork')), 'beforeWork warning should mention field name');

  // 10b: Draft without legacy fields should NOT produce legacy warnings
  const clean = makeMinimalDraft();
  clean.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1, blocks: [{ type: 'text', order: 1, content: { ar: 'محتوى' } }] }];
  r = validate(loadDraft(clean));
  const cleanLegacyWarns = r.warnings.filter(w => w.includes('يحتوي على بيانات'));
  assert(cleanLegacyWarns.length === 0, 'Clean draft should have zero legacy field warnings');

  console.log('  PASS: All legacy field checks passed');
})();

// ---------------------------------------------------------------------------
// Test 11: Invalid visual_theme validation
// ---------------------------------------------------------------------------
(() => {
  console.log('\n11. visual_theme validation');

  // 11a: Invalid visual_theme.accent gives warning
  const badTheme = makeMinimalDraft();
  badTheme.topic.visual_theme = { accent: 'hot_pink' };
  badTheme.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1, blocks: [{ type: 'text', order: 1, content: { ar: 'محتوى' } }] }];
  let r = validate(loadDraft(badTheme));
  assert(r.warnings.some(w => w.includes('visual_theme')), 'Invalid visual_theme.accent should give warning');

  // 11b: Valid theme key produces no visual_theme warning
  const goodTheme = makeMinimalDraft();
  goodTheme.topic.visual_theme = { accent: 'cement_gray' };
  goodTheme.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1, blocks: [{ type: 'text', order: 1, content: { ar: 'محتوى' } }] }];
  r = validate(loadDraft(goodTheme));
  const vtWarns = r.warnings.filter(w => w.includes('visual_theme') && !w.includes('visualTheme'));
  assert(vtWarns.length === 0, 'Valid visual_theme should give no visual_theme warning');

  // 11c: Missing visual_theme is allowed (no warning)
  const noTheme = makeMinimalDraft();
  noTheme.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1, blocks: [{ type: 'text', order: 1, content: { ar: 'محتوى' } }] }];
  r = validate(loadDraft(noTheme));
  const missingWarns = r.warnings.filter(w => w.includes('visual_theme'));
  assert(missingWarns.length === 0, 'Missing visual_theme should give no visual_theme warning');

  // 11d: camelCase visualTheme should warn
  const camelTheme = makeMinimalDraft();
  camelTheme.topic.visualTheme = 'cement_gray';
  camelTheme.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1, blocks: [{ type: 'text', order: 1, content: { ar: 'محتوى' } }] }];
  r = validate(loadDraft(camelTheme));
  assert(r.warnings.some(w => w.includes('visualTheme')), 'camelCase visualTheme should give warning');

  console.log('  PASS: All visual_theme checks passed');
})();

// ---------------------------------------------------------------------------
// Test 12: Unknown block type produces error
// ---------------------------------------------------------------------------
(() => {
  console.log('\n12. Unknown block type produces error');

  const unknown = makeMinimalDraft();
  unknown.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{ type: 'unknown_block_type', order: 1 }, { type: 'text', order: 2, content: { ar: 'محتوى' } }]
  }];
  const r = validate(loadDraft(unknown));
  assert(r.hasErrors, 'Unknown block type should produce errors');
  const unknownErrors = r.errors.filter(e => e.includes('غير معروف'));
  assert(unknownErrors.length === 1, 'Should have exactly 1 unknown block type error');
  assert(unknownErrors[0].includes('unknown_block_type'), 'Error should mention the unknown type');
  assert(unknownErrors[0].includes('الأنواع المقبولة'), 'Error should list accepted types');

  console.log('  PASS: Unknown block type check passed');
})();

// ---------------------------------------------------------------------------
// Test 13: Image blob/data URL produces error
// ---------------------------------------------------------------------------
(() => {
  console.log('\n13. Image blob/data URL produces error');

  // 13a: blob: URL
  const blobUrl = makeMinimalDraft();
  blobUrl.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{ type: 'image', order: 1, url: 'blob:http://example.com/uuid' }]
  }];
  let r = validate(loadDraft(blobUrl));
  assert(r.hasErrors, 'blob: URL should produce errors');
  assert(r.errors.some(e => e.includes('blob')), 'Error should mention blob');

  // 13b: data: URL
  const dataUrl = makeMinimalDraft();
  dataUrl.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{ type: 'image', order: 1, url: 'data:image/png;base64,abc123' }]
  }];
  r = validate(loadDraft(dataUrl));
  assert(r.hasErrors, 'data: URL should produce errors');
  assert(r.errors.some(e => e.includes('data:')), 'Error should mention data:');

  // 13c: file: URL
  const fileUrl = makeMinimalDraft();
  fileUrl.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{ type: 'image', order: 1, url: 'file:///C:/images/test.png' }]
  }];
  r = validate(loadDraft(fileUrl));
  assert(r.hasErrors, 'file: URL should produce errors');
  assert(r.errors.some(e => e.includes('file:')), 'Error should mention file:');

  // 13d: Valid image path produces no errors
  const valid = makeMinimalDraft();
  valid.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{ type: 'image', order: 1, url: 'assets/images/test.png' }]
  }];
  r = validate(loadDraft(valid));
  assert(r.errors.length === 0, 'Valid image path should produce no errors');

  console.log('  PASS: All image URL checks passed');
})();

// ---------------------------------------------------------------------------
// Test 14: Empty checklist gives warning
// ---------------------------------------------------------------------------
(() => {
  console.log('\n14. Empty checklist gives warning');

  const emptyChecklist = makeMinimalDraft();
  emptyChecklist.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{ type: 'checklist', order: 1, items: [] }]
  }];
  const r = validate(loadDraft(emptyChecklist));
  assert(r.warnings.some(w => w.includes('قائمة الفحص فارغة')), 'Empty checklist should give warning');
  assert(!r.hasErrors, 'Empty checklist should not produce errors');

  console.log('  PASS: Empty checklist check passed');
})();

// ---------------------------------------------------------------------------
// Test 15: code_reference missing code gives error
// ---------------------------------------------------------------------------
(() => {
  console.log('\n15. code_reference missing code gives error');

  // 15a: Missing code should error
  const noCode = makeMinimalDraft();
  noCode.sections = [{ id: 's1', title: 'S1', type: 'codeReference', order: 1,
    blocks: [{ type: 'code_reference', order: 1, code: '', title: { ar: 'مادة الكود' } }]
  }];
  let r = validate(loadDraft(noCode));
  assert(r.hasErrors, 'code_reference with empty code should produce errors');
  assert(r.errors.some(e => e.includes('code')), 'Error should mention code field');

  // 15b: Valid code_reference should not error
  const validCode = makeMinimalDraft();
  validCode.sections = [{ id: 's1', title: 'S1', type: 'codeReference', order: 1,
    blocks: [{ type: 'code_reference', order: 1, code: 'ACI 318-19', title: { ar: 'مادة الكود' }, section: '5.4', excerpt: { ar: 'نص المادة' } }]
  }];
  r = validate(loadDraft(validCode));
  const codeErrors = r.errors.filter(e => e.includes('code_reference'));
  assert(codeErrors.length === 0, 'Valid code_reference should produce no code_reference errors');
  assert(!r.hasErrors, 'Valid code_reference should not produce errors');

  console.log('  PASS: All code_reference checks passed');
})();

// ---------------------------------------------------------------------------
// Test 16: App-ready JSON detection gives warning
// ---------------------------------------------------------------------------
(() => {
  console.log('\n16. App-ready JSON detection gives warning');

  // 16a: Draft with app-ready signals should warn
  const appReadyLike = {
    _meta: { schemaVersion: '1.0.0', version: 1, createdAt: '2024-01-01T00:00:00Z', updatedAt: '2024-01-01T00:00:00Z', source: 'test', id: 'test' },
    review: { status: 'draft', reviewedBy: null, reviewedAt: null, reviewNotes: null, approvalStatus: null },
    topic: {
      id: 'test', titleAr: 'Test', categoryId: 'concrete',
      summary: 'This is summary not summaryAr',
      level: 'basic', planKey: 'free', status: 'draft'
    },
    sections: [
      { id: 's1', title: 'S1', type: 'general', order: 1 }
    ],
    blocks: {
      s1: [{ type: 'text', order: 1, content: 'محتوى نصي' }]
    }
  };
  const raw = new Draft();
  raw.load(JSON.stringify(appReadyLike), 'app-ready.json');
  const r = validate(raw);
  assert(r.hasWarnings, 'App-ready-like JSON should produce warnings');
  const appReadyWarn = r.warnings.some(w => w.includes('App-ready'));
  assert(appReadyWarn, 'Warning should mention App-ready JSON');

  // 16b: Valid Draft JSON should NOT produce app-ready warning
  const validDraft = loadDraft(makeMinimalDraft());
  const r2 = validate(validDraft);
  const falsePositive = r2.warnings.filter(w => w.includes('App-ready'));
  assert(falsePositive.length === 0, 'Valid Draft JSON should not produce App-ready warning');

  console.log('  PASS: App-ready detection checks passed');
})();

// ---------------------------------------------------------------------------
// Test 17: Table cell count mismatch
// ---------------------------------------------------------------------------
(() => {
  console.log('\n17. Table cell count mismatch');

  // Row with fewer cells than headers
  const mismatch = makeMinimalDraft();
  mismatch.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{
      type: 'table', order: 1,
      headers: ['Col1', 'Col2', 'Col3'],
      rows: [{ cells: ['v1', 'v2'] }]
    }]
  }];
  const r = validate(loadDraft(mismatch));
  assert(!r.hasErrors, 'Cell count mismatch should not error');
  assert(r.warnings.some(w => w.includes('عدد الخلايا')), 'Cell count mismatch should warn');

  // Row with matching cells should not warn
  const match = makeMinimalDraft();
  match.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{
      type: 'table', order: 1,
      headers: ['Col1', 'Col2'],
      rows: [{ cells: ['v1', 'v2'] }]
    }]
  }];
  const r2 = validate(loadDraft(match));
  const cellWarns = r2.warnings.filter(w => w.includes('عدد الخلايا'));
  assert(cellWarns.length === 0, 'Matching cells should not warn');

  console.log('  PASS: Table cell count checks passed');
})();

// ---------------------------------------------------------------------------
// Test 18: Checklist block shape and validation
// ---------------------------------------------------------------------------
(() => {
  console.log('\n18. Checklist block shape and validation');

  // 18a: Empty checklist gives warning (no errors)
  const empty = makeMinimalDraft();
  empty.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{ type: 'checklist', order: 1, title: { ar: '' }, items: [] }]
  }];
  let r = validate(loadDraft(empty));
  assert(!r.hasErrors, 'Empty checklist should not produce errors');
  assert(r.warnings.some(w => w.includes('قائمة الفحص فارغة')), 'Empty checklist should warn');

  // 18b: Proper checklist with items should pass
  const good = makeMinimalDraft();
  good.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{
      type: 'checklist', order: 1,
      title: { ar: 'قبل الصب' },
      items: [
        { id: 'item-01', textAr: 'فحص هبوط المخروط', isRequired: true },
        { id: 'item-02', textAr: 'فحص درجة الحرارة', isRequired: false }
      ]
    }]
  }];
  r = validate(loadDraft(good));
  assert(!r.hasErrors, 'Valid checklist should produce no errors');
  const clWarns = r.warnings.filter(w => w.includes('checklist'));
  assert(clWarns.length === 0, 'Valid checklist should produce no checklist warnings');

  // 18c: Checklist with empty item textAr warns
  const emptyItem = makeMinimalDraft();
  emptyItem.sections = [{ id: 's1', title: 'S1', type: 'general', order: 1,
    blocks: [{
      type: 'checklist', order: 1,
      title: { ar: 'قائمة' },
      items: [{ id: 'item-01', textAr: '', isRequired: true }]
    }]
  }];
  r = validate(loadDraft(emptyItem));
  assert(r.warnings.some(w => w.includes('textAr')), 'Empty checklist item textAr should warn');

  console.log('  PASS: All checklist checks passed');
})();

// ---------------------------------------------------------------------------
// Test 19: Inspection point block shape and validation
// ---------------------------------------------------------------------------
(() => {
  console.log('\n19. Inspection point block shape and validation');

  // 19a: Missing criteriaAr should error
  const noCriteria = makeMinimalDraft();
  noCriteria.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1,
    blocks: [{ type: 'inspection_point', order: 1, criteriaAr: '', methodAr: '', isCritical: false }]
  }];
  let r = validate(loadDraft(noCriteria));
  assert(r.hasErrors, 'Inspection point with empty criteriaAr should error');
  assert(r.errors.some(e => e.includes('criteriaAr')), 'Error should mention criteriaAr');

  // 19b: Proper inspection point should pass
  const good = makeMinimalDraft();
  good.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1,
    blocks: [{
      type: 'inspection_point', order: 1,
      criteriaAr: 'التطبيل',
      methodAr: 'فحص بصري',
      isCritical: true,
      acceptableTolerance: '±5 مم'
    }]
  }];
  r = validate(loadDraft(good));
  assert(!r.hasErrors, 'Valid inspection point should produce no errors');
  const ipWarns = r.warnings.filter(w => w.includes('inspection_point'));
  assert(ipWarns.length === 0, 'Valid inspection point should produce no inspection_point warnings');

  // 19c: Missing methodAr should warn but not error
  const noMethod = makeMinimalDraft();
  noMethod.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1,
    blocks: [{ type: 'inspection_point', order: 1, criteriaAr: 'الاستواء', methodAr: '' }]
  }];
  r = validate(loadDraft(noMethod));
  assert(!r.hasErrors, 'Missing methodAr should not error');
  assert(r.warnings.some(w => w.includes('methodAr')), 'Missing methodAr should warn');

  console.log('  PASS: All inspection point checks passed');
})();

// ---------------------------------------------------------------------------
// Test 20: Equipment block shape and validation
// ---------------------------------------------------------------------------
(() => {
  console.log('\n20. Equipment block shape and validation');

  // 20a: Empty equipment gives warning
  const empty = makeMinimalDraft();
  empty.sections = [{ id: 's1', title: 'S1', type: 'equipment', order: 1,
    blocks: [{ type: 'equipment', order: 1, title: '', items: [] }]
  }];
  let r = validate(loadDraft(empty));
  assert(!r.hasErrors, 'Empty equipment should not error');
  assert(r.warnings.some(w => w.includes('items')), 'Empty equipment should warn about items');

  // 20b: Proper equipment with items should pass
  const good = makeMinimalDraft();
  good.sections = [{ id: 's1', title: 'S1', type: 'equipment', order: 1,
    blocks: [{
      type: 'equipment', order: 1,
      title: 'معدات الفحص',
      items: [
        { nameAr: 'مخروط الهبوط', purpose: 'قياس الهبوط', specification: 'ASTM C143' },
        { nameAr: 'ميزان', purpose: 'التحقق من الاستواء', specification: '' }
      ]
    }]
  }];
  r = validate(loadDraft(good));
  assert(!r.hasErrors, 'Valid equipment should produce no errors');
  const eqWarns = r.warnings.filter(w => w.includes('equipment'));
  assert(eqWarns.length === 0, 'Valid equipment should produce no equipment warnings');

  // 20c: Item with missing nameAr should warn
  const noName = makeMinimalDraft();
  noName.sections = [{ id: 's1', title: 'S1', type: 'equipment', order: 1,
    blocks: [{
      type: 'equipment', order: 1,
      items: [{ nameAr: '', purpose: 'اختبار', specification: '' }]
    }]
  }];
  r = validate(loadDraft(noName));
  assert(!r.hasErrors, 'Missing nameAr should not error');
  assert(r.warnings.some(w => w.includes('nameAr')), 'Missing nameAr should warn');

  console.log('  PASS: All equipment checks passed');
})();

// ---------------------------------------------------------------------------
// Test 21: markerStyle validation for inspection_point
// ---------------------------------------------------------------------------
(() => {
  console.log('\n21. markerStyle for inspection_point');

  // 21a: inspection_point without markerStyle passes (default fallback)
  const noStyle = makeMinimalDraft();
  noStyle.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1,
    blocks: [{ type: 'inspection_point', order: 1, criteriaAr: 'التطبيل', methodAr: 'فحص', isCritical: true, acceptableTolerance: '5%' }]
  }];
  let r = validate(loadDraft(noStyle));
  assert(!r.hasErrors, 'Inspection point without markerStyle should produce no errors');
  const msWarns = r.warnings.filter(w => w.includes('markerStyle'));
  assert(msWarns.length === 0, 'Inspection point without markerStyle should produce no markerStyle warnings');

  // 21b: markerStyle = critical passes
  const crit = makeMinimalDraft();
  crit.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1,
    blocks: [{ type: 'inspection_point', order: 1, criteriaAr: 'التطبيل', methodAr: 'فحص', isCritical: true, markerStyle: 'critical' }]
  }];
  r = validate(loadDraft(crit));
  assert(!r.hasErrors, 'markerStyle = critical should produce no errors');
  const critWarns = r.warnings.filter(w => w.includes('markerStyle'));
  assert(critWarns.length === 0, 'markerStyle = critical should produce no markerStyle warnings');

  // 21c: markerStyle = success passes
  const succ = makeMinimalDraft();
  succ.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1,
    blocks: [{ type: 'inspection_point', order: 1, criteriaAr: 'الاستواء', methodAr: 'قياس', isCritical: false, markerStyle: 'success' }]
  }];
  r = validate(loadDraft(succ));
  assert(!r.hasErrors, 'markerStyle = success should produce no errors');
  const succWarns = r.warnings.filter(w => w.includes('markerStyle'));
  assert(succWarns.length === 0, 'markerStyle = success should produce no markerStyle warnings');

  // 21d: invalid markerStyle triggers warning
  const bad = makeMinimalDraft();
  bad.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1,
    blocks: [{ type: 'inspection_point', order: 1, criteriaAr: 'التطبيل', methodAr: 'فحص', isCritical: true, markerStyle: 'purple' }]
  }];
  r = validate(loadDraft(bad));
  assert(!r.hasErrors, 'Invalid markerStyle should not produce errors');
  assert(r.warnings.some(w => w.includes('markerStyle')), 'Invalid markerStyle should produce a warning');

  // 21e: all valid marker styles pass
  for (const ms of MARKER_STYLE_OPTIONS) {
    const d = makeMinimalDraft();
    d.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1,
      blocks: [{ type: 'inspection_point', order: 1, criteriaAr: 'اختبار', methodAr: 'فحص', isCritical: false, markerStyle: ms }]
    }];
    r = validate(loadDraft(d));
    assert(!r.hasErrors, `Valid markerStyle "${ms}" should produce no errors`);
    const msw = r.warnings.filter(w => w.includes('markerStyle'));
    assert(msw.length === 0, `Valid markerStyle "${ms}" should produce no markerStyle warnings`);
  }

  console.log('  PASS: All markerStyle checks passed');
})();

// ---------------------------------------------------------------------------
// Test 22: markerColorMode validation
// ---------------------------------------------------------------------------
(() => {
  console.log('\n22. markerColorMode for inspection_point');

  // 22a: markerColorMode = theme passes (default)
  const themeMode = makeMinimalDraft();
  themeMode.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1,
    blocks: [{ type: 'inspection_point', order: 1, criteriaAr: 'التطبيل', methodAr: 'فحص', markerColorMode: 'theme' }]
  }];
  let r = validate(loadDraft(themeMode));
  assert(!r.hasErrors, 'markerColorMode = theme should produce no errors');
  let cmWarns = r.warnings.filter(w => w.includes('markerColorMode'));
  assert(cmWarns.length === 0, 'markerColorMode = theme should produce no markerColorMode warnings');

  // 22b: markerColorMode = semantic passes
  const semMode = makeMinimalDraft();
  semMode.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1,
    blocks: [{ type: 'inspection_point', order: 1, criteriaAr: 'الاستواء', methodAr: 'قياس', markerColorMode: 'semantic' }]
  }];
  r = validate(loadDraft(semMode));
  assert(!r.hasErrors, 'markerColorMode = semantic should produce no errors');
  cmWarns = r.warnings.filter(w => w.includes('markerColorMode'));
  assert(cmWarns.length === 0, 'markerColorMode = semantic should produce no markerColorMode warnings');

  // 22c: missing markerColorMode passes (default = theme)
  const noMode = makeMinimalDraft();
  noMode.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1,
    blocks: [{ type: 'inspection_point', order: 1, criteriaAr: 'التطبيل', methodAr: 'فحص' }]
  }];
  r = validate(loadDraft(noMode));
  assert(!r.hasErrors, 'Missing markerColorMode should produce no errors');
  cmWarns = r.warnings.filter(w => w.includes('markerColorMode'));
  assert(cmWarns.length === 0, 'Missing markerColorMode should produce no markerColorMode warnings');

  // 22d: invalid markerColorMode triggers warning
  const badMode = makeMinimalDraft();
  badMode.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1,
    blocks: [{ type: 'inspection_point', order: 1, criteriaAr: 'التطبيل', methodAr: 'فحص', markerColorMode: 'invalid' }]
  }];
  r = validate(loadDraft(badMode));
  assert(!r.hasErrors, 'Invalid markerColorMode should not produce errors');
  assert(r.warnings.some(w => w.includes('markerColorMode')), 'Invalid markerColorMode should produce a warning');

  // 22e: all valid markerColorMode values pass
  for (const cm of MARKER_COLOR_MODE_OPTIONS) {
    const d = makeMinimalDraft();
    d.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1,
      blocks: [{ type: 'inspection_point', order: 1, criteriaAr: 'اختبار', methodAr: 'فحص', markerColorMode: cm }]
    }];
    r = validate(loadDraft(d));
    assert(!r.hasErrors, `Valid markerColorMode "${cm}" should produce no errors`);
    const cmw = r.warnings.filter(w => w.includes('markerColorMode'));
    assert(cmw.length === 0, `Valid markerColorMode "${cm}" should produce no markerColorMode warnings`);
  }

  console.log('  PASS: All markerColorMode checks passed');
})();

// ---------------------------------------------------------------------------
// Test 23: New marker styles (diamond, triangle, square, target)
// ---------------------------------------------------------------------------
(() => {
  console.log('\n23. New marker styles for inspection_point');

  for (const ms of ['diamond', 'triangle', 'square', 'target']) {
    const d = makeMinimalDraft();
    d.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1,
      blocks: [{ type: 'inspection_point', order: 1, criteriaAr: 'اختبار', methodAr: 'فحص', isCritical: false, markerStyle: ms }]
    }];
    const r = validate(loadDraft(d));
    assert(!r.hasErrors, `New markerStyle "${ms}" should produce no errors`);
    const msw = r.warnings.filter(w => w.includes('markerStyle'));
    assert(msw.length === 0, `New markerStyle "${ms}" should produce no markerStyle warnings`);
  }

  console.log('  PASS: All new marker style checks passed');
})();

// ---------------------------------------------------------------------------
// Test 24: Default block template accepts markerStyle/markerColorMode
//          (regression: ensure draft.setField works on blocks created by
//           handleAddBlock's template, which omits marker fields)
// ---------------------------------------------------------------------------
(() => {
  console.log('\n24. Default inspection_point block template accepts marker fields');

  // Exact template from handleAddBlock in app.js (line 1250-1252)
  const defaultBlock = {
    type: 'inspection_point', order: 1, criteriaAr: 'اختبار',
    methodAr: 'فحص', isCritical: false, acceptableTolerance: ''
  };

  const d = makeMinimalDraft();
  d.sections = [{ id: 's1', title: 'S1', type: 'inspection', order: 1, blocks: [defaultBlock] }];
  const draft = loadDraft(d);

  // 24a: No markerStyle/markerColorMode initially — should not warn
  let r = validate(draft);
  assert(!r.hasErrors, 'No markerStyle/markerColorMode should produce no errors');
  let msw = r.warnings.filter(w => w.includes('markerStyle'));
  assert(msw.length === 0, 'No markerStyle/markerColorMode should produce no markerStyle warnings');
  let cmw = r.warnings.filter(w => w.includes('markerColorMode'));
  assert(cmw.length === 0, 'No markerStyle/markerColorMode should produce no markerColorMode warnings');

  // 24b: Set markerStyle via draft.setField (as _handleMarkerPick does)
  draft.setField('sections.0.blocks.0.markerStyle', 'diamond');
  r = validate(draft);
  assert(!r.hasErrors, 'markerStyle=diamond after setField should produce no errors');
  msw = r.warnings.filter(w => w.includes('markerStyle'));
  assert(msw.length === 0, 'markerStyle=diamond after setField should produce no markerStyle warnings');

  // 24c: Set markerColorMode via draft.setField (as _handleMarkerColorMode does)
  draft.setField('sections.0.blocks.0.markerColorMode', 'semantic');
  r = validate(draft);
  assert(!r.hasErrors, 'markerColorMode=semantic after setField should produce no errors');
  cmw = r.warnings.filter(w => w.includes('markerColorMode'));
  assert(cmw.length === 0, 'markerColorMode=semantic after setField should produce no markerColorMode warnings');

  // 24d: Verify both fields persist in the draft data
  const data = draft.toJSON();
  assert(data.sections[0].blocks[0].markerStyle === 'diamond', 'markerStyle=diamond should persist in draft data');
  assert(data.sections[0].blocks[0].markerColorMode === 'semantic', 'markerColorMode=semantic should persist in draft data');

  console.log('  PASS: All default block template checks passed');
})();

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------
console.log(`\n${'='.repeat(40)}`);
const total = passed + failed;
console.log(`Total: ${total}  Passed: ${passed}  Failed: ${failed}`);
if (failed > 0) {
  process.exit(1);
}
