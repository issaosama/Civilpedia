const fs = require('fs');
const path = require('path');
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  HeadingLevel, AlignmentType, BorderStyle, WidthType, ShadingType,
  PageBreak, TableOfContents, Header, Footer, PageNumber, TabStopPosition,
  TabStopType
} = require('docx');

// ── Read source draft ──
const draft = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../../../../draft_jsons/slump_test.draft.json'), 'utf8'));
const topic = draft.topic;
const sections = draft.sections;

// ── Helpers ──
const FONT = 'Calibri';
const DIR = 'rtl'; // We'll set the document to RTL

function p(text, opts = {}) {
  const runs = [];
  if (typeof text === 'string') {
    runs.push(new TextRun({ text, font: FONT, size: 24, ...opts }));
  } else if (Array.isArray(text)) {
    text.forEach(t => {
      if (typeof t === 'string') runs.push(new TextRun({ text: t, font: FONT, size: 24, ...opts }));
      else runs.push(new TextRun({ font: FONT, size: 24, ...opts, ...t }));
    });
  }
  return new Paragraph({ children: runs, alignment: AlignmentType.RIGHT, ...opts.paraOpts });
}

function heading(text, level) {
  const sizes = { 1: 36, 2: 30, 3: 26, 4: 24, 5: 22 };
  return new Paragraph({
    children: [new TextRun({ text, font: FONT, size: sizes[level] || 24, bold: true })],
    heading: level === 1 ? HeadingLevel.HEADING_1 : level === 2 ? HeadingLevel.HEADING_2 : level === 3 ? HeadingLevel.HEADING_3 : undefined,
    alignment: AlignmentType.RIGHT,
    spacing: { before: 300, after: 150 },
  });
}

function spacer(h = 200) {
  return new Paragraph({ spacing: { before: h, after: 0 }, children: [] });
}

function cell(text, opts = {}) {
  return new TableCell({
    children: [new Paragraph({
      children: [new TextRun({ text: String(text), font: FONT, size: 22, ...opts })],
      alignment: AlignmentType.RIGHT,
    })],
    width: opts.width ? { size: opts.width, type: WidthType.PERCENTAGE } : undefined,
    shading: opts.shading ? { fill: opts.shading, type: ShadingType.CLEAR } : undefined,
  });
}

function headerRow(cells) {
  return new TableRow({
    children: cells.map(c => cell(c, { bold: true, shading: 'D9D9D9' })),
    tableHeader: true,
  });
}

function dataRow(cells) {
  return new TableRow({
    children: cells.map(c => cell(c)),
  });
}

function makeTable(headers, rows) {
  return new Table({
    rows: [
      headerRow(headers),
      ...rows.map(r => dataRow(r)),
    ],
    width: { size: 100, type: WidthType.PERCENTAGE },
  });
}

// ── Build document content ──
const children = [];

// ── Cover Page ──
children.push(spacer(800));
children.push(new Paragraph({
  children: [new TextRun({ text: 'Civilpedia', font: FONT, size: 48, bold: true, color: 'C26A0C' })],
  alignment: AlignmentType.CENTER,
}));
children.push(spacer(200));
children.push(new Paragraph({
  children: [new TextRun({ text: 'مراجعة محتوى هندسي', font: FONT, size: 40, bold: true })],
  alignment: AlignmentType.CENTER,
}));
children.push(spacer(100));
children.push(new Paragraph({
  children: [new TextRun({ text: 'اختبار الهبوط Slump Test', font: FONT, size: 36, color: '595959' })],
  alignment: AlignmentType.CENTER,
}));
children.push(spacer(300));
children.push(new Paragraph({
  children: [new TextRun({ text: 'الغرض من الملف: تدقيق وتطوير المحتوى الهندسي قبل نشره داخل التطبيق', font: FONT, size: 24 })],
  alignment: AlignmentType.RIGHT,
}));
children.push(new Paragraph({
  children: [new TextRun({ text: 'يرجى تعديل هذا الملف مباشرة أو كتابة الملاحظات أسفل كل قسم', font: FONT, size: 24, italics: true })],
  alignment: AlignmentType.RIGHT,
}));
children.push(new Paragraph({
  children: [new TextRun({ text: 'ثم إرسال النسخة النهائية مع الصور إلى صاحب العمل', font: FONT, size: 24, italics: true })],
  alignment: AlignmentType.RIGHT,
}));
children.push(new Paragraph({ children: [], spacing: { before: 400 } }));

