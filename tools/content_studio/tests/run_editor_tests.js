#!/usr/bin/env node
'use strict';

const path = require('path');
const BASE = path.join(__dirname, '..', 'js');

global.window = { __csTempPreviews: null };
global.document = {
  getElementById: () => ({ innerHTML: '' }),
  createElement: (tag) => {
    if (tag === 'div') {
      return {
        textContent: '',
        innerHTML: '',
        set textContent(v) { this.innerHTML = String(v).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); },
        appendChild() {},
        removeChild() {},
        addEventListener() {},
      };
    }
    if (tag === 'input') {
      return { type: 'text', value: '', addEventListener() {} };
    }
    if (tag === 'button') {
      return { addEventListener() {} };
    }
    return { addEventListener() {} };
  },
};

const schemaMod = require(path.join(BASE, 'schema.js'));
Object.assign(global, schemaMod);

const { Draft } = require(path.join(BASE, 'draft.js'));
const { PreviewRenderer } = require(path.join(BASE, 'preview.js'));
const { InlineBlockEditor } = require(path.join(BASE, 'editor.js'));

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

function assertEqual(actual, expected, msg) {
  if (actual !== expected) {
    console.error(`  FAIL: ${msg} — expected "${expected}", got "${actual}"`);
    failed++;
  } else {
    console.log(`  PASS: ${msg}`);
    passed++;
  }
}

function assertIncludes(text, substr, msg) {
  if (!text.includes(substr)) {
    console.error(`  FAIL: ${msg} — "${substr}" not found in:\n  ${text.substring(0, 200)}`);
    failed++;
  } else {
    console.log(`  PASS: ${msg}`);
    passed++;
  }
}

function assertExcludes(text, substr, msg) {
  if (text.includes(substr)) {
    console.error(`  FAIL: ${msg} — "${substr}" found in:\n  ${text.substring(0, 200)}`);
    failed++;
  } else {
    console.log(`  PASS: ${msg}`);
    passed++;
  }
}

function makeDraftWithCommonMistakes(items) {
  const d = new Draft();
  d.load(JSON.stringify({
    _meta: { schemaVersion: '1.0.0', version: 1, createdAt: '2024-01-01T00:00:00Z', updatedAt: '2024-01-01T00:00:00Z', source: 'test', id: 'test' },
    topic: { id: 'test', titleAr: 'Test', categoryId: 'concrete', summaryAr: 'Test', level: 'basic', planKey: 'free', status: 'draft' },
    sections: [{
      id: 'sec-1', title: 'Test Section', type: 'general', order: 1,
      blocks: [{ type: 'common_mistakes', order: 1, title: 'My Mistakes', items: items || [] }]
    }],
    review: { status: 'draft', reviewedBy: null, reviewedAt: null, reviewNotes: null, approvalStatus: null }
  }), 'test.draft.json');
  return d;
}

// ---------- Minimal DOM mock for editor handling tests ----------

function createElement(tag) {
  const el = {
    tagName: tag.toUpperCase(),
    children: [],
    classList: new Set(),
    dataset: {},
    attributes: {},
    parentElement: null,
    textContent: '',
    _innerHTML: '',
    get innerHTML() { return this._innerHTML; },
    set innerHTML(v) {
      this._innerHTML = v;
      this.textContent = v.replace(/<[^>]*>/g, '');
      this.children = [];
      const match = v.match(/class="([^"]*)"/g);
      if (match) match.forEach(m => {
        m.replace(/class="([^"]*)"/, (_, cls) => {
          cls.split(' ').forEach(c => this.classList.add(c));
        });
      });
    },
    get className() { return Array.from(this.classList).join(' '); },
    set className(v) {
      this.classList.clear();
      v.split(' ').filter(Boolean).forEach(c => this.classList.add(c));
    },
    appendChild(child) {
      if (child) {
        child.parentElement = this;
        this.children.push(child);
      }
    },
    removeChild(child) {
      const idx = this.children.indexOf(child);
      if (idx >= 0) this.children.splice(idx, 1);
    },
    remove() {
      if (this.parentElement) this.parentElement.removeChild(this);
    },
    closest(sel) {
      let cur = this;
      while (cur) {
        const cls = sel.replace('.', '');
        if (cur.classList && cur.classList.has(cls)) return cur;
        cur = cur.parentElement;
      }
      return null;
    },
    querySelector(sel) {
      const cls = sel.replace('.', '');
      if (this.classList && this.classList.has(cls)) return this;
      for (const c of this.children) {
        const found = c.querySelector ? c.querySelector(sel) : null;
        if (found) return found;
      }
      return null;
    },
    querySelectorAll(sel) {
      const cls = sel.replace('.', '');
      const results = [];
      if (this.classList && this.classList.has(cls)) results.push(this);
      for (const c of this.children) {
        if (c.querySelectorAll) {
          const found = c.querySelectorAll(sel);
          found.forEach(f => results.push(f));
        }
      }
      return results;
    },
    getAttribute(name) { return this.attributes[name]; },
    setAttribute(name, val) { this.attributes[name] = String(val); },
    dispatchEvent() {},
    addEventListener() {},
    focus() {}
  };
  return el;
}

