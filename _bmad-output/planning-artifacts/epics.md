---
stepsCompleted: [step-01-validate-prerequisites, step-02-design-epics, step-03-create-stories, step-04-final-validation]
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-GestBud-2026-06-30/prd.md
  - _bmad-output/planning-artifacts/architecture/architecture-GestBud-2026-06-30/ARCHITECTURE-SPINE.md
  - _bmad-output/planning-artifacts/ux-designs/ux-GestBud-2026-06-30/DESIGN.md
  - _bmad-output/planning-artifacts/ux-designs/ux-GestBud-2026-06-30/EXPERIENCE.md
---

# GestBud - Epic Breakdown

## Overview

Ce document fournit le découpage complet en epics et stories pour GestBud, décomposant les exigences du PRD, du contrat UX Design et de l'Architecture Spine en stories implémentables.

## Requirements Inventory

### Functional Requirements

FR-1: Inscription par numéro de téléphone — L'utilisateur peut s'inscrire en saisissant son numéro de téléphone au format international (E.164). Le système envoie un OTP via Africa's Talking SMS. Un numéro déjà inscrit déclenche un flux de connexion, pas une double inscription.

FR-2: Validation OTP et accès — L'utilisateur peut saisir l'OTP reçu pour accéder à l'application. Un OTP invalide ou expiré (> 10 minutes) affiche un message d'erreur avec option de renvoi. Après validation, la session est persistée (flutter_secure_storage) — l'utilisateur n'est pas redemandé à la prochaine ouverture.

FR-3: Renvoi d'OTP — L'utilisateur peut demander un renvoi d'OTP après 60 secondes. Le bouton « Renvoyer » est désactivé pendant 60 s avec un compteur visible.

FR-4: Déconnexion — L'utilisateur peut se déconnecter, ce qui efface uniquement le token de session (flutter_secure_storage). Les données de Transactions sont conservées en base locale après déconnexion.

FR-5: Création d'une Dépense manuelle — montant (FCFA, non nul et non négatif), Catégorie, date (défaut : aujourd'hui ; dates antérieures autorisées), note optionnelle. Transaction visible dans l'historique et Solde mis à jour immédiatement.

FR-6: Création d'un Revenu manuel — même logique que FR-5 pour le type Revenu. Visuellement distinct d'une Dépense dans l'historique. Le Solde augmente immédiatement.

FR-7: Modification d'une Transaction existante — modifier n'importe quel champ (montant, Catégorie, date, note) d'une Transaction déjà validée (manuelle ou ligne de Reçu). Solde et Postes recalculés immédiatement.

FR-8: Suppression d'une Transaction — après confirmation explicite (action non réversible). Solde et Postes recalculés immédiatement.

FR-9: Capture photo du Reçu — déclenchement caméra native ou sélection depuis galerie. Permission caméra/galerie demandée au premier accès avec explication. La photo est transmise à l'API OCR sans stockage local permanent.

FR-10: Extraction OCR et affichage des Lignes — envoi photo au BFF → Mindee v2 async polling → Mistral batch catégorisation. Affichage des Lignes (libellé + montant) avec Catégorie suggérée. État de chargement visible pendant l'appel. Timeout 10 s → message d'erreur + option saisie manuelle.

FR-11: Validation et correction des Lignes — pour chaque Ligne : valider la Catégorie suggérée, changer la Catégorie, modifier le montant, supprimer la Ligne (doublon OCR), ajouter une Ligne manquante. Total du Reçu recalculé dynamiquement à chaque modification.

FR-12: Validation globale du Reçu — chaque Ligne validée est créée comme une Dépense distincte dans l'historique via TransactionRepository.insertReceiptLines() (insertion atomique). Solde et Postes mis à jour pour chaque Ligne imputée. Transactions du même Reçu regroupées visuellement dans l'historique.

