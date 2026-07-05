# Réconciliation : brief.md → prd.md

## Verdict
Le PRD couvre fidèlement la grande majorité du brief, mais introduit deux divergences structurelles majeures qui contredisent des décisions explicites du brief : la plateforme cible (PWA → app native) et l'architecture de stockage (localStorage cloud-optionnel → local-first intégral).

---

## Écarts identifiés

- **haut** Plateforme cible — Le brief spécifie explicitement une **PWA mobile-first, optimisée Android**. Le PRD décide unilatéralement d'une **application mobile native cross-platform (iOS et Android)** distribuée via App Store et Google Play. Il s'agit d'une décision architecturale majeure (coût, complexité, délai de soumission stores) absente du brief et non justifiée dans le PRD. *Suggestion :* Soit aligner le PRD sur la PWA du brief, soit documenter la décision de changement de plateforme comme une décision architecturale consciente, avec justification, et faire valider par le PM/commanditaire avant de continuer.

- **haut** Architecture de stockage — Le brief ne dit rien d'un stockage purement local : il mentionne un OCR cloud et une authentification OTP, sans préciser comment les données sont persistées. Le PRD tranche vers un **stockage 100 % local (SQLite embarqué), sans backend**, avec synchronisation cloud explicitement hors périmètre. Ce choix a des implications fortes (perte de données en cas de réinitialisation, pas de multi-appareil). Le brief n'exclut pas un backend ; le PRD l'exclut sans mandate du brief. *Suggestion :* Documenter ce choix architectural dans une section « Décisions structurelles » et confirmer qu'il est aligné avec les contraintes réelles du projet (budget, hébergement, etc.).

- **moyen** iOS dans le périmètre MVP — Le brief classe explicitement l'**application native iOS hors périmètre MVP** (« Android couvre +85 % du marché ; PWA suffit »). Le PRD inclut iOS dans le périmètre MVP (§6.1, NFRs). *Suggestion :* Retirer iOS du périmètre MVP ou ajouter une justification explicite du revirement.

- **moyen** Critères de succès — Le brief définit des critères simples et qualitatifs (20 utilisateurs, 8 mois, usage à chaque achat, rétention mensuelle). Le PRD les enrichit considérablement avec des cibles chiffrées (SM-1 ≥ 90 %, SM-2 > 50 %, SM-3 ≥ 3/semaine, SM-4, SM-5 < 20 %, contre-métrique SM-C1). L'enrichissement est positif mais **SM-2 (adoption du scan > 50 %)** est une cible absente du brief qui pourrait fausser les priorités si l'OCR s'avère peu fiable sur les reçus locaux. *Suggestion :* Conserver les métriques enrichies, mais noter que SM-2 est une cible ajoutée par le PRD, non issue du brief, et la conditionner à la validation de l'hypothèse OCR (A-2).

- **bas** Différenciateur « moins de 30 secondes » — Le brief cite ce critère dans la section différenciateurs (« moins de 30 secondes du scan à la validation »). Le PRD le reprend dans la description de §4.3 et dans la vision, ce qui est correct, mais il n'est pas formalisé comme critère de performance mesurable dans les NFRs (seul le timeout OCR à 10 s est spécifié). *Suggestion :* Ajouter un NFR explicite : « Le flux complet scan → validation doit être réalisable en ≤ 30 secondes sur un réseau 4G standard. »

- **bas** Profils secondaires (étudiants, commerçants) — Le brief mentionne explicitement des profils secondaires non prioritaires pour le MVP. Le PRD liste dans §2.2 les non-utilisateurs v1 (commerçants, utilisateurs Mobile Money, zone rurale) mais **n'identifie pas les étudiants** comme profil secondaire potentiel pour une V2. *Suggestion :* Ajouter les étudiants dans une note de §2.2 comme profil secondaire envisagé post-MVP, conformément au brief.

---

## Éléments bien couverts

- **Problème** — Le problème de fond (ne pas savoir où est passé l'argent, ticket mixte non décomposé, cahier insuffisant) est restitué fidèlement dans la vision et les Jobs to Be Done (§2.1).
- **Persona primaire** — Aminata (cadre urbaine, Dakar, Android, 4G, responsable d'un foyer) est détaillée avec précision dans les parcours utilisateur UJ-1 à UJ-3.
- **Villes cibles** — Dakar, Abidjan, Douala sont mentionnées dans les parcours et les questions ouvertes (§8.1).
- **Trois modes de saisie** — Scan de reçu, saisie manuelle, enregistrement de revenus couverts en §4.2, §4.3 avec des FR granulaires.
- **OCR cloud article par article** — Google Vision / Mindee, extraction ligne par ligne, catégorisation IA, validation ligne par ligne : couvert en FR-9 à FR-12 avec précision.
- **Tableau de bord mensuel** — Solde en temps réel, totaux par catégorie, graphique d'évolution, comparaison mois/mois : tous couverts en FR-17 à FR-21.
- **Authentification OTP SMS via Africa's Talking** — Couverte en §4.1, FR-1 à FR-4.
- **Périmètre hors MVP** — Mobile Money, email, reçus manuscrits, monétisation : tous listés en §6.2 avec les mêmes justifications que le brief.
- **Différenciateurs** — Absence d'APIs bancaires, OCR article par article, friction minimale : présents dans la vision.
- **Hypothèses et risques** — Les quatre hypothèses du brief (précision OCR, 4G fiable, 20 utilisateurs accessibles, transfert de l'habitude cahier) sont toutes couvertes : A-2 (OCR), NFR réseau (4G), SM-1/SM-3 (20 utilisateurs, usage régulier), A-4 et la vision (transfert cahier). Deux sont taguées `[ASSUMPTION]` dans le PRD.
- **Catégories prédéfinies adaptées au marché** — Liste de 10 catégories couvrant les postes courants d'Afrique subsaharienne francophone (§4.4).
- **Cible beta** — 20 utilisateurs, 8 mois : repris fidèlement dans la vision et §7.