function parseHTML(html) {
  const root = createElement('div');
  root.innerHTML = html;
  return root;
}

// ---------- Test helpers (replicating handler logic from app.js) ----------

function testAddItem(editor) {
  const itemsContainer = editor.querySelector('.ie-callout-items');
  if (!itemsContainer) return;
  const itemDiv = createElement('div');
  itemDiv.className = 'ie-callout-item';
  const textInput = createElement('input');
  textInput.className = 'form-input ie-callout-text';
  textInput.value = '';
  const removeBtn = createElement('button');
  removeBtn.className = 'ie-callout-remove-item';
  itemDiv.appendChild(textInput);
  itemDiv.appendChild(removeBtn);
  const emptyState = (itemsContainer.querySelector('.empty-state-compact'));
  if (emptyState) {
    const idx = itemsContainer.children.indexOf(emptyState);
    if (idx >= 0) itemsContainer.children.splice(idx, 1);
  }
  itemsContainer.appendChild(itemDiv);
}

function testSaveEditor(editor, draft) {
  const sectionIdx = parseInt(editor.dataset.sectionIdx, 10);
  const blockIdx = parseInt(editor.dataset.blockIdx, 10);
  if (isNaN(sectionIdx) || isNaN(blockIdx)) return;
  const data = draft.toJSON();
  const sections = data.sections || [];
  if (!sections[sectionIdx]) return;
  const block = sections[sectionIdx].blocks[blockIdx];
  if (!block) return;

  const titleInput = editor.querySelector('.ie-callout-title');
  block.title = (titleInput ? titleInput.value : '').trim();

  const itemEls = editor.querySelectorAll('.ie-callout-item');
  block.items = Array.from(itemEls)
    .map(itemEl => {
      const textInput = itemEl.querySelector('.ie-callout-text');
      return { textAr: (textInput ? textInput.value : '').trim() };
    })
    .filter(item => item.textAr !== '');

  draft.setField(`sections.${sectionIdx}.blocks.${blockIdx}`, block);
}

// ===================================================================
// Tests
// ===================================================================

(() => {
  console.log('\n=== Common Mistakes Editor: Labels ===');

  const editorHtml = InlineBlockEditor._commonMistakesEditor(0, 0, {
    type: 'common_mistakes', order: 1, title: 'Test', items: [{ textAr: 'مثال' }]
  });

  assertIncludes(editorHtml, 'الأخطاء', 'common_mistakes label is الأخطاء (not البنود)');
  assertIncludes(editorHtml, 'إضافة خطأ', 'common_mistakes add button is إضافة خطأ (not إضافة بند)');
  assertIncludes(editorHtml, 'الأخطاء الشائعة', 'editor header contains الأخطاء الشائعة');
  assertExcludes(editorHtml, 'البنود', 'common_mistakes editor does not contain البنود');
  assertExcludes(editorHtml, 'إضافة بند', 'common_mistakes editor does not contain إضافة بند');
})();

