class InlineBlockEditor {
  static EDITING_CLASS = 'inline-editor';

  static getEditorHtml(sectionIdx, blockIdx, block) {
    switch (block.type) {
      case 'text': return this._textEditor(sectionIdx, blockIdx, block);
      case 'execution_step': return this._executionStepEditor(sectionIdx, blockIdx, block);
      case 'safety_note': return this._safetyNoteEditor(sectionIdx, blockIdx, block);
      case 'table': return this._tableEditor(sectionIdx, blockIdx, block);
      case 'image': return this._imageEditor(sectionIdx, blockIdx, block);
      case 'checklist': return this._checklistEditor(sectionIdx, blockIdx, block);
      case 'inspection_point': return this._inspectionPointEditor(sectionIdx, blockIdx, block);
      case 'code_reference': return this._codeReferenceEditor(sectionIdx, blockIdx, block);
      case 'equipment': return this._equipmentEditor(sectionIdx, blockIdx, block);
      default: return '';
    }
  }

  static _textEditor(sectionIdx, blockIdx, block) {
    const content = block.content || {};
    return `
      <div class="${this.EDITING_CLASS}" data-section-idx="${sectionIdx}" data-block-idx="${blockIdx}">
        <div class="inline-header">✏️ تحرير النص</div>
        <div class="inline-body">
          <div class="inline-field">
            <label>المحتوى</label>
            <textarea class="form-textarea ie-input" data-field="content.ar" dir="rtl" rows="4">${esc(content.ar || '')}</textarea>
          </div>
        </div>
        <div class="inline-actions">
          <button class="btn btn-success ie-save" type="button">💾 حفظ</button>
          <button class="btn btn-outline ie-cancel" type="button">إلغاء</button>
        </div>
      </div>
    `;
  }

  static _executionStepEditor(sectionIdx, blockIdx, block) {
    const desc = block.description || {};
    const notes = block.notes || {};
    return `
      <div class="${this.EDITING_CLASS}" data-section-idx="${sectionIdx}" data-block-idx="${blockIdx}">
        <div class="inline-header">✏️ تحرير الخطوة التنفيذية</div>
        <div class="inline-body">
          <div class="inline-field inline-field-short">
            <label>رقم الخطوة</label>
            <input type="number" class="form-input ie-input" data-field="stepNumber" value="${block.stepNumber || 1}" min="1">
          </div>
          <div class="inline-field">
            <label>الوصف</label>
            <textarea class="form-textarea ie-input" data-field="description.ar" dir="rtl" rows="3">${esc(desc.ar || '')}</textarea>
          </div>
          <div class="inline-field">
            <label>ملاحظات</label>
            <textarea class="form-textarea ie-input" data-field="notes.ar" dir="rtl" rows="2">${esc(notes.ar || '')}</textarea>
          </div>
        </div>
        <div class="inline-actions">
          <button class="btn btn-success ie-save" type="button">💾 حفظ</button>
          <button class="btn btn-outline ie-cancel" type="button">إلغاء</button>
        </div>
      </div>
    `;
  }

