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
    if (topic.simpleExplanation) {
      if (topic.simpleExplanation.ar === undefined || topic.simpleExplanation.ar === null) {
        this._addWarning('simpleExplanation.ar مفقود');
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
      this._addWarning(`section "${sectionId}" block[${index}] — النوع "${type}" غير معروف`);
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
        break;
      case 'checklist':
        if (block.items && Array.isArray(block.items) && block.items.length === 0) {
          this._addWarning(`section "${sectionId}" block[${index}] — checklist: قائمة الفحص فارغة`);
        }
        break;
      case 'inspection_point':
        if (!block.criteriaAr) {
          const fe = { sectionIdx, blockIdx: index, type: 'block', message: 'معيار الفحص فارغ' };
          this._addError(`section "${sectionId}" block[${index}] — inspection_point: "criteriaAr" مفقود`, { sectionIdx, blockIdx: index });
          this.fieldErrors.push(fe);
        }
        if (!block.methodAr) this._addWarning(`section "${sectionId}" block[${index}] — inspection_point: "methodAr" مفقود`);
        break;
      case 'image': {
        if (!block.url) {
          this._addWarning(`section "${sectionId}" block[${index}] — image: "url" مفقود`);
          break;
        }
        const url = block.url;
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
      case 'equipment':
        if (!block.items || (Array.isArray(block.items) && block.items.length === 0)) {
          this._addWarning(`section "${sectionId}" block[${index}] — equipment: "items" فارغ`);
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