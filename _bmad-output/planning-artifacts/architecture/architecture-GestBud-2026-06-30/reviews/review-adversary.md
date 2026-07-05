---
type: adversarial-architecture-review
target: ARCHITECTURE-SPINE.md
reviewer: adversary
date: 2026-06-30
verdict: FAIL — 7 incompatible pairs found; 6 new or tightened ADs required
---

# Adversarial Architecture Review — GestBud

## Method

Each pair is constructed so that both units follow every stated AD to the letter yet produce an integration clash. The clash is the gap — a constraint that the spine does not yet express.

---

## Pair 1 — `scan/` vs `transactions/` : conflicting ownership of the Transaction write path

**Units:** `features/scan/repository/` · `features/transactions/repository/`

**How each unit obeys all ADs:**

- Both call `TransactionDao` (AD-3: all SQLite access via Drift DAOs).
- Neither imports the other (AD-2: no cross-feature import).
- Both expose a `saveTransaction()` method through their own repository (AD-1: state via Riverpod; the Conventions table says "Only the Repository writes to the DB via DAO").
- Both accept `amount_cents: int` (AD-8).
- Both read currency from `settingsProvider` (AD-9).

**The clash:**

Two repositories are each the "only writer" to `Transactions`. The Conventions table says "Seul le Repository écrit en base via DAO" (singular). With two repositories each calling `TransactionDao.insert()`, the following breaks:

1. **Receipt-line deduplication is undefined.** AD-3 specifies `receipt_id TEXT nullable` shared across lines from the same receipt. `scan/repository/` generates that UUID and calls `insert()`. If `transactions/repository/` also calls `insert()` (e.g., during a correction flow), nothing prevents two different `receipt_id` values being assigned, or the same row being inserted twice. No AD assigns UUID generation responsibility.

2. **Post-save side-effects diverge.** If `transactions/repository/` emits a Drift `Stream` event after insert, and `scan/repository/` bypasses it by writing directly to the DAO in a different transaction batch, `soldeProvider` (a derived provider listening to that stream) sees partial data mid-write for multi-line receipts.

3. **Conflict on the `note` field.** `scan/` attaches the raw OCR label as `note`. `transactions/` attaches user-typed text as `note`. The spine does not define which wins when a scanned line is edited before saving.

**Missing AD:** A single authoritative write path for `Transaction` inserts — either one named owner or an explicit mediator in `shared/`. `scan/` must stage lines and delegate final persistence to `transactions/repository/`, or `shared/data/` must expose a `TransactionWriter` that both call.

---

## Pair 2 — `categories/` vs `shared/providers/categoryListProvider` : dual-owner of the Category entity

**Units:** `features/categories/repository/` · `shared/providers/categoryListProvider`

**How each unit obeys all ADs:**

- `categories/repository/` uses `CategoryDao` for all reads/writes (AD-3). It exposes a Riverpod provider inside `features/categories/providers/` (AD-1).
- `shared/providers/categoryListProvider` is declared in `shared/providers/` (AD-2 compliant — it is the allowed cross-feature bridge), reads from `CategoryDao`, and returns the list used by `transactions/` and `dashboard/`.
- Neither imports the other feature (AD-2).

**The clash:**

1. **Two live `Stream` subscriptions to `CategoryDao`.** `categories/providers/` opens a watch-stream for the categories screen (to show live updates during rename/delete). `shared/providers/categoryListProvider` opens a second independent watch-stream for the rest of the app. Drift allows multiple subscribers, but they are separate listeners — mutation by `categories/repository/` triggers both streams asynchronously. During a delete, `dashboard/` may briefly display a transaction whose `category_id` FK points to a row that is already gone in the local stream snapshot but not yet reflected in `categoryListProvider`. No AD defines the ordering or isolation of these two subscriptions.

2. **Predefined category seeding is unassigned.** AD-3 establishes `is_predefined` on the CATEGORY entity but assigns no feature the duty of seeding default categories on first launch. `categories/` might seed them; `shared/data/` might seed them in an AppDatabase callback. If both do it (each obeying AD-3 by using `CategoryDao`), the seed runs twice and violates uniqueness. If neither does it, the app starts with an empty category list that breaks `transactions/`.