// ── Message to reviewers ──
children.push(new Paragraph({ children: [new PageBreak()] }));
children.push(heading('رسالة إلى المراجعين', 1));
children.push(p('السلام عليكم ورحمة الله وبركاتة،'));
children.push(spacer(100));
children.push(p([
  'هذا ملف مراجعة لمحتوى موضوع هندسي لتطبيق ',
  { text: 'Civilpedia', bold: true },
  { text: ' بعنوان ' },
  { text: '"اختبار الهبوط Slump Test"', bold: true },
  { text: '.' },
]));
children.push(spacer(100));
children.push(p('المطلوب منكم تدقيق المعلومات هندسياً، تصحيح القيم، إضافة النواقص، تحسين الصياغة إذا تحتاج، وتزويدي بالصور أو الرسومات المناسبة.'));
children.push(spacer(100));
children.push(p('إذا المحتوى تمام، يرجى إرسال النسخة النهائية مع الصور حتى يتم تثبيتها داخل التطبيق.'));
children.push(spacer(100));
children.push(p('لا تحتاجون تعديل أي ملفات برمجية أو JSON. فقط هذا الملف والصور المرفقة.'));
children.push(spacer(100));
children.push(p('وجزاكم الله خيراً.'));

// ── Instructions ──
children.push(spacer(400));
children.push(heading('تعليمات المراجعة', 1));
children.push(p('• عدلوا مباشرة داخل ملف Word أو اكتبوا الملاحظات أسفل كل قسم.'));
children.push(p('• إذا تصححون رقم أو معلومة، يفضل تذكرون المصدر أو الكود إذا متوفر (مثل ACI, ASTM, الكود العراقي).'));
children.push(p('• إذا أكو قيمة غير متأكدين منها، اكتبوا: يحتاج تدقيق.'));
children.push(p('• أرسلوا الصور كمرفقات منفصلة، واذكروا أين يجب وضع كل صورة داخل المحتوى.'));
children.push(p('• يفضل أن تكون الصور واضحة وقابلة للاستخدام داخل التطبيق (ملفات PNG أو JPG).'));
children.push(p('• لا تستخدموا صوراً عليها حقوق نشر إلا إذا مسموح استخدامها بشكل صريح.'));

// ── Topic Content ──
children.push(new Paragraph({ children: [new PageBreak()] }));
children.push(heading('محتوى الموضوع للمراجعة', 1));

// Topic info
children.push(heading('معلومات الموضوع', 2));
children.push(makeTable(
  ['الحقل', 'القيمة'],
  [
    ['العنوان العربي', topic.titleAr || ''],
    ['العنوان الإنكليزي', topic.titleEn || '(فارغ)'],
    ['التصنيف', topic.categoryId || ''],
    ['الملخص', topic.summaryAr || ''],
    ['صورة الغلاف', topic.coverImageUrl || '(لا توجد)'],
    ['المستوى', topic.level || ''],
    ['حالة النشر', 'مسودة — لم تنشر بعد'],
  ]
));
children.push(spacer(200));

// Simple explanation
if (topic.simpleExplanation && topic.simpleExplanation.ar) {
  children.push(heading('شرح مبسط', 2));
  children.push(p(topic.simpleExplanation.ar));
  children.push(spacer(200));
}

// Sections
sections.forEach((section, idx) => {
  children.push(spacer(300));
  children.push(heading(`القسم ${idx + 1}: ${section.title}`, 2));
  if (section.titleEn) {
    children.push(p(`(EN: ${section.titleEn})`, { paraOpts: { spacing: { before: 50, after: 100 } } }));
  }

  section.blocks.forEach(block => {
    switch (block.type) {
      case 'text': {
        const content = block.content?.ar || '';
        children.push(p(content, { paraOpts: { spacing: { before: 80, after: 80 } } }));
        break;
      }
      case 'execution_step': {
        const desc = block.description?.ar || '';
        children.push(p([
          { text: `الخطوة ${block.stepNumber || '?'}: `, bold: true },
          { text: desc },
        ], { paraOpts: { spacing: { before: 60, after: 60 }, indent: { right: 300 } } }));
        break;
      }
      case 'table': {
        const headers = block.headers || [];
        const rows = (block.rows || []).map(r => (r.cells || []).map(c => c || ''));
        if (headers.length > 0) {
          children.push(makeTable(headers, rows));
          children.push(spacer(100));
        }
        break;
      }
      case 'safety_note': {
        const msg = block.message?.ar || '';
        const sev = block.severity || 'low';
        const severityLabels = { high: '⚠️ عالية', medium: '⚡ متوسطة', low: 'ℹ️ منخفضة' };
        children.push(p([
          { text: `${severityLabels[sev] || sev}: `, bold: true },
          { text: msg },
        ], { paraOpts: { spacing: { before: 60, after: 60 } } }));
        break;
      }
      case 'image': {
        const url = block.url || '';
        const caption = block.caption?.ar || '';
        children.push(p([
          { text: `[صورة] ${caption}`, italics: true },
        ], { paraOpts: { spacing: { before: 60, after: 60 } } }));
        children.push(p([
          { text: `   الملف: ${url}`, size: 20, color: '808080' },
        ], { paraOpts: { spacing: { before: 0, after: 80 } } }));
        break;
      }
      case 'checklist': {
        const title = block.title || '';
        const items = block.items || [];
        children.push(p(`[قائمة فحص] ${title}`, { paraOpts: { spacing: { before: 60, after: 40 } } }));
        items.forEach(item => {
          children.push(p(`□ ${item.text?.ar || ''}`, { paraOpts: { indent: { right: 300 } } }));
        });
        break;
      }
      default: {
        // Fallback: try to render any known text
        const content = block.content?.ar || block.description?.ar || '';
        if (content) children.push(p(content, { paraOpts: { spacing: { before: 60, after: 60 } } }));
        break;
      }
    }
  });
});

