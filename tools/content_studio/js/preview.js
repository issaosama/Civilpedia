class PreviewRenderer {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
  }

  render(draft) {
    if (!draft || !draft.isValid()) {
      this.container.innerHTML = '<div class="preview-empty">قم بتحميل ملف Draft لعرض المعاينة</div>';
      return;
    }
    const data = draft.toJSON();
    const topic = data.topic || {};
    const sections = data.sections || [];
    const html = this._renderTopic(topic) + this._renderSections(sections, data) + this._renderMistakes(topic) + this._renderAcceptReject(topic);
    this.container.innerHTML = html;
  }

  clear() {
    this.container.innerHTML = '<div class="preview-empty">قم بتحميل ملف Draft لعرض المعاينة</div>';
  }

  _renderTopic(topic) {
    const levelBadge = topic.level ? `<span class="preview-badge preview-badge-${topic.level}">${topic.level}</span>` : '';
    const planBadge = topic.planKey ? `<span class="preview-badge preview-badge-plan">${topic.planKey}</span>` : '';
    const tags = topic.tags && Array.isArray(topic.tags)
      ? topic.tags.map(t => `<span class="preview-tag">${this._escape(t)}</span>`).join('')
      : '';

    return `
      <div class="preview-section preview-header">
        <h1 class="preview-title-ar">${this._escape(topic.titleAr || '')}</h1>
        <h2 class="preview-title-en">${this._escape(topic.titleEn || '')}</h2>
        <div class="preview-badges">${levelBadge} ${planBadge}</div>
        <div class="preview-tags">${tags}</div>
        <p class="preview-summary">${this._escape(topic.summaryAr || topic.summary || '')}</p>
      </div>
    `;
  }

  _renderSections(sections, data) {
    if (!sections.length) return '<div class="preview-empty">لا توجد أقسام</div>';

    let html = '';
    for (const section of sections) {
      html += this._renderSection(section, data);
    }
    return html;
  }

  _renderSection(section, data) {
    const typeLabel = SECTION_TYPE_LABELS[section.type] || section.type;
    const blocks = section.blocks || [];

    let blocksHtml = '';
    for (const block of blocks) {
      blocksHtml += this._renderBlock(block, data);
    }

    return `
      <div class="preview-section preview-section-block">
        <div class="preview-section-header">
          <span class="preview-section-type">${typeLabel}</span>
          <h3 class="preview-section-title">${this._escape(section.title)}</h3>
        </div>
        <div class="preview-section-content">
          ${blocksHtml}
        </div>
      </div>
    `;
  }

  _renderBlock(block, data) {
    switch (block.type) {
      case 'text':
        return this._renderTextBlock(block);
      case 'execution_step':
        return this._renderExecutionStep(block);
      case 'safety_note':
        return this._renderSafetyNote(block);
      case 'table':
        return this._renderTable(block);
      case 'checklist':
        return this._renderChecklist(block);
      case 'inspection_point':
        return this._renderInspectionPoint(block);
      case 'image':
        return this._renderImage(block);
      case 'equipment':
        return this._renderEquipment(block);
      case 'code_reference':
        return this._renderCodeReference(block);
      default:
        return `<div class="preview-block preview-unknown">${this._escape(block.type || 'نوع غير معروف')}</div>`;
    }
  }

  _renderTextBlock(block) {
    const content = block.content || {};
    const text = content.ar || '';
    const variant = block.variant || 'paragraph';
    const cls = `preview-text preview-text-${variant}`;
    return `<div class="${cls}">${this._escape(text)}</div>`;
  }

  _renderExecutionStep(block) {
    const desc = block.description || {};
    const notes = block.notes || {};
    const stepNum = block.stepNumber || '?';
    const noteHtml = notes.ar ? `<div class="preview-step-note">💡 ${this._escape(notes.ar)}</div>` : '';
    return `
      <div class="preview-step">
        <div class="preview-step-number">${stepNum}</div>
        <div class="preview-step-body">
          <div class="preview-step-desc">${this._escape(desc.ar || '')}</div>
          ${noteHtml}
        </div>
      </div>
    `;
  }

  _renderSafetyNote(block) {
    const msg = block.message || {};
    const severity = block.severity || 'medium';
    const severityLabel = SEVERITY_LABELS[severity] || severity;
    return `
      <div class="preview-safety preview-safety-${severity}">
        <div class="preview-safety-icon">⚠️</div>
        <div class="preview-safety-body">
          <div class="preview-safety-severity">${severityLabel}</div>
          <div class="preview-safety-msg">${this._escape(msg.ar || '')}</div>
        </div>
      </div>
    `;
  }

  _renderTable(block) {
    const caption = block.caption ? (block.caption.ar || '') : '';
    const headers = block.headers || [];
    const rows = block.rows || [];
    let thead = '';
    if (headers.length) {
      thead = '<thead><tr>' + headers.map(h => `<th>${this._escape(h)}</th>`).join('') + '</tr></thead>';
    }
    let tbody = '';
    if (rows.length) {
      tbody = '<tbody>' + rows.map(row => {
        const cells = row.cells || [];
        return '<tr>' + cells.map(c => `<td>${this._escape(c)}</td>`).join('') + '</tr>';
      }).join('') + '</tbody>';
    }
    return `
      <div class="preview-table-wrapper">
        ${caption ? `<div class="preview-table-caption">${this._escape(caption)}</div>` : ''}
        <table class="preview-table">
          ${thead}
          ${tbody}
        </table>
        ${this._noTableData(headers, rows)}
      </div>
    `;
  }

  _noTableData(headers, rows) {
    if (headers.length > 0 && rows.length > 0) return '';
    return '<div class="preview-empty-inline">⚠️ جدول بدون بيانات</div>';
  }

  _renderChecklist(block) {
    const title = block.title ? (block.title.ar || '') : '';
    const items = block.items || [];
    if (items.length === 0) {
      return `
        <div class="preview-checklist">
          ${title ? `<div class="preview-checklist-title">${this._escape(title)}</div>` : ''}
          <div class="preview-empty-inline">⚠️ قائمة الفحص فارغة — يرجى إضافة بنود</div>
        </div>
      `;
    }
    const listHtml = items.map(item => {
      const required = item.isRequired !== false;
      return `<div class="preview-checklist-item ${required ? 'preview-checklist-required' : ''}">
        <span class="preview-checklist-check">${required ? '☐' : '◻'}</span>
        <span>${this._escape(item.textAr || item.text || '')}</span>
      </div>`;
    }).join('');
    return `
      <div class="preview-checklist">
        ${title ? `<div class="preview-checklist-title">${this._escape(title)}</div>` : ''}
        ${listHtml}
      </div>
    `;
  }

  _renderInspectionPoint(block) {
    const isCritical = block.isCritical;
    const icon = isCritical ? '🔴' : '🟡';
    return `
      <div class="preview-inspection">
        <div class="preview-inspection-header">
          ${icon} <strong>${this._escape(block.criteriaAr || '')}</strong>
        </div>
        <div class="preview-inspection-detail">
          القبول: ${this._escape(block.acceptanceLimitAr || '')}<br>
          الطريقة: ${this._escape(block.methodAr || '')}
        </div>
      </div>
    `;
  }

  _renderImage(block) {
    return `
      <div class="preview-image-placeholder">
        <div class="preview-image-icon">🖼️</div>
        <div>${this._escape(block.url || '')}</div>
        ${block.caption ? `<div class="preview-image-caption">${this._escape(block.caption.ar || '')}</div>` : ''}
      </div>
    `;
  }

  _renderEquipment(block) {
    const items = block.items || [];
    if (items.length === 0) return '<div class="preview-empty-inline">⚠️ قائمة المعدات فارغة</div>';
    const list = items.map(item => {
      return `<div class="preview-equipment-item">
        <strong>${this._escape(item.nameAr || '')}</strong>
        ${item.specification ? `— ${this._escape(item.specification)}` : ''}
        ${item.purpose ? `<br><em>${this._escape(item.purpose)}</em>` : ''}
      </div>`;
    }).join('');
    return `<div class="preview-equipment">${list}</div>`;
  }

  _renderCodeReference(block) {
    const title = block.title || {};
    return `
      <div class="preview-code-ref">
        <strong>${this._escape(block.code || '')}</strong>
        ${title.ar ? `— ${this._escape(title.ar)}` : ''}
        ${block.excerpt ? `<br><em>${this._escape(block.excerpt.ar || '')}</em>` : ''}
      </div>
    `;
  }

  _renderMistakes(topic) {
    const mistakes = topic.commonMistakes;
    if (!mistakes || !mistakes.length) return '';
    const items = mistakes.map(m => `
      <li class="preview-mistake-item">
        <span class="preview-mistake-icon">❌</span>
        <span>${this._escape(m.ar || '')}</span>
      </li>
    `).join('');
    return `
      <div class="preview-section preview-section-block">
        <div class="preview-section-header">
          <h3 class="preview-section-title">الأخطاء الشائعة</h3>
        </div>
        <ul class="preview-mistakes">${items}</ul>
      </div>
    `;
  }

  _renderAcceptReject(topic) {
    const items = topic.acceptRejectItems;
    if (!items || !items.length) return '';
    const rows = items.map(item => {
      const critical = item.isCritical ? '🔴' : '🟡';
      return `<tr>
        <td>${critical}</td>
        <td>${this._escape(item.criteriaAr || '')}</td>
        <td>${this._escape(item.acceptanceLimitAr || '')}</td>
        <td>${this._escape(item.methodAr || '')}</td>
      </tr>`;
    }).join('');
    return `
      <div class="preview-section preview-section-block">
        <div class="preview-section-header">
          <h3 class="preview-section-title">معايير القبول والرفض</h3>
        </div>
        <table class="preview-table preview-table-small">
          <thead><tr>
            <th></th>
            <th>المعيار</th>
            <th>حد القبول</th>
            <th>طريقة الفحص</th>
          </tr></thead>
          <tbody>${rows}</tbody>
        </table>
      </div>
    `;
  }

  _escape(str) {
    if (str === null || str === undefined) return '';
    const div = document.createElement('div');
    div.textContent = String(str);
    return div.innerHTML;
  }
}
