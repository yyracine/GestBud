---
baseline_commit: NO_VCS
story_key: 2-4-transaction-edit-delete
status: in-progress
---

# Story 2.4 — Modification et suppression d'une Transaction

## Story

**En tant qu'** utilisateur,
**Je veux** corriger une transaction mal saisie ou en supprimer une erronée,
**Afin que** mon solde reste exact.

## Acceptance Criteria

- **AC-1:** L'utilisateur appuie sur une ligne dans l'Historique → l'écran Détail/Modification s'ouvre avec tous les champs pré-remplis (type, montant, catégorie, date, note) et le bouton « Supprimer » visible.

- **AC-2:** L'utilisateur modifie un ou plusieurs champs et appuie sur « Enregistrer » → `TransactionRepository.update()` est appelé, l'écran se ferme, le solde et l'Historique reflètent la correction immédiatement (< 100 ms).

- **AC-3:** L'utilisateur appuie sur « Supprimer » → une confirmation explicite est demandée (dialogue : « Supprimer cette transaction ? » / boutons « Annuler » · « Supprimer »).

- **AC-4:** L'utilisateur confirme la suppression → `TransactionRepository.delete()` est appelé, l'écran se ferme, le solde et l'Historique se mettent à jour immédiatement ; l'action est non réversible.

- **AC-5:** L'utilisateur annule la confirmation de suppression → rien n'est modifié et l'écran Détail/Modification reste ouvert.

- **AC-6:** La transaction modifiée ou supprimée appartient à un reçu (`receipt_id` non nul) → seule cette ligne individuelle est modifiée/supprimée ; les autres lignes du même reçu ne sont pas affectées.

## Tasks / Subtasks

### Task 1: Tests TransactionRepository.update() et delete()
- [x] 1.1 Ajouter tests `update()` : modifie type, montant, catégorie, note, date
- [x] 1.2 Ajouter tests `delete()` : supprime par id, n'affecte pas les autres transactions, fonctionne sur transaction avec receipt_id

### Task 2: TransactionDetailScreen
- [x] 2.1 Créer `lib/features/transactions/screens/transaction_detail_screen.dart` — Scaffold avec AppBar (titre « Modifier la transaction » + icône corbeille), formulaire pré-rempli (type/montant/catégorie/date/note), CTA « Enregistrer » → `repo.update()`, sélecteur catégorie inline (bottom sheet direct, pas de loop), dialogue suppression

### Task 3: Câblage HistoryScreen
- [x] 3.1 Ajouter `onTap` sur `TransactionTile` dans `HistoryScreen` → `Navigator.push` vers `TransactionDetailScreen(transaction: tx, category: categoryMap[tx.categoryId])`

## Dev Notes

### Architecture
- `TransactionDetailScreen` → `lib/features/transactions/screens/` (feature transactions)
- Aucun import cross-feature (AD-2)
- `transactionRepositoryProvider` existant — aucun nouveau provider
- `categoryListProvider` existant — aucun nouveau provider

### Formulaire de modification
- Segmented control Dépense/Revenu initialisé depuis `tx.type`
- Montant pré-rempli : `(tx.amountCents ~/ 100).toString()` (entier FCFA, pas de virgule)
- Catégorie passée depuis `HistoryScreen` via le `categoryMap` existant (évite une lookup asynchrone dans l'écran)
- Date : `DateTime.fromMillisecondsSinceEpoch(tx.date)` → affichée en `dd/MM/yyyy`
- Note : `tx.note ?? ''`

### Catégorie dans TransactionDetailScreen
- TransactionDetailScreen est un FULL SCREEN (pas bottom sheet) → peut ouvrir un bottom sheet catégorie sans violer UX-DR20
- `showModalBottomSheet<Category?>(CategorySelectorSheet)` → retour Category? → `setState`
- PAS de _runFormLoop (pas nécessaire en plein écran)

### Transaction.copyWith non disponible (Drift génère copyWith)
- Pour `update()`: construire un nouveau `Transaction(id: tx.id, type: _type, amountCents: amount*100, currency: tx.currency, categoryId: _category.id, receiptId: tx.receiptId, note: ..., date: ..., createdAt: tx.createdAt)`
- `currency` et `createdAt` préservés depuis la transaction d'origine

### Navigation
- `Navigator.of(context).push(MaterialPageRoute(...))` depuis HistoryScreen (sub-navigation dans l'onglet — pas une "route principale" au sens GoRouter)
- Après update ou delete : `Navigator.of(context).pop()` dans le DetailScreen

### Dialogue suppression
- `showDialog<bool>()` avec `AlertDialog`
- `backgroundColor: AppColors.surface`
- Boutons : TextButton « Annuler » (textSecondary) + TextButton « Supprimer » (danger/bold)
- Pas de titre contextuel sur la ligne — dialogue générique (AC-3)

### Tests
- Tests widget absents (project-context.md Phase MVP)
- Repository tests uniquement (in-memory Drift) — même pattern que `transaction_repository_test.dart`

## Dev Agent Record

### Implementation Plan
Ordre : Task 1 (tests RED-GREEN) → Task 2 (TransactionDetailScreen) → Task 3 (câblage)

### Debug Log

| # | Issue | Fix |
|---|-------|-----|

### Completion Notes

- 45/45 tests passent (7 nouveaux — update ×4 + delete ×3), `flutter analyze` : 0 issues
- AC-1 : `TransactionTile.onTap` dans `HistoryScreen` → `Navigator.push(TransactionDetailScreen)` avec transaction + category pré-résolue depuis `categoryMap`
- AC-2 : `_save()` construit un `Transaction` complet et appelle `repo.update()` → Drift stream réactif → solde/historique mis à jour automatiquement
- AC-3/5 : `showDialog<bool>(AlertDialog)` — « Annuler » retourne `false`, aucune mutation si `confirmed != true`
- AC-4 : `repo.delete(tx.id)` puis `Navigator.pop()` — Drift stream retire la transaction sans action UI
- AC-6 : `delete()` cible uniquement `tx.id` — les autres lignes du même `receipt_id` sont intactes (vérifié par test dédié)
- Catégorie dans l'écran d'édition : `showModalBottomSheet<Category?>(CategorySelectorSheet)` direct (plein écran → pas de stack UX-DR20)

## File List

### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/2-4-transaction-edit-delete.md`
- `lib/features/transactions/screens/transaction_detail_screen.dart`

### Fichiers modifiés
- `test/shared/data/transaction_repository_test.dart`
- `lib/features/transactions/screens/history_screen.dart`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-03 | Story créée et implémentée — 45/45 tests, 0 issues analyze — statut review |

## Status

review
