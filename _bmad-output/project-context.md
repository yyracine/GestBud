---
project_name: 'GestBud'
user_name: 'Racine'
date: '2026-07-01'
sections_completed: ['technology_stack', 'language_rules', 'framework_rules', 'testing_rules', 'code_quality', 'workflow', 'anti_patterns']
status: 'complete'
optimized_for_llm: true
rule_count: 58
last_updated: '2026-07-01'
---

# Project Context for AI Agents

_Ce fichier contient les règles critiques et patterns que les agents AI doivent suivre lors de l'implémentation du code GestBud. Priorité aux détails non-évidents qu'un agent manquerait autrement._

---

## Technology Stack & Versions

### Flutter (mobile)
- Flutter SDK: ^3.22 | Dart: ^3.4
- flutter_riverpod: ^3.3.2 (peut être pre-release — vérifier pub.dev avant `flutter pub add`)
- drift + drift_flutter: ^2.x (confirmer patch exact sur pub.dev)
- go_router: ^14.8.0
- flutter_secure_storage: ^10.3.1
- intl: (dernière stable compatible Flutter 3.22) — locale `fr` obligatoire
- dart:uuid: pour UUID v4 — jamais d'auto-increment SQLite comme ID externe
- Urbanist (Google Fonts) — chargée via pubspec.yaml assets

### BFF (Cloudflare Worker)
- Runtime: V8 Workers (Wrangler 4.x)
- Langage: TypeScript
- Mindee API: v2 (flux async : POST soumission → GET `/jobs/<jobId>` polling)
- Mistral API: `mistral-small-latest` (batch, un prompt pour toutes les lignes)
- Africa's Talking SMS API: v1

### Environnements
- Flutter build: `--dart-define=BFF_URL=https://...` (jamais hardcodé)
- BFF dev: `wrangler dev` avec `.dev.vars` pour les secrets
- BFF prod: `wrangler secret put` — jamais de clés en clair dans `wrangler.toml`

## Critical Implementation Rules

### Règles Dart / Flutter

#### Montants financiers
- Tout montant est stocké en `INTEGER` centimes (ex. 1 500 FCFA → `150000`)
- Jamais de `double` pour un montant — risque d'arrondi floating-point
- Affichage : diviser par 100, formater avec `intl` en espace fine insécable ` `
- Format affiché : `245 800 FCFA` — devise en style `caption`, jamais en `display`

#### Dates
- Stockées en `INTEGER` millisecondes epoch dans Drift (`int` Dart)
- Affichées en `JJ/MM/AAAA` via `intl` locale `fr`
- Jamais de `String` pour une date en base

#### Identifiants d'entités
- Toujours UUID v4 (`package:uuid`) — jamais `AUTOINCREMENT` SQLite comme ID externe
- `receipt_id` est `TEXT NULL` sur `transactions` : null pour saisie manuelle, UUID partagé pour toutes les lignes d'un même reçu

#### Nommage
- Fichiers : `snake_case.dart` — un fichier = une classe principale
- Classes et providers : `PascalCase` ; providers toujours suffixés `Provider` (ex. `soldeProvider`, `categoryListProvider`)
- Pas d'abréviation dans les noms (ex. `transactionRepository` pas `txRepo`)

#### Gestion d'erreurs
- `sealed class Failure` avec variantes : `NetworkFailure`, `OcrFailure`, `DatabaseFailure`, `AuthFailure`
- Les repositories retournent `Either<Failure, T>` ou `Result<T>` — jamais de throw nu dans une feature
- Les providers exposent l'état d'erreur via `AsyncValue` de Riverpod

#### Imports
- Jamais d'import cross-feature (ex. `scan/` n'importe jamais depuis `transactions/`)
- Toute entité ou provider partagé réside dans `shared/` et est importé depuis là

### Riverpod

