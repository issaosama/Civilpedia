(function () {
  'use strict';

  let draft = new Draft();
  let previewRenderer = new PreviewRenderer('preview-container');

  const $ = id => document.getElementById(id);

  function init() {
    $('load-btn').addEventListener('click', () => $('file-input').click());
    $('file-input').addEventListener('change', handleFileLoad);
    $('validate-btn').addEventListener('click', runValidation);
    $('download-btn').addEventListener('click', downloadDraft);
    $('export-btn').addEventListener('click', exportAppReady);
    $('preview-btn').addEventListener('click', updatePreview);

    previewRenderer.clear();
    $('sections-container').innerHTML = '<div class="empty-state">قم بتحميل ملف Draft JSON لعرض الأقسام والكتل</div>';
    $('sections-container').addEventListener('click', handleSectionContainerClick);
    $('validation-results').innerHTML = '';
    $('download-btn').disabled = true;
    $('export-btn').disabled = true;
  }

  function handleFileLoad(e) {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = function (ev) {
      try {
        draft.load(ev.target.result, file.name);
        $('file-name').textContent = file.name;
        renderTopicMetadata();
        renderSections();
        updatePreview();
        $('download-btn').disabled = false;
        $('export-btn').disabled = false;
        showToast('✅ تم تحميل الملف بنجاح', 'success');
      } catch (err) {
        showToast('❌ خطأ في قراءة الملف: ' + err.message, 'error');
        draft = new Draft();
        previewRenderer.clear();
        $('sections-container').innerHTML = '';
        $('validation-results').innerHTML = '';
        $('download-btn').disabled = true;
        $('export-btn').disabled = true;
        $('export-warning').innerHTML = '';
      }
    };
    reader.readAsText(file);
    e.target.value = '';
  }

  function renderTopicMetadata() {
    if (!draft.isValid()) return;
    const data = draft.toJSON();
    const topic = data.topic || {};
    const review = data.review || {};
    const meta = data._meta || {};

    const html = `
      <div class="form-section">
        <h3>بيانات الموضوع الرئيسية</h3>
        <div class="form-grid">
          <div class="form-group">
            <label>topic.id</label>
            <input type="text" data-path="topic.id" value="${esc(topic.id || '')}" class="form-input" dir="ltr">
          </div>
          <div class="form-group">
            <label>topic.titleAr</label>
            <input type="text" data-path="topic.titleAr" value="${esc(topic.titleAr || '')}" class="form-input" dir="rtl">
          </div>
          <div class="form-group">
            <label>topic.categoryId</label>
            <input type="text" data-path="topic.categoryId" value="${esc(topic.categoryId || '')}" class="form-input" dir="ltr">
          </div>
          <div class="form-group form-group-full">
            <label>topic.summaryAr</label>
            <textarea data-path="topic.summaryAr" class="form-textarea" dir="rtl" rows="2">${esc(topic.summaryAr || '')}</textarea>
          </div>
          <div class="form-group">
            <label>topic.level</label>
            <select data-path="topic.level" class="form-select">
              ${options(VALID_LEVELS, topic.level)}
            </select>
          </div>
          <div class="form-group">
            <label>topic.planKey</label>
            <select data-path="topic.planKey" class="form-select">
              ${options(VALID_PLAN_KEYS, topic.planKey)}
            </select>
          </div>
          <div class="form-group">
            <label>topic.status</label>
            <select data-path="topic.status" class="form-select">
              ${options(VALID_TOPIC_STATUSES, topic.status)}
            </select>
          </div>
          <div class="form-group">
            <label>السمة البصرية</label>
            <select data-path="topic.visual_theme.accent" class="form-select">
              ${themeOptions((topic.visual_theme && topic.visual_theme.accent) || 'cement_gray')}
            </select>
          </div>
          <div class="form-group">
            <label>review.status</label>
            <select data-path="review.status" class="form-select">
              ${options(VALID_REVIEW_STATUSES, review.status)}
            </select>
          </div>
        </div>
      </div>
      <div class="form-section">
        <h3>نص التقرير اليومي</h3>
        <div class="form-group form-group-full">
          <label>reportWording.ar</label>
          <textarea data-path="topic.reportWording.ar" class="form-textarea" dir="rtl" rows="3">${esc((topic.reportWording && topic.reportWording.ar) || '')}</textarea>
        </div>
      </div>
      <div class="form-section">
        <h3>بيانات المخطط (_meta)</h3>
        <div class="form-grid">
          <div class="form-group">
            <label>_meta.schemaVersion</label>
            <input type="text" data-path="_meta.schemaVersion" value="${esc(meta.schemaVersion || '')}" class="form-input" dir="ltr" readonly>
          </div>
          <div class="form-group">
            <label>_meta.version</label>
            <input type="number" data-path="_meta.version" value="${meta.version || 1}" class="form-input" dir="ltr">
          </div>
          <div class="form-group">
            <label>_meta.id</label>
            <input type="text" data-path="_meta.id" value="${esc(meta.id || '')}" class="form-input" dir="ltr">
          </div>
          <div class="form-group">
            <label>_meta.source</label>
            <input type="text" data-path="_meta.source" value="${esc(meta.source || '')}" class="form-input" dir="ltr" readonly>
          </div>
        </div>
      </div>
    `;
    $('topic-metadata').innerHTML = html;
    $('topic-metadata').querySelectorAll('input, textarea, select').forEach(el => {
      el.addEventListener('change', handleMetadataChange);
      el.addEventListener('input', handleMetadataChange);
    });
  }

  function renderSections() {
    if (!draft.isValid()) return;
    const data = draft.toJSON();
    const sections = data.sections || [];
    let html = '';
    if (sections.length === 0) {
      html = '<div class="empty-state">لا توجد أقسام في هذا الموضوع</div>';
    } else {
      for (let i = 0; i < sections.length; i++) {
        html += renderSectionCard(sections[i], i);
      }
    }
    html += InlineTopicEditor.renderMistakesEditor(draft);
    html += InlineTopicEditor.renderAcceptRejectEditor(draft);
    $('sections-container').innerHTML = html;
  }

  function renderSectionCard(section, index) {
    const blocks = section.blocks || [];
    const typeLabel = SECTION_TYPE_LABELS[section.type] || section.type;
    let blocksHtml = blocks.map((block, bi) => renderBlockMini(block, bi, index)).join('');
    if (!blocksHtml) blocksHtml = '<div class="empty-state">لا توجد كتل في هذا القسم</div>';

    const addBlockHtml = `
      <div class="section-add-block">
        <select class="form-select add-block-select" data-section-idx="${index}">
          ${addableBlockOptions()}
        </select>
        <button class="btn btn-success ie-add-block" data-section-idx="${index}" type="button">➕ إضافة كتلة</button>
      </div>
    `;

    return `
      <div class="section-card">
        <div class="section-card-header">
          <span class="section-order">#${section.order}</span>
          <span class="section-type-badge">${esc(typeLabel)}</span>
          <span class="section-title">${esc(section.title)}</span>
          <span class="section-block-count">${blocks.length} كتل</span>
        </div>
        <div class="section-card-body">
          ${blocksHtml}
          ${addBlockHtml}
        </div>
      </div>
    `;
  }

  function renderBlockMini(block, index, sectionIdx) {
    const typeLabel = BLOCK_DISPLAY_NAMES[block.type] || block.type;
    const order = block.order || '-';
    let summary = '';

    switch (block.type) {
      case 'text': {
        const content = block.content || {};
        summary = (content.ar || '').substring(0, 80);
        break;
      }
      case 'execution_step': {
        const desc = block.description || {};
        summary = (desc.ar || '').substring(0, 60);
        break;
      }
      case 'safety_note': {
        const msg = block.message || {};
        summary = (msg.ar || '').substring(0, 60);
        break;
      }
      case 'table':
        summary = (block.caption ? (block.caption.ar || '') : '') || `جدول: ${(block.headers || []).length} أعمدة × ${(block.rows || []).length} صفوف`;
        break;
      case 'checklist':
        summary = `قائمة فحص: ${(block.items || []).length} بنود`;
        break;
      case 'inspection_point':
        summary = block.criteriaAr || '';
        break;
      case 'code_reference':
        summary = block.code || '';
        break;
      case 'equipment':
        summary = `معدات: ${(block.items || []).length} عناصر`;
        break;
      case 'image':
        summary = block.url || '';
        break;
      default:
        summary = '';
    }

    const isSimple = BLOCK_TYPES_SIMPLE.includes(block.type);
    const removeBtn = isSimple
      ? `<button class="ie-remove-block" data-section-idx="${sectionIdx}" data-block-idx="${index}" type="button" title="حذف الكتلة">🗑️</button>`
      : '';

    return `
      <div class="block-mini block-mini-${block.type}" data-section-idx="${sectionIdx}" data-block-idx="${index}">
        <div class="block-mini-header">
          <span class="block-type-label">${esc(typeLabel)}</span>
          <span class="block-order">ترتيب ${order}</span>
        </div>
        <div class="block-mini-summary">${esc(summary) || '<em class="muted">لا يوجد محتوى</em>'}</div>
        ${removeBtn}
      </div>
    `;
  }

  function handleMetadataChange(e) {
    if (!draft.isValid()) return;
    const el = e.target;
    const path = el.dataset.path;
    if (!path) return;
    let value = el.type === 'number' ? parseInt(el.value, 10) : el.value;
    if (el.tagName === 'SELECT') value = el.value;
    draft.setField(path, value);
  }

  function runValidation() {
    if (!draft.isValid()) {
      showToast('❌ يرجى تحميل ملف Draft JSON أولاً', 'error');
      return;
    }
    const engine = new ValidationEngine(draft);
    const result = engine.validate();
    renderValidationResults(result);
  }

  function renderValidationResults(result) {
    const container = $('validation-results');
    const summaryClass = result.hasErrors ? 'val-error' : result.hasWarnings ? 'val-warning' : 'val-pass';
    let html = `<div class="val-summary ${summaryClass}">${result.summary}</div>`;

    if (result.passed.length) {
      html += '<div class="val-group"><h4>✅ نجاح</h4><ul>' +
        result.passed.map(m => `<li class="val-pass-item">${esc(m)}</li>`).join('') + '</ul></div>';
    }
    if (result.warnings.length) {
      html += '<div class="val-group"><h4>⚠️ تحذيرات</h4><ul>' +
        result.warnings.map(m => `<li class="val-warning-item">${esc(m)}</li>`).join('') + '</ul></div>';
    }
    if (result.errors.length) {
      html += '<div class="val-group"><h4>❌ أخطاء</h4><ul>' +
        result.errors.map(m => `<li class="val-error-item">${esc(m)}</li>`).join('') + '</ul></div>';
    }
    container.innerHTML = html;
  }

  function updatePreview() {
    if (draft && draft.isValid()) {
      const data = draft.toJSON();
      const accent = (data.topic && data.topic.visual_theme && data.topic.visual_theme.accent) || 'cement_gray';
      $('preview-container').setAttribute('data-theme', accent);
    }
    previewRenderer.render(draft);
  }

  function downloadDraft() {
    if (!draft.isValid()) return;
    try {
      const json = draft.serialize(true);
      downloadBlob(json, draft.fileName || 'draft.json', 'application/json');
      showToast('✅ تم تحميل ملف Draft JSON بنجاح', 'success');
    } catch (err) {
      showToast('❌ فشل التحميل: ' + err.message, 'error');
    }
  }

  function exportAppReady() {
    if (!draft.isValid()) {
      showToast('❌ يرجى تحميل ملف Draft JSON أولاً', 'error');
      return;
    }

    const engine = new ValidationEngine(draft);
    const result = engine.validate();
    renderValidationResults(result);

    if (result.hasErrors) {
      showToast('❌ التصدير محظور — يوجد أخطاء في التحقق. راجع لوحة التحقق.', 'error');
      $('export-warning').innerHTML = '';
      return;
    }

    if (result.hasWarnings) {
      $('export-warning').innerHTML =
        '<div class="export-warning-banner">⚠️ يوجد تحذيرات — يرجى مراجعتها قبل الاعتماد على الملف المُصدر.</div>';
    } else {
      $('export-warning').innerHTML = '';
    }

    try {
      const exporter = new AppExporter();
      const exportData = exporter.export(draft);
      const json = JSON.stringify(exportData, null, 2);
      const topicId = exportData.topic.id || 'exported';
      const fileName = topicId + '.topic.json';
      downloadBlob(json, fileName, 'application/json');
      showToast('✅ تم تصدير الملف بنجاح: ' + fileName, 'success');
    } catch (err) {
      showToast('❌ فشل التصدير: ' + err.message, 'error');
    }
  }

  function downloadBlob(content, fileName, mimeType) {
    const blob = new Blob([content], { type: mimeType || 'application/octet-stream' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  function showToast(msg, type) {
    const toast = document.createElement('div');
    toast.className = `toast toast-${type || 'info'}`;
    toast.textContent = msg;
    document.body.appendChild(toast);
    setTimeout(() => {
      toast.classList.add('toast-fade');
      setTimeout(() => toast.remove(), 300);
    }, 2500);
  }

  function handleSectionContainerClick(e) {
    const target = e.target.closest('[data-section-idx], .ie-save, .ie-cancel, .ie-save-topic, .ie-add-item, .ie-remove-item, .ie-add-block, .ie-remove-block');
    if (!target) return;

    if (target.classList.contains('ie-save')) {
      handleBlockSave(target);
    } else if (target.classList.contains('ie-cancel')) {
      handleBlockCancel();
    } else if (target.classList.contains('ie-save-topic')) {
      handleTopicSave(target);
    } else if (target.classList.contains('ie-add-item')) {
      handleAddItem(target);
    } else if (target.classList.contains('ie-remove-item')) {
      handleRemoveItem(target);
    } else if (target.classList.contains('ie-add-block')) {
      handleAddBlock(target);
    } else if (target.classList.contains('ie-remove-block')) {
      handleRemoveBlock(target);
    } else if (target.classList.contains('block-mini')) {
      handleBlockEdit(target);
    }
  }

  function handleBlockEdit(blockMini) {
    const sectionIdx = parseInt(blockMini.dataset.sectionIdx, 10);
    const blockIdx = parseInt(blockMini.dataset.blockIdx, 10);
    const data = draft.toJSON();
    const sections = data.sections || [];
    if (!sections[sectionIdx]) return;
    const block = sections[sectionIdx].blocks[blockIdx];
    if (!block) return;
    const editorHtml = InlineBlockEditor.getEditorHtml(sectionIdx, blockIdx, block);
    if (!editorHtml) return;
    const wrapper = document.createElement('div');
    wrapper.innerHTML = editorHtml;
    blockMini.replaceWith(wrapper.firstElementChild);
  }

  function handleBlockSave(saveBtn) {
    if (!draft.isValid()) return;
    const editor = saveBtn.closest('.inline-editor');
    if (!editor) return;
    const sectionIdx = parseInt(editor.dataset.sectionIdx, 10);
    const blockIdx = parseInt(editor.dataset.blockIdx, 10);
    const path = `sections.${sectionIdx}.blocks.${blockIdx}`;

    // Read all fields from the editor form
    const inputs = editor.querySelectorAll('.ie-input');
    inputs.forEach(input => {
      const field = input.dataset.field;
      if (!field) return;
      const fullPath = `${path}.${field}`;
      let value = input.value;
      if (input.type === 'number') value = parseInt(value, 10);
      draft.setField(fullPath, value);
    });

    renderSections();
    updatePreview();
    showToast('✅ تم حفظ التعديلات', 'success');
  }

  function handleBlockCancel() {
    renderSections();
    updatePreview();
  }

  function handleTopicSave(saveBtn) {
    if (!draft.isValid()) return;
    const targetPath = saveBtn.dataset.target;
    if (!targetPath) return;

    const items = saveBtn.closest('.section-card-body').querySelectorAll('.inline-topic-item');
    items.forEach(item => {
      const fields = item.querySelectorAll('.ie-topic-field');
      fields.forEach(field => {
        const outerPath = field.dataset.outer;
        const fieldName = field.dataset.field;
        if (!outerPath || !fieldName) return;
        const fullPath = `${outerPath}.${fieldName}`;
        let value;
        if (field.type === 'checkbox') {
          value = field.checked;
        } else if (field.type === 'number') {
          value = parseInt(field.value, 10);
        } else {
          value = field.value;
        }
        draft.setField(fullPath, value);
      });
    });

    renderSections();
    updatePreview();
    showToast('✅ تم حفظ التعديلات', 'success');
  }

  function handleAddItem(btn) {
    if (!draft.isValid()) return;
    const targetPath = btn.dataset.target;
    if (!targetPath) return;

    const data = draft.toJSON();
    let arr = getNested(data, targetPath);
    if (!Array.isArray(arr)) arr = [];

    let newItem;
    if (targetPath === 'topic.commonMistakes') {
      newItem = { ar: '', en: '', severity: 'medium' };
    } else if (targetPath === 'topic.acceptRejectItems') {
      newItem = { criteriaAr: '', criteriaEn: '', acceptanceLimitAr: '', acceptanceLimitEn: '', methodAr: '', methodEn: '', isCritical: false, reviewRequired: true, planKey: '', codeReference: '' };
    } else {
      return;
    }

    arr.push(newItem);
    draft.setField(targetPath, arr);
    renderSections();
    updatePreview();
  }

  function handleRemoveItem(btn) {
    if (!draft.isValid()) return;
    const targetPath = btn.dataset.target;
    const idx = parseInt(btn.dataset.idx, 10);
    if (!targetPath || isNaN(idx)) return;

    const data = draft.toJSON();
    let arr = getNested(data, targetPath);
    if (!Array.isArray(arr) || idx < 0 || idx >= arr.length) return;

    arr.splice(idx, 1);
    draft.setField(targetPath, arr);
    renderSections();
    updatePreview();
    showToast('✅ تم حذف البند', 'success');
  }

  function handleAddBlock(btn) {
    if (!draft.isValid()) return;
    const sectionIdx = parseInt(btn.dataset.sectionIdx, 10);
    if (isNaN(sectionIdx)) return;

    const sectionCard = btn.closest('.section-card');
    if (!sectionCard) return;
    const select = sectionCard.querySelector('.add-block-select');
    const blockType = select ? select.value : 'text';
    if (!BLOCK_TYPES_SIMPLE.includes(blockType)) return;

    const data = draft.toJSON();
    const sections = data.sections || [];
    if (!sections[sectionIdx]) return;
    const blocks = sections[sectionIdx].blocks || [];
    const nextOrder = blocks.length + 1;

    let newBlock;
    switch (blockType) {
      case 'text':
        newBlock = { type: 'text', order: nextOrder, content: { ar: '' } };
        break;
      case 'execution_step':
        newBlock = { type: 'execution_step', order: nextOrder, stepNumber: 1, description: { ar: '' }, notes: { ar: '' } };
        break;
      case 'safety_note':
        newBlock = { type: 'safety_note', order: nextOrder, message: { ar: '' }, severity: 'medium' };
        break;
      default:
        return;
    }

    blocks.push(newBlock);
    draft.setField(`sections.${sectionIdx}.blocks`, blocks);
    renderSections();
    updatePreview();
    showToast('✅ تم إضافة الكتلة بنجاح', 'success');
  }

  function handleRemoveBlock(btn) {
    if (!draft.isValid()) return;
    const sectionIdx = parseInt(btn.dataset.sectionIdx, 10);
    const blockIdx = parseInt(btn.dataset.blockIdx, 10);
    if (isNaN(sectionIdx) || isNaN(blockIdx)) return;

    if (!confirm('هل أنت متأكد من حذف هذه الكتلة؟')) return;

    const data = draft.toJSON();
    const sections = data.sections || [];
    if (!sections[sectionIdx]) return;
    const blocks = sections[sectionIdx].blocks || [];
    if (blockIdx < 0 || blockIdx >= blocks.length) return;

    blocks.splice(blockIdx, 1);
    draft.setField(`sections.${sectionIdx}.blocks`, blocks);
    renderSections();
    updatePreview();
    showToast('✅ تم حذف الكتلة', 'success');
  }

  function getNested(obj, path) {
    const parts = path.split('.');
    let current = obj;
    for (const part of parts) {
      if (current === null || current === undefined || typeof current !== 'object') return undefined;
      if (Array.isArray(current)) {
        const idx = parseInt(part, 10);
        if (isNaN(idx) || idx < 0 || idx >= current.length) return undefined;
        current = current[idx];
      } else {
        if (!(part in current)) return undefined;
        current = current[part];
      }
    }
    return current;
  }

  document.addEventListener('DOMContentLoaded', init);
})();
