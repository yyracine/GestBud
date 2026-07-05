---
baseline_commit: NO_VCS
story_key: 1-3-otp-verify-session
status: in-progress
---

# Story 1.3 — Validation OTP, session et renvoi de code

## Story

**En tant qu'** utilisateur ayant reçu un OTP,
**Je veux** saisir le code reçu pour accéder à l'app sans devoir me reconnecter à chaque ouverture,
**Afin que** mon expérience quotidienne soit fluide dès le deuxième lancement.

## Acceptance Criteria

- **AC-1:** L'écran Auth/OTP affiche un champ 6 chiffres ; saisir les 6 chiffres corrects et valider → token stocké dans `flutter_secure_storage` + GoRouter redirige vers `/home`
- **AC-2:** OTP invalide ou expiré (> 10 min) soumis → message d'erreur inline sous le CTA, aucune navigation
- **AC-3:** App relancée après session valide (token dans FSS) → `sessionProvider` lit FSS, GoRouter redirige directement vers `/home` sans repasser par `/auth`
- **AC-4:** Bouton « Renvoyer » désactivé 60s dès l'arrivée sur l'écran avec compteur visible décrémentant (`59s`, `58s`…) ; après expiration, tap → nouvel OTP via `POST /otp/send`
- **AC-5:** Pendant le compteur de renvoi, le bouton « Renvoyer » ne répond pas (désactivé visuellement et fonctionnellement)

## Tasks / Subtasks

### Task 1: AuthRepository.verifyOtp — TDD
- [x] 1.1 Tests RED : `verifyOtp` retourne `(token, null)` sur succès, `(null, NetworkFailure)` sur SocketException/TimeoutException, `(null, AuthFailure)` sur BffException
- [x] 1.2 Ajouter `verifyOtp(String phone, String code)` dans `auth_repository.dart` — retourne `(String?, Failure?)`
- [x] 1.3 Tests GREEN — 8/8 tests passent (4 verifyOtp + 4 sendOtp)

### Task 2: BFF — handler OTP verify
- [x] 2.1 Implémenter `handleVerify` dans `bff/src/handlers/otp.ts` — lit KV `otp:{phone}`, vérifie le code, génère `crypto.randomUUID()`, supprime le KV après succès, retourne `{ token }` ou erreur 400

### Task 3: OtpScreen — implémentation complète
- [x] 3.1 Convertir le stub `otp_screen.dart` en `ConsumerStatefulWidget` avec : champ 6 chiffres (keyboardType number), CTA « Vérifier » activé seulement à 6 chiffres, état de chargement, message erreur inline
- [x] 3.2 Sur succès : appeler `sessionStateProvider.notifier.authenticate(token)` → GoRouter redirect automatique vers `/home`
- [x] 3.3 Compteur 60s dès `initState`, bouton « Renvoyer » désactivé pendant le compte à rebours, réactivé à 0 ; tap « Renvoyer » → `repo.sendOtp()` + relance le compteur

## Dev Notes

- **Retour de `verifyOtp`** : record Dart 3 `(String? token, Failure? failure)` — un seul est non-null
- **Parsing erreur BFF** : extraire `e.body` en JSON → `parsed['error'] as String` pour message lisible (évite JSON brut affiché)
- **Token BFF** : `crypto.randomUUID()` — stateless, aucune persistance côté BFF ; Flutter stocke en FSS via `sessionNotifier.authenticate(token)`
- **AC-3** : déjà couvert par `sessionProvider.build()` + `redirect` GoRouter de Story 1.1 ; aucun code additionnel requis
- **Compteur resend** : `Timer.periodic(Duration(seconds: 1), ...)` + `setState(() => _resendCooldown--)` ; annuler dans `dispose()`
- **Champ OTP** : `maxLength: 6`, `keyboardType: TextInputType.number`, `inputFormatters: [FilteringTextInputFormatter.digitsOnly]`
- **Messages erreur** : `AuthFailure.message` = message extrait du JSON BFF (ex: « Ce code a expiré. Demande-en un nouveau. »)

## Dev Agent Record

### Implementation Plan
Ordre : AuthRepository.verifyOtp TDD (RED→GREEN) → BFF handleVerify → OtpScreen complet.

### Debug Log

| # | Issue | Fix |
|---|-------|-----|

### Completion Notes
- 17/17 tests GREEN (5 DB + 4 session + 4 verifyOtp + 4 sendOtp), 0 issues analyze
- `AuthRepository.verifyOtp()` retourne record `(String?, Failure?)` — parse JSON BFF pour message lisible
- BFF `handleVerify` : lit KV, vérifie code, supprime KV (anti-replay), génère `crypto.randomUUID()` → `{ token }`
- `OtpScreen` : `ConsumerStatefulWidget`, champ 6 chiffres, Timer 60s initState, resend avec relance compteur
- AC-1 ✅ 6 chiffres corrects → authenticate() → GoRouter /home
- AC-2 ✅ Mauvais code / expiré → AuthFailure.message inline
- AC-3 ✅ Déjà couvert sessionProvider.build() + redirect GoRouter (Story 1.1)
- AC-4 ✅ Compteur 60s initState + resend relance compteur
- AC-5 ✅ `_canResend` false pendant countdown

## File List

### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/1-3-otp-verify-session.md`

### Fichiers modifiés
- `lib/features/auth/repository/auth_repository.dart`
- `lib/features/auth/screens/otp_screen.dart`
- `test/features/auth/repository/auth_repository_test.dart`
- `bff/src/handlers/otp.ts`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-01 | Story créée, statut in-progress |
| 2026-07-01 | Toutes tasks complétées — 17/17 tests GREEN, 0 analyze issues — statut review |

## Status

review
