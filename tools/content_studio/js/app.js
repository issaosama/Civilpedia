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
            <label>topic.titleEn</label>
            <input type="text" data-path="topic.titleEn" value="${esc(topic.titleEn || '')}" class="form-input" dir="ltr">
          </div>
          <div class="form-group">
            <label>topic.categoryId</label>
            <input type="text" data-path="topic.categoryId" value="${esc(topic.categoryId || '')}" class="form-input" dir="ltr">
          </div>
          <div class="form-group form-group-full">
            <label>topic.summaryAr</label>
            <textarea data-path="topic.summaryAr" class="form-textarea" dir="rtl" rows="2">${esc(topic.summaryAr || '')}</textarea>
          </div>
          <div class="form-group form-group-full">
            <label>topic.summaryEn</label>
            <textarea data-path="topic.summaryEn" class="form-textarea" dir="ltr" rows="2">${esc(topic.summaryEn || '')}</textarea>
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
            <label>review.status</label>
            <select data-path="review.status" class="form-select">
              ${options(VALID_REVIEW_STATUSES, review.status)}
            </select>
          </div>
        </div>
      </div>
      <div class="form-section">
        <h3>نص التقرير اليومي (Report Wording)</h3>
        <div class="form-group form-group-full">
          <label>reportWording.ar</label>
          <textarea data-path="topic.reportWording.ar" class="form-textarea" dir="rtl" rows="3">${esc((topic.reportWording && topic.reportWording.ar) || '')}</textarea>
        </div>
        <div class="form-group form-group-full">
          <label>reportWording.en</label>
          <textarea data-path="topic.reportWording.en" class="form-textarea" dir="ltr" rows="3">${esc((topic.reportWording && topic.reportWording.en) || '')}</textarea>
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
    if (sections.length === 0) {
      $('sections-container').innerHTML = '<div class="empty-state">لا توجد أقسام في هذا الموضوع</div>';
      return;
    }
    let html = '';
    for (let i = 0; i < sections.length; i++) {
      html += renderSectionCard(sections[i], i);
    }
    $('sections-container').innerHTML = html;
  }

  function renderSectionCard(section, index) {
    const blocks = section.blocks || [];
    const typeLabel = SECTION_TYPE_LABELS[section.type] || section.type;
    let blocksHtml = blocks.map((block, bi) => renderBlockMini(block, bi, section.id)).join('');
    if (!blocksHtml) blocksHtml = '<div class="empty-state">لا توجد كتل في هذا القسم</div>';

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
        </div>
      </div>
    `;
  }

  function renderBlockMini(block, index, sectionId) {
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

    return `
      <div class="block-mini block-mini-${block.type}">
        <div class="block-mini-header">
          <span class="block-type-label">${esc(typeLabel)}</span>
          <span class="block-order">ترتيب ${order}</span>
        </div>
        <div class="block-mini-summary">${esc(summary) || '<em class="muted">لا يوجد محتوى</em>'}</div>
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

  document.addEventListener('DOMContentLoaded', init);
})();
