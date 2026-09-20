# CIVILPEDIA V1-R10.1 — VISUAL DIRECTION & TOKEN FREEZE

PHASE: V1-R10.1
TITLE: Visual Direction & Token Freeze
STATUS: DRAFT — AWAITING ARCHITECT / USER VISUAL APPROVAL
AUTHORITY: V1-R10-CONTRACT-v1
MODE: SPECIFICATION / VISUAL APPROVAL ONLY — NO PRODUCTION FLUTTER IMPLEMENTATION

---

## 1. Purpose and authority boundary

This document is the R10.1 visual-system candidate. It records measured brand
evidence and an implementation-ready visual specification for later approval.
It does not authorize or implement production Flutter changes.

The frozen V1-R10 contract remains authoritative. In particular:

- Civilpedia uses Logo Amber, Logo Blue, and warm neutrals;
- themed Material is the generic component authority;
- Arabic RTL is the default and English LTR is first-class;
- light and dark themes are first-class;
- Tools remains a launcher into dedicated tool/calculator routes;
- the accepted animated splash and all startup invariants remain unchanged;
- R11 owns Projects functionality, R12 owns calculator engineering semantics,
  and R13 owns Encyclopedia content completion;
- `Editor -> Preview -> Flutter` parity remains mandatory;
- production implementation begins only after R10.1 is closed and R10.2 is
  explicitly authorized.

No material conflict was found between this discovery and the frozen contract.

---

## 2. Canonical identity source

### 2.1 Asset inventory

| Asset | Format | Dimensions | Transparency | Role / quality |
|---|---:|---:|---|---|
| `assets/branding/app_icon_adaptive_foreground.png` | PNG | 1254 × 1254 | Binary alpha, transparent background | Highest-resolution isolated mark; best source for mark geometry and color measurement |
| `assets/branding/app_icon.png` | PNG | 1254 × 1254 | Opaque RGB | Launcher-ready square composition; mark fills the canvas and is partially cropped by the icon treatment |
| `assets/branding/splash_logo.png` | PNG | 1254 × 1254 | Opaque RGB | Highest-resolution complete lockup: mark, CIVILPEDIA wordmark, and tagline |
| `assets/branding/splash_logo_display.png` | PNG | 891 × 836 | Binary alpha, transparent background | Display-cropped complete lockup used by the approved Flutter splash |

No SVG, PDF, or other vector master is present in the repository. These four
PNG files are the complete repository branding set.

### 2.2 Selected authority

- **Primary measurement source:**
  `assets/branding/app_icon_adaptive_foreground.png`. The isolated mark occupies
  the largest source area, retains transparency, and preserves the official
  facets without a background or icon mask.
- **Complete-lockup authority:** `assets/branding/splash_logo.png` for the
  CIVILPEDIA wordmark and `BUILD • LEARN • CONNECT` relationship.
- **Production display corroboration:**
  `assets/branding/splash_logo_display.png`, which preserves the same lockup in
  a transparent display crop.

The source pixels must not be recolored or approximated inside the logo. UI
tokens below are representatives for product interface roles, not replacements
for the logo artwork.

### 2.3 Measured source colors

The logo is not flat-color artwork.

- The Amber triangle is a restrained diagonal golden-orange gradient. Measured
  opaque interior pixels run approximately from `#FEAC04` in the bright upper
  region to `#F47F00` at the deep lower edge. The sampled interior average is
  approximately `#FD9D03`; the stable central source representative is
  `#FE9E03`.
- The Blue C is a multi-facet gradient system. Representative visible samples
  include bright `#0164FB`, primary `#0155DA`, mid/deep `#0051D0`,
  `#0141B1`, and `#013595`. The complete source also contains smaller extremes
  near `#55A7FE` and `#001772`.
- The isolated mark's sampled Blue average is approximately `#0155DA`.
- The CIVILPEDIA wordmark's sampled Blue average is approximately `#063284`.
- The tagline is a quieter steel-blue, sampled around `#41638A`.

### 2.4 Gradient policy

- Preserve source gradients inside official logo assets and approved
  logo-derived artwork.
- A small, non-text decorative brand motif may use a controlled Blue facet
  gradient or Amber edge accent when it is explicitly part of an approved
  visual reference.
- Do not apply logo gradients to buttons, chips, fields, navigation containers,
  ordinary cards, semantic status surfaces, or body text.
