---
baseline_commit: NO_VCS
story_key: 1-2-phone-otp-send
status: in-progress
---

# Story 1.2 — Saisie du numéro de téléphone et envoi d'OTP

## Story

**En tant que** nouvel utilisateur,
**Je veux** saisir mon numéro de téléphone et recevoir un code OTP par SMS,
**Afin de** pouvoir vérifier mon identité et m'inscrire dans l'app.

## Acceptance Criteria

- **AC-1:** L'écran Auth/Téléphone valide le format E.164 en temps réel ; le CTA « Envoyer le code » reste désactivé tant que le format n'est pas valide ; le clavier numérique natif s'affiche automatiquement ✅
- **AC-2:** Un numéro E.164 valide saisi + tap CTA → état de chargement visible + requête `POST /otp/send` envoyée au BFF ✅
- **AC-3:** `POST /otp/send` succès → l'app navigue vers l'écran Auth/OTP (stub) ✅
- **AC-4:** Réseau absent au moment de l'envoi → message inline « Pas de connexion réseau » sous le bouton, aucune navigation ✅
- **AC-5:** Numéro déjà inscrit → BFF traite comme un flux de connexion (comportement identique pour l'utilisateur) ✅

## Tasks / Subtasks

### Task 1: Failure domain types
- [x] 1.1 Créer `lib/shared/domain/failure.dart` — sealed class Failure (NetworkFailure, AuthFailure, OcrFailure, DatabaseFailure)

### Task 2: AuthRepository
- [x] 2.1 Tests RED : `sendOtp` retourne null sur succès BFF, `NetworkFailure` sur SocketException et TimeoutException, `AuthFailure` sur BffException
- [x] 2.2 Créer `lib/features/auth/repository/auth_repository.dart` — `sendOtp(String phone)` délègue à `BffClient.post('/otp/send')`
- [x] 2.3 Tests GREEN — 4/4 ✅

### Task 3: Écran Auth/Phone — implémentation complète
- [x] 3.1 Transformer `AuthPhoneScreen` en `ConsumerStatefulWidget` avec validation E.164 temps réel, état chargement, message erreur inline
- [x] 3.2 Sur succès : navigation vers `/auth/otp` avec le numéro en extra GoRouter
- [x] 3.3 Sur `NetworkFailure` : message « Pas de connexion réseau » sous le CTA

### Task 4: OTP screen stub + route GoRouter
- [x] 4.1 Créer `lib/features/auth/screens/otp_screen.dart` — stub pour navigation (Story 1.3 complétera)
- [x] 4.2 Ajouter route `/auth/otp` dans `shared/routing/app_router.dart`

### Task 5: BFF — handler OTP send avec Africa's Talking
- [x] 5.1 Mettre à jour `bff/src/handlers/otp.ts` — valider E.164, générer OTP 6 chiffres, stocker en KV (TTL 600s), envoyer SMS via Africa's Talking API v1
- [x] 5.2 Mettre à jour `bff/src/index.ts` — ajouter `OTP_STORE: KVNamespace` dans interface Env
- [x] 5.3 Ajouter binding KV `OTP_STORE` dans `bff/wrangler.toml` (dev + prod)
- [x] 5.4 Créer `bff/.dev.vars.example` — template secrets

## Dev Notes

- **E.164 regex** : `^\+[1-9]\d{6,14}$`
- **`Failure` sealed class** : `NetworkFailure`, `AuthFailure`, `OcrFailure`, `DatabaseFailure` dans `shared/domain/failure.dart`
- **`AuthRepository.sendOtp()`** retourne `Failure?` (null = succès) — pas de throw nu
- **BFF stateless** : l'OTP est stocké en Workers KV avec TTL 600s — clé `otp:{phone}`, valeur `{otp, phone, createdAt}`
- **Africa's Talking SMS API** : `POST https://api.africastalking.com/version1/messaging`, header `apiKey`, body `application/x-www-form-urlencoded` (username, to, message)
- **Secrets BFF** : `AFRICA_TALKING_API_KEY`, `AFRICA_TALKING_USERNAME` — `.dev.vars` en dev, `wrangler secret put` en prod
- **Navigation** : phone passé via GoRouter `extra` → `OtpScreen(phone: phone)`
- **Clavier** : `TextInputType.phone` → clavier numérique natif + touche `+`

## Dev Agent Record

### Implementation Plan
Ordre : Failure domain → AuthRepository TDD (RED→GREEN) → AuthPhoneScreen update → OtpScreen stub + GoRouter → BFF OTP handler.

### Debug Log

| # | Issue | Fix |
|---|-------|-----|

### Completion Notes
- 13/13 tests GREEN (9 Story 1.1 + 4 AuthRepository), 0 issues analyze
- `sealed class Failure` créée dans `shared/domain/failure.dart` (NetworkFailure, AuthFailure, OcrFailure, DatabaseFailure)
- `AuthRepository.sendOtp()` retourne `Failure?` — null = succès, jamais de throw nu
- BFF : OTP 6 chiffres stocké en Workers KV (TTL 600s) + envoi SMS Africa's Talking API v1
- Route `/auth/otp` ajoutée dans GoRouter, phone passé via `extra`
- AC-1 à AC-5 satisfaits

## File List

### Nouveaux fichiers
- `lib/shared/domain/failure.dart`
- `lib/features/auth/repository/auth_repository.dart`
- `lib/features/auth/screens/otp_screen.dart`
- `test/features/auth/repository/auth_repository_test.dart`
- `bff/.dev.vars.example`

### Fichiers modifiés
- `lib/features/auth/screens/auth_phone_screen.dart`
- `lib/shared/routing/app_router.dart`
- `bff/src/handlers/otp.ts`
- `bff/src/index.ts`
- `bff/wrangler.toml`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-01 | Story créée, statut in-progress |
| 2026-07-01 | Toutes tasks complétées — 13/13 tests GREEN, 0 analyze issues — statut review |

## Status

review
