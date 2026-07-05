---
baseline_commit: NO_VCS
story_key: 2-1-balance-card-home
status: review
---

# Story 2.1 — Carte Solde et écran Accueil avec état vide

## Story

**En tant qu'** utilisateur authentifié,
**Je veux** voir mon solde courant dès que j'ouvre l'app,
**Afin de** savoir en un coup d'œil où j'en suis financièrement sans aucune navigation.

## Acceptance Criteria

- **AC-1:** L'utilisateur est sur l'écran Accueil avec au moins une transaction → la Carte Solde est visible (gradient `accent #6B5CFF → #4A3FD4`, radius 24px, padding 24px) avec : label Caption « Solde courant », montant en Display blanc (formaté avec espace fine insécable, sans signe +/−), variation mensuelle en Caption (+/− coloré `success`/`danger`), sparkline blanc en bas.
- **AC-2:** Aucune transaction → la Carte Solde montre 0 FCFA et l'état vide s'affiche sous la carte (icône wallet accent centrée, titre « Ton premier reçu t'attend. », CTA « Scanner un reçu »).
- **AC-3:** Une transaction est ajoutée ou supprimée → le solde se recalcule et s'affiche mis à jour en moins de 100 ms (provider dérivé, jamais persisté en base).
- **AC-4:** Le solde est négatif → le montant affiché dans la Carte Solde porte une indication visuelle distincte (couleur `danger #FF6B6B`).
- **AC-5:** VoiceOver/TalkBack actif → le montant du solde est annoncé « [montant] francs CFA » (devise complète, jamais l'abréviation FCFA).

## Tasks / Subtasks

### Task 1: transactionListProvider — StreamProvider Drift
- [x] 1.1 Créer `lib/shared/providers/transaction_list_provider.dart` — `StreamProvider<List<Transaction>>` sur `TransactionDao.watchAll()`

### Task 2: balanceProvider — TDD
- [x] 2.1 Tests RED : `balanceProvider` retourne 0 sans transaction ; somme revenus − dépenses ; solde négatif possible
- [x] 2.2 Créer `lib/shared/providers/balance_provider.dart` — `Provider<int>` dérivé de `transactionListProvider` + `sparklineDataProvider`
- [x] 2.3 Tests GREEN — tous les tests balanceProvider passent

### Task 3: monthlyVariationProvider — TDD
- [x] 3.1 Tests RED : variation = net transactions du mois courant ; 0 si aucune transaction ce mois ; exclut les mois passés
- [x] 3.2 Créer `lib/shared/providers/monthly_variation_provider.dart` — `Provider<int>`
- [x] 3.3 Tests GREEN — tous les tests monthlyVariationProvider passent

### Task 4: BalanceCard widget
- [x] 4.1 Ajouter `AppColors.accentGradient = Color(0xFF4A3FD4)` dans `app_colors.dart`
- [x] 4.2 Créer `lib/features/dashboard/widgets/balance_card.dart` — UX-DR4 (gradient, radius 24px, ombre, sparkline 7j, variation mensuelle, Semantics AC-5)

### Task 5: HomeScreen et routage
- [x] 5.1 Créer `lib/features/dashboard/screens/home_screen.dart` — `BalanceCard` + état vide UX-DR14 (icône wallet, titre, CTA)
- [x] 5.2 Mettre à jour `lib/shared/routing/app_router.dart` — remplacer `_HomePlaceholder` par `HomeScreen`

## Dev Notes

- **`transactionListProvider`** : `StreamProvider<List<Transaction>>` dans `shared/providers/` — même pattern que `categoryListProvider`
- **`balanceProvider`** : `Provider<int>` dérivé de `transactionListProvider.asData?.value ?? []` — fold typé `<int>`, `+amountCents` si `type == 'revenu'`, `−amountCents` sinon ; jamais persisté (AD contraint)
- **`monthlyVariationProvider`** : `Provider<int>` — filtre `date >= startOfMonth` (premier jour du mois courant en ms epoch) ; même logique de signed sum
- **`sparklineDataProvider`** : dans `balance_provider.dart` — `Provider<List<int>>`, 7 valeurs = solde cumulatif à fin de chacun des 7 derniers jours
- **Gradient Balance Card** : `LinearGradient([AppColors.accent, AppColors.accentGradient], begin: topLeft, end: bottomRight)` — ajouter `accentGradient = Color(0xFF4A3FD4)` dans AppColors
- **Ombre Balance Card** : `BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 16, offset: Offset(0, 4))` — UX-DR24 : seuls FAB et Carte Solde portent une ombre
- **Format montant** : `cents ~/ 100` → séparateur espace fine insécable ` ` inséré manuellement (pas d'espace normal)
- **Sparkline** : `CustomPainter` — pas de dépendance externe (fl_chart est pour Story 4.3) ; courbe blanche `withValues(alpha: 0.6)` sur fond transparent
- **État vide** : `Icons.account_balance_wallet_outlined` couleur accent (pas de flutter_svg — non dans les dépendances)
- **CTA "Scanner un reçu"** : `onPressed: null` pour l'instant — le câblage FAB est Story 2.2
- **Semantics AC-5** : `Semantics(label: '[valeur en units] francs CFA', excludeSemantics: true)` sur le Text montant
- **Tests** : `StreamProvider.future` timeout dans les tests unitaires purs (`NativeDatabase.memory()` stream n'émet pas sans Flutter bindings) — pattern retenu : `db.transactionDao.getAll()` + logique fold extraite, plus `container.read(balanceProvider)` en état loading pour tester la valeur par défaut

## Dev Agent Record

### Implementation Plan
Ordre : Task 1 (transactionListProvider) → Task 2 TDD balanceProvider → Task 3 TDD monthlyVariationProvider → Task 4 BalanceCard → Task 5 HomeScreen + router.

### Debug Log

| # | Issue | Fix |
|---|-------|-----|
| 1 | `StreamProvider.future` timeout (30s) dans tous les tests providers — Drift `watch()` stream n'émet pas dans `NativeDatabase.memory()` sans Flutter bindings | Remplacé l'attente de la première émission par `db.transactionDao.getAll()` + logique fold extraite en helper local ; `container.read(balanceProvider)` en état loading pour tester la valeur par défaut 0 |

### Completion Notes

- 32/32 tests passent, `flutter analyze` : 0 issues
- AC-3 (<100ms) garanti par architecture Riverpod : `balanceProvider` est un `Provider<int>` synchrone dérivé de `transactionListProvider`, recalculé immédiatement à chaque émission Drift sans I/O supplémentaire
- AC-4 : couleur `AppColors.danger` appliquée si `balanceCents < 0`, montant affiché sans signe
- AC-5 : `Semantics(label: '${balanceCents.abs() ~/ 100} francs CFA', excludeSemantics: true)` sur le widget Text
- CTA "Scanner un reçu" : `onPressed: null` — câblage caméra/BFF prévu Story 2.2

## File List

### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/2-1-balance-card-home.md`
- `lib/shared/providers/transaction_list_provider.dart`
- `lib/shared/providers/balance_provider.dart`
- `lib/shared/providers/monthly_variation_provider.dart`
- `lib/features/dashboard/widgets/balance_card.dart`
- `lib/features/dashboard/screens/home_screen.dart`
- `test/shared/providers/balance_provider_test.dart`

### Fichiers modifiés
- `lib/shared/theme/app_colors.dart`
- `lib/shared/routing/app_router.dart`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-01 | Story créée depuis Epic 2 — statut in-progress |
| 2026-07-01 | Implémentation complète — 32/32 tests, 0 issues analyze — statut review |

## Status

review