  static _imageEditor(sectionIdx, blockIdx, block) {
    const url = block.url || '';
    const caption = block.caption ? (block.caption.ar || '') : '';
    const urlInputId = `ie-img-url-${sectionIdx}-${blockIdx}`;
    const fileInputId = `ie-img-file-${sectionIdx}-${blockIdx}`;
    const previewId = `ie-img-prev-${sectionIdx}-${blockIdx}`;
    const previewHtml = url
      ? `<div id="${previewId}" class="image-editor-preview"><img src="${esc(url)}" alt="" style="max-width:100%;max-height:200px;border-radius:6px;border:1px solid #ddd;" onerror="this.style.display='none';this.nextElementSibling.style.display='block'"><div style="display:none;color:#999;font-size:12px;">⚠️ تعذر تحميل الصورة</div></div>`
      : `<div id="${previewId}" class="image-editor-hint" style="color:#999;font-size:12px;">أدخل مسار الصورة داخل assets/images</div>`;
    return `
      <div class="${this.EDITING_CLASS}" data-section-idx="${sectionIdx}" data-block-idx="${blockIdx}">
        <div class="inline-header">✏️ تحرير الصورة</div>
        <div class="inline-body">
          <div class="inline-field">
            <label>مسار الصورة</label>
            <div style="display:flex;gap:6px;align-items:center;">
              <input type="text" id="${urlInputId}" class="form-input ie-input" data-field="url" value="${esc(url)}" placeholder="assets/images/..." dir="ltr" style="flex:1;">
              <button type="button" class="btn btn-outline image-pick-btn" onclick="document.getElementById('${fileInputId}').click()" style="white-space:nowrap;">اختيار صورة</button>
            </div>
            <input type="file" id="${fileInputId}" accept="image/png,image/jpeg,image/webp" style="display:none" onchange="InlineBlockEditor._handleImagePick(this,'${urlInputId}','${previewId}')">
          </div>
          <div class="image-guidance-block">المقاس المقترح: 1200×900 بنسبة 4:3 أو 1200×675 بنسبة 16:9 حسب نوع الصورة.</div>
          <div style="margin-top:4px;font-size:11px;color:#888;line-height:1.6;">
            <strong>إرشاد سريع:</strong><br>
            اضغط "اختيار صورة" وسيتم تعبئة المسار تلقائياً.<br>
            أرسل ملف الصورة مع ملف الـ Draft.<br>
            يفضّل أن يكون اسم الصورة إنكليزي وبدون فراغات.
          </div>
          <div id="img-warn-${previewId}" class="image-warning" style="display:none"></div>
          ${previewHtml}
          <div id="img-return-${previewId}" class="image-return-info" style="display:none"></div>
          <div class="inline-field">
            <label>التعليق (اختياري)</label>
            <textarea class="form-textarea ie-input" data-field="caption.ar" dir="rtl" rows="2">${esc(caption)}</textarea>
          </div>
        </div>
        <div class="inline-actions">
          <button class="btn btn-success ie-save" type="button">💾 حفظ</button>
          <button class="btn btn-outline ie-cancel" type="button">إلغاء</button>
        </div>
      </div>
    `;
  }

  // ─── Temp preview URL registry ────────────────────
  // Maps stored app path (assets/images/...) to ephemeral blob: URL
  // so selected local images appear in preview before files exist in project.
  static _ensureTempRegistry() {
    if (!window.__csTempPreviews) window.__csTempPreviews = new Map();
  }

  static _getTempPreviewUrl(appPath) {
    this._ensureTempRegistry();
    return window.__csTempPreviews.get(appPath);
  }

  // ─── Filename advice warning (non-blocking) ──────
  static _nameWarningMessage(filename) {
    const warns = [];
    if (/\s/.test(filename)) warns.push('المسافات');
    if (/[A-Z]/.test(filename)) warns.push('الأحرف الكبيرة');
    if (/[\u0600-\u06FF]/.test(filename)) warns.push('الأحرف العربية');
    const ext = filename.split('.').pop();
    const allowed = ['png', 'jpg', 'jpeg', 'webp'];
    if (ext && !allowed.includes(ext.toLowerCase())) {
      warns.push('صيغة غير مدعومة');
    }
    if (warns.length === 0) return '';
    return 'ملاحظة: ' + warns.join('، ') + ' — يفضل أن يكون اسم الصورة باللغة الإنكليزية وبحروف صغيرة وبدون مسافات، مثل: slump_cone_photo.jpg';
  }