- L'état partagé entre plus d'un widget passe TOUJOURS par un provider Riverpod — jamais `setState` ni `InheritedWidget` pour l'état global
- `soldeProvider` et tous les agrégats du dashboard sont des `Provider` dérivés (calcul en mémoire) — jamais persistés en base
- `categoryListProvider` est le SEUL `StreamProvider` sur `CategoryDao.watchAll()` — aucune feature n'ouvre son propre stream Drift sur les catégories
- `sessionStateProvider` est un `AsyncNotifierProvider<SessionState>` — lit `flutter_secure_storage` une seule fois au démarrage, jamais dans `redirect`
- `main.dart` attend la résolution de `sessionProvider` (via `ProviderContainer`) avant de monter `MaterialApp` pour éviter la race condition auth

### Drift ORM

- Tout accès SQLite passe par les DAOs générés (`TransactionDao`, `CategoryDao`, `SettingsDao`) — jamais de SQL en string brut ni de `sqflite` direct
- Schéma V1 complet dès `AppDatabase.onCreate` : tables `app_settings`, `categories`, `transactions` avec `currency TEXT NOT NULL DEFAULT 'XOF'`
- `AppDatabase.onCreate` est le SEUL point qui insère les catégories prédéfinies (via `insertOrIgnore` — idempotent)
- Les insertions multi-lignes d'un reçu s'effectuent dans un bloc `database.transaction()` unique — atomicité garantie, aucun event stream partiel visible par `soldeProvider`
- Les providers écoutent les changements via les streams Drift (réactivité automatique) — jamais de rechargement manuel

### TransactionRepository (AD-10)

- `shared/data/transaction_repository.dart` est le SEUL code qui appelle `TransactionDao.insert()` ou `TransactionDao.delete()`
- `features/transactions/` l'utilise pour les saisies manuelles
- `features/scan/` délègue via `TransactionRepository.insertReceiptLines(receiptId, lines)` — jamais d'appel direct à `TransactionDao` depuis une feature

### GoRouter

- Toutes les routes nommées dans `shared/routing/app_router.dart` — jamais de `Navigator.push` pour les routes principales
- La garde auth (redirection vers `/auth`) est dans le `redirect` de GoRouter, qui lit uniquement `ref.watch(sessionProvider)` — jamais FSS directement dans `redirect`

### BFF Client

- L'app Flutter n'appelle QUE le BFF via `shared/network/bff_client.dart`
- URL lue via `String.fromEnvironment('BFF_URL')` — jamais hardcodée
- Aucun appel HTTP direct vers Mindee, Mistral ou Africa's Talking depuis une feature Flutter
- Timeout scan BFF : 10 secondes (Mindee polling inclus)
- Format retour BFF : `[{label: string, amount_cents: int, category: string}]` — `amount_cents` en centimes, jamais en FCFA

### Devise

- La devise active est lue depuis `AppSettings.currency` (Drift) via `settingsProvider`
- Aucun provider ni widget ne référence `'XOF'` en dur — toujours via `settingsProvider`

### Tests

#### Repositories Flutter (Drift)
- Les repositories sont testés avec `driftTestExecutor` (base in-memory) — jamais de mocks Drift
- Un vrai `AppDatabase` in-memory est instancié dans chaque test (`NativeDatabase.memory()` ou `driftTestExecutor`)
- `AppDatabase.onCreate` est appelé dans les tests — les catégories prédéfinies sont seedées automatiquement

#### Handlers BFF (Cloudflare Worker)
- Les handlers BFF sont testés avec Miniflare (environnement local Workers)
- Les appels Mindee/Mistral/Africa's Talking sont mockés au niveau réseau dans les tests BFF
- Ne jamais appeler les APIs tierces réelles dans les tests automatisés

#### Limites unit vs intégration
- Tests unitaires : providers Riverpod isolés (avec `ProviderContainer` de test)
- Tests d'intégration : repository + DAO + base in-memory (pas de mocks pour la couche données)
- Les widgets ne sont pas testés en Phase MVP — priorité aux couches repository et BFF handlers

