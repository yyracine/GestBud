---
baseline_commit: 830a841f506552392e0e452e218446acf1b15807
story_key: 5-1-liste-categories
status: in-progress
---

# Story 5.1 — Liste des catégories et accès depuis les Paramètres

## Story

**En tant qu'** utilisateur,
**Je veux** accéder à la liste de toutes mes catégories depuis les Paramètres,
**Afin de** voir ce qui est disponible et d'y gérer mes catégories personnalisées.

## Acceptance Criteria

- **AC-1:** L'écran Paramètres affiche un lien « Gérer mes catégories » en plus du bouton « Se déconnecter ».

- **AC-2:** Un tap sur « Gérer mes catégories » navigue vers l'écran Gestion des Catégories (`/settings/categories`).

- **AC-3:** L'écran Gestion des Catégories liste toutes les catégories : les 10 prédéfinies en premier, puis les catégories personnalisées (triées par `createdAt` croissant), chaque ligne conforme UX-DR15 (pastille 40px à gauche, nom Body au centre).

- **AC-4:** Une catégorie prédéfinie : sa ligne n'affiche pas d'icônes crayon ni corbeille et n'est pas interactive au-delà de l'affichage.

- **AC-5:** Une catégorie personnalisée : sa ligne affiche une icône crayon (renommer) et une icône corbeille (supprimer) à droite, espacées de 12px, cibles ≥ 44px.

- **AC-6:** Aucune catégorie personnalisée n'existe encore → seules les 10 prédéfinies s'affichent, avec un bouton `+` visible en bas à droite.

## Tasks / Subtasks

### Task 1: `CategoryManagementScreen` + `sortCategories`
- [x] 1.1 Créer `lib/features/categories/screens/category_management_screen.dart` — `ConsumerWidget` lisant `categoryListProvider`. Exporter `sortCategories(List<Category>) → List<Category>` (prédéfinies d'abord, personnalisées triées par `createdAt`). `_CategoryTile` conforme UX-DR15 : pastille 40px · nom Body · icônes crayon/corbeille pour personnalisées (handlers vides — Story 5.3). FAB `+` visible (handler vide — Story 5.2).

### Task 2: Tests — `sortCategories`
- [x] 2.1 Créer `test/features/categories/category_management_screen_test.dart` — 6 tests purs sur `sortCategories` : liste vide, prédéfinies avant custom, custom triées par createdAt, mélange, seules prédéfinies, seules custom.

### Task 3: Route `/settings/categories`
- [x] 3.1 Modifier `lib/shared/routing/app_router.dart` — ajouter `GoRoute(path: '/settings/categories', ...)` important `CategoryManagementScreen`.

### Task 4: Mise à jour `SettingsScreen`
- [x] 4.1 Modifier `lib/features/auth/screens/settings_screen.dart` — ajouter `ListTile` « Gérer mes catégories » (icône `category`, couleur `textPrimary`) avant « Se déconnecter », navigue vers `/settings/categories`.

## Dev Notes

### Architecture
- `CategoryManagementScreen` dans `features/categories/screens/` — conforme feature-based (AD-2)
- Réutilise `categoryListProvider` (StreamProvider AD-11) — pas de nouveau StreamProvider
- `sortCategories` exportée comme fonction pure pour testabilité (même pattern que stories précédentes)
- Route `/settings/categories` ajoutée comme GoRoute top-level (hors ShellRoute)

### `sortCategories` — logique
```
[...predefined (ordre DB), ...custom.sortedBy(createdAt)]
```
- Prédéfinies : ordre issu de la base (insertion seed)
- Personnalisées : `createdAt` ASC → la plus ancienne apparaît en premier

### `_CategoryTile` — UX-DR15
- Padding : `16px` vertical · `16px` horizontal
- Pastille : `Container(40×40, BoxShape.circle, CategoryUtils.pastilleColors(colorToken))`
- Nom : `Body 15px/400 textPrimary`
- Icônes custom : `Icons.edit_outlined` (textSecondary) + `Icons.delete_outline` (danger), `IconButton` avec `minWidth/minHeight: 44`, espacées `SizedBox(width: 12)`
- Prédéfinies : sans icônes (condition `!category.isPredefined`)

### Tests — pattern
Même pattern que stories précédentes : fonctions pures uniquement, tests synchrones.

## Dev Agent Record

### Implementation Plan
Ordre : Task 1 → Task 2 (RED→GREEN) → Task 3 → Task 4 → validation finale

### Debug Log

| # | Issue | Fix |
|---|-------|-----|

### Completion Notes

- 128/128 tests passent (6 nouveaux), `flutter analyze` : 0 issues
- AC-1 : `ListTile` « Gérer mes catégories » ajouté dans `SettingsScreen` avant « Se déconnecter »
- AC-2 : Route `/settings/categories` → `CategoryManagementScreen` via GoRouter
- AC-3 : `sortCategories()` → prédéfinies (ordre DB) puis custom (createdAt ASC) ; `_CategoryTile` conforme UX-DR15
- AC-4 : Condition `!category.isPredefined` → icônes absentes pour les prédéfinies
- AC-5 : `IconButton` crayon + corbeille avec `minWidth/minHeight: 44`, `SizedBox(width: 12)` entre eux
- AC-6 : FAB `+` toujours visible (handler vide, Story 5.2)
- Fix : `unnecessary_underscores` lint → `(_, __)` remplacé par `(_, _)` (Dart 3 wildcard)

### File List

#### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/5-1-liste-categories.md`
- `lib/features/categories/screens/category_management_screen.dart`
- `test/features/categories/category_management_screen_test.dart`

#### Fichiers modifiés
- `lib/shared/routing/app_router.dart`
- `lib/features/auth/screens/settings_screen.dart`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-05 | Story créée et implémentée — 128/128 tests, 0 issues analyze — statut review |

## Status

review
