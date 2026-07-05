---
baseline_commit: NO_VCS
story_key: 1-1-flutter-foundation
status: review
---

# Story 1.1 — Initialisation du projet Flutter et fondation technique

## Story

**En tant que** développeur,
**Je veux** un projet Flutter greenfield correctement initialisé avec la stack complète (Drift, Riverpod, GoRouter, BFF skeleton),
**Afin de** disposer d'une fondation technique solide pour toutes les features suivantes.

## Acceptance Criteria

- **AC-1:** L'app s'ouvre sur l'écran Auth/Phone (fond #0D0F1E, police Urbanist, dark only) sans flash blanc ✅
- **AC-2:** `sessionProvider` lit `flutter_secure_storage` → redirige vers `/auth/phone` (pas de token) ou `/home` (token valide) ✅
- **AC-3:** `main.dart` attend la résolution de `sessionProvider` via `ProviderContainer` avant de monter `MaterialApp` (pas de race condition) ✅
- **AC-4:** `AppDatabase.onCreate` insère 10 catégories prédéfinies via `insertOrIgnore` ✅
- **AC-5:** Aucun import cross-feature (les features n'importent que depuis `shared/`) ✅
- **AC-6:** `/home` affiche un shell 3-onglets (Accueil · Historique · Tableau de bord), FAB stub, icône Settings en haut à droite ✅

## Tasks / Subtasks

### Task 1: pubspec.yaml et structure de projet
- [x] 1.1 Modifier `pubspec.yaml` : dépendances (drift, riverpod, go_router, flutter_secure_storage, google_fonts, uuid, intl, http), sdk flutter ^3.22
- [x] 1.2 Créer l'arborescence `lib/` complète (26 répertoires features + shared + bff)
- [x] 1.3 `analysis_options.yaml` généré par flutter create, no issues after analyze

### Task 2: Drift schema + DAOs + seeding
- [x] 2.1 Tests RED : `AppDatabase.onCreate` insère exactement 10 catégories
- [x] 2.2 Créer `lib/shared/data/database/app_database.dart` (3 tables : app_settings, categories, transactions)
- [x] 2.3 Créer `lib/shared/data/database/daos/category_dao.dart`, `transaction_dao.dart`, `settings_dao.dart`
- [x] 2.4 Seeding de 10 catégories prédéfinies via UUID v5 déterministe + `insertOrIgnore`
- [x] 2.5 Tests GREEN : 5/5 ✅

### Task 3: Providers Riverpod
- [x] 3.1 Tests RED : `sessionProvider` retourne `unauthenticated` quand FSS vide
- [x] 3.2 Créer `lib/shared/domain/session_state.dart` (sealed class SessionState)
- [x] 3.3 Créer `lib/shared/providers/session_provider.dart` (AsyncNotifierProvider<SessionState>)
- [x] 3.4 Créer `lib/shared/providers/settings_provider.dart`
- [x] 3.5 Créer `lib/shared/providers/category_list_provider.dart` (SEUL StreamProvider sur CategoryDao)
- [x] 3.6 Créer `lib/shared/providers/database_provider.dart`
- [x] 3.7 Tests GREEN : 4/4 ✅

### Task 4: GoRouter avec garde auth
- [x] 4.1 Créer `lib/shared/routing/app_router.dart` — toutes les routes nommées, `redirect` lit `sessionProvider`

### Task 5: ThemeData + design tokens
- [x] 5.1 Créer `lib/shared/theme/app_colors.dart` (tokens Nuit Violette)
- [x] 5.2 Créer `lib/shared/theme/app_text_styles.dart` (Urbanist, tabular figures)
- [x] 5.3 Créer `lib/shared/theme/app_theme.dart` (ThemeData dark only)

### Task 6: BffClient
- [x] 6.1 Créer `lib/shared/network/bff_client.dart` — URL via `String.fromEnvironment('BFF_URL')`

### Task 7: Home shell (AC-6)
- [x] 7.1 Créer `lib/features/dashboard/screens/home_shell.dart` — 3 onglets + FAB stub + Settings icon

### Task 8: Auth Phone screen stub (AC-1)
- [x] 8.1 Créer `lib/features/auth/screens/auth_phone_screen.dart` — scaffold fond #0D0F1E, Urbanist

### Task 9: main.dart (AC-2, AC-3)
- [x] 9.1 `lib/main.dart` — `ProviderContainer` await sessionProvider avant `MaterialApp` via `UncontrolledProviderScope`

### Task 10: BFF skeleton
- [x] 10.1 Créer `bff/wrangler.toml` avec `[env.dev]` et `[env.prod]`
- [x] 10.2 Créer `bff/src/index.ts` — fetch handler avec routing `/otp`, `/scan`, `/categorize`
- [x] 10.3 Créer `bff/src/handlers/otp.ts`, `ocr.ts`, `categorize.ts` — stubs

## Dev Notes

- Flutter CLI : `C:\src\flutter\bin\flutter.bat`
- Code gen Drift : `dart run build_runner build` (relancer après modif schéma)
- Tests : `flutter test test/shared/` — 9/9 ✅
- Analyze : `flutter analyze` — No issues ✅
- `categoryListProvider` = SEUL StreamProvider sur `CategoryDao.watchAll()`
- Montants en centimes INTEGER, jamais double
- Design : dark only, fond `#0D0F1E`, accent `#6B5CFF`, Urbanist via google_fonts

## Dev Agent Record

### Implementation Plan
Story 1.1 — fondation greenfield. Ordre : flutter create → pubspec deps → Drift schema + build_runner → domain/providers → GoRouter → theme → BFF client → screens → main.dart → BFF skeleton → tests → analyze.

### Debug Log

| # | Issue | Fix |
|---|-------|-----|
| 1 | Flutter CLI absent du PATH | Chemin fourni : `C:\src\flutter\bin` |
| 2 | `deleteFrom` inexistant dans DAO Drift v2 | Remplacé par `delete(...)` |
| 3 | `http` transitive non déclarée | `flutter pub add http` |
| 4 | `__` wildcard lint warning | Remplacé par `_` (Dart 3.x wildcard) |
| 5 | `MyApp` inexistant dans widget_test | Vidé le test généré par flutter create |
| 6 | UUID v4 non-déterministe → seeding non idempotent | UUID v5 + namespace OID constant |
| 7 | `Uuid.NAMESPACE_OID` déprécié | Constante string RFC 4122 `_kOidNamespace` |
| 8 | `package:uuid/uuid_util.dart` inexistant | Supprimé, constante string directe |

### Completion Notes
- 9/9 tests GREEN, 0 analyze issues
- Abstraction `SecureStorage` créée (`lib/shared/domain/secure_storage.dart`) + adapter FSS → testabilité sans platform channels
- BFF skeleton TypeScript prêt pour Stories 1.2–1.3 (handlers otp/ocr/categorize)
- AC-1 à AC-6 satisfaits

## File List

### Nouveaux fichiers créés
- `lib/main.dart` (remplacé)
- `lib/shared/data/database/app_database.dart`
- `lib/shared/data/database/app_database.g.dart` (généré)
- `lib/shared/data/database/daos/category_dao.dart`
- `lib/shared/data/database/daos/category_dao.g.dart` (généré)
- `lib/shared/data/database/daos/transaction_dao.dart`
- `lib/shared/data/database/daos/transaction_dao.g.dart` (généré)
- `lib/shared/data/database/daos/settings_dao.dart`
- `lib/shared/data/database/daos/settings_dao.g.dart` (généré)
- `lib/shared/data/flutter_secure_storage_adapter.dart`
- `lib/shared/domain/session_state.dart`
- `lib/shared/domain/secure_storage.dart`
- `lib/shared/providers/database_provider.dart`
- `lib/shared/providers/session_provider.dart`
- `lib/shared/providers/settings_provider.dart`
- `lib/shared/providers/category_list_provider.dart`
- `lib/shared/routing/app_router.dart`
- `lib/shared/theme/app_colors.dart`
- `lib/shared/theme/app_text_styles.dart`
- `lib/shared/theme/app_theme.dart`
- `lib/shared/network/bff_client.dart`
- `lib/features/auth/screens/auth_phone_screen.dart`
- `lib/features/dashboard/screens/home_shell.dart`
- `bff/wrangler.toml`
- `bff/src/index.ts`
- `bff/src/handlers/otp.ts`
- `bff/src/handlers/ocr.ts`
- `bff/src/handlers/categorize.ts`
- `test/shared/data/database/app_database_test.dart`
- `test/shared/providers/session_provider_test.dart`
- `test/widget_test.dart` (vidé)

## Change Log

| Date | Change |
|------|--------|
| 2026-07-01 | Story créée, statut in-progress |
| 2026-07-01 | Toutes tasks complétées — 9/9 tests GREEN, 0 analyze issues — statut review |

## Status

review
