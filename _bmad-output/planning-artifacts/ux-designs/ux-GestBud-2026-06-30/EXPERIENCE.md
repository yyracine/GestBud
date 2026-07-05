---
title: "EXPERIENCE : GestBud"
status: final
created: 2026-06-30
updated: 2026-06-30
sources:
  - _bmad-output/planning-artifacts/prds/prd-GestBud-2026-06-30/prd.md
  - _bmad-output/planning-artifacts/briefs/brief-GestBud-2026-06-30/brief.md
---

# GestBud — Experience Spine

## Foundation

Application mobile native cross-platform Flutter, iOS 15+ et Android 9+. Parity complète entre les deux plateformes — aucun comportement différencié par OS sauf les conventions système (safe areas, permissions caméra/galerie, clavier numérique natif). Pas de UI system tiers nommé — les tokens visuels viennent de `DESIGN.md` qui est la référence d'identité visuelle. Dark mode par défaut et unique — pas de mode clair.

Stockage 100 % local (SQLite via `sqflite`). Les seules dépendances réseau sont l'OTP SMS (Africa's Talking) et l'OCR (Mindee). La saisie manuelle fonctionne entièrement hors connexion.

Référence maquettes clés : [`mockups/key-screens-1.html`](mockups/key-screens-1.html) (Auth · Accueil · Scan · Tableau de bord · Saisie manuelle) · [`mockups/key-screens-2.html`](mockups/key-screens-2.html) (Gestion Catégories — états 06a–06d). Palette de couleurs : [`mockups/color-themes-1.html`](mockups/color-themes-1.html). Les spines ont priorité sur les maquettes en cas de conflit.

## Information Architecture

| Surface | Accessible depuis | Rôle |
|---|---|---|
| Authentification — Téléphone | Cold open · déconnexion | Saisie du numéro de téléphone |
| Authentification — OTP | Après envoi SMS | Saisie du code à 6 chiffres |
| Accueil | Auth réussie · onglet Accueil | Solde courant + 5 dernières transactions |
| FAB Menu | Tap FAB depuis n'importe quelle surface | Choix d'action : Scan Reçu · Nouvelle transaction |
| Saisie manuelle | FAB Menu → Nouvelle transaction | Bottom sheet création/édition de transaction |
| Scan — Capture | FAB Menu → Scan Reçu | Viewfinder caméra ou galerie |
| Scan — Revue | Après retour OCR | Liste de lignes extraites à valider/corriger |
| Historique | Onglet liste · « Voir tout » depuis Accueil | Toutes les transactions groupées par jour |
| Détail Transaction | Tap sur une ligne dans Historique | Édition ou suppression d'une transaction |
| Tableau de bord | Onglet graphique | Solde, postes, graphique d'évolution, comparaison |
| Gestion Catégories | Paramètres | Catégories personnalisées (créer, renommer, supprimer) |
| Paramètres | Icône settings depuis Accueil (haut droite) | Déconnexion, catégories, avertissement stockage |

Navigation principale : bottom tab bar 3 onglets (Accueil · Historique · Tableau de bord) + FAB central. Paramètres accessibles via icône en haut à droite de l'Accueil — pas dans la tab bar. Les bottom sheets (Saisie manuelle, FAB Menu, Sélecteur catégorie, Sélecteur date) ne s'empilent jamais à plus d'un niveau.

## Voice and Tone

Microcopy. L'identité de marque et la posture esthétique vivent dans `DESIGN.md`.

Tutoiement systématique. Chaud et direct sur les succès, neutre et clair sur les erreurs. Pas d'emojis dans les messages critiques.

| Situation | À écrire | À éviter |
|---|---|---|
| Validation d'un reçu | « Reçu enregistré ! » | « Opération réussie ✓ » |
| Validation d'une transaction | « Transaction enregistrée ! » | « Dépense ajoutée avec succès ! » |
| Solde affiché | « Il te reste 87 200 FCFA ce mois. » | « Solde : 87 200 XOF » |
| Erreur réseau OCR | « Impossible de lire le reçu. Saisis-le manuellement. » | « Erreur réseau (code 503) » |
| OTP expiré | « Ce code a expiré. Demande-en un nouveau. » | « Token invalide » |
| Suppression | « Cette transaction sera supprimée définitivement. » | « Supprimer ? Oui / Non » |
| État vide Accueil | « Ton premier reçu t'attend. » | « Aucune donnée à afficher. » |
| Bannière stockage local | « Tes données sont sur ton téléphone. Ne désinstalle pas l'app. » | « Attention : vos données sont stockées localement. » |
| Chargement OCR | « Analyse du reçu en cours… » | « Chargement… » |
| Suppression d'une ligne de reçu | « Cette ligne sera retirée du reçu. » | « Supprimer ? Oui / Non » |
| Date de fin antérieure à la date de début | « La date de fin doit être après la date de début. » | « Période invalide » |

