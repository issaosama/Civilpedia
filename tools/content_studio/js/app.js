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
    $('validation-results').addEventListener('click', handleValidationNavClick);
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
      const numSections = sections.length;
      for (let i = 0; i < numSections; i++) {
        html += renderSectionCard(sections[i], i, numSections);
      }
    }
    html += `
      <div class="section-add-control">
        <select class="form-select add-section-type">
          ${addableSectionOptions()}
        </select>
        <button class="btn btn-primary ie-add-section" type="button">➕ إضافة قسم</button>
      </div>
    `;
    html += InlineTopicEditor.renderMistakesEditor(draft);
    html += InlineTopicEditor.renderAcceptRejectEditor(draft);
    $('sections-container').innerHTML = html;
  }

  function renderSectionCard(section, index, numSections) {
    const blocks = section.blocks || [];
    const typeLabel = SECTION_TYPE_LABELS[section.type] || section.type;
    let blocksHtml = blocks.map((block, bi) => renderBlockMini(block, bi, index, blocks.length)).join('');
    if (!blocksHtml) blocksHtml = '<div class="empty-state-compact">لا توجد كتل داخل هذا القسم</div>';

    const addBlockHtml = `
      <div class="section-add-block">
        <select class="form-select add-block-select" data-section-idx="${index}">
          ${addableBlockOptions()}
        </select>
        <button class="btn btn-success ie-add-block" data-section-idx="${index}" type="button">➕ إضافة كتلة</button>
      </div>
    `;

    const sectionUpDisabled = index === 0;
    const sectionDownDisabled = index === numSections - 1;
    const sectionReorderHtml = `
      <span class="section-reorder-group">
        <button class="ie-section-up" data-section-idx="${index}" type="button" title="تحريك القسم للأعلى"${sectionUpDisabled ? ' disabled' : ''}>↑</button>
        <button class="ie-section-down" data-section-idx="${index}" type="button" title="تحريك القسم للأسفل"${sectionDownDisabled ? ' disabled' : ''}>↓</button>
      </span>
    `;

    return `
      <div class="section-card">
        <div class="section-card-header">
          <span class="section-order">#${section.order}</span>
          <span class="section-type-badge">${esc(typeLabel)}</span>
          <span class="section-title">${esc(section.title)}</span>
          <span class="section-block-count">${blocks.length} كتل</span>
          ${sectionReorderHtml}
          <button class="ie-remove-section" data-section-idx="${index}" type="button" title="حذف القسم">🗑️</button>
        </div>
        <div class="section-card-body">
          ${blocksHtml}
          ${addBlockHtml}
        </div>
      </div>
    `;
  }

  function renderBlockMini(block, index, sectionIdx, blocksLen) {
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
    const moveDisabledUp = index === 0;
    const moveDisabledDown = index === blocksLen - 1;
    const reorderHtml = isSimple
      ? `<div class="block-mini-reorder">
          <button class="ie-move-up" data-section-idx="${sectionIdx}" data-block-idx="${index}" type="button" title="تحريك للأعلى"${moveDisabledUp ? ' disabled' : ''}>↑</button>
          <button class="ie-move-down" data-section-idx="${sectionIdx}" data-block-idx="${index}" type="button" title="تحريك للأسفل"${moveDisabledDown ? ' disabled' : ''}>↓</button>
        </div>`
      : '';
    const removeBtn = isSimple
      ? `<button class="ie-remove-block" data-section-idx="${sectionIdx}" data-block-idx="${index}" type="button" title="حذف الكتلة">🗑️</button>`
      : '';

    return `
      <div class="block-mini block-mini-${block.type}" data-section-idx="${sectionIdx}" data-block-idx="${index}">
        ${reorderHtml}
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

  function clearFieldHighlights() {
    document.querySelectorAll('.field-error').forEach(el => el.classList.remove('field-error'));
    document.querySelectorAll('.section-card-error').forEach(el => el.classList.remove('section-card-error'));
    document.querySelectorAll('.block-mini-error').forEach(el => el.classList.remove('block-mini-error'));
  }

  function applyFieldHighlights(result) {
    if (!result.fieldErrors) return;
    result.fieldErrors.forEach(fe => {
      if (fe.type === 'field' && fe.path) {
        const el = document.querySelector(`[data-path="${fe.path}"]`);
        if (el) el.classList.add('field-error');
      } else if (fe.type === 'section' && fe.sectionIdx !== undefined) {
        const cards = document.querySelectorAll('.section-card');
        if (cards[fe.sectionIdx]) cards[fe.sectionIdx].classList.add('section-card-error');
      } else if (fe.type === 'block' && fe.sectionIdx !== undefined && fe.blockIdx !== undefined) {
        const cards = document.querySelectorAll('.section-card');
        const sectionCard = cards[fe.sectionIdx];
        if (sectionCard) {
          const blockMinis = sectionCard.querySelectorAll('.block-mini');
          if (blockMinis[fe.blockIdx]) blockMinis[fe.blockIdx].classList.add('block-mini-error');
        }
      }
    });
  }

  function makeValItemAttrs(meta) {
    if (!meta) return '';
    let attrs = '';
    if (meta.path) attrs += ` data-target-path="${esc(meta.path)}"`;
    if (meta.sectionIdx !== undefined) attrs += ` data-section-idx="${meta.sectionIdx}"`;
    if (meta.blockIdx !== undefined) attrs += ` data-block-idx="${meta.blockIdx}"`;
    if (attrs) attrs += ' style="cursor:pointer;" title="انقر للانتقال إلى موقع الخطأ"';
    return attrs;
  }

  function renderValidationResults(result) {
    clearFieldHighlights();

    const container = $('validation-results');
    const summaryClass = result.hasErrors ? 'val-error' : result.hasWarnings ? 'val-warning' : 'val-pass';
    let html = `<div class="val-summary ${summaryClass}">${result.summary}</div>`;

    if (result.passed.length) {
      html += '<div class="val-group"><h4>✅ نجاح</h4><ul>' +
        result.passed.map(m => `<li class="val-pass-item">${esc(m)}</li>`).join('') + '</ul></div>';
    }
    if (result.warnings.length) {
      html += '<div class="val-group"><h4>⚠️ تحذيرات</h4><ul>';
      result.warnings.forEach((m, i) => {
        const meta = result.warningsMeta ? result.warningsMeta[i] : null;
        html += `<li class="val-warning-item"${makeValItemAttrs(meta)}>${esc(m)}</li>`;
      });
      html += '</ul></div>';
    }
    if (result.errors.length) {
      html += '<div class="val-group"><h4>❌ أخطاء</h4><ul>';
      result.errors.forEach((m, i) => {
        const meta = result.errorsMeta ? result.errorsMeta[i] : null;
        html += `<li class="val-error-item"${makeValItemAttrs(meta)}>${esc(m)}</li>`;
      });
      html += '</ul></div>';
    }
    container.innerHTML = html;

    applyFieldHighlights(result);
  }

  function navigateToTarget(path, sectionIdx, blockIdx) {
    let el = null;
    if (path) {
      el = document.querySelector(`[data-path="${path}"]`);
      if (el && el.focus) {
        el.focus();
        if (el.select) el.select();
      }
    }
    if (!el && sectionIdx !== undefined) {
      const cards = document.querySelectorAll('.section-card');
      el = cards[sectionIdx];
      if (el && blockIdx !== undefined) {
        const blockMinis = el.querySelectorAll('.block-mini');
        if (blockMinis[blockIdx]) el = blockMinis[blockIdx];
      }
    }
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'center' });
      el.classList.add('highlight-flash');
      setTimeout(() => el.classList.remove('highlight-flash'), 2000);
    }
  }

  function handleValidationNavClick(e) {
    const li = e.target.closest('.val-error-item, .val-warning-item');
    if (!li) return;
    const path = li.dataset.targetPath;
    const sectionIdx = li.dataset.sectionIdx !== undefined ? parseInt(li.dataset.sectionIdx, 10) : undefined;
    const blockIdx = li.dataset.blockIdx !== undefined ? parseInt(li.dataset.blockIdx, 10) : undefined;
    if (path === undefined && sectionIdx === undefined) return;
    navigateToTarget(path, sectionIdx, blockIdx);
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
    const target = e.target.closest('[data-section-idx], .ie-save, .ie-cancel, .ie-save-topic, .ie-add-item, .ie-remove-item, .ie-add-block, .ie-remove-block, .ie-move-up, .ie-move-down, .ie-add-section, .ie-remove-section, .ie-section-up, .ie-section-down, .ie-save-table, .ie-table-add-row, .ie-table-remove-row, .ie-table-add-header, .ie-table-remove-header');
    if (!target) return;

    if (target.classList.contains('ie-save')) {
      handleBlockSave(target);
    } else if (target.classList.contains('ie-save-table')) {
      handleTableSave(target);
    } else if (target.classList.contains('ie-table-add-row')) {
      handleTableAddRow(target);
    } else if (target.classList.contains('ie-table-remove-row')) {
      handleTableRemoveRow(target);
    } else if (target.classList.contains('ie-table-add-header')) {
      handleTableAddHeader(target);
    } else if (target.classList.contains('ie-table-remove-header')) {
      handleTableRemoveHeader(target);
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
    } else if (target.classList.contains('ie-move-up')) {
      handleMoveBlock(target, 'up');
    } else if (target.classList.contains('ie-move-down')) {
      handleMoveBlock(target, 'down');
    } else if (target.classList.contains('ie-add-section')) {
      handleAddSection();
    } else if (target.classList.contains('ie-remove-section')) {
      handleRemoveSection(target);
    } else if (target.classList.contains('ie-section-up')) {
      handleMoveSection(target, 'up');
    } else if (target.classList.contains('ie-section-down')) {
      handleMoveSection(target, 'down');
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

  function handleTableSave(saveBtn) {
    if (!draft.isValid()) return;
    const editor = saveBtn.closest('.inline-editor');
    if (!editor) return;
    const sectionIdx = parseInt(editor.dataset.sectionIdx, 10);
    const blockIdx = parseInt(editor.dataset.blockIdx, 10);
    if (isNaN(sectionIdx) || isNaN(blockIdx)) return;

    const data = draft.toJSON();
    const sections = data.sections || [];
    if (!sections[sectionIdx]) return;
    const block = sections[sectionIdx].blocks[blockIdx];
    if (!block) return;

    const captionInput = editor.querySelector('.ie-table-caption');
    block.caption = block.caption || {};
    block.caption.ar = captionInput ? captionInput.value : '';

    const headerInputs = editor.querySelectorAll('.ie-table-header-input');
    block.headers = Array.from(headerInputs).map(inp => inp.value);

    const rowEls = editor.querySelectorAll('.ie-table-row');
    block.rows = Array.from(rowEls).map(rowEl => {
      const cellInputs = rowEl.querySelectorAll('.ie-table-cell-input');
      return { cells: Array.from(cellInputs).map(inp => inp.value) };
    });

    draft.setField(`sections.${sectionIdx}.blocks.${blockIdx}`, block);
    renderSections();
    updatePreview();
    showToast('✅ تم حفظ الجدول', 'success');
  }

  function handleTableAddRow(target) {
    const editor = target.closest('.inline-editor');
    if (!editor) return;
    const headersContainer = editor.querySelector('.ie-table-headers');
    const rowsContainer = editor.querySelector('.ie-table-rows');
    if (!rowsContainer) return;
    const numCols = headersContainer ? headersContainer.querySelectorAll('.ie-table-header-input').length : 0;

    const rowDiv = document.createElement('div');
    rowDiv.className = 'ie-table-row';
    for (let c = 0; c < numCols; c++) {
      const cellInput = document.createElement('input');
      cellInput.type = 'text';
      cellInput.className = 'form-input ie-table-cell-input';
      cellInput.value = '';
      cellInput.placeholder = '...';
      cellInput.dir = 'rtl';
      rowDiv.appendChild(cellInput);
    }
    const removeBtn = document.createElement('button');
    removeBtn.className = 'ie-table-remove-row';
    removeBtn.title = 'حذف الصف';
    removeBtn.textContent = '🗑️';
    rowDiv.appendChild(removeBtn);

    rowsContainer.appendChild(rowDiv);

    const emptyState = editor.querySelector('.ie-table-section:last-child .empty-state-compact');
    if (emptyState) emptyState.remove();
  }

  function handleTableRemoveRow(target) {
    const row = target.closest('.ie-table-row');
    if (!row) return;
    const rowsContainer = row.closest('.ie-table-rows');
    if (!rowsContainer) return;
    if (rowsContainer.children.length <= 1) {
      if (!confirm('سيؤدي حذف آخر صف إلى جدول فارغ. هل أنت متأكد؟')) return;
    }
    row.remove();
    const editor = target.closest('.inline-editor');
    if (editor && !rowsContainer.children.length) {
      const section = rowsContainer.closest('.ie-table-section');
      if (section && !section.querySelector('.empty-state-compact')) {
        const emptyDiv = document.createElement('div');
        emptyDiv.className = 'empty-state-compact';
        emptyDiv.textContent = 'لا توجد صفوف في الجدول';
        section.appendChild(emptyDiv);
      }
    }
  }

  function handleTableAddHeader(target) {
    const editor = target.closest('.inline-editor');
    if (!editor) return;
    const headersContainer = editor.querySelector('.ie-table-headers');
    const rowsContainer = editor.querySelector('.ie-table-rows');
    if (!headersContainer) return;

    const headerDiv = document.createElement('div');
    headerDiv.className = 'ie-table-header-row';
    const headerInput = document.createElement('input');
    headerInput.type = 'text';
    headerInput.className = 'form-input ie-table-header-input';
    headerInput.value = '';
    headerInput.placeholder = '...';
    headerInput.dir = 'rtl';
    headerDiv.appendChild(headerInput);
    const removeHeaderBtn = document.createElement('button');
    removeHeaderBtn.className = 'ie-table-remove-header';
    removeHeaderBtn.title = 'حذف العمود';
    removeHeaderBtn.textContent = '🗑️';
    headerDiv.appendChild(removeHeaderBtn);
    headersContainer.appendChild(headerDiv);

    const emptyState = headersContainer.querySelector('.empty-state-compact');
    if (emptyState) emptyState.remove();

    if (rowsContainer) {
      Array.from(rowsContainer.children).forEach(rowEl => {
        const cellInput = document.createElement('input');
        cellInput.type = 'text';
        cellInput.className = 'form-input ie-table-cell-input';
        cellInput.value = '';
        cellInput.placeholder = '...';
        cellInput.dir = 'rtl';
        rowEl.insertBefore(cellInput, rowEl.querySelector('.ie-table-remove-row'));
      });
    }
  }

  function handleTableRemoveHeader(target) {
    const headerRow = target.closest('.ie-table-header-row');
    if (!headerRow) return;
    const headersContainer = headerRow.closest('.ie-table-headers');
    if (!headersContainer) return;
    const colIdx = Array.from(headersContainer.children).indexOf(headerRow);
    if (colIdx === -1) return;

    headerRow.remove();

    if (!headersContainer.children.length) {
      const emptyDiv = document.createElement('div');
      emptyDiv.className = 'empty-state-compact';
      emptyDiv.textContent = 'لا توجد رؤوس أعمدة';
      headersContainer.appendChild(emptyDiv);
    }

    const editor = target.closest('.inline-editor');
    if (!editor) return;
    const rowsContainer = editor.querySelector('.ie-table-rows');
    if (rowsContainer) {
      Array.from(rowsContainer.children).forEach(rowEl => {
        const cells = rowEl.querySelectorAll('.ie-table-cell-input');
        if (cells[colIdx]) cells[colIdx].remove();
      });
    }
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
      case 'table':
        newBlock = { type: 'table', order: nextOrder, caption: { ar: '', en: '' }, headers: [], headersEn: [], rows: [] };
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

  function handleMoveSection(btn, direction) {
    if (!draft.isValid()) return;
    const sectionIdx = parseInt(btn.dataset.sectionIdx, 10);
    if (isNaN(sectionIdx)) return;

    const data = draft.toJSON();
    const sections = data.sections || [];
    const targetIdx = direction === 'up' ? sectionIdx - 1 : sectionIdx + 1;
    if (targetIdx < 0 || targetIdx >= sections.length) return;

    [sections[sectionIdx], sections[targetIdx]] = [sections[targetIdx], sections[sectionIdx]];
    sections.forEach((s, i) => { s.order = i + 1; });
    draft.setField('sections', sections);
    renderSections();
    updatePreview();
    showToast('✅ تم تغيير ترتيب الأقسام', 'success');
  }

  function handleAddSection() {
    if (!draft.isValid()) return;
    const data = draft.toJSON();
    const sections = data.sections || [];
    const select = document.querySelector('.add-section-type');
    const sectionType = select ? select.value : 'general';
    const nextOrder = sections.length + 1;

    const newSection = {
      id: `sec-${Date.now()}`,
      title: 'قسم جديد',
      type: sectionType,
      order: nextOrder,
      blocks: []
    };

    sections.push(newSection);
    sections.forEach((s, i) => { s.order = i + 1; });
    draft.setField('sections', sections);
    renderSections();
    updatePreview();
    showToast('✅ تم إضافة القسم بنجاح', 'success');
  }

  function handleRemoveSection(btn) {
    if (!draft.isValid()) return;
    const sectionIdx = parseInt(btn.dataset.sectionIdx, 10);
    if (isNaN(sectionIdx)) return;

    if (!confirm('هل أنت متأكد من حذف هذا القسم وكل الكتل داخله؟')) return;

    const data = draft.toJSON();
    const sections = data.sections || [];
    if (sectionIdx < 0 || sectionIdx >= sections.length) return;

    sections.splice(sectionIdx, 1);
    sections.forEach((s, i) => { s.order = i + 1; });
    draft.setField('sections', sections);
    renderSections();
    updatePreview();
    showToast('✅ تم حذف القسم', 'success');
  }

  function handleMoveBlock(btn, direction) {
    if (!draft.isValid()) return;
    const sectionIdx = parseInt(btn.dataset.sectionIdx, 10);
    const blockIdx = parseInt(btn.dataset.blockIdx, 10);
    if (isNaN(sectionIdx) || isNaN(blockIdx)) return;

    const data = draft.toJSON();
    const sections = data.sections || [];
    if (!sections[sectionIdx]) return;
    const blocks = sections[sectionIdx].blocks || [];

    const targetIdx = direction === 'up' ? blockIdx - 1 : blockIdx + 1;
    if (targetIdx < 0 || targetIdx >= blocks.length) return;

    [blocks[blockIdx], blocks[targetIdx]] = [blocks[targetIdx], blocks[blockIdx]];

    blocks.forEach((b, i) => { b.order = i + 1; });

    draft.setField(`sections.${sectionIdx}.blocks`, blocks);
    renderSections();
    updatePreview();
    showToast('✅ تم تغيير الترتيب', 'success');
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