  // ─── Cover image picker ───────────────────────────
  static _handleCoverPick(fileInput) {
    const file = fileInput.files[0];
    if (!file) return;
    const ext = file.name.toLowerCase().split('.').pop();
    const supported = ['png', 'jpg', 'jpeg', 'webp'];
    if (!supported.includes(ext)) {
      alert('صيغة الصورة غير مدعومة. استخدم PNG أو JPG أو JPEG أو WEBP.');
      fileInput.value = '';
      return;
    }
    const originalName = file.name;
    const appPath = 'assets/images/' + originalName;
    const urlInput = document.querySelector('[data-path="topic.coverImageUrl"]');
    if (!urlInput) return;

    // Store original filename in draft
    urlInput.value = appPath;
    urlInput.dispatchEvent(new Event('change', { bubbles: true }));

    // Register temp preview URL for main preview
    this._ensureTempRegistry();
    const objUrl = URL.createObjectURL(file);
    window.__csTempPreviews.set(appPath, objUrl);

    // Update return-info UI
    const infoDiv = document.getElementById('cover-return-info');
    if (infoDiv) {
      infoDiv.style.display = 'block';
      infoDiv.innerHTML = `
        <div class="image-return-text">تم اختيار الصورة. عند إرسال الملف، أرسل الصورة أيضاً بنفس الاسم:</div>
        <div class="image-return-filename">${esc(originalName)}</div>
        <div class="image-return-path-label">المسار داخل التطبيق: <span dir="ltr">${esc(appPath)}</span></div>
      `;
    }

    // Show name warning if needed
    const warnMsg = this._nameWarningMessage(originalName);
    const warnDiv = document.getElementById('cover-image-warning');
    if (warnDiv) {
      warnDiv.textContent = warnMsg;
      warnDiv.style.display = warnMsg ? 'block' : 'none';
    }

    // Force preview update
    if (window._updatePreview) window._updatePreview();

    fileInput.value = '';
  }

  // ─── Article image picker ─────────────────────────
  static _handleImagePick(fileInput, urlInputId, previewId) {
    const file = fileInput.files[0];
    if (!file) return;
    const ext = file.name.toLowerCase().split('.').pop();
    const supported = ['png', 'jpg', 'jpeg', 'webp'];
    if (!supported.includes(ext)) {
      alert('صيغة الصورة غير مدعومة حالياً. استخدم PNG أو JPG أو JPEG أو WEBP.');
      fileInput.value = '';
      return;
    }
    const originalName = file.name;
    const appPath = 'assets/images/' + originalName;
    const urlInput = document.getElementById(urlInputId);
    if (!urlInput) return;

    // Store original filename in editor field
    urlInput.value = appPath;
    // Trigger save so draft data is updated
    urlInput.dispatchEvent(new Event('input', { bubbles: true }));

    // Register temp preview URL for main preview
    this._ensureTempRegistry();
    const objUrl = URL.createObjectURL(file);
    window.__csTempPreviews.set(appPath, objUrl);

    // Update editor inline preview
    const preview = document.getElementById(previewId);
    if (preview) {
      if (preview._objUrl) URL.revokeObjectURL(preview._objUrl);
      preview._objUrl = objUrl;
      preview.className = 'image-editor-preview';
      preview.innerHTML = '';
      const img = document.createElement('img');
      img.src = objUrl;
      img.style.cssText = 'max-width:100%;max-height:200px;border-radius:6px;border:1px solid #ddd;';
      preview.appendChild(img);
    }

    // Update return-info UI
    const infoDiv = document.getElementById('img-return-' + previewId);
    if (infoDiv) {
      infoDiv.style.display = 'block';
      infoDiv.innerHTML = `
        <div class="image-return-text">أرسل هذه الصورة مع ملف JSON بنفس الاسم:</div>
        <div class="image-return-filename">${esc(originalName)}</div>
        <div class="image-return-path-label">المسار داخل التطبيق: <span dir="ltr">${esc(appPath)}</span></div>
      `;
    }

    // Show name warning if needed
    const warnMsg = this._nameWarningMessage(originalName);
    const warnDiv = document.getElementById('img-warn-' + previewId);
    if (warnDiv) {
      warnDiv.textContent = warnMsg;
      warnDiv.style.display = warnMsg ? 'block' : 'none';
    }

    // Force preview update
    if (window._updatePreview) window._updatePreview();

    fileInput.value = '';
  }

  static _safetyNoteEditor(sectionIdx, blockIdx, block) {
    const msg = block.message || {};
    return `
      <div class="${this.EDITING_CLASS}" data-section-idx="${sectionIdx}" data-block-idx="${blockIdx}">
        <div class="inline-header">✏️ تحرير ملاحظة السلامة</div>
        <div class="inline-body">
          <div class="inline-field">
            <label>الرسالة</label>
            <textarea class="form-textarea ie-input" data-field="message.ar" dir="rtl" rows="3">${esc(msg.ar || '')}</textarea>
          </div>
        </div>
        <div class="inline-actions">
          <button class="btn btn-success ie-save" type="button">💾 حفظ</button>
          <button class="btn btn-outline ie-cancel" type="button">إلغاء</button>
        </div>
      </div>
    `;
  }

