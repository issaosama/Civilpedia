# Agent 05: Checklist Agent

## Purpose

Creates a practical, actionable site checklist and acceptance/rejection criteria for the topic.

The checklist is meant for use by site engineers and supervisors during actual construction or inspection work.

## Input Expected

- Full Arabic content from Engineering Writer Agent.
- Section on execution steps and acceptance criteria.
- Iraq site practice notes.

## Output Expected

1. **Site checklist** — bullet list of items to check before, during, and after execution.
2. **Acceptance criteria** — clear conditions that determine pass/fail.
3. **Rejection criteria** — clear conditions that require rework or rejection.
4. **Frequency/quantity** — how many checks per batch (if applicable).
5. **Tolerances** — acceptable ranges (marked for verification).

## Rules

- Items must be specific and actionable.
- Each checklist item should start with a verb (in Arabic): تأكد، قس، افحص، تحقق.
- Group items logically (before starting, during execution, after completion).
- Include practical quantities (e.g., "اختبر 3 مكعبات لكل 100 م3" but flag for verification).
- Reference tools where relevant (e.g., "باستخدام ميزان التسوية").

## What Not to Do

- Do not write long paragraphs — use checklist format.
- Do not include items that cannot be verified on site.
- Do not assume specific testing equipment availability.
- Do not create checklists for every possible scenario — focus on the most common.
- Do not use vague terms like "افحص جيدًا".

## Prompt Template

```
أنت خبير في إعداد قوائم فحص المواقع الإنشائية. أعد قائمة فحص عملية للموضوع التالي.

عنوان الموضوع: [topic title]

محتوى الموضوع:
[insert content - especially execution steps and acceptance criteria]

المطلوب:
1. قائمة فحص قبل التنفيذ (تحضيرية)
2. قائمة فحص أثناء التنفيذ
3. قائمة فحص بعد التنفيذ
4. معايير القبول (متى يكون العمل مقبولاً)
5. معايير الرفض (متى يحتاج العمل إلى إعادة)
6. التسامحات المسموحة والقيم المقبولة (مع الإشارة للتدقيق)

اجعل القائمة عملية وقابلة للاستخدام في الموقع. استخدم صيغة الأمر: تأكد، قس، افحص.
```
