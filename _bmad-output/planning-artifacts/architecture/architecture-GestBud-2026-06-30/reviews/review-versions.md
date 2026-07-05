---
type: version-review
target: ARCHITECTURE-SPINE.md — Stack section + ADs
date: 2026-06-30
reviewer: automated web-search verification
verdict: PARTIALLY-OUTDATED — 3 items require action before first flutter pub get
---

# Version Verification Review — GestBud Stack

## Summary verdict

| # | Technology | Spine version | Actual current | Status |
|---|---|---|---|---|
| 1 | flutter_riverpod | ^3.3.2 | ~3.3.2 (stable appears to be 3.2.x; 3.3.2 may still be pre-release) | NEEDS CONFIRMATION |
| 2 | drift + drift_flutter | ^2.x | 2.x series confirmed still active (last update Feb/Mar 2026) | OK — confirm exact patch |
| 3 | go_router | ^14.x | 14.8.0 confirmed in 2026 articles | OK |
| 4 | flutter_secure_storage | ^9.x | 10.3.1 stable; 11.0.0-beta.1 pre-release | OUTDATED — ^9.x is behind; use ^10.x |
| 5 | Cloudflare Workers / Wrangler 3.x | Wrangler 3.x | Wrangler 4.x (4.102.0 as of June 2026) | OUTDATED — major version jump |
| 6 | Mindee API | v1 | API v2 (api-v2.mindee.net) is current | OUTDATED — v1 superseded by v2 |
| 7 | Mistral API — mistral-small-latest | mistral-small-latest | Still valid alias; resolves to Mistral Small 4 (released 2026-03-16) | OK — alias is stable |
| 8 | Africa's Talking SMS API | v1 | No public version bump found; v1 endpoint still documented | OK — no evidence of deprecation |

---

## Detailed findings

### 1. flutter_riverpod ^3.3.2

**Spine entry:** `flutter_riverpod ^3.3.2`

**Finding:** Riverpod 3.0 was released as a major version and the `^3.x` series is the current generation. Search results from the official Riverpod docs reference `^3.3.2` in dependency examples, suggesting the maintainer already considers this the recommended pin. However, pub.dev version listings indicate the latest *stable* may be 3.2.1 with 3.3.2 as a dev/release-candidate at time of search.

**Action required:** Run `flutter pub outdated` or check `https://pub.dev/packages/flutter_riverpod/versions` before the first `flutter pub add`. If 3.3.2 is not yet stable, pin `^3.2.1` and update the spine once 3.3.2 is promoted.

**Risk level:** Low — breaking API changes between 3.2.x and 3.3.x are unlikely; the constraint `^3.3.2` will simply fail to resolve if the version is not yet published as stable.

---

### 2. drift + drift_flutter ^2.x

**Spine entry:** `drift + drift_flutter ^2.x ¹` (footnote already flags "confirm on pub.dev")

**Finding:** Both packages are in active development. The drift_flutter page was last updated February 28, 2026; drift_dev was last updated March 22, 2026. The 2.x series remains current — no 3.x release detected.

**Action required:** Before `flutter pub get`, verify the exact latest patch (e.g., `2.x.y`) on `https://pub.dev/packages/drift` and `https://pub.dev/packages/drift_flutter` and pin to the exact patch version in `pubspec.yaml`.

**Risk level:** Low — footnote in spine already acknowledges this gap.

---

### 3. go_router ^14.x

**Spine entry:** `go_router ^14.x ¹`

**Finding:** go_router 14.8.0 is confirmed in 2026 guides and tutorials. The Flutter team has declared the package feature-complete and is now in maintenance/bug-fix mode; the 14.x series is current.

**Action required:** Confirm exact latest patch on `https://pub.dev/packages/go_router/versions`. No major concern.

**Risk level:** None.

---

### 4. flutter_secure_storage ^9.x — OUTDATED

**Spine entry:** `flutter_secure_storage ^9.x ¹`

**Finding:** The latest stable is **10.3.1** with a pre-release of 11.0.0-beta.1. Version 9.x is at minimum one major version behind. The `^9.x` constraint will resolve to the highest 9.x release (likely 9.2.x) and will NOT pull in 10.x improvements or security patches.

**Action required (mandatory before first pub get):**
- Update the spine Stack entry to `flutter_secure_storage ^10.3.1`
- Verify the 10.x changelog for any breaking API changes vs 9.x (constructor or read/write method changes are typical between major versions)
- Update AD-7 wording accordingly

**Risk level:** Medium — security packages should track stable majors. Running 9.x in a production app handling session tokens is inadvisable.

---

### 5. Cloudflare Workers / Wrangler 3.x — OUTDATED

**Spine entry:** `Cloudflare Workers runtime v8 (Wrangler 3.x)`

**Finding:** Wrangler has advanced to the **4.x** major series. As of June 19, 2026, Wrangler **4.102.0** was referenced in Cloudflare's own release notes for a new `--temporary` deployment feature targeting AI agents. The 3.x series is no longer current.

