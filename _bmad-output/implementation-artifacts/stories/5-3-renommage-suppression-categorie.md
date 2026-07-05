---
baseline_commit: 3b225ab
story_key: 5-3-renommage-suppression-categorie
status: in-progress
---

# Story 5.3 — Renommage et suppression d'une catégorie personnalisée

## Story

**En tant qu'** utilisateur,
**Je veux** pouvoir renommer ou supprimer une catégorie personnalisée,
**Afin que** mes catégories restent pertinentes sans laisser de transactions orphelines.

## Acceptance Criteria

- **AC-1:** Appuyer sur l'icône crayon d'une catégorie personnalisée → le bottom sheet Renommage s'ouvre (même composant `CategoryFormSheet` — UX-DR16) avec le nom, l'icône et la couleur actuels pré-remplis.

- **AC-2:** L'utilisateur modifie le nom/icône/couleur et appuie sur « Enregistrer » → `CategoryDao.updateCategory()` est appelé ; le nom est mis à jour dans la table `categories` et propagé immédiatement via `categoryListProvider`.

- **AC-3:** Nom identique à une **autre** catégorie existante (insensible à la casse ; la catégorie en cours d'édition n'est **pas** comptée comme doublon) → bordure `danger` + message « Cette catégorie existe déjà. » + CTA désactivé.

- **AC-4:** Appuyer sur l'icône corbeille d'une catégorie personnalisée → dialog de confirmation : « Supprimer "[nom]" ? Les transactions associées seront réaffectées à "Autre". » / boutons « Annuler » · « Supprimer ».

- **AC-5:** L'utilisateur confirme la suppression → dans une unique `database.transaction()` atomique : toutes les transactions ayant `categoryId == id` sont réaffectées à la catégorie « Autre », puis la catégorie est supprimée ; `categoryListProvider` se met à jour automatiquement, la catégorie disparaît de tous les sélecteurs.

## Tasks / Subtasks

### Task 1: DAO — update, delete, findByName, reassign
- [x] 1.1 Ajouter `findByName(String name) → Future<Category?>` dans `CategoryDao`
- [x] 1.2 Ajouter `updateCategory(String id, {name, icon, colorToken}) → Future<void>` dans `CategoryDao`
- [x] 1.3 Ajouter `deleteCategory(String id) → Future<int>` dans `CategoryDao`
- [x] 1.4 Ajouter `reassignToCategory(String fromId, String toId) → Future<void>` dans `TransactionDao`

### Task 2: AppDatabase.deleteCustomCategoryWithReassign()
- [x] 2.1 Ajouter `deleteCustomCategoryWithReassign(String categoryId) → Future<void>` dans `AppDatabase` — atomique via `transaction()`

### Task 3: CategoryFormSheet — mode édition
- [x] 3.1 Ajouter `Category? initial` au constructeur de `CategoryFormSheet`
- [x] 3.2 `initState` pré-remplit nom/icône/couleur depuis `widget.initial` si non null
- [x] 3.3 Titre : « Modifier la catégorie » / CTA : « Enregistrer » en mode édition ; label inchangé en mode création
- [x] 3.4 `isDuplicate` — ajouter `{String? excludeId}` optionnel pour exclure la catégorie en cours d'édition (rétrocompatible)
- [x] 3.5 Ajouter `_update()` — appelle `categoryDao.updateCategory()` puis `Navigator.pop()`

### Task 4: Wiring crayon + corbeille dans `_CategoryTile`
- [x] 4.1 Transformer `_CategoryTile` en `ConsumerWidget` pour accéder à `databaseProvider`
- [x] 4.2 Crayon `onPressed` → `showModalBottomSheet(CategoryFormSheet(initial: category))`
- [x] 4.3 Corbeille `onPressed` → `_confirmDelete()` : `showDialog` confirmation → `deleteCustomCategoryWithReassign()`

