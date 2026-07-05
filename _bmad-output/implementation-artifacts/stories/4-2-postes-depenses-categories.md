---
baseline_commit: b7984f1e7bc874ed6b85d5f3cd28f01b729fed92
story_key: 4-2-postes-depenses-categories
status: in-progress
---

# Story 4.2 — Postes de dépense par catégorie et comparaison mois/mois

## Story

**En tant qu'** utilisateur,
**Je veux** voir le total dépensé par catégorie sur ma période et le comparer au mois précédent,
**Afin d'** identifier où va mon argent et repérer les dérives.

## Acceptance Criteria

- **AC-1:** La période sélectionnée contient des dépenses → la liste des postes s'affiche triée par montant décroissant ; chaque poste présente : pastille catégorie, nom, montant Body préfixé `−` ; la somme de tous les postes = total des dépenses de la période.

- **AC-2:** Une catégorie n'a aucune transaction sur la période sélectionnée → elle n'apparaît pas dans la liste.

- **AC-3:** Chaque poste affiché indique la variation mois/mois vs le même poste du mois calendaire précédant `period.start` : montant `+`/`−` + pourcentage + indicateur directionnel (↑ hausse · ↓ baisse).

- **AC-4:** Le mois précédent est vide pour un poste (pas de dépense dans cette catégorie ce mois-là) → la cellule variation affiche « — » sans indicateur directionnel.

- **AC-5:** La période change via le Sélecteur de Période → la liste et toutes les variations se mettent à jour immédiatement (< 100 ms, sans rechargement visible).

- **AC-6:** La période sélectionnée ne contient aucune dépense → l'état vide « Aucune dépense sur cette période. » s'affiche à la place de la liste.

## Tasks / Subtasks

### Task 1: `CategorySpendingEntry` + `categorySpendingProvider`
- [x] 1.1 Créer `lib/shared/providers/category_spending_provider.dart` — définir la classe `CategorySpendingEntry { final String categoryId; final String categoryName; final String icon; final String colorToken; final int currentAmountCents; }` et le `categorySpendingProvider` de type `Provider<List<CategorySpendingEntry>>` dérivé de `transactionListProvider`, `selectedPeriodProvider` et `categoryListProvider`. Filtrer `type == 'depense'`, grouper par `categoryId`, joindre avec `categoryListProvider` pour le nom/icon/colorToken, trier par `currentAmountCents` décroissant. Catégories sans dépense sur la période exclues (AC-2). Fonctions pures `computeSpendingTotals` et `buildCategorySpendingEntries` exportées pour testabilité.

### Task 2: `monthlyComparisonProvider`
- [x] 2.1 Créer `lib/shared/providers/monthly_comparison_provider.dart` — `monthlyComparisonProvider` de type `Provider<Map<String, int>>` mappant `categoryId → amountCents` pour le mois calendaire précédant `selectedPeriodProvider.start`. Utiliser `previousMonth(period)` de `selected_period_provider.dart` + `computeSpendingTotals` de `category_spending_provider.dart`. Map vide si aucune dépense ce mois.

### Task 3: Tests — providers
- [x] 3.1 Créer `test/shared/providers/category_spending_provider_test.dart` — 14 tests : `computeSpendingTotals()` (8) et `buildCategorySpendingEntries()` (6). Pattern pur (fonctions testables), cohérent avec le pattern du projet (balance_provider_test).
- [x] 3.2 Créer `test/shared/providers/monthly_comparison_provider_test.dart` — 6 tests : mois précédent via `computeSpendingTotals()` avec `previousMonth()`. Transition Jan→Déc, revenus exclus, cumul multi-transactions, plage custom.