(() => {
  console.log('\n=== Common Mistakes Editor: Empty state label ===');

  const editorHtml = InlineBlockEditor._commonMistakesEditor(0, 0, {
    type: 'common_mistakes', order: 1, title: 'Test', items: []
  });

  assertIncludes(editorHtml, 'لا توجد أخطاء مضافة', 'common_mistakes empty state is لا توجد أخطاء مضافة');
  assertExcludes(editorHtml, 'لا توجد بنود', 'common_mistakes empty state does not contain لا توجد بنود');
})();

(() => {
  console.log('\n=== Acceptance/Rejection Labels unchanged ===');

  const accHtml = InlineBlockEditor._acceptanceCriteriaEditor(0, 1, {
    type: 'acceptance_criteria', order: 2, title: '', items: [{ textAr: 'acc' }]
  });
  const rejHtml = InlineBlockEditor._rejectionCriteriaEditor(0, 2, {
    type: 'rejection_criteria', order: 3, title: '', items: [{ textAr: 'rej' }]
  });

  assertIncludes(accHtml, 'البنود', 'acceptance_criteria label still البنود');
  assertIncludes(accHtml, 'إضافة بند', 'acceptance_criteria add button still إضافة بند');
  assertIncludes(rejHtml, 'البنود', 'rejection_criteria label still البنود');
  assertIncludes(rejHtml, 'إضافة بند', 'rejection_criteria add button still إضافة بند');
  assertExcludes(accHtml, 'الأخطاء', 'acceptance_criteria does not contain الأخطاء');
  assertExcludes(rejHtml, 'الأخطاء', 'rejection_criteria does not contain الأخطاء');
})();

(() => {
  console.log('\n=== Common Mistakes Editor: Add item (click simulation) ===');

  const editorHtml = InlineBlockEditor._commonMistakesEditor(0, 0, {
    type: 'common_mistakes', order: 1, title: 'My Title', items: [{ textAr: 'First' }]
  });
  const editor = parseHTML(editorHtml);

  const itemsBefore = editor.querySelectorAll('.ie-callout-item').length;
  assertEqual(itemsBefore, 1, 'starts with 1 item');

  testAddItem(editor);
  const itemsAfter1 = editor.querySelectorAll('.ie-callout-item').length;
  assertEqual(itemsAfter1, 2, 'clicking add creates second mistake item');

  testAddItem(editor);
  const itemsAfter2 = editor.querySelectorAll('.ie-callout-item').length;
  assertEqual(itemsAfter2, 3, 'second click adds third mistake item');
})();

(() => {
  console.log('\n=== Common Mistakes Editor: Add item from empty state ===');

  const editorHtml = InlineBlockEditor._commonMistakesEditor(0, 0, {
    type: 'common_mistakes', order: 1, title: 'Empty', items: []
  });
  const editor = parseHTML(editorHtml);

  const itemsBefore = editor.querySelectorAll('.ie-callout-item').length;
  assertEqual(itemsBefore, 0, 'starts with 0 items');

  testAddItem(editor);
  const itemsAfter = editor.querySelectorAll('.ie-callout-item').length;
  assertEqual(itemsAfter, 1, 'add creates first item from empty state');
})();

(() => {
  console.log('\n=== Common Mistakes Editor: Save persists title and items ===');

  const draft = makeDraftWithCommonMistakes([{ textAr: 'Old' }]);

  // Build mock editor DOM manually (innerHTML parsing is limited in mock)
  const editor = createElement('div');
  editor.className = 'inline-editor';
  editor.dataset.sectionIdx = '0';
  editor.dataset.blockIdx = '0';

  const titleInput = createElement('input');
  titleInput.className = 'form-input ie-callout-title';
  titleInput.value = 'New Title';
  editor.appendChild(titleInput);

  const itemsContainer = createElement('div');
  itemsContainer.className = 'ie-callout-items';

  const item1 = createElement('div');
  item1.className = 'ie-callout-item';
  const text1 = createElement('input');
  text1.className = 'form-input ie-callout-text';
  text1.value = 'Item One';
  item1.appendChild(text1);
  itemsContainer.appendChild(item1);

  const item2 = createElement('div');
  item2.className = 'ie-callout-item';
  const text2 = createElement('input');
  text2.className = 'form-input ie-callout-text';
  text2.value = 'Item Two';
  item2.appendChild(text2);
  itemsContainer.appendChild(item2);

  editor.appendChild(itemsContainer);

  testSaveEditor(editor, draft);

  const saved = draft.toJSON();
  const block = saved.sections[0].blocks[0];
  assertEqual(block.title, 'New Title', 'save persists title');
  assertEqual(block.items.length, 2, 'save persists 2 items');
  assertEqual(block.items[0].textAr, 'Item One', 'first item saved');
  assertEqual(block.items[1].textAr, 'Item Two', 'second item saved');
})();

