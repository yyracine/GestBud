---
title: "DESIGN : GestBud"
status: final
created: 2026-06-30
updated: 2026-06-30
name: GestBud
description: Application mobile Flutter de gestion financière personnelle pour actifs urbains francophones d'Afrique subsaharienne.
colors:
  bg: '#0D0F1E'
  surface: '#181B33'
  surface-raised: '#1E2240'
  accent: '#6B5CFF'
  accent-dim: '#2A2460'
  text-primary: '#FFFFFF'
  text-secondary: '#A8A8C0'
  success: '#00C897'
  danger: '#FF6B6B'
  warning: '#F5A623'
  border: '#2A2D4A'
  cat-alimentation-bg: '#1A3A2A'
  cat-alimentation-fg: '#4CAF50'
  cat-transport-bg: '#1A2A3A'
  cat-transport-fg: '#42A5F5'
  cat-sante-bg: '#3A1A2A'
  cat-sante-fg: '#EF5350'
  cat-hygiene-bg: '#1A3A3A'
  cat-hygiene-fg: '#26C6DA'
  cat-logement-bg: '#3A2A1A'
  cat-logement-fg: '#FFA726'
  cat-education-bg: '#1E1A3A'
  cat-education-fg: '#9B7FD4'
  cat-loisirs-bg: '#3A2010'
  cat-loisirs-fg: '#FF7043'
  cat-habillement-bg: '#2A1A3A'
  cat-habillement-fg: '#C772D6'
  cat-transferts-bg: '#3A3010'
  cat-transferts-fg: '#FFD54F'
  cat-autre-bg: '#1E1E2A'
  cat-autre-fg: '#9E9E9E'
  cat-revenu-bg: '#0F3A1A'
  cat-revenu-fg: '#00C897'
  cat-custom-rose-bg: '#3A1A28'
  cat-custom-rose-fg: '#F06292'
  cat-custom-teal-bg: '#0F2A28'
  cat-custom-teal-fg: '#26A69A'
  cat-custom-terracotta-bg: '#3A2418'
  cat-custom-terracotta-fg: '#BF6E5D'
  cat-custom-olive-bg: '#2A3018'
  cat-custom-olive-fg: '#AED581'
  cat-custom-slate-bg: '#1E2630'
  cat-custom-slate-fg: '#90A4AE'
  cat-custom-prune-bg: '#2A1A28'
  cat-custom-prune-fg: '#9C6B8C'
typography:
  display:
    fontFamily: 'Urbanist'
    fontSize: '32px'
    fontWeight: '800'
    letterSpacing: '-0.5px'
  title:
    fontFamily: 'Urbanist'
    fontSize: '20px'
    fontWeight: '600'
  body:
    fontFamily: 'Urbanist'
    fontSize: '15px'
    fontWeight: '400'
    lineHeight: '1.5'
  caption:
    fontFamily: 'Urbanist'
    fontSize: '12px'
    fontWeight: '500'
    letterSpacing: '0.2px'
rounded:
  sm: '8px'
  md: '14px'
  lg: '16px'
  xl: '24px'
  sheet: '28px'
  full: '9999px'
spacing:
  '1': '4px'
  '2': '8px'
  '3': '12px'
  '4': '16px'
  '5': '24px'
  '6': '32px'
  gutter: '16px'