- Interface controls use the flat representatives defined below. This keeps
  state, contrast, and hierarchy deterministic.

---

## 3. Current theme audit

### 3.1 Existing system

- Light identity currently uses `primary #E98A1E`, `primaryDark #C26A0C`,
  approximate `brandBlue #2E6BC6`, `pageBackground #FAF7F2`, white elevated
  surfaces, and warm secondary surface `#F6F1E8`.
- Dark identity currently uses warm-black `#15140F`, surfaces `#1F1D16` and
  `#24221A`, warm light text, and restrained borders.
- Cairo is supplied through `google_fonts` for both Arabic and English.
- The existing spacing scale is `4, 8, 12, 16, 20, 24, 40`.
- Existing radii are `8, 12, 14, 18, 26, 30, 28, full`.
- Existing motion is 200 ms / 350 ms with an ease-out curve.
- Existing Material theming covers ColorScheme, app bar, card, bottom
  navigation, elevated button, inputs, divider, and dialog.

### 3.2 Gaps to resolve in later authorized slices

- `#E98A1E` is a prior UI Amber, not the official `#FE9E03` source
  representative.
- White on current Amber is only about `2.59:1`; white on official Amber is
  about `2.08:1`. `onPrimary = white` is therefore unsafe for normal text and
  meaningful icons on an Amber fill.
- Existing `brandBlue #2E6BC6` is a reasonable approximation but is less
  saturated and lighter in character than the measured source representative.
- Dark `ColorScheme.secondary` currently points to a light Amber rather than a
  supporting Logo Blue, weakening the two-color identity.
- `background #DBD6CB` and `pageBackground #FAF7F2` overlap in purpose;
  `surface`, `surfacePrimary`, and legacy lavender surface aliases also create
  role ambiguity.
- App bars can become large dark-orange areas, which conflicts with the
  restrained-Amber direction.
- Directly relevant shared/state seams still contain raw grey/white/black
  values, including shimmer/state widgets and some calculator actions.
- Home category cards still contain a feature-local multi-color palette.
- `GlassCard` and the floating shell use blur/translucency; the final language
  should prefer calm opaque surfaces and use blur only where already justified,
  never as a broad glassmorphism system.
- Filled, outlined, text, destructive, chip, snackbar, and bottom-sheet
  variants are not yet expressed as a complete theme family.

### 3.3 Compatibility policy

- Retain existing public token names as compatibility aliases during R10.2
  where immediate removal would create unrelated churn.
- Introduce semantic authority first, then migrate surfaces when touched.
- Do not rename tokens solely for aesthetic purity.
- `CivilSurfaceCard`, `CivilAppBar`, `SectionHeader`, and Material component
  themes remain the intended consolidation path. Do not create thin wrappers
  around every Material control.

---

## 4. Brand roles

### 4.1 Logo Amber — signature

Use for selected accents, high-value primary actions, active chips, small
badges, focused highlights, and limited signature moments. Amber must remain
scarce enough to signal importance. Large page backgrounds, ordinary cards,
long text, and warning authority must not use brand Amber.

### 4.2 Logo Blue — technical authority

Use for links, information, secondary actions, focus treatment, engineering
iconography, result emphasis, and complementary brand presence. Blue supports
Amber; it does not create a second competing primary CTA hierarchy.

### 4.3 Warm neutrals — structural system

Use for page backgrounds, cards, input fills, borders, typography, navigation
containers, and large layout areas. Neutral structure should carry most of the
screen so brand color remains deliberate.

### 4.4 Semantic colors — independent authority

Success, warning, error, and information retain distinct semantic hues and
always pair color with iconography and/or text. Brand Amber is not the sole
warning signal.

---

## 5. Candidate production tokens

These are the exact R10.1 candidates for visual approval. Names describe roles;
R10.2 may map them onto existing compatible names without needless churn.

### 5.1 Light palette

