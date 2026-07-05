# GestBud — Résumé de session

> **À lire en début de session. À mettre à jour en fin de session.**
> Dernière mise à jour : 2026-07-05 (session 6)

---

## Projet

**GestBud** — Application mobile de gestion budgétaire pour l'Afrique francophone.
- Flutter 3.22 / Dart 3.4 (iOS 15+ · Android 9+)
- Backend BFF : Cloudflare Worker (Wrangler 4.x)
- Pipeline OCR : Mindee v2 → Mistral → Flutter
- Authentification : OTP SMS via Africa's Talking
- Dépôt GitHub : https://github.com/yyracine/GestBud
- Devise : XOF (FCFA), montants stockés en **centimes INTEGER**

---

## Stack technique

| Couche | Choix |
|--------|-------|
| UI | Flutter 3.22, Urbanist (Google Fonts), dark theme uniquement |
| State | flutter_riverpod 3.3.2 — `AsyncNotifierProvider`, `StreamProvider` |
| DB | Drift + drift_flutter 2.x (SQLite local), DAOs générés |
| Routing | go_router 14.8.0 — guard auth dans `redirect` |
| Auth storage | flutter_secure_storage 10.3.1 |
| BFF | Cloudflare Workers v8 (TypeScript), Wrangler 4.x |
| OCR | Mindee API v2 (async polling `/jobs/{jobId}`) |
| IA | Mistral `mistral-small-latest` (batch catégorisation) |
| SMS | Africa's Talking API v1 |
| IDs | uuid 4.5.3 (UUID v4) |

---

## Architecture

```
lib/
├── features/
│   ├── auth/          # Écrans + repository Auth (OTP)
│   ├── scan/          # Capture, chargement, revue reçu
│   ├── transactions/  # Historique, détail/modification
│   ├── dashboard/     # Tableau de bord (Epic 4 — non démarré)
│   └── categories/    # Gestion catégories (Epic 5 — non démarré)
├── shared/
│   ├── data/          # TransactionRepository, AppDatabase, DAOs
│   ├── domain/        # ReceiptLine, SessionState, Failure, SecureStorage
│   ├── network/       # BffClient (lit BFF_URL via dart-define)
│   ├── providers/     # balance, categoryList, session, settings, transactionList…
│   ├── routing/       # app_router.dart (GoRouter + guard)
│   ├── theme/         # AppColors, AppTextStyles, AppTheme
│   ├── utils/         # category_utils.dart
│   └── widgets/       # CategorySelectorSheet, ReceiptLineItem, TransactionFormSheet…
└── main.dart

bff/src/
├── handlers/          # otp.ts, scan.ts, ocr.ts, categorize.ts
└── index.ts
```

**Règles clés :**
- Les features ne s'importent jamais entre elles — uniquement depuis `shared/`
- `TransactionRepository` = seul écrivain en base (AD-10)
- `categoryListProvider` = seul StreamProvider sur `CategoryDao.watchAll()` (AD-11)
- Aucune clé API dans le binaire Flutter (tout dans le BFF)

---

## Design tokens principaux

| Token | Valeur |
|-------|--------|
| `AppColors.bg` | `#0D0F1E` |
| `AppColors.surface` | `#181B33` |
| `AppColors.surfaceRaised` | `#1E2240` |
| `AppColors.accent` | `#6B5CFF` |
| `AppColors.accentDim` | `#2A2460` |
| `AppColors.warning` | `#F5A623` |
| `AppColors.danger` | `#FF6B6B` |
| `AppColors.success` | `#00C897` |
| `AppColors.border` | `#2A2D4A` |
| `AppColors.textPrimary` | `#FFFFFF` |
| `AppColors.textSecondary` | `#A8A8C0` |

Typographie : Urbanist — Display 32px/800, Title 20px/600, Body 15px/400, Caption 12px/500.

---

## État d'avancement des Stories

### Epic 1 — Fondation + Authentification ✅ COMPLET

| Story | Titre | Statut |
|-------|-------|--------|
| 1.1 | Initialisation Flutter + fondation technique | ✅ review |
| 1.2 | Saisie numéro de téléphone + envoi OTP | ✅ review |
| 1.3 | Validation OTP, session, renvoi code | ✅ review |
| 1.4 | Paramètres, déconnexion, bannière avertissement | ✅ review |

### Epic 2 — Saisie manuelle + Historique ✅ COMPLET

| Story | Titre | Statut |
|-------|-------|--------|
| 2.1 | Carte Solde + écran Accueil état vide | ✅ review |
| 2.2 | Saisie manuelle Dépense/Revenu | ✅ review |
| 2.3 | Historique des Transactions | ✅ review |
| 2.4 | Modification et suppression Transaction | ✅ review |

### Epic 3 — Scan Reçu + Pipeline OCR ✅ COMPLET