(() => {
  console.log('\n=== Common Mistakes Editor: Save trims whitespace and removes empty items ===');

  const draft = makeDraftWithCommonMistakes([{ textAr: 'A' }]);

  const editor = createElement('div');
  editor.className = 'inline-editor';
  editor.dataset.sectionIdx = '0';
  editor.dataset.blockIdx = '0';

  const titleInput = createElement('input');
  titleInput.className = 'form-input ie-callout-title';
  titleInput.value = '  My Title  ';
  editor.appendChild(titleInput);

  const itemsContainer = createElement('div');
  itemsContainer.className = 'ie-callout-items';

  const item1 = createElement('div');
  item1.className = 'ie-callout-item';
  const text1 = createElement('input');
  text1.className = 'form-input ie-callout-text';
  text1.value = '  Valid  ';
  item1.appendChild(text1);
  itemsContainer.appendChild(item1);

  const item2 = createElement('div');
  item2.className = 'ie-callout-item';
  const text2 = createElement('input');
  text2.className = 'form-input ie-callout-text';
  text2.value = '   ';
  item2.appendChild(text2);
  itemsContainer.appendChild(item2);

  editor.appendChild(itemsContainer);

  testSaveEditor(editor, draft);

  const block = draft.toJSON().sections[0].blocks[0];
  assertEqual(block.title, 'My Title', 'save trims title whitespace');
  assertEqual(block.items.length, 1, 'save removes fully empty items');
  assertEqual(block.items[0].textAr, 'Valid', 'save trims item whitespace and keeps valid item');
})();

(() => {
  console.log('\n=== Common Mistakes Editor: Save with all empty items ===');

  const draft = makeDraftWithCommonMistakes([{ textAr: 'Old' }]);

  const editor = createElement('div');
  editor.className = 'inline-editor';
  editor.dataset.sectionIdx = '0';
  editor.dataset.blockIdx = '0';

  const titleInput = createElement('input');
  titleInput.className = 'form-input ie-callout-title';
  titleInput.value = 'T';
  editor.appendChild(titleInput);

  const itemsContainer = createElement('div');
  itemsContainer.className = 'ie-callout-items';

  const item1 = createElement('div');
  item1.className = 'ie-callout-item';
  const text1 = createElement('input');
  text1.className = 'form-input ie-callout-text';
  text1.value = '';
  item1.appendChild(text1);
  itemsContainer.appendChild(item1);

  editor.appendChild(itemsContainer);

  testSaveEditor(editor, draft);

  const block = draft.toJSON().sections[0].blocks[0];
  assertEqual(block.items.length, 0, 'save produces empty items array when all items are empty');
})();

(() => {
  console.log('\n=== Common Mistakes: Download/reopen preserves saved data ===');

  const draft = makeDraftWithCommonMistakes([{ textAr: 'Keep Me' }, { textAr: 'Also Keep' }]);
  draft.setField('sections.0.blocks.0.title', 'Saved Title');

  // Simulate download/reopen round-trip
  const serialized = draft.serialize();
  const reopened = new Draft();
  reopened.load(serialized, 'reopened.draft.json');
  const data = reopened.toJSON();
  const block = data.sections[0].blocks[0];

  assertEqual(block.type, 'common_mistakes', 'round-trip preserves block type');
  assertEqual(block.title, 'Saved Title', 'round-trip preserves title');
  assertEqual(block.items.length, 2, 'round-trip preserves item count');
  assertEqual(block.items[0].textAr, 'Keep Me', 'round-trip preserves first item');
  assertEqual(block.items[1].textAr, 'Also Keep', 'round-trip preserves second item');
})();