## Component Patterns

Comportemental. Les specs visuelles (couleurs, tailles, arrondis) vivent dans `DESIGN.md`.

| Composant | Usage | Règles comportementales |
|---|---|---|
| Carte Solde | Accueil · Tableau de bord | Recalculée après chaque mutation de Transaction. Solde négatif : montant en `{colors.danger}` (défini dans DESIGN.md). |
| FAB | Toutes surfaces avec nav bar | Tap → bottom sheet FAB Menu (2 options). Pas de long-press. |
| Bottom sheet Saisie manuelle | FAB Menu → Nouvelle transaction · Détail Transaction | Segmented control Dépense/Revenu en haut. Clavier numérique natif pour le montant. Dismiss par swipe down ou tap outside. |
| Sélecteur Catégorie | Saisie manuelle · Revue Reçu | S'ouvre en bottom sheet. Catégories prédéfinies en premier, personnalisées ensuite. Recherche non requise en v1. |
| Sélecteur Date | Saisie manuelle | S'ouvre en bottom sheet avec date-picker natif. Défaut : aujourd'hui. Dates futures non sélectionnables. |
| Ligne de Reçu | Scan — Revue | Libellé + montant (champ éditable inline) + sélecteur Catégorie. État warning si montant vide. Swipe-to-delete pour supprimer une ligne, avec bouton menu « ⋯ » équivalent toujours visible (alternative accessible, cf. Accessibility Floor). |
| En-tête sticky Reçu | Scan — Revue | Affiche le total dynamique recalculé à chaque modification de ligne. Fixe en haut de la liste. |
| Skeleton chargement | Scan — entre Capture et Revue | Reproduit la géométrie de la liste de lignes. Remplacé par les données réelles à l'arrivée du résultat OCR. |
| Ligne de Transaction | Historique | Tap → Détail Transaction. Long-press réservé à la sélection texte système. |
| Entrée Reçu groupé | Historique | Tap → expand les lignes du reçu en-dessous. Deuxième tap → collapse. Chevron animé indique l'état. |
| Sélecteur de Période | Tableau de bord | Navigation mois ◀ ▶ par défaut. Tap sur le mois en cours → bottom sheet pour sélection période custom (date début + date fin). Date fin < date début bloquée. |
| Bannière info | Accueil (première connexion) | Affichée une seule fois (flag local). Dismissable via ×. Ne bloque aucune interaction. Positionnée au-dessus de la nav bar. |
| Ligne de Catégorie (gestion) | Gestion Catégories | Catégories personnalisées : tap crayon → Champ Création/Renommage pré-rempli ; tap corbeille → confirmation de suppression. Catégories prédéfinies : icônes crayon/corbeille absentes, ligne non interactive au-delà de l'affichage. |
| Champ Création/Renommage Catégorie | Gestion Catégories | Icône (grille d'emojis) et couleur (palette de 6 teintes curées) présélectionnées par défaut à l'ouverture, modifiables par tap avant d'enregistrer — choix obligatoire mais jamais bloquant grâce à la présélection. Validation à la saisie : nom vide → CTA désactivé. Nom dupliqué (insensible à la casse, catégories existantes incluses prédéfinies) → erreur inline, CTA désactivé. Renommage : icône et couleur pré-remplies avec les valeurs actuelles de la catégorie, modifiables ; cascade automatique sur toutes les transactions existantes de cette catégorie. Catégories prédéfinies : icône et couleur fixes, non exposées dans ce flux (cohérent avec leur statut non éditable). |

## State Patterns

| État | Surface | Traitement |
|---|---|---|
| Cold open (non authentifié) | Auth — Téléphone | Affichage direct sans splash screen. |
| OTP en attente | Auth — OTP | Bouton « Renvoyer » désactivé 60 s, compteur visible. |
| OTP invalide / expiré | Auth — OTP | Message d'erreur inline sous le champ, pas de modal. |
| Première connexion réussie | Accueil | Bannière info stockage local affichée une fois. |
| Accueil vide (0 transactions) | Accueil | État vide : illustration + « Ton premier reçu t'attend. » + CTA « Scanner un reçu ». |
| OCR en cours | Scan — Revue | Skeleton animé sur la liste de lignes + message « Analyse du reçu en cours… ». |
| OCR timeout (> 10 s) | Scan — Revue | Message d'erreur + CTA « Saisir manuellement » (ouvre Saisie manuelle pré-remplie avec le total si connu). |
| OCR — ligne illisible | Scan — Revue | Ligne en état warning (fond ambre, icône ⚠), montant vide, Catégorie « Autre ». |
| Réseau absent (scan) | Scan — Capture | Message « Pas de connexion. Le scan nécessite internet. » + CTA « Saisir manuellement ». |
| Réseau absent (OTP) | Auth — Téléphone | Message inline sous le bouton « Pas de connexion réseau ». |
| Saisie manuelle hors connexion | Bottom sheet | Fonctionne normalement — aucun indicateur réseau nécessaire. |
| Historique vide | Historique | État vide : illustration + « Aucune transaction pour le moment. » + CTA « Ajouter une transaction ». |
| Tableau de bord — mois sans données | Tableau de bord | Graphique vide (axe X présent, pas de courbe) + message Caption muted « Aucune dépense ce mois. » |
| Variation mois/mois — mois précédent vide | Tableau de bord | Indicateur de variation affiché « — » (tiret), pas de flèche. |
| Solde négatif | Accueil · Tableau de bord | Montant en `{colors.danger}`, pas d'autre alerte modale. |
| Suppression Transaction | Détail Transaction | Confirmation requise (bottom sheet ou dialog natif) : « Cette transaction sera supprimée définitivement. » Pas de snackbar d'annulation en v1. |
| Gestion Catégories vide (0 catégorie personnalisée) | Gestion Catégories | Liste des catégories prédéfinies affichée normalement (non interactives) ; pas d'état vide dédié — un bouton « Nouvelle catégorie » est toujours visible en haut de liste. |
| Nom de catégorie dupliqué | Gestion Catégories | Erreur inline sous le Champ Création/Renommage : « Cette catégorie existe déjà. » CTA « Enregistrer » désactivé tant que l'erreur persiste. |
| Suppression Catégorie | Gestion Catégories | Confirmation requise (bottom sheet ou dialog natif) : « Les transactions de cette catégorie seront déplacées vers Autre. » Pas de snackbar d'annulation en v1. |
| Catégorie prédéfinie (action bloquée) | Gestion Catégories | Aucune icône crayon/corbeille affichée sur les catégories prédéfinies — le renommage et la suppression ne sont pas exposés à l'UI (pas de message d'erreur nécessaire, l'action est simplement absente). |

## Interaction Primitives

- **Tap** pour toute action intentionnelle. Cible minimum : 44 pt iOS / 48 dp Android.
- **Swipe down** pour fermer un bottom sheet. Tap outside la surface du sheet également accepté.
- **Swipe-to-delete** sur les lignes de Reçu (surface Scan — Revue) uniquement, toujours doublé d'un bouton menu « ⋯ » équivalent (alternative accessible). Pas de swipe-to-delete sur l'Historique (accès via Détail Transaction).
- **Tap expandable** sur les entrées Reçu groupées dans l'Historique.
- **Pull-to-refresh** non nécessaire (données 100 % locales, pas de sync réseau).
- **Gestes natifs** (back swipe iOS, navigation par geste Android) honorés sans override.
- **Interdit :** carousels, modals d'onboarding multi-étapes, streaks ou badges de gamification, notifications push (hors périmètre v1).

## Accessibility Floor

Comportemental. Le contraste visuel (≥ 4.5:1) et les tailles de police vivent dans `DESIGN.md`.

- **VoiceOver / TalkBack :** chaque élément interactif a un label sémantique incluant son rôle et son état. Les montants sont lus avec la devise : « 245 800 francs CFA ». Les pastilles de catégorie annoncent le nom de la catégorie, pas juste l'emoji.
- **Taille des cibles :** ≥ 44 pt (iOS) / 48 dp (Android) pour tous les éléments interactifs y compris les lignes de liste, les chevrons, le × de la bannière.
- **Clavier et focus :** l'ordre de focus suit l'ordre de lecture (haut-gauche → bas-droite). Les bottom sheets piègent le focus tant qu'ils sont ouverts.
- **Reduce Motion :** le skeleton de chargement passe de l'animation pulse à un fond statique `{colors.surface-raised}`. Les transitions d'écran utilisent les transitions cross-fade courtes de Flutter plutôt que les slides.
- **Dynamic type :** les tokens typographiques (Urbanist 32/20/15/12) servent de tailles de base. L'app doit rester lisible sans troncation jusqu'à la taille d'accessibilité maximale du système.
- **Langue :** interface en français uniquement (v1). Les montants utilisent l'espace fine comme séparateur de milliers — vérifier que les lecteurs d'écran lisent bien le chiffre complet.
- **Segmented control (Dépense/Revenu) :** état sélectionné annoncé explicitement, ex. « Dépense, sélectionné, 1 sur 2 ».
- **Entrées Reçu groupées (Historique) :** état annoncé à chaque tap, ex. « Reçu, 5 articles, réduit » / « Reçu, 5 articles, développé ».
- **Swipe-to-delete (Ligne de Reçu) :** le geste de swipe n'est pas l'unique moyen de supprimer une ligne — une action de menu (bouton « ⋯ » ou long-press) expose la suppression visuellement pour tous les utilisateurs, et est exposée en plus comme action d'accessibilité personnalisée (« Supprimer cette ligne ») pour VoiceOver/TalkBack, puisque le swipe gestuel n'est pas fiablement accessible aux utilisateurs de lecteur d'écran ou de contrôle de switch.
- **FAB Menu :** à l'ouverture, le focus se déplace dans le bottom sheet (règle générale de piégeage du focus des bottom sheets, ligne 114) ; chaque option (« Scan Reçu », « Nouvelle transaction ») est annoncée comme un élément de liste actionnable.
- **Confirmations critiques (transaction enregistrée, reçu enregistré, suppression) :** exposées en live-region d'accessibilité — pas seulement un toast visuel — pour que la confirmation soit annoncée même sans focus sur l'élément déclencheur.
- **Sélecteur de couleur (Champ Création/Renommage Catégorie) :** chaque pastille a un label sémantique nommant la teinte (« Rose », « Sarcelle », « Terracotta », « Olive », « Ardoise », « Prune »), jamais juste « couleur 1 » — la couleur seule ne porte jamais l'information pour un lecteur d'écran.

## Inspiration & Anti-patterns

**Inspirations retenues :**
- Registre dark fintech (capture partagée par Racine) : fond navy profond, accent violet unique, cartes surélevées par la couleur. Repris fidèlement dans la palette Nuit Violette.
- Pastilles de catégorie colorées (pratique courante dans les apps PFM comme Wallet, Toshl) : permet la reconnaissance instantanée dans l'historique sans lire les libellés.
- FAB central avec bottom sheet d'actions (pattern commun sur les apps mobiles d'Afrique de l'Ouest) : l'action principale est toujours à un tap.

**Anti-patterns rejetés :**
- **Onboarding multi-écrans :** les 20 beta sont des utilisateurs recrutés, pas des utilisateurs froids. Un état vide actionnable est plus efficace.
- **Swipe-to-delete sur l'Historique :** le risque de suppression accidentelle sur des données financières est trop élevé. La suppression passe par le Détail Transaction avec confirmation explicite.
- **Dashboard sur l'Accueil :** l'accueil répond à une seule question (« Où j'en suis ? ») — le dashboard complet est dans son onglet. Mélanger les deux surcharge sans gain.
- **Connexion bancaire / Mobile Money :** hors périmètre v1 — aucun élément d'UI ne doit suggérer cette possibilité pour ne pas créer d'attente.
- **Notifications push :** hors périmètre v1. Aucun badge, aucun compteur non lu dans l'app.

## Key Flows

### Flow 1 — Aminata scanne son ticket Auchan (UJ-1)

*Aminata, cadre à Dakar, gère les finances du foyer. Elle rentre de courses avec un ticket de 38 000 FCFA mélangé alimentation/hygiène.*

1. Aminata ouvre GestBud depuis l'Accueil.
2. Elle appuie sur le FAB `+`.
3. Le FAB Menu s'ouvre : « Scan Reçu » · « Nouvelle transaction ».
4. Elle choisit « Scan Reçu ».
5. L'app demande la permission caméra (premier accès) ou ouvre le viewfinder directement.
6. Elle pointe son téléphone sur le ticket. Tap sur le bouton de capture.
7. Écran Revue : skeleton animé, message « Analyse du reçu en cours… ».
8. Les lignes apparaissent progressivement. Total sticky en haut : « 38 000 FCFA · 5 articles ».
9. Elle identifie une ligne en warning (libellé illisible, montant vide) — elle saisit le montant et choisit la catégorie.
10. Elle corrige la catégorie de deux autres lignes via le sélecteur.
11. Elle appuie sur « Valider le reçu (5 articles) ».
12. **Climax :** retour sur l'Accueil. La carte Solde est mise à jour. « Reçu enregistré ! » en feedback bref. Aminata range son ticket — pour le reste du mois, elle sait ce qu'il reste.

*Cas d'erreur réseau (OCR timeout) :* message « Impossible de lire le reçu. Saisis-le manuellement. » — CTA ouvre la Saisie manuelle.

---

### Flow 2 — Aminata note un taxi pris au marché (UJ-2)

*Achat sans reçu, 1 500 FCFA, debout au bord de la route.*

1. Aminata appuie sur le FAB depuis n'importe quelle surface.
2. FAB Menu → « Nouvelle transaction ».
3. Bottom sheet s'ouvre : segmented control sur « Dépense », clavier numérique natif actif.
4. Elle tape `1500`.
5. Elle sélectionne la catégorie Transport (sélecteur → bottom sheet liste).
6. Date : aujourd'hui par défaut, elle ne touche pas.
7. Note : elle laisse vide.
8. Tap « Enregistrer ».
9. **Climax :** bottom sheet se ferme. La transaction apparaît en tête de l'Historique. Le Solde est mis à jour. 10 secondes, elle remet le téléphone dans la poche.

---

### Flow 3 — Aminata consulte son bilan de fin de mois (UJ-3)

*30 juin, fin de soirée. Aminata veut comprendre où est passé l'argent.*

1. Aminata ouvre l'app, appuie sur l'onglet Tableau de bord (graphique).
2. L'écran affiche le mois courant (juin 2026) par défaut.
3. Elle voit le Solde en haut : 87 200 FCFA.
4. Elle fait défiler la courbe d'évolution : pic à mi-mois (salaire) puis descente régulière.
5. Elle lit les postes par catégorie : Alimentation 38 000 · Transport 12 500 · Santé 7 200.
6. Elle repère que Santé affiche `↑ +100 %` en rouge — elle se souvient : médicaments de son enfant malade.
7. Elle appuie sur le chevron `◀` pour comparer avec mai — les chiffres se mettent à jour.
8. **Climax :** elle voit que juillet, elle devra réduire les sorties pour compenser Santé. Elle ferme l'app avec un plan concret pour le mois suivant.

---

### Flow 4 — Aminata crée une catégorie « Tontine » (FR-13–FR-16)

*Aminata cotise chaque mois à une tontine entre collègues — une dépense récurrente qui ne rentre dans aucune catégorie prédéfinie.*

1. Aminata ouvre les Paramètres depuis l'icône en haut à droite de l'Accueil.
2. Elle accède à Gestion Catégories.
3. Elle voit la liste des catégories prédéfinies (non éditables) et appuie sur « Nouvelle catégorie ».
4. Le Champ Création/Renommage Catégorie s'ouvre, icône et couleur déjà présélectionnées. Elle change l'icône pour 🤝 et choisit la teinte terracotta — plus parlant que la valeur par défaut. Elle tape « Tontine ».
5. Elle appuie sur « Enregistrer ». La catégorie apparaît dans la liste avec son icône et sa couleur, éditable (icônes crayon/corbeille visibles).
6. **Climax :** la prochaine fois qu'elle scanne un reçu ou saisit une transaction, « Tontine » apparaît dans le Sélecteur Catégorie aux côtés des catégories prédéfinies — elle peut enfin suivre ce poste séparément.

*Cas d'erreur (nom dupliqué) :* elle tape « Transport » par erreur — message inline « Cette catégorie existe déjà. », CTA désactivé jusqu'à correction.

*Cas de suppression :* six mois plus tard, la tontine se termine. Elle supprime la catégorie ; confirmation « Les transactions de cette catégorie seront déplacées vers Autre. » — son historique reste intact, reclassé.
