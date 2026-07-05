---
baseline_commit: NO_VCS
story_key: 3-1-scan-capture-receipt
status: review
---

# Story 3.1 — Capture photo du Reçu

## Story

**En tant qu'** utilisateur,
**Je veux** photographier mon ticket de caisse directement depuis l'app ou le sélectionner dans ma galerie,
**Afin de** pouvoir le faire analyser automatiquement sans saisie manuelle.

## Acceptance Criteria

- **AC-1:** L'utilisateur appuie sur le FAB `+` → menu FAB s'ouvre → l'option « Scan Reçu » est désormais active (plus grisée) et accessible.

- **AC-2:** L'utilisateur sélectionne « Scan Reçu » et c'est le premier accès à la caméra → la permission correspondante est demandée avec un message explicatif (string déclaré dans Info.plist et AndroidManifest).

- **AC-3:** La permission est accordée → la caméra native s'ouvre pour capturer une photo.

- **AC-4:** L'utilisateur capture ou sélectionne une image → l'app navigue immédiatement vers l'écran de chargement OCR (skeleton) et envoie la photo au BFF via `POST /scan/receipt`.

- **AC-5:** La permission est refusée définitivement → un message contextuel invite l'utilisateur à activer la permission dans les Réglages du système, sans plantage ni état bloqué.

- **AC-6:** Le réseau est absent au moment de l'envoi → un message inline s'affiche : « Pas de connexion réseau. Saisis le reçu manuellement. » avec un CTA ouvrant le bottom sheet Transaction (FR-5).

## Tasks / Subtasks

### Task 1: Dépendances Flutter et permissions natives
- [x] 1.1 Ajouter `image_picker` et `permission_handler` dans pubspec.yaml + flutter pub get
- [x] 1.2 Ajouter `NSCameraUsageDescription` et `NSPhotoLibraryUsageDescription` dans ios/Runner/Info.plist
- [x] 1.3 Ajouter `<uses-permission android:name="android.permission.CAMERA" />` dans AndroidManifest.xml

### Task 2: BFF scan handler
- [x] 2.1 Créer `bff/src/handlers/scan.ts` — `handleScan` stub POST `/scan/receipt` → `{ lines: [] }`
- [x] 2.2 Mettre à jour `bff/src/index.ts` — router `/scan/receipt` → `handleScan`

### Task 3: BffClient multipart
- [x] 3.1 Ajouter `postMultipart(path, {imageBytes, filename})` dans `lib/shared/network/bff_client.dart`

### Task 4: ScanLoadingScreen (skeleton OCR)
- [x] 4.1 Créer `lib/features/scan/screens/scan_loading_screen.dart` — skeleton 6 lignes avec animation pulse (0.4→0.8→0.4, 1.2 s), Reduce Motion = fond statique opacité 0.6, état d'erreur réseau avec CTA → `_runFormLoop`

### Task 5: ScanEntryScreen (capture + permissions)
- [x] 5.1 Créer `lib/features/scan/screens/scan_entry_screen.dart` — 2 CTAs (caméra + galerie), vérification `Permission.camera` avant capture, état `permissionDenied` → bouton Réglages, navigate vers `ScanLoadingScreen` après capture

### Task 6: Câblage FabMenuSheet + HomeShell + Router
- [x] 6.1 Activer « Scan Reçu » dans `lib/shared/widgets/fab_menu_sheet.dart` → retourne `'scan_receipt'`
- [x] 6.2 Ajouter route `/scan/entry` dans `lib/shared/routing/app_router.dart` (hors ShellRoute)
- [x] 6.3 Mettre à jour `lib/features/dashboard/screens/home_shell.dart` — handle `'scan_receipt'` → `context.push('/scan/entry')`

## Dev Notes

### Architecture
- `ScanEntryScreen` + `ScanLoadingScreen` → `lib/features/scan/screens/`
- GoRouter route `/scan/entry` pour `HomeShell → ScanEntryScreen` (évite import cross-feature)
- `Navigator.push` pour `ScanEntryScreen → ScanLoadingScreen` (intra-feature, paramètres typés : Uint8List + filename)
- Aucun import cross-feature (AD-2) — `scan/` n'importe que depuis `shared/`

