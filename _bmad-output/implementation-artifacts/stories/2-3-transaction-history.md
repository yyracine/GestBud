---
baseline_commit: NO_VCS
story_key: 2-3-transaction-history
status: review
---

# Story 2.3 — Historique des Transactions

## Story

**En tant qu'** utilisateur,
**Je veux** parcourir la liste complète de mes transactions passées,
**Afin de** retrouver une dépense spécifique et suivre mes habitudes financières.

## Acceptance Criteria

- **AC-1:** L'utilisateur navigue vers l'onglet « Historique » et des transactions existent → la liste complète s'affiche triée par date décroissante, chaque ligne conforme UX-DR8 : pastille catégorie à gauche, libellé Body + date Caption/secondary en colonne, montant Body (préfixé `+`/`−`, coloré `success`/`danger`) à droite, hauteur min 60px, divider border en bas.

- **AC-2:** L'onglet Historique est affiché et aucune transaction n'existe → l'état vide s'affiche (UX-DR14) : icône wallet accent centrée, titre « Aucune transaction pour le moment. », CTA « Ajouter une transaction » ouvrant le bottom sheet Transaction.

- **AC-3:** L'utilisateur est sur l'Historique et une nouvelle transaction est ajoutée depuis le FAB → la liste se met à jour immédiatement sans action de l'utilisateur (StreamProvider réactif).

- **AC-4:** VoiceOver/TalkBack est actif sur une ligne → l'annonce combine dans l'ordre : nom de la catégorie, libellé, montant en francs CFA avec signe, date.

- **AC-5:** L'utilisateur effectue un swipe horizontal sur une ligne → aucune action ne se déclenche (swipe-to-delete absent sur l'Historique — UX-DR26).

## Tasks / Subtasks

### Task 1: Tri par date dans TransactionDao
- [x] 1.1 Mettre à jour `watchAll()` dans `TransactionDao` pour trier par `date DESC` (tri réactif)
- [x] 1.2 Mettre à jour `getAll()` pour cohérence

### Task 2: Composant TransactionTile
- [x] 2.1 Créer `lib/shared/widgets/transaction_tile.dart` — `TransactionTile` conforme UX-DR8 : pastille 40px, libellé Body + date Caption, montant Body (+/− coloré), min 60px, Semantics AC-4

### Task 3: HistoryScreen
- [x] 3.1 Créer `lib/features/transactions/screens/history_screen.dart` — `ConsumerWidget` : `transactionListProvider` + `categoryListProvider`, liste triée, état vide avec CTA ouvrant `TransactionFormSheet` (même loop que `_HomeFab`)

### Task 4: Câblage route
- [x] 4.1 Mettre à jour `lib/shared/routing/app_router.dart` — remplacer `_HistoryPlaceholder` par `HistoryScreen()`

## Dev Notes

### Architecture constraints
- `HistoryScreen` → `lib/features/transactions/screens/` (feature transactions)
- `TransactionTile` → `lib/shared/widgets/` (réutilisable depuis scan, dashboard, etc.)
- Aucun import cross-feature (AD-2)
- `transactionListProvider` existant (StreamProvider sur `watchAll()`) — pas de nouveau provider

### UX-DR8 TransactionTile
- Pastille catégorie 40px à gauche (UX-DR7)
- Libellé : `transaction.note` si présent, sinon type label ('Dépense' / 'Revenu')
- Date : `JJ/MM/AAAA` via `DateFormat('dd/MM/yyyy', 'fr')`
- Montant : `+` ou `−` préfixe non-coloré ; couleur `success` (revenu) / `danger` (dépense)
- `FontFeature.tabularFigures()` sur les montants
- `ConstrainedBox(minHeight: 60)` — cible de tap ≥ 44pt/48dp (NFR-3)
- Semantics label : "categorieName, libellé, signe+montant francs CFA, date"
- Séparateur milliers : U+202F (espace fine insécable)

### Empty state CTA
- `_runFormLoop` dupliqué (minimal, stateless) — même pattern que `_HomeFab` de home_shell.dart
- Pas d'abstraction partagée : les 15 lignes ne justifient pas un fichier dédié (project-context.md)

### Catégories
- `categoryListProvider` → `Map<String, Category>` dans le build
- `categoryMap[tx.categoryId]` peut être null (transaction orpheline) — `TransactionTile` gère via `Category?`

### Tests
- Tests widget absents (project-context.md Phase MVP)
- Validation : flutter test (38 tests existants) + flutter analyze

## Dev Agent Record

### Implementation Plan
Ordre : Task 1 (DAO sort) → Task 2 (TransactionTile) → Task 3 (HistoryScreen) → Task 4 (Router)

### Debug Log

| # | Issue | Fix |
|---|-------|-----|

### Completion Notes

- 38/38 tests passent (aucun nouveau — tests widget absents Phase MVP), `flutter analyze` : 0 issues
- AC-1 : `watchAll()` trié par `date DESC` → liste toujours décroissante sans sort côté UI
- AC-2 : état vide avec CTA ouvrant `TransactionFormSheet` via `_runFormLoop` (même pattern UX-DR20)
- AC-3 : `transactionListProvider` = `StreamProvider` sur `watchAll()` → réactivité automatique Drift
- AC-4 : `Semantics(label: 'catégorie, libellé, ±montant francs CFA, date')` sur chaque `TransactionTile`
- AC-5 : aucun `Dismissible` ni swipe — `InkWell` uniquement

## File List

### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/2-3-transaction-history.md`
- `lib/shared/widgets/transaction_tile.dart`
- `lib/features/transactions/screens/history_screen.dart`

### Fichiers modifiés
- `lib/shared/data/database/daos/transaction_dao.dart`
- `lib/shared/routing/app_router.dart`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-03 | Story créée et implémentée — 38/38 tests, 0 issues analyze — statut review |

## Status

review