// ── Values Needing Verification ──
children.push(new Paragraph({ children: [new PageBreak()] }));
children.push(heading('القيم والمعلومات التي تحتاج تدقيق', 1));
children.push(p('القيم التالية تحمل علامة "يحتاج تدقيق" أو "يحتاج تدقيق هندسي". يرجى مراجعتها وتصحيحها.'));

const valuesToVerify = [
  { value: 'أبعاد قالب الهبوط: ارتفاع 300 مم، قطر القاعدة 200 مم، قطر الفتحة العلوية 100 مم', location: 'قسم الأدوات — جدول المعدات', note: '', correction: '', source: '' },
  { value: 'قضيب الدمك: قطر 16 مم، طول 600 مم', location: 'قسم الأدوات — جدول المعدات', note: '', correction: '', source: '' },
  { value: '25 مرة دمك لكل طبقة', location: 'خطوات الاختبار (الخطوة 3) + قائمة الفحص', note: '', correction: '', source: '' },
  { value: '3-7 ثوانٍ لرفع القالب', location: 'خطوات الاختبار (الخطوة 5) + قائمة الفحص', note: '', correction: '', source: '' },
  { value: 'الأساسات المسلحة: 25-75 مم', location: 'جدول القيم المقبولة', note: '', correction: '', source: '' },
  { value: 'الأعمدة والجدران: 50-100 مم', location: 'جدول القيم المقبولة', note: '', correction: '', source: '' },
  { value: 'الكمرات والأسقف: 75-125 مم', location: 'جدول القيم المقبولة', note: '', correction: '', source: '' },
  { value: 'الخرسانة العادية: 25-50 مم', location: 'جدول القيم المقبولة', note: '', correction: '', source: '' },
  { value: 'الخرسانة المضخوخة: 75-150 مم', location: 'جدول القيم المقبولة', note: '', correction: '', source: '' },
  { value: 'الخرسانة الجافة (الطرق): 0-25 مم', location: 'جدول القيم المقبولة', note: '', correction: '', source: '' },
  { value: 'الحد الزمني للخرسانة الطازجة: 15-20 دقيقة', location: 'الأخطاء الشائعة', note: '', correction: '', source: '' },
  { value: 'درجة الحرارة في الصيف العراقي: 40-50 درجة مئوية', location: 'ملاحظات للموقع العراقي', note: '', correction: '', source: '' },
];

children.push(makeTable(
  ['القيمة / المعلومة', 'مكانها داخل الموضوع', 'ملاحظة المراجع', 'التصحيح المقترح', 'المصدر إن وجد'],
  valuesToVerify.map(v => [v.value, v.location, v.note, v.correction, v.source])
));

// ── Images Needed ──
children.push(new Paragraph({ children: [new PageBreak()] }));
children.push(heading('الصور والرسومات المطلوبة', 1));
children.push(p('يرجى مراجعة الصور المطلوبة أدناه وإبداء الرأي أو توفير صور بديلة.'));