### Permissions
- `permission_handler` : vérification `Permission.camera.status` avant caméra → `isPermanentlyDenied` → état dédié
- `image_picker` : gère le dialog de permission en interne (iOS NSCameraUsageDescription, Android)
- Galerie : `ImagePicker().pickImage(source: ImageSource.gallery)` — permission gérée en interne par image_picker

### Envoi image BFF
- `BffClient.postMultipart('/scan/receipt', imageBytes: bytes, filename: name)` — multipart/form-data, champ `file`
- Toute exception (SocketException, TimeoutException, BffException) → état `networkError` dans ScanLoadingScreen
- Photo jamais persistée localement après envoi (AD-4)

### Skeleton (UX-DR12)
- 6 lignes reproduisant la géométrie des lignes de reçu : pastille 40px + label 14px + date 10px + montant 52px
- Pulse `AnimationController` 1.2 s, opacité 0.4→0.8→0.4
- Reduce Motion : `MediaQuery.disableAnimationsOf(context)` → opacité fixe 0.6, contrôleur toujours lancé mais anim ignorée

### Story 3.2
- `_sendToServer()` dans ScanLoadingScreen parsera la réponse `{ lines: [] }` → navigation ScanReviewScreen

### Tests
- Tests widget absents (project-context.md Phase MVP)
- Validation : flutter test (45 tests existants) + flutter analyze

## Dev Agent Record

### Implementation Plan
Ordre : Task 1 (deps + native) → Task 2 (BFF) → Task 3 (BffClient) → Task 4 (ScanLoadingScreen) → Task 5 (ScanEntryScreen) → Task 6 (câblage)

### Debug Log

| # | Issue | Fix |
|---|-------|-----|

### Completion Notes

- 45/45 tests passent (aucun nouveau — tests widget absents Phase MVP), `flutter analyze` : 0 issues
- AC-1 : `FabMenuSheet` — « Scan Reçu » activé, retourne `'scan_receipt'`
- AC-2/3 : `ScanEntryScreen` — `Permission.camera.request()` avant capture ; iOS `NSCameraUsageDescription` + Android `<uses-permission CAMERA>` déclarés
- AC-4 : capture → `Navigator.push(ScanLoadingScreen)` ; `_sendToServer()` appelle `BffClient.postMultipart('/scan/receipt')`
- AC-5 : `Permission.camera.status.isPermanentlyDenied` → état `permissionDenied` → CTA `openAppSettings()`
- AC-6 : toute exception dans `_sendToServer()` → état `networkError` → message inline + CTA `_runFormLoop` (TransactionFormSheet)
- Nouveau plugin `image_picker 1.2.3` + `permission_handler 12.0.3` résolus
- Route GoRouter `/scan/entry` (hors ShellRoute) — évite import cross-feature `dashboard/ → scan/`
- Navigation `ScanEntryScreen → ScanLoadingScreen` via `Navigator.push` (intra-feature, même pattern que TransactionDetailScreen)

### File List

#### Nouveaux fichiers
- `_bmad-output/implementation-artifacts/stories/3-1-scan-capture-receipt.md`
- `bff/src/handlers/scan.ts`
- `lib/features/scan/screens/scan_entry_screen.dart`
- `lib/features/scan/screens/scan_loading_screen.dart`

#### Fichiers modifiés
- `pubspec.yaml`
- `ios/Runner/Info.plist`
- `android/app/src/main/AndroidManifest.xml`
- `bff/src/index.ts`
- `lib/shared/network/bff_client.dart`
- `lib/shared/widgets/fab_menu_sheet.dart`
- `lib/shared/routing/app_router.dart`
- `lib/features/dashboard/screens/home_shell.dart`

## Change Log

| Date | Change |
|------|--------|
| 2026-07-03 | Story créée et implémentée — 45/45 tests, 0 issues analyze — statut review |

## Status

review