| Token | Value | Intended role |
|---|---:|---|
| `brandAmber` | `#FE9E03` | Official flat Amber representative; primary fills and signature accents |
| `brandAmberPressed` | `#A95400` | Accessible dark Amber for pressed states, selected labels/icons, and Amber-on-light foreground |
| `brandAmberSoft` | `#FFF1DB` | Selected/active container, quiet badge, soft highlight |
| `brandBlue` | `#0155DA` | Measured Logo Blue representative; links, focus, information, secondary action |
| `brandBlueDark` | `#063284` | Wordmark-derived deep Blue; strong technical text/icon role |
| `brandBlueSoft` | `#E8F1FF` | Quiet informational or Blue-selected container |
| `background` | `#FAF7F2` | Primary warm page background |
| `surface` | `#FFFFFF` | Standard card/control surface |
| `surfaceSecondary` | `#F6F1E8` | Warm grouped surface, input fill, secondary panel |
| `surfaceElevated` | `#FFFDFC` | Dialog/sheet/floating surface when separation is required |
| `textPrimary` | `#221F18` | Primary text |
| `textSecondary` | `#665E55` | Supporting text |
| `textMuted` | `#70685F` | Hints and metadata; remains normal-text accessible on warm input surfaces |
| `textOnAmber` | `#221F18` | Text/icons on official Amber |
| `textOnBlue` | `#FFFFFF` | Text/icons on Logo Blue or deep Blue |
| `border` | `#DED5C7` | Subtle structural divider/card boundary where contrast is not the sole cue |
| `borderStrong` | `#8C8174` | Input/control boundary where a 3:1-class edge is required |
| `divider` | `#EAE2D7` | Quiet internal separation |
| `success` | `#267A4B` | Success text/icon/strong boundary |
| `successSoft` | `#E8F4EC` | Success container |
| `warning` | `#9A5B00` | Warning text/icon/strong boundary |
| `warningSoft` | `#FFF2D8` | Warning container, independent from brand Amber |
| `error` | `#B3261E` | Error/destructive text, icon, and strong boundary |
| `errorSoft` | `#FDECEA` | Error container |
| `info` | `#245FAE` | Semantic information authority |
| `infoSoft` | `#E8F1FF` | Information container; may alias `brandBlueSoft` |
| `disabled` | `#9D958A` | Disabled foreground only; disabled state also uses shape/opacity |
| `disabledSurface` | `#EEE8DE` | Disabled control fill |
| `scrim` | `#221F18` at 48% | Modal scrim |

### 5.2 Dark palette

| Token | Value | Intended role |
|---|---:|---|
| `darkBackground` | `#121820` | Navy-charcoal page background; never pure black |
| `darkSurface` | `#19212B` | Standard card/control surface |
| `darkSurfaceSecondary` | `#202A35` | Grouped/input surface |
| `darkSurfaceElevated` | `#273340` | Dialog, sheet, floating navigation |
| `darkTextPrimary` | `#F5F1E8` | Warm primary text |
| `darkTextSecondary` | `#C9C2B7` | Supporting text |
| `darkTextMuted` | `#9D968C` | Metadata/hints |
| `darkBorder` | `#3A4653` | Subtle structural boundary |
| `darkBorderStrong` | `#687482` | Input/control edge when the edge is an essential cue |
| `darkBrandAmber` | `#FFB02E` | Brighter signature Amber for dark surfaces |
| `darkTextOnAmber` | `#241A0E` | Foreground on dark-mode Amber |
| `darkBrandBlue` | `#63A4FF` | Accessible supporting Blue on dark surfaces |
| `darkTextOnBlue` | `#0B1625` | Foreground on bright dark-mode Blue |
| `darkSuccess` | `#6FCF97` | Success foreground |
| `darkSuccessSoft` | `#173626` | Success container |
| `darkWarning` | `#FFC45C` | Warning foreground |
| `darkWarningSoft` | `#3B2A10` | Warning container |
| `darkError` | `#FF8A80` | Error/destructive foreground |
| `darkErrorSoft` | `#421E1D` | Error container |
| `darkInfo` | `#78B2FF` | Information foreground |
| `darkInfoSoft` | `#152F50` | Information container |
| `darkDisabled` | `#717983` | Disabled foreground |
| `darkDisabledSurface` | `#252E38` | Disabled fill |
| `darkScrim` | `#0B1016` at 72% | Modal scrim |

---

## 6. Contrast validation

Ratios use WCAG relative luminance. Normal text targets `4.5:1`; large text and
meaningful non-text UI boundaries target at least `3:1`.

