class InlineBlockEditor {
  static EDITING_CLASS = 'inline-editor';

  static getEditorHtml(sectionIdx, blockIdx, block) {
    switch (block.type) {
      case 'text': return this._textEditor(sectionIdx, blockIdx, block);
      case 'execution_step': return this._executionStepEditor(sectionIdx, blockIdx, block);
      case 'safety_note': return this._safetyNoteEditor(sectionIdx, blockIdx, block);
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
            <label>المحتوى (عربي)</label>
            <textarea class="form-textarea ie-input" data-field="content.ar" dir="rtl" rows="4">${esc(content.ar || '')}</textarea>
          </div>
          <div class="inline-field">
            <label>المحتوى (English)</label>
            <textarea class="form-textarea ie-input" data-field="content.en" dir="ltr" rows="3">${esc(content.en || '')}</textarea>
          </div>
          <div class="inline-field">
            <label>النمط</label>
            <select class="form-select ie-input" data-field="variant">${options(VALID_TEXT_VARIANTS, block.variant)}</select>
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
            <label>الوصف (عربي)</label>
            <textarea class="form-textarea ie-input" data-field="description.ar" dir="rtl" rows="3">${esc(desc.ar || '')}</textarea>
          </div>
          <div class="inline-field">
            <label>الوصف (English)</label>
            <textarea class="form-textarea ie-input" data-field="description.en" dir="ltr" rows="2">${esc(desc.en || '')}</textarea>
          </div>
          <div class="inline-field">
            <label>ملاحظات (عربي)</label>
            <textarea class="form-textarea ie-input" data-field="notes.ar" dir="rtl" rows="2">${esc(notes.ar || '')}</textarea>
          </div>
          <div class="inline-field">
            <label>ملاحظات (English)</label>
            <textarea class="form-textarea ie-input" data-field="notes.en" dir="ltr" rows="2">${esc(notes.en || '')}</textarea>
          </div>
        </div>
        <div class="inline-actions">
          <button class="btn btn-success ie-save" type="button">💾 حفظ</button>
          <button class="btn btn-outline ie-cancel" type="button">إلغاء</button>
        </div>
      </div>
    `;
  }

  static _safetyNoteEditor(sectionIdx, blockIdx, block) {
    const msg = block.message || {};
    return `
      <div class="${this.EDITING_CLASS}" data-section-idx="${sectionIdx}" data-block-idx="${blockIdx}">
        <div class="inline-header">✏️ تحرير ملاحظة السلامة</div>
        <div class="inline-body">
          <div class="inline-field">
            <label>الرسالة (عربي)</label>
            <textarea class="form-textarea ie-input" data-field="message.ar" dir="rtl" rows="3">${esc(msg.ar || '')}</textarea>
          </div>
          <div class="inline-field">
            <label>الرسالة (English)</label>
            <textarea class="form-textarea ie-input" data-field="message.en" dir="ltr" rows="2">${esc(msg.en || '')}</textarea>
          </div>
          <div class="inline-field">
            <label>مستوى الخطورة</label>
            <select class="form-select ie-input" data-field="severity">${options(VALID_SEVERITIES, block.severity)}</select>
          </div>
        </div>
        <div class="inline-actions">
          <button class="btn btn-success ie-save" type="button">💾 حفظ</button>
          <button class="btn btn-outline ie-cancel" type="button">إلغاء</button>
        </div>
      </div>
    `;
  }
}

class InlineTopicEditor {
  static renderMistakesEditor(draft) {
    const data = draft.toJSON();
    const mistakes = (data.topic && data.topic.commonMistakes) || [];
    if (!mistakes.length && !data.topic) return '';
    return this._card('commonMistakes', 'الأخطاء الشائعة (Common Mistakes)', mistakes, (m, i) => `
      <div class="inline-topic-item" data-mistake-idx="${i}">
        <div class="inline-field">
          <label>الخطأ (عربي) #${i + 1}</label>
          <textarea class="form-textarea ie-topic-field" data-outer="topic.commonMistakes.${i}" data-field="ar" dir="rtl" rows="2">${esc(m.ar || '')}</textarea>
        </div>
        <div class="inline-field">
          <label>الخطأ (English)</label>
          <textarea class="form-textarea ie-topic-field" data-outer="topic.commonMistakes.${i}" data-field="en" dir="ltr" rows="2">${esc(m.en || '')}</textarea>
        </div>
        <div class="inline-field">
          <label>severity</label>
          <select class="form-select ie-topic-field" data-outer="topic.commonMistakes.${i}" data-field="severity">${options(['low', 'medium', 'high', 'critical'], m.severity)}</select>
        </div>
        <button class="btn btn-outline ie-remove-item" data-target="topic.commonMistakes" data-idx="${i}" type="button" style="font-size:12px;padding:4px 8px;margin-top:4px;">🗑️ حذف</button>
      </div>
    `, 'topic.commonMistakes');
  }

  static renderAcceptRejectEditor(draft) {
    const data = draft.toJSON();
    const items = (data.topic && data.topic.acceptRejectItems) || [];
    if (!items.length && !data.topic) return '';
    return this._card('acceptRejectItems', 'معايير القبول والرفض (Accept/Reject)', items, (item, i) => `
      <div class="inline-topic-item" data-ar-idx="${i}">
        <div class="inline-field">
          <label>المعيار (criteriaAr)</label>
          <input type="text" class="form-input ie-topic-field" data-outer="topic.acceptRejectItems.${i}" data-field="criteriaAr" value="${esc(item.criteriaAr || '')}" dir="rtl">
        </div>
        <div class="inline-field">
          <label>criteriaEn</label>
          <input type="text" class="form-input ie-topic-field" data-outer="topic.acceptRejectItems.${i}" data-field="criteriaEn" value="${esc(item.criteriaEn || '')}" dir="ltr">
        </div>
        <div class="inline-field">
          <label>حد القبول (acceptanceLimitAr)</label>
          <input type="text" class="form-input ie-topic-field" data-outer="topic.acceptRejectItems.${i}" data-field="acceptanceLimitAr" value="${esc(item.acceptanceLimitAr || '')}" dir="rtl">
        </div>
        <div class="inline-field">
          <label>acceptanceLimitEn</label>
          <input type="text" class="form-input ie-topic-field" data-outer="topic.acceptRejectItems.${i}" data-field="acceptanceLimitEn" value="${esc(item.acceptanceLimitEn || '')}" dir="ltr">
        </div>
        <div class="inline-field">
          <label>طريقة الفحص (methodAr)</label>
          <input type="text" class="form-input ie-topic-field" data-outer="topic.acceptRejectItems.${i}" data-field="methodAr" value="${esc(item.methodAr || '')}" dir="rtl">
        </div>
        <div class="inline-field">
          <label>methodEn</label>
          <input type="text" class="form-input ie-topic-field" data-outer="topic.acceptRejectItems.${i}" data-field="methodEn" value="${esc(item.methodEn || '')}" dir="ltr">
        </div>
        <div class="inline-field inline-field-row">
          <label class="inline-checkbox-label">
            <input type="checkbox" class="ie-topic-field" data-outer="topic.acceptRejectItems.${i}" data-field="isCritical" ${item.isCritical ? 'checked' : ''}>
            isCritical
          </label>
          <label class="inline-checkbox-label">
            <input type="checkbox" class="ie-topic-field" data-outer="topic.acceptRejectItems.${i}" data-field="reviewRequired" ${item.reviewRequired !== false ? 'checked' : ''}>
            reviewRequired
          </label>
        </div>
        <button class="btn btn-outline ie-remove-item" data-target="topic.acceptRejectItems" data-idx="${i}" type="button" style="font-size:12px;padding:4px 8px;margin-top:4px;">🗑️ حذف</button>
      </div>
    `, 'topic.acceptRejectItems');
  }

  static _card(key, title, items, itemRenderer, arrayPath) {
    const itemsHtml = items.map((m, i) => itemRenderer(m, i)).join('');
    return `
      <div class="section-card topic-editor-card" data-key="${key}">
        <div class="section-card-header">
          <span class="section-title">✏️ ${esc(title)}</span>
          <span class="section-block-count">${items.length} بند</span>
        </div>
        <div class="section-card-body">
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
