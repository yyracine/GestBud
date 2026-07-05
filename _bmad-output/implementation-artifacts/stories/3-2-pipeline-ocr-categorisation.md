---
baseline_commit: NO_VCS
story_key: 3-2-pipeline-ocr-categorisation
status: in-progress
---

# Story 3.2 — Pipeline OCR, catégorisation IA et état de chargement

## Story

**En tant qu'** utilisateur,
**Je veux** voir un indicateur de chargement clair pendant que mon reçu est analysé, puis les lignes extraites avec leurs catégories suggérées,
**Afin de** savoir que le traitement est en cours et de pouvoir corriger le résultat.

## Acceptance Criteria

- **AC-1:** La photo est envoyée au BFF et le traitement est en cours → l'écran Skeleton s'affiche : barres de hauteur variable sur fond `surface-raised` reproduisant la géométrie d'une liste de lignes, animation pulse (opacité 0.4 → 0.8 → 0.4, 1.2 s). (déjà implémenté en Story 3.1)

- **AC-2:** Reduce Motion est activé sur l'appareil → fond statique `surface-raised` sans animation pulse (UX-DR12). (déjà implémenté en Story 3.1)

- **AC-3:** L'analyse se termine dans les 10 secondes → l'écran Revue Reçu s'affiche avec les lignes extraites (libellé + montant + catégorie suggérée pour chaque ligne).

- **AC-4:** L'analyse dépasse 10 secondes (timeout) → le skeleton est remplacé par un message d'erreur : « Impossible de lire le reçu. Saisis-le manuellement. » et un CTA « Saisie manuelle » ouvrant le bottom sheet Transaction.

- **AC-5:** Le BFF reçoit la photo → Mindee v2 async polling sur `/jobs/{jobId}` → lignes OCR envoyées en un seul prompt Mistral (batch) → fallback dictionnaire si Mistral échoue → `category: "Autre"` pour lignes non reconnues → montants en `amount_cents` (centimes).

- **AC-6:** L'app Flutter reçoit la réponse BFF → format identique `[{label, amount_cents, category}]` que Mistral ou fallback. Flutter ne distingue pas les deux chemins.

## Tasks / Subtasks

### Task 1: BFF — categorize.ts — extraire `categorizeLines` + Mistral + fallback
- [x] 1.1 Exporter `categorizeLines(lines, env)` depuis `bff/src/handlers/categorize.ts` — prompt Mistral batch + fallback dictionnaire de mots-clés + `handleCategorize` conservé

### Task 2: BFF — scan.ts — Mindee v2 polling + orchestration
- [x] 2.1 Implémenter `handleScan` complet : extraire image du multipart → Mindee v2 async POST/GET polling → appel `categorizeLines` → réponse `{ lines: [{label, amount_cents, category}] }`

### Task 3: Flutter — ReceiptLine model
- [x] 3.1 Créer `lib/shared/domain/receipt_line.dart` — `ReceiptLine(label, amountCents, category)` + `fromJson`

### Task 4: Flutter — ScanLoadingScreen — timeout + parsing + navigation
- [x] 4.1 Ajouter `_LoadState.timeout` + `_TimeoutErrorState` widget ("Impossible de lire le reçu. Saisis-le manuellement." + CTA saisie manuelle)
- [x] 4.2 Mettre à jour `_sendToServer()` — `TimeoutException` → timeout, `SocketException` → networkError, succès → parser `{ lines }` → `Navigator.pushReplacement` vers `ScanReviewScreen`

### Task 5: Flutter — ScanReviewScreen (affichage des lignes)
- [x] 5.1 Créer `lib/features/scan/screens/scan_review_screen.dart` — AppBar "Revue du reçu", liste des lignes (pastille catégorie + libellé + montant FCFA), bouton "Valider le reçu" inactif (Story 3.4)
- [x] 5.2 Ajouter `categoryVisuals(String name)` dans `lib/shared/utils/category_utils.dart` pour obtenir (icon, colorToken) depuis le nom de catégorie

## Dev Notes