**Action required (mandatory):**
- Update the spine Stack entry to `Wrangler 4.x`
- Check `wrangler.toml` schema for any breaking changes between Wrangler 3 and 4 (Wrangler 4 introduced changes to the `wrangler.toml` format in some areas)
- Review Cloudflare's Wrangler 4 migration guide before scaffolding `bff/wrangler.toml`
- The Workers runtime remains v8; this part of the entry is accurate

**Risk level:** Medium — scaffolding the BFF with Wrangler 3 `wrangler.toml` conventions and then finding Wrangler 4 installed via npm will cause config parse errors. Fix the spine before the BFF scaffold.

---

### 6. Mindee API v1 — OUTDATED

**Spine entry:** `Mindee API v1`

**Finding:** Mindee's current REST API base is `api-v2.mindee.net`. The v2 API provides asynchronous inference across five model families (Extraction, Classification, Crop, OCR, Split) plus a unified Jobs endpoint for polling. The GitHub API-Evangelist mirror for Mindee explicitly documents the v2 base URL. All current SDK client libraries (Python, Node.js, Java, .NET, PHP, Ruby) target v2.

**Action required (mandatory):**
- Update the spine Stack entry to `Mindee API v2`
- Update AD-4 and `bff/handlers/ocr.ts` design to use `api-v2.mindee.net` endpoints
- The v2 API uses asynchronous polling (POST to submit, GET /jobs/{id} to poll), which differs from v1's synchronous response. The BFF `ocr.ts` handler design must accommodate this polling loop.
- Review Mindee's v2 receipt endpoint: `https://developers.mindee.com/docs/receipt-ocr`

**Risk level:** High — calling a deprecated/incorrect API version will result in 404 or broken responses in production. This must be corrected before BFF implementation.

---

### 7. Mistral API — mistral-small-latest

**Spine entry:** `Mistral API v1 (modèle : mistral-small-latest)`

**Finding:** The alias `mistral-small-latest` is still a valid, officially documented model identifier. As of March 16, 2026, it resolves to **Mistral Small 4**, a multimodal, multifunction model that supersedes Small 3.1. The alias approach (using `latest` rather than a pinned version slug like `mistral-small-2603`) is intentional on Mistral's part — it is the recommended way to always use the newest production-ready small model.

The Mistral REST API itself remains v1 at `api.mistral.ai/v1`.

**Action required:** None — the spine entry is correct. Optionally note in the BFF implementation that `mistral-small-latest` now points to a multimodal model; this does not affect text-only categorization use.

**Risk level:** None.

---

### 8. Africa's Talking SMS API v1

**Spine entry:** `Africa's Talking SMS API v1`

**Finding:** The Africa's Talking SMS API continues to be documented under the v1 path. No public announcement of a v2 or deprecation of v1 was found. The official developer portal (`developers.africastalking.com/docs/sms`) still documents the current endpoints without a version migration notice.

**Action required:** None currently. Monitor Africa's Talking developer portal for any v2 announcement.

**Risk level:** None currently.

---

## Flutter / Dart SDK versions (not explicitly tasked but noted)

The spine lists `Flutter SDK ^3.22` and `Dart ^3.4`. Flutter 3.22 was released in May 2024; by mid-2026 the stable channel is likely on Flutter 3.27+ or higher. While `^3.22` is a valid lower bound (pub constraints are semver-compatible), the team should confirm the target Flutter SDK on the development machines and consider tightening the constraint to match the actual installed version to avoid CI/CD surprises.

---

## Required spine changes before implementation

1. `flutter_secure_storage ^9.x` → `^10.3.1` (or latest stable 10.x)
2. `Wrangler 3.x` → `Wrangler 4.x`
3. `Mindee API v1` → `Mindee API v2`
4. `flutter_riverpod ^3.3.2` — confirm 3.3.2 is stable on pub.dev; fall back to `^3.2.1` if not
5. Confirm exact drift / drift_flutter patch versions before first `flutter pub get`

---

## Sources consulted

- [flutter_riverpod on pub.dev](https://pub.dev/packages/flutter_riverpod)
- [flutter_riverpod versions](https://pub.dev/packages/flutter_riverpod/versions)
- [Riverpod — What's new in 3.0](https://riverpod.dev/docs/whats_new)
- [drift on pub.dev](https://pub.dev/packages/drift)
- [drift_flutter on pub.dev](https://pub.dev/packages/drift_flutter)
- [go_router on pub.dev](https://pub.dev/packages/go_router)
- [flutter_secure_storage on pub.dev](https://pub.dev/packages/flutter_secure_storage)
- [flutter_secure_storage versions](https://pub.dev/packages/flutter_secure_storage/versions)
- [Cloudflare Workers Wrangler docs](https://developers.cloudflare.com/workers/wrangler/)
- [Cloudflare workers-sdk releases (GitHub)](https://github.com/cloudflare/workers-sdk/releases)
- [Mistral Models Overview](https://docs.mistral.ai/models/overview)
- [Mistral Chat Completion API](https://docs.mistral.ai/api)
- [Mindee API Evangelist (v2 base)](https://github.com/api-evangelist/mindee)
- [Mindee Receipt OCR docs](https://developers.mindee.com/docs/receipt-ocr)
- [Africa's Talking SMS docs](https://developers.africastalking.com/docs/sms/overview)
