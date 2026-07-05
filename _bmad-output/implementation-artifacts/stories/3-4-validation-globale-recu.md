---
baseline_commit: fc59b32050bc568a251e0348d1912ede901b30b1
story_key: 3-4-validation-globale-recu
status: in-progress
---

# Story 3.4 — Validation globale du Reçu et regroupement dans l'Historique

## Story

**En tant qu'** utilisateur,
**Je veux** valider mon reçu d'un seul geste pour que toutes ses lignes soient enregistrées dans mon historique et mon solde mis à jour,
**Afin de** ne pas avoir à saisir chaque article manuellement.

## Acceptance Criteria

- **AC-1:** L'utilisateur appuie sur « Valider le reçu » → `TransactionRepository.insertReceiptLines(receiptId, lines)` est appelé : toutes les lignes sont insérées dans un unique `database.transaction()` atomique (soit toutes réussissent, soit aucune — en cas d'erreur, l'état de revue est conservé intact).

- **AC-2:** La validation réussit → l'écran Revue Reçu se ferme, l'app navigue vers l'Accueil (`/home`), le solde se met à jour immédiatement (providers dérivés réactifs), et un SnackBar de confirmation s'affiche : « Reçu enregistré ! »

- **AC-3:** L'utilisateur consulte l'onglet Historique après validation → le reçu apparaît comme une entrée groupée (libellé « Reçu · N articles · total FCFA ») avec un chevron indiquant l'état réduit.

- **AC-4:** L'utilisateur appuie sur l'entrée groupée → les lignes individuelles s'expandent en-dessous (UX-DR19) avec `AnimatedSize` ; un deuxième tap les réduit ; le chevron est animé. Avec Reduce Motion activé (`MediaQuery.disableAnimations`), la durée d'animation est 0ms.

- **AC-5:** VoiceOver/TalkBack actif sur l'entrée groupée → l'état est annoncé à chaque tap : « Reçu, [N] articles, développé » ou « Reçu, [N] articles, réduit ».

- **AC-6:** L'utilisateur appuie sur une ligne individuelle dans l'état développé → il accède à l'écran Détail/Modification (Story 2.4) pour cette ligne uniquement.

## Tasks / Subtasks

### Task 1: `TransactionRepository.insertReceiptLines()`
- [x] 1.1 Ajouter `insertReceiptLines(String receiptId, List<ReceiptLine> lines)` dans `TransactionRepository` — résolution nom → ID catégorie via `categoryDao.getAll()`, fallback "Autre", insertion dans `db.transaction()` atomique, type='depense', `note=line.label`, date=now, `receiptId` partagé

### Task 2: Activer la validation dans `ScanReviewScreen`
- [x] 2.1 Connecter `_ValidateButton.onPressed` → `_validateReceipt()` : génère un UUID v4 `receiptId`, appelle `ref.read(transactionRepositoryProvider).insertReceiptLines(receiptId, _lines)`, navigue vers `/home` via `context.go('/home')`, affiche SnackBar « Reçu enregistré ! »

### Task 3: Créer `ReceiptGroupTile` dans `shared/widgets/`
- [x] 3.1 `ReceiptGroupTile(StatefulWidget)` — props : `transactions`, `categoryMap`, `onLineTap`
- [x] 3.2 Header : pastille reçu (icône receipt, fond surfaceRaised), libellé « Reçu · N articles · total FCFA », chevron animé (`AnimatedRotation`)
- [x] 3.3 Body expand/collapse : `AnimatedSize` (durée 200ms ou 0ms si Reduce Motion), liste de `TransactionTile` pour chaque ligne
- [x] 3.4 `Semantics` sur l'header : `label` = « Reçu, N articles, [développé/réduit] », announce à chaque tap

### Task 4: Mettre à jour `HistoryScreen` pour les groupes
- [x] 4.1 Transformer la liste plate en `_HistoryItem` (sealed class) : `_SingleTx(Transaction)` et `_ReceiptGroup(List<Transaction>)` — grouper par `receiptId` non-null, conserver l'ordre date desc
- [x] 4.2 `ListView` : afficher `ReceiptGroupTile` pour les groupes, `TransactionTile` pour les transactions individuelles

### Task 5: Tests — `insertReceiptLines`
- [x] 5.1 Tester dans `transaction_repository_test.dart` : insertion normale (N lignes → N transactions avec même receiptId), atomicité (0 lignes → 0 insertions), fallback catégorie inconnue → "Autre", unicité des IDs générés, type='depense' systématique, note=label

## Dev Notes

### Architecture
- `insertReceiptLines` réside dans `shared/data/transaction_repository.dart` (AD-10 — seul écrivain)
- `ReceiptGroupTile` → `shared/widgets/receipt_group_tile.dart` (partagé entre features)
- `HistoryScreen` update → `features/transactions/screens/history_screen.dart`
- `ScanReviewScreen` update → `features/scan/screens/scan_review_screen.dart`

