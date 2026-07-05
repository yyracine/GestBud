---
baseline_commit: 5412b5a33461722a3dfea65c0154db6724cff74b
story_key: 4-3-graphique-evolution-solde
status: in-progress
---

# Story 4.3 — Graphique d'évolution du Solde

## Story

**En tant qu'** utilisateur,
**Je veux** voir l'évolution de mon solde sous forme de graphique linéaire pour la période sélectionnée,
**Afin de** comprendre comment mon solde a évolué dans le temps et détecter les tendances.

## Acceptance Criteria

- **AC-1:** Graphique linéaire affichant le solde cumulatif en fin de journée (23:59) pour chaque jour de la période sélectionnée.

- **AC-2:** Un jour sans transaction affiche le même solde que le jour précédent (ligne plate — carry-forward).

- **AC-3:** Solde négatif → la courbe passe sous l'axe zéro ; l'axe zéro est visible comme repère visuel.

- **AC-4:** Aucune transaction sur la période → ligne plate (pas d'état vide). Si aucune transaction du tout, ligne plate à 0 FCFA.

- **AC-5:** La période change → le graphique se recalcule immédiatement (< 100 ms, sans rechargement visible).

- **AC-6:** Accessibilité — hauteur du graphique ≥ 44px (Android 5") ; description textuelle TalkBack (ex. « Solde en hausse de X FCFA sur la période »).

## Tasks / Subtasks

### Task 1: `DailyBalancePoint` + `dailyBalanceProvider`
- [x] 1.1 Créer `lib/shared/providers/daily_balance_provider.dart` — classe `DailyBalancePoint { final DateTime date; final int balanceCents; }` + `Provider<List<DailyBalancePoint>>` dérivé de `transactionListProvider` et `selectedPeriodProvider`. Fonction pure `computeDailyBalances(transactions, period)` : solde initial (toutes tx avant `period.start`) + carry-forward jour par jour. Un point par jour de la période.

### Task 2: Tests — `daily_balance_provider_test.dart`
- [x] 2.1 Créer `test/shared/providers/daily_balance_provider_test.dart` — tester `computeDailyBalances()` : liste vide → tous à 0, tx pré-période → solde initial, tx dans période → solde mis à jour, jours sans tx → carry-forward, solde négatif, revenus ajoutent / dépenses soustraient, période 1 jour.

### Task 3: `BalanceChart` widget
- [x] 3.1 Créer `lib/features/dashboard/widgets/balance_chart.dart` — `ConsumerWidget` lisant `dailyBalanceProvider`. `fl_chart` `LineChart` : axe zéro visible (AC-3), hauteur ≥ 180px (AC-6), `Semantics` avec description textuelle de tendance (AC-6). Couleur ligne : `AppColors.accent`. Labels X : premier/dernier jour. Labels Y : montants en FCFA abrégés.

### Task 4: Mise à jour `DashboardScreen`
- [x] 4.1 Modifier `lib/features/dashboard/screens/dashboard_screen.dart` — remplacer `_ComingSoon('Graphique — Story 4.3')` par `const BalanceChart()` dans la section FR-19.

## Dev Notes

### Architecture
- `dailyBalanceProvider` dans `shared/providers/` — consommé uniquement par `BalanceChart`
- `BalanceChart` dans `features/dashboard/widgets/` — usage exclusif dashboard
- `computeDailyBalances` exportée comme fonction pure pour testabilité (même pattern que Story 4.2)

### `computeDailyBalances` — logique
```
1. Calculer solde initial : sum(allTx avant period.start) — revenus + · dépenses −
2. Pour chaque jour i de 0 à duration.inDays :
   day = DateTime(period.start.year, period.start.month, period.start.day + i)
   dayStartMs = day.millisecondsSinceEpoch  (minuit)
   dayEndMs   = DateTime(day.year, day.month, day.day, 23, 59, 59).ms
   Pour chaque tx dans [dayStartMs, dayEndMs] : running += revenu/−dépense
   points.add(DailyBalancePoint(date: day, balanceCents: running))
3. Retourner points (toujours non vide si période ≥ 1 jour)
```

### `BalanceChart` — design fl_chart
- `LineChartBarData.spots` : `FlSpot(i.toDouble(), point.balanceCents / 100)`  (Y en FCFA entier)
- `showingTooltipIndicators` ou `LineTouchData` pour tooltip date + montant
- Zero line : `ExtraLinesData(horizontalLines: [HorizontalLine(y: 0, color: AppColors.border)])`
- `gridData`: `FlGridData(show: false)` (pas de grille)
- `borderData`: `FlBorderData(show: false)`
- `titlesData`: axe X — 2-3 labels max (premier, milieu, dernier) ; axe Y — 3 labels (min, 0, max)
- `minY` / `maxY` : calculé depuis les points avec padding 10%
- Hauteur widget : 180px (≥ 44px AC-6)
- `Semantics(label: _trendLabel(points), child: SizedBox(height: 180, child: LineChart(...)))`

### Tendance TalkBack
- hausse : `'Solde en hausse de X FCFA sur la période'`  (last − first > 0)
- baisse : `'Solde en baisse de X FCFA sur la période'`
- stable : `'Solde stable sur la période'`

### Tests — pattern
Même pattern que Story 4.2 : fonctions pures uniquement, tests synchrones.

## Dev Agent Record

### Implementation Plan
Ordre : Task 1 → Task 2 (tests RED→GREEN) → Task 3 → Task 4 → validation finale

### Debug Log

| # | Issue | Fix |
|---|-------|-----|
| 1 | `SideTitleWidget(meta: meta, ...)` → erreur compile : `axisSide` required | fl_chart 0.69.2 utilise encore `axisSide: meta.axisSide` (pas encore migré vers `meta`) |
| 2 | `SideTitles(show: false)` → erreur compile : param inconnu | Paramètre correct : `showTitles: false` |
| 3 | `withOpacity()` deprecated | Remplacé par `withValues(alpha: 0.08)` |

### Completion Notes

- 122/122 tests passent (12 nouveaux), `flutter analyze` : 0 issues
- AC-1 : `computeDailyBalances()` → 1 point par jour, solde cumulatif fin de journée → `LineChart`
- AC-2 : carry-forward implicite dans la boucle — le `running` ne change pas si aucune tx ce jour
- AC-3 : `HorizontalLine(y: 0)` toujours visible ; la courbe descend naturellement sous 0 si solde négatif
- AC-4 : `computeDailyBalances` retourne toujours ≥ 1 point (jamais vide) — ligne plate si aucune tx
- AC-5 : `Provider<T>` dérivé → rebuild automatique quand `selectedPeriodProvider` change
- AC-6 : hauteur `SizedBox(height: 180)` ≥ 44px ; `Semantics(label: _trendLabel(points))`
- Note tech : fl_chart 0.69.2 = `SideTitleWidget(axisSide: meta.axisSide)` ; `SideTitles(showTitles: false)`

### File List

#### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/4-3-graphique-evolution-solde.md`
- `lib/shared/providers/daily_balance_provider.dart`
- `lib/features/dashboard/widgets/balance_chart.dart`
- `test/shared/providers/daily_balance_provider_test.dart`

#### Fichiers modifiés
- `lib/features/dashboard/screens/dashboard_screen.dart`
- `pubspec.yaml` (ajout `fl_chart: ^0.69.0`)

## Change Log

| Date | Change |
|------|--------|
| 2026-07-05 | Story créée et implémentée — 122/122 tests, 0 issues analyze — statut review |

## Status

review