components:
  card-solde:
    background: 'linear-gradient(135deg, {colors.accent} 0%, #4A3FD4 100%)'
    radius: '{rounded.xl}'
    padding: '{spacing.5}'
  bottom-sheet:
    background: '{colors.surface}'
    radius-top: '{rounded.sheet}'
    handle-color: '{colors.border}'
    handle-size: '40px × 4px'
  category-badge:
    size: '40px'
    radius: '{rounded.full}'
    icon-size: '20px'
  fab:
    background: '{colors.accent}'
    size: '56px'
    radius: '{rounded.full}'
    shadow: '0 4px 16px rgba(107, 92, 255, 0.4)'
  button-primary:
    background: '{colors.accent}'
    radius: '{rounded.lg}'
    height: '52px'
    font-weight: '600'
    font-size: '{typography.body.fontSize}'
  nav-bar:
    background: '{colors.surface}'
    border-top: '1px solid {colors.border}'
    height: '64px'
    active-color: '{colors.accent}'
    inactive-color: '{colors.text-secondary}'
  input:
    background: '{colors.surface-raised}'
    radius: '{rounded.md}'
    height: '48px'
    border: '1px solid {colors.border}'
    focus-border: '1px solid {colors.accent}'
    padding: '{spacing.4}'
  segmented-control:
    background: '{colors.surface-raised}'
    active-background: '{colors.accent}'
    active-text: '{colors.text-primary}'
    inactive-text: '{colors.text-secondary}'
    radius: '{rounded.md}'
    height: '40px'
  warning-row:
    background: '#3A2A00'
    border-left: '3px solid {colors.warning}'
  info-banner:
    background: '{colors.surface-raised}'
    border: '1px solid {colors.border}'
    radius: '{rounded.md}'
    padding: '{spacing.3} {spacing.4}'
---

<!-- Maquettes de référence (spines gagnent en cas de conflit) :
  mockups/key-screens-1.html — Auth · Accueil · Scan · Tableau de bord · Saisie manuelle
  mockups/key-screens-2.html — Gestion Catégories (06a–06d : canonique, vide, création icône+couleur, erreur doublon)
  mockups/color-themes-1.html — palette Nuit Violette -->

## Brand & Style

GestBud est l'application qui remplace le cahier. Son utilisateur — l'actif urbain francophone d'Abidjan, Dakar ou Douala — gère aujourd'hui ses finances à la main, dans un carnet. GestBud ne lui propose pas un tableau de bord de banquier ; il lui offre une vision claire de où est passé son argent, poste par poste, mois par mois.

Le registre visuel est premium et sobre. Dark mode par défaut — non par convention fintech, mais parce que le fond sombre permet aux données financières de s'imposer sans compétition. Un seul accent chromatique, le violet `#6B5CFF`, réservé aux actions et aux indicateurs de valeur. Les catégories de dépenses sont le seul endroit où la couleur se multiplie — chacune porte sa teinte propre, reconnaissable d'un coup d'œil dans l'historique.

