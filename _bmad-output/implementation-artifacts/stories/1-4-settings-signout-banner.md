---
baseline_commit: NO_VCS
story_key: 1-4-settings-signout-banner
status: in-progress
---

# Story 1.4 — Paramètres, déconnexion et bannière avertissement stockage

## Story

**En tant qu'** utilisateur authentifié,
**Je veux** être informé une seule fois que mes données sont stockées sur mon téléphone, et pouvoir me déconnecter,
**Afin de** comprendre où vivent mes données et de pouvoir terminer ma session quand je le souhaite.

## Acceptance Criteria

- **AC-1:** L'utilisateur se connecte pour la première fois (`AppSettings.onboarding_shown = false`) → la bannière info s'affiche en bas de l'écran Accueil (au-dessus de la nav bar), non bloquante, avec le texte « Tes données sont sur ton téléphone. Ne désinstalle pas l'app. »
- **AC-2:** La bannière est visible, l'utilisateur appuie sur × → la bannière disparaît et `AppSettings.onboarding_shown` est mis à `true` en base Drift — elle ne réapparaît plus jamais, même après relance ou déconnexion/reconnexion
- **AC-3:** `AppSettings.onboarding_shown = true` → la bannière n'est pas affichée, même après déconnexion puis reconnexion
- **AC-4:** L'utilisateur est sur l'écran Accueil → appuie sur l'icône Settings (haut droite) → navigué vers l'écran Paramètres affichant au minimum un bouton « Se déconnecter »
- **AC-5:** L'utilisateur est sur l'écran Paramètres → appuie sur « Se déconnecter » → confirme → token effacé de `flutter_secure_storage`, `sessionProvider` non-authentifié, GoRouter redirige vers `/auth/phone`
- **AC-6:** Après déconnexion et réouverture de l'app → écran Auth/Téléphone ; transactions et catégories intactes en base Drift — seul le token de session a été effacé

## Tasks / Subtasks

### Task 1: SettingsDao.setOnboardingShown — TDD
- [x] 1.1 Tests RED : `setOnboardingShown(true)` → `getSettings()` retourne `onboardingShown = true` ; crée la ligne si inexistante ; idempotent (appels multiples)
- [x] 1.2 Implémenter `setOnboardingShown(bool)` dans `settings_dao.dart`
- [x] 1.3 Tests GREEN — tous les tests SettingsDao passent

### Task 2: SettingsScreen — déconnexion
- [x] 2.1 Créer `lib/features/auth/screens/settings_screen.dart` — ConsumerWidget, "Se déconnecter" ListTile + AlertDialog de confirmation → `sessionStateProvider.notifier.signOut()`
- [x] 2.2 Ajouter route `/settings` dans `app_router.dart`
- [x] 2.3 Câbler l'icône Settings de `HomeShell` sur `context.push('/settings')`

### Task 3: InfoBanner widget + intégration HomeShell
- [x] 3.1 Créer `lib/shared/widgets/info_banner.dart` — conforme UX-DR13 (fond `surfaceRaised`, bordure `border`, radius 14px, padding 12/16px, × cible ≥ 44pt)
- [x] 3.2 Ajouter `onboardingShownProvider` dans `settings_provider.dart` — dérivé de `settingsProvider`
- [x] 3.3 Convertir `HomeShell` en `ConsumerWidget` — afficher `InfoBanner` au-dessus de la nav bar quand `!onboardingShown` ; tap × → `settingsDao.setOnboardingShown(true)`

## Dev Notes

- **`AppSettings.onboardingShown`** : déjà dans le schéma Drift V1 (`BoolColumn`, default `false`) — aucune migration requise
- **SettingsDao.setOnboardingShown** : upsert avec `id = 'default'` fixe (crée ou met à jour) ; utilise `insertOnConflictUpdate`
- **AC-6 garanti passivement** : `signOut()` efface uniquement FSS (`session_token`) — Drift non touché → transactions/catégories intactes
- **`onboardingShownProvider`** : `Provider<bool>` dérivé de `settingsProvider.valueOrNull?.onboardingShown ?? false`
- **InfoBanner UX-DR13** : fond `surfaceRaised (#1E2240)`, bordure `border (#2A2D4A)`, radius `md` (14px), padding `12` vertical / `16` horizontal, × target ≥ 44pt
- **Pas de test widget** : conformément au project-context.md, les tests widget ne sont pas requis en Phase MVP
- **Dismiss banner** : lire `databaseProvider` directement depuis `ConsumerWidget` → `ref.read(databaseProvider).settingsDao.setOnboardingShown(true)`
- **Navigation settings** : `context.push('/settings')` depuis `HomeShell` — `/settings` est une route top-level (hors ShellRoute)
- **AlertDialog déconnexion** : `showDialog<bool>` + retour `true` sur confirmation ; ne pas procéder si `confirmed != true`

## Dev Agent Record

### Implementation Plan
Ordre : SettingsDao TDD (RED→GREEN) → SettingsScreen + route + wiring → InfoBanner + provider + HomeShell.

### Debug Log

| # | Issue | Fix |
|---|-------|-----|

### Completion Notes
- 20/20 tests GREEN (3 SettingsDao + 5 AppDatabase + 4 session + 8 auth), 0 issues analyze
- `SettingsDao.setOnboardingShown(bool)` : upsert `id='default'` via `insertOnConflictUpdate` — crée ou met à jour
- `onboardingShownProvider` : `Provider<bool>` dérivé de `settingsProvider.asData?.value?.onboardingShown ?? false`
- `InfoBanner` : conforme UX-DR13 — fond `surfaceRaised`, bordure `border`, radius 14px, × target 44pt
- `HomeShell` → `ConsumerWidget` : banner conditionnel `if (!onboardingShown)` au-dessus de la nav bar
- `SettingsScreen` : AlertDialog confirmation avant signOut → GoRouter redirect vers `/auth/phone`
- AC-6 garanti passivement : `signOut()` efface uniquement FSS — Drift intouché
- AC-1 ✅ Bannière visible au premier login (onboarding_shown = false)
- AC-2 ✅ × → setOnboardingShown(true) → bannière disparaît définitivement
- AC-3 ✅ onboarding_shown = true → pas de bannière même après déconnexion/reconnexion
- AC-4 ✅ Settings icon → context.push('/settings') → SettingsScreen avec "Se déconnecter"
- AC-5 ✅ Confirmation → signOut() → sessionProvider non-authentifié → GoRouter /auth/phone
- AC-6 ✅ Transactions/catégories intactes — seul le token FSS est effacé

## File List

### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/1-4-settings-signout-banner.md`
- `lib/features/auth/screens/settings_screen.dart`
- `lib/shared/widgets/info_banner.dart`

### Fichiers modifiés
- `lib/shared/data/database/daos/settings_dao.dart`
- `lib/shared/providers/settings_provider.dart`
- `lib/shared/routing/app_router.dart`
- `lib/features/dashboard/screens/home_shell.dart`
- `test/shared/data/database/app_database_test.dart`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-01 | Story créée, statut in-progress |
| 2026-07-01 | Toutes tasks complétées — 20/20 tests GREEN, 0 analyze issues — statut review |

## Status

review
