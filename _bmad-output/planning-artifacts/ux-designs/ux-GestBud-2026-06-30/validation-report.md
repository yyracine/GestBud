# Validation Report — GestBud

- **DESIGN.md:** `DESIGN.md`
- **EXPERIENCE.md:** `EXPERIENCE.md`
- **Run at:** 2026-06-30

## Overall verdict

La paire de spines est solide sur ses fondamentaux : les trois flows clés (UJ-1/2/3) sont pleinement réalisés avec protagoniste nommé, étapes numérotées et beat climax ; tous les tokens résolvent ; la discipline d'héritage (sources, noms de composants, glossaire) est propre. Le gap critique structurel est la **Gestion Catégories** (FR-13–FR-16) : une fonctionnalité MVP entièrement scopée n'a aucune spec visuelle ni comportementale dans aucun des deux fichiers.

Les deux lenses additionnelles déplacent sensiblement le tableau. L'accessibilité relève deux problèmes critiques pour une app financière grand public sur Android d'entrée de gamme : deux pastilles de catégorie échouent le contraste WCAG AA, et la couleur est l'unique signal dépense/revenu partout dans l'app. Le microcopy review confirme que les règles de voix sont saines mais que plusieurs moments utilisateurs réels n'ont aucun texte spécifié.

## Category verdicts
- Flow coverage — strong
- Token completeness — strong
- Component coverage — thin
- State coverage — adequate
- Visual reference coverage — n/a (mockups/wireframes pas encore promus à ce stade)
- Bloat & overspecification — strong
- Inheritance discipline — strong
- Shape fit — strong

## Findings by severity

### Critical (4)
**Component coverage** — Aucune spec visuelle ni comportementale pour la surface Gestion Catégories (DESIGN.md + EXPERIENCE.md, absent)
FR-13–FR-16 entièrement scopées mais zéro composant nommé.
Fix: Ajouter au minimum ligne de catégorie en liste, champ création/renommage, dialogue de confirmation de suppression.

**State coverage** — Gestion Catégories : zéro couverture State Patterns (EXPERIENCE.md IA ligne 35)
Aucun état vide, erreur de doublon, confirmation de suppression, ou blocage sur catégorie prédéfinie.
Fix: Ajouter 3–4 lignes State Patterns pour cette surface.

**Accessibility** — Deux paires badge catégorie échouent WCAG AA (DESIGN.md lignes 30-31, 34-35, 87-90)
`cat-education` = 3.19:1, `cat-habillement` = 3.33:1, tous deux sous 4.5:1.
Fix: Éclaircir les tokens fg ou assombrir/désaturer les bg, vérifier par calcul.

**Accessibility** — La couleur est l'unique signal dépense/revenu partout dans l'app (DESIGN.md lignes 151-152, 166, 230 ; EXPERIENCE.md lignes 64, 181)
Échoue WCAG 1.4.1, affecte les ~8% d'hommes daltoniens rouge-vert.
Fix: Ajouter un repère non-coloré obligatoire (préfixe +/−).

### High (10)
**Flow coverage** — Aucun Key Flow ni UJ ne couvre la Gestion Catégories (EXPERIENCE.md IA + Key Flows)
Fix: Ajouter un Key Flow court ou des lignes Component/State Patterns dédiées.

**Component coverage** — Sélecteur Catégorie sans spec visuelle DESIGN.md (EXPERIENCE.md ligne 67)
Fix: Ajouter une entrée DESIGN.md.Components.

**Component coverage** — Sélecteur Date sans spec visuelle (EXPERIENCE.md ligne 68)
Fix: Ajouter une ligne DESIGN.md.Components.

**Accessibility** — Label « Solde courant » à 70% d'opacité sous le seuil de contraste (DESIGN.md ligne 203)
Fix: Supprimer la réduction d'opacité ou la relever à ≥85%.

**Accessibility** — Aucune guidance lecteur d'écran pour segmented control, lignes reçu expandables, swipe-to-delete, menu FAB (EXPERIENCE.md lignes 62-75 vs 108-117)
Fix: Ajouter une ligne par pattern précisant les états annoncés.

**Accessibility** — Swipe-to-delete sans alternative accessible (EXPERIENCE.md lignes 69, 102)
Fix: Ajouter une alternative visible exposée comme action d'accessibilité.

**Microcopy** — Asymétrie de chaleur entre « Reçu enregistré ! » et « Transaction enregistrée. » (EXPERIENCE.md lignes 48-49)
Fix: Harmoniser la chaleur ou documenter la différence comme choix délibéré.

