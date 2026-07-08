class PreviewRenderer {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
    this._sectionNum = 0;
  }

  render(draft) {
    this._sectionNum = 0;
    if (!draft || !draft.isValid()) {
      this.container.innerHTML = '<div class="preview-empty">قم بتحميل ملف Draft لعرض المعاينة</div>';
      return;
    }
    const data = draft.toJSON();
    const topic = data.topic || {};
    const sections = data.sections || [];

    let html = this._renderTopic(topic, data);

    // Overview section (matches Flutter _buildOverviewSection)
    const overviewText = (topic.simpleExplanation && topic.simpleExplanation.ar) || topic.summaryAr || '';
    if (overviewText) {
      html += this._buildSection('OVERVIEW', 'نظرة عامة', `<p class="fp-overview-text">${this._escape(overviewText)}</p>`);
    }

    // Importance section (matches Flutter _buildImportanceSection)
    const siteNotes = topic.siteNotes && topic.siteNotes.ar || '';
    const codeNotes = topic.codeNotes && topic.codeNotes.ar || '';
    if (siteNotes || codeNotes) {
      let itemsHtml = '';
      if (siteNotes) {
        itemsHtml += `<div class="fp-importance-item"><span class="fp-importance-diamond">◆</span><span>${this._escape(siteNotes)}</span></div>`;
      }
      if (codeNotes) {
        itemsHtml += `<div class="fp-importance-item"><span class="fp-importance-diamond">◆</span><span>${this._escape(codeNotes)}</span></div>`;
      }
      html += this._buildSection('IMPORTANCE', 'الأهمية الهندسية', `<div class="fp-importance-card">${itemsHtml}</div>`);
    }

    // Draft sections
    html += this._renderSections(sections, data);

    // Common Mistakes (matches Flutter _buildCommonMistakesSection)
    html += this._renderMistakes(topic);

    // Accept/Reject criteria (matches Flutter _buildInspectionSection)
    html += this._renderAcceptReject(topic);

    this.container.innerHTML = html;
  }

  clear() {
    this._sectionNum = 0;
    this.container.innerHTML = '<div class="preview-empty">قم بتحميل ملف Draft لعرض المعاينة</div>';
  }

  // ─── Preview-only asset path resolver ────────────
  // Content Studio runs from tools/content_studio/, while Flutter asset paths
  // (assets/images/...) are project-root relative. This resolver is preview-only.
  _resolveAssetPath(path) {
    if (!path) return '';
    // Check for ephemeral temp preview (local file picked via file input)
    if (window.__csTempPreviews && window.__csTempPreviews.has(path)) {
      return window.__csTempPreviews.get(path);
    }
    if (path.startsWith('assets/images/')) return '../../' + path;
    if (path.startsWith('./') || path.startsWith('../')) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('data:')) return path;
    return path;
  }

  // ─── Helpers ──────────────────────────────────────

  _nextNum() {
    this._sectionNum++;
    return this._sectionNum < 10 ? '0' + this._sectionNum : String(this._sectionNum);
  }

  _buildSection(kicker, title, bodyHtml) {
    const num = this._nextNum();
    return `
      <div class="fp-section">
        <div class="fp-section-header">
          <div class="fp-accent-bar"></div>
          <span class="fp-section-kicker">${kicker} · ${num}</span>
        </div>
        <h2 class="fp-section-title">${title}</h2>
        <div class="fp-section-body">${bodyHtml}</div>
      </div>
    `;
  }

  _categoryName(id) {
    const names = {
      concrete: 'الخرسانة',
      steel: 'الحديد',
      soil: 'التربة',
      finishing: 'أعمال الإنهاءات'
    };
    return names[id] || id || '';
  }

  // ─── Topic Hero ───────────────────────────────────

  _renderTopic(topic) {
    const category = this._categoryName(topic.categoryId);
    const tags = topic.tags && Array.isArray(topic.tags)
      ? topic.tags.map(t => `<span class="fp-tag">${this._escape(t)}</span>`).join('')
      : '';
    const summary = (topic.simpleExplanation && topic.simpleExplanation.ar) || topic.summaryAr || topic.summary || '';

    // Card preview — mirrors Flutter topic card listing
    const coverImageSrc = this._resolveAssetPath(topic.coverImageUrl || '');
    let cardPreviewHtml = '';
    if (topic.titleAr || topic.coverImageUrl) {
      const thumbHtml = topic.coverImageUrl
        ? `<img src="${this._escape(coverImageSrc)}" alt="" class="fp-card-preview-img" onerror="this.onerror=null;this.style.display='none';this.parentNode.innerHTML='<div class=\\'fp-card-preview-fallback\\'>📖</div>'">`
        : '<div class="fp-card-preview-fallback">📖</div>';
      cardPreviewHtml = `
        <div class="fp-card-preview">
          <div class="fp-card-preview-label">📋 معاينة البطاقة في قائمة الموسوعة</div>
          <div class="fp-card-preview-card">
            <div class="fp-card-preview-thumb">${thumbHtml}</div>
            <div class="fp-card-preview-info">
              <div class="fp-card-preview-title">${this._escape(topic.titleAr || '')}</div>
              ${summary ? `<div class="fp-card-preview-summary">${this._escape(summary).substring(0, 80)}…</div>` : ''}
            </div>
          </div>
        </div>
      `;
    }

    // Hero cover — polished hero position
    let coverHtml = '';
    if (topic.coverImageUrl) {
      coverHtml = `
        <div class="fp-cover">
          <img src="${this._escape(coverImageSrc)}" alt="" class="fp-cover-img"
            onerror="this.onerror=null;this.style.display='none';this.nextElementSibling.style.display='flex'" />
          <div class="fp-cover-placeholder" style="display:none">
            <div class="fp-cover-placeholder-icon">🖼️</div>
            <div class="fp-cover-placeholder-label">الصورة غير موجودة أو لم يتم إضافتها بعد</div>
            <div class="fp-cover-placeholder-path">${this._escape(topic.coverImageUrl)}</div>
          </div>
        </div>
      `;
    }

    return `
      ${cardPreviewHtml}
      ${coverHtml}
      <div class="fp-hero">
        ${category ? `<div class="fp-category">${this._escape(category)}</div>` : ''}
        <h1 class="fp-title">${this._escape(topic.titleAr || '')}</h1>
        ${summary ? `<p class="fp-summary">${this._escape(summary)}</p>` : ''}
        ${tags ? `<div class="fp-tags">${tags}</div>` : ''}
      </div>
    `;
  }

  // ─── Sections ─────────────────────────────────────

  _renderSections(sections, data) {
    let html = '';
    for (const section of sections) {
      html += this._renderSection(section, data);
    }
    return html;
  }

  _sectionKicker(type) {
    const map = {
      general: 'GENERAL',
      execution: 'APPLICATION',
      safety: 'SAFETY',
      inspection: 'INSPECTION',
      equipment: 'EQUIPMENT',
      codeReference: 'CODE REFERENCE'
    };
    return map[type] || (type ? type.toUpperCase() : '');
  }

  _renderSection(section, data) {
    const kicker = this._sectionKicker(section.type);
    const blocks = section.blocks || [];
    const num = this._nextNum();

    let blocksHtml = '';
    for (const block of blocks) {
      blocksHtml += this._renderBlock(block, data);
    }

    return `
      <div class="fp-section">
        <div class="fp-section-header">
          <div class="fp-accent-bar"></div>
          <span class="fp-section-kicker">${kicker} · ${num}</span>
        </div>
        <h2 class="fp-section-title">${this._escape(section.title)}</h2>
        <div class="fp-section-body">
          ${blocksHtml || '<div class="fp-empty-inline">⚠️ لا توجد كتل في هذا القسم</div>'}
        </div>
      </div>
    `;
  }

  // ─── Block Router ─────────────────────────────────

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
        return `<div class="fp-text">${this._escape(block.type || 'نوع غير معروف')}</div>`;
    }
  }

  // ─── Block Renderers ──────────────────────────────

  _renderTextBlock(block) {
    const content = block.content || {};
    const text = content.ar || '';
    return `<div class="fp-text">${this._escape(text)}</div>`;
  }

  _renderExecutionStep(block) {
    const desc = block.description || {};
    const notes = block.notes || {};
    const stepNum = block.stepNumber || '?';
    const noteHtml = notes.ar ? `<div class="fp-step-note">💡 ${this._escape(notes.ar)}</div>` : '';
    return `
      <div class="fp-step">
        <div class="fp-step-number">${stepNum}</div>
        <div class="fp-step-body">
          <div class="fp-step-desc">${this._escape(desc.ar || '')}</div>
          ${noteHtml}
        </div>
      </div>
    `;
  }

  _renderSafetyNote(block) {
    const msg = block.message || {};
    return `
      <div class="fp-safety">
        <div class="fp-safety-icon">⚠️</div>
        <div class="fp-safety-body">
          <div class="fp-safety-text">${this._escape(msg.ar || '')}</div>
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
      <div class="fp-table-wrapper">
        ${caption ? `<div class="fp-table-caption">${this._escape(caption)}</div>` : ''}
        <table class="fp-table">
          ${thead}
          ${tbody}
        </table>
        ${this._noTableData(headers, rows)}
      </div>
    `;
  }

  _noTableData(headers, rows) {
    if (headers.length > 0 && rows.length > 0) return '';
    return '<div class="fp-empty-inline">⚠️ جدول بدون بيانات</div>';
  }

  _renderChecklist(block) {
    const title = block.title ? (block.title.ar || '') : '';
    const items = block.items || [];
    if (items.length === 0) {
      return `
        <div class="fp-checklist">
          ${title ? `<div class="fp-checklist-title">${this._escape(title)}</div>` : ''}
          <div class="fp-empty-inline">⚠️ قائمة الفحص فارغة — يرجى إضافة بنود</div>
        </div>
      `;
    }
    const listHtml = items.map(item => {
      const required = item.isRequired !== false;
      return `<div class="fp-checklist-item">
        <span class="fp-checklist-check">${required ? '☐' : '◻'}</span>
        <span>${this._escape(item.textAr || item.text || '')}</span>
      </div>`;
    }).join('');
    return `
      <div class="fp-checklist">
        ${title ? `<div class="fp-checklist-title">${this._escape(title)}</div>` : ''}
        <div class="fp-checklist-card">${listHtml}</div>
      </div>
    `;
  }

  _renderInspectionPoint(block) {
    const isCritical = block.isCritical;
    const icon = isCritical ? '🔴' : '🟡';
    return `
      <div class="fp-inspection">
        <div class="fp-inspection-row">
          <span class="fp-inspection-icon ${isCritical ? 'fp-inspection-critical' : 'fp-inspection-regular'}">${icon}</span>
          <div>
            <strong>${this._escape(block.criteriaAr || '')}</strong><br>
            <span class="fp-text-muted">القبول: ${this._escape(block.acceptanceLimitAr || '')} | الطريقة: ${this._escape(block.methodAr || '')}</span>
          </div>
        </div>
      </div>
    `;
  }

  _renderImage(block) {
    const url = block.url || '';
    const caption = block.caption ? (block.caption.ar || '') : '';
    if (!url && !caption) return '';
    const resolvedSrc = this._resolveAssetPath(url);
    let innerHtml;
    if (url) {
      innerHtml = `<img src="${this._escape(resolvedSrc)}" alt="${this._escape(caption)}" class="fp-image-img" onerror="this.onerror=null;this.style.display='none';this.nextElementSibling.style.display='block'" /><div class="fp-image-empty" style="display:none"><div class="fp-image-icon">🖼️</div><div class="fp-image-placeholder-label">الصورة غير موجودة أو لم يتم إضافتها بعد</div><div class="fp-image-path">${this._escape(url)}</div></div>`;
    } else {
      innerHtml = '<div class="fp-image-empty"><div class="fp-image-icon">🖼️</div><div class="fp-image-placeholder-label">الصورة غير موجودة أو لم يتم إضافتها بعد</div></div>';
    }
    if (caption) {
      innerHtml += `<div class="fp-image-caption">${this._escape(caption)}</div>`;
    }
    return `<div class="fp-image">${innerHtml}</div>`;
  }

  _renderEquipment(block) {
    const items = block.items || [];
    if (items.length === 0) return '<div class="fp-empty-inline">⚠️ قائمة المعدات فارغة</div>';
    const list = items.map(item => {
      let html = `<div class="fp-equipment-item"><strong>${this._escape(item.nameAr || '')}</strong>`;
      if (item.specification) html += ` <span class="fp-equipment-spec">— ${this._escape(item.specification)}</span>`;
      if (item.purpose) html += `<br><span class="fp-equipment-purpose">${this._escape(item.purpose)}</span>`;
      html += '</div>';
      return html;
    }).join('');
    return `<div class="fp-equipment">${list}</div>`;
  }

  _renderCodeReference(block) {
    const title = block.title || {};
    let html = `<div class="fp-code-ref"><strong>${this._escape(block.code || '')}</strong>`;
    if (title.ar) html += ` — ${this._escape(title.ar)}`;
    if (block.excerpt) html += `<br><em>${this._escape(block.excerpt.ar || '')}</em>`;
    html += '</div>';
    return html;
  }

  // ─── Common Mistakes ──────────────────────────────

  _renderMistakes(topic) {
    const mistakes = topic.commonMistakes;
    if (!mistakes || !mistakes.length) return '';
    const items = mistakes.map(m => `
      <div class="fp-mistake-item">
        <span class="fp-mistake-icon">×</span>
        <span>${this._escape(m.ar || '')}</span>
      </div>
    `).join('');
    return this._buildSection('COMMON MISTAKES', 'أخطاء شائعة يجب تجنبها', `<div class="fp-mistakes">${items}</div>`);
  }

  // ─── Accept / Reject ──────────────────────────────

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
    return this._buildSection('INSPECTION', 'معايير القبول والرفض', `
      <div class="fp-table-wrapper">
        <table class="fp-table fp-table-small">
          <thead><tr>
            <th></th>
            <th>المعيار</th>
            <th>حد القبول</th>
            <th>طريقة الفحص</th>
          </tr></thead>
          <tbody>${rows}</tbody>
        </table>
      </div>
    `);
  }

  // ─── Escape ───────────────────────────────────────

  _escape(str) {
    if (str === null || str === undefined) return '';
    const div = document.createElement('div');
    div.textContent = String(str);
    return div.innerHTML;
  }
}