  static _tableEditor(sectionIdx, blockIdx, block) {
    const caption = block.caption ? (block.caption.ar || '') : '';
    const headers = block.headers || [];
    const rows = block.rows || [];

    const headersHtml = headers.map((h, ci) => `
      <div class="ie-table-header-row" data-col-key="col-${ci}">
        <input type="text" class="form-input ie-table-header-input" value="${esc(h)}" placeholder="..." dir="rtl">
        <button class="ie-table-remove-header" title="حذف العمود">🗑️</button>
      </div>
    `).join('');

    const rowsHtml = rows.map(r => {
      const cells = r.cells || [];
      const cellsHtml = cells.map((c, ci) => `
        <input type="text" class="form-input ie-table-cell-input" data-col-key="col-${ci}" value="${esc(c)}" placeholder="..." dir="rtl">
      `).join('');
      return `<div class="ie-table-row">${cellsHtml}<button class="ie-table-remove-row" title="حذف الصف">🗑️</button></div>`;
    }).join('');

    const noRows = rows.length === 0 ? '<div class="empty-state-compact">لا توجد صفوف في الجدول</div>' : '';

    return `
      <div class="${this.EDITING_CLASS}" data-section-idx="${sectionIdx}" data-block-idx="${blockIdx}">
        <div class="inline-header">✏️ تحرير الجدول</div>
        <div class="inline-body">
          <div class="inline-field">
            <label>عنوان الجدول</label>
            <input type="text" class="form-input ie-table-caption" value="${esc(caption)}" placeholder="..." dir="rtl">
          </div>
          <div class="ie-table-section">
            <div class="ie-table-section-header">
              <span>رؤوس الأعمدة</span>
              <button class="btn btn-outline ie-table-add-header" type="button" style="font-size:11px;padding:3px 8px;">➕ إضافة عمود</button>
            </div>
            <div class="ie-table-headers">
              ${headersHtml || '<div class="empty-state-compact">لا توجد رؤوس أعمدة</div>'}
            </div>
          </div>
          <div class="ie-table-section">
            <div class="ie-table-section-header">
              <span>الصفوف</span>
              <button class="btn btn-outline ie-table-add-row" type="button" style="font-size:11px;padding:3px 8px;">➕ إضافة صف</button>
            </div>
            <div class="ie-table-rows">
              ${rowsHtml}
            </div>
            ${noRows}
          </div>
        </div>
        <div class="inline-actions">
          <button class="btn btn-success ie-save-table" type="button">💾 حفظ</button>
          <button class="btn btn-outline ie-cancel" type="button">إلغاء</button>
        </div>
      </div>
    `;
  }

  // ─── Checklist Editor ─────────────────────────────

  static _checklistEditor(sectionIdx, blockIdx, block) {
    const title = block.title || {};
    const items = block.items || [];
    const itemsHtml = items.map((item, ci) => `
      <div class="ie-checklist-item" data-ci="${ci}">
        <input type="text" class="form-input ie-checklist-text" value="${esc(item.textAr || '')}" placeholder="نص البند" dir="rtl" style="flex:1;">
        <label class="inline-checkbox-label" style="white-space:nowrap;">
          <input type="checkbox" class="ie-checklist-required" ${item.isRequired !== false ? 'checked' : ''}>
          إجباري
        </label>
        <button class="ie-checklist-remove-item" title="حذف البند">🗑️</button>
      </div>
    `).join('');

    return `
      <div class="${this.EDITING_CLASS}" data-section-idx="${sectionIdx}" data-block-idx="${blockIdx}">
        <div class="inline-header">✏️ تحرير قائمة الفحص</div>
        <div class="inline-body">
          <div class="inline-field">
            <label>عنوان القائمة</label>
            <input type="text" class="form-input ie-checklist-title" value="${esc(title.ar || '')}" placeholder="..." dir="rtl">
          </div>
          <div class="inline-field">
            <label>البنود</label>
            <div class="ie-checklist-items">
              ${itemsHtml || '<div class="empty-state-compact">لا توجد بنود في القائمة</div>'}
            </div>
            <button class="btn btn-outline ie-checklist-add-item" type="button" style="margin-top:6px;font-size:12px;padding:4px 10px;">➕ إضافة بند</button>
          </div>
        </div>
        <div class="inline-actions">
          <button class="btn btn-success ie-save-checklist" type="button">💾 حفظ</button>
          <button class="btn btn-outline ie-cancel" type="button">إلغاء</button>
        </div>
      </div>
    `;
  }