| Combination | Ratio | Decision |
|---|---:|---|
| `textPrimary` on `background` | 15.39:1 | Pass |
| `textPrimary` on `surface` | 16.44:1 | Pass |
| `textSecondary` on `surface` | 6.37:1 | Pass |
| `textMuted` on `surfaceSecondary` | 4.87:1 | Pass for hints/metadata |
| `textOnAmber` on `brandAmber` | 7.91:1 | Pass; freeze dark foreground direction |
| white on `brandAmber` | 2.08:1 | **Fail**; prohibited for meaningful text/icons |
| white on existing `#E98A1E` | 2.59:1 | **Fail**; existing `onPrimary` assumption must not survive Amber adoption |
| `textOnBlue` on `brandBlue` | 6.34:1 | Pass |
| `brandAmberPressed` on white | 5.31:1 | Pass for selected label/icon |
| `brandAmberPressed` on `brandAmberSoft` | 4.77:1 | Pass for selected navigation/chip labels |
| `borderStrong` on `surfaceSecondary` | 3.39:1 | Pass for essential control boundary |
| `brandBlue` focus edge on `surfaceSecondary` | 5.63:1 | Pass |
| `darkTextPrimary` on `darkBackground` | 15.83:1 | Pass |
| `darkTextPrimary` on `darkSurface` | 14.40:1 | Pass |
| `darkTextSecondary` on `darkSurface` | 9.19:1 | Pass |
| `darkTextMuted` on `darkSurface` | 5.55:1 | Pass |
| `darkTextOnAmber` on `darkBrandAmber` | 9.36:1 | Pass |
| `darkBrandBlue` on `darkSurface` | 6.40:1 | Pass |
| `darkTextOnBlue` on `darkBrandBlue` | 7.17:1 | Pass |
| `darkBorderStrong` on `darkSurface` | 3.41:1 | Pass for essential control boundary |
| light semantic strong colors on white | 5.29–6.54:1 | Pass |
| dark semantic foregrounds on `darkSurface` | 7.11–10.28:1 | Pass |

Subtle `border` and `darkBorder` are intentionally quieter than 3:1 and must
not be the only cue for focus, error, selection, or an interactive boundary.
Those states use `borderStrong`, Blue focus, semantic color, iconography, and/or
text.

---

## 7. Typography hierarchy

Cairo remains canonical for Arabic and English. The hierarchy is restrained,
maps onto Material TextTheme, and prioritizes Arabic line-height and legibility.

| Product role | Material role | Size | Weight | Line height | Use |
|---|---|---:|---:|---:|---|
| Display / result | `displayLarge` | 32 | 700 | 1.20 | Calculator result or rare high-value metric; not ordinary page chrome |
| Hero / greeting | `headlineLarge` | 24 | 700 | 1.35 | Home greeting or major reference headline |
| Screen title | `headlineMedium` | 20 | 700 | 1.40 | App bar/screen heading |
| Section title | `titleLarge` | 18 | 600 | 1.45 | Major section heading |
| Card title | `titleMedium` | 16 | 600 | 1.50 | Card/tool/result title |
| Compact title | `titleSmall` | 14 | 600 | 1.50 | Compact rows and status cards |
| Primary body | `bodyLarge` | 16 | 400 | 1.65 | Important explanatory copy |
| Body | `bodyMedium` | 14 | 400 | 1.65 | Standard content and form help |
| Metadata | `bodySmall` | 12 | 400 | 1.60 | Secondary metadata; never critical instruction alone |
| Action label | `labelLarge` | 14 | 600 | 1.40 | Buttons and primary chips |
| Compact label | `labelMedium` | 12 | 600 | 1.40 | Badges, tabs, metadata labels |
| Navigation label | derived `labelMedium` | 11–12 | 600 selected / 500 rest | 1.30 | Five-item bottom navigation; do not drop to unreadable 10 px |

Rules:

- Arabic titles may wrap to two lines; do not force clipping to preserve a
  fixed English height.
- Numerals and units may use tabular numerals where supported, but remain Cairo
  unless a tested technical exception is approved.
- Result values use `displayLarge`; units use `titleMedium` and align on the
  baseline rather than competing with the value.
- Support text scaling through at least 1.3× without clipped controls.

---

## 8. Spacing, radius, elevation, and iconography

### 8.1 Spacing

Retain the existing `4, 8, 12, 16, 20, 24, 40` scale.

- compact page gutter: 16;
- medium page gutter: 24;
- expanded page gutter: 32, derived as `2 × 16`, with a max-width container;
- section gap: 20 or 24;
- card padding: 16;
- compact row/list padding: 12;
- field/control internal spacing: 12–16;
- icon-to-label spacing: 8;
- related controls: 8 or 12;
- major composition break: 40 only when hierarchy genuinely requires it.

