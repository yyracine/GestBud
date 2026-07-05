---
title: "Review — Architecture Spine GestBud"
date: 2026-06-30
reviewed-file: ARCHITECTURE-SPINE.md
reviewer: Claude Code (Sonnet 4.6)
verdict: CONDITIONAL PASS — solid core, four findings to address before epic work starts
---

# Architecture Spine Review — GestBud

## Overall Verdict

**CONDITIONAL PASS.** The spine is well-structured, well-reasoned, and covers the domain deeply. The paradigm choice (Riverpod + Clean Architecture slices + BFF stateless) is sound for the problem. However four findings must be resolved before stories are written: one silent dimension (operational/deployment envelope), one deferred item that can produce divergence between teams, one capability gap in the Capability Map, and one unverified tech version. None are structural re-works — all can be addressed with additions to the current document.

---

## Checklist Results

### 1. Fixes the real divergence points for the level below and misses none

**Result: PASS with minor gap**

The nine ADs collectively cover the critical forks a developer would face:

- State management (AD-1) — prevents the setState/InheritedWidget sprawl endemic to Flutter codebases.
- Feature coupling (AD-2) — the explicit `shared/` boundary rule is clear and enforceable.
- Data access (AD-3) — Drift-only ORM rule eliminates raw SQL and migration drift.
- API key security (AD-4) — BFF isolation rule is concrete and binary (either the app calls BFF or it doesn't).
- AI categorisation (AD-5) — batch-vs-line-by-line divergence prevented; fallback path specified.
- Navigation (AD-6) — GoRouter + single file rule closes the imperative push fragmentation.
- Token storage (AD-7) — corrects the PRD's "localStorage" language and names the exact API.
- Monetary precision (AD-8) — cents-as-integer rule is unambiguous.
- Currency parameterisation (AD-9) — prevents the V2 migration problem.

**Minor gap:** No AD governs image/photo lifecycle (FR-9 specifies "not stored permanently locally"). The Conventions table covers mutations but not ephemeral media. This is not a blocking divergence risk since camera_plugin behaviour is standard, but the PRD's open question 4 (Mindee data retention) is flagged as "BLOQUANT BETA" and the spine neither resolves it nor defers it explicitly — it is silently absent. A note in Deferred or an AD covering "photo not persisted beyond BFF response" would close this.

---

### 2. Every AD's Rule is enforceable and actually prevents its stated divergence

**Result: PASS**

Each AD has a stated divergence and a concrete, checkable rule:

- AD-1: "tout état visible par plus d'un widget passe par un provider Riverpod" — enforceable via code review / lint rule (flutter_riverpod has a lint package).
- AD-2: "une feature n'importe jamais depuis une autre feature" — enforceable via import analyser or CI check.
- AD-3: "tout accès à la base locale passe par des DAOs Drift générés" — enforceable; DAOs are generated types, any direct sqflite import would be visible.
- AD-4: "l'app Flutter n'appelle que le BFF" — enforceable; any `http` or `dio` call not targeting `bff.gestbud.workers.dev` is a violation.
- AD-5: Rule is on the BFF side, not Flutter. The Flutter app is correctly insulated ("ne distingue pas les deux chemins"). Enforceable on the BFF via handler unit tests.
- AD-6: "toutes les routes nommées sont déclarées dans `shared/routing/app_router.dart`" — enforceable.
- AD-7: "lu et écrit exclusivement via flutter_secure_storage" — enforceable; grep for SharedPreferences in auth context.
- AD-8: "jamais de `double` pour un montant financier" — enforceable; a custom lint rule or PR checklist.
- AD-9: "aucun provider ne référence 'XOF' en dur" — enforceable via grep in CI.

No AD has a rule that is purely aspirational or untestable. All rules pass.

---

### 3. Nothing under Deferred could let two independent units diverge

**Result: FINDING — one item**

Most deferred items are safe: they name what is NOT being built and correctly defer UI/locale work for XAF to V2 while keeping the schema ready.

**Finding D-1 (Medium): "Stratégie de tests — à définir au niveau epic"**

This deferral is risky. Test strategy determines:
- Whether repositories are tested against real Drift databases or mocks.
- Whether BFF handlers are tested with Miniflare or live APIs.
- What the contract between Flutter and BFF is (shared types? OpenAPI schema?).

If left undefined until epics, two developers writing different features will independently choose different testing approaches. Repository mocks vs. real Drift is a divergence that produces incompatible test fixtures. The spine should either:
(a) Add a minimal test AD ("repositories tested with in-memory Drift; BFF handlers tested with Miniflare; no mocking of domain logic"), or
(b) Move this to an explicit open question with a decision owner, not just "à définir au niveau epic."

The current deferral language creates a gap where independent teams diverge before anyone notices.

---

### 4. Named tech is verified or flagged

**Result: PASS with two noted items**

The spine appropriately flags three packages with "¹ Version à confirmer sur pub.dev avant le premier flutter pub get":
- `drift + drift_flutter ^2.x`
- `go_router ^14.x`
- `flutter_secure_storage ^9.x`

These are correctly flagged as unverified.

**flutter_riverpod ^3.3.2** is listed without a flag. As of mid-2026, the Riverpod 3.x line is in active development and `^3.3.2` may not yet be stable on pub.dev. This should receive the same "¹ à confirmer" flag. This is minor but consistent with the spine's own standard.

**Cloudflare Workers runtime v8 / Wrangler 3.x** — no flag. Wrangler is on 3.x (confirmed), Workers runtime v8 is accurate. No issue.

**Mistral `mistral-small-latest`** — the model alias resolves to the current latest small model. This is a floating pointer; if Mistral retires the alias or promotes a new model, the BFF will silently switch behaviour. Worth noting in Deferred or as an open question ("pin to a specific model version before beta to prevent silent quality changes").

---

### 5. Covers all spec capabilities (FR-1 to FR-24)

**Result: FINDING — one capability partially missing**

The Capability Map header claims `binds: [FR-1 ... FR-24]` and the table covers:

| Range | Status |
|---|---|
| FR-1 to FR-4 (Auth) | Covered — AD-4, AD-6, AD-7 |
| FR-5 to FR-8 (Manual entry) | Covered — AD-1, AD-2, AD-3, AD-8 |
| FR-9 to FR-12 (Scan) | Covered — AD-4, AD-5 |
| FR-13 to FR-16 (Categories) | Covered — AD-2, AD-3 |
| FR-17 to FR-21 (Dashboard) | Covered — AD-1, AD-9 |
| FR-22 to FR-23 (Local storage) | Covered — AD-3 |
| FR-24 (Navigation) | Covered — AD-6 |

**Finding C-1 (Low): FR-12 grouping behaviour not ruled**

FR-12 specifies: "Les Transactions issues d'un même Reçu sont regroupées visuellement dans l'historique (tag ou section 'Reçu du JJ/MM')." [A-3]

The ERD correctly provides `receipt_id TEXT nullable` on TRANSACTION to support this. However, the Capability Map maps FR-9 to FR-12 entirely to AD-4 and AD-5 (BFF concerns). The `receipt_id` grouping logic is a Flutter/UI concern governed by AD-3 (Drift) and AD-1 (Riverpod derived state), but neither AD mentions `receipt_id` as a pattern. AD-3 mentions the field schema but not how it is queried. A developer implementing the history screen has no architectural guidance on whether grouping is a Drift query (GROUP BY receipt_id), a provider-level transformation, or a widget-level rendering decision.

This is not a blocking gap (the field exists), but the Capability Map row for FR-9 to FR-12 should reference AD-3 or add a convention note about `receipt_id` grouping being a provider-level derived state (consistent with AD-1).

---

### 6. Every dimension the altitude owns is decided, deferred, or an open question — especially the operational/environmental envelope

**Result: FINDING — one silent dimension (highest severity)**

The spine decides or defers most dimensions well. The following are confirmed handled:

- Flutter SDK version: decided (^3.22).
- State management paradigm: decided (Riverpod).
- Local persistence: decided (Drift/SQLite).
- Auth approach: decided (OTP via BFF/AT).
- BFF platform: decided (Cloudflare Workers).
- AI provider: decided (Mistral small via BFF).
- OCR provider: decided (Mindee, fallback Google Vision).
- Currency strategy: decided (AD-9).
- Error model: decided (sealed Failure class).

**Finding O-1 (High — Silent Dimension): Operational/Deployment Envelope**

The spine does not address the following operational questions at all — they are neither decided, deferred, nor listed as open questions:

1. **BFF deployment environments** — Is there a staging BFF? A local dev BFF? Or does every developer hit the single `bff.gestbud.workers.dev` production URL? For a 1-developer project this may be acceptable, but it must be stated, not silent. The Flutter app's `shared/network/bff_client.dart` needs to know the base URL strategy (env flag, dart-define, flavors).

2. **Flutter build flavors / environments** — The spine defines `shared/network/bff_client.dart` with a `base URL BFF`, but does not specify how the base URL is parameterised (dart-define? flutter_flavor? hardcoded?). This is a Day-1 code question that will fork immediately if left unaddressed.

3. **BFF secrets management** — The spine correctly isolates API keys in the BFF. But it does not say where those keys are stored during development (`.dev.vars` Wrangler file?) vs. production (Cloudflare Workers Secrets?). A developer setting up the project for the first time has no guidance.

4. **App distribution for beta** — The PRD targets 20 beta users. The spine does not mention Firebase App Distribution, TestFlight, or any other distribution channel. While distribution is partially a DevOps concern, the choice of channel affects build signing configuration, which is a Day-1 architecture decision.

These are not minor omissions — items 1 and 2 will cause divergence on the first day of coding. At minimum, items 1–2 should be added as explicit open questions in the spine, and items 3–4 should be added to Deferred with a decision note.

---

### 7. The diagrams are valid Mermaid

**Result: PASS with one note**

**Design Paradigm diagram (graph LR):** Valid. Subgraphs, node declarations, and edges are all syntactically correct. The `feature["features/{feature}/"]` label with curly braces may render inconsistently across Mermaid versions (some parsers treat `{}` as special). Safe to keep but worth testing in the target renderer.

**System Context diagram (graph TB):** Valid. Labels with quotes, subgraphs, styled nodes, and directional arrows are all correct. `style` directives are valid syntax.

**ERD diagram:** Valid. All entity/attribute blocks and relationship lines conform to Mermaid ERD syntax. The `"nullable — UUID partagé si issu d'un reçu"` label inside an attribute is non-standard but tolerated by most parsers as a string value. No issue in practice.

No placeholder graphs (e.g., `graph LR; A-->B`). All three diagrams convey real architectural content.

---

## Summary of Findings

| ID | Severity | Checklist Item | Finding |
|---|---|---|---|
| O-1 | High | #6 — Operational envelope | BFF URL parameterisation, build flavors, secrets management, and beta distribution are entirely absent — not decided, not deferred, not listed as open questions. Will cause Day-1 divergence. |
| D-1 | Medium | #3 — Deferred items | "Stratégie de tests — à définir au niveau epic" is a genuine divergence risk: two developers will independently pick incompatible testing approaches without a guiding AD or open question. |
| C-1 | Low | #5 — Capability coverage | FR-12 receipt grouping (`receipt_id` query pattern) is not governed by any AD in the Capability Map, leaving the history-screen developer without architectural guidance. |
| V-1 | Low | #4 — Named tech verified | `flutter_riverpod ^3.3.2` is not flagged "à confirmer" unlike the other three packages. Mistral `mistral-small-latest` is a floating alias — pinning recommended before beta. |
| Ph-1 | Low | #1 — Divergence points | Photo lifecycle (FR-9: "not stored locally permanently") and PRD open question 4 (Mindee data retention policy, flagged BLOQUANT BETA) are absent from both ADs and Deferred. |

---

## Recommended Actions (ordered by priority)

1. **Add an "Environments & Operations" section** (or open questions) covering: BFF URL per environment (dart-define strategy), Wrangler environments for dev/staging/prod, secrets management pattern (.dev.vars vs. CF Secrets), and beta distribution channel.

2. **Promote test strategy to a minimal AD** (e.g., AD-10): "Repositories are tested against in-memory Drift databases. BFF handlers are tested with Miniflare. No mocking of domain models in unit tests." Or move to explicit open question with a decision deadline.

3. **Add FR-12 grouping to Capability Map**: Update the FR-9 to FR-12 row to reference AD-3 and add a convention note that `receipt_id`-based grouping is resolved at provider level (consistent with AD-1 derived state).

4. **Flag flutter_riverpod version** with "¹ à confirmer" for consistency. Add a note about pinning Mistral model alias before beta.

5. **Add photo lifecycle to Deferred or AD-4**: Extend AD-4 or add a Deferred note: "Photo not persisted beyond BFF response; Mindee data retention policy must be verified before beta launch (PRD §10, question 4)."
