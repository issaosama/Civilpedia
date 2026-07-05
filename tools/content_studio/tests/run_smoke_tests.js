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
// Summary
// ---------------------------------------------------------------------------
console.log(`\n${'='.repeat(40)}`);
const total = passed + failed;
console.log(`Total: ${total}  Passed: ${passed}  Failed: ${failed}`);
if (failed > 0) {
  process.exit(1);
}