  // ─── Inspection Point Editor ───────────────────────

  static _inspectionPointEditor(sectionIdx, blockIdx, block) {
    const pickerId = `marker-picker-${sectionIdx}-${blockIdx}`;
    const markerChips = ['', ...MARKER_STYLE_OPTIONS].map(m => {
      const val = m || '';
      const label = m ? MARKER_STYLE_LABELS[m] : 'تلقائي';
      const sym = m ? MARKER_STYLE_SYMBOLS[m] : '?';
      const col = m ? MARKER_STYLE_COLORS[m] : { bg: 'var(--topic-accent)', fg: '#FFFFFF' };
      const active = val === (block.markerStyle || '') ? ' active' : '';
      return `<div class="marker-option${active}" data-value="${val}" onclick="var g=document.getElementById('${pickerId}');g.querySelector('.ie-input').value='${val}';g.querySelectorAll('.marker-option').forEach(function(o){o.classList.remove('active')});this.classList.add('active')">
        <span class="marker-preview" style="background:${col.bg};color:${col.fg}">${sym}</span>
        <span class="marker-picker-label">${label}</span>
      </div>`;
    }).join('');
    const cmLabels = MARKER_COLOR_MODE_OPTIONS.map(m =>
      `<option value="${m}"${(block.markerColorMode || 'theme') === m ? ' selected' : ''}>${esc(MARKER_COLOR_MODE_LABELS[m])}</option>`
    ).join('');
    return `
      <div class="${this.EDITING_CLASS}" data-section-idx="${sectionIdx}" data-block-idx="${blockIdx}">
        <div class="inline-header">✏️ تحرير نقطة الفحص</div>
        <div class="inline-body">
          <div class="inline-field">
            <label>معيار الفحص</label>
            <textarea class="form-textarea ie-input" data-field="criteriaAr" dir="rtl" rows="2">${esc(block.criteriaAr || '')}</textarea>
          </div>
          <div class="inline-field">
            <label>طريقة الفحص</label>
            <textarea class="form-textarea ie-input" data-field="methodAr" dir="rtl" rows="2">${esc(block.methodAr || '')}</textarea>
          </div>
          <div class="inline-field">
            <label>حد القبول</label>
            <input type="text" class="form-input ie-input" data-field="acceptableTolerance" value="${esc(block.acceptableTolerance || '')}" dir="rtl" placeholder="مثال: ±5 مم">
          </div>
          <div class="inline-field">
            <label>نمط العلامة</label>
            <div class="marker-picker-grid" id="${pickerId}">
              ${markerChips}
            </div>
            <input type="hidden" class="ie-input" data-field="markerStyle" value="${block.markerStyle || ''}">
          </div>
          <div class="inline-field">
            <label>وضع لون العلامة</label>
            <select class="form-input ie-input" data-field="markerColorMode" dir="rtl">
              ${cmLabels}
            </select>
          </div>
          <div class="inline-field inline-field-row">
            <label class="inline-checkbox-label">
              <input type="checkbox" class="ie-input" data-field="isCritical" ${block.isCritical ? 'checked' : ''}>
              حرج (Critical)
            </label>
          </div>
        </div>
        <div class="inline-actions">
          <button class="btn btn-success ie-save" type="button">💾 حفظ</button>
          <button class="btn btn-outline ie-cancel" type="button">إلغاء</button>
        </div>
      </div>
    `;
  }

  // ─── Code Reference Editor ─────────────────────────

