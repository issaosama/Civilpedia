class InlineBlockEditor {
  static EDITING_CLASS = 'inline-editor';

  static getEditorHtml(sectionIdx, blockIdx, block) {
    switch (block.type) {
      case 'text': return this._textEditor(sectionIdx, blockIdx, block);
      case 'execution_step': return this._executionStepEditor(sectionIdx, blockIdx, block);
      case 'safety_note': return this._safetyNoteEditor(sectionIdx, blockIdx, block);
      case 'table': return this._tableEditor(sectionIdx, blockIdx, block);
      case 'image': return this._imageEditor(sectionIdx, blockIdx, block);
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
          <div style="margin-top:4px;font-size:11px;color:#888;line-height:1.6;">
            <strong>إرشاد سريع:</strong><br>
            اضغط "اختيار صورة" وسيتم تعبئة المسار تلقائياً.<br>
            أرسل ملف الصورة مع ملف الـ Draft.<br>
            يفضّل أن يكون اسم الصورة إنكليزي وبدون فراغات.
          </div>
          ${previewHtml}
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
    const name = file.name.toLowerCase().replace(/[^a-z0-9._-]/g, '_').replace(/\s+/g, '_');
    const urlInput = document.querySelector('[data-path="topic.coverImageUrl"]');
    if (!urlInput) return;
    urlInput.value = 'assets/images/' + name;
    urlInput.dispatchEvent(new Event('change', { bubbles: true }));
    fileInput.value = '';
  }

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
    const name = file.name.toLowerCase().replace(/[^a-z0-9._-]/g, '_').replace(/\s+/g, '_');
    const urlInput = document.getElementById(urlInputId);
    if (!urlInput) return;
    urlInput.value = 'assets/images/' + name;
    const preview = document.getElementById(previewId);
    if (!preview) return;
    if (preview._objUrl) URL.revokeObjectURL(preview._objUrl);
    preview._objUrl = URL.createObjectURL(file);
    preview.innerHTML = '';
    const img = document.createElement('img');
    img.src = preview._objUrl;
    img.style.cssText = 'max-width:100%;max-height:200px;border-radius:6px;border:1px solid #ddd;';
    preview.appendChild(img);
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
