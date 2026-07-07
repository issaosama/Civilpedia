# Image Guidelines for Civilpedia Content

## Allowed Formats

| Format | Extension | Status |
|---|---|---|
| PNG | .png | ✅ Allowed |
| JPEG | .jpg | ✅ Allowed |
| JPEG | .jpeg | ✅ Allowed |
| WebP | .webp | ✅ Allowed |
| HEIC | .heic | ❌ Avoid |
| SVG | .svg | ❌ Avoid |
| BMP | .bmp | ❌ Avoid |
| TIFF | .tiff | ❌ Avoid |
| AVIF | .avif | ❌ Avoid |

## File Naming Rules

- Use **lowercase English** letters only.
- No spaces — use underscores `_` instead.
- No special characters (parentheses, brackets, etc.).
- Filename should clearly describe the image content.

**Good examples:**
```
concrete_slump_cone.png
rebar_cover_spacer.jpg
curing_water_hose.webp
cube_compression_test.jpg
```

**Bad examples:**
```
اختبار_الهبوط.jpeg        ← Arabic characters
Concrete Slump Cone.png   ← Spaces and capitals
test (2).jpg              ← Parentheses and spaces
IMG_20260705_143022.png   ← Generic camera name
```

## Path Convention

In Draft JSON, image paths must follow this pattern:
```
assets/images/file_name.png
```

- Always start with `assets/images/`.
- Use forward slashes `/`.
- Never use absolute paths (`C:\...`, `D:\...`).
- Never use backslashes `\`.
- Never use relative paths like `../images/`.

## Source Rules

- AI agents must NOT assume images are already available in the repository.
- The Image Brief Agent outputs **image briefs**, not actual image files.
- Avoid random internet images unless the license is known and documented.
- Prefer these sources:
  - Original site photos taken by the team.
  - AI-generated diagrams created specifically for the topic.
  - Simple technical diagrams (drawn or generated).
  - Internally prepared illustrations.

## Cover Image

Every topic should have a **optional cover image** (`coverImageUrl`) used as the main thumbnail in the topic card and hero in the topic detail.

**Cover picker in Content Studio:** The topic metadata form includes a "اختيار صورة" button that opens a file picker. When selected, the filename is sanitized (lowercase, no spaces, no special chars), prefixed with `assets/images/`, and set as `coverImageUrl`. The change event triggers validation and preview updates.

### Cover Image Rules

- The `coverImageUrl` field is set at the topic level (not inside a section block).
- It is different from image blocks inside sections — image blocks are placed inside section content.
- The cover image follows the same path and format rules as regular images.
- If no cover image is set, the app displays a gradient/icon fallback.
- Missing cover image files do not crash the app — a placeholder is shown.

### Cover Image Brief

The Image Brief Agent must now produce a **cover image brief** in addition to internal image briefs:

```json
{
  "filename": "concrete_slump_cover.png",
  "captionAr": "صورة غلاف توضح اختبار الهبوط للخرسانة الطازجة",
  "purpose": "تستخدم كصورة رئيسية لبطاقة الموضوع وصفحة التفاصيل",
  "visual_description": "لقطة أو رسم يوضح قالب الهبوط والخرسانة الطازجة في موقع إنشائي",
  "required_or_optional": "recommended"
}
```

The cover image brief is listed first, before internal image briefs.

## Image Brief Format

Every image brief (including cover) must include:

```json
{
  "filename": "file_name.png",
  "captionAr": "عنوان الصورة بالعربية",
  "purpose": "Why this image is needed",
  "description": "Suggested visual description for the person creating the image",
  "required": true
}
```

| Field | Description |
|---|---|
| `filename` | Must follow naming rules above |
| `captionAr` | Arabic caption describing the image |
| `purpose` | Short explanation of what the image shows |
| `description` | Detailed visual description (useful for AI generation or illustrator) |
| `required` | `true` = essential, `false` = nice to have |

## Image Placement in Content

- Place images near the relevant text or step.
- Every image must have at least an Arabic caption.
- Images should add information, not just decorate.
- Use images to show:
  - Equipment and tools.
  - Step-by-step procedure visuals.
  - Correct vs. incorrect examples.
  - Site photographs of real conditions.
  - Technical diagrams (cross-sections, details).

## Caption Rules

- Captions are in Arabic (`caption.ar`).
- English caption (`caption.en`) can be empty unless structurally required.
- Captions should describe what the image shows, not interpret it.
- Keep captions to 1-2 sentences.

## What Not to Do

- Do not use images with watermarks.
- Do not use copyrighted images from textbooks or websites.
- Do not generate image briefs for decorative images.
- Do not use images without a clear purpose.
- Do not include images that require special rendering in Content Studio.
