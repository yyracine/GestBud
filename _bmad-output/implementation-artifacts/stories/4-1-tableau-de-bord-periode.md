---
baseline_commit: 7d860d6f997a9630b3673c83311b2e288db35cb4
story_key: 4-1-tableau-de-bord-periode
status: in-progress
---

# Story 4.1 — Structure du Tableau de bord et Sélecteur de Période

## Story

**En tant qu'** utilisateur,
**Je veux** naviguer entre les mois et sélectionner une période personnalisée,
**Afin d'** analyser mes finances sur n'importe quel intervalle de temps.

## Acceptance Criteria

- **AC-1:** L'utilisateur navigue vers l'onglet « Tableau de bord » → le mois courant est sélectionné par défaut (label format « Juillet 2026 ») avec des flèches ◀▶ visibles en haut de l'écran.

- **AC-2:** L'utilisateur appuie sur ◀ ou ▶ → le mois précédent ou suivant est sélectionné et l'ensemble du contenu du dashboard se met à jour immédiatement (< 100 ms, providers dérivés).

- **AC-3:** L'utilisateur appuie sur le label de la période (ex. « Juillet 2026 ») → un bottom sheet de sélection de période custom s'ouvre avec deux Sélecteurs Date (date début · date fin) et un CTA « Valider ».

- **AC-4:** La date fin saisie est antérieure à la date début → un message inline s'affiche : « La date de fin doit être après la date de début. » et le CTA « Valider » reste désactivé.

- **AC-5:** L'utilisateur valide une période custom → le label affiche la plage (ex. « 01/06 – 15/07 ») et tout le contenu du dashboard se met à jour immédiatement.

- **AC-6:** Le mois sélectionné ne contient aucune transaction → les sections FR-18, FR-19 et FR-20 affichent chacune leur état vide respectif sans crash.

## Tasks / Subtasks

### Task 1: `selectedPeriodProvider`
- [x] 1.1 Créer `lib/shared/providers/selected_period_provider.dart` — `NotifierProvider<SelectedPeriodNotifier, DateTimeRange>` initialisé au mois courant (1er jour → dernier jour du mois). Exporter `monthRange(year, month)`, `isFullMonth(range)`, `previousMonth(range)`, `nextMonth(range)` comme fonctions package-level testables. Note : `StateProvider` absent de Riverpod 3.x — `NotifierProvider` utilisé à la place.

### Task 2: `PeriodSelector` widget
- [x] 2.1 Créer `lib/features/dashboard/widgets/period_selector.dart` — `ConsumerWidget` affichant ◀ [label] ▶ centré horizontalement (hauteur min 48px par bouton pour a11y). Label : mois complet → « Juillet 2026 » (map French mois), plage custom → « 01/06 – 15/07 ». Tap ◀ → `previousMonth`, tap ▶ → `nextMonth`, tap label → ouvre `CustomPeriodSheet`.

### Task 3: `CustomPeriodSheet`
- [x] 3.1 Créer `lib/features/dashboard/widgets/custom_period_sheet.dart` — bottom sheet `StatefulWidget` avec deux champs date tap-to-pick (ouvre `showDatePicker`, dates futures bloquées). Validation inline : `_end.isBefore(_start)` → message « La date de fin doit être après la date de début. ». CTA « Valider » désactivé si invalide. Retourne `DateTimeRange` via `Navigator.pop`.

### Task 4: `DashboardScreen`
- [x] 4.1 Créer `lib/features/dashboard/screens/dashboard_screen.dart` — `ConsumerWidget`, `PeriodSelector` en haut, body avec sections placeholder pour FR-18 (postes dépenses) et FR-19 (graphique solde) affichant chacune leur état vide si aucune transaction sur la période. Aucun crash si 0 transactions.

### Task 5: Brancher la route `/dashboard`
- [x] 5.1 Modifier `lib/shared/routing/app_router.dart` — remplacer `_DashboardPlaceholder` par `DashboardScreen`. Suppression de la classe `_DashboardPlaceholder`.

### Task 6: Tests — `selectedPeriodProvider` et helpers
- [x] 6.1 Créer `test/shared/providers/selected_period_provider_test.dart` — 21 tests : `monthRange` (6), `isFullMonth` (5), `previousMonth` (4), `nextMonth` (3), `selectedPeriodProvider` (3). Transitions Jan/Déc, années bissextiles, plages custom.

## Dev Notes

### Architecture
- `selectedPeriodProvider` dans `shared/providers/` — dérivé par tous les providers du dashboard (4.2, 4.3)
- `PeriodSelector` dans `features/dashboard/widgets/` — pas dans `shared/` (usage exclusif dashboard)
- `CustomPeriodSheet` dans `features/dashboard/widgets/`
- `DashboardScreen` dans `features/dashboard/screens/`

