# Agent 06: Image Brief Agent

## Purpose

Defines the images needed for a topic, including filenames, Arabic captions, and detailed visual descriptions.

The output is a set of image briefs that can be used by a graphic designer or AI image generator to create the actual images.

## Input Expected

- Full Arabic content.
- Topic outline sections.
- Image suggestions from Planner Agent.

## Output Expected

A list of image briefs, each containing:

```
- filename: concrete_slump_cone.png
  captionAr: قالب اختبار الهبوط المخروطي
  purpose: إظهار شكل القالب المستخدم في اختبار الهبوط
  description: قالب معدني مخروطي الشكل، القاعدة 20 سم، الفتحة العلوية 10 سم، الارتفاع 30 سم
  required: true

- filename: slump_measurement.jpg
  captionAr: قياس الهبوط بعد رفع القالب
  purpose: إظهار طريقة قياس الهبوط
  description: خرسانة بعد رفع القالب المخروطي، مع شريط قياس يوضح مقدار الهبوط
  required: true
```

## Cover Image Brief

The agent must now produce a **cover image brief** as the first item in the output, before internal image briefs.

Cover image brief fields:
```
filename: concrete_slump_cover.png
captionAr: صورة غلاف توضح اختبار الهبوط للخرسانة الطازجة
purpose: تستخدم كصورة رئيسية لبطاقة الموضوع وصفحة التفاصيل
visual_description: لقطة أو رسم يوضح الموضوع في سياقه العملي
required_or_optional: recommended
```

The cover image path will be `assets/images/<filename>`. It is stored in `topic.coverImageUrl`, not as an image block inside a section.

**Cover picker in Content Studio:** The topic metadata form includes a "اختيار صورة" button that opens a file picker. When the user selects an image, the filename is sanitized (lowercase, no spaces, no special chars), prefixed with `assets/images/`, and set as `coverImageUrl`. The picker fires a change event that triggers validation and preview updates.

## Rules

- Follow `IMAGE_GUIDELINES.md` strictly.
- Filenames must be lowercase English, no spaces, underscores allowed.
- Allowed extensions: .png, .jpg, .jpeg, .webp.
- Every image brief must have a caption in Arabic.
- Purpose must explain why this image is needed.
- Description must be detailed enough for someone to create the image visually.
- Mark each image as `required: true` or `required: false`.
- **Cover image brief must be listed first**, before internal image briefs.

## What Not to Do

- Do not assume images are already available.
- Do not use copyrighted images.
- Do not reference specific internet sources.
- Do not generate more than 5-7 images per topic unless justified.
- Do not include images that don't add information.
- Do not include decorative images.

## Prompt Template

```
أنت خبير في إعداد موجزات الصور للمحتوى الهندسي. حدد الصور المطلوبة للموضوع التالي.

عنوان الموضوع: [topic title]

المحتوى:
[insert content]

المطلوب:
أولاً: أخرج موجز صورة الغلاف (cover image brief) باستخدام الحقول التالية:
1. filename (اسم الملف)
2. captionAr (تعليق بالعربية)
3. purpose (الغرض)
4. visual_description (وصف بصري)
5. required_or_optional (مطلوبة / موصى بها)

ثانياً: لكل صورة داخلية مطلوبة:
1. اسم الملف (lowercase English، underscores، .png/.jpg/.jpeg/.webp)
2. captionAr (تعليق بالعربية)
3. purpose (الغرض من الصورة)
4. description (وصف بصري مفصل)
5. required (مطلوبة / اختيارية)

اتبع IMAGE_GUIDELINES.md. لا تضع صورًا زخرفية غير مفيدة. ضع موجز صورة الغلاف أولاً.
```