const requiredImages = [
  { filename: 'concrete_slump_cover.png', desc: 'صورة غلاف للموضوع — قالب الهبوط والخرسانة الطازجة في موقع إنشائي', placement: 'صورة الغلاف (بطاقة الموضوع + صفحة التفاصيل)', required: 'اختيارية', note: '', canProvide: '' },
  { filename: 'concrete_slump_cone.png', desc: 'قالب الهبوط المخروطي Slump Cone — شكل وأبعاد القالب', placement: 'قسم الأدوات', required: 'مطلوبة', note: '', canProvide: '' },
  { filename: 'tamping_rod.jpg', desc: 'قضيب الدمك Tamping Rod — شكل وأبعاد القضيب', placement: 'قسم الأدوات', required: 'مطلوبة', note: '', canProvide: '' },
  { filename: 'slump_measurement.jpg', desc: 'قياس مقدار الهبوط — طريقة القياس الصحيحة', placement: 'قسم قراءة النتيجة', required: 'مطلوبة', note: '', canProvide: '' },
  { filename: 'slump_types.png', desc: 'أنواع الهبوط الثلاثة: حقيقي، قص، انهيار', placement: 'قسم قراءة النتيجة', required: 'مطلوبة', note: '', canProvide: '' },
  { filename: 'slump_test_setup.jpg', desc: 'تجهيزات الاختبار الكاملة في الموقع (اختياري)', placement: 'قسم الأدوات أو قسم مستقل', required: 'اختيارية', note: '', canProvide: '' },
];

children.push(makeTable(
  ['اسم الصورة', 'وصف الصورة المطلوبة', 'أين توضع', 'ضرورية؟', 'ملاحظات المراجع', 'هل تستطيع توفير صورة حقيقية؟'],
  requiredImages.map(img => [img.filename, img.desc, img.placement, img.required, img.note, img.canProvide])
));

children.push(spacer(200));
children.push(p('ملاحظة: يرجى إرسال الصور كمرفقات منفصلة مع ذكر اسم الملف لكل صورة.'));

// ── Reviewer Final Notes ──
children.push(new Paragraph({ children: [new PageBreak()] }));
children.push(heading('الملاحظات النهائية للمراجع', 1));

children.push(spacer(100));
children.push(p('اسم المراجع: ________________________________________'));
children.push(p('الاختصاص: ________________________________________'));
children.push(p('سنوات الخبرة: ________________________________________'));
children.push(p('تاريخ المراجعة: ________________________________________'));
children.push(spacer(200));

children.push(heading('القرار النهائي', 3));
children.push(p('□ مقبول'));
children.push(p('□ مقبول بعد تعديلات بسيطة'));
children.push(p('□ يحتاج تعديلات مهمة'));
children.push(p('□ غير مقبول حالياً'));
children.push(spacer(200));

children.push(heading('الملاحظات النهائية', 3));
children.push(p(''));
children.push(p(''));
children.push(p(''));

children.push(spacer(200));
children.push(heading('الصور المرفقة مع هذا الملف', 3));
children.push(p(''));
children.push(p(''));

children.push(spacer(200));
children.push(heading('هل النسخة جاهزة للنشر داخل التطبيق؟', 3));
children.push(p('□ نعم'));
children.push(p('□ لا'));
children.push(spacer(200));
children.push(p('شكراً لوقتك وجهدك في المراجعة.', { paraOpts: { alignment: AlignmentType.CENTER } }));

// ── Create Document ──
const doc = new Document({
  title: 'مراجعة محتوى هندسي — اختبار الهبوط Slump Test',
  description: 'مراجعة المحتوى الهندسي لموضوع اختبار الهبوط في تطبيق Civilpedia',
  creator: 'Civilpedia Content Team',
  defaultTabStop: 36,
  styles: {
    default: {
      document: {
        run: { font: FONT, size: 24 },
        paragraph: { alignment: AlignmentType.RIGHT },
      },
      heading1: {
        run: { font: FONT, size: 36, bold: true, color: '1F1D16' },
        paragraph: { spacing: { before: 360, after: 180 } },
      },
      heading2: {
        run: { font: FONT, size: 30, bold: true, color: '2A2620' },
        paragraph: { spacing: { before: 240, after: 120 } },
      },
      heading3: {
        run: { font: FONT, size: 26, bold: true },
        paragraph: { spacing: { before: 200, after: 100 } },
      },
    },
  },
  sections: [
    {
      properties: {
        page: {
          margin: { top: 1440, bottom: 1440, right: 1440, left: 1440 },
          rtl: true,
        },
      },
      children,
    },
  ],
});

// ── Generate DOCX ──
const outputPath = path.resolve(__dirname, 'slump_test_engineer_review.docx');
Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync(outputPath, buffer);
  console.log(`✅ Word file created: ${outputPath}`);
  console.log(`   Size: ${(buffer.length / 1024).toFixed(1)} KB`);
}).catch(err => {
  console.error('❌ Error creating document:', err);
  process.exit(1);
});
