# GestBud — Résumé de session

> **À lire en début de session. À mettre à jour en fin de session.**
> Dernière mise à jour : 2026-07-05 (session 2)

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

### Epic 3 — Scan Reçu + Pipeline OCR 🔄 EN COURS

| Story | Titre | Statut |
|-------|-------|--------|
| 3.1 | Capture photo du Reçu | ✅ review |
| 3.2 | Pipeline OCR, catégorisation IA, skeleton loading | ✅ review |
| 3.3 | Revue et correction des Lignes du Reçu | ✅ review |
| 3.4 | Validation globale + regroupement Historique | ✅ review |

### Epic 4 — Tableau de bord analytique ⏳ À FAIRE

Stories 4.1 (Période), 4.2 (Postes dépenses), 4.3 (Graphique solde)

### Epic 5 — Gestion Catégories personnalisées ⏳ À FAIRE

Stories 5.1 (Liste), 5.2 (Création), 5.3 (Renommage/Suppression)

---

## Story 4.1 — prochaine à implémenter

**Titre :** Structure du Tableau de bord et Sélecteur de Période

**ACs clés :**
- AC-1 : Onglet « Tableau de bord » — mois courant sélectionné par défaut, flèches ◀▶
- AC-2 : Tap ◀▶ → mois précédent/suivant, contenu mis à jour immédiatement (< 100ms)
- AC-3 : Tap label période → bottom sheet sélection custom (date début + date fin)
- AC-4 : Date fin < date début → message inline, CTA désactivé
- AC-5 : Validation période custom → label plage + contenu mis à jour
- AC-6 : Mois sans transaction → états vides dans chaque section sans crash

**Nouveaux fichiers attendus :**
- `lib/features/dashboard/screens/dashboard_screen.dart`
- `lib/features/dashboard/widgets/period_selector.dart`
- `lib/shared/providers/selected_period_provider.dart` (`StateProvider<DateRange>`)
- Mise à jour `lib/shared/routing/app_router.dart` — `/dashboard` branché sur `DashboardScreen`
- Mise à jour `lib/features/dashboard/screens/home_shell.dart` si nécessaire

**Notes :**
- `DateRange` de Flutter SDK : `DateTimeRange` ou classe custom `DateRange(start, end)` ?
- Tous les providers du dashboard dériveront de `selectedPeriodProvider`
- Le Sélecteur Date natif : `showDatePicker` Flutter (UX-DR10 — dates futures bloquées)

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

---

## Résultats des tests

**Dernier run :** 69/69 tests passent · `flutter analyze` : 0 issues

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