3. **Rename/delete authority is ambiguous.** `categories/repository/` can rename a category. But `shared/providers/categoryListProvider` vends the list to `transactions/` and `dashboard/` — if those features cache the category name in their own derived providers (fully legal under AD-1), a rename in `categories/` is not guaranteed to invalidate derived providers in other features. AD-1 says derived state is computed by providers, not stored in DB — but it does not say which provider invalidation chain governs cross-feature category changes.

**Missing AD:** Declare `CategoryDao` ownership: seeding responsibility (one named locus), and a rule that `shared/providers/categoryListProvider` is the single Drift stream for category reads app-wide — `categories/` uses it rather than opening its own stream.

---

## Pair 3 — `scan/` BFF response shape vs `transactions/` domain model : incompatible `Transaction` construction

**Units:** `features/scan/` (BFF response consumer) · `features/transactions/` (manual entry, domain model owner)

**How each unit obeys all ADs:**

- AD-4/AD-5: `scan/` calls only the BFF and accepts `[{label, amount, category}]`.
- AD-8: `scan/` must store `amount_cents: int`. So it converts `amount` from the BFF response to cents.
- AD-3: `transactions/` creates `Transaction` domain objects and persists via `TransactionDao`.
- AD-2: neither imports the other.

**The clash:**

1. **`amount` unit in BFF response is undefined.** AD-5 specifies the BFF returns `[{label, amount, category}]`. AD-8 mandates `amount_cents INTEGER` in Drift. The spine never declares whether the BFF `amount` field is already in cents (INTEGER) or in the display unit (e.g., 1500.00 FCFA as a float). If `scan/repository/` assumes `amount` is already in cents and `transactions/repository/` independently builds `Transaction` with `amountCents = (userInput * 100).round()`, a receipt line of "1500 FCFA" is stored as either 1500 or 150000 depending on which path created it. Both implementations obey AD-8 (they store integers) and AD-5 (they call the BFF). The ERD shows `amount_cents` but the BFF contract does not.