### Architecture
- `ReceiptLine` → `lib/shared/domain/receipt_line.dart` (modèle transient, pas persisté)
- `ScanReviewScreen` → `lib/features/scan/screens/scan_review_screen.dart`
- Navigation: `ScanLoadingScreen → ScanReviewScreen` via `Navigator.pushReplacement` (supprime le loading de la pile)
- État édition en Story 3.3 via `StateProvider<List<ReceiptLine>>`

### BFF Pipeline
- Mindee v2 async: POST `/products/mindee/expense_receipts/v5/predict_async` → jobId → GET polling `/documents/queue/{jobId}`
- Poll strategy: max 5 × 2 s = 10 s max (CF Worker wall time limite ~30 s)
- Mistral `mistral-small-latest`: un seul prompt avec toutes les lignes — réponse JSON `[{index, category}]`
- Fallback dict: regex sur le libellé → catégorie prédéfinie, sinon "Autre"
- Si `MINDEE_API_KEY` absent → retourne `{ lines: [] }` (dev local sans API)
- Si `MISTRAL_API_KEY` absent → fallback dict uniquement

### Timeout Flutter
- `postMultipart` timeout existant = 10 s (`_timeout = Duration(seconds: 10)`)
- `TimeoutException` → `_LoadState.timeout` → "Impossible de lire le reçu. Saisis-le manuellement."
- `SocketException` → `_LoadState.networkError` → "Pas de connexion réseau." (Story 3.1)

### Formatage montants
- Utiliser `TransactionTile._formatCents` pattern ou dupliquer dans `scan_review_screen.dart`

### Security invariants
- ❌ MINDEE_API_KEY et MISTRAL_API_KEY uniquement dans les secrets Wrangler (`.dev.vars` en dev)
- ❌ Photo non conservée après traitement Mindee (AD-4) — BFF stateless

### Tests
- Tests widget absents (project-context.md Phase MVP)
- Validation : flutter test (45 tests existants) + flutter analyze

## Dev Agent Record

### Implementation Plan
Ordre : Task 1 (categorize.ts refactor + Mistral) → Task 2 (scan.ts Mindee) → Task 3 (ReceiptLine) → Task 4 (ScanLoadingScreen) → Task 5 (ScanReviewScreen + CategoryUtils)

### Debug Log

| # | Issue | Fix |
|---|-------|-----|

### Completion Notes

- 45/45 tests passent (aucun nouveau — tests widget absents Phase MVP), `flutter analyze` : 0 issues
- AC-1/2 : Skeleton + Reduce Motion déjà implémentés en Story 3.1 — inchangés
- AC-3 : `_sendToServer()` parse `{ lines }` → `ReceiptLine.fromJson` → `Navigator.pushReplacement(ScanReviewScreen)`
- AC-4 : `TimeoutException` → `_LoadState.timeout` → `_TimeoutErrorState` ("Impossible de lire le reçu. Saisis-le manuellement." + CTA saisie manuelle)
- AC-5 : `handleScan` orchestre Mindee v2 (POST submit + GET polling 5×2 s) → `categorizeLines` (Mistral batch → fallback dict si MISTRAL_API_KEY absent ou erreur)
- AC-6 : format réponse `[{label, amount_cents, category}]` identique quel que soit le chemin Mistral/fallback
- `ReceiptLine` : champs mutables (`label`, `amountCents`, `category`) — prêt pour Story 3.3 (`StateProvider<List<ReceiptLine>>`)
- `ScanReviewScreen` : affichage lecture seule, bouton "Valider le reçu" `onPressed: null` — Story 3.4 l'activera
- `CategoryUtils.categoryVisuals(name)` : mappe nom catégorie → (iconName, colorToken) pour les pastilles dans `ScanReviewScreen`

### File List

#### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/3-2-pipeline-ocr-categorisation.md`
- `lib/shared/domain/receipt_line.dart`
- `lib/features/scan/screens/scan_review_screen.dart`

#### Fichiers modifiés
- `bff/src/handlers/categorize.ts`
- `bff/src/handlers/scan.ts`
- `lib/features/scan/screens/scan_loading_screen.dart`
- `lib/shared/utils/category_utils.dart`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-03 | Story créée et implémentée — 45/45 tests, 0 issues analyze — statut review |

## Status

review
