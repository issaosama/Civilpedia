/**
 * Builds a combined catalog.generated.json from individual topic JSON files.
 *
 * Usage: node tools/content_studio/scripts/build_catalog_from_topics.js
 *
 * Reads:  app_ready_jsons/topics/*.topic.json
 * Writes: app_ready_jsons/catalog.generated.json
 *
 * Does NOT modify assets/encyclopedia/catalog.json.
 */

const fs = require('fs');
const path = require('path');

const TOPICS_DIR = path.resolve(__dirname, '../../../app_ready_jsons/topics');
const OUTPUT_PATH = path.resolve(__dirname, '../../../app_ready_jsons/catalog.generated.json');

const errors = [];
const warnings = [];
const seenTopicIds = new Set();
const seenSectionIds = new Set();

let filesRead = 0;
let filesValid = 0;

function main() {
  console.log('=== Catalog Generator ===');
  console.log('Input:  ' + TOPICS_DIR);
  console.log('Output: ' + OUTPUT_PATH + '\n');

  if (!fs.existsSync(TOPICS_DIR)) {
    fail('Input directory not found: ' + TOPICS_DIR);
    return;
  }

  const files = fs.readdirSync(TOPICS_DIR)
    .filter(f => f.endsWith('.topic.json'))
    .map(f => path.join(TOPICS_DIR, f));

  if (files.length === 0) {
    fail('No *.topic.json files found in ' + TOPICS_DIR);
    return;
  }

  console.log(`Found ${files.length} topic file(s)\n`);

  const topics = [];
  const sections = {};
  const blocks = {};

  for (const filePath of files) {
    const fileName = path.basename(filePath);
    filesRead++;
    console.log('Processing: ' + fileName);

    try {
      const content = fs.readFileSync(filePath, 'utf-8');
      const data = JSON.parse(content);

      if (!data.topic) { error(fileName + ': missing "topic" key'); continue; }
      if (!data.sections) { error(fileName + ': missing "sections" key'); continue; }
      if (!data.blocks) { error(fileName + ': missing "blocks" key'); continue; }

      const topicId = data.topic.id;
      if (!topicId) { error(fileName + ': topic.id is missing or empty'); continue; }
      if (seenTopicIds.has(topicId)) { error(fileName + ': duplicate topic id "' + topicId + '"'); continue; }
      seenTopicIds.add(topicId);

      const cleanedSections = [];
      for (const s of data.sections) {
        const secId = s.id;
        if (!secId) { error(fileName + ': section missing "id"'); continue; }
        if (seenSectionIds.has(secId)) { error(fileName + ': duplicate section id "' + secId + '"'); continue; }
        seenSectionIds.add(secId);

        if (!s.title) warn(fileName + ': section "' + secId + '" missing "title"');
        if (!s.type) warn(fileName + ': section "' + secId + '" missing "type"');
        if (s.order === undefined) warn(fileName + ': section "' + secId + '" missing "order"');

        cleanedSections.push({ id: secId, title: s.title || '', type: s.type || '', order: s.order || 0 });
      }
      sections[topicId] = cleanedSections;

      for (const [secId, blkList] of Object.entries(data.blocks)) {
        if (!seenSectionIds.has(secId)) {
          warn(fileName + ': blocks reference section "' + secId + '" which is not in sections list');
        }

        const cleanedBlocks = [];
        for (const b of blkList) {
          if (!b.type) { error(fileName + ': block in section "' + secId + '" missing "type"'); continue; }

          if (b.type === 'table') {
            const tblData = b.data;
            if (!tblData) { error(fileName + ': table block in "' + secId + '" missing "data"'); }
            else if (!tblData.headers || tblData.headers.length === 0) {
              error(fileName + ': table block in "' + secId + '" has missing/empty headers');
            }
          }
          if (b.type === 'checklist' && b.items && b.items.length === 0) {
            warn(fileName + ': checklist in "' + secId + '" has empty items');
          }

          cleanedBlocks.push({ ...b });
        }
        blocks[secId] = cleanedBlocks;
      }

      topics.push({ ...data.topic });
      filesValid++;
      const totalBlocks = Object.values(data.blocks).reduce((s, v) => s + v.length, 0);
      console.log('  Valid: topicId=' + topicId + ', ' + cleanedSections.length + ' sections, ' + totalBlocks + ' blocks');

    } catch (e) {
      error(fileName + ': failed to parse - ' + e.message);
    }
  }

  console.log('\n=== Summary ===');
  console.log('Files read:   ' + filesRead);
  console.log('Files valid:  ' + filesValid);
  console.log('Errors:       ' + errors.length);
  console.log('Warnings:     ' + warnings.length);

  if (errors.length > 0) {
    console.log('\n--- Errors ---');
    errors.forEach(e => console.log('  ' + e));
  }
  if (warnings.length > 0) {
    console.log('\n--- Warnings ---');
    warnings.forEach(w => console.log('  ' + w));
  }

  if (errors.length > 0) {
    console.log('\nBuild aborted due to ' + errors.length + ' error(s). No output written.');
    process.exit(1);
  }

  const now = new Date().toISOString();
  const output = {
    _meta: {
      format: 'civilpedia-catalog-generated',
      schemaVersion: 1,
      generatedAt: now,
      source: 'app_ready_jsons/topics',
      topicCount: topics.length,
      sectionCount: Object.values(sections).reduce((s, v) => s + v.length, 0),
      blockCount: Object.values(blocks).reduce((s, v) => s + v.length, 0),
    },
    topics,
    sections,
    blocks,
  };

  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(output, null, 2));
  const totalSections = output._meta.sectionCount;
  const totalBlocks = output._meta.blockCount;
  console.log('\nOutput written: ' + OUTPUT_PATH);
  console.log('Topics: ' + topics.length + ', Sections: ' + totalSections + ', Blocks: ' + totalBlocks);
}

function error(msg) { errors.push(msg); }
function warn(msg) { warnings.push(msg); }
function fail(msg) { console.log('\n' + msg); process.exit(1); }

main();