| Story | Titre | Statut |
|-------|-------|--------|
| 3.1 | Capture photo du Reçu | ✅ review |
| 3.2 | Pipeline OCR, catégorisation IA, skeleton loading | ✅ review |
| 3.3 | Revue et correction des Lignes du Reçu | ✅ review |
| 3.4 | Validation globale + regroupement Historique | ✅ review |

### Epic 4 — Tableau de bord analytique ✅ COMPLET

| Story | Titre | Statut |
|-------|-------|--------|
| 4.1 | Structure Tableau de bord + Sélecteur de Période | ✅ review |
| 4.2 | Postes dépenses par catégorie + comparaison mois/mois | ✅ review |
| 4.3 | Graphique d'évolution du Solde | ✅ review |

### Epic 5 — Gestion Catégories personnalisées ⏳ En cours

| Story | Titre | Statut |
|-------|-------|--------|
| 5.1 | Liste des catégories + accès Paramètres | ✅ review |
| 5.2 | Création d'une catégorie personnalisée | ⏳ À faire |
| 5.3 | Renommage et suppression | ⏳ À faire |

---

## Epic 5 — Story en cours : 5.2

**Story 5.2 :** Création d'une catégorie personnalisée — `CategoryFormSheet` bottom sheet (grille emojis + 6 pastilles couleur custom + champ nom + validation doublon). `CategoryDao.insert()`.

**Notes techniques Epic 5 :**
- `sortCategories(List<Category>)` : prédéfinies d'abord (ordre DB), custom triées par `createdAt` ASC — exportée dans `category_management_screen.dart`
- `categoryListProvider` = seul StreamProvider sur `CategoryDao.watchAll()` (AD-11) — déjà en place
- Gestion des catégories prédéfinies vs personnalisées (`isPredefined` flag)
- 6 paires couleur custom : `cat-custom-rose`, `cat-custom-teal`, `cat-custom-terracotta`, `cat-custom-olive`, `cat-custom-slate`, `cat-custom-prune` — à définir dans `CategoryUtils.pastilleColors()` pour Story 5.2
- Story 5.3 : suppression → réaffecter transactions à « Autre » + supprimer catégorie dans `database.transaction()` atomique

---

## Fichiers clés modifiés/créés (Sessions précédentes)

| Fichier | Rôle |
|---------|------|
| `lib/shared/domain/receipt_line.dart` | `id` UUID v4, `isWarning`, `copyWith` préserve `id` |
| `lib/shared/widgets/receipt_line_item.dart` | Widget ligne éditable (warning, swipe, menu ⋯, a11y) |
| `lib/features/scan/screens/scan_review_screen.dart` | `ConsumerStatefulWidget`, validation → `insertReceiptLines`, navigation `/home` |
| `lib/shared/data/transaction_repository.dart` | Ajout `insertReceiptLines()` — atomique, fallback "Autre" |
| `lib/shared/widgets/receipt_group_tile.dart` | Entrée groupée expand/collapse (AnimatedSize, Semantics) |
| `lib/features/transactions/screens/history_screen.dart` | Groupement `_HistoryItem` sealed class, `ReceiptGroupTile` |
| `test/shared/domain/receipt_line_test.dart` | 17 tests unitaires |
| `test/shared/data/transaction_repository_test.dart` | 20 tests (dont 7 sur `insertReceiptLines`) |
| `.gitignore` | Exclusions BFF + `.claude/` |
| `lib/shared/providers/selected_period_provider.dart` | `NotifierProvider<DateTimeRange>` + helpers `monthRange`, `isFullMonth`, `previousMonth`, `nextMonth` |
| `lib/features/dashboard/widgets/period_selector.dart` | ◀ [label] ▶ — ConsumerWidget, tap label → CustomPeriodSheet |
| `lib/features/dashboard/widgets/custom_period_sheet.dart` | Bottom sheet période custom, validation inline date fin < date début |
| `lib/features/dashboard/screens/dashboard_screen.dart` | Tableau de bord — PeriodSelector + FR-18 postes réels (Story 4.2) + FR-19 placeholder |
| `test/shared/providers/selected_period_provider_test.dart` | 21 tests (monthRange, isFullMonth, previousMonth, nextMonth, provider) |
| `lib/shared/providers/category_spending_provider.dart` | `Provider<List<CategorySpendingEntry>>` + `computeSpendingTotals` + `buildCategorySpendingEntries` |
| `lib/shared/providers/monthly_comparison_provider.dart` | `Provider<Map<String, int>>` — dépenses catégorie du mois précédent |
| `lib/features/dashboard/widgets/category_spending_tile.dart` | Pastille + nom + montant − + variation ↑↓ mois/mois |
| `test/shared/providers/category_spending_provider_test.dart` | 14 tests purs (computeSpendingTotals × 8, buildCategorySpendingEntries × 6) |
| `test/shared/providers/monthly_comparison_provider_test.dart` | 6 tests purs (mois précédent, transition jan→déc, cumul) |
| `lib/shared/providers/daily_balance_provider.dart` | `Provider<List<DailyBalancePoint>>` + `computeDailyBalances` (carry-forward) |
| `lib/features/dashboard/widgets/balance_chart.dart` | `LineChart` fl_chart — axe zéro, labels JJ/MM, Semantics TalkBack |
| `test/shared/providers/daily_balance_provider_test.dart` | 12 tests purs (computeDailyBalances : solde initial, carry-forward, boundaries) |
| `lib/features/categories/screens/category_management_screen.dart` | Liste catégories UX-DR15 — `sortCategories` pure, FAB `+`, icônes crayon/corbeille |
| `test/features/categories/category_management_screen_test.dart` | 6 tests purs (sortCategories : vide, prédéfinies avant custom, createdAt ASC) |

