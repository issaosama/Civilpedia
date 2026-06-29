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
}

class InlineTopicEditor {
  static renderMistakesEditor(draft) {
    const data = draft.toJSON();
    const mistakes = (data.topic && data.topic.commonMistakes) || [];
    if (!mistakes.length && !data.topic) return '';
    return this._card('commonMistakes', 'الأخطاء الشائعة', mistakes, (m, i) => `
      <div class="inline-topic-item" data-mistake-idx="${i}">
        <div class="inline-field">
          <label>الخطأ #${i + 1}</label>
          <textarea class="form-textarea ie-topic-field" data-outer="topic.commonMistakes.${i}" data-field="ar" dir="rtl" rows="2">${esc(m.ar || '')}</textarea>
        </div>
        <button class="btn btn-outline ie-remove-item" data-target="topic.commonMistakes" data-idx="${i}" type="button" style="font-size:12px;padding:4px 8px;margin-top:4px;">🗑️ حذف</button>
      </div>
    `, 'topic.commonMistakes');
  }

  static renderAcceptRejectEditor(draft) {
    const data = draft.toJSON();
    const items = (data.topic && data.topic.acceptRejectItems) || [];
    if (!items.length && !data.topic) return '';
    return this._card('acceptRejectItems', 'معايير القبول والرفض', items, (item, i) => `
      <div class="inline-topic-item" data-ar-idx="${i}">
        <div class="inline-field">
          <label>المعيار</label>
          <input type="text" class="form-input ie-topic-field" data-outer="topic.acceptRejectItems.${i}" data-field="criteriaAr" value="${esc(item.criteriaAr || '')}" dir="rtl">
        </div>
        <div class="inline-field">
          <label>حد القبول</label>
          <input type="text" class="form-input ie-topic-field" data-outer="topic.acceptRejectItems.${i}" data-field="acceptanceLimitAr" value="${esc(item.acceptanceLimitAr || '')}" dir="rtl">
        </div>
        <div class="inline-field">
          <label>طريقة الفحص</label>
          <input type="text" class="form-input ie-topic-field" data-outer="topic.acceptRejectItems.${i}" data-field="methodAr" value="${esc(item.methodAr || '')}" dir="rtl">
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