### Task 5: Tests — isDuplicate avec excludeId
- [x] 5.1 Ajouter 3 tests dans `category_form_sheet_test.dart` — `excludeId` : self-exclusion, seul match exclu, autre match non exclu

## Dev Notes

### Architecture
- `deleteCustomCategoryWithReassign` sur `AppDatabase` — seule couche avec accès multi-DAO sans violer la séparation (pattern déjà utilisé dans `seedPredefinedCategories`)
- FK `transactions.categoryId → categories.id` + `PRAGMA foreign_keys = ON` → l'ordre dans la transaction est obligatoire : reassign d'abord, delete ensuite
- `categoryListProvider` se met à jour automatiquement via `watchAll()` (AD-11)

### isDuplicate — mode édition
```
isDuplicate(name, existing, excludeId: widget.initial?.id)
```
- `excludeId` null (création) : comportement inchangé
- `excludeId` non null (édition) : la catégorie ayant cet id est ignorée dans la comparaison

### CategoryFormSheet — mode édition
- `Category? initial` — null = création, non null = édition
- `initState` : `_nameCtrl = TextEditingController(text: widget.initial?.name ?? '')`
- Titre : `widget.initial != null ? 'Modifier la catégorie' : 'Nouvelle catégorie'`
- CTA label : `widget.initial != null ? 'Enregistrer' : 'Créer'`
- `_save()` dispatche vers `_create()` ou `_update()` selon le mode

### deleteCustomCategoryWithReassign — logique
```dart
transaction(() async {
  final autre = await categoryDao.findByName('Autre'); // UUID déterministe
  await transactionDao.reassignToCategory(categoryId, autre!.id);
  await categoryDao.deleteCategory(categoryId);
});
```

### Dialog de confirmation
- `AlertDialog` avec `backgroundColor: AppColors.surface`, shape radius 16
- Titre : `'Supprimer "${category.name}" ?'` — Body/SemiBold/textPrimary
- Contenu : `'Les transactions associées seront réaffectées à "Autre".'` — Caption/textSecondary
- « Annuler » TextButton textSecondary · « Supprimer » TextButton danger/SemiBold

## Dev Agent Record

### Implementation Plan
Ordre : Task 1 → Task 2 → Task 3 → Task 4 → Task 5 → validation finale

### Debug Log

| # | Issue | Fix |
|---|-------|-----|

### Completion Notes

- 138/138 tests passent (3 nouveaux), `flutter analyze` : 0 issues
- AC-1 : Crayon `onPressed` → `showModalBottomSheet(CategoryFormSheet(initial: category))` — pré-rempli nom/icône/couleur
- AC-2 : `_update()` appelle `categoryDao.updateCategory(id, name, icon, colorToken)` ; `categoryListProvider` se met à jour automatiquement via `watchAll()`
- AC-3 : `isDuplicate` avec `excludeId: widget.initial?.id` — la catégorie en édition n'est pas comptée comme doublon
- AC-4 : `AlertDialog` confirmation — « Supprimer "[nom]" ? » / « Annuler » · « Supprimer »
- AC-5 : `deleteCustomCategoryWithReassign()` dans `AppDatabase.transaction()` — reassign → delete atomique ; FK garantit la cohérence

### File List

#### Fichiers modifiés
- `lib/shared/data/database/daos/category_dao.dart` (findByName + updateCategory + deleteCategory)
- `lib/shared/data/database/daos/transaction_dao.dart` (reassignToCategory)
- `lib/shared/data/database/app_database.dart` (deleteCustomCategoryWithReassign)
- `lib/features/categories/widgets/category_form_sheet.dart` (mode édition + isDuplicate excludeId)
- `lib/features/categories/screens/category_management_screen.dart` (_CategoryTile → ConsumerWidget + wiring)
- `test/features/categories/category_form_sheet_test.dart` (3 tests excludeId)

## Change Log

| Date | Change |
|------|--------|
| 2026-07-05 | Story créée et implémentée — 138/138 tests, 0 issues analyze — statut review |

## Status

review