### `insertReceiptLines` — détails d'implémentation
```dart
Future<void> insertReceiptLines(String receiptId, List<ReceiptLine> lines) async {
  if (lines.isEmpty) return;
  final now = DateTime.now().millisecondsSinceEpoch;
  final allCats = await _db.categoryDao.getAll();
  final catByName = {for (final c in allCats) c.name: c.id};
  final autreCatId = catByName['Autre']!;
  await _db.transaction(() async {
    for (final line in lines) {
      final categoryId = catByName[line.category] ?? autreCatId;
      await _db.transactionDao.insertEntry(
        TransactionsCompanion.insert(
          id: _uuid.v4(),
          type: 'depense',
          amountCents: line.amountCents,
          categoryId: categoryId,
          date: now,
          createdAt: now,
          note: Value(line.label),
          receiptId: Value(receiptId),
        ),
      );
    }
  });
}
```

### Groupement dans `HistoryScreen`
- Fonction `_buildItems(List<Transaction> txs, Map<String, Category> catMap)` → `List<_HistoryItem>`
- Parcourir la liste triée date desc ; si `tx.receiptId != null`, accumuler dans un groupe tant que le `receiptId` est identique ; sinon, émettre un `_SingleTx`
- Important : les transactions d'un reçu sont consécutives car elles ont le même `createdAt` et sont triées par date desc — mais pour robustesse, regrouper par `receiptId` en une passe (Map accumulation)

### `ReceiptGroupTile` — détails
- Header tappable avec `InkWell`, `Semantics`
- Expand state via `StatefulWidget` local (`bool _expanded = false`)
- `AnimatedSize` sur le body des lignes
- Durée animation : `MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200)`
- Chevron : `AnimatedRotation(turns: _expanded ? 0.5 : 0.0, duration: ...)`
- Total du groupe : somme des `amountCents` de toutes les transactions du groupe
- Format label : `'Reçu · ${txs.length} article${txs.length > 1 ? "s" : ""} · ${_formatCents(total)} FCFA'`

### Navigation depuis `ScanReviewScreen`
- Après validation : `context.go('/home')` (GoRouter) — pas `Navigator.pop`
- Le snack bar : `ScaffoldMessenger.of(context).showSnackBar(...)` AVANT `context.go`

### Tests — atomicité
- Simuler une ligne avec `amountCents` très grand pour déclencher une FK violation ? Non — tester avec une liste normale et vérifier que N transactions sont créées d'un coup
- Test "0 lignes" → `insertReceiptLines(id, [])` → 0 insertions, pas d'erreur
- Test atomicité réelle difficile sans vrai mock d'erreur — vérifier que le receiptId est partagé

## Dev Agent Record

### Implementation Plan
Ordre : Task 1 (repository) → Task 5 (tests repository) → Task 2 (ScanReviewScreen) → Task 3 (ReceiptGroupTile) → Task 4 (HistoryScreen)

### Debug Log

| # | Issue | Fix |
|---|-------|-----|

### Completion Notes

- 69/69 tests passent (7 nouveaux — `insertReceiptLines`), `flutter analyze` : 0 issues
- AC-1 : `TransactionRepository.insertReceiptLines(receiptId, lines)` dans `db.transaction()` atomique — résolution catégorie par nom, fallback "Autre", type='depense', note=label
- AC-2 : `_validateReceipt()` dans `ScanReviewScreen` — génère UUID v4 `receiptId`, appelle `insertReceiptLines`, SnackBar « Reçu enregistré ! », `context.go('/home')` ; `_isValidating` empêche les double-taps
- AC-3 : `ReceiptGroupTile` dans `HistoryScreen` — label « Reçu · N articles · total FCFA », chevron `AnimatedRotation`
- AC-4 : `AnimatedSize` (200ms) pour expand/collapse ; `MediaQuery.disableAnimationsOf(context)` → `Duration.zero` si Reduce Motion
- AC-5 : `Semantics(label: 'Reçu, N articles, développé/réduit')` sur le header du groupe
- AC-6 : `onLineTap(tx)` → `TransactionDetailScreen(transaction: tx)` depuis les lignes individuelles développées
- `_buildItems()` : sealed class `_HistoryItem` (`_SingleTx` / `_ReceiptGroup`), groupement par `receiptId` non-null en préservant l'ordre date desc via Map d'accumulation

### File List

#### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/3-4-validation-globale-recu.md`
- `lib/shared/widgets/receipt_group_tile.dart`

#### Fichiers modifiés
- `lib/shared/data/transaction_repository.dart`
- `lib/features/scan/screens/scan_review_screen.dart`
- `lib/features/transactions/screens/history_screen.dart`
- `test/shared/data/transaction_repository_test.dart`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-05 | Story créée et implémentée — 69/69 tests, 0 issues analyze — statut review |

## Status

review
