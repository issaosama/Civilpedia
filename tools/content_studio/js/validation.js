class ValidationEngine {
  constructor(draft) {
    this.draft = draft;
    this.errors = [];
    this.warnings = [];
    this.passed = [];
  }

  validate() {
    this.errors = [];
    this.warnings = [];
    this.passed = [];

    if (!this.draft || !this.draft.isValid()) {
      this.errors.push('لم يتم تحميل أي ملف Draft JSON');
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
        this.errors.push(`المفتاح الرئيسي مفقود: "${key}"`);
      } else {
        this.passed.push(`المفتاح الرئيسي "${key}" موجود`);
      }
    }
  }

  _checkMeta(meta) {
    if (!meta) return;
    for (const key of REQUIRED_META) {
      if (meta[key] === undefined || meta[key] === null) {
        this.errors.push(`_meta.${key} مفقود`);
      } else {
        this.passed.push(`_meta.${key} موجود`);
      }
    }
    if (meta.schemaVersion && meta.schemaVersion !== SCHEMA_VERSION) {
      this.warnings.push(`إصدار المخطط (${meta.schemaVersion}) يختلف عن الإصدار الحالي (${SCHEMA_VERSION})`);
    }
  }

  _checkTopic(topic) {
    if (!topic) return;
    for (const key of REQUIRED_TOPIC) {
      if (topic[key] === undefined || topic[key] === null) {
        this.errors.push(`topic.${key} مفقود`);
      } else {
        this.passed.push(`topic.${key} موجود`);
      }
    }
    if (topic.level && !VALID_LEVELS.includes(topic.level)) {
      this.warnings.push(`topic.level غير صالح: "${topic.level}". القيم المقبولة: ${VALID_LEVELS.join(', ')}`);
    }
    if (topic.planKey && !VALID_PLAN_KEYS.includes(topic.planKey)) {
      this.warnings.push(`topic.planKey غير صالح: "${topic.planKey}". القيم المقبولة: ${VALID_PLAN_KEYS.join(', ')}`);
    }
    if (topic.status && !VALID_TOPIC_STATUSES.includes(topic.status)) {
      this.warnings.push(`topic.status غير صالح: "${topic.status}". القيم المقبولة: ${VALID_TOPIC_STATUSES.join(', ')}`);
    }
    if (topic.tags && Array.isArray(topic.tags) && topic.tags.length === 0) {
      this.warnings.push('topic.tags فارغ — يفضل إضافة وسوم');
    }
    if (topic.simpleExplanation) {
      if (topic.simpleExplanation.ar === undefined || topic.simpleExplanation.ar === null) {
        this.warnings.push('simpleExplanation.ar مفقود');
      }
    }
  }

  _checkSections(sections) {
    if (!sections || !Array.isArray(sections)) {
      this.errors.push('sections يجب أن يكون مصفوفة');
      return;
    }
    if (sections.length === 0) {
      this.warnings.push('لا توجد أقسام في هذا الموضوع');
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
        this.errors.push(`section[${index}] "${section.id || '?'}" — "${key}" مفقود`);
      } else {
        this.passed.push(`section "${section.id || '?'}" — "${key}" موجود`);
      }
    }
    if (section.type && !VALID_SECTION_TYPES.includes(section.type)) {
      this.warnings.push(`section "${section.id || '?'}" — النوع "${section.type}" غير معروف`);
    }
    if (section.blocks && Array.isArray(section.blocks)) {
      this.passed.push(`section "${section.id || '?'}" — عدد الكتل: ${section.blocks.length}`);
      for (let j = 0; j < section.blocks.length; j++) {
        this._checkBlock(section.blocks[j], section.id || '?', j);
      }
    } else {
      this.errors.push(`section "${section.id || '?'}" — "blocks" مفقود أو ليس مصفوفة`);
    }
  }

  _checkBlock(block, sectionId, index) {
    for (const key of REQUIRED_BLOCK) {
      if (block[key] === undefined || block[key] === null) {
        this.errors.push(`section "${sectionId}" block[${index}] — "${key}" مفقود`);
      }
    }
    const type = block.type;
    if (type && !VALID_BLOCK_TYPES.includes(type)) {
      this.warnings.push(`section "${sectionId}" block[${index}] — النوع "${type}" غير معروف`);
    }

    switch (type) {
      case 'text':
        if (!block.content) {
          this.errors.push(`section "${sectionId}" block[${index}] — text: "content" مفقود`);
        }
        if (block.variant && !VALID_TEXT_VARIANTS.includes(block.variant)) {
          this.warnings.push(`section "${sectionId}" block[${index}] — text variant "${block.variant}" غير معروف`);
        }
        break;
      case 'execution_step':
        if (block.stepNumber === undefined || block.stepNumber === null) {
          this.warnings.push(`section "${sectionId}" block[${index}] — execution_step: "stepNumber" مفقود`);
        }
        if (!block.description) {
          this.errors.push(`section "${sectionId}" block[${index}] — execution_step: "description" مفقود`);
        }
        break;
      case 'safety_note':
        if (!block.message) {
          this.errors.push(`section "${sectionId}" block[${index}] — safety_note: "message" مفقود`);
        }
        if (block.severity && !VALID_SEVERITIES.includes(block.severity)) {
          this.warnings.push(`section "${sectionId}" block[${index}] — severity "${block.severity}" غير صالح`);
        }
        break;
      case 'table':
        if (!block.headers || (Array.isArray(block.headers) && block.headers.length === 0)) {
          this.errors.push(`section "${sectionId}" block[${index}] — table: "headers" مفقود أو فارغ`);
        }
        if (!block.rows || (Array.isArray(block.rows) && block.rows.length === 0)) {
          this.warnings.push(`section "${sectionId}" block[${index}] — table: "rows" فارغ`);
        }
        break;
      case 'checklist':
        if (block.items && Array.isArray(block.items) && block.items.length === 0) {
          this.warnings.push(`section "${sectionId}" block[${index}] — checklist: قائمة الفحص فارغة`);
        }
        break;
      case 'inspection_point':
        if (!block.criteriaAr) this.errors.push(`section "${sectionId}" block[${index}] — inspection_point: "criteriaAr" مفقود`);
        if (!block.methodAr) this.warnings.push(`section "${sectionId}" block[${index}] — inspection_point: "methodAr" مفقود`);
        break;
      case 'image':
        if (!block.url) this.warnings.push(`section "${sectionId}" block[${index}] — image: "url" مفقود`);
        break;
      case 'equipment':
        if (!block.items || (Array.isArray(block.items) && block.items.length === 0)) {
          this.warnings.push(`section "${sectionId}" block[${index}] — equipment: "items" فارغ`);
        }
        break;
    }
  }

  _checkReview(review) {
    if (!review) return;
    if (review.status && !VALID_REVIEW_STATUSES.includes(review.status)) {
      this.warnings.push(`review.status غير صالح: "${review.status}". القيم المقبولة: ${VALID_REVIEW_STATUSES.join(', ')}`);
    }
    this.passed.push('review موجود');
  }

  getResult() {
    return {
      errors: this.errors,
      warnings: this.warnings,
      passed: this.passed,
      hasErrors: this.errors.length > 0,
      hasWarnings: this.warnings.length > 0,
      summary: `${this.passed.length} نجاح، ${this.warnings.length} تحذير، ${this.errors.length} خطأ`
    };
  }
}
