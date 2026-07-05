---
baseline_commit: 3b225ab
story_key: 5-2-creation-categorie-perso
status: in-progress
---

# Story 5.2 — Création d'une catégorie personnalisée

## Story

**En tant qu'** utilisateur,
**Je veux** créer une catégorie avec l'icône et la couleur de mon choix,
**Afin qu'** elle apparaisse immédiatement dans tous les sélecteurs de catégorie de l'app.

## Acceptance Criteria

- **AC-1:** Appuyer sur le bouton `+` de l'écran Gestion des Catégories ouvre le bottom sheet Création (UX-DR16) avec : grille 4 colonnes d'icônes, rangée 6 pastilles couleur (Rose · Sarcelle · Terracotta · Olive · Ardoise · Prune avec labels sémantiques accessibles), champ nom (placeholder « Nom de la catégorie ») ; présélection par défaut : premier icône + couleur Rose.

- **AC-2:** Champ nom vide → CTA « Créer » désactivé.

- **AC-3:** Nom identique à une catégorie existante (insensible à la casse, toutes catégories confondues) → bordure `danger`, message « Cette catégorie existe déjà. », CTA désactivé.

- **AC-4:** Sélection couleur → anneau `text-primary` 2px autour de la pastille sélectionnée.

- **AC-5:** Sélection icône → anneau `accent` 2px autour de l'icône sélectionnée.

- **AC-6:** Nom valide + couleur + icône sélectionnés + tap « Créer » → `CategoryDao.insertCategory()` appelé, bottom sheet fermé, nouvelle catégorie visible immédiatement dans la liste et dans tous les sélecteurs (via `categoryListProvider` réactif).

## Tasks / Subtasks

### Task 1: Tokens couleur + nouvelles icônes dans `CategoryUtils`
- [x] 1.1 Ajouter 6 paires couleur custom dans `pastilleColors()` : `cat-custom-rose`, `cat-custom-teal`, `cat-custom-terracotta`, `cat-custom-olive`, `cat-custom-slate`, `cat-custom-prune`
- [x] 1.2 Ajouter 16 entrées d'icône dans `iconData()` pour la grille du picker

### Task 2: `CategoryDao.insertCategory()`
- [x] 2.1 Ajouter `Future<void> insertCategory(CategoriesCompanion companion)` dans `category_dao.dart`

### Task 3: `CategoryFormSheet` + `isDuplicate`
- [x] 3.1 Créer `lib/features/categories/widgets/category_form_sheet.dart` — `ConsumerStatefulWidget` avec grille icônes 4 colonnes, rangée 6 couleurs, champ nom, validation doublon, CTA « Créer »
- [x] 3.2 Exporter `isDuplicate(String name, List<Category> existing) → bool` comme fonction pure (même pattern que `sortCategories`)

### Task 4: Tests — `isDuplicate`
- [x] 4.1 Créer `test/features/categories/category_form_sheet_test.dart` — 7 tests purs sur `isDuplicate`

### Task 5: Wiring FAB → `CategoryFormSheet`
- [x] 5.1 Modifier `CategoryManagementScreen` — FAB `onPressed` ouvre `CategoryFormSheet` via `showModalBottomSheet`

## Dev Notes

### Architecture
- `CategoryFormSheet` dans `features/categories/widgets/` — conforme feature-based (AD-2)
- Accès DB : `ref.read(databaseProvider).categoryDao.insertCategory(...)` — pas de nouveau provider
- `categoryListProvider` (AD-11) propagera la nouvelle catégorie automatiquement via `watchAll()`
- `isDuplicate` exportée comme fonction pure pour testabilité

### `isDuplicate` — logique
```
name.trim().toLowerCase() ∈ existing.map(c => c.name.toLowerCase())
```
- Insensible à la casse, toutes catégories confondues (prédéfinies + personnalisées)
- `name` trimmed avant comparaison

### `CategoryFormSheet` — UX-DR16
- Grille icônes : 4 colonnes × 4 lignes = 16 icônes Material, pastille 48px avec couleur sélectionnée ; anneau accent 2px sur icône sélectionnée
- Couleurs : 6 boutons cercles 44px en couleur fg vivide ; anneau text-primary 2px sur couleur sélectionnée
- Nom : TextField standard, bordure danger + message si doublon, CTA désactivé si vide ou doublon
- CTA « Créer » : accent, 52px height, radius 16, désactivé → accentDim
- Keyboard : `isScrollControlled: true` + `MediaQuery.viewInsetsOf(context).bottom`

### Couleurs custom (UX-DR1)
| Token | bg | fg |
|-------|----|----|
| `cat-custom-rose` | `#3D1533` | `#FF6BAF` |
| `cat-custom-teal` | `#0A2B2B` | `#00C2A8` |
| `cat-custom-terracotta` | `#3D1A0A` | `#E07A5F` |
| `cat-custom-olive` | `#1E2A0A` | `#8DB53E` |
| `cat-custom-slate` | `#1A1F30` | `#7B8EC8` |
| `cat-custom-prune` | `#280A3D` | `#B57BFF` |

### Tests — pattern
Même pattern que stories précédentes : fonctions pures uniquement, tests synchrones.

## Dev Agent Record

### Implementation Plan
Ordre : Task 1 → Task 2 → Task 3 (RED→GREEN) → Task 4 → Task 5 → validation finale

### Debug Log

| # | Issue | Fix |
|---|-------|-----|

### Completion Notes

- 135/135 tests passent (7 nouveaux), `flutter analyze` : 0 issues
- AC-1 : `CategoryFormSheet` ouverte par FAB — grille 16 icônes 4 col × 4 lignes + rangée 6 couleurs + champ nom + présélection `star` + `cat-custom-rose`
- AC-2 : CTA « Créer » désactivé si champ nom vide
- AC-3 : Bordure danger + message « Cette catégorie existe déjà. » + CTA désactivé si doublon (insensible à la casse, toutes catégories)
- AC-4 : Anneau `text-primary` 2px sur pastille couleur sélectionnée
- AC-5 : Anneau `accent` 2px sur icône sélectionnée
- AC-6 : `CategoryDao.insertCategory()` appelé avec `Uuid().v4()`, `isPredefined: false` ; bottom sheet fermé ; `categoryListProvider` se met à jour automatiquement via `watchAll()`
- 6 couleurs custom ajoutées dans `CategoryUtils.pastilleColors()` ; 16 icônes dans `iconData()`
- `isDuplicate` exportée comme fonction pure — même pattern que `sortCategories`

### File List

#### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/5-2-creation-categorie-perso.md`
- `lib/features/categories/widgets/category_form_sheet.dart`
- `test/features/categories/category_form_sheet_test.dart`

#### Fichiers modifiés
- `lib/shared/utils/category_utils.dart` (6 couleurs custom + 16 icônes picker)
- `lib/shared/data/database/daos/category_dao.dart` (`insertCategory()`)
- `lib/features/categories/screens/category_management_screen.dart` (FAB wired)

## Change Log

| Date | Change |
|------|--------|
| 2026-07-05 | Story créée et implémentée — 135/135 tests, 0 issues analyze — statut review |

## Status

review