### Task 4: `CategorySpendingTile` widget
- [x] 4.1 Créer `lib/features/dashboard/widgets/category_spending_tile.dart` — `ConsumerWidget` : pastille 40×40 (`CategoryUtils.pastilleColors`), nom catégorie (Body/600), montant `−X FCFA` (danger, tabular figures), `_VariationLine` (lit `monthlyComparisonProvider`) : ↑ danger / ↓ success / « — » si absent (AC-3, AC-4). Séparateur milliers espace fine insécable U+202F. Tokens uniquement.

### Task 5: Mise à jour `DashboardScreen`
- [x] 5.1 Modifier `lib/features/dashboard/screens/dashboard_screen.dart` — remplacer placeholder `_ComingSoon` FR-18 par `categorySpendingProvider` → `...entries.map((e) => CategorySpendingTile(entry: e))`. État vide si `entries.isEmpty` (AC-6). Section FR-19 reste `_ComingSoon`. Simplification : suppression du filtrage manuel de transactions (géré par le provider).

## Dev Notes

### Architecture
- `categorySpendingProvider` et `monthlyComparisonProvider` dans `shared/providers/` — consommés par `CategorySpendingTile` et `DashboardScreen`
- `CategorySpendingTile` dans `features/dashboard/widgets/` — usage exclusif dashboard
- Pas de classe dans `shared/domain/` pour `CategorySpendingEntry` (c'est un DTO de présentation, pas un domaine métier)

### `categorySpendingProvider` — logique
```dart
// Pseudo-code
final period = ref.watch(selectedPeriodProvider);
final txAsync = ref.watch(transactionListProvider);
final catAsync = ref.watch(categoryListProvider);

final allTx = txAsync.asData?.value ?? [];
final cats = catAsync.asData?.value ?? [];

final startMs = period.start.millisecondsSinceEpoch;
final endMs = DateTime(period.end.year, period.end.month, period.end.day, 23, 59, 59).millisecondsSinceEpoch;

final catById = {for (final c in cats) c.id: c};

// Filtrer dépenses de la période
final depenses = allTx.where((t) => t.type == 'depense' && t.date >= startMs && t.date <= endMs);

// Grouper par categoryId
final Map<String, int> totals = {};
for (final t in depenses) {
  totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amountCents;
}

// Joindre avec categories, filtrer inconnues, trier
return totals.entries
    .where((e) => catById.containsKey(e.key))
    .map((e) {
      final cat = catById[e.key]!;
      return CategorySpendingEntry(
        categoryId: e.key,
        categoryName: cat.name,
        icon: cat.icon,
        colorToken: cat.colorToken,
        currentAmountCents: e.value,
      );
    })
    .toList()
  ..sort((a, b) => b.currentAmountCents.compareTo(a.currentAmountCents));
```

### `monthlyComparisonProvider` — logique
- "Mois précédent" = `previousMonth(period)` de `selected_period_provider.dart` — toujours mois calendaire, même si période custom
- Retourne `Map<String, int>` categoryId → amountCents (0-based : si absente, la map ne contient pas la clé)
- `endMs` du mois précédent calculé de la même façon (23:59:59 du dernier jour)

### `CategorySpendingTile` — layout
```
[Pastille 40px] [Nom catégorie]    [−245 800 FCFA]
               [↑ +12 300 · +5%]
```
- Pastille : `Container(40×40, radius: 20, bg pastille, icon 20px fg pastille)`
- Montant : `−X FCFA` en `danger` (#FF6B6B), Urbanist Body 15px/600, tabular figures
- Variation : si `prevAmountCents == null` → « — » textSecondary Caption
  - hausse (current > prev) → `↑ +X FCFA · +Y%` en `danger` (plus de dépenses = mauvais)
  - baisse (current < prev) → `↓ −X FCFA · −Y%` en `success` (moins de dépenses = bon)
  - égal → `= 0 FCFA · 0%` en textSecondary
- Espace fine insécable ` ` (U+202F) comme séparateur de milliers
- Padding : 12px vertical, 16px horizontal

### Montants — formatage
- `_fmt(int cents)` → ex. `245 800` (avec espace fine insécable, pas de FCFA dans le helper)
- Affichage final : `−${_fmt(cents)} FCFA` ou `+${_fmt(cents)} FCFA`
- Espace fine insécable : `' '` (Unicode non-breaking thin space)

### Tests
- Utiliser `ProviderContainer` avec `overrideWith` pour fournir des données de test sans Drift
- Les providers `categorySpendingProvider` et `monthlyComparisonProvider` sont des `Provider` (non-async) — `ProviderContainer` fournit la valeur synchroniquement
- Pour `transactionListProvider` (StreamProvider) : override avec `StreamProvider.overrideWith(() => Stream.value([...]))`
- Pour `categoryListProvider` : idem
- Pour `selectedPeriodProvider` : override avec `NotifierProvider.overrideWith(() => SelectedPeriodNotifier()..state = ...)` ou setter direct

### Riverpod 3.3.2 — override patterns
```dart
// Override d'un StreamProvider pour les tests :
transactionListProvider.overrideWith((ref) => Stream.value(fakeTxList))

// Override du selectedPeriodProvider :
selectedPeriodProvider.overrideWith(() {
  final n = SelectedPeriodNotifier();
  return n; // state sera initialisé via build() (mois courant)
})
// ou directement après container.read :
container.read(selectedPeriodProvider.notifier).selectRange(testRange);
```

## Dev Agent Record

### Implementation Plan
Ordre : Task 1 (categorySpendingProvider) → Task 2 (monthlyComparisonProvider) → Task 3 (tests RED→GREEN) → Task 4 (CategorySpendingTile) → Task 5 (DashboardScreen update) → validation finale

### Debug Log

| # | Issue | Fix |
|---|-------|-----|
| 1 | `await container.read(transactionListProvider.future)` timeout 30s — `Stream.value()` ne se complète jamais en Riverpod 3.x dans les tests unitaires | Adopté le pattern du projet (`balance_provider_test.dart`) : logique pure extraite en `computeSpendingTotals()` + `buildCategorySpendingEntries()`, tests synchrones sur fonctions pures |

### Completion Notes

- 110/110 tests passent (20 nouveaux), `flutter analyze` : 0 issues
- AC-1 : `categorySpendingProvider` → `buildCategorySpendingEntries()` joint avec cats + tri décroissant; `DashboardScreen` affiche `CategorySpendingTile` pour chaque poste
- AC-2 : catégories sans dépense absentes — `computeSpendingTotals()` ne les inclut pas; `buildCategorySpendingEntries()` filtre les orphelines
- AC-3 : `_VariationLine` dans `CategorySpendingTile` calcule diff + pct depuis `monthlyComparisonProvider`; ↑ danger (hausse dépense = mauvais) · ↓ success (baisse = bon)
- AC-4 : `prevCents == null` (clé absente de `monthlyComparisonProvider`) → affiche « — » sans indicateur
- AC-5 : Providers dérivés (`Provider<T>`) — rebuild automatique quand `selectedPeriodProvider` change (< 100ms)
- AC-6 : `entries.isEmpty` → `_EmptySection('Aucune dépense sur cette période.')`
- Note tech : `computeSpendingTotals` + `buildCategorySpendingEntries` exportés comme fonctions pures → pattern testable sans Riverpod, cohérent avec `balance_provider_test.dart`

### File List

#### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/4-2-postes-depenses-categories.md`
- `lib/shared/providers/category_spending_provider.dart`
- `lib/shared/providers/monthly_comparison_provider.dart`
- `lib/features/dashboard/widgets/category_spending_tile.dart`
- `test/shared/providers/category_spending_provider_test.dart`
- `test/shared/providers/monthly_comparison_provider_test.dart`

#### Fichiers modifiés
- `lib/features/dashboard/screens/dashboard_screen.dart`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-05 | Story créée et implémentée — 110/110 tests, 0 issues analyze — statut review |

## Status

review
