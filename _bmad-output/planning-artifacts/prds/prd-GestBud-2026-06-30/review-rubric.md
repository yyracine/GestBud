# PRD Quality Review — GestBud

## Overall verdict

Un PRD solide pour un MVP personnel : les FR sont numérotés, les conséquences testables sont précises, les hypothèses sont indexées, et la vision est honnête sur le marché cible. Les risques principaux sont l'absence de décision sur des choix architecturaux bloquants (OCR provider, framework mobile, devise) qui restent ouverts au moment où l'implémentation devrait démarrer, et quelques lacunes de scope qui pourraient créer des frictions pour un UX designer ou un architecte qui lirait ce PRD sans contexte supplémentaire.

---

## 1. Decision-readiness — adequate

Le PRD permet à un développeur seul (le cas d'usage déclaré §0) de commencer l'implémentation sur ~70 % des features. Cependant, trois questions ouvertes (§8) sont en réalité des décisions bloquantes pour FR-9 à FR-12, FR-1 à FR-4, et le modèle de données devise — elles auraient dû être tranchées ou escaladées avec un délai explicite.

### Findings

- **high** Choix OCR non tranché (§8 Q1 + §4.3 FR-10) — Le PRD liste Google Vision et Mindee sans recommandation ni critère de décision. Un ingénieur qui implémenterait FR-10 devrait choisir arbitrairement ou attendre. *Fix :* Désigner un provider par défaut avec critère override (ex. "Mindee par défaut ; bascule si taux d'erreur > X% au test").
- **high** Framework mobile non tranché (§8 Q6) — Le choix React Native / Flutter impacte directement le moteur SQLite (FR-22), l'accès caméra (FR-9), et le workflow de build. Il est listé comme "à trancher en phase architecture" mais aucune phase n'est définie. *Fix :* Ajouter une contrainte ou un délai de décision (ex. "À trancher avant story 1, semaine 1").
- **high** Devise non tranchée (§8 Q3) — FCFA XOF vs XAF impacte le modèle de données et l'affichage dans FR-17 à FR-21. Si la cible est Dakar uniquement pour la beta, le dire et fermer la question. *Fix :* Déclarer "Beta V1 : XOF uniquement. V2 : devise configurable" et clore l'OQ.
- **medium** Ambiguïté localStorage vs SQLite (§4.1 + §4.6) — La §4.1 mentionne "localStorage" (terme web/React Native AsyncStorage) et la §4.6 mentionne "SQLite ou équivalent". A-1 et FR-22 se contredisent potentiellement si les données transactions sont en SQLite mais la session en localStorage/AsyncStorage. Un ingénieur doit inférer l'intention. *Fix :* Distinguer explicitement : session token → AsyncStorage/Keychain, données financières → SQLite.

---

## 2. Substance over theater — strong

Le PRD évite les pièges courants. Les personas sont ancrés sur des Jobs to Be Done concrets, pas sur des attributs démographiques vides. Les NFRs sont chiffrés (44 px, 4.5:1, < 100 ms, ≤ 10 s). Les métriques ont des cibles numériques et une contre-métrique. La vision §1 ne survend pas : elle nomme le risque (précision OCR sur reçus locaux) comme hypothèse critique à valider.

### Findings

- **low** Persona unique (§2.3) — Aminata est bien construite mais c'est la seule persona. UJ-2 et UJ-3 réutilisent le même persona, ce qui est cohérent mais laisse invisible un cas limite : l'utilisateur masculin urbain avec des revenus irréguliers (indépendant, commerçant formel). Pour un MVP 20 users, c'est acceptable ; à noter si la beta révèle une diversité de profils. *Fix :* Aucun changement requis pour le MVP ; ajouter un second persona en V1.1 si la beta l'exige.
- **low** SM-1 cible ambitieuse (§7) — 90 % de rétention mensuelle sur 8 mois est élevé même pour une beta recrutée à la main. Si non atteint, le PRD ne dit pas ce que ça signifie pour la décision de continuer. *Fix :* Ajouter un seuil de "pivot signal" (ex. "si SM-1 < 60 % à M3, revoir le flux scan avant de continuer la beta").

---

## 3. Strategic coherence — strong

Le PRD a une thèse claire et maintenue du §1 au §7 : remplacer le cahier par le scan de reçu, pour un marché sans bancarisation, avec un storage local pour éviter la dépendance réseau. Les features servent toutes cette thèse. Les non-objectifs (§5) ferment explicitement les dérives classiques (Mobile Money, budgets, export). L'arc "scan → catégorisation → tableau de bord" est lisible.

### Findings

- **low** Tension non résolue entre "30 secondes" et "corriger chaque ligne" (§4.3) — Le temps cible du flux scan est < 30 secondes (§4.3 description), mais FR-11 permet de modifier montant, catégorie, supprimer et ajouter des lignes. Sur un reçu de 25 articles, la correction ligne par ligne peut dépasser 30 secondes facilement. *Fix :* Préciser que les 30 secondes s'appliquent au flux sans correction (happy path), et que la correction est optionnelle — ou proposer une validation en masse ("Tout valider").

---

## 4. Done-ness clarity — strong

C'est le point le plus solide du PRD. Chaque FR a des conséquences testables en phrases actives vérifiables. FR-5 : "Le montant ne peut pas être nul ou négatif." FR-17 : "Un Solde négatif est affiché avec une indication visuelle distincte." Ces formulations permettent d'écrire des tests d'acceptance directement.

### Findings

- **medium** FR-19 graphique : "lisible sur écran 5 pouces" insuffisant (§4.5 FR-19) — La conséquence testable mentionne "éléments interactifs ≥ 44 px" mais ne définit pas ce qu'est "lisible" pour le graphique lui-même (nombre de points affichés, lisibilité des labels). *Fix :* Ajouter : "Les labels d'axe sont lisibles sans zoom sur un écran 360 dp de largeur" ou déléguer à UX.
- **medium** FR-12 groupement visuel conditionnel (§4.3 FR-12) — A-3 tague le groupement comme assumption, mais aucune conséquence testable ne décrit l'état de l'historique sans groupement (si A-3 est rejetée). *Fix :* Ajouter une conséquence testable pour le cas où le groupement n'est pas implémenté en V1 : "Au minimum, chaque Ligne apparaît comme une Dépense distincte avec la date du reçu."
- **low** FR-23 "première connexion réussie" ambigu (§4.6 FR-23) — Est-ce après le premier OTP validé, ou à chaque première session de la journée ? *Fix :* Préciser "une seule fois, au premier accès authentifié après installation."

---

## 5. Scope honesty — adequate

Les [ASSUMPTION] et [NOTE FOR PM] font leur travail : A-1 à A-4 sont indexées en §9 avec backref de section, et les NOTE FOR PM signalent les reports en V2. Les non-objectifs §5 sont exhaustifs. La §6.2 inclut un tableau avec raisons de report.

### Findings

- **high** Risque de perte de données sous-pondéré (§4.6 + §5) — FR-23 avertit l'utilisateur, mais le PRD ne définit pas ce qui se passe si l'utilisateur change de téléphone pendant la beta (cas probable sur 8 mois). Aucun FR ne couvre un workflow "j'ai un nouveau téléphone". *Fix :* Ajouter un [NOTE FOR PM] en §4.6 : "Cas de changement d'appareil : données perdues. À documenter dans les instructions beta pour éviter la déception." Ou ajouter FR-24 : export/import manuel JSON comme filet de sécurité beta.
- **medium** Double mention de la synchronisation dans les non-objectifs (§5) — "Synchronisation des données entre plusieurs appareils." apparaît deux fois de suite. *Fix :* Supprimer la ligne dupliquée.
- **medium** Photo OCR : politique de rétention non résolue (§Contraintes) — Le PRD dit "Vérifier la politique de rétention d'images du fournisseur retenu avant le lancement beta" mais c'est un pre-condition bloquante pour la beta, pas un nice-to-have. *Fix :* Élever en question ouverte §8 avec statut "bloquant avant beta" et assigner à l'architecte.
- **low** Absence d'un FR pour l'onboarding initial (hors OTP) — Le flux "première utilisation" (avant qu'Aminata ait des données) n'est pas couvert. L'écran d'accueil avec zéro transaction est-il vide, ou y a-t-il un état vide guidé ? *Fix :* Ajouter un NOTE FOR PM ou un FR-0 optionnel pour l'état vide de l'écran d'accueil.

---

## 6. Downstream usability — adequate

Le PRD peut alimenter UX et architecture sur ~80 % du périmètre. Les User Journeys §2.3 sont suffisamment détaillés pour un wireframe. Les FR numérotés globalement (FR-1 à FR-23) et le glossaire §3 permettent un découpage en stories direct. La section §4.6 donne les contraintes SQLite à l'architecte.

### Findings

- **high** Aucun état de l'écran d'accueil défini (§4 global) — Les FR décrivent des actions, pas des surfaces. Un UX designer ne sait pas ce qui s'affiche sur l'écran d'accueil entre UJ-1 et UJ-3 : accès rapide au scan ? liste des transactions récentes ? tableau de bord par défaut ? *Fix :* Ajouter un FR ou une description de surface pour l'écran principal (Home) : "L'écran d'accueil affiche [X] et donne accès au Scan et à la Saisie via [Y]."
- **medium** Navigation entre écrans non spécifiée — Le PRD liste des features mais pas d'arborescence ou de flux de navigation. Un architecte ne sait pas si le tableau de bord est la racine ou si c'est l'historique. *Fix :* Ajouter un schéma de navigation minimaliste (5 lignes textuelles suffisent : Home → Dashboard, Home → Scan, Home → +Transaction, etc.) ou déléguer explicitement à UX en phase 2.
- **low** FR-13 : ordre d'affichage délégué à UX sans signal (§4.4 FR-13) — "à trancher en UX" est correct, mais sans contrainte UX (ex. "les prédéfinies doivent être visibles sans scroll sur un écran standard"), la décision flotte. *Fix :* Ajouter une contrainte orientante : "Les catégories les plus utilisées doivent être accessibles en < 2 taps."

---

## 7. Shape fit — strong

La forme est bien calibrée pour un MVP personnel 20 users : pas de roadmap à 18 mois, pas de matrices de priorité RICE, pas d'analyse concurrentielle exhaustive. Le PRD est court, dense, et actionnable. Le §0 définit clairement l'audience (le développeur = Racine) et l'usage du document. La calibration "intermédiaire" est respectée.

### Findings

- **low** Section "Contraintes et confidentialité" est déplacée (entre §4 et §5) — Elle n'a pas de numéro de section, ce qui crée un flottement dans la structure. Pour un PRD à numérotation stricte, ça crée un problème de référencement en stories. *Fix :* Numéroter comme §4.7 ou déplacer en §8bis / annexe.
- **low** §8 questions ouvertes : numérotation incohérente (§8) — La Q6 apparaît avant la Q5 dans le document (erreur de numérotation). *Fix :* Renuméroter Q1 à Q6 dans l'ordre.

---

## Mechanical notes

- **Glossaire drift :** Le terme "localStorage" est utilisé en §4.1 et §9 (A-1, A-4) mais contredit par "SQLite ou équivalent" en §4.6. Le glossaire §3 ne définit pas le mécanisme de stockage. Risque de divergence d'implémentation.
- **ID continuity :** FR-1 à FR-23 sont continus et sans saut. Correct.
- **Assumptions Index roundtrip :** A-1 à A-4 sont toutes référencées dans les FR avec backref de section ET indexées en §9. Roundtrip complet et propre.
- **NOTE FOR PM :** 4 notes présentes (§4.3, §4.6, §5, §6.2). Toutes pertinentes, aucune redondante.
- **Duplicate non-objectif :** §5 liste deux fois "Synchronisation des données entre plusieurs appareils."
- **Numérotation §8 :** Q6 avant Q5 — erreur d'ordre dans le document source.