2. **`currency` field on `TRANSACTION` row.** The ERD schema includes `currency TEXT` on `TRANSACTION`. AD-9 says currency comes from `settingsProvider`. `transactions/` can legally copy `settingsProvider.currency` into the row at insert time. `scan/` may omit the field (it's not in the BFF response shape `{label, amount, category}`) and leave it NULL or default. Both approaches comply with every stated AD, yet produce rows with inconsistent `currency` population — breaking any future multi-currency query.

**Missing AD:** Define the BFF wire contract as an explicit schema (amount unit, currency field presence) and assign `scan/repository/` the duty of populating `currency` from `settingsProvider` before insert.

---

## Pair 4 — `dashboard/soldeProvider` vs `scan/` multi-line receipt insert : non-atomic reactivity

**Units:** `features/dashboard/providers/soldeProvider` · `features/scan/repository/` (batch insert)

**How each unit obeys all ADs:**

- `soldeProvider` is a derived `Provider` computed from `TransactionDao` stream (AD-1: derived state never persisted; AD-3: reads via DAO).
- `scan/repository/` inserts N rows for a single receipt, one `TransactionDao.insert()` call per line (AD-3 does not require batch inserts; it only requires DAOs).
- AD-9: `soldeProvider` reads currency from `settingsProvider`.

**The clash:**

Drift's `watchAll()` stream emits after every single row insert. `scan/` inserts N lines in a loop. Between insert 1 and insert N, `soldeProvider` recomputes N−1 intermediate balances, each triggering a UI rebuild of the dashboard. The final balance is correct, but:

1. **Intermediate states are observable.** A user who has the dashboard visible while a scan is saving sees the balance tick up line by line. This is a UX defect but — critically — it is architecturally ambiguous: does the spine allow intermediate stream emissions during a multi-row write, or does it require atomic batch writes? No AD addresses transaction (DB-transaction) semantics.

2. **Error in mid-batch insert leaves partial data.** If `scan/repository/` inserts lines 1–3 of a 5-line receipt and then a `DatabaseFailure` is thrown, lines 1–3 are committed (no DB transaction wrap required by any AD). `soldeProvider` now reflects a balance that includes partial receipt data. AD-3 specifies receipt_id for grouping but does not mandate wrapping a multi-line receipt in a single Drift DB transaction.

**Missing AD:** Require that all inserts for a single receipt are wrapped in a Drift `transaction()` block, and that DAOs expose a batch-insert method. This makes atomicity explicit and prevents partial-balance states.

---

## Pair 5 — `auth/` session guard vs `shared/routing/app_router.dart` : two legal implementations of the redirect that produce incompatible session-check logic

**Units:** `features/auth/providers/` (session state) · `shared/routing/app_router.dart` (GoRouter redirect)

**How each unit obeys all ADs:**

- AD-6: the auth guard lives in GoRouter's `redirect` callback in `shared/routing/app_router.dart` — not in widgets.
- AD-7: the session token is read via `flutter_secure_storage`.
- AD-1: auth state is a Riverpod provider in `features/auth/providers/`.

**The clash:**

AD-6 says the redirect reads "session absente" — but it does not specify *which artifact* is the source of truth for "session present":

- **Implementation A:** `app_router.dart` reads `flutter_secure_storage` directly (synchronous check not possible — FSS is async; the developer wraps it in a `FutureProvider`). GoRouter's `redirect` is synchronous (go_router ≥ 7 does support `redirectFirst` but requires specific setup). A developer following AD-6 literally (guard in router) and AD-7 literally (FSS for token) may write an async redirect that blocks navigation on cold start.

- **Implementation B:** `auth/providers/sessionProvider` holds a `bool isAuthenticated` derived from FSS. `app_router.dart` reads `ref.read(sessionProvider)` in the redirect. This is synchronous but requires GoRouter to be `ProviderScope`-aware (using `ref` inside `redirect` via `riverpod_gorouter` or a manual `ref` capture). AD-6 and AD-1 both permit this but do not mandate it.

Both implementations fully obey AD-1, AD-6, and AD-7. They are architecturally incompatible: A blocks navigation until FSS resolves (flicker / race on cold start), B requires a specific Riverpod-GoRouter integration pattern that is not mandated. A dev implementing A and a dev implementing B will have conflicting code in `app_router.dart` that cannot be merged.

**Missing AD:** Specify that `app_router.dart` reads a named `sessionProvider` (not FSS directly), and that `sessionProvider` is initialized during the ProviderScope bootstrap before GoRouter first resolves. The FSS read happens once at app start, not inside the redirect callback.

---

## Pair 6 — `categories/` delete vs `transactions/` display : referential integrity not governed

**Units:** `features/categories/repository/` (delete) · `features/transactions/` (display)

**How each unit obeys all ADs:**

- `categories/repository/` calls `CategoryDao.delete(id)` (AD-3).
- `features/transactions/` reads `TransactionDao.watchAll()` and joins with category name for display (AD-3, AD-1).
- AD-2: no cross-feature import.
- No AD governs FK cascade behavior.

**The clash:**

AD-3 defines `CATEGORY ||--o{ TRANSACTION` in the ERD (a category can have zero or more transactions). It does not declare `ON DELETE` behavior for the FK. Drift does not enforce FK cascade by default (SQLite FK enforcement is opt-in with `PRAGMA foreign_keys = ON`).

- `categories/repository/` deletes a predefined or custom category. `transactions/` then calls `TransactionDao.watchAll()` — rows with `category_id` pointing to the deleted category either return a null join (if the query left-joins) or silently return stale data (if the query inner-joins). Both DAO implementations obey AD-3 (they use Drift, not raw SQL strings).

- Whether `PRAGMA foreign_keys = ON` is set in `AppDatabase` is unspecified. Two developers — one enabling it (rows fail to delete if transactions exist), one not (orphan rows) — both comply with every AD.

**Missing AD:** Declare FK enforcement strategy: either `PRAGMA foreign_keys = ON` in `AppDatabase` setup (AD-3 extension) with a `SET NULL` cascade on `category_id`, or a business rule that categories with linked transactions cannot be deleted (enforced in `categories/repository/`, not the DAO layer). Also specify the DAO join type (LEFT JOIN) so `transactions/` degrades gracefully.

---

## Pair 7 — `shared/providers/settingsProvider` vs `dashboard/soldeProvider` : currency mismatch on historical transactions

**Units:** `shared/providers/settingsProvider` · `features/dashboard/providers/soldeProvider`

**How each unit obeys all ADs:**

- `settingsProvider` reads `AppSettings.currency` from `SettingsDao` (AD-3, AD-9).
- `soldeProvider` is a derived provider that sums `amount_cents` from `TransactionDao` and attaches the active currency from `settingsProvider` (AD-1, AD-8, AD-9).
- The ERD shows `currency TEXT` on the TRANSACTION row.

**The clash:**

AD-9 defers multi-currency to V2 but mandates a `currency` column on every `TRANSACTION` row from V1. When the user changes the active currency (future V2 path, but the schema is V1-ready), `soldeProvider` will sum all historical `amount_cents` — some recorded when `currency = 'XOF'`, some when `currency = 'XAF'` — and display the total with the current active currency label. Both amounts are stored as integers (AD-8 compliant), but 1000 XOF-cents ≠ 1000 XAF-cents in real value.

However, even in V1 (single currency), the issue is already latent: `soldeProvider` sums all rows but does not filter or assert `WHERE currency = settingsProvider.currency`. If any insert path ever omits the `currency` field (see Pair 3 — scan omitting currency), `soldeProvider` silently includes those rows in the balance with no AD preventing it.

**Missing AD:** `soldeProvider` must explicitly filter `WHERE transaction.currency = settings.currency` and the spine must declare what happens when rows with mismatched currency exist (ignore, surface error, or refuse). This constraint belongs in AD-9 as an extension.

---

## Summary Table

| # | Pair | Clash type | Root gap |
|---|------|-----------|----------|
| 1 | `scan/repo` × `transactions/repo` | Dual writer, receipt UUID ownership | No single named Transaction writer |
| 2 | `categories/repo` × `shared/categoryListProvider` | Dual stream, no seeding owner | No single Category stream locus + no seeding rule |
| 3 | `scan/` BFF shape × `transactions/` domain | Wire unit ambiguity, nullable currency | BFF `amount` unit unspecified; currency population unassigned |
| 4 | `dashboard/soldeProvider` × `scan/` batch insert | Non-atomic multi-row insert | No DB-transaction requirement for receipt batches |
| 5 | `auth/providers` × `shared/routing` | Async/sync redirect incompatibility | Session truth source for GoRouter redirect unspecified |
| 6 | `categories/repo` delete × `transactions/` display | FK cascade unspecified | No PRAGMA / ON DELETE rule in AD-3 |
| 7 | `settingsProvider` × `soldeProvider` | Cross-currency sum contamination | AD-9 defers multi-currency but V1 rows already carry currency |

---

## Required new / tightened ADs

**AD-3 (tighten):** Add: (a) `PRAGMA foreign_keys = ON` in AppDatabase; (b) `category_id SET NULL ON DELETE`; (c) multi-line receipt inserts must be wrapped in a Drift `transaction()` block; (d) `TransactionDao` must expose a `batchInsert(List<TransactionCompanion>)` method.

**AD-5 (tighten):** Specify the BFF wire schema explicitly: `amount` is INTEGER centimes; the response shape is `[{label: string, amount_cents: int, category: string}]`. The BFF never returns floats for amounts.

**AD-8 (tighten):** Add: `scan/repository/` is responsible for assigning `currency` from `settingsProvider` before persisting BFF scan results — the BFF response carries no currency field.

**AD-9 (tighten):** Add: `soldeProvider` filters `WHERE currency = settingsProvider.currency`; rows with mismatched or null `currency` must be surfaced as a `DatabaseFailure`, not silently included.

**AD-10 (new) — Single Transaction write authority:** `features/transactions/repository/TransactionRepository` is the sole writer of `Transaction` rows. `features/scan/` stages corrected lines as `PendingTransactionDraft` objects and passes them to `TransactionRepository.saveAll()` via `shared/providers/`. No other repository calls `TransactionDao.insert/update/delete` directly.

**AD-11 (new) — Category stream and seeding ownership:** `shared/providers/categoryListProvider` is the single Drift watch-stream for categories across the entire app. `features/categories/` uses this provider for display and calls `CategoryRepository` for mutations. `AppDatabase.onCreate` seeds predefined categories exactly once; `CategoryRepository` must not re-seed. `features/categories/` does not open an independent DAO stream.

**AD-12 (new) — GoRouter session check:** The GoRouter `redirect` in `app_router.dart` reads only `ref.read(sessionStateProvider)` (a synchronous `bool`). `sessionStateProvider` is a `StateProvider<bool>` initialized to `false`, then set to `true` by `AuthRepository.checkSession()` during the app bootstrap sequence before the first route resolves. `AuthRepository.checkSession()` is the only point that reads `flutter_secure_storage`; it calls FSS once and writes the result into `sessionStateProvider`. No other code reads FSS for session status.