  static _codeReferenceEditor(sectionIdx, blockIdx, block) {
    const title = block.title || {};
    const excerpt = block.excerpt || {};
    return `
      <div class="${this.EDITING_CLASS}" data-section-idx="${sectionIdx}" data-block-idx="${blockIdx}">
        <div class="inline-header">✏️ تحرير مرجع كود</div>
        <div class="inline-body">
          <div class="inline-field">
            <label>رمز الكود <span class="field-required">*</span></label>
            <input type="text" class="form-input ie-input" data-field="code" value="${esc(block.code || '')}" dir="ltr" placeholder="ACI 318-19">
            <div class="form-help">يجب التحقق من صحة رقم الكود هندسياً</div>
          </div>
          <div class="inline-field">
            <label>العنوان</label>
            <input type="text" class="form-input ie-input" data-field="title.ar" value="${esc(title.ar || '')}" dir="rtl" placeholder="مادة الكود">
          </div>
          <div class="inline-field">
            <label>القسم (اختياري)</label>
            <input type="text" class="form-input ie-input" data-field="section" value="${esc(block.section || '')}" dir="ltr" placeholder="5.4">
          </div>
          <div class="inline-field">
            <label>نص المادة (اختياري)</label>
            <textarea class="form-textarea ie-input" data-field="excerpt.ar" dir="rtl" rows="3">${esc(excerpt.ar || '')}</textarea>
          </div>
        </div>
        <div class="inline-actions">
          <button class="btn btn-success ie-save" type="button">💾 حفظ</button>
          <button class="btn btn-outline ie-cancel" type="button">إلغاء</button>
        </div>
      </div>
    `;
  }

  // ─── Equipment Editor ──────────────────────────────

  static _equipmentEditor(sectionIdx, blockIdx, block) {
    const items = block.items || [];
    const itemsHtml = items.map((item, ei) => `
      <div class="ie-equipment-item" data-ei="${ei}">
        <input type="text" class="form-input ie-equipment-name" value="${esc(item.nameAr || '')}" placeholder="اسم المعدة" dir="rtl" style="flex:1;">
        <input type="text" class="form-input ie-equipment-purpose" value="${esc(item.purpose || '')}" placeholder="الغرض" dir="rtl" style="flex:1;">
        <input type="text" class="form-input ie-equipment-spec" value="${esc(item.specification || '')}" placeholder="المواصفات" dir="rtl" style="flex:0.7;">
        <button class="ie-equipment-remove-item" title="حذف">🗑️</button>
      </div>
    `).join('');

    return `
      <div class="${this.EDITING_CLASS}" data-section-idx="${sectionIdx}" data-block-idx="${blockIdx}">
        <div class="inline-header">✏️ تحرير قائمة المعدات</div>
        <div class="inline-body">
          <div class="inline-field">
            <label>العنوان</label>
            <input type="text" class="form-input ie-equipment-section-title" value="${esc(block.title || '')}" placeholder="..." dir="rtl">
          </div>
          <div class="inline-field">
            <label>المعدات / الأدوات</label>
            <div class="ie-equipment-items">
              ${itemsHtml || '<div class="empty-state-compact">لا توجد معدات</div>'}
            </div>
            <button class="btn btn-outline ie-equipment-add-item" type="button" style="margin-top:6px;font-size:12px;padding:4px 10px;">➕ إضافة معدة</button>
          </div>
        </div>
        <div class="inline-actions">
          <button class="btn btn-success ie-save-equipment" type="button">💾 حفظ</button>
          <button class="btn btn-outline ie-cancel" type="button">إلغاء</button>
        </div>
      </div>
    `;
  }
}

class InlineTopicEditor {
  static renderMistakesEditor(draft, isOpen) {
    const data = draft.toJSON();
    const mistakes = (data.topic && data.topic.commonMistakes) || [];
    if (!mistakes.length && !data.topic) return '';
    return this._card('commonMistakes', 'الأخطاء الشائعة', mistakes, (m, i) => `
      <div class="inline-topic-item" data-mistake-idx="${i}">
        <div class="inline-field">
          <label>الخطأ #${i + 1}</label>
          <textarea class="form-textarea ie-topic-field" data-path="topic.commonMistakes.${i}.ar" data-outer="topic.commonMistakes.${i}" data-field="ar" dir="rtl" rows="2">${esc(m.ar || '')}</textarea>
        </div>
        <button class="btn btn-outline ie-remove-item" data-target="topic.commonMistakes" data-idx="${i}" type="button" style="font-size:12px;padding:4px 8px;margin-top:4px;">🗑️ حذف</button>
      </div>
    `, 'topic.commonMistakes', isOpen);
  }

