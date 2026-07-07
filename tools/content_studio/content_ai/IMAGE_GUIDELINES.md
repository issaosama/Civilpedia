# Image Guidelines for Civilpedia Content

## 1. Official Image Standards

### 1.1 Cover Image / صورة الغلاف
| Property | Value |
|---|---|
| Aspect ratio | **16:9** |
| Recommended size | **1600 × 900 px** |
| Minimum size | 1200 × 675 px |
| Fit behavior | cover / crop |
| Usage | Topic cards, encyclopedia listing cards, topic detail hero |
| Safe area | Keep the most important subject centered — edges may be cropped |
| Text | Avoid placing text or critical detail near the edges |

### 1.2 Article Image / صورة داخل المقال
| Property | Value |
|---|---|
| Preferred aspect ratio | **4:3** |
| Recommended size | **1200 × 900 px** |
| Alternative wide ratio | 16:9 at 1200 × 675 px |
| Fit behavior | contain (full image visible, no cropping) |
| Usage | Section images, equipment photos, site photos, step photos |

### 1.3 Engineering Diagram / مخطط أو رسم توضيحي
| Property | Value |
|---|---|
| Preferred aspect ratio | **4:3** |
| Recommended size | **1200 × 900 px** |
| Styling | Clean labels, high contrast, centered elements |
| Readability | Avoid small, unreadable text or low-contrast lines |

### 1.4 Tall Process Image / صورة طولية
| Property | Value |
|---|---|
| Aspect ratio | **3:4** |
| Recommended size | **900 × 1200 px** |
| Use | Only when a vertical orientation is essential (e.g., a multi-step vertical graphic) |
| Caution | Must not break preview or card layout |

## 2. File Format & Naming Rules

### Allowed Formats
| Format | Extension | Status |
|---|---|---|
| PNG | `.png` | ✅ Allowed |
| JPEG | `.jpg` | ✅ Allowed |
| JPEG | `.jpeg` | ✅ Allowed |
| WebP | `.webp` | ✅ Allowed |
| HEIC | `.heic` | ❌ Avoid |
| SVG | `.svg` | ❌ Avoid |
| BMP | `.bmp` | ❌ Avoid |
| TIFF | `.tiff` | ❌ Avoid |
| AVIF | `.avif` | ❌ Avoid |

### Required Path Format
```
assets/images/file_name.png
```

### Rules
1. Must start with `assets/images/`
2. Use forward slashes `/` only — never backslashes `\`
3. Must not be a Windows absolute path (`C:\...`, `D:\...`)
4. Must not contain spaces
5. Filename should be lowercase English only
6. Use underscores `_` instead of spaces
7. No special characters (parentheses `()`, brackets `[]`, `&`, `%`, `#`)
8. No Arabic letters in filenames — Arabic is for captions only
9. No base64-embedded images
10. Do not automatically copy or upload files — send them separately

### Good Examples
```
concrete_slump_cone.png
rebar_cover_spacer.jpg
curing_water_hose.webp
cube_compression_test.jpg
slump_measurement_diagram.png
```

### Bad Examples
```
اختبار_الهبوط.jpeg          ← Arabic characters
Concrete Slump Cone.png     ← Spaces and capitals
test (2).jpg                ← Parentheses and spaces
IMG_20260705_143022.png     ← Generic camera name — use descriptive name
D:\assets\image.png         ← Windows absolute path
assets\images\test.png      ← Backslashes
```

## 3. Image Brief Requirements

Every image brief (including cover) must include:

```json
{
  "filename": "concrete_slump_cone.png",
  "captionAr": "عنوان الصورة بالعربية",
  "purpose": "Why this image is needed",
  "description": "Detailed visual description for the creator",
  "required": true,
  "imageType": "cover | article | diagram | tall"
}
```

