---
baseline_commit: NO_VCS
story_key: 2-2-transaction-form
status: review
---

# Story 2.2 — Saisie manuelle d'une Dépense ou d'un Revenu

## Story

**En tant qu'** utilisateur,
**Je veux** enregistrer rapidement une dépense ou un revenu depuis l'écran d'accueil,
**Afin que** mon solde reflète immédiatement la réalité de mes finances.

## Acceptance Criteria

- **AC-1:** L'utilisateur appuie sur le FAB `+` → un menu bottom sheet s'ouvre avec 2 options : « Scan Reçu » (grisé, non fonctionnel) et « Nouvelle transaction ».
- **AC-2:** L'utilisateur sélectionne « Nouvelle transaction » → le bottom sheet Transaction s'ouvre avec : segmented control Dépense/Revenu (Dépense par défaut), champ montant Display centré (clavier numérique natif), champ Catégorie, champ Date (défaut : aujourd'hui), champ Note (optionnel).
- **AC-3:** L'utilisateur appuie sur le champ Catégorie → le bottom sheet Transaction se ferme et le Sélecteur Catégorie s'ouvre (grille 4 colonnes de pastilles, prédéfinies d'abord puis personnalisées, séparées par un divider) ; après sélection, le Sélecteur se ferme et le bottom sheet Transaction se rouvre avec la catégorie pré-remplie.
- **AC-4:** Tous les champs obligatoires remplis (montant > 0, catégorie sélectionnée) → CTA « Enregistrer » actif → `TransactionRepository.insert()` appelé, bottom sheet ferme, solde et Accueil mis à jour immédiatement (< 100 ms via Riverpod réactif).
- **AC-5:** Montant = 0 ou vide → CTA « Enregistrer » désactivé.
- **AC-6:** Segmented control sur « Revenu » + enregistrement → `type = revenu`, solde augmente, transaction dans Historique avec `+` et couleur `success`.
- **AC-7:** Hors connexion → saisie 100 % locale, aucun indicateur réseau affiché.

## Tasks / Subtasks

### Task 1: TransactionRepository — TDD
- [x] 1.1 Tests RED : `insert()` crée une transaction avec type, amountCents, categoryId, note ; génère un UUID unique
- [x] 1.2 Créer `lib/shared/data/transaction_repository.dart` — `insert()`, `update()`, `delete()`
- [x] 1.3 Créer `lib/shared/providers/transaction_repository_provider.dart` — `Provider<TransactionRepository>`
- [x] 1.4 Tests GREEN — tous les tests repository passent

### Task 2: Utilitaires catégorie
- [x] 2.1 Créer `lib/shared/utils/category_utils.dart` — mapping `colorToken → (bg, fg)` et `iconName → IconData`

### Task 3: CategorySelectorSheet
- [x] 3.1 Créer `lib/shared/widgets/category_selector_sheet.dart` — `ConsumerWidget`, grille 4 colonnes de pastilles `CategoryPastille` (52px), anneau accent 2px sur catégorie sélectionnée, prédéfinies / divider / personnalisées, retourne `Category?` à la sélection

### Task 4: TransactionFormSheet
- [x] 4.1 Créer `lib/shared/widgets/transaction_form_sheet.dart` — `ConsumerStatefulWidget`, segmented Dépense/Revenu, champ montant (clavier `number`), catégorie, date (`showDatePicker`, JJ/MM/AAAA), note, CTA « Enregistrer » (désactivé si montant=0/vide ou catégorie absente), pop avec `PickCategorySignal` si catégorie tappée

### Task 5: FabMenuSheet
- [x] 5.1 Créer `lib/shared/widgets/fab_menu_sheet.dart` — liste 2 options : « Scan Reçu » (grisé, `onTap: null`) + « Nouvelle transaction » (retourne `'new_transaction'`)

### Task 6: Câblage FAB + navigation loop
- [x] 6.1 Mettre à jour `lib/features/dashboard/screens/home_shell.dart` — ajouter `_HomeFab` private widget : ouvre `FabMenuSheet` → `TransactionFormSheet` ↔ `CategorySelectorSheet` sans empilement (AC-3, UX-DR20)

## Dev Notes

### Architecture constraints
- `FabMenuSheet`, `TransactionFormSheet`, `CategorySelectorSheet` → `lib/shared/widgets/` (HomeShell en `features/dashboard/` ne peut pas importer depuis `features/transactions/` — AD-2)
- `TransactionRepository` → `lib/shared/data/transaction_repository.dart` (seul écrivain — AD-10)
- IDs toujours UUID v4 via `package:uuid` — jamais AUTOINCREMENT

### Schéma categories
- `colorToken`: 'success' | 'accent' | 'danger' | 'warning' | 'text-secondary'
- `icon`: nom Material icon string ('restaurant', 'directions_bus', etc.)

### PickCategorySignal + TransactionFormData
- `TransactionFormData` : données formulaire inter-sheets (type, amountText, category, date, note)
- `PickCategorySignal` : signal renvoyé par TransactionFormSheet quand catégorie tappée
- Navigation loop gérée dans `_HomeFab._runFormLoop()` — récursive, jamais d'empilement

### Montants
- Utilisateur saisit en FCFA → `amountCents = int.parse(text) * 100`
- `FilteringTextInputFormatter.digitsOnly` — entiers uniquement

### Tests
- Tests widget absents (project-context.md MVP)
- 6 tests repository : insert type/montant, UUID unique, note présente/nulle, date epoch, type depense

## Dev Agent Record

### Implementation Plan
Ordre : Task 1 TDD Repository → Task 2 CategoryUtils → Task 3 CategorySelectorSheet → Task 4 TransactionFormSheet → Task 5 FabMenuSheet → Task 6 Câblage FAB

### Debug Log

| # | Issue | Fix |
|---|-------|-----|
| 1 | `FabMenuSheet` / `TransactionFormSheet` dans `features/transactions/` provoquerait une violation AD-2 (HomeShell = `features/dashboard/`) | Déplacé vers `lib/shared/widgets/` |

### Completion Notes

- 38/38 tests passent (6 nouveaux), `flutter analyze` : 0 issues
- AC-3 : navigation loop dans `_HomeFab._runFormLoop()` — récursion, jamais deux sheets simultanés (UX-DR20)
- AC-4 : balance recalculée via `transactionListProvider` (Stream Drift) → `balanceProvider` — < 100ms garanti
- AC-5 : CTA désactivé si `amountText.isEmpty || int.parse(amountText) == 0 || category == null`
- AC-7 : 100% local — TransactionRepository écrit dans SQLite sans réseau

## File List

### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/2-2-transaction-form.md`
- `lib/shared/data/transaction_repository.dart`
- `lib/shared/providers/transaction_repository_provider.dart`
- `lib/shared/utils/category_utils.dart`
- `lib/shared/widgets/category_selector_sheet.dart`
- `lib/shared/widgets/transaction_form_sheet.dart`
- `lib/shared/widgets/fab_menu_sheet.dart`
- `test/shared/data/transaction_repository_test.dart`

### Fichiers modifiés
- `lib/features/dashboard/screens/home_shell.dart`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-02 | Story créée et implémentée — 38/38 tests, 0 issues analyze — statut review |

## Status

review