FR-13: Affichage des Catégories disponibles — lors de toute saisie nécessitant une catégorisation, liste complète (prédéfinies d'abord, personnalisées ensuite) dans un sélecteur.

FR-14: Création d'une Catégorie personnalisée — nom unique (validation insensible à la casse). Immédiatement disponible dans tous les sélecteurs.

FR-15: Modification d'une Catégorie personnalisée — renommage avec propagation automatique à toutes les Transactions existantes. Les Catégories prédéfinies ne sont pas renommables.

FR-16: Suppression d'une Catégorie personnalisée — après confirmation. Les Transactions associées sont réaffectées à « Autre ». Suppression bloquée pour les Catégories prédéfinies.

FR-17: Affichage du Solde — Solde courant affiché et recalculé après chaque mutation de Transaction. Solde négatif avec indication visuelle distincte.

FR-18: Totaux par Catégorie — Poste de dépense pour chaque Catégorie ayant au moins une Transaction sur la Période sélectionnée, triés par montant décroissant. Somme des Postes = total des Dépenses de la Période.

FR-19: Graphique d'évolution du Solde — graphique linéaire, valeur du Solde en fin de journée pour chaque jour de la Période. Lisible sur écran Android 5" (éléments ≥ 44 px).

FR-20: Comparaison mois/mois — variation en montant et en pourcentage par Poste vs même Poste du mois précédent, avec indicateur visuel directionnel. Si mois précédent vide pour un Poste → « — ».

FR-21: Sélection de Période — navigation mois calendaire (◀▶) ou sélection Période custom (date début + date fin). Date fin antérieure à date début bloquée. Changement de Période met à jour FR-18, FR-19 et FR-20 immédiatement.

FR-22: Persistance locale des données — toutes les Transactions, Catégories et préférences utilisateur stockées en base SQLite locale (Drift), sans appel réseau (hors OCR et OTP). Données intactes après fermeture, redémarrage et mise à jour. Saisie manuelle 100 % hors connexion.

FR-23: Avertissement de risque de perte de données — bannière affichée une seule fois à la première connexion réussie (flag persisté en base). Dismissable sans action requise. Texte : « Tes données sont sur ton téléphone. Ne désinstalle pas l'app. »

FR-24: Accès unifié aux fonctionnalités depuis l'écran d'accueil — toutes fonctionnalités principales (Scan Reçu, Saisie Dépense, Saisie Revenu, Tableau de bord, Historique) accessibles en ≤ 2 taps. Solde courant visible sans navigation supplémentaire.

### NonFunctional Requirements

NFR-1: Performance scan — Du déclenchement caméra à la validation globale du Reçu : ≤ 30 secondes pour un Reçu standard (10–20 Lignes, 4G normale). L'appel BFF/Mindee seul doit se compléter en ≤ 10 s ; au-delà, un timeout affiche une option de saisie manuelle.

NFR-2: Performance navigation — Les transitions entre écrans et les recalculs de Solde doivent être perçus comme instantanés (< 100 ms sur le thread principal).

NFR-3: Accessibilité — Taille minimale des éléments interactifs : 44 × 44 px (iOS) / 48 × 48 dp (Android). Contraste texte ≥ 4.5:1 sur tous les fonds.

NFR-4: Framework et distribution — Flutter ^3.22 / Dart ^3.4. iOS 15+ (App Store) et Android 9+ (Google Play Store). Parité complète entre les deux plateformes sauf conventions système (safe areas, permissions, clavier natif).

NFR-5: Internationalisation — Interface en français uniquement (v1). Devise Beta V1 : XOF avec espace fine insécable comme séparateur de milliers. XAF prévu en V2 — la Devise doit être configurable dans l'architecture dès V1 (AppSettings.currency). Dates au format JJ/MM/AAAA (intl, locale fr).

NFR-6: Résilience réseau — La saisie manuelle (FR-5, FR-6) fonctionne entièrement hors connexion (aucun indicateur réseau nécessaire). Le scan (FR-9 à FR-12) et l'OTP (FR-1, FR-2) requièrent une connexion ; un message clair l'indique si le réseau est absent.

### Additional Requirements

- **AD-1 — Riverpod exclusif pour l'état global :** jamais de setState ou InheritedWidget pour l'état partagé entre widgets. Le Solde et les agrégats du Tableau de bord sont des providers dérivés (jamais persistés en base).

- **AD-2 — Structure feature-based :** les features (auth/, scan/, transactions/, dashboard/, categories/) ne s'importent jamais les unes les autres. Entités, providers et widgets partagés dans shared/. Communication inter-feature uniquement via les providers de shared/providers/.

- **AD-3 — Drift ORM exclusivement pour SQLite :** tout accès en base passe par des DAOs Drift générés (TransactionDao, CategoryDao, SettingsDao). Schéma : `currency TEXT NOT NULL DEFAULT 'XOF'` sur app_settings dès V1 ; `receipt_id TEXT` nullable sur transactions (UUID partagé pour lignes d'un même reçu). Insertions multi-lignes d'un reçu dans un database.transaction() atomique.

- **AD-4 — BFF Cloudflare Worker stateless :** aucune clé API (Mindee, Mistral, Africa's Talking) dans le binaire Flutter. URL BFF injectée via `--dart-define=BFF_URL`. BFF orchestre : Mindee v2 (async polling /jobs/<jobId>) → Mistral batch → réponse unique `[{label, amount_cents, category}]`. Photo non conservée après l'appel Mindee.

- **AD-5 — Catégorisation Mistral batch :** BFF envoie toutes les lignes OCR en un seul prompt Mistral. Fallback dictionnaire mots-clés si Mistral échoue → category: "Autre" pour lignes non reconnues. Réponse en `amount_cents` (centimes, jamais unités FCFA). L'app Flutter ne distingue pas les deux chemins.

- **AD-6 — GoRouter déclaratif :** toutes les routes nommées dans `shared/routing/app_router.dart`. Garde auth (redirect vers /auth si session absente) dans le redirect GoRouter, jamais dans les widgets.

- **AD-7 — flutter_secure_storage pour le token :** token de session lu et écrit exclusivement via flutter_secure_storage (Keychain iOS / Keystore Android). Jamais SharedPreferences ni Drift pour le token.

- **AD-8 — Montants en centimes INTEGER :** tout montant stocké en INTEGER (centimes XOF). Couche d'affichage divise par 100 avec séparateur espace fine. Jamais de double pour un montant financier.

- **AD-10 — TransactionRepository = seul écrivain :** `shared/data/transaction_repository.dart` est le seul endroit qui appelle `TransactionDao.insert()` ou `TransactionDao.delete()`. features/scan/ délègue via `TransactionRepository.insertReceiptLines(receiptId, lines)`.

- **AD-11 — CategoryDao seeding unique :** `AppDatabase.onCreate` est le seul point qui insère les catégories prédéfinies (idempotent via insertOrIgnore). `shared/providers/categoryListProvider` est le seul StreamProvider sur `CategoryDao.watchAll()`.

- **AD-12 — sessionStateProvider + bootstrap FSS :** `shared/providers/session_provider.dart` expose un `AsyncNotifierProvider<SessionState>` (lit flutter_secure_storage une seule fois au démarrage). `main.dart` attend la résolution de ce provider avant de monter le MaterialApp. La fonction redirect de GoRouter lit uniquement `ref.watch(sessionProvider)`.

- **AD-13 — Environnements BFF :** Wrangler 4.x, deux environnements dans wrangler.toml : `[env.dev]` (local, wrangler dev) et `[env.prod]`. Clés API dans secrets Wrangler en prod et .dev.vars en dev — jamais en clair dans wrangler.toml.

- **AD-14 — Devise configurable dès V1 :** devise active lue depuis `AppSettings.currency` (Drift). Aucun provider ni widget ne référence 'XOF' en dur.

- **Stack technique :** Flutter ^3.22, Dart ^3.4, flutter_riverpod ^3.3.2, drift + drift_flutter ^2.x, go_router ^14.8.0, flutter_secure_storage ^10.3.1, Cloudflare Workers v8 (Wrangler 4.x), Mindee API v2 (async polling), Mistral mistral-small-latest, Africa's Talking SMS API v1.

- **Projet Greenfield :** pas de starter template existant — projet Flutter créé from scratch avec la structure feature-based définie dans l'architecture.

### UX Design Requirements

UX-DR1: Implémenter le système de tokens de design complet dans Flutter — palette couleurs (bg #0D0F1E, surface #181B33, surface-raised #1E2240, accent #6B5CFF, accent-dim #2A2460, text-primary #FFFFFF, text-secondary #A8A8C0, success #00C897, danger #FF6B6B, warning #F5A623, border #2A2D4A) + 11 paires bg/fg pour catégories prédéfinies + 6 paires pour catégories personnalisées (rose, teal, terracotta, olive, slate, prune). L'accent #6B5CFF est exclusivement réservé aux actions et indicateurs de valeur — jamais pour les états passifs ni les erreurs.

UX-DR2: Implémenter la typographie Urbanist (Google Fonts, déclarée dans pubspec.yaml) — 4 rôles : Display 32px/ExtraBold (800), Title 20px/SemiBold (600), Body 15px/Regular (400), Caption 12px/Medium (500). Tabular-nums (`font-feature-settings: "tnum"`) activé pour tous les montants (alignement dans les listes).

UX-DR3: Formatage des montants — espace fine insécable (` `) comme séparateur de milliers (ex: 245 800 FCFA). Devise FCFA toujours en Caption inline, jamais en Display. Signe + Revenu / − Dépense non-coloré systématique sur tout montant de transaction (accessibilité daltonisme). Solde non préfixé. Jamais de double pour représenter un montant financier.

UX-DR4: Implémenter la Carte Solde — gradient `accent (#6B5CFF) → #4A3FD4`, radius xl (24px), padding 24px. Label Caption « Solde courant » en text-primary opacité pleine (pas de réduction d'opacité — risque contraste 4.5:1 sur gradient). Montant en Display blanc. Variation du mois en Caption colorée préfixée +/−. Sparkline SVG blanc en bas. Contenu strict : jamais d'autre élément.

UX-DR5: Implémenter le FAB — cercle 56px, fond accent, ombre violet diffuse (0 4px 16px rgba(107,92,255,0.4)). Positionné au centre horizontal, émergeant à −28px au-dessus du bord supérieur de la nav bar. Icône + uniquement, pas de label texte. Tap → bottom sheet FAB Menu (2 options : « Scan Reçu » · « Nouvelle transaction »). Pas de long-press.

UX-DR6: Implémenter la Bottom Sheet « Nouvelle transaction » — fond surface, coins supérieurs radius sheet (28px), drag handle centré. Segmented control Dépense/Revenu pleine largeur (height 40px, radius md). Montant en Display centré avec curseur (clavier numérique natif). Champs Catégorie (ouvre Sélecteur Catégorie), Date (ouvre Sélecteur Date), Note (optionnelle). CTA « Enregistrer » pleine largeur (height 52px, radius lg, fond accent). Dismiss par swipe down ou tap outside.

UX-DR7: Implémenter la Pastille de catégorie — cercle 40px, fond `cat-{nom}-bg`, icône 20px en `cat-{nom}-fg`. Présente dans : lignes Historique, lignes Revue Reçu, Sélecteur Catégorie, Tableau de bord. Label VoiceOver/TalkBack = nom de la catégorie (jamais juste l'emoji).

UX-DR8: Implémenter la Ligne de transaction (Historique) — pastille catégorie à gauche · libellé Body + date Caption/secondary en colonne · montant Body (coloré danger/success, préfixé +/−) aligné à droite. Hauteur min 60px (cible de tap ≥ 44pt/48dp). Divider border en bas. Tap → Détail Transaction. Pas de swipe-to-delete sur l'Historique.

UX-DR9: Implémenter le Sélecteur Catégorie — bottom sheet héritant du composant bottom-sheet. Grille 4 colonnes de pastilles de catégorie, label Caption sous chaque pastille. Catégories prédéfinies d'abord, personnalisées ensuite, séparées par un divider border léger. Catégorie sélectionnée : anneau accent 2px autour de la pastille. Pas de recherche en v1.

UX-DR10: Implémenter le Sélecteur Date — bottom sheet héritant du composant bottom-sheet. Date-picker natif iOS/Android. Défaut : aujourd'hui. Dates futures non sélectionnables. CTA « Valider » pleine largeur.

UX-DR11: Implémenter la Ligne de Reçu (surface Scan — Revue) — fond surface, radius md. Libellé OCR (Body) + montant (Body, champ éditable inline) + badge Catégorie (dropdown ouvre Sélecteur Catégorie). État warning : fond #3A2A00, bordure gauche 3px warning, icône ⚠ ambre visible. Swipe-to-delete + bouton menu ⋯ toujours visible comme alternative accessible. Action de menu ⋯ exposée aussi comme action d'accessibilité personnalisée pour VoiceOver/TalkBack.

UX-DR12: Implémenter le Skeleton de chargement (Scan — entre Capture et Revue) — barres de hauteur variable sur fond surface-raised reproduisant exactement la géométrie de la liste de lignes. Animation pulse (opacité 0.4→0.8→0.4, 1.2s). Avec Reduce Motion activé : fond statique surface-raised sans animation.

UX-DR13: Implémenter la Bannière info — fond surface-raised, bordure border, radius md, padding 12px vertical 16px horizontal. Texte Caption/secondary à gauche. Icône × dismissable à droite (cible ≥ 44pt). Affichée une seule fois (flag local), positionnée fixe au-dessus de la nav bar sur l'Accueil, ne bloque aucune interaction.

UX-DR14: Implémenter l'État vide — icône SVG accent centrée (receipt ou wallet selon la surface), titre Body/SemiBold blanc, CTA bouton-primary. Fond page directement, pas de card wrapper. Textes selon surface : Accueil vide → « Ton premier reçu t'attend. » / CTA « Scanner un reçu » ; Historique vide → « Aucune transaction pour le moment. » / CTA « Ajouter une transaction ».

UX-DR15: Implémenter la Ligne de Catégorie (surface Gestion Catégories) — fond surface, padding 16px vertical. Pastille catégorie à gauche · nom Body au centre · icônes crayon (renommer) + corbeille (supprimer) 24px à droite pour les catégories personnalisées (espacées de 12px). Catégories prédéfinies : sans icônes crayon/corbeille, ligne non interactive au-delà de l'affichage.

UX-DR16: Implémenter le Champ Création/Renommage Catégorie — bottom sheet avec : (1) grille 4 colonnes d'emojis (anneau accent 2px sur icône sélectionnée), (2) rangée de 6 pastilles couleur palette personnalisée (anneau text-primary 2px sur couleur sélectionnée, label sémantique nommant la teinte : Rose/Sarcelle/Terracotta/Olive/Ardoise/Prune), (3) champ nom (input standard, placeholder « Nom de la catégorie »). Présélection par défaut à l'ouverture (première icône, cat-custom-rose). Validation : nom vide → CTA désactivé ; nom dupliqué (insensible à la casse, toutes catégories confondues) → focus-border danger + « Cette catégorie existe déjà. » + CTA désactivé. Renommage : pré-rempli avec valeurs actuelles. Cascade automatique sur toutes les transactions existantes.

UX-DR17: Implémenter l'En-tête sticky Reçu (Scan — Revue) — total dynamique recalculé à chaque modification de ligne (libellé + nombre d'articles). Title/SemiBold. Fixe en haut de la liste (sticky header).

UX-DR18: Implémenter le Sélecteur de Période (Tableau de bord) — navigation mois ◀▶ par défaut (mois courant affiché). Tap sur le label du mois → bottom sheet sélection période custom (date début + date fin). Date fin < date début → message inline « La date de fin doit être après la date de début. » Changement de période met à jour FR-18, FR-19, FR-20 immédiatement.

UX-DR19: Implémenter l'Entrée Reçu groupé dans l'Historique — tap sur l'entrée reçu expand/collapse les lignes individuelles en-dessous. Deuxième tap collapse. Chevron animé indique l'état (développé/réduit). État annoncé par VoiceOver/TalkBack à chaque tap (ex. « Reçu, 5 articles, développé »).

UX-DR20: Architecture d'information — bottom tab bar 3 onglets (Accueil · Historique · Tableau de bord) + FAB central (68px de haut total avec la nav bar, overlap −28px). Paramètres accessibles via icône settings en haut à droite de l'Accueil, pas dans la tab bar. Bottom sheets ne s'empilent jamais à plus d'un niveau simultanément.

UX-DR21: Microcopy en français, tutoiement systématique. Chaud et direct sur les succès (« Reçu enregistré ! », « Transaction enregistrée ! »). Neutre et clair sur les erreurs (« Impossible de lire le reçu. Saisis-le manuellement. »). Pas d'emojis dans les messages critiques (erreurs, suppressions, solde négatif). Utiliser la table de référence de EXPERIENCE.md.

UX-DR22: Accessibilité — VoiceOver/TalkBack : montants lus avec devise complète (« 245 800 francs CFA »), pastilles annoncent le nom de la catégorie. Cibles ≥ 44pt (iOS) / 48dp (Android) pour tous éléments interactifs. Ordre de focus haut-gauche→bas-droite. Bottom sheets piègent le focus tant qu'ils sont ouverts. Segmented control Dépense/Revenu : état sélectionné annoncé explicitement (ex. « Dépense, sélectionné, 1 sur 2 »). Confirmations critiques exposées en live-region.

UX-DR23: Support Reduce Motion — skeleton de chargement passe de l'animation pulse à un fond statique surface-raised. Transitions d'écran utilisent cross-fade courts (Flutter) au lieu de slides.

UX-DR24: Élévation par différence de teinte uniquement (bg→surface→surface-raised). Ombres réservées exclusivement au FAB et à la Carte Solde. Aucune autre surface ne porte d'ombre.

UX-DR25: Dark mode par défaut et unique — pas de mode clair, pas de détection des préférences système pour basculer de thème.

UX-DR26: Interactions primaires — Tap pour toute action intentionnelle. Swipe down pour fermer un bottom sheet (tap outside également accepté). Swipe-to-delete uniquement sur les Lignes de Reçu (pas sur l'Historique). Gestes natifs iOS/Android (back swipe, navigation par geste) honorés sans override. Pull-to-refresh absent (données 100 % locales).

### FR Coverage Map

FR-1 → Epic 1 — Inscription numéro de téléphone + OTP
FR-2 → Epic 1 — Validation OTP et persistance de session
FR-3 → Epic 1 — Renvoi d'OTP avec compteur 60s
FR-4 → Epic 1 — Déconnexion et effacement token
FR-5 → Epic 2 — Création Dépense manuelle
FR-6 → Epic 2 — Création Revenu manuel
FR-7 → Epic 2 — Modification Transaction existante
FR-8 → Epic 2 — Suppression Transaction avec confirmation
FR-9 → Epic 3 — Capture photo Reçu (caméra ou galerie)
FR-10 → Epic 3 — Extraction OCR + catégorisation IA via BFF
FR-11 → Epic 3 — Validation et correction Lignes OCR
FR-12 → Epic 3 — Validation globale Reçu + regroupement historique
FR-13 → Epic 2 — Affichage Catégories disponibles dans sélecteur
FR-14 → Epic 5 — Création Catégorie personnalisée
FR-15 → Epic 5 — Renommage Catégorie personnalisée
FR-16 → Epic 5 — Suppression Catégorie personnalisée
FR-17 → Epic 2 — Affichage Solde en temps réel (aussi présent en Epic 4)
FR-18 → Epic 4 — Totaux par Catégorie sur Période sélectionnée
FR-19 → Epic 4 — Graphique d'évolution du Solde
FR-20 → Epic 4 — Comparaison mois/mois
FR-21 → Epic 4 — Sélection de Période (mois calendaire + custom)
FR-22 → Epic 1 — Initialisation DB Drift + AppSettings ; actif dans toutes les features
FR-23 → Epic 1 — Bannière avertissement perte données (première connexion)
FR-24 → Epic 2 — Accès unifié complet ; shell de navigation créé en Epic 1

## Epic List

### Epic 1 : Fondation du projet et Authentification

L'utilisateur peut s'inscrire avec son numéro de téléphone, recevoir un OTP par SMS, se connecter et accéder à l'écran d'accueil de l'application. Cet epic pose toute la fondation technique : projet Flutter greenfield, structure feature-based, schéma Drift avec seeding des catégories prédéfinies, GoRouter + garde auth, squelette BFF Cloudflare Worker (handler OTP), système de tokens de design, architecture de navigation.

**FRs couverts :** FR-1, FR-2, FR-3, FR-4, FR-22, FR-23, FR-24 (shell)

### Epic 2 : Saisie manuelle et Historique des Transactions

L'utilisateur peut enregistrer des dépenses et des revenus manuellement, voir son solde mis à jour en temps réel, parcourir l'historique, et modifier ou supprimer ses transactions.

**FRs couverts :** FR-5, FR-6, FR-7, FR-8, FR-13, FR-17, FR-24 (complet)

### Epic 3 : Scan de Reçu et Pipeline OCR

L'utilisateur peut photographier un ticket de caisse, voir les lignes extraites, les corriger, et valider le reçu pour l'imputer à son solde en moins de 30 secondes.

**FRs couverts :** FR-9, FR-10, FR-11, FR-12

### Epic 4 : Tableau de bord analytique

L'utilisateur peut consulter ses postes de dépense par catégorie, un graphique d'évolution de son solde, et comparer ses dépenses mois après mois sur la période de son choix.

**FRs couverts :** FR-17 (complet), FR-18, FR-19, FR-20, FR-21

### Epic 5 : Gestion des Catégories personnalisées

L'utilisateur peut créer ses propres catégories avec une icône et une couleur, les renommer, et les supprimer avec réaffectation automatique des transactions concernées.

**FRs couverts :** FR-14, FR-15, FR-16

## Epic 1 : Fondation du projet et Authentification

L'utilisateur peut s'inscrire avec son numéro de téléphone, recevoir un OTP par SMS, se connecter et accéder à l'écran d'accueil de l'application. Cet epic pose toute la fondation technique : projet Flutter greenfield, structure feature-based, schéma Drift avec seeding des catégories prédéfinies, GoRouter + garde auth, squelette BFF Cloudflare Worker (handler OTP), système de tokens de design, architecture de navigation.

**FRs couverts :** FR-1, FR-2, FR-3, FR-4, FR-22, FR-23, FR-24 (shell)

---

### Story 1.1 : Initialisation du projet Flutter et fondation technique

En tant qu'utilisateur,
Je veux pouvoir ouvrir l'app GestBud sur mon iPhone ou téléphone Android et voir un écran d'authentification avec le design correct,
Afin de savoir que l'app est installée et prête à l'emploi.

**Acceptance Criteria:**

- Given l'app est installée sur iOS 15+ ou Android 9+ sans session active, When l'utilisateur ouvre l'app, Then l'écran Auth/Téléphone s'affiche (fond `#0D0F1E`, police Urbanist, thème dark uniquement) sans flash ni écran de chargement intermédiaire.

- Given l'app démarre, When `sessionProvider` lit `flutter_secure_storage`, Then si aucun token n'est trouvé GoRouter redirige vers `/auth/phone` ; si un token valide est trouvé GoRouter redirige vers `/home`.

- Given `main.dart` démarre, When `MaterialApp` est sur le point d'être monté, Then `sessionProvider` est résolu (via `ProviderContainer` + `Future`) avant le montage — aucune race condition possible.

- Given le schéma Drift est initialisé à la première installation, When `AppDatabase.onCreate` s'exécute, Then les 10 catégories prédéfinies sont insérées de façon idempotente (via `insertOrIgnore`) : Alimentation, Transport, Santé & Pharmacie, Hygiène & Entretien, Logement & Factures, Éducation, Loisirs & Sorties, Habillement, Transferts & Épargne, Autre.

- Given la structure feature-based est en place, Then aucune feature (`auth/`, `scan/`, `transactions/`, `dashboard/`, `categories/`) n'importe directement depuis une autre feature — seuls les imports depuis `shared/` sont autorisés.

- Given l'écran d'accueil shell (`/home`) est affiché après authentification, Then la bottom tab bar 3 onglets (Accueil · Historique · Tableau de bord) est visible, le FAB `+` est présent mais sans action fonctionnelle pour l'instant, et l'icône Settings apparaît en haut à droite.

> **Notes techniques :** Création du projet Flutter (`flutter create gestbud`), structure `lib/features/{auth,scan,transactions,dashboard,categories}/` + `lib/shared/`, schéma Drift complet (tables : `app_settings`, `categories`, `transactions`), `settingsProvider`, `sessionProvider` (`AsyncNotifierProvider<SessionState>`), GoRouter (`shared/routing/app_router.dart`) avec guard auth dans `redirect`, `ThemeData` dark avec palette de tokens de couleurs et typographie Urbanist (Google Fonts), squelette BFF (Cloudflare Worker, `wrangler.toml` avec `[env.dev]` + `[env.prod]`, `src/index.ts` + `src/handlers/`), `BffClient` (`shared/network/bff_client.dart`) lisant `BFF_URL` via `String.fromEnvironment`.

---

### Story 1.2 : Saisie du numéro de téléphone et envoi d'OTP

En tant que nouvel utilisateur,
Je veux saisir mon numéro de téléphone et recevoir un code OTP par SMS,
Afin de pouvoir vérifier mon identité et m'inscrire dans l'app.

**Acceptance Criteria:**

- Given l'écran Auth/Téléphone est affiché, When l'utilisateur commence à saisir un numéro, Then le CTA « Envoyer le code » reste désactivé tant que le format E.164 n'est pas valide (validation en temps réel côté client, clavier numérique natif affiché automatiquement).

- Given un numéro E.164 valide est saisi, When l'utilisateur appuie sur « Envoyer le code », Then un état de chargement s'affiche et la requête `POST /otp/send` est envoyée au BFF.

- Given la requête `POST /otp/send` aboutit avec succès, Then un SMS OTP est reçu en moins de 60 secondes (conditions réseau normales) et l'app navigue vers l'écran Auth/OTP.

- Given le réseau est absent au moment de l'envoi, When l'utilisateur appuie sur « Envoyer le code », Then un message inline s'affiche sous le bouton : « Pas de connexion réseau » ; aucune navigation ne se produit.

- Given le BFF reçoit une requête pour un numéro déjà inscrit, Then il traite la demande comme un flux de connexion (comportement apparent identique pour l'utilisateur — pas de double inscription).

> **Notes techniques :** `features/auth/screens/phone_screen.dart`, `features/auth/repository/auth_repository.dart` (délègue vers `BffClient`), `bff/src/handlers/otp.ts` (POST `/otp/send` → Africa's Talking SMS API v1), secrets Wrangler pour la clé API Africa's Talking (`.dev.vars` en dev, secrets Wrangler en prod — jamais en clair dans `wrangler.toml`).

---

### Story 1.3 : Validation OTP, session et renvoi de code

En tant qu'utilisateur ayant reçu un OTP,
Je veux saisir le code reçu pour accéder à l'app sans devoir me reconnecter à chaque ouverture,
Afin que mon expérience quotidienne soit fluide dès le deuxième lancement.

**Acceptance Criteria:**

- Given l'écran Auth/OTP est affiché et l'utilisateur saisit les 6 chiffres OTP corrects, When il valide, Then le token de session est stocké dans `flutter_secure_storage` et GoRouter redirige vers `/home`.

- Given un OTP invalide ou expiré (> 10 minutes) est soumis, Then un message d'erreur inline s'affiche (ex. « Ce code a expiré. Demande-en un nouveau. ») sans aucune navigation.

- Given l'app est relancée après une session valide (token présent dans `flutter_secure_storage`), When `sessionProvider` initialise, Then GoRouter redirige directement vers `/home` sans repasser par `/auth`.

- Given le bouton « Renvoyer » vient d'être utilisé, Then il est désactivé pendant exactement 60 secondes avec un compteur visible décrémentant (`59s`, `58s`…) ; un nouvel OTP est envoyé via `POST /otp/send`.

- Given le compteur de renvoi est en cours, When l'utilisateur appuie sur le bouton « Renvoyer », Then le bouton ne répond pas (désactivé visuellement et fonctionnellement).

> **Notes techniques :** `features/auth/screens/otp_screen.dart`, `bff/src/handlers/otp.ts` ajout de `POST /otp/verify`, `sessionProvider` mis à jour à l'état authentifié après succès (via `flutter_secure_storage` + `ref.invalidate`). Le token est effacé de `flutter_secure_storage` uniquement à la déconnexion (Story 1.4).

---

### Story 1.4 : Paramètres, déconnexion et bannière avertissement stockage

En tant qu'utilisateur authentifié,
Je veux être informé une seule fois que mes données sont stockées sur mon téléphone, et pouvoir me déconnecter,
Afin de comprendre où vivent mes données et de pouvoir terminer ma session quand je le souhaite.

**Acceptance Criteria:**

- Given l'utilisateur se connecte pour la première fois (`AppSettings.onboarding_shown = false`), When l'écran Accueil s'affiche, Then la bannière info s'affiche en bas (au-dessus de la nav bar), non bloquante, avec le texte « Tes données sont sur ton téléphone. Ne désinstalle pas l'app. »

- Given la bannière est visible, When l'utilisateur appuie sur ×, Then la bannière disparaît et `AppSettings.onboarding_shown` est mis à `true` en base Drift — elle ne réapparaît plus jamais, même après relance ou déconnexion/reconnexion.

- Given `AppSettings.onboarding_shown = true`, When l'utilisateur ouvre l'app (même après une déconnexion puis reconnexion), Then la bannière n'est pas affichée.

- Given l'utilisateur est sur l'écran Accueil, When il appuie sur l'icône Settings (haut droite), Then il est navigué vers l'écran Paramètres affichant au minimum un bouton « Se déconnecter ».

- Given l'utilisateur est sur l'écran Paramètres et appuie sur « Se déconnecter », When il confirme l'action, Then le token est effacé de `flutter_secure_storage`, `sessionProvider` retourne à l'état non-authentifié, et GoRouter redirige vers `/auth/phone`.

- Given l'utilisateur vient de se déconnecter et rouvre l'app, Then il voit l'écran Auth/Téléphone ; ses transactions et catégories sont intactes en base Drift — seul le token de session a été effacé.

> **Notes techniques :** `features/auth/screens/settings_screen.dart`, `SettingsDao.setOnboardingShown(bool)` (mise à jour `AppSettings.onboarding_shown`), `sessionProvider.logout()` (efface `flutter_secure_storage` + `ref.invalidate(sessionProvider)`), composant `InfoBanner` dans `shared/widgets/` conforme UX-DR13 (fond `surface-raised`, bordure `border`, radius md, padding 12/16px, icône × cible ≥ 44pt).

## Epic 2 : Saisie manuelle et Historique des Transactions

L'utilisateur peut enregistrer des dépenses et des revenus manuellement, voir son solde mis à jour en temps réel, parcourir l'historique, et modifier ou supprimer ses transactions.

**FRs couverts :** FR-5, FR-6, FR-7, FR-8, FR-13, FR-17, FR-24 (complet)

---

### Story 2.1 : Carte Solde et écran Accueil avec état vide

En tant qu'utilisateur authentifié,
Je veux voir mon solde courant dès que j'ouvre l'app,
Afin de savoir en un coup d'œil où j'en suis financièrement sans aucune navigation.

**Acceptance Criteria:**

- Given l'utilisateur est sur l'écran Accueil avec au moins une transaction, When l'écran s'affiche, Then la Carte Solde est visible (gradient `accent #6B5CFF → #4A3FD4`, radius 24px, padding 24px) avec : label Caption « Solde courant », montant en Display blanc (formaté avec espace fine insécable, sans signe +/−), variation mensuelle en Caption (+/− coloré `success`/`danger`), sparkline SVG blanc.

- Given aucune transaction n'existe encore, When l'écran Accueil s'affiche, Then la Carte Solde montre 0 FCFA et l'état vide s'affiche sous la carte (icône SVG wallet accent centrée, titre « Ton premier reçu t'attend. », CTA « Scanner un reçu »).

- Given une transaction est ajoutée ou supprimée, When la mutation est persistée en base, Then le solde se recalcule et s'affiche mis à jour en moins de 100 ms (provider dérivé, jamais persisté en base).

- Given le solde est négatif, Then le montant affiché dans la Carte Solde porte une indication visuelle distincte (couleur `danger #FF6B6B`).

- Given VoiceOver/TalkBack est actif, Then le montant du solde est annoncé « [montant] francs CFA » (devise complète, jamais l'abréviation FCFA).

> **Notes techniques :** `features/dashboard/widgets/balance_card.dart` (Carte Solde), `shared/providers/balance_provider.dart` (provider dérivé combinant `transactionListProvider` — jamais persisté), `shared/providers/monthly_variation_provider.dart`. Sparkline = courbe SVG simple sur les 7 derniers jours. La Carte Solde est le seul composant avec la FAB autorisé à porter une ombre (UX-DR24).

---

### Story 2.2 : Saisie manuelle d'une Dépense ou d'un Revenu

En tant qu'utilisateur,
Je veux enregistrer rapidement une dépense ou un revenu depuis l'écran d'accueil,
Afin que mon solde reflète immédiatement la réalité de mes finances.

**Acceptance Criteria:**

- Given l'utilisateur est sur n'importe quel onglet, When il appuie sur le FAB `+` (cercle 56px, fond accent, ombre violet diffuse), Then un menu bottom sheet s'ouvre avec 2 options : « Scan Reçu » (label grisé, non fonctionnel pour l'instant) et « Nouvelle transaction ».

- Given l'utilisateur sélectionne « Nouvelle transaction », Then le menu bottom sheet se ferme et le bottom sheet Transaction s'ouvre (jamais deux bottom sheets simultanément — UX-DR20) avec : segmented control Dépense/Revenu pleine largeur (Dépense sélectionné par défaut), champ montant en Display centré (clavier numérique natif), champ Catégorie, champ Date (défaut : aujourd'hui), champ Note (optionnel).

- Given l'utilisateur appuie sur le champ Catégorie, Then le bottom sheet Transaction se ferme et le Sélecteur Catégorie s'ouvre : grille 4 colonnes de pastilles, catégories prédéfinies d'abord puis personnalisées (séparées par un divider), catégorie sélectionnée avec anneau accent 2px.

- Given une catégorie est sélectionnée dans le Sélecteur, Then le Sélecteur se ferme et le bottom sheet Transaction se rouvre avec la catégorie pré-remplie.

- Given tous les champs obligatoires sont remplis (montant > 0, catégorie sélectionnée), When l'utilisateur appuie sur « Enregistrer », Then `TransactionRepository.insert()` est appelé, le bottom sheet se ferme, le solde et la liste de l'Accueil se mettent à jour immédiatement (< 100 ms).

- Given le montant saisi est 0 ou le champ est vide, Then le CTA « Enregistrer » reste désactivé.

- Given le segmented control est positionné sur « Revenu » et l'utilisateur enregistre, Then la transaction est créée avec `type = revenu`, le solde augmente, et la transaction apparaît dans l'Historique avec le signe `+` et la couleur `success`.

- Given l'utilisateur est hors connexion, Then la saisie fonctionne entièrement sans réseau (aucun indicateur d'état réseau affiché — saisie 100 % locale).

> **Notes techniques :** `features/transactions/widgets/fab_menu_sheet.dart`, `features/transactions/widgets/transaction_form_sheet.dart`. Le Sélecteur Catégorie est dans `shared/widgets/category_selector_sheet.dart` (pas de dépendance directe entre `features/transactions/` et `features/categories/`). `TransactionRepository` (AD-10) : seul point d'écriture en base. Montants stockés en INTEGER centimes (AD-8) ; la couche d'affichage divise par 100 avec séparateur espace fine insécable.

---

### Story 2.3 : Historique des Transactions

En tant qu'utilisateur,
Je veux parcourir la liste complète de mes transactions passées,
Afin de retrouver une dépense spécifique et suivre mes habitudes financières.

**Acceptance Criteria:**

- Given l'utilisateur navigue vers l'onglet « Historique » et des transactions existent, When l'écran s'affiche, Then la liste complète s'affiche triée par date décroissante, chaque ligne conforme UX-DR8 : pastille catégorie à gauche, libellé Body + date Caption/secondary en colonne, montant Body (préfixé `+`/`−`, coloré `success`/`danger`) à droite, hauteur min 60px, divider border en bas.

- Given l'onglet Historique est affiché et aucune transaction n'existe, Then l'état vide s'affiche (UX-DR14) : icône SVG wallet accent centrée, titre « Aucune transaction pour le moment. », CTA « Ajouter une transaction » ouvrant le bottom sheet Transaction.

- Given l'utilisateur est sur l'Historique et une nouvelle transaction est ajoutée depuis le FAB, Then la liste se met à jour immédiatement sans action de l'utilisateur (StreamProvider réactif).

- Given VoiceOver/TalkBack est actif sur une ligne de transaction, Then l'annonce combine dans l'ordre : nom de la catégorie, libellé, montant en francs CFA avec signe, date.

- Given l'utilisateur effectue un swipe horizontal sur une ligne de l'Historique, Then aucune action ne se déclenche (swipe-to-delete absent sur l'Historique — UX-DR26).

> **Notes techniques :** `features/transactions/screens/history_screen.dart`, `shared/providers/transaction_list_provider.dart` (StreamProvider sur `TransactionDao.watchAll()` — distinct du `categoryListProvider` de AD-11). Composant `TransactionTile` dans `shared/widgets/`. Pas de pagination en v1 (volume limité en SQLite local).

---

### Story 2.4 : Modification et suppression d'une Transaction

En tant qu'utilisateur,
Je veux corriger une transaction mal saisie ou en supprimer une erronée,
Afin que mon solde reste exact.

**Acceptance Criteria:**

- Given l'utilisateur appuie sur une ligne dans l'Historique, Then l'écran Détail/Modification s'ouvre avec tous les champs pré-remplis (type, montant, catégorie, date, note) et le bouton « Supprimer » visible.

- Given l'utilisateur modifie un ou plusieurs champs et appuie sur « Enregistrer », Then `TransactionRepository.update()` est appelé, l'écran se ferme, le solde et l'Historique reflètent la correction immédiatement (< 100 ms).

- Given l'utilisateur appuie sur « Supprimer », Then une confirmation explicite est demandée (dialogue : « Supprimer cette transaction ? » / boutons « Annuler » · « Supprimer »).

- Given l'utilisateur confirme la suppression, Then `TransactionRepository.delete()` est appelé, l'écran se ferme, le solde et l'Historique se mettent à jour immédiatement ; l'action est non réversible.

- Given l'utilisateur annule la confirmation de suppression, Then rien n'est modifié et l'écran Détail/Modification reste ouvert.

- Given la transaction modifiée ou supprimée appartient à un reçu (`receipt_id` non nul), Then seule cette ligne individuelle est modifiée/supprimée ; les autres lignes du même reçu ne sont pas affectées.

> **Notes techniques :** `features/transactions/screens/transaction_detail_screen.dart`, réutilisation de `TransactionFormSheet` en mode édition (paramètre `Transaction? initial`). Ajout de `TransactionRepository.update(transaction)` et `TransactionRepository.delete(id)` — toujours le seul point d'écriture (AD-10).

## Epic 3 : Scan de Reçu et Pipeline OCR

L'utilisateur peut photographier un ticket de caisse, voir les lignes extraites avec catégories suggérées, les corriger, et valider le reçu pour l'imputer à son solde en moins de 30 secondes.

**FRs couverts :** FR-9, FR-10, FR-11, FR-12

---

### Story 3.1 : Capture photo du Reçu

En tant qu'utilisateur,
Je veux photographier mon ticket de caisse directement depuis l'app ou le sélectionner dans ma galerie,
Afin de pouvoir le faire analyser automatiquement sans saisie manuelle.

**Acceptance Criteria:**

- Given l'utilisateur appuie sur le FAB `+`, When le menu FAB s'ouvre, Then l'option « Scan Reçu » est désormais active (plus grisée) et accessible.

- Given l'utilisateur sélectionne « Scan Reçu » et c'est le premier accès à la caméra ou à la galerie, Then la permission correspondante est demandée avec un message explicatif (« GestBud a besoin de ta caméra pour scanner tes reçus »).

- Given la permission est accordée, Then la caméra native s'ouvre pour capturer une photo.

- Given l'utilisateur capture ou sélectionne une image, Then l'app navigue immédiatement vers l'écran de chargement OCR (skeleton) et envoie la photo au BFF via `POST /scan/receipt`.

- Given la permission est refusée définitivement, Then un message contextuel invite l'utilisateur à activer la permission dans les Réglages du système, sans plantage ni état bloqué.

- Given le réseau est absent au moment de l'envoi, Then un message inline s'affiche : « Pas de connexion réseau. Saisis le reçu manuellement. » avec un CTA ouvrant le bottom sheet Transaction (FR-5).

> **Notes techniques :** `features/scan/screens/scan_entry_screen.dart`, plugin `image_picker` (caméra + galerie), permission handling via `permission_handler`. L'image est transmise au BFF en multipart/form-data — jamais stockée en local après envoi. `bff/src/handlers/scan.ts` (POST `/scan/receipt`) ajouté au squelette BFF de Epic 1.

---

### Story 3.2 : Pipeline OCR, catégorisation IA et état de chargement

En tant qu'utilisateur,
Je veux voir un indicateur de chargement clair pendant que mon reçu est analysé, puis les lignes extraites avec leurs catégories suggérées,
Afin de savoir que le traitement est en cours et de pouvoir corriger le résultat.

**Acceptance Criteria:**

- Given la photo est envoyée au BFF et le traitement est en cours, Then l'écran Skeleton s'affiche : barres de hauteur variable sur fond `surface-raised` reproduisant la géométrie d'une liste de lignes, animation pulse (opacité 0.4 → 0.8 → 0.4, 1.2 s).

- Given Reduce Motion est activé sur l'appareil, When le skeleton est affiché, Then fond statique `surface-raised` sans animation pulse (UX-DR12).

- Given l'analyse se termine dans les 10 secondes, Then l'écran Revue Reçu s'affiche avec les lignes extraites (libellé + montant + catégorie suggérée pour chaque ligne).

- Given l'analyse dépasse 10 secondes (timeout BFF), Then le skeleton est remplacé par un message d'erreur : « Impossible de lire le reçu. Saisis-le manuellement. » et un CTA « Saisie manuelle » ouvrant le bottom sheet Transaction.

- Given le BFF reçoit la photo, When Mindee v2 répond (async polling sur `/jobs/{jobId}`), Then les lignes OCR sont envoyées en un seul prompt Mistral pour catégorisation (batch) ; si Mistral échoue, le fallback dictionnaire mots-clés s'applique avec `category: "Autre"` pour les lignes non reconnues ; les montants sont renvoyés en `amount_cents` (INTEGER centimes).

- Given l'app Flutter reçoit la réponse du BFF, Then elle ne distingue pas si la catégorisation vient de Mistral ou du fallback — le format `[{label, amount_cents, category}]` est identique dans les deux cas.

> **Notes techniques :** `bff/src/handlers/scan.ts` orchestre : Mindee v2 async polling (`POST /documents` → polling `GET /jobs/{jobId}`) → Mistral `mistral-small-latest` (prompt batch) → fallback dictionnaire → réponse unique. Timeout 10 s côté Flutter via `BffClient`. `features/scan/screens/scan_loading_screen.dart` (skeleton). Photo non conservée après l'appel Mindee (AD-4).

---

### Story 3.3 : Revue et correction des Lignes du Reçu

En tant qu'utilisateur,
Je veux vérifier les lignes extraites de mon reçu, corriger les montants et catégories incorrects, et supprimer les doublons,
Afin que seules les données exactes soient imputées à mon solde.

**Acceptance Criteria:**

- Given l'écran Revue Reçu s'affiche, Then un en-tête sticky indique le total dynamique (montant + nombre d'articles) en Title/SemiBold (UX-DR17), et chaque ligne présente : libellé OCR (Body), montant éditable inline (Body), badge Catégorie (dropdown).

- Given l'utilisateur modifie le montant d'une ligne inline, When la valeur change, Then le total de l'en-tête sticky se recalcule immédiatement.

- Given l'utilisateur appuie sur le badge Catégorie d'une ligne, Then le Sélecteur Catégorie (bottom sheet) s'ouvre ; après sélection, le badge est mis à jour et le bottom sheet se ferme.

- Given une ligne est en état d'avertissement (montant nul, libellé vide, ou catégorie inconnue), Then elle s'affiche avec fond `#3A2A00`, bordure gauche 3px `warning`, icône ⚠ ambre (UX-DR11).

- Given l'utilisateur effectue un swipe-to-delete sur une ligne, Then la ligne est supprimée et le total recalculé ; aucune confirmation n'est requise (données non encore persistées).

- Given le lecteur d'écran est actif, Then l'action de suppression est également accessible via le menu ⋯ de chaque ligne et exposée comme action d'accessibilité personnalisée VoiceOver/TalkBack (UX-DR11).

- Given l'utilisateur appuie sur « Ajouter une ligne », Then une nouvelle ligne vide est insérée en bas de la liste avec focus automatique sur le champ libellé.

- Given toutes les lignes sont supprimées, Then un état vide local s'affiche dans la liste ; le CTA « Valider le reçu » reste présent mais désactivé.

> **Notes techniques :** `features/scan/screens/scan_review_screen.dart`, composant `ReceiptLineItem` (`shared/widgets/`) conforme UX-DR11. Le Sélecteur Catégorie (`shared/widgets/category_selector_sheet.dart`) est réutilisé depuis Epic 2. L'état de revue est maintenu dans un `StateProvider<List<ReceiptLine>>` local à la session — rien n'est persisté tant que l'utilisateur n'a pas validé.

---

### Story 3.4 : Validation globale du Reçu et regroupement dans l'Historique

En tant qu'utilisateur,
Je veux valider mon reçu d'un seul geste pour que toutes ses lignes soient enregistrées dans mon historique et mon solde mis à jour,
Afin de ne pas avoir à saisir chaque article manuellement.

**Acceptance Criteria:**

- Given l'écran Revue Reçu contient au moins une ligne, When l'utilisateur appuie sur « Valider le reçu », Then `TransactionRepository.insertReceiptLines(receiptId, lines)` est appelé : toutes les lignes sont insérées dans un unique `database.transaction()` atomique (soit toutes réussissent, soit aucune — en cas d'erreur, l'état de revue est conservé intact).

- Given la validation réussit, Then l'écran Revue Reçu se ferme, l'app navigue vers l'Accueil, le solde est mis à jour immédiatement (déduit du total du reçu), et un message de confirmation s'affiche : « Reçu enregistré ! »

- Given l'utilisateur consulte l'onglet Historique après validation, Then le reçu apparaît comme une entrée groupée (libellé « Reçu · N articles · total FCFA ») avec un chevron indiquant l'état réduit.

- Given l'utilisateur appuie sur l'entrée groupée dans l'Historique, Then les lignes individuelles s'expandent en-dessous (UX-DR19) ; un deuxième tap les réduit ; le chevron est animé pour indiquer l'état.

- Given VoiceOver/TalkBack est actif sur l'entrée groupée, Then l'état est annoncé à chaque tap : « Reçu, [N] articles, [état développé/réduit] ».

- Given l'utilisateur souhaite modifier une ligne individuelle d'un reçu déjà validé, Then il peut appuyer dessus (ligne individuelle dans l'état développé) et accéder à l'écran Détail/Modification (Story 2.4) ; la modification ne touche que cette ligne.

> **Notes techniques :** `TransactionRepository.insertReceiptLines(String receiptId, List<ReceiptLine> lines)` — génère un UUID v4 pour `receiptId` (partagé entre toutes les lignes), insère en `database.transaction()` atomique (AD-3, AD-10). Composant `ReceiptGroupTile` dans `shared/widgets/` (expand/collapse avec `AnimatedSize`, respecte Reduce Motion via `MediaQuery.disableAnimations`). `receipt_id TEXT` nullable sur la table `transactions` est déjà défini dans le schéma Drift de Story 1.1.

## Epic 4 : Tableau de bord analytique

L'utilisateur peut consulter ses postes de dépense par catégorie, un graphique d'évolution de son solde, et comparer ses dépenses mois après mois sur la période de son choix.

**FRs couverts :** FR-17 (contexte dashboard), FR-18, FR-19, FR-20, FR-21

---

### Story 4.1 : Structure du Tableau de bord et Sélecteur de Période

En tant qu'utilisateur,
Je veux naviguer entre les mois et sélectionner une période personnalisée,
Afin d'analyser mes finances sur n'importe quel intervalle de temps.

**Acceptance Criteria:**

- Given l'utilisateur navigue vers l'onglet « Tableau de bord », Then le mois courant est sélectionné par défaut (label format « Juillet 2026 ») avec des flèches ◀▶ visibles en haut de l'écran.

- Given l'utilisateur appuie sur ◀ ou ▶, Then le mois précédent ou suivant est sélectionné et l'ensemble du contenu du dashboard se met à jour immédiatement (< 100 ms, providers dérivés).

- Given l'utilisateur appuie sur le label de la période (ex. « Juillet 2026 »), Then un bottom sheet de sélection de période custom s'ouvre avec deux Sélecteurs Date (date début · date fin) et un CTA « Valider ».

- Given la date fin saisie est antérieure à la date début, Then un message inline s'affiche : « La date de fin doit être après la date de début. » et le CTA « Valider » reste désactivé.

- Given l'utilisateur valide une période custom, Then le label affiche la plage (ex. « 01/06 – 15/07 ») et tout le contenu du dashboard se met à jour immédiatement.

- Given le mois sélectionné ne contient aucune transaction, Then les sections FR-18, FR-19 et FR-20 affichent chacune leur état vide respectif sans crash.

> **Notes techniques :** `features/dashboard/screens/dashboard_screen.dart`, `shared/providers/selected_period_provider.dart` (`StateProvider<DateRange>`, défaut : mois courant). Toutes les sections du dashboard lisent ce provider et se recalculent automatiquement. Composant `PeriodSelector` dans `features/dashboard/widgets/`.

---

### Story 4.2 : Postes de dépense par catégorie et comparaison mois/mois

En tant qu'utilisateur,
Je veux voir le total dépensé par catégorie sur ma période et le comparer au mois précédent,
Afin d'identifier où va mon argent et repérer les dérives.

**Acceptance Criteria:**

- Given la période sélectionnée contient des dépenses, Then la liste des postes s'affiche triée par montant décroissant ; chaque poste présente : pastille catégorie, nom, montant en Body (dépenses uniquement, préfixé `−`) ; la somme de tous les postes = total des dépenses de la période.

- Given une catégorie n'a aucune transaction sur la période sélectionnée, Then elle n'apparaît pas dans la liste.

- Given chaque poste est affiché, Then une ligne de comparaison mois/mois indique la variation vs le même poste du mois précédent : montant `+`/`−` + pourcentage, avec indicateur directionnel (↑ hausse · ↓ baisse).

- Given le mois précédent ne contient aucune transaction pour ce poste, Then la variation affiche « — » sans indicateur directionnel.

- Given la période change via le Sélecteur Période, Then la liste et toutes les variations se mettent à jour immédiatement (< 100 ms), sans rechargement visible.

- Given la période sélectionnée ne contient aucune dépense, Then un état vide local s'affiche à la place de la liste (texte : « Aucune dépense sur cette période. »).

> **Notes techniques :** `shared/providers/category_spending_provider.dart` (provider dérivé de `transactionListProvider` + `selectedPeriodProvider`), `shared/providers/monthly_comparison_provider.dart`. Le « mois précédent » est toujours le mois calendaire précédent la date de début de la période — même si la période est une plage custom. Composant `CategorySpendingTile` dans `features/dashboard/widgets/`.

---

### Story 4.3 : Graphique d'évolution du Solde

En tant qu'utilisateur,
Je veux voir l'évolution de mon solde jour par jour sur la période sélectionnée,
Afin de visualiser l'impact de mes dépenses dans le temps.

**Acceptance Criteria:**

- Given la période sélectionnée contient des transactions, Then un graphique linéaire s'affiche avec la valeur du solde en fin de journée pour chaque jour de la période (solde cumulatif à 23:59 de chaque jour).

- Given un jour de la période n'a aucune transaction, Then le solde de ce jour est égal au solde du jour précédent (la ligne reste plate).

- Given le solde est négatif sur une partie de la période, Then la courbe passe sous l'axe zéro avec un repère visuel de l'axe zéro clairement visible.

- Given la période sélectionnée ne contient aucune transaction, Then une ligne plate à 0 FCFA est affichée (la valeur 0 est informative — pas d'état vide).

- Given la période change, Then le graphique se recalcule et se ré-affiche immédiatement (< 100 ms).

- Given l'écran est affiché sur un Android 5" (résolution typique), Then tous les éléments textuels du graphique ont une hauteur minimale de 44px (NFR-3).

- Given VoiceOver/TalkBack est actif sur le graphique, Then une description textuelle accessible résume la tendance (ex. « Solde en hausse de X FCFA sur la période »).

> **Notes techniques :** `features/dashboard/widgets/balance_chart.dart`, librairie recommandée : `fl_chart` (compatible Flutter ^3.22). `shared/providers/daily_balance_provider.dart` (provider dérivé calculant le solde cumulatif par jour, réutilisant la logique de `balance_provider` de Story 2.1 — pas de duplication).

## Epic 5 : Gestion des Catégories personnalisées

L'utilisateur peut créer ses propres catégories avec une icône et une couleur, les renommer, et les supprimer avec réaffectation automatique des transactions concernées.

**FRs couverts :** FR-14, FR-15, FR-16

---

### Story 5.1 : Liste des catégories et accès depuis les Paramètres

En tant qu'utilisateur,
Je veux accéder à la liste de toutes mes catégories depuis les Paramètres,
Afin de voir ce qui est disponible et d'y gérer mes catégories personnalisées.

**Acceptance Criteria:**

- Given l'utilisateur est sur l'écran Paramètres, Then un lien « Gérer mes catégories » est visible en plus du bouton « Se déconnecter ».

- Given l'utilisateur appuie sur « Gérer mes catégories », Then il est navigué vers l'écran Gestion des Catégories.

- Given l'écran Gestion des Catégories s'affiche, Then toutes les catégories sont listées : les 10 prédéfinies en premier, puis les catégories personnalisées, chaque ligne conforme UX-DR15 (pastille à gauche, nom Body au centre).

- Given une catégorie est prédéfinie, Then sa ligne n'affiche pas d'icônes crayon ni corbeille et n'est pas interactive au-delà de l'affichage.

- Given une catégorie est personnalisée, Then sa ligne affiche une icône crayon (renommer) et une icône corbeille (supprimer) à droite, espacées de 12px, cibles ≥ 44px.

- Given aucune catégorie personnalisée n'existe encore, Then seules les 10 catégories prédéfinies s'affichent, avec un bouton `+` visible pour en créer une.

> **Notes techniques :** `features/categories/screens/category_management_screen.dart`, réutilisation de `shared/providers/categoryListProvider` (StreamProvider existant sur `CategoryDao.watchAll()` — AD-11). Ajout de la route `/settings/categories` dans `app_router.dart`. Mise à jour de `features/auth/screens/settings_screen.dart` pour ajouter le lien « Gérer mes catégories ».

---

### Story 5.2 : Création d'une catégorie personnalisée

En tant qu'utilisateur,
Je veux créer une catégorie avec l'icône et la couleur de mon choix,
Afin qu'elle apparaisse immédiatement dans tous les sélecteurs de catégorie de l'app.

**Acceptance Criteria:**

- Given l'utilisateur appuie sur le bouton `+` de l'écran Gestion des Catégories, Then le bottom sheet Création s'ouvre (UX-DR16) avec : grille 4 colonnes d'emojis, rangée de 6 pastilles couleur (Rose · Sarcelle · Terracotta · Olive · Ardoise · Prune avec labels sémantiques accessibles), champ nom (placeholder « Nom de la catégorie ») ; présélection par défaut : premier emoji + couleur Rose.

- Given le champ nom est vide, Then le CTA « Créer » reste désactivé.

- Given l'utilisateur saisit un nom identique à une catégorie existante (insensible à la casse, toutes catégories confondues), Then le champ nom affiche une bordure `danger`, le message « Cette catégorie existe déjà. » apparaît sous le champ, et le CTA « Créer » reste désactivé.

- Given l'utilisateur sélectionne une couleur, Then un anneau `text-primary` 2px s'affiche autour de la pastille sélectionnée.

- Given l'utilisateur sélectionne un emoji, Then un anneau `accent` 2px s'affiche autour de l'emoji sélectionné.

- Given le nom est valide, une couleur et un emoji sont sélectionnés, et l'utilisateur appuie sur « Créer », Then `CategoryDao.insert()` est appelé, le bottom sheet se ferme, la nouvelle catégorie apparaît immédiatement dans la liste et dans tous les Sélecteurs Catégorie de l'app (via `categoryListProvider` réactif).

> **Notes techniques :** `features/categories/widgets/category_form_sheet.dart` (réutilisé en mode création et renommage). Les 6 paires couleur personnalisées sont définies dans les tokens de design (UX-DR1) : `cat-custom-rose`, `cat-custom-teal`, `cat-custom-terracotta`, `cat-custom-olive`, `cat-custom-slate`, `cat-custom-prune`. `CategoryDao.insert()` déclenche la mise à jour de `categoryListProvider` via `watchAll()`.

---

### Story 5.3 : Renommage et suppression d'une catégorie personnalisée

En tant qu'utilisateur,
Je veux pouvoir renommer ou supprimer une catégorie personnalisée,
Afin que mes catégories restent pertinentes sans laisser de transactions orphelines.

**Acceptance Criteria:**

- Given l'utilisateur appuie sur l'icône crayon d'une catégorie personnalisée, Then le bottom sheet Renommage s'ouvre (même composant que la création — UX-DR16) avec le nom, l'emoji et la couleur actuels pré-remplis.

- Given l'utilisateur modifie le nom et appuie sur « Enregistrer », Then `CategoryDao.update()` est appelé : le nom est mis à jour dans la table `categories` et toutes les transactions associées reflètent immédiatement le nouveau nom (via la relation FK).

- Given le nom modifié est identique à une autre catégorie existante (insensible à la casse), Then bordure `danger` + message « Cette catégorie existe déjà. » + CTA désactivé.

- Given l'utilisateur appuie sur l'icône corbeille d'une catégorie personnalisée, Then une confirmation explicite est demandée : « Supprimer "[nom]" ? Les transactions associées seront réaffectées à "Autre". » / boutons « Annuler » · « Supprimer ».

- Given l'utilisateur confirme la suppression, Then dans une unique `database.transaction()` atomique : toutes les transactions ayant cette `category_id` sont réaffectées à la catégorie « Autre », puis la catégorie est supprimée ; `categoryListProvider` se met à jour et la catégorie disparaît de tous les sélecteurs immédiatement.

- Given l'utilisateur annule la confirmation, Then aucune modification n'est effectuée.

- Given l'utilisateur tente d'interagir avec les icônes d'une catégorie prédéfinie, Then aucune action ne se déclenche (icônes absentes de la ligne — UX-DR15).

> **Notes techniques :** `CategoryDao.update(Category)` et `CategoryDao.delete(int id)`. La suppression avec réaffectation est atomique via `AppDatabase.transaction(() async { ... })` — mise à jour des transactions puis suppression de la catégorie. L'ID de « Autre » est récupéré via `CategoryDao.findByName('Autre')` avant l'opération. Réutilisation de `category_form_sheet.dart` en mode édition (paramètre `Category? initial`).