#### Règles générales
- Jamais de mocks pour la couche Drift — le comportement réel de SQLite est requis pour valider les contraintes (unicité, FK, transactions atomiques)
- Les tests de `TransactionRepository.insertReceiptLines` vérifient l'atomicité : si une insertion échoue, aucune ligne du lot n'est persistée

### Code Quality & Style

#### Structure des fichiers
- `lib/features/{feature}/` : `providers/`, `repository/`, `screens/`, `widgets/`
- `lib/shared/` : `data/`, `domain/`, `providers/`, `routing/`, `network/`, `widgets/`
- `bff/src/handlers/` : `ocr.ts`, `categorize.ts`, `otp.ts` — un fichier par domaine BFF
- Un fichier Dart = une classe principale (pas de fichiers "barrel" ou multi-classes)

#### Commentaires
- Aucun commentaire sur le code évident — les noms doivent suffire
- Commentaire uniquement pour : invariants non-évidents, workarounds, contraintes cachées
- Pas de docstrings multi-lignes sur les méthodes publiques standard

#### Design System — tokens obligatoires
- Toutes les couleurs sont des tokens du design system (pas de valeurs hex inline dans les widgets)
- Niveaux d'élévation : `bg (#0D0F1E)` → `surface (#181B33)` → `surface-raised (#1E2240)` — jamais d'ombres sur les cartes ordinaires
- Arrondis : `xl` (24px) pour les cartes, `lg` (16px) pour les CTAs, `md` (14px) pour les champs, `sheet` (28px) pour les coins supérieurs de bottom sheet, `full` pour FAB et pastilles
- `accent (#6B5CFF)` réservé aux actions et indicateurs de valeur — jamais pour décorer ou signaler des états passifs
- `warning (#F5A623)` exclusivement pour les lignes OCR mal reconnues — pas pour les erreurs génériques