  static renderAcceptRejectEditor(draft, isOpen) {
    const data = draft.toJSON();
    const items = (data.topic && data.topic.acceptRejectItems) || [];
    if (!items.length && !data.topic) return '';
    return this._card('acceptRejectItems', 'معايير القبول والرفض', items, (item, i) => `
      <div class="inline-topic-item" data-ar-idx="${i}">
        <div class="inline-field">
          <label>المعيار</label>
          <input type="text" class="form-input ie-topic-field" data-path="topic.acceptRejectItems.${i}.criteriaAr" data-outer="topic.acceptRejectItems.${i}" data-field="criteriaAr" value="${esc(item.criteriaAr || '')}" dir="rtl">
        </div>
        <div class="inline-field">
          <label>حد القبول</label>
          <input type="text" class="form-input ie-topic-field" data-path="topic.acceptRejectItems.${i}.acceptanceLimitAr" data-outer="topic.acceptRejectItems.${i}" data-field="acceptanceLimitAr" value="${esc(item.acceptanceLimitAr || '')}" dir="rtl">
        </div>
        <div class="inline-field">
          <label>طريقة الفحص</label>
          <input type="text" class="form-input ie-topic-field" data-path="topic.acceptRejectItems.${i}.methodAr" data-outer="topic.acceptRejectItems.${i}" data-field="methodAr" value="${esc(item.methodAr || '')}" dir="rtl">
        </div>
        <div class="inline-field inline-field-row">
          <label class="inline-checkbox-label">
            <input type="checkbox" class="ie-topic-field" data-path="topic.acceptRejectItems.${i}.isCritical" data-outer="topic.acceptRejectItems.${i}" data-field="isCritical" ${item.isCritical ? 'checked' : ''}>
            isCritical
          </label>
          <label class="inline-checkbox-label">
            <input type="checkbox" class="ie-topic-field" data-path="topic.acceptRejectItems.${i}.reviewRequired" data-outer="topic.acceptRejectItems.${i}" data-field="reviewRequired" ${item.reviewRequired !== false ? 'checked' : ''}>
            reviewRequired
          </label>
        </div>
        <button class="btn btn-outline ie-remove-item" data-target="topic.acceptRejectItems" data-idx="${i}" type="button" style="font-size:12px;padding:4px 8px;margin-top:4px;">🗑️ حذف</button>
      </div>
    `, 'topic.acceptRejectItems', isOpen);
  }

  static _card(key, title, items, itemRenderer, arrayPath, isOpen) {
    const itemsHtml = items.map((m, i) => itemRenderer(m, i)).join('');
    const arrow = isOpen ? '▾' : '▸';
    const collapsedClass = isOpen ? '' : ' section-card-collapsed';
    const bodyStyle = isOpen ? '' : ' style="display:none"';
    return `
      <div class="section-card topic-editor-card${collapsedClass}" data-key="${key}">
        <div class="section-card-header ie-topic-toggle" data-topic-list="${key}">
          <span class="section-toggle-arrow">${arrow}</span>
          <span class="section-title">✏️ ${esc(title)}</span>
          <span class="section-block-count">${items.length} بند</span>
        </div>
        <div class="section-card-body"${bodyStyle}>
          <div class="topic-editor-items">${itemsHtml}</div>
          <div class="inline-actions" style="margin-top:12px;">
            <button class="btn btn-success ie-save-topic" data-target="${arrayPath}" type="button">💾 حفظ الكل</button>
            <button class="btn btn-outline ie-add-item" data-target="${arrayPath}" type="button">➕ إضافة بند</button>
          </div>
        </div>
      </div>
    `;
  }
}
