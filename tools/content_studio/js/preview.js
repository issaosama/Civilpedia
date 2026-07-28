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
      execution: 'EXECUTION',
      safety: 'SAFETY',
      inspection: 'INSPECTION',
      equipment: 'EQUIPMENT',
      codeReference: 'CODE REFERENCE',
      commonMistakes: 'COMMON MISTAKES',
      acceptance: 'ACCEPTANCE CRITERIA',
      rejection: 'REJECTION CRITERIA',
      bestPractice: 'BEST PRACTICE',
      siteNotes: 'SITE NOTES',
      quality: 'QUALITY CONTROL',
      coordination: 'COORDINATION',
      report: 'REPORT'
    };
    return map[type] || (type ? type.toUpperCase() : '');
  }

  _firstBlockLabel(blocks) {
    if (!blocks || blocks.length === 0) return 'القسم';
    const b = blocks[0];
    if (b.type === 'text') {
      const variant = b.variant;
      if (variant === 'note') return 'ملاحظة';
      if (variant === 'tip') return 'نصيحة';
      if (variant === 'warning') return 'تنبيه';
      return 'نص';
    }
    const map = {
      table: 'جدول',
      equipment: 'معدات',
      execution_step: 'خطوة تنفيذ',
      inspection_point: 'نقطة فحص',
      checklist: 'قائمة فحص',
      safety_note: 'ملاحظة سلامة',
      code_reference: 'مرجع كود',
      image: 'صورة',
      common_mistakes: 'أخطاء شائعة',
      acceptance_criteria: 'معايير قبول',
      rejection_criteria: 'معايير رفض'
    };
    return map[b.type] || 'القسم';
  }

  _renderSection(section, data) {
    const kicker = this._sectionKicker(section.type);
    const blocks = section.blocks || [];
    const num = this._nextNum();
    const badgeLabel = this._firstBlockLabel(blocks);

    let blocksHtml = '';
    for (const block of blocks) {
      blocksHtml += this._renderBlock(block, data);
    }

    return `
      <div class="fp-section">
        <div class="fp-section-header">
          <div class="fp-accent-bar"></div>
          <span class="fp-section-kicker">${kicker} · ${num}</span>
          <span class="fp-section-type-badge">${badgeLabel}</span>
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
      case 'common_mistakes':
        return this._renderCommonMistakes(block);
      case 'acceptance_criteria':
        return this._renderAcceptanceCriteria(block);
      case 'rejection_criteria':
        return this._renderRejectionCriteria(block);
      default:
        return `<div class="fp-text">${this._escape(block.type || 'نوع غير معروف')}</div>`;
    }
  }

  // ─── Block Renderers ──────────────────────────────

  _renderTextBlock(block) {
    const content = block.content || {};
    const text = content.ar || '';
    const variant = block.variant;
    if (variant && variant !== 'paragraph') {
      const vc = this._variantConfig(variant);
      if (vc) {
        return `
          <div class="fp-variant-card fp-variant-${vc.cssClass}">
            <span class="fp-variant-icon">${vc.icon}</span>
            <div class="fp-variant-content">
              <div class="fp-variant-label">${vc.label}</div>
              <div class="fp-variant-text">${this._escape(text)}</div>
            </div>
          </div>`;
      }
    }
    return `<div class="fp-text">${this._escape(text)}</div>`;
  }

  _variantConfig(variant) {
    const map = {
      note:    { cssClass: 'note',    icon: 'ℹ️',  label: 'ملاحظة' },
      tip:     { cssClass: 'tip',     icon: '💡', label: 'نصيحة' },
      warning: { cssClass: 'warning', icon: '⚠️', label: 'تنبيه' },
    };
    return map[variant] || { cssClass: 'note', icon: 'ℹ️', label: 'ملاحظة' };
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
    const text = msg.ar || '';
    if (!text) return '';
    const sev = block.severity || 'medium';
    const cfg = this._severityConfig(sev);
    return `
      <div class="fp-safety fp-safety-${sev}">
        <div class="fp-safety-icon fp-safety-icon-${sev}">${cfg.icon}</div>
        <div class="fp-safety-body">
          <div class="fp-safety-label fp-safety-label-${sev}">${cfg.label}</div>
          <div class="fp-safety-text">${this._escape(text)}</div>
        </div>
      </div>
    `;
  }

  _severityConfig(severity) {
    const map = {
      none:     { icon: '',   label: '' },
      low:      { icon: '✓',  label: 'منخفض' },
      medium:   { icon: '⚠',  label: 'متوسط' },
      high:     { icon: '✗',  label: 'عالي' },
      critical: { icon: '!!', label: 'خطير' },
    };
    return map[severity] || map.medium;
  }

  _renderTable(block) {
    const headers = block.headers || [];
    const rows = block.rows || [];
    if (!headers.length || !rows.length) return '';
    const caption = block.caption ? (block.caption.ar || '') : '';
    const thead = '<thead><tr>' + headers.map(h => `<th>${this._escape(h)}</th>`).join('') + '</tr></thead>';
    const tbody = '<tbody>' + rows.map(row => {
      const cells = row.cells || [];
      return '<tr>' + cells.map(c => `<td>${this._escape(c)}</td>`).join('') + '</tr>';
    }).join('') + '</tbody>';
    return `
      <div class="fp-table-wrapper">
        ${caption ? `<div class="fp-table-caption">${this._escape(caption)}</div>` : ''}
        <table class="fp-table">
          ${thead}
          ${tbody}
        </table>
      </div>
    `;
  }

  _renderChecklist(block) {
    const title = block.title ? (block.title.ar || '') : '';
    const items = block.items || [];
    if (items.length === 0) return '';
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

  // ─── Marker helpers ──────────────────────────────

  _markerHtml(markerStyle, isCritical, markerColorMode) {
    const style = markerStyle || (isCritical ? 'critical' : 'inspection');
    const map = {
      neutral:    { bg: '#9E9E9E', symbol: '•', syFg: '#FFFFFF' },
      inspection: { bg: '#EF6C00', symbol: '!', syFg: '#FFFFFF' },
      info:       { bg: '#1976D2', symbol: 'i', syFg: '#FFFFFF' },
      warning:    { bg: '#F9A825', symbol: '!', syFg: '#1A1A1A' },
      critical:   { bg: '#D32F2F', symbol: '!', syFg: '#FFFFFF' },
      success:    { bg: '#388E3C', symbol: '✓', syFg: '#FFFFFF' },
      diamond:    { bg: '#2E7D32', symbol: '◆', syFg: '#FFFFFF' },
      triangle:   { bg: '#1565C0', symbol: '▲', syFg: '#FFFFFF' },
      square:     { bg: '#6A1B9A', symbol: '■', syFg: '#FFFFFF' },
      target:     { bg: '#C62828', symbol: '◎', syFg: '#FFFFFF' },
    };
    const m = map[style] || map.inspection;
    const isSemantic = markerColorMode === 'semantic';
    const bg = isSemantic ? m.bg : 'var(--topic-accent)';
    const syFg = isSemantic ? m.syFg : '#FFFFFF';
    return `<span class="fp-marker" style="display:inline-flex;align-items:center;justify-content:center;width:22px;height:22px;border-radius:50%;background:${bg};color:${syFg};font-size:12px;font-weight:bold;flex-shrink:0;line-height:1;">${m.symbol}</span>`;
  }

  _renderInspectionPoint(block) {
    const markerHtml = this._markerHtml(block.markerStyle, block.isCritical, block.markerColorMode);
    const criticalBadge = block.isCritical ? '<span class="fp-inspection-critical-badge">حرج</span>' : '';
    return `
      <div class="fp-inspection">
        <div class="fp-inspection-row">
          ${markerHtml}
          <div style="margin-right:8px;flex:1;">
            <strong>${this._escape(block.criteriaAr || '')}</strong> ${criticalBadge}<br>
            <span class="fp-text-muted">القبول: ${this._escape(block.acceptableTolerance || '')} | الطريقة: ${this._escape(block.methodAr || '')}</span>
          </div>
        </div>
      </div>
    `;
  }

  _renderImage(block) {
    const url = block.url || '';
    if (!url) return '';
    const caption = block.caption ? (block.caption.ar || '') : '';
    const resolvedSrc = this._resolveAssetPath(url);
    let innerHtml = `<img src="${this._escape(resolvedSrc)}" alt="${this._escape(caption)}" class="fp-image-img" onerror="this.onerror=null;this.style.display='none';this.nextElementSibling.style.display='block'" /><div class="fp-image-empty" style="display:none"><div class="fp-image-icon">🖼️</div><div class="fp-image-placeholder-label">الصورة غير موجودة أو لم يتم إضافتها بعد</div><div class="fp-image-path">${this._escape(url)}</div></div>`;
    if (caption) {
      innerHtml += `<div class="fp-image-caption">${this._escape(caption)}</div>`;
    }
    return `<div class="fp-image">${innerHtml}</div>`;
  }

  _renderEquipment(block) {
    const items = block.items || [];
    if (items.length === 0) return '';
    const list = items.map(item => {
      let html = `<div class="fp-equipment-item"><strong>${this._escape(item.nameAr || '')}</strong>`;
      if (item.specification) html += ` <span class="fp-equipment-spec">— ${this._escape(item.specification)}</span>`;
      if (item.purpose) html += `<br><span class="fp-equipment-purpose">${this._escape(item.purpose)}</span>`;
      html += '</div>';
      return html;
    }).join('');
    return `<div class="fp-equipment">${list}</div>`;
  }

  _renderCommonMistakes(block) {
    const items = block.items || [];
    if (items.length === 0) return '';
    const list = items.map(item => `
      <div class="fp-mistakes-item">
        <span class="fp-mistakes-marker">✕</span>
        <span class="fp-mistakes-text">${this._escape(item.textAr || '')}</span>
      </div>
    `).join('');
    return `
      <div class="fp-mistakes-block">
        <div class="fp-mistakes-title">${this._escape(block.title || 'الأخطاء الشائعة')}</div>
        <div class="fp-mistakes-list">${list}</div>
      </div>
    `;
  }

  _renderAcceptanceCriteria(block) {
    const items = block.items || [];
    if (items.length === 0) return '';
    const list = items.map(item => `
      <div class="fp-callout-item">
        <span class="fp-callout-icon fp-callout-icon-success">✓</span>
        <span class="fp-callout-text">${this._escape(item.textAr || '')}</span>
      </div>
    `).join('');
    return `
      <div class="fp-callout fp-acceptance-block">
        <div class="fp-callout-header">
          <span class="fp-callout-header-icon">✅</span>
          <span class="fp-callout-header-label">${block.title || 'معايير القبول'}</span>
        </div>
        <div class="fp-callout-body">${list}</div>
      </div>
    `;
  }

  _renderRejectionCriteria(block) {
    const items = block.items || [];
    if (items.length === 0) return '';
    const list = items.map(item => `
      <div class="fp-callout-item">
        <span class="fp-callout-icon fp-callout-icon-danger">⛔</span>
        <span class="fp-callout-text">${this._escape(item.textAr || '')}</span>
      </div>
    `).join('');
    return `
      <div class="fp-callout fp-rejection-block">
        <div class="fp-callout-header">
          <span class="fp-callout-header-icon">⛔</span>
          <span class="fp-callout-header-label">${block.title || 'معايير الرفض'}</span>
        </div>
        <div class="fp-callout-body">${list}</div>
      </div>
    `;
  }

  _renderCodeReference(block) {
    const title = block.title || {};
    const codeStr = block.code || '';
    const refs = codeStr.split('/').map(s => s.trim()).filter(s => s.length > 0);
    const isMulti = refs.length > 1;
    const hasRefs = refs.length > 0;
    const headerText = (title.ar && title.ar.trim()) ? title.ar : codeStr;

    let headerHtml = `<span class="fp-code-ref-title">${this._escape(headerText)}</span>`;
    if (block.section) {
      headerHtml += `<span class="fp-code-ref-section">القسم ${this._escape(block.section)}</span>`;
    }
    let html = `<div class="fp-code-ref"><div class="fp-code-ref-header">${headerHtml}</div>`;

    if (hasRefs) {
      html += '<div class="fp-code-ref-divider"></div>';
      if (isMulti) {
        let chipsHtml = '';
        for (const ref of refs) {
          chipsHtml += `<span class="fp-code-ref-chip">${this._escape(ref)}</span>`;
        }
        html += '<div class="fp-code-ref-references">';
        html += '<div class="fp-code-ref-references-label">🏷 المراجع</div>';
        html += `<div class="fp-code-ref-chips">${chipsHtml}</div>`;
        html += '</div>';
      } else {
        html += `<span class="fp-code-ref-code-badge">${this._escape(codeStr)}</span>`;
      }
    }

    if (block.excerpt) {
      html += `<div class="fp-code-ref-excerpt"><em>${this._escape(block.excerpt.ar || '')}</em></div>`;
    }
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

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { PreviewRenderer };
}
