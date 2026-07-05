---
baseline_commit: NO_VCS
story_key: 3-3-revue-correction-lignes-recu
status: in-progress
---

# Story 3.3 — Revue et correction des Lignes du Reçu

## Story

**En tant qu'** utilisateur,
**Je veux** vérifier les lignes extraites de mon reçu, corriger les montants et catégories incorrects, et supprimer les doublons,
**Afin que** seules les données exactes soient imputées à mon solde.

## Acceptance Criteria

- **AC-1:** L'écran Revue Reçu s'affiche → un en-tête sticky indique le total dynamique (montant + nombre d'articles) en Title/SemiBold (UX-DR17), et chaque ligne présente : libellé OCR (Body, éditable), montant éditable inline (Body), badge Catégorie (dropdown).

- **AC-2:** L'utilisateur modifie le montant d'une ligne inline → le total de l'en-tête sticky se recalcule immédiatement.

- **AC-3:** L'utilisateur appuie sur le badge Catégorie d'une ligne → le Sélecteur Catégorie (bottom sheet) s'ouvre ; après sélection, le badge est mis à jour et le bottom sheet se ferme.

- **AC-4:** Une ligne est en état d'avertissement (montant nul, libellé vide, ou catégorie vide) → fond `#3A2A00`, bordure gauche 3px `warning`, icône ⚠ ambre (UX-DR11).

- **AC-5:** L'utilisateur effectue un swipe-to-delete sur une ligne → la ligne est supprimée et le total recalculé ; aucune confirmation requise.

- **AC-6:** Le lecteur d'écran est actif → l'action de suppression est accessible via le menu ⋯ de chaque ligne et exposée comme action d'accessibilité personnalisée VoiceOver/TalkBack (UX-DR11).

- **AC-7:** L'utilisateur appuie sur « Ajouter une ligne » → une nouvelle ligne vide est insérée en bas avec focus automatique sur le champ libellé.

- **AC-8:** Toutes les lignes sont supprimées → un état vide local s'affiche ; le CTA « Valider le reçu » reste présent mais désactivé.

## Tasks / Subtasks

### Task 1: Modifier `ReceiptLine` — ajouter `id` et `isWarning`
- [x] 1.1 Ajouter champ `id` (UUID v4, généré à la construction si absent) et getter `isWarning` (`amountCents <= 0 || label.trim().isEmpty || category.trim().isEmpty`); `copyWith` préserve `id`

### Task 2: Créer `ReceiptLineItem` dans `shared/widgets/`
- [x] 2.1 `ReceiptLineItem` (`StatefulWidget`) — contrôleurs label + montant, pastille catégorie tappable, état warning, swipe Dismissible, menu ⋯, action sémantique VoiceOver/TalkBack

### Task 3: Réécrire `ScanReviewScreen` en `ConsumerStatefulWidget`
- [x] 3.1 Convertir en `ConsumerStatefulWidget` avec état `List<ReceiptLine> _lines`, `_pendingFocusLineId`, `_scrollController`
- [x] 3.2 En-tête sticky (`SliverPersistentHeader`) avec total dynamique (montant + article count) + `CustomScrollView` + `SliverList` de `ReceiptLineItem`
- [x] 3.3 `_showCategorySelector(int index)` — `showModalBottomSheet(CategorySelectorSheet)` → `_updateCategory`
- [x] 3.4 "Ajouter une ligne" button + état vide + bouton "Valider le reçu" (activé si non-vide, `onPressed: null` Story 3.4)

### Task 4: Tests — `ReceiptLine`
- [x] 4.1 `test/shared/domain/receipt_line_test.dart` — `isWarning`, `copyWith` (préserve `id`), `fromJson`, unicité `id`

## Dev Notes

### Architecture
- `ReceiptLine` → `lib/shared/domain/receipt_line.dart` — ajout `id` UUID v4 (uuid déjà dans pubspec) + `isWarning`
- `ReceiptLineItem` → `lib/shared/widgets/receipt_line_item.dart` (shared car réutilisé Story 3.4 dans ReceiptGroupTile)
- `ScanReviewScreen` → `lib/features/scan/screens/scan_review_screen.dart` (rewritten as ConsumerStatefulWidget)
- `ScanLoadingScreen` → navigue toujours vers `ScanReviewScreen(lines: lines)` — paramètre initial inchangé

### State management
- `ScanReviewScreen` maintient `List<ReceiptLine> _lines` (copie modifiable des lignes initiales)
- Mutations via `setState` : `_updateLabel`, `_updateAmount`, `_updateCategory`, `_deleteLine`, `_addLine`
- Rien n'est persisté tant que l'utilisateur n'a pas validé (Story 3.4)
- `_totalCents` = computed getter (somme des `amountCents`)

### ReceiptLineItem
- `StatefulWidget` avec `ValueKey(line.id)` sur le site d'appel (parent)
- `TextEditingController _labelCtrl` (text = `line.label`) + `FocusNode _labelFocus`
- `TextEditingController _amountCtrl` (text = `(line.amountCents ~/ 100).toString()` ou '' si 0)
- Listeners propagent vers parent via callbacks (`onLabelChanged`, `onAmountChanged`)
- `didUpdateWidget` : ne PAS réinitialiser les contrôleurs (data flow : controller → parent, pas l'inverse)
- Warning : `widget.line.isWarning` lu directement depuis la prop (toujours à jour)
- Dismissible direction `endToStart` (swipe gauche)
- `PopupMenuButton` ⋯ toujours visible
- `Semantics.customSemanticsActions` : `CustomSemanticsAction(label: 'Supprimer')` → `onDelete`

### Category selector depuis ScanReviewScreen
- `_showCategorySelector(int i)` : lit `ref.read(categoryListProvider).valueOrNull` → trouve ID par nom → `showModalBottomSheet(CategorySelectorSheet(selectedId: id))` → `_updateCategory(i, cat.name)`
- Feature scan importe `shared/widgets/category_selector_sheet.dart` ✓

### Sticky header
- `SliverPersistentHeader(pinned: true, delegate: _TotalHeaderDelegate(totalCents, lineCount))`
- `minExtent == maxExtent = 56.0` (non-collapsible)
- `shouldRebuild` : si `totalCents` ou `lineCount` change

### Tests
- Pas de tests widget (Phase MVP)
- Tests unitaires `ReceiptLine` : `fromJson`, `isWarning`, `copyWith`, unicité `id`
- Tests existants : 45 (inchangés)

## Dev Agent Record

### Implementation Plan
Ordre : Task 1 (ReceiptLine) → Task 2 (ReceiptLineItem) → Task 3 (ScanReviewScreen) → Task 4 (Tests)

### Debug Log

| # | Issue | Fix |
|---|-------|-----|

### Completion Notes

- 62/62 tests passent (17 nouveaux — ReceiptLine), `flutter analyze` : 0 issues
- AC-1 : en-tête sticky `_TotalHeaderDelegate` (Title/SemiBold, 20px) + `SliverPersistentHeader(pinned: true)` + `ReceiptLineItem` avec champs label et montant éditables inline
- AC-2 : listeners sur contrôleurs montant → `_updateAmount(i, cents)` → `setState` → `_totalCents` recalculé → en-tête mis à jour immédiatement
- AC-3 : tap pastille catégorie → `_showCategorySelector(i)` → `showModalBottomSheet(CategorySelectorSheet)` → `_updateCategory(i, cat.name)`
- AC-4 : `ReceiptLine.isWarning` (centimes ≤ 0 OU label vide OU catégorie vide) → fond `#3A2A00`, bordure gauche 3px `warning`, icône ⚠ ambre
- AC-5 : `Dismissible(direction: endToStart, onDismissed: _deleteLine)` → suppression + recalcul total
- AC-6 : `Semantics.customSemanticsActions` → `CustomSemanticsAction(label: 'Supprimer')` + `PopupMenuButton ⋯` toujours visible
- AC-7 : `_addLine()` → nouvelle `ReceiptLine(label:'', amountCents:0, category:'Autre')` + `autoFocusLabel: true` → `FocusScope.requestFocus` post-frame
- AC-8 : `SliverFillRemaining(_EmptyListState)` si `_lines.isEmpty` ; `_ValidateButton(enabled: lineCount > 0, onPressed: null)` toujours présent
- `ReceiptLine.id` ajouté (UUID v4) — `ValueKey(line.id)` garantit conservation des contrôleurs lors des rebuilds

### File List

#### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/3-3-revue-correction-lignes-recu.md`
- `lib/shared/widgets/receipt_line_item.dart`
- `test/shared/domain/receipt_line_test.dart`

#### Fichiers modifiés
- `lib/shared/domain/receipt_line.dart`
- `lib/features/scan/screens/scan_review_screen.dart`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-05 | Story créée et implémentée — 62/62 tests, 0 issues analyze — statut review |

## Status

review