**Microcopy** — Aucun copy pour la confirmation de suppression d'une ligne de reçu (EXPERIENCE.md lignes 69, 102)
Fix: Ajouter une ligne State Patterns avec copy explicite.

**Microcopy** — Aucun copy pour la validation « date fin < date début bloquée » (EXPERIENCE.md ligne 74)
Fix: Clarifier le mécanisme et ajouter le message si applicable.

### Medium (15)
**Flow coverage** — Flow 2 sans chemin d'échec (EXPERIENCE.md lignes 156–169)
Fix: Ajouter cas d'erreur montant à 0 + ligne State Patterns.

**Component coverage** — En-tête sticky Reçu, Entrée Reçu groupé, Sélecteur de Période sans spec visuelle (EXPERIENCE.md lignes 70, 73, 74)
Fix: Ajouter une courte entrée Components par composant.

**Component coverage** — `nav-bar` sans ligne Component Patterns comportementale (DESIGN.md components.nav-bar)
Fix: Ajouter une ligne Component Patterns pour la bottom tab bar.

**State coverage** — Paramètres : zéro couverture State Patterns (EXPERIENCE.md IA ligne 36)
Fix: Ajouter une ligne State Patterns minimale.

**Accessibility** — Token `border` quasi invisible, 1.16–1.42:1 (DESIGN.md lignes 19, 108-114, 174)
Fix: Confirmer un second repère ou éclaircir le token.

**Accessibility** — Cibles tactiles des icônes seules non garanties ≥44pt/48dp (DESIGN.md lignes 205-219)
Fix: Ajouter une guidance hit-slop explicite.

**Accessibility** — Reduce Motion : ambiguïté cross-fade défaut vs accommodation (EXPERIENCE.md ligne 115)
Fix: Clarifier la relation entre défaut et accommodation.

**Accessibility** — Pas de redondance haptique/sonore pour confirmations critiques (EXPERIENCE.md lignes 150, 168)
Fix: Spécifier l'exposition en live-region d'accessibilité.

**Microcopy** — Aucun copy pour le refus de permission caméra (EXPERIENCE.md Flow 1 ligne 143)
Fix: Ajouter une ligne State Patterns, même pattern que « Réseau absent ».

**Microcopy** — Gestion Catégories sans aucun copy (EXPERIENCE.md ligne 35)
Fix: Ajouter Component/State Patterns en miroir du pattern de suppression de transaction.

**Microcopy** — Aucune confirmation de renvoi OTP réussi (EXPERIENCE.md ligne 82)
Fix: Ajouter une confirmation neutre ou préciser réinitialisation silencieuse.

**Microcopy** — Message OCR timeout non cité (EXPERIENCE.md ligne 87)
Fix: Citer explicitement le message.

**Microcopy** — Règle anti-emoji formulée différemment entre fichiers, ⚠ non réconcilié (DESIGN.md lignes 138, 232 ; EXPERIENCE.md ligne 44)
Fix: Clarifier que la règle vise le texte, pas les icônes système.

### Low (13)
- Token completeness — DESIGN.md ne restate jamais de ratio de contraste numérique. Fix: ajouter une phrase de confirmation.
- Token completeness — Placeholder `{nom}` ambigu avec la syntaxe de référence. Fix: note d'une ligne.
- Component coverage — `input` sans ligne comportementale dédiée. Fix: noter le choix de consolidation.
- Flow coverage — Flow 3 sans cas tableau de bord totalement vide. Fix: optionnel.
- State coverage — Pas d'état « mode édition » pour Détail Transaction (FR-7). Fix: ajouter une ligne dédiée.
- State coverage — Pas d'état « permission caméra refusée ». Fix: ajouter une ligne State Patterns.
- Inheritance discipline — Dérive de nommage entre fichiers sur 3 composants. Fix: aligner les noms exacts.
- Accessibility — Lecture de l'espace fine par lecteurs d'écran non résolue. Fix: résoudre via semanticsLabel avant build.
- Microcopy — Incohérence « francs CFA » vs « FCFA ». Fix: note d'exception TTS.
- Microcopy — Dérive terminologique « ticket » vs « Reçu » dans Flow 1. Fix: note glossaire.
- Microcopy — « Opération réussie ✓ » correctement utilisé comme contre-exemple. Aucune action requise.
- Microcopy — Style d'ellipse non normalisé. Fix: note de style.
- Accessibility — Scope français uniquement documenté comme intentionnel. Aucune action requise — suivre en v2.

## Reviewer files
- `review-rubric.md`
- `review-accessibility.md`
- `review-microcopy.md`