### 8.2 Radius

Retain the existing radius authority:

- 8: very small badges/inner technical elements;
- 12: buttons, fields, compact controls;
- 14: icon containers;
- 18: canonical cards and list tiles;
- 26: dialogs and sheet top corners;
- 28: signature search field;
- 30: floating bottom navigation container;
- full: chips/pills only.

### 8.3 Elevation and shadow

- Standard light card: elevation 3 using the existing soft two-layer shadow.
- Warm grouped card: elevation 0–1 plus subtle border.
- Floating navigation: one restrained 0/8/24 shadow at approximately 12%
  neutral opacity; no luminous Amber shadow.
- Dialog/sheet: restrained 0/12/32 shadow at approximately 18% neutral opacity.
- Dark mode: elevation is expressed primarily through surface value and border;
  ordinary cards use no cast shadow.
- No neumorphism, heavy glow, or broad glassmorphism system.

### 8.4 Icons

- Use one Material rounded/outlined family consistently per surface.
- Default icon size: 24; compact: 20; section/feature: 28–32.
- Icon containers use radius 14 and either Amber Soft or Blue Soft.
- Semantic icons use semantic colors, never brand Amber as a warning surrogate.

---

## 9. Component visual language

### 9.1 App header / app bar

- Neutral page background, not a full-width Amber bar.
- Height follows Material toolbar 56 plus safe area.
- Centered screen title where current navigation expects it; Home may use a
  start-aligned brand/greeting composition.
- One-pixel divider only where scrolling content needs separation.
- Back/action icons use primary text; a single high-value action may use Blue or
  Amber accent.
- Preserve `CivilAppBar` behavior, route semantics, and 48 × 48 tap targets.

### 9.2 Signature search field

- Height: 56 dp.
- Radius: 28 dp.
- Compact horizontal padding: 16–20 dp.
- Light fill: `surface`; dark fill: `darkSurfaceSecondary`.
- Resting edge: subtle `border`; focus edge: 2 dp `brandBlue` /
  `darkBrandBlue`.
- Search icon sits at logical start, 22–24 dp. Resting icon is secondary text;
  focused icon is Blue.
- Hint uses accessible muted text. Entered text uses primary text.
- Read-only launcher and editable search share geometry but expose correct
  semantics and focus behavior.
- RTL/LTR is derived from locale; never hardcode Arabic hint text in English.

### 9.3 Canonical card family

All variants use the same 18 dp outer radius, neutral surface family, restrained
border/shadow, and 16 dp standard padding.

1. **Content card:** image/thumbnail where relevant, title, concise metadata,
   optional one-line summary, clear tap affordance.
2. **Launcher/tool card:** Blue or Amber Soft icon container, title, maximum
   two-line description, optional directional affordance; no embedded form.
3. **Compact/list card:** 12 dp padding, 48 dp leading target, one/two text
   lines, trailing status/action.
4. **Result card:** neutral or Blue Soft surface, small Blue technical label,
   prominent result value, unit, optional Amber signature rule.
5. **Status/state card:** semantic soft surface and strong semantic icon/text;
   brand colors do not replace status meaning.

Do not assign unrelated category colors to whole cards. Category identity may
appear as a small icon/accent while the card remains neutral.

### 9.4 Buttons

- Minimum height: 48 dp; primary form action may be 52 dp.
- Radius: 12 dp; horizontal padding: 20–24 dp.
- **Primary:** `brandAmber` fill with `textOnAmber`; reserved for the screen's
  high-value action.
- **Primary pressed:** `brandAmberPressed` fill with white or warm-white text,
  or a controlled state overlay verified during implementation.
- **Secondary:** `brandBlue` fill with `textOnBlue`, or Blue Soft tonal style
  for lower emphasis.
- **Outlined:** neutral surface, `borderStrong`, primary text; Blue focus.
- **Text:** Blue for navigation/information; semantic color for semantic action.
- **Destructive:** `error` fill with white, or `errorSoft` with `error` text.
- **Disabled:** disabled surface and foreground; no elevation; not conveyed by
  opacity alone.

### 9.5 Chips