### `DateTimeRange`
- Utiliser `DateTimeRange` du SDK Flutter (material.dart) — pas de classe custom
- Fin du mois : `DateTime(year, month + 1, 0)` — le 0ème jour du mois suivant = dernier jour du mois courant
- `DateTimeRange.start` et `DateTimeRange.end` sont des `DateTime` (temps à minuit par défaut)
- Comparaison de dates : pour inclure toute la journée de `end`, comparer `t.date <= endOfDay` où `endOfDay = end.copyWith(hour: 23, minute: 59, second: 59).millisecondsSinceEpoch`

### Label du mois en français
- Utiliser une map statique (pas d'`intl` DateFormat pour les noms de mois) pour éviter `initializeDateFormatting` :
  ```dart
  const _kFrMonths = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
  ```
- Label mois complet : `'${_kFrMonths[start.month - 1]} ${start.year}'`
- Label plage custom : `'${_fmt(start)} – ${_fmt(end)}'` avec `_fmt` formatant en JJ/MM

### `CustomPeriodSheet`
- UX-DR20 : pas deux bottom sheets empilés → `showDatePicker` est un Dialog, pas un bottom sheet → OK
- Dates futures bloquées : `lastDate: DateTime.now()` dans `showDatePicker`
- Initialiser `_start` et `_end` depuis `current.start` et `current.end`
- CTA désactivé si `_end.isBefore(_start)` ou `_end == _start` (une seule journée est OK : start == end)

Wait — une journée unique (start == end) : `_end.isBefore(_start)` → false → valide ✓

### `DashboardScreen` — état vide AC-6
- Filtrer les transactions par période : `t.date >= startMs && t.date <= endMs`
- `endMs` = `DateTime(end.year, end.month, end.day, 23, 59, 59).millisecondsSinceEpoch`
- Section postes (FR-18) vide : « Aucune dépense sur cette période. »
- Section graphique (FR-19) : ligne plate à 0 (pas d'état vide — valeur 0 est informative, AC Story 4.3)
- Pour Story 4.1 : placeholder visuel pour les sections 4.2/4.3

### Intl
- `intl: ^0.20.3` déjà en dépendance
- Pour les dates au format JJ/MM/AAAA : `'${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}'` — pas besoin d'intl pour ça
- `initializeDateFormatting` pas encore appelé dans `main.dart` — garder cette approche simple

## Dev Agent Record

### Implementation Plan
Ordre : Task 1 (provider + helpers) → Task 6 (tests RED) → Task 1 green → Task 2 (PeriodSelector) → Task 3 (CustomPeriodSheet) → Task 4 (DashboardScreen) → Task 5 (routeur) → tests finaux

### Debug Log

| # | Issue | Fix |
|---|-------|-----|

### Completion Notes

- 90/90 tests passent (21 nouveaux), `flutter analyze` : 0 issues
- AC-1 : `DashboardScreen` avec `PeriodSelector` — mois courant par défaut (« Juillet 2026 »), flèches ◀▶ visibles
- AC-2 : Tap ◀▶ → `previousMonth`/`nextMonth` → `selectedPeriodProvider.notifier.selectRange(range)` → dashboard se reconstruit via `ref.watch`
- AC-3 : Tap label → `CustomPeriodSheet` (bottom sheet StatefulWidget) avec deux date-pickers natifs (`showDatePicker`)
- AC-4 : `_end.isBefore(_start)` → message inline « La date de fin doit être après la date de début. » + CTA désactivé
- AC-5 : Validation → `Navigator.pop(DateTimeRange)` → `PeriodSelector` met à jour le provider → label passe en « JJ/MM – JJ/MM »
- AC-6 : `DashboardScreen` filtre les transactions par période — sections postes (FR-18) et graphique (FR-19) affichent états vides sans crash
- Note tech : `StateProvider` absent de Riverpod 3.3.2 → `NotifierProvider<SelectedPeriodNotifier, DateTimeRange>` utilisé. Map statique French mois (pas d'intl DateFormat) pour éviter `initializeDateFormatting`.

### File List

#### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/4-1-tableau-de-bord-periode.md`
- `lib/shared/providers/selected_period_provider.dart`
- `lib/features/dashboard/widgets/period_selector.dart`
- `lib/features/dashboard/widgets/custom_period_sheet.dart`
- `lib/features/dashboard/screens/dashboard_screen.dart`
- `test/shared/providers/selected_period_provider_test.dart`

#### Fichiers modifiés
- `lib/shared/routing/app_router.dart`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-05 | Story créée et implémentée — 90/90 tests, 0 issues analyze — statut review |

## Status

review
