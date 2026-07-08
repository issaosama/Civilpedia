class ValidationEngine {
  constructor(draft) {
    this.draft = draft;
    this.errors = [];
    this.warnings = [];
    this.passed = [];
    this.fieldErrors = [];
    this.errorsMeta = [];
    this.warningsMeta = [];
  }

  _addError(msg, meta) {
    this.errors.push(msg);
    this.errorsMeta.push(meta || null);
  }

  _addWarning(msg, meta) {
    this.warnings.push(msg);
    this.warningsMeta.push(meta || null);
  }

  validate() {
    this.errors = [];
    this.warnings = [];
    this.passed = [];
    this.fieldErrors = [];
    this.errorsMeta = [];
    this.warningsMeta = [];

    if (!this.draft || !this.draft.isValid()) {
      this._addError('لم يتم تحميل أي ملف Draft JSON');
      return this.getResult();
    }

    const data = this.draft.toJSON();

    this._checkTopLevel(data);
    if (this.errors.length > 0) return this.getResult();

    this._checkMeta(data._meta);
    this._checkTopic(data.topic);
    this._checkSections(data.sections);
    this._checkReview(data.review);
    this._checkDraftVsAppReady(data);

    return this.getResult();
  }

  _checkTopLevel(data) {
    for (const key of REQUIRED_TOP_LEVEL) {
      if (data[key] === undefined || data[key] === null) {
        this._addError(`المفتاح الرئيسي مفقود: "${key}"`);
      } else {
        this.passed.push(`المفتاح الرئيسي "${key}" موجود`);
      }
    }
  }

  _checkMeta(meta) {
    if (!meta) return;
    for (const key of REQUIRED_META) {
      if (meta[key] === undefined || meta[key] === null) {
        this._addError(`_meta.${key} مفقود`);
      } else {
        this.passed.push(`_meta.${key} موجود`);
      }
    }
    if (meta.schemaVersion && meta.schemaVersion !== SCHEMA_VERSION) {
      this._addWarning(`إصدار المخطط (${meta.schemaVersion}) يختلف عن الإصدار الحالي (${SCHEMA_VERSION})`);
    }
  }

  _checkTopic(topic) {
    if (!topic) return;
    for (const key of REQUIRED_TOPIC) {
      if (topic[key] === undefined || topic[key] === null) {
        this._addError(`topic.${key} مفقود`);
      } else {
        this.passed.push(`topic.${key} موجود`);
      }
    }
    if (topic.titleAr !== undefined && topic.titleAr !== null && topic.titleAr.trim() === '') {
      const fe = { path: 'topic.titleAr', type: 'field', message: 'عنوان الموضوع فارغ' };
      this._addError('topic.titleAr فارغ — يرجى إدخال عنوان الموضوع', { path: 'topic.titleAr' });
      this.fieldErrors.push(fe);
    }
    if (topic.summaryAr !== undefined && topic.summaryAr !== null && topic.summaryAr.trim() === '') {
      const fe = { path: 'topic.summaryAr', type: 'field', message: 'ملخص الموضوع فارغ' };
      this._addError('topic.summaryAr فارغ — يرجى إدخال ملخص الموضوع', { path: 'topic.summaryAr' });
      this.fieldErrors.push(fe);
    }
    if (topic.level && !VALID_LEVELS.includes(topic.level)) {
      this._addWarning(`topic.level غير صالح: "${topic.level}". القيم المقبولة: ${VALID_LEVELS.join(', ')}`);
    }
    if (topic.planKey && !VALID_PLAN_KEYS.includes(topic.planKey)) {
      this._addWarning(`topic.planKey غير صالح: "${topic.planKey}". القيم المقبولة: ${VALID_PLAN_KEYS.join(', ')}`);
    }
    if (topic.status && !VALID_TOPIC_STATUSES.includes(topic.status)) {
      this._addWarning(`topic.status غير صالح: "${topic.status}". القيم المقبولة: ${VALID_TOPIC_STATUSES.join(', ')}`);
    }
    for (const field of LEGACY_BODY_FIELDS) {
      const val = topic[field];
      if (val === undefined || val === null || val === '') continue;
      let hasContent = false;
      if (typeof val === 'string') {
        hasContent = val.trim() !== '';
      } else if (typeof val === 'object') {
        if (Array.isArray(val)) {
          hasContent = val.length > 0;
        } else if (val.ar !== undefined) {
          hasContent = val.ar !== null && val.ar !== '';
        } else {
          hasContent = Object.keys(val).length > 0;
        }
      } else {
        hasContent = true;
      }
      if (hasContent) {
        this._addWarning(`topic.${field} يحتوي على بيانات — يُفضّل نقل هذا المحتوى إلى أقسام وكتل`, { path: `topic.${field}` });
      }
    }

    if (topic.keyTopics !== undefined) {
      if (!Array.isArray(topic.keyTopics)) {
        this._addWarning('topic.keyTopics ليس مصفوفة. يفضل استخدام مصفوفة من النصوص.', { path: 'topic.keyTopics' });
      } else if (topic.keyTopics.length > 20) {
        this._addWarning('topic.keyTopics يحتوي على أكثر من 20 كلمة مفتاحية. يُفضّل تقليل العدد.', { path: 'topic.keyTopics' });
      } else {
        const hasInvalid = topic.keyTopics.some(kt => typeof kt !== 'string' || kt.trim() === '');
        if (hasInvalid) {
          this._addWarning('topic.keyTopics يحتوي على قيم غير صالحة. تأكد من أن جميع القيم نصوص غير فارغة.', { path: 'topic.keyTopics' });
        }
      }
    }

    if (topic.coverImageUrl) {
      const url = topic.coverImageUrl;
      const ext = url.split('.').pop().toLowerCase();
      const supported = ['png', 'jpg', 'jpeg', 'webp'];
      if (!supported.includes(ext)) {
        this._addWarning(`coverImageUrl: صيغة غير مدعومة .${ext}. استخدم PNG أو JPG أو JPEG أو WEBP.`);
      }
      if (!url.startsWith('assets/images/')) {
        this._addWarning('coverImageUrl: يجب أن يبدأ المسار بـ assets/images/');
      }
      if (/^[A-Za-z]:\\/.test(url)) {
        this._addWarning('coverImageUrl: لا تستخدم مسار الحاسبة مثل C:\\ أو D:\\');
      }
      if (url.includes('\\')) {
        this._addWarning('coverImageUrl: استخدم / بدلاً من \\ في المسار.');
      }
      if (/\s/.test(url)) {
        this._addWarning('coverImageUrl: يفضّل أن يكون اسم الملف بدون فراغات.');
      }
    }

    const vt = topic.visual_theme;
    if (vt !== undefined && vt !== null) {
      if (typeof vt === 'object') {
        const accent = vt.accent;
        if (accent !== undefined && accent !== null) {
          if (!VALID_THEME_KEYS.includes(accent)) {
            this._addWarning(`topic.visual_theme.accent "${accent}" غير صالح. القيم المقبولة: ${VALID_THEME_KEYS.join(', ')}`, { path: 'topic.visual_theme.accent' });
          }
        }
      } else if (typeof vt === 'string') {
        if (!VALID_THEME_KEYS.includes(vt)) {
          this._addWarning(`topic.visual_theme "${vt}" غير صالح. القيم المقبولة: ${VALID_THEME_KEYS.join(', ')}`, { path: 'topic.visual_theme' });
        }
      }
    }
    if (topic.visualTheme !== undefined && topic.visualTheme !== null) {
      this._addWarning('topic.visualTheme (camelCase) موجود — استخدم visual_theme بدلاً من ذلك.', { path: 'topic.visualTheme' });
    }
  }

  _checkSections(sections) {
    if (!sections || !Array.isArray(sections)) {
      this._addError('sections يجب أن يكون مصفوفة');
      return;
    }
    if (sections.length === 0) {
      this._addWarning('لا توجد أقسام في هذا الموضوع');
      return;
    }
    this.passed.push(`عدد الأقسام: ${sections.length}`);

    for (let i = 0; i < sections.length; i++) {
      this._checkSection(sections[i], i);
    }
  }

  _checkSection(section, index) {
    for (const key of REQUIRED_SECTION) {
      if (section[key] === undefined || section[key] === null) {
        if (key === 'title') {
          const fe = { sectionIdx: index, type: 'section', message: 'عنوان القسم فارغ' };
          this._addError(`section[${index}] "${section.id || '?'}" — "${key}" مفقود`, { sectionIdx: index });
          this.fieldErrors.push(fe);
        } else {
          this._addError(`section[${index}] "${section.id || '?'}" — "${key}" مفقود`);
        }
      } else {
        this.passed.push(`section "${section.id || '?'}" — "${key}" موجود`);
        if (key === 'title' && section.title !== undefined && section.title !== null && section.title.trim() === '') {
          const fe = { sectionIdx: index, type: 'section', message: 'عنوان القسم فارغ' };
          this._addError(`section[${index}] "${section.id || '?'}" — عنوان القسم فارغ`, { sectionIdx: index });
          this.fieldErrors.push(fe);
        }
      }
    }
    if (section.type && !VALID_SECTION_TYPES.includes(section.type)) {
      this._addWarning(`section "${section.id || '?'}" — النوع "${section.type}" غير معروف`);
    }
    if (section.blocks && Array.isArray(section.blocks)) {
      if (section.blocks.length === 0) {
        const fe = { sectionIdx: index, type: 'section', message: 'لا توجد كتل في هذا القسم' };
        this._addWarning(`section "${section.id || '?'}" — لا توجد كتل في هذا القسم`, { sectionIdx: index });
        this.fieldErrors.push(fe);
      }
      this.passed.push(`section "${section.id || '?'}" — عدد الكتل: ${section.blocks.length}`);
      for (let j = 0; j < section.blocks.length; j++) {
        this._checkBlock(section.blocks[j], section.id || '?', index, j);
      }
    } else {
      const fe = { sectionIdx: index, type: 'section', message: 'الكتل مفقودة في هذا القسم' };
      this._addError(`section "${section.id || '?'}" — "blocks" مفقود أو ليس مصفوفة`, { sectionIdx: index });
      this.fieldErrors.push(fe);
    }
  }

  _checkBlock(block, sectionId, sectionIdx, index) {
    for (const key of REQUIRED_BLOCK) {
      if (block[key] === undefined || block[key] === null) {
        this._addError(`section "${sectionId}" block[${index}] — "${key}" مفقود`);
      }
    }
    const type = block.type;
    if (type && !VALID_BLOCK_TYPES.includes(type)) {
      const orderStr = block.order !== undefined ? ` (ترتيب ${block.order})` : '';
      this._addError(`section "${sectionId}" block[${index}]${orderStr} — النوع "${type}" غير معروف. الأنواع المقبولة: ${VALID_BLOCK_TYPES.join(', ')}`, { sectionIdx, blockIdx: index });
    }

    switch (type) {
      case 'text':
        if (!block.content) {
          const fe = { sectionIdx, blockIdx: index, type: 'block', message: 'محتوى النص فارغ' };
          this._addError(`section "${sectionId}" block[${index}] — text: "content" مفقود`, { sectionIdx, blockIdx: index });
          this.fieldErrors.push(fe);
        } else if (!block.content.ar || block.content.ar.trim() === '') {
          const fe = { sectionIdx, blockIdx: index, type: 'block', message: 'محتوى النص العربي فارغ' };
          this._addError(`section "${sectionId}" block[${index}] — text: المحتوى العربي فارغ`, { sectionIdx, blockIdx: index });
          this.fieldErrors.push(fe);
        }
        if (block.variant && !VALID_TEXT_VARIANTS.includes(block.variant)) {
          this._addWarning(`section "${sectionId}" block[${index}] — text variant "${block.variant}" غير معروف`);
        }
        break;
      case 'execution_step':
        if (block.stepNumber === undefined || block.stepNumber === null) {
          this._addWarning(`section "${sectionId}" block[${index}] — execution_step: "stepNumber" مفقود`);
        }
        if (!block.description) {
          const fe = { sectionIdx, blockIdx: index, type: 'block', message: 'وصف الخطوة فارغ' };
          this._addError(`section "${sectionId}" block[${index}] — execution_step: "description" مفقود`, { sectionIdx, blockIdx: index });
          this.fieldErrors.push(fe);
        } else if (!block.description.ar || block.description.ar.trim() === '') {
          const fe = { sectionIdx, blockIdx: index, type: 'block', message: 'الوصف العربي للخطوة فارغ' };
          this._addError(`section "${sectionId}" block[${index}] — execution_step: الوصف العربي فارغ`, { sectionIdx, blockIdx: index });
          this.fieldErrors.push(fe);
        }
        break;
      case 'safety_note':
        if (!block.message) {
          const fe = { sectionIdx, blockIdx: index, type: 'block', message: 'رسالة السلامة فارغة' };
          this._addError(`section "${sectionId}" block[${index}] — safety_note: "message" مفقود`, { sectionIdx, blockIdx: index });
          this.fieldErrors.push(fe);
        } else if (!block.message.ar || block.message.ar.trim() === '') {
          const fe = { sectionIdx, blockIdx: index, type: 'block', message: 'رسالة السلامة العربية فارغة' };
          this._addError(`section "${sectionId}" block[${index}] — safety_note: الرسالة العربية فارغة`, { sectionIdx, blockIdx: index });
          this.fieldErrors.push(fe);
        }
        if (block.severity && !VALID_SEVERITIES.includes(block.severity)) {
          this._addWarning(`section "${sectionId}" block[${index}] — severity "${block.severity}" غير صالح`);
        }
        break;
      case 'table':
        if (!block.headers || (Array.isArray(block.headers) && block.headers.length === 0)) {
          const fe = { sectionIdx, blockIdx: index, type: 'block', message: 'رؤوس الأعمدة فارغة' };
          this._addError(`section "${sectionId}" block[${index}] — table: "headers" مفقود أو فارغ`, { sectionIdx, blockIdx: index });
          this.fieldErrors.push(fe);
        }
        if (!block.rows || (Array.isArray(block.rows) && block.rows.length === 0)) {
          const fe = { sectionIdx, blockIdx: index, type: 'block', message: 'صفوف الجدول فارغة' };
          this._addWarning(`section "${sectionId}" block[${index}] — table: "rows" فارغ`, { sectionIdx, blockIdx: index });
          this.fieldErrors.push(fe);
        }
        if (block.headersEn !== undefined && block.headers !== undefined && Array.isArray(block.headers) && Array.isArray(block.headersEn) && block.headers.length !== block.headersEn.length) {
          this._addWarning(`section "${sectionId}" block[${index}] — table: عدد الرؤوس (${block.headers.length}) لا يتطابق مع الرؤوس الإنجليزية (${block.headersEn.length})`);
        }
        if (block.rows && Array.isArray(block.rows) && block.headers && Array.isArray(block.headers) && block.headers.length > 0) {
          for (let ri = 0; ri < block.rows.length; ri++) {
            const row = block.rows[ri];
            if (!row.cells || !Array.isArray(row.cells)) {
              this._addWarning(`section "${sectionId}" block[${index}] — table row[${ri}]: "cells" مفقود أو ليس مصفوفة`, { sectionIdx, blockIdx: index });
            } else if (row.cells.length !== block.headers.length) {
              this._addWarning(`section "${sectionId}" block[${index}] — table row[${ri}]: عدد الخلايا (${row.cells.length}) لا يتطابق مع عدد الرؤوس (${block.headers.length})`, { sectionIdx, blockIdx: index });
            }
          }
        }
        break;
      case 'checklist':
        if (block.items && Array.isArray(block.items) && block.items.length === 0) {
          this._addWarning(`section "${sectionId}" block[${index}] — checklist: قائمة الفحص فارغة`, { sectionIdx, blockIdx: index });
        }
        if (block.items && Array.isArray(block.items)) {
          for (let ci = 0; ci < block.items.length; ci++) {
            const item = block.items[ci];
            if (item.textAr !== undefined && item.textAr !== null && item.textAr.trim() === '') {
              this._addWarning(`section "${sectionId}" block[${index}] — checklist item[${ci}]: "textAr" فارغ`, { sectionIdx, blockIdx: index });
            }
            if (item.id === undefined || item.id === null || item.id === '') {
              this._addWarning(`section "${sectionId}" block[${index}] — checklist item[${ci}]: يُفضّل وجود "id" مستقر`, { sectionIdx, blockIdx: index });
            }
          }
        }
        break;
      case 'inspection_point':
        if (!block.criteriaAr) {
          const fe = { sectionIdx, blockIdx: index, type: 'block', message: 'معيار الفحص فارغ' };
          this._addError(`section "${sectionId}" block[${index}] — inspection_point: "criteriaAr" مفقود`, { sectionIdx, blockIdx: index });
          this.fieldErrors.push(fe);
        }
        if (!block.methodAr) this._addWarning(`section "${sectionId}" block[${index}] — inspection_point: "methodAr" مفقود`, { sectionIdx, blockIdx: index });
        if (block.acceptableTolerance !== undefined && block.acceptableTolerance !== null) {
          const tol = block.acceptableTolerance;
          if (typeof tol === 'object' && tol.ar !== undefined && tol.ar !== null && tol.ar.trim() === '') {
            this._addWarning(`section "${sectionId}" block[${index}] — inspection_point: "acceptableTolerance.ar" فارغ`, { sectionIdx, blockIdx: index });
          }
        }
        if (block.acceptanceLimit !== undefined && block.acceptanceLimit !== null) {
          const al = block.acceptanceLimit;
          if (typeof al === 'object' && al.ar !== undefined && al.ar !== null && al.ar.trim() === '') {
            this._addWarning(`section "${sectionId}" block[${index}] — inspection_point: "acceptanceLimit.ar" فارغ`, { sectionIdx, blockIdx: index });
          }
        }
        if (block.markerStyle !== undefined && block.markerStyle !== null && block.markerStyle !== '') {
          if (!MARKER_STYLE_OPTIONS.includes(block.markerStyle)) {
            this._addWarning(`section "${sectionId}" block[${index}] — inspection_point: "markerStyle" "${block.markerStyle}" غير صالح. القيم المقبولة: ${MARKER_STYLE_OPTIONS.join(', ')}`, { sectionIdx, blockIdx: index });
          }
        }
        break;
      case 'image': {
        if (!block.url) {
          this._addWarning(`section "${sectionId}" block[${index}] — image: "url" مفقود`, { sectionIdx, blockIdx: index });
          break;
        }
        const url = block.url;
        if (url.startsWith('blob:') || url.startsWith('data:')) {
          this._addError(`section "${sectionId}" block[${index}] — image: لا يمكن استخدام عناوين blob: أو data:. استخدم مسار ملف صالح مثل assets/images/...`, { sectionIdx, blockIdx: index });
        }
        if (url.startsWith('file:')) {
          this._addError(`section "${sectionId}" block[${index}] — image: لا يمكن استخدام عناوين file:. استخدم مسار ملف صالح مثل assets/images/...`, { sectionIdx, blockIdx: index });
        }
        const ext = url.split('.').pop().toLowerCase();
        const supported = ['png', 'jpg', 'jpeg', 'webp'];
        if (!supported.includes(ext)) {
          this._addWarning(`section "${sectionId}" block[${index}] — صيغة الصورة غير مدعومة: .${ext}. استخدم PNG أو JPG أو JPEG أو WEBP.`);
        }
        if (!url.startsWith('assets/images/')) {
          this._addWarning(`section "${sectionId}" block[${index}] — يجب أن يبدأ مسار الصورة بـ assets/images/`);
        }
        if (/^[A-Za-z]:\\/.test(url)) {
          this._addWarning(`section "${sectionId}" block[${index}] — لا تستخدم مسار الحاسبة مثل C:\\ أو D:\\`);
        }
        if (url.includes('\\')) {
          this._addWarning(`section "${sectionId}" block[${index}] — استخدم / بدلاً من \\ في المسار.`);
        }
        if (/\s/.test(url)) {
          this._addWarning(`section "${sectionId}" block[${index}] — يفضّل أن يكون اسم الصورة بدون فراغات.`);
        }
        break;
      }
      case 'code_reference':
        if (!block.code || (typeof block.code === 'string' && block.code.trim() === '')) {
          this._addError(`section "${sectionId}" block[${index}] — code_reference: "code" مفقود`, { sectionIdx, blockIdx: index });
        }
        if (block.title !== undefined && block.title !== null) {
          if (block.title.ar === undefined || block.title.ar === null || block.title.ar.trim() === '') {
            this._addWarning(`section "${sectionId}" block[${index}] — code_reference: "title.ar" مفقود أو فارغ`, { sectionIdx, blockIdx: index });
          }
        }
        if (block.excerpt !== undefined && block.excerpt !== null) {
          if (block.excerpt.ar !== undefined && block.excerpt.ar !== null && block.excerpt.ar.trim() === '') {
            this._addWarning(`section "${sectionId}" block[${index}] — code_reference: "excerpt.ar" فارغ`, { sectionIdx, blockIdx: index });
          }
        }
        break;
      case 'equipment':
        if (!block.items || (Array.isArray(block.items) && block.items.length === 0)) {
          this._addWarning(`section "${sectionId}" block[${index}] — equipment: "items" فارغ`, { sectionIdx, blockIdx: index });
        }
        if (block.items && Array.isArray(block.items)) {
          for (let ei = 0; ei < block.items.length; ei++) {
            const item = block.items[ei];
            if (!item.nameAr || (typeof item.nameAr === 'string' && item.nameAr.trim() === '')) {
              this._addWarning(`section "${sectionId}" block[${index}] — equipment item[${ei}]: "nameAr" مفقود أو فارغ`, { sectionIdx, blockIdx: index });
            }
          }
        }
        break;
    }
  }

  _checkReview(review) {
    if (!review) return;
    if (review.status && !VALID_REVIEW_STATUSES.includes(review.status)) {
      this._addWarning(`review.status غير صالح: "${review.status}". القيم المقبولة: ${VALID_REVIEW_STATUSES.join(', ')}`);
    }
    this.passed.push('review موجود');
  }

  _checkDraftVsAppReady(data) {
    const signals = [];
    if (!data._meta || !data.review) {
      signals.push('المفاتيح الرئيسية _meta و/أو review مفقودة — هذا يبدو كـ App-ready JSON');
    }
    if (data.sections && Array.isArray(data.sections)) {
      const missingBlocks = data.sections.some(s => s.blocks === undefined || s.blocks === null);
      if (missingBlocks && data.blocks && typeof data.blocks === 'object') {
        signals.push('الأقسام لا تحتوي على blocks ولكن يوجد blocks ككائن علوي — هذا هو تنسيق App-ready');
      }
    }
    if (data.topic && data.topic.summary !== undefined && data.topic.summaryAr === undefined) {
      signals.push('topic.summary موجود بدلاً من topic.summaryAr — هذا هو تنسيق App-ready');
    }
    if (data.topic) {
      const appReadySignals = [];
      if (data.topic.featuredImageUrl) appReadySignals.push('featuredImageUrl');
      if (data.topic.simpleExplanation) appReadySignals.push('simpleExplanation');
      if (appReadySignals.length > 0 && !data.sections) {
        signals.push('يحتوي على حقول قديمة في topic بدون أقسام — هذا يبدو كـ App-ready JSON قديم');
      }
    }
    if (signals.length > 0) {
      this._addWarning('هذا الملف يبدو أنه بتنسيق App-ready JSON، وليس Draft JSON. قد تحتاج إلى تحويل الاستيراد/التصدير.' + ' الإشارات: ' + signals.join(' | '));
    }
  }

  getResult() {
    return {
      errors: this.errors,
      warnings: this.warnings,
      passed: this.passed,
      fieldErrors: this.fieldErrors,
      errorsMeta: this.errorsMeta,
      warningsMeta: this.warningsMeta,
      hasErrors: this.errors.length > 0,
      hasWarnings: this.warnings.length > 0,
      summary: `${this.passed.length} نجاح، ${this.warnings.length} تحذير، ${this.errors.length} خطأ`
    };
  }
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { ValidationEngine };
}