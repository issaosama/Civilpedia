class AppExporter {

  export(draft) {
    if (!draft || !draft.isValid()) {
      throw new Error('لم يتم تحميل أي ملف Draft JSON');
    }

    const source = draft.toJSON();
    const draftTopic = source.topic || {};
    const draftSections = source.sections || [];

    const topic = this._exportTopic(draftTopic);
    const sections = this._exportSections(draftSections);
    const blocks = this._exportBlocks(draftSections);

    return { topic, sections, blocks };
  }

  _exportTopic(src) {
    return {
      id: src.id || '',
      titleAr: src.titleAr || '',
      titleEn: src.titleEn || '',
      categoryId: src.categoryId || '',
      summary: src.summaryAr || src.summary || '',
      tags: src.tags || [],
      relatedTopicIds: src.relatedTopicIds || [],
      createdAt: src.createdAt || null,
      updatedAt: src.updatedAt || null,
      level: src.level || 'basic',
      planKey: src.planKey || null,
      featuredImageUrl: src.featuredImageUrl || null,
      simpleExplanation: this._localized(src.simpleExplanation),
      beforeWork: this._localized(src.beforeWork),
      duringWork: this._localized(src.duringWork),
      afterWork: this._localized(src.afterWork),
      commonMistakes: this._exportCommonMistakes(src.commonMistakes),
      acceptRejectItems: this._exportAcceptReject(src.acceptRejectItems),
      codeNotes: this._localized(src.codeNotes),
      siteNotes: this._localized(src.siteNotes),
      reportWording: this._localized(src.reportWording),
      relatedToolRoutes: src.relatedToolRoutes || [],
      relatedChecklistIds: src.relatedChecklistIds || []
    };
  }

  _exportCommonMistakes(mistakes) {
    if (!mistakes || !Array.isArray(mistakes)) return [];
    return mistakes.map(m => ({
      ar: m.ar || '',
      en: m.en || ''
    }));
  }

  _exportAcceptReject(items) {
    if (!items || !Array.isArray(items)) return [];
    return items.map(item => ({
      criteriaAr: item.criteriaAr || '',
      criteriaEn: item.criteriaEn || '',
      acceptanceLimitAr: item.acceptanceLimitAr || '',
      acceptanceLimitEn: item.acceptanceLimitEn || '',
      methodAr: item.methodAr || '',
      methodEn: item.methodEn || '',
      isCritical: !!item.isCritical,
      reviewRequired: item.reviewRequired !== false,
      planKey: item.planKey || '',
      codeReference: item.codeReference || ''
    }));
  }

  _exportSections(srcSections) {
    if (!srcSections || !Array.isArray(srcSections)) return [];
    return srcSections.map(s => ({
      id: s.id,
      title: s.title,
      type: s.type,
      order: s.order
    }));
  }

  _exportBlocks(srcSections) {
    if (!srcSections || !Array.isArray(srcSections)) return {};
    const result = {};
    for (const section of srcSections) {
      const sectionId = section.id;
      if (!sectionId) continue;
      const srcBlocks = section.blocks || [];
      result[sectionId] = srcBlocks.map(b => this._exportBlock(b));
    }
    return result;
  }

  _exportBlock(src) {
    const type = src.type;
    const order = src.order;
    let block = { type, order };

    switch (type) {
      case 'text': {
        const content = src.content || {};
        block.content = content.ar || '';
        if (src.variant) block.variant = src.variant;
        break;
      }
      case 'execution_step': {
        const desc = src.description || {};
        const notes = src.notes || {};
        block.step = {
          stepNumber: src.stepNumber || 1,
          description: desc.ar || '',
          notes: notes.ar || ''
        };
        break;
      }
      case 'safety_note': {
        const msg = src.message || {};
        block.note = {
          message: msg.ar || '',
          severity: src.severity || 'medium'
        };
        break;
      }
      case 'table': {
        const caption = src.caption || {};
        block.data = {
          caption: caption.ar || '',
          headers: src.headers || [],
          rows: (src.rows || []).map(r => ({
            cells: r.cells || []
          }))
        };
        break;
      }
      case 'checklist': {
        const title = src.title || {};
        block.title = title.ar || '';
        block.items = (src.items || []).map(item => ({
          textAr: item.textAr || '',
          textEn: item.textEn || '',
          isRequired: item.isRequired !== false,
          category: item.category || ''
        }));
        break;
      }
      case 'inspection_point': {
        block.criteria = src.criteriaAr || '';
        block.criteriaAr = src.criteriaAr || '';
        block.criteriaEn = src.criteriaEn || '';
        block.acceptanceLimitAr = src.acceptanceLimitAr || '';
        block.acceptanceLimitEn = src.acceptanceLimitEn || '';
        block.method = src.methodAr || '';
        block.methodAr = src.methodAr || '';
        block.methodEn = src.methodEn || '';
        block.isCritical = !!src.isCritical;
        if (src.acceptableTolerance) block.acceptableTolerance = src.acceptableTolerance;
        break;
      }
      case 'code_reference': {
        const title = src.title || {};
        const excerpt = src.excerpt || {};
        block.code = src.code || '';
        block.code_title = title.ar || title.en || '';
        block.code_section = src.section || '';
        block.code_excerpt = excerpt.ar || excerpt.en || '';
        break;
      }
      case 'equipment': {
        block.items = (src.items || []).map(item => ({
          nameAr: item.nameAr || '',
          nameEn: item.nameEn || '',
          specification: item.specification || '',
          purpose: item.purpose || ''
        }));
        break;
      }
      case 'image': {
        block.url = src.url || '';
        const caption = src.caption || {};
        block.caption = caption.ar || '';
        break;
      }
      default:
        block = { ...block, ...src };
    }

    return block;
  }

  _localized(obj) {
    if (!obj || typeof obj !== 'object') return { ar: '', en: '' };
    return {
      ar: obj.ar || '',
      en: obj.en || ''
    };
  }
}