L'app parle à l'utilisateur directement, en français, au tutoiement. Les messages sont courts et chaleureux sur les succès, neutres et clairs sur les erreurs. Pas d'emojis dans les messages critiques. L'illustration est réservée à deux surfaces : l'écran d'authentification (motif géométrique violet) et les états vides (icône centrale, appel à l'action direct).

## Colors

La palette est construite autour d'un fond navy profond et d'un seul accent violet. Toutes les décisions de couleur découlent de cette contrainte : ne pas disperser l'attention.

- **`bg` (`#0D0F1E`)** — Fond de page. Navy presque noir avec une légère teinte bleue. Toutes les surfaces flottent au-dessus.
- **`surface` (`#181B33`)** — Cartes, bottom sheets, nav bar. Premier niveau d'élévation visible.
- **`surface-raised` (`#1E2240`)** — Champs de saisie, second niveau de card, en-têtes de groupes dans les listes.
- **`accent` (`#6B5CFF`)** — Violet électrique. Utilisé exclusivement pour : le FAB, les CTAs primaires, la carte Solde (gradient), les éléments actifs de la nav bar, le segmented control sélectionné, les sélecteurs de catégories ouverts. Jamais utilisé pour les états d'erreur ni les indicateurs passifs.
- **`accent-dim` (`#2A2460`)** — Version tintée de l'accent. Utilisée pour les fonds de badges, les highlights discrets, jamais en texte.
- **`text-primary` (`#FFFFFF`)** — Texte principal. Montants, titres d'écran, labels de champs.
- **`text-secondary` (`#A8A8C0`)** — Lavande clair. Dates, sous-titres, labels de catégories non sélectionnées, placeholders.
- **`success` (`#00C897`)** — Vert émeraude. Montants de Revenus, variations positives, indicateur de Solde en hausse. Aussi utilisé pour la catégorie Revenu.
- **`danger` (`#FF6B6B`)** — Rouge corail. Montants de Dépenses, variations négatives, Solde négatif.
- **`warning` (`#F5A623`)** — Ambre. Exclusivement pour les lignes de Reçu mal reconnues par l'OCR (montant vide ou libellé illisible). Jamais utilisé pour autre chose.
- **`border` (`#2A2D4A`)** — Séparateur. Utilisé pour les dividers entre lignes de liste, les bordures de champs au repos, le contour de la nav bar.
- **Couleurs de catégories** — Onze paires bg/fg pour les catégories prédéfinies (cf. tokens `cat-*`). Fond toujours teinté sombre (faible luminosité), icône dans la couleur vive correspondante. Ces couleurs ne migrent pas vers d'autres usages.
- **Palette catégories personnalisées** — Six paires bg/fg additionnelles (`cat-custom-rose`, `cat-custom-teal`, `cat-custom-terracotta`, `cat-custom-olive`, `cat-custom-slate`, `cat-custom-prune`), réservées au sélecteur de couleur du Champ Création/Renommage Catégorie. Choisies pour rester visuellement distinctes des onze teintes prédéfinies et de `{colors.accent}` (jamais de violet dans cette palette — l'accent reste exclusif aux actions et à la valeur). Si l'utilisateur crée plus de six catégories personnalisées, la palette boucle depuis `cat-custom-rose`.

## Typography

Police : **Urbanist** (Google Fonts), chargée via `pubspec.yaml`. Quatre rôles :

- **Display** — 32px, ExtraBold (800). Réservé au Solde courant sur la carte d'accueil et le tableau de bord. `font-feature-settings: "tnum"` activé (tabular figures) pour l'alignement des montants.
- **Title** — 20px, SemiBold (600). En-têtes d'écran (AppBar), titres de sections (« Transactions récentes »), total du reçu en en-tête sticky.
- **Body** — 15px, Regular (400). Tout le contenu courant : libellés de transactions, labels de catégories, texte des champs.
- **Caption** — 12px, Medium (500). Dates, sous-titres de lignes, variations mois/mois, labels de nav bar, microcopy.

**Formatage des montants :** séparateur de milliers = espace fine insécable (` `). Exemple : `245 800 FCFA`. La devise `FCFA` est toujours en `caption` inline, jamais en `display`. Les montants de Dépenses sont en `{colors.danger}`, les Revenus en `{colors.success}`, le Solde en `{colors.text-primary}` (blanc pur).

**Signe non-couleur :** la couleur seule ne distingue jamais une Dépense d'un Revenu (accessibilité daltonisme). Chaque montant de transaction est préfixé d'un signe : `−` pour une Dépense, `+` pour un Revenu. Exemples : `−1 500 FCFA` (Dépense), `+450 000 FCFA` (Revenu). Le Solde n'est pas préfixé (ce n'est ni une dépense ni un revenu).

## Layout & Spacing

Grille de base : 4 px. Échelle : 4 / 8 / 12 / 16 / 24 / 32 px. Marge horizontale fixe : 16 px des deux côtés (gutter). Pas de grille multi-colonnes — GestBud est single-column sur toutes les surfaces.

- Padding interne des cartes : 24 px.
- Gap entre cartes : 12 px.
- Padding interne des lignes de liste : 12 px vertical, 0 px horizontal (pleine largeur, séparés par un divider `{colors.border}`).
- La nav bar a une hauteur fixe de 64 px + safe area inférieure. Le FAB est positionné à `−28px` au-dessus du bord supérieur de la nav bar (overlap intentionnel).
- Les bottom sheets ont un padding horizontal de 16 px et un padding supérieur de 8 px (drag handle) + 16 px.

## Elevation & Depth

GestBud utilise l'élévation par différence de teinte, pas par ombre. La hiérarchie est :

1. `bg` (`#0D0F1E`) — fond de page, jamais cliquable.
2. `surface` (`#181B33`) — cartes, bottom sheet, nav bar.
3. `surface-raised` (`#1E2240`) — champs de saisie, lignes actives, second niveau de card.

Les ombres sont réservées à deux éléments : le FAB (`box-shadow: 0 4px 16px rgba(107, 92, 255, 0.4)`) et la carte Solde (légère ombre violet diffuse). Rien d'autre ne porte d'ombre — l'élévation vient de la couleur, pas du shadow.

## Shapes

Les arrondis sont généreux et cohérents. Aucun angle vif dans l'app.

- `xl` (24 px) — Cartes principales (Solde, cartes du tableau de bord).
- `lg` (16 px) — Boutons CTAs, chips de catégories dans le sélecteur.
- `md` (14 px) — Champs de saisie, lignes de liste avec fond, segmented control.
- `sm` (8 px) — Badges de variation (%), petits chips.
- `sheet` (28 px) — Coins supérieurs des bottom sheets uniquement.
- `full` (9999 px) — FAB, pastilles de catégories, avatar utilisateur.

Les images (illustrations d'états vides) suivent exactement le rayon du conteneur qui les accueille.

## Components

**Carte Solde** — Gradient `{colors.accent} → #4A3FD4`, `{rounded.xl}`, padding `{spacing.5}`. Contient : label Caption « Solde courant » en `{colors.text-primary}` opacité pleine (la réduction d'opacité fait chuter le contraste sous le seuil 4.5:1 sur l'extrémité claire du gradient — ne pas réduire), montant en Display blanc, variation du mois en Caption `{colors.success}` ou `{colors.danger}` préfixée du signe `+`/`−`, sparkline SVG blanc en bas. Jamais d'autre contenu.

**FAB** — Cercle `{components.fab.size}`, fond `{colors.accent}`, ombre violet diffuse. Positionné au centre horizontal, émergeant au-dessus de la nav bar. Au tap : bottom sheet FAB Menu s'ouvre avec 2 options (Scan Reçu · Nouvelle transaction). Pas de label texte sur le FAB lui-même, juste l'icône `+`.

**Bottom sheet « Nouvelle transaction »** — Fond `{colors.surface}`, coins supérieurs `{rounded.sheet}`, drag handle centré. Header : titre Body/SemiBold + icône × à droite. Segmented control Dépense/Revenu pleine largeur. Montant en Display centré avec curseur. Champs Catégorie, Date, Note. CTA « Enregistrer » pleine largeur `{components.button-primary}`.

**Pastille de catégorie** — Cercle 40 px, fond `cat-{nom}-bg`, icône 20 px en `cat-{nom}-fg`. Présente dans : lignes de liste Historique, lignes de Reçu, sélecteur de catégories, Tableau de bord.

**Ligne de transaction** — Pastille catégorie à gauche · libellé (Body) + date (Caption/secondary) en colonne · montant (Body, coloré, préfixé `+`/`−`) aligné à droite. Divider `{colors.border}` en bas. Hauteur min. 60 px (cible de tap ≥ 44 px).

**Sélecteur Catégorie** — Bottom sheet héritant de `{components.bottom-sheet}`. Header : titre Body/SemiBold « Choisir une catégorie » + icône × à droite. Liste de pastilles de catégorie (`{components.category-badge}`) en grille 4 colonnes, label Caption sous chaque pastille, catégories prédéfinies puis catégories personnalisées séparées par un divider `{colors.border}` léger. Catégorie sélectionnée : anneau `{colors.accent}` 2 px autour de la pastille.

**Sélecteur Date** — Bottom sheet héritant de `{components.bottom-sheet}`. Header : titre Body/SemiBold « Choisir une date » + icône × à droite. Corps : widget natif de sélection de date (date-picker iOS/Android natif), CTA « Valider » pleine largeur `{components.button-primary}` en pied de sheet.

**Ligne de Catégorie (gestion)** — Fond `{colors.surface}`, padding `{spacing.4}` vertical. Pastille catégorie (`{components.category-badge}`) à gauche · nom (Body) au centre · icône crayon (renommer) + icône corbeille (supprimer) à droite, 24 px chacune, espacées de `{spacing.3}`. Catégories prédéfinies : icônes crayon/corbeille omises (non éditables, non supprimables) — pastille et nom seuls.

**Champ Création/Renommage Catégorie** — Bottom sheet héritant de `{components.bottom-sheet}`. Header : titre Body/SemiBold (« Nouvelle catégorie » ou « Renommer ») + icône × à droite. Corps, dans l'ordre : sélecteur d'icône (grille 4 colonnes d'emojis, même grille que `{components.category-badge}` dans le Sélecteur Catégorie ; icône sélectionnée entourée d'un anneau `{colors.accent}` 2 px), sélecteur de couleur (rangée de 6 pastilles pleines issues de la palette catégories personnalisées, pastille sélectionnée entourée d'un anneau `{colors.text-primary}` 2 px), puis `{components.input}` standard pour le nom, placeholder « Nom de la catégorie ». Préselection par défaut à l'ouverture : première icône du set, première couleur (`cat-custom-rose`) — l'utilisateur peut tout changer avant d'enregistrer. En cas de nom dupliqué (insensible à la casse) : `focus-border` devient `{colors.danger}`, message d'erreur Caption `{colors.danger}` sous le champ.

**Ligne de Reçu** — Fond `{colors.surface}`, `{rounded.md}`. Libellé OCR (Body) + montant (Body, modifiable) + badge Catégorie (dropdown). En état warning : fond `#3A2A00`, bordure gauche 3 px `{colors.warning}`, icône ⚠ ambre visible.

**Skeleton de chargement** — Barres de hauteur variable sur fond `{colors.surface-raised}`, animation pulse (opacité 0.4 → 0.8 → 0.4, 1.2 s). Reproduit exactement la géométrie de la liste de lignes qu'il précède.

**Bannière info** — Fond `{colors.surface-raised}`, bordure `{colors.border}`, `{rounded.md}`. Texte Caption/secondary à gauche, icône × dismissable à droite. Fixe en bas de l'Accueil, au-dessus de la nav bar.

**État vide** — Icône centred SVG en `{colors.accent}` (receipt ou wallet selon la surface), titre Body/SemiBold blanc, CTA `{components.button-primary}`. Fond page, pas de card wrapper.

## Do's and Don'ts

| Do | Don't |
|---|---|
| Un seul accent violet — sur les actions et la valeur | Utiliser `{colors.accent}` pour décorer ou signaler des états passifs |
| Montants en tabular-nums, espace fine comme séparateur de milliers | Arrondir les montants ou omettre la devise |
| Couleurs de catégories uniquement pour les pastilles de catégories | Réutiliser les couleurs `cat-*` pour d'autres éléments d'UI |
| Élévation par différence de teinte (bg → surface → surface-raised) | Ajouter des ombres sur les cartes ordinaires |
| Arrondis généreux et cohérents selon l'échelle définie | Mélanger les rayons — une card est toujours `xl`, un champ toujours `md` |
| `{colors.danger}` pour les Dépenses, `{colors.success}` pour les Revenus | Inverser les couleurs ou les utiliser pour autre chose |
| Préfixer tout montant de `+` (Revenu) ou `−` (Dépense) — la couleur seule ne suffit jamais | Afficher un montant coloré sans signe non-coloré associé |
| `{colors.warning}` exclusivement pour les lignes OCR mal reconnues | Utiliser l'ambre pour les erreurs génériques ou les alertes système |
| Microcopy courte, directe, au tutoiement | Emojis dans les messages d'erreur, de solde négatif, ou de suppression |