#### Affichage des montants (règle critique UI)
- Séparateur milliers = espace fine insécable Unicode ` ` (pas un espace normal, pas `&nbsp;`)
- Tout montant de transaction est préfixé `−` (Dépense) ou `+` (Revenu) — la couleur seule ne suffit jamais (accessibilité daltonisme)
- Montants Dépenses : `danger (#FF6B6B)` ; Revenus : `success (#00C897)` ; Solde : `text-primary (#FFFFFF)` sans préfixe
- Devise `FCFA` toujours en style `caption` inline — jamais en `display`
- `font-feature-settings: "tnum"` sur les montants (tabular figures pour l'alignement)

#### Bottom sheets
- Ne s'empilent jamais à plus d'un niveau simultanément (UX-DR20)
- Si l'utilisateur ouvre le sélecteur de catégorie depuis le formulaire de transaction : fermer le formulaire → ouvrir le sélecteur → à la sélection, rouvrir le formulaire

### Workflow de développement

#### Structure du projet
- Projet greenfield — créé depuis zéro avec `flutter create` (pas de template existant)
- Le BFF (`bff/`) est un projet TypeScript Cloudflare Worker séparé, déployé indépendamment de l'app Flutter
- `lib/` et `bff/` coexistent à la racine du repo mais ont leurs propres cycles de build

#### Build Flutter
- Toujours injecter `BFF_URL` à la compilation : `flutter run --dart-define=BFF_URL=https://...`
- Ne jamais committer `.env` ou fichiers contenant des clés API dans le repo Flutter
- La police Urbanist doit être déclarée dans `pubspec.yaml` sous `flutter.fonts` avec ses variantes (Regular 400, Medium 500, SemiBold 600, ExtraBold 800)

#### Build BFF (Wrangler 4.x)
- Dev local : `wrangler dev` — les secrets sont dans `.dev.vars` (non commité, `.gitignore`)
- Prod : `wrangler deploy --env prod` — secrets via `wrangler secret put <KEY> --env prod`
- `wrangler.toml` contient deux environnements : `[env.dev]` et `[env.prod]` — jamais de clés en clair dedans

#### Génération du code Drift
- Après toute modification du schéma Drift, relancer `dart run build_runner build --delete-conflicting-outputs`
- Les fichiers `.g.dart` sont générés — ne pas les éditer manuellement
- Commiter les fichiers `.g.dart` générés avec le schéma qui les a produits

#### Implémentation par story
- Une story à la fois, dans l'ordre des epics (1.1 → 1.2 → … → 5.3)
- Chaque story doit satisfaire tous ses critères d'acceptance avant de passer à la suivante
- Ne pas implémenter des fonctionnalités futures anticipées — respecter le périmètre de la story courante

### Anti-patterns critiques — NE JAMAIS FAIRE

#### Sécurité
- ❌ Embarquer une clé API (Mindee, Mistral, Africa's Talking) dans le binaire Flutter (APK/IPA)
- ❌ Stocker le token de session OTP dans `SharedPreferences` ou dans Drift — uniquement `flutter_secure_storage`
- ❌ Appeler Mindee/Mistral/Africa's Talking directement depuis l'app Flutter — passer obligatoirement par le BFF
- ❌ Logger des tokens, numéros de téléphone ou montants dans les logs de production

#### Données financières
- ❌ Utiliser `double` pour un montant financier (arrondi floating-point)
- ❌ Stocker un montant en FCFA entiers — toujours en centimes (`int`)
- ❌ Hardcoder `'XOF'` dans un provider ou widget — lire depuis `settingsProvider`
- ❌ Persister en base le solde ou les agrégats du dashboard — ce sont des valeurs dérivées calculées par des providers

#### Architecture Flutter
- ❌ Importer depuis une autre feature (`scan/` → `transactions/`, etc.)
- ❌ Utiliser `Navigator.push` pour les routes principales — GoRouter uniquement
- ❌ Lire `flutter_secure_storage` directement dans la fonction `redirect` de GoRouter — passer par `sessionProvider`
- ❌ Ouvrir un `StreamProvider` sur `CategoryDao` dans une feature — utiliser `categoryListProvider` de `shared/`
- ❌ Appeler `TransactionDao.insert()` directement depuis une feature — passer par `TransactionRepository`
- ❌ Insérer les lignes d'un reçu une par une hors transaction Drift — risque de solde partiel visible

#### Design
- ❌ Afficher un montant coloré sans signe `+`/`−` — la couleur seule ne suffit pas (daltonisme)
- ❌ Empiler deux bottom sheets simultanément
- ❌ Utiliser `accent (#6B5CFF)` pour décorer ou signaler un état passif
- ❌ Utiliser `warning (#F5A623)` pour autre chose que les lignes OCR mal reconnues
- ❌ Ajouter des ombres sur les cartes ordinaires — l'élévation vient de la différence de teinte, pas du shadow
- ❌ Utiliser un espace normal comme séparateur de milliers — uniquement espace fine ` `

#### BFF
- ❌ Stocker des données utilisateur dans le Cloudflare Worker entre deux requêtes — le BFF est stateless
- ❌ Conserver la photo du reçu après l'appel Mindee (vérifier la politique de rétention Mindee v2 avant la beta — ⚠ BLOQUANT)
- ❌ Appeler Mistral ligne par ligne — toujours envoyer toutes les lignes OCR en un seul prompt batch

---

## Usage Guidelines

**Pour les agents AI :**
- Lire ce fichier avant d'implémenter n'importe quel code GestBud
- Suivre TOUTES les règles exactement telles que documentées
- En cas de doute, choisir l'option la plus restrictive
- Les règles marquées SEUL/TOUJOURS/JAMAIS sont des invariants non négociables

**Pour les humains :**
- Mettre à jour ce fichier si la stack technologique évolue
- Ajouter une règle dès qu'un pattern non-évident est identifié en review
- Supprimer les règles qui deviennent évidentes avec le temps

_Dernière mise à jour : 2026-07-01_