- Height: 36–40 dp; full pill radius; 12–16 dp horizontal padding.
- Default: neutral surface with subtle border and secondary text.
- Active brand choice: Amber Soft with `brandAmberPressed` text/icon.
- Informational choice: Blue Soft with `brandBlueDark` text/icon.
- Disabled: disabled surface/foreground and disabled interaction.
- Semantic chips use semantic pairs, not brand variants.

### 9.6 Inputs

- Height: at least 52 dp; radius 12 dp; warm secondary fill.
- Resting border: subtle border where fill already defines the field.
- Focus: 2 dp Blue edge and persistent label.
- Error: error edge, icon where useful, localized supporting text.
- Disabled: disabled fill/foreground; value remains readable.
- Engineering unit/suffix lives in a fixed trailing region and does not shift as
  values change.
- Numeric entry uses locale-appropriate alignment while formulas and unit
  tokens remain directionally isolated.

### 9.7 Bottom navigation

- Preserve exactly Home, Encyclopedia, Tools, Projects, Directory.
- Compact canvas: 16 dp side margin, 8–12 dp bottom safe margin, approximately
  76 dp content height, radius 30.
- Use an opaque/effectively opaque elevated neutral surface. Blur may remain as
  a subtle platform effect but must not become the identity.
- Selected item: Amber Soft pill, `brandAmberPressed` icon and label; official
  bright Amber may appear as a small decorative indicator only.
- Unselected items: secondary text/icon; labels stay visible.
- Five equal logical slots; tap target at least 48 × 48.
- Item order follows the existing router/shell contract. Directionality changes
  layout naturally without remapping route identity.

---

## 10. Home visual reference specification — Light

### 10.1 Canvas

- Reference canvas: 390 × 844 logical pixels, Arabic RTL, 1× design scale.
- Respect a 24 dp representative top safe area and 34 dp bottom safe area.
- Page background: `#FAF7F2`; content gutter: 16 dp.
- The reference must also be renderable in English LTR without structural
  rearrangement beyond direction-aware start/end behavior.

### 10.2 Composition, top to bottom

1. **Header (72 dp content height):** compact official C mark at logical start
   of the brand cluster, Civilpedia name, greeting/subtitle, and 48 dp profile
   control at logical end. Neutral background; no solid Amber band.
2. **Search (56 dp):** signature pill immediately below header, with 12 dp
   vertical separation.
3. **Featured/hero area:** one restrained 16:7 card, maximum 176 dp high on
   compact. Image uses a controlled dark scrim for text; one small Amber badge
   and white image-overlay text are acceptable only where contrast is measured.
   It must not dominate the first viewport.
4. **Quick access:** section title, then four compact neutral cards or a
   horizontally scrollable row. Icon containers alternate only between Amber
   Soft and Blue Soft; cards themselves stay neutral.
5. **Engineering tools preview:** two or three compact launcher rows/cards with
   technical Blue icons, concise titles, and no embedded calculator controls.
6. **Engineering content/categories:** adaptive neutral card grid with small
   category icon accents and count metadata. Remove whole-card multi-color
   treatment.
7. **Relevant/recent content:** content rows/cards with clear title, metadata,
   and at most two useful summary lines. Do not truncate decorative copy merely
   to fill space.
8. **Bottom navigation:** approved five-item floating neutral container with
   Home selected in Amber Soft/dark Amber.

### 10.3 Hierarchy rules

- Section title: 18/600; action: 12–14/600 Blue.
- Vertical section gap: 20–24 dp.
- Card-to-card gap: 12 dp compact.
- Amber appears in selected navigation, the principal badge/action, and a small
  number of accents—not in every icon.
- Blue carries technical icons, links, focus, and supporting actions.

### 10.4 Render result

The first viewport should communicate brand, search, one featured item, and the
beginning of quick access without visual crowding. It should read as a calm
professional engineering product, not a promotional orange dashboard.

---

## 11. Tools Launcher visual reference specification — Light

### 11.1 Canvas and structure

- Reference canvas: 390 × 844 logical pixels, Arabic RTL.
- Neutral app bar with screen title “الأدوات” and no back button in the shell.
- Introductory warm-neutral card with a Blue technical icon, one-line title,
  and at most two concise description lines.
- The current catalog is small enough that search is omitted from the reference.
  Add launcher search only if the visible registry grows beyond approximately
  eight tools or discoverability evidence justifies it.

### 11.2 Tool grid