---

## Résultats des tests

**Dernier run :** 128/128 tests passent · `flutter analyze` : 0 issues

---

## Notes techniques importantes

### Riverpod 3.3.2
- Pas de `valueOrNull` — utiliser `asData?.value ?? []`
- Pattern : `ref.read(categoryListProvider).asData?.value ?? []`

### `CustomSemanticsAction`
- Nécessite `import 'package:flutter/semantics.dart';` (non ré-exporté par `flutter/material.dart`)

### `ValueKey(line.id)` obligatoire
- Sur chaque `ReceiptLineItem` pour que les `TextEditingController` survivent aux rebuilds du parent

### Montants
- Stockés en INTEGER centimes. BFF renvoie `amount_cents`. Affichage : `amountCents ~/ 100`
- `ReceiptLineItem._amountCtrl` : texte = entier FCFA (`amountCents ~/ 100`), listener × 100

### `CategorySelectorSheet` depuis `ScanReviewScreen`
- `_findCategoryId(name, cats)` — cherche l'ID par nom dans `categoryListProvider`
- Résultat : `cat.name` (pas `cat.id`) stocké dans `ReceiptLine.category`

### Riverpod 3.3.2 — `StateProvider` supprimé
- `StateProvider` n'existe pas en Riverpod 3.3.2 — utiliser `NotifierProvider` avec un `Notifier<T>` simple
- Pattern : `NotifierProvider<MyNotifier, T>(MyNotifier.new)` avec `state` mutable dans le notifier
- Mise à jour externe : `ref.read(provider.notifier).selectRange(newValue)`

### Noms de mois en français
- Pas d'`intl` DateFormat pour les noms de mois (évite `initializeDateFormatting`) — utiliser map statique :
  `const _kFrMonths = ['Janvier', 'Février', ..., 'Décembre']`
- Format JJ/MM : `d.day.toString().padLeft(2, '0')/${d.month.toString().padLeft(2, '0')}`

### fl_chart 0.69.2 — API correcte

- `SideTitleWidget(axisSide: meta.axisSide, child: ...)` — PAS `meta: meta` (non encore migré)
- `SideTitles(showTitles: false)` — PAS `show: false`
- `withValues(alpha: x)` à la place de `withOpacity(x)` (deprecated Flutter 3.22+)
- `getTooltipColor: (_) => color` sur `LineTouchTooltipData` (pas `tooltipBgColor`)

### Tests StreamProvider (Riverpod 3.3.2) — pattern établi

- `await container.read(myStreamProvider.future)` ne se complète JAMAIS si `Stream.value()` est utilisé en override — timeout 30s garanti
- Pattern du projet : extraire la logique en **fonctions pures testables** (`computeSpendingTotals`, `buildCategorySpendingEntries`) + tests synchrones
- Les tests d'intégration Riverpod (loading state) utilisent une vraie DB Drift in-memory (`databaseProvider.overrideWithValue(db)`)

### `DateTimeRange` Flutter SDK
- `DateTimeRange(start, end)` de `package:flutter/material.dart` — pas de classe custom
- Dernier jour du mois : `DateTime(year, month + 1, 0)` — 0ème jour = dernier jour du mois précédent
- Plage couvrant toute la journée de `end` : `endMs = DateTime(y, m, d, 23, 59, 59).millisecondsSinceEpoch`

---

## Git

- Dépôt : https://github.com/yyracine/GestBud (branche `master`)
- Commit initial : `b2f496f` — 190 fichiers, 27 221 insertions
- Auteur configuré : Racine Yao <racine.yao@gmail.com>

---

## Instructions de mise à jour

En fin de session, mettre à jour :
1. **Date** en haut du fichier
2. **Statut** de la story terminée (→ `✅ review`)
3. **Prochaine story** à implémenter (section dédiée)
4. **Résultats des tests** (nombre total)
5. **Fichiers clés** si de nouveaux fichiers importants ont été créés
6. **Notes techniques** si une subtilité nouvelle a été découverte