(() => {
  console.log('\n=== Common Mistakes: Preview refreshes after save ===');

  const previewContainer = { innerHTML: '' };
  global.window = { __csTempPreviews: null };
  global.document = {
    getElementById: (id) => id === 'preview-container' ? previewContainer : ({ innerHTML: '' }),
    createElement: (tag) => {
      if (tag === 'div') {
        return {
          textContent: '', innerHTML: '',
          set textContent(v) { this.innerHTML = String(v).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); },
        };
      }
      if (tag === 'input') return { type: 'text', value: '', addEventListener() {} };
      if (tag === 'button') return { addEventListener() {} };
      return { addEventListener() {} };
    },
  };

  const renderer = new PreviewRenderer('preview-container');
  const draft = makeDraftWithCommonMistakes([{ textAr: 'Preview Item' }]);

  // Mutate draft via setField so it's persisted
  draft.setField('sections.0.blocks.0.title', 'Preview Title');
  const data = draft.toJSON();
  data.sections[0].blocks[0].items.push({ textAr: 'New After Save' });
  draft.setField('sections', data.sections);

  renderer.render(draft);
  const previewHtml = previewContainer.innerHTML;
  assertIncludes(previewHtml, 'Preview Title', 'preview shows updated title');
  assertIncludes(previewHtml, 'New After Save', 'preview shows newly saved item');
})();

(() => {
  console.log('\n=== Common Mistakes: Undo restores previous state ===');

  const draft = makeDraftWithCommonMistakes([{ textAr: 'Before Undo' }]);
  const originalTitle = 'Original Title';
  draft.setField('sections.0.blocks.0.title', originalTitle);

  // Capture pre-save state
  const preSaveState = draft.toJSON();

  // Modify and save
  const data = draft.toJSON();
  data.sections[0].blocks[0].title = 'Changed Title';
  data.sections[0].blocks[0].items.push({ textAr: 'Should Be Gone' });
  draft.setField('sections', data.sections);

  // Verify changes applied
  assertEqual(draft.toJSON().sections[0].blocks[0].title, 'Changed Title', 'title changed before undo');

  // Restore undo snapshot
  draft.load(JSON.stringify(preSaveState), 'restored.draft.json');

  const restored = draft.toJSON().sections[0].blocks[0];
  assertEqual(restored.title, 'Original Title', 'undo restores original title');
  assertEqual(restored.items.length, 1, 'undo restores original item count');
  assertEqual(restored.items[0].textAr, 'Before Undo', 'undo restores original item text');
})();

(() => {
  console.log('\n=== Common Mistakes Editor: Empty-state text NOT in Final Preview ===');

  const previewContainer = { innerHTML: '' };
  global.window = { __csTempPreviews: null };
  global.document = {
    getElementById: (id) => id === 'preview-container' ? previewContainer : ({ innerHTML: '' }),
    createElement: (tag) => {
      if (tag === 'div') {
        return {
          textContent: '', innerHTML: '',
          set textContent(v) { this.innerHTML = String(v).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;'); },
        };
      }
      if (tag === 'input') return { type: 'text', value: '', addEventListener() {} };
      if (tag === 'button') return { addEventListener() {} };
      return { addEventListener() {} };
    },
  };

  const renderer = new PreviewRenderer('preview-container');
  const draft = makeDraftWithCommonMistakes([{ textAr: 'Visible' }]);

  renderer.render(draft);
  const previewHtml = previewContainer.innerHTML;
  assertExcludes(previewHtml, 'لا توجد أخطاء مضافة', 'preview does not contain editor empty-state text');
  assertExcludes(previewHtml, 'لا توجد بنود', 'preview does not contain generic empty-state text');
  assertIncludes(previewHtml, 'Visible', 'preview shows actual content');
})();

// ===================================================================
// Summary
// ===================================================================
const total = passed + failed;
console.log(`\n=== Results: ${passed}/${total} passed, ${failed} failed ===\n`);
process.exit(failed > 0 ? 1 : 0);
