# Civilpedia — CUI-1 Authoritative Media Addendum V1

DOCUMENT_STATUS: ACCEPTED — CANONICAL CUI-1 MEDIA AUTHORITY ADDENDUM

ARCHITECT_ACCEPTANCE: ACCEPTED — 2026-10-06

FREEZE_STATE: FROZEN — CUI-1 AUTHORITATIVE MEDIA DELTA ONLY

IMPLEMENTATION_AUTHORIZED: YES — BOUNDED CUI-1 CORRECTION ONLY

DOCUMENT_VERSION: 1

MODE: ARCHITECTURE / GOVERNANCE ONLY — NO PRODUCTION OR TEST IMPLEMENTATION IN THIS PASS

PUBLIC_BACKEND_AUTHORITY_DELTA: ZERO

COMMERCIAL_AUTHORITY_DELTA: ZERO

CUI1_STATE: NOT CLOSED

IMPLEMENTATION_CORRECTION: REQUIRED

## 1. Authority, history and precedence

Authority: Owner-provided Architect media-authority reconciliation instruction dated 2026-10-06. The acceptance metadata above records that supplied instruction; it is not agent self-acceptance of the implementation, an independent-review PASS or slice closure.

Governing sources:

- [Frozen CUI-1 implementation contract](CIVILPEDIA_COMMERCIAL_CUI1_BUSINESS_EXPERIENCE_FOUNDATION_IMPLEMENTATION_CONTRACT_V1.md), accepted 2026-10-05 at contract commit `889ff1da4389ba891247cfb5497554ca98fa58b3`.
- [Master Roadmap](../CIVILPEDIA_V1_MASTER_ROADMAP.md), including the committed CUI-1 implementation authorization and its appended media reconciliation control.
- Owner Visual QA: **PASS / ACCEPTED** for the final media-rich Business Detail direction, including supplied cover, logo and gallery, with honest no-media fallback.
- Independent-review conflict, as recorded in the Owner's reconciliation instruction: the approved media presentation conflicts with the frozen contract's blanket media-loading prohibition.

The original frozen contract remains historically intact. This addendum controls only the limited authoritative-media presentation exception below. Every other contract requirement, authority separation, exclusion, allowlist, STOP condition and review obligation remains active. Owner Visual QA acceptance does not waive independent findings or establish overall contract compliance.

## 2. Exact superseded clause scope

The following historical clauses remain readable in the original contract. Their blanket prohibition or deferral of the presentation authorized in §3 is superseded only to that extent:

| Historical location | Conflicting wording / meaning | Narrow controlling exception |
| --- | --- | --- |
| §4, logo/cover/gallery dependency row | “No media loading in CUI-1.” The row requires a neutral type icon instead of supplied media | Existing typed, validated authoritative media may render as cover, logo/avatar and gallery thumbnails; the neutral fallback still applies when such media is unavailable |
| §11, Media/logo/cover/gallery authority row | Public URL/mediaType is “not used in CUI-1”; “Generic type icon; no media fetch or synthetic logo” | Fetch/render only a validated supplied HTTPS URL for an existing typed role. The prohibition on synthetic production branding and on treating the first row as approved/ordered remains active |
| §5 concluding scope paragraph | A “media gallery” requires another contract/provider | This addendum supplies the narrow authority for gallery thumbnails from the existing entity/media model. A gallery-management system, new viewer/navigation workflow or new provider remains outside this exception |
| §16 media risk row and media-deferral summary | Rendering is deferred pending a broader URL/storage/order/approval contract | The supplied typed/HTTPS presentation exception is now allowed. Broader delivery, storage, ordering-field and approval-system architecture is not authorized or certified |
| §12 generic-placeholder boundary | Neutral type icons are permitted placeholders, with no fabricated business facts | Keep that boundary. A real supplied cover/logo is actual media, not a placeholder; absent/invalid media still uses only honest generic fallbacks |

Only the **“No media loading” restriction and its directly corresponding media-deferral statements** are superseded. The §12 bans on runtime mocks, production seeds, fake positive states and QA leakage are not superseded. This exception does not amend categories/services copy, responsive geometry, contacts, management, commercial copy or any other independent-review point.

## 3. Authorized presentation and existing data authority

CUI-1 may render media only when supplied through the existing authoritative Directory entity/media model and accepted repository/controller composition. The existing `CanonicalDirectoryEntity.media` collection and `CanonicalDirectoryMedia.url` / `mediaType` fields are the entire data boundary. The existing public projection supplies `url` and `media_type`; no new model field, SELECT, RPC or authority provider is authorized.

| Existing explicit media type | Authorized public Business Detail presentation |
| --- | --- |
| `cover` | Hero / cover image |
| `logo` | Business logo / avatar |
| `gallery` | Gallery thumbnails |

Do not derive a role from a filename, entity type, an untyped URL or the first arbitrary media row. Unknown/missing roles are not authority for cover, logo or gallery. Where the existing supplied fields cannot identify an unambiguous cover/logo, use the generic fallback rather than invent priority or approval. Gallery presentation may retain the existing supplied sequence; it must not invent a missing position, caption, approval or commercial priority field. Media ordering and availability must not affect organic search ranking, filtering or eligibility.