- Compact: 2 columns; 12 dp gap; cards at least 148 dp high.
- Each launcher card contains a 44–48 dp icon container, a 16/600 title, an
  optional two-line 12–14 dp description, and a subtle directional affordance.
- Concrete/quantity calculators use Blue technical icons; checklist/project
  utilities may use restrained Amber accent. Card surfaces remain neutral.
- Press state uses a subtle surface shift and ink response; no scale bounce.
- A tap always opens the existing dedicated route. No calculator fields,
  results, or inline expansion appear in the launcher grid.

---

## 12. Dedicated Concrete Volume calculator reference — Light

### 12.1 Canvas and hierarchy

- Reference canvas: 390 × 844 logical pixels, Arabic RTL.
- Neutral `CivilAppBar` with back action and “حجم الخرسانة”.
- Content width uses 16 dp gutters and a single readable column.
- Order is fixed: title/context, short description, inputs, primary action,
  result, then notes/warnings.

### 12.2 Reference content

1. **Intro:** one sentence explaining that the tool calculates concrete volume;
   no formula changes or claims beyond existing semantics.
2. **Unit/element controls:** compact chips above the field group where the
   existing calculator requires them.
3. **Input card:** neutral surface, 18 dp radius, 16 dp padding. Three stacked
   fields: Length, Width, Thickness. Unit suffix is isolated and visually
   stable (`m`, `cm`, or the existing selected unit). Field gap: 12 dp.
4. **Primary action:** full-width 52 dp Amber button with dark text, localized
   calculation label, and no white-on-Amber text.
5. **Result card:** Blue Soft or neutral surface with a 3 dp Blue start rule;
   label 14/600, value `2.50` at 32/700, unit `m³` at 16/600 on the baseline.
   A small Amber signature accent may mark the result, but Blue communicates
   technical authority.
6. **Notes/warnings:** quiet body text or semantic state card. Validation errors
   use the Error palette and never raw exceptions.

The reference specifies presentation only. Formulas, rounding, units, presets,
and engineering meaning remain under V1-R12 authority.

---

## 13. Representative Dark Mode reference — Calculator

Use the same Concrete Volume hierarchy on a 390 × 844 canvas.

- Page: `darkBackground #121820`.
- Input/result cards: `darkSurface #19212B`; grouped input fill:
  `darkSurfaceSecondary #202A35`.
- Elevated result/dialog surfaces: `darkSurfaceElevated #273340`.
- Ordinary cards use `darkBorder #3A4653`, no cast shadow.
- Focused inputs use 2 dp `darkBrandBlue #63A4FF`.
- Primary action uses `darkBrandAmber #FFB02E` with
  `darkTextOnAmber #241A0E`.
- Result value uses `darkTextPrimary`; label/start rule uses dark Blue.
- Secondary and metadata text use their accessible warm-neutral roles.
- Error/warning cards use dark semantic pairs, not Amber branding.

The result must feel recognizably Civilpedia through the restrained Amber CTA,
Blue technical focus/result cues, warm text, and calm navy-charcoal surfaces.
It must not become pure black, neon, or glow-heavy.

---

## 14. Responsive behavior

Responsive decisions use available content width, not device labels.

| Class | Width | Gutter / max width | Grid guidance |
|---|---:|---|---|
| Compact | `< 600` | 16 dp gutter; single readable feed | Tools/categories 2 columns; content and calculator 1 column |
| Medium | `600–839` | 24 dp gutter; content max approximately 760 dp | Tools/categories 3 columns; Home compact cards 3–4; calculator centered at max 600 dp |
| Expanded | `>= 840` | 32 dp gutter; overall max approximately 1200 dp | Tools/categories 4 columns; content cards 2-column where useful; calculator stays max 640 dp |

- Hero width grows within the content container but height remains restrained.
- Content rows may become two columns only when reading order remains obvious.
- Cards preserve minimum tap targets and useful text; do not stretch to fill an
  unlimited desktop canvas.
- A side rail/drawer is not part of this specification and still requires
  separate Architect approval.
- This is one adaptive product, not a separate desktop design.

---

## 15. RTL / LTR direction rules

- Arabic RTL is the default. English LTR uses the same hierarchy and component
  geometry.
- All padding, alignment, row order, and directional affordances use logical
  start/end.
- Back arrows and directional chevrons follow platform/Directionality behavior;
  brand marks never mirror.