| Field | Description |
|---|---|
| `filename` | Must follow naming rules above |
| `captionAr` | Arabic caption (required for every image) |
| `purpose` | Short explanation of what the image shows |
| `description` | Detailed visual description (useful for AI generation or illustrator) |
| `required` | `true` = essential, `false` = nice to have |
| `imageType` | Type of image: `cover`, `article`, `diagram`, or `tall` |

The **cover image brief** must be listed first in the image briefs array.

Every brief should specify the **recommended dimensions** based on its `imageType`:
- `cover` → 1600×900 (16:9)
- `article` → 1200×900 (4:3) or 1200×675 (16:9)
- `diagram` → 1200×900 (4:3)
- `tall` → 900×1200 (3:4)

## 4. Image Placement in Content

- Place images near the relevant text or step
- Every image must have at least an Arabic caption
- Images should **add information**, not just decorate
- Use images to show:
  - Equipment and tools
  - Step-by-step procedure visuals
  - Correct vs. incorrect examples
  - Site photographs of real conditions
  - Technical diagrams (cross-sections, details)
- Do NOT add images that are purely decorative

## 5. Caption Rules

- Captions are in Arabic (`caption.ar`)
- English caption (`caption.en`) can be empty unless structurally required
- Captions should describe what the image shows, not interpret it
- Keep captions to 1–2 sentences
- Every image block must have a caption

## 6. Source & Legal Rules

- Prefer these sources (in order):
  1. Original site photos taken by the team
  2. AI-generated diagrams created specifically for the topic
  3. Simple technical diagrams (drawn or generated)
  4. Internally prepared illustrations
- **Do NOT use:**
  - Watermarked images
  - Copyrighted images from textbooks, websites, or other publications without written permission
  - Screenshots with unreadable text
  - Very small or blurry images
  - Random internet images unless the license is known and documented
  - Images with important content near the edges (will be cropped on cover images)
- AI agents must NOT assume images are already available in the repository
- The Image Brief Agent outputs **image briefs**, not actual image files

## 7. Content Studio Image Display

### Cover Image
- Displayed in topic detail hero with **16:9 crop** (`object-fit: cover`)
- Fixed height: 200px in both Flutter and Content Studio preview
- If missing: placeholder with icon, path, and Arabic message shows
- Content Studio applies border-radius + subtle shadow matching Flutter

### Article Images
- Displayed with **contain** fit (full image visible, no crop)
- Matching Flutter: `BoxFit.contain` → the image fills available width at its natural aspect ratio
- If missing: placeholder with icon, path, and Arabic message shows
- Content Studio preview matches Flutter border-radius and surface style

### Validation in Content Studio
- Path must start with `assets/images/`
- Only `.png`, `.jpg`, `.jpeg`, `.webp` allowed
- No spaces, no backslashes, no Windows absolute paths
- Missing image URL produces a **warning**, not an error (images are optional)
- Empty image URL on an image block warns that the image is missing

## 8. Contributor Handoff Rules

When sending images to include in a topic:

### What to Send
- Image files (PNG, JPG, or WebP)
- A note of where each image should appear (section + position)
- Arabic caption for each image

### File Preparation
- Rename files to **lowercase English** using underscores for spaces
- Use descriptive names: `concrete_slump_cone.png` not `IMG_001.jpg`
- Crop/reduce to recommended sizes before sending
- Do NOT embed images in the JSON file

### What NOT to Do
- Do not send images with:
  - Watermarks
  - Copyrighted content
  - Arabic or special characters in filenames
  - Spaces in filenames
- Do not embed images as base64
- Do not use HEIC, SVG, BMP, TIFF, or AVIF formats

### Checklist Before Publishing
1. Every image path starts with `assets/images/`
2. Every filename is lowercase English with no spaces
3. Every image has an Arabic caption
4. Cover image is 16:9 with main subject centered
5. Article images use preferred 4:3 ratio (or 16:9 or 3:4 where appropriate)
6. Preview checked in Content Studio (light + dark mode)
7. Preview matches Flutter app rendering
8. No watermarks, no copyright issues
9. All images are readable on mobile (not too small, not too detailed)
10. Images add information — none are purely decorative