Existing cache/seed freshness semantics remain active: route extra is a provisional hint, not a replacement authority; existing stale/failure notices remain truthful; authoritative absence removes the entity and its media. No media presence or image-fetch success establishes fresh verification, ownership, entitlement or publication eligibility.

## 4. Strict media safety and fallback

- Render authoritative supplied media only, through the existing typed model.
- Validate an absolute **HTTPS** URL with a nonempty host before loading. Reject invalid or unsupported URLs and roles; preserve existing rejection of credentials/fragments rather than weakening validation. Do not invent, reconstruct or substitute a production URL.
- No generated/fake production hero, logo or gallery; no QA fixture, reference-image crop, demo endpoint, runtime flag or synthetic fallback data in production composition.
- A generic placeholder must never pretend to be a real company logo or photograph. A supplied image is not evidence of trademark ownership, approval, endorsement or commercial verification.
- When authoritative media is absent, invalid, ambiguous for its role or cannot be loaded: the hero uses the neutral Civilpedia/entity-type fallback; logo/avatar uses the neutral entity-type icon; unavailable gallery media is omitted, and the gallery is omitted when no usable thumbnail remains. Never replace a failed image with a fake brand asset.
- Preserve readable RTL/LTR presentation, responsive layout, light/dark behavior and text scaling under the original visual/test obligations. Image availability must not displace required identity, contacts, Saved or management affordances.

This is presentation of existing public media URLs, not permission for new Storage wiring, uploads, signing services, bucket/ACL changes, media moderation, optimization infrastructure, repository retries or backend delivery architecture. If rendering requires such work or a missing field, STOP and report the gap under the frozen rules.

## 5. Authority separations remain normative

- Directory Verification ≠ Commercial Verification V1.
- Sponsored ≠ Verified.
- Directory Location ≠ Commercial Branch.
- Saved ≠ Ownership.
- Claim ≠ Management authority; public entity ID ≠ Management authority.
- Commercial information shell ≠ Catalog authority.
- Paid ≠ Verified ≠ Sponsored.
- Media ≠ Verification ≠ Ownership ≠ Sponsored ≠ Paid entitlement: each authority remains independent; no media availability, role or placement infers any of these states.

Commercial Verification V1, payment/subscription authority, entitlement decisions, Sponsored eligibility/purchase, commercial lifecycle/publication, branch/team rights, OQ-84 and M4/M5 remain outside CUI-1. Neither the media exception nor Owner Visual QA closes those dependencies.

## 6. Production and test boundaries

The frozen eight-file production allowlist is unchanged:

```text
lib/features/directory/presentation/directory_landing_screen.dart
lib/features/directory/presentation/directory_search_screen.dart
lib/features/directory/presentation/directory_provider_card.dart
lib/features/directory/presentation/directory_provider_detail_screen.dart
lib/features/directory/presentation/directory_verification_badge.dart
lib/features/directory/presentation/widgets/directory_sponsored_provider_card.dart
lib/localization/ar.dart
lib/localization/en.dart
```

No ninth production file; no backend, SQL, migration, provider, repository, domain, route, DI or global-theme work is authorized. Preserve one production Supabase authority and one AuthProvider. No dependency/SDK patch, commercial static-guard edit, search/ranking change or unrelated redesign is authorized.

The existing six-file CUI-1 implementation-test boundary and read-only baseline-correction regressions in original §13 remain unchanged. Within that boundary, tests may legitimately prove supplied typed media rendering, HTTPS/role validation, absent/invalid/load-failed media fallback, absence of fake production media, and RTL/LTR/responsive media presentation. Tests must no longer treat the superseded blanket “no media loading” rule as active for media that meets this addendum. Tests must retain all non-media authority and safety assertions; no weakening or fixture leakage is permitted. Clearly labeled test-only media fixtures may remain in authorized visual regression tests and external evidence.

This governance pass edits no production or test implementation. The bounded correction authorization recorded above does not make correction complete, permit a static-guard compatibility patch, or authorize staging/commit/push. Any mechanically necessary documentary/static compatibility requires separate exact authorization; the existing guards remain unchanged here.

## 7. Roadmap state and completion requirements

The appended Master Roadmap reconciliation record makes this addendum the controlling narrow authority for the media point and preserves the historical authorization records. CUI-1 remains **NOT CLOSED**; implementation correction and independent re-review remain **REQUIRED**. The accepted visual direction is preserved, but this document does not retrospectively certify every implementation clause, mark cleanup complete, or resolve other independent-review findings.

M3 remains CLOSED; M4 and M5 remain NOT AUTHORIZED; R10.5-D remains audit-only / IMPLEMENTATION NO. No unrelated roadmap advancement, commercial launch, new media-system phase or publication cutover follows. The roadmap's future Engineering Directory Media System remains a separate unapproved broader architecture candidate; this exception only consumes fields already supplied today.

Subsequent bounded correction must verify the implementation and tests against the original frozen contract **plus this media exception**, retain the accepted design direction and existing safety boundaries, provide focused/render evidence, and return for independent review and Architect implementation acceptance. User retains Git ownership. This uncommitted governance result is prepared for Architect review; no execution or implementation acceptance is performed in this pass.