- Search icon and field affordances occupy logical start/end consistently.
- Numeric engineering fields may render their editable numeric run LTR while
  the field label and surrounding layout follow the active locale.
- Units (`m`, `m²`, `m³`, `kg`, `mm`) and formulas are directionally isolated
  so exponent/order cannot reverse in Arabic context.
- Emails, URLs, IDs, and code-like values render LTR with safe wrapping.
- Mixed Arabic/Latin descriptions use Unicode-aware text layout and are tested
  at 1.0× and 1.3× scaling.

---

## 16. Loading, empty, offline, and error language

- **Skeleton/shimmer:** use the final surface geometry, neutral warm greys in
  light and dark surface steps in dark. No bright white flash, colored shimmer,
  or indefinite decorative motion.
- **Progress indicator:** compact Material indicator using Blue for ordinary
  technical loading; Amber only when tied to a primary user action.
- **Empty:** neutral state card, one restrained 40–48 dp icon, concise localized
  title/body, and one relevant action if available. No oversized illustration.
- **Offline:** warning semantic pair, offline icon, concise cause, preserve
  known-good data, and show retry only when allowed by domain behavior.
- **Retryable error:** error or information semantic pair according to cause,
  localized safe copy, and a clear retry action.
- **Destructive/error:** Error palette with icon plus text; never color alone.
- Never expose raw backend messages, SQLSTATE, stack traces, or internal IDs.

---

## 17. Visual reference rendering checklist

All four references use Cairo, real localized-length copy, official logo assets,
and the exact candidate colors above. They must not substitute a redesigned
logo, arbitrary font, or decorative gradient UI.

### 17.1 Home — Light

- [ ] 390 × 844 compact Arabic RTL reference
- [ ] neutral header, greeting/profile, 56 dp search
- [ ] restrained hero, quick access, tools preview, categories/content
- [ ] five-item bottom navigation with Home selected
- [ ] Amber scarcity and Blue technical support visible
- [ ] no multi-color-card palette

### 17.2 Tools Launcher — Light

- [ ] 390 × 844 compact Arabic RTL reference
- [ ] intro card plus two-column adaptive launcher grid
- [ ] no inline calculator
- [ ] coherent launcher-card family and dedicated-route affordance

### 17.3 Dedicated Calculator — Light

- [ ] 390 × 844 compact Arabic RTL reference
- [ ] Length / Width / Thickness with clean units
- [ ] accessible Amber CTA
- [ ] `2.50 m³` result hierarchy
- [ ] semantic notes/errors, no formula change

### 17.4 Representative Dark Mode

- [ ] same calculator hierarchy in dark mode
- [ ] navy-charcoal surfaces, warm readable type
- [ ] Amber signature, Blue technical support
- [ ] borders instead of excessive shadows
- [ ] no neon/glow or pure-black treatment

### 17.5 Rendering handoff assumptions

- Produce full-screen UI references, not marketing-device mockups.
- Use a 1× logical-pixel grid; export may scale uniformly to 2× or 3×.
- Keep status/safe areas visible enough to judge layout but do not imitate a
  specific OEM skin.
- Use representative realistic Civilpedia content; do not invent new product
  capabilities.
- Architect/user approval of the rendered set is required before this document
  can be frozen and R10.1 can close.

---

## 18. Unresolved Architect / user visual decisions

No structural contract contradiction remains. The following visual choices
require explicit approval through the mandatory references:

1. Approve `#FE9E03` as the flat signature Amber while preserving the source
   gradient only inside official artwork.
2. Approve measured `#0155DA` as the flat Logo Blue representative and
   wordmark-derived `#063284` as its deep support role.
3. Approve dark mode's navy-charcoal base (`#121820`) in place of the current
   warmer near-black base.
4. Approve dark foreground on Amber for all meaningful button/chip/navigation
   content; white-on-Amber is explicitly rejected by contrast evidence.
5. Approve the four visual references described in Sections 10–13 after they
   are rendered.

Until those approvals occur, this document remains a draft candidate and R10.2
is not authorized.

---

## 19. R10.1 acceptance state

- Discovery: complete.
- Candidate tokens: specified.
- Contrast analysis: complete.
- Component language: specified.
- Home / Tools / Calculator / Dark references: render-ready specifications.
- Production Flutter changes: none.
- R10.1 closure: pending Architect/user visual approval.
- R10.2 authorization: not granted.

