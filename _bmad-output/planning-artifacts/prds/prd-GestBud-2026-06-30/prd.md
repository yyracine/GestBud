---
title: "PRD : GestBud"
status: final
created: 2026-06-30
updated: 2026-06-30
---

# PRD : GestBud

## 0. Objet du document

Ce PRD s'adresse au développeur (Racine) qui construira GestBud, et servira de référence pour les workflows UX, architecture et découpage en stories. Il est organisé autour de fonctionnalités groupées avec des FR numérotés globalement. Les hypothèses non confirmées sont taguées `[ASSUMPTION]` et indexées en §11. Le brief produit (`brief.md`, 2026-06-30) est le document source amont ; ce PRD en est la traduction opérationnelle.

---

## 1. Vision

GestBud est une application mobile native (iOS et Android) de gestion financière personnelle conçue pour les actifs urbains francophones d'Afrique subsaharienne qui tiennent aujourd'hui leurs comptes dans un cahier. L'application remplace ce cahier en proposant trois modes de saisie complémentaires — scan de Reçu, saisie manuelle, enregistrement de revenus — et un Tableau de bord mensuel qui donne à l'utilisateur une visibilité réelle sur ses postes de dépense. Les données sont stockées localement sur l'appareil, sans dépendance à un backend cloud.

Là où les apps occidentales exigent une connexion bancaire inexistante dans ce marché, GestBud part du ticket de caisse : l'OCR cloud lit chaque article, l'IA propose une Catégorie, l'utilisateur valide. Ce flux transforme un Reçu de 25 000 FCFA mélangé (alimentation + ménage + hygiène) en données exploitables en moins de 30 secondes.

Le MVP cible 20 utilisateurs beta sur 8 mois. Il valide deux hypothèses critiques : la précision de l'OCR sur les reçus locaux, et le transfert de l'habitude cahier vers l'app.

---

## 2. Utilisateur cible

### 2.1 Jobs to Be Done

- **Savoir où est passé mon argent** en fin de mois, poste par poste — pas seulement le Solde bancaire.
- **Décomposer un achat mixte** (un ticket de supermarché) sans ressaisir chaque article à la main.
- **Suivre mon Solde en temps réel** sans faire le calcul mental à chaque achat.
- **Identifier les postes à réduire** pour économiser sur le mois suivant.
- **Avoir un outil que j'utilise à chaque achat** — pas une app abandonnée après deux semaines.

### 2.2 Non-utilisateurs (v1)

- Commerçants gérant une trésorerie d'entreprise.
- Utilisateurs souhaitant connecter un compte bancaire ou Mobile Money.
- Utilisateurs en zone rurale ou sans connexion 4G fiable.
- Étudiants et commerçants (profils secondaires identifiés dans le brief) — non prioritaires pour le MVP, potentiellement adressés en V2.

### 2.3 Parcours utilisateur clés

**UJ-1. Aminata scanne son ticket après les courses à Auchan.**
- **Persona + contexte :** Aminata, cadre à Dakar, gère les dépenses d'un foyer de 4 personnes. Elle rentre de courses avec un ticket de 38 000 FCFA mélangé alimentation/hygiène.
- **État d'entrée :** Authentifiée, sur l'écran d'accueil.
- **Parcours :** Appuie sur Scan → pointe son téléphone sur le ticket → l'app envoie la photo à l'OCR → les Lignes apparaissent avec une Catégorie suggérée par Ligne → elle corrige deux Lignes mal catégorisées → valide le Reçu.
- **Climax :** Le Solde se met à jour ; le poste Alimentation affiche les 22 000 FCFA imputés.
- **Résolution :** Elle range le ticket. Pour le reste du mois, elle sait ce qu'il reste.
- **Cas d'erreur :** L'OCR rate une Ligne illisible → la Ligne apparaît avec le montant vide et Catégorie « Autre » → Aminata saisit le montant, choisit la Catégorie, valide.

**UJ-2. Aminata note un taxi pris au marché.**
- **Persona + contexte :** Même persona, achat sans reçu.
- **État d'entrée :** Authentifiée, n'importe quel écran.
- **Parcours :** Appuie sur « + » → choisit Dépense → saisit 1 500 FCFA, Catégorie Transport, date du jour → valide.
- **Climax :** La Transaction apparaît dans l'historique, le Solde est mis à jour.
- **Résolution :** 10 secondes, elle remet son téléphone dans la poche.

**UJ-3. Aminata consulte son bilan de fin de mois.**
- **Persona + contexte :** Même persona, 30 du mois, bilan mensuel.
- **État d'entrée :** Authentifiée, ouvre le Tableau de bord.
- **Parcours :** Voit son Solde actuel → fait défiler les totaux par Catégorie → consulte le graphique d'évolution → compare Alimentation juin vs. mai → identifie que Santé a doublé (médicaments d'un enfant malade).
- **Climax :** Elle sait que juillet, il faudra réduire les sorties pour compenser.
- **Résolution :** Elle ferme l'app avec un plan concret pour le mois suivant.

---

## 3. Glossaire

- **Transaction** — Enregistrement d'un mouvement financier (Dépense ou Revenu). Chaque Transaction a un montant, une date, une Catégorie, et optionnellement une note.
- **Dépense** — Transaction de type sortie d'argent.
- **Revenu** — Transaction de type entrée d'argent (salaire, virement, revenu ponctuel).
- **Reçu** — Document physique (ticket de caisse) photographié pour extraction OCR. Un Reçu génère une ou plusieurs Lignes.
- **Ligne** — Article individuel extrait d'un Reçu par l'OCR. Une Ligne a un libellé, un montant, et une Catégorie suggérée.
- **Devise** — XOF (Franc CFA BCEAO), utilisé par le marché Beta V1 (Sénégal, Côte d'Ivoire). XAF (Franc CFA BEAC, Cameroun) prévu en V2 ; l'app est conçue pour supporter une Devise configurable.
- **Catégorie** — Label thématique attribué à une Transaction ou une Ligne. Peut être prédéfinie ou personnalisée.
- **Catégorie prédéfinie** — Catégorie fournie par le système à l'installation (non supprimable).
- **Catégorie personnalisée** — Catégorie créée par l'utilisateur (modifiable, supprimable).
- **Solde** — Différence cumulée entre tous les Revenus et toutes les Dépenses enregistrées depuis la première utilisation, toutes périodes confondues.
- **Poste de dépense** — Montant total des Dépenses d'une Catégorie sur une Période donnée.
- **Période** — Plage de dates sélectionnée pour l'analyse du Tableau de bord (mois calendaire ou période custom).
- **Tableau de bord** — Surface principale de visualisation : Solde, Postes de dépense, graphique d'évolution, comparaison mois/mois.
- **OTP** — Code à usage unique à 6 chiffres envoyé par SMS pour l'authentification.

---

## 4. Fonctionnalités

### 4.1 Authentification

**Description :** L'utilisateur s'inscrit et se connecte avec son numéro de téléphone. Un OTP est envoyé par SMS via Africa's Talking. Aucun mot de passe n'est stocké. La session est maintenue en localStorage jusqu'à déconnexion explicite. Réalise UJ-1, UJ-2, UJ-3 (état d'entrée).

**Exigences fonctionnelles :**

#### FR-1 : Inscription par numéro de téléphone
L'utilisateur peut s'inscrire en saisissant son numéro de téléphone au format international. Le système envoie un OTP via Africa's Talking SMS.

**Conséquences testables :**
- L'OTP est reçu en moins de 60 secondes dans les conditions réseau normales.
- Un numéro déjà inscrit déclenche un flux de connexion, pas une double inscription.
- Le numéro est validé côté client (format E.164) avant l'envoi de la requête.

#### FR-2 : Validation OTP et accès
L'utilisateur peut saisir l'OTP reçu pour accéder à l'application. La session est persistée en localStorage.

**Conséquences testables :**
- Un OTP invalide ou expiré (> 10 minutes) affiche un message d'erreur et propose de renvoyer.
- Après validation, l'utilisateur est redirigé vers l'écran d'accueil sans ressaisir ses identifiants à la prochaine ouverture de l'app.

#### FR-3 : Renvoi d'OTP
L'utilisateur peut demander un renvoi d'OTP si le premier n'est pas reçu, après un délai d'attente de 60 secondes.

**Conséquences testables :**
- Le bouton « Renvoyer » est désactivé pendant 60 secondes après chaque envoi.
- Un compteur visible indique le temps restant avant de pouvoir renvoyer.

#### FR-4 : Déconnexion
L'utilisateur peut se déconnecter depuis l'app, ce qui efface la session du localStorage.

**Conséquences testables :**
- Après déconnexion, l'accès à l'application redirige vers l'écran d'authentification.
- [ASSUMPTION : A-1] Les données de Transactions sont conservées en localStorage après déconnexion — seule la session est effacée.

---

### 4.2 Saisie manuelle de Transactions

**Description :** Pour les achats sans reçu (transport, marché, transferts d'argent) et les revenus, l'utilisateur saisit directement montant, Catégorie et date. La note est optionnelle. Les Transactions existantes peuvent être modifiées ou supprimées après validation. Réalise UJ-2.

**Exigences fonctionnelles :**

#### FR-5 : Création d'une Dépense manuelle
L'utilisateur peut créer une Dépense en saisissant un montant (FCFA), une Catégorie et une date (par défaut : aujourd'hui). Une note est optionnelle.

**Conséquences testables :**
- Le montant ne peut pas être nul ou négatif.
- La date peut être antérieure à aujourd'hui (saisie différée autorisée).
- La Transaction apparaît dans l'historique et le Solde se met à jour immédiatement après validation.

#### FR-6 : Création d'un Revenu manuel
L'utilisateur peut créer un Revenu (salaire, virement, revenu ponctuel) selon la même logique que FR-5.

**Conséquences testables :**
- Le type Revenu est visuellement distinct d'une Dépense dans l'historique (couleur ou icône).
- Le Solde augmente immédiatement après ajout d'un Revenu.

#### FR-7 : Modification d'une Transaction existante
L'utilisateur peut modifier n'importe quel champ d'une Transaction déjà validée (montant, Catégorie, date, note).

**Conséquences testables :**
- Le Solde et les Postes de dépense sont recalculés immédiatement après modification.
- La modification est possible aussi bien pour les Transactions manuelles que pour les Lignes issues d'un Reçu.

#### FR-8 : Suppression d'une Transaction
L'utilisateur peut supprimer une Transaction après confirmation explicite.

**Conséquences testables :**
- Une confirmation est demandée avant suppression (action non réversible).
- Le Solde et les Postes de dépense sont recalculés immédiatement après suppression.

---

### 4.3 Scan de Reçu

**Description :** Flux principal de GestBud. L'utilisateur photographie un ticket de caisse ; l'OCR cloud Mindee extrait chaque article ; l'IA suggère une Catégorie par Ligne ; l'utilisateur valide, corrige ou supprime chaque Ligne avant imputation. Le flux cible moins de 30 secondes du scan à la validation pour un Reçu standard. Réalise UJ-1.

**Exigences fonctionnelles :**

#### FR-9 : Capture photo du Reçu
L'utilisateur peut déclencher la caméra native depuis l'app pour photographier un Reçu, ou sélectionner une photo existante depuis la galerie.

**Conséquences testables :**
- L'app demande la permission caméra/galerie au premier accès et explique pourquoi.
- La photo est transmise à l'API OCR sans être stockée localement de façon permanente.

#### FR-10 : Extraction OCR et affichage des Lignes
Le système envoie la photo à l'API Mindee et affiche les Lignes extraites (libellé + montant) avec une Catégorie suggérée par l'IA pour chaque Ligne. En cas de précision insuffisante sur les reçus tests locaux, Google Vision API constitue le provider de bascule.

**Conséquences testables :**
- Un état de chargement est affiché pendant l'appel OCR.
- Si l'API OCR est indisponible ou dépasse 10 secondes, un message d'erreur s'affiche avec l'option de saisir le Reçu manuellement.
- [ASSUMPTION : A-2] L'IA utilise un modèle de correspondance libellé → Catégorie (règles ou modèle léger) — pas d'entraînement en ligne sur les données de l'utilisateur.

#### FR-11 : Validation et correction des Lignes
L'utilisateur peut, pour chaque Ligne extraite : valider la Catégorie suggérée, changer la Catégorie, modifier le montant, supprimer la Ligne, ou ajouter une Ligne manquante manuellement.

**Conséquences testables :**
- Chaque Ligne affiche : libellé, montant (modifiable), Catégorie (sélecteur modifiable).
- L'utilisateur peut supprimer une Ligne (ex. : article dupliqué par l'OCR).
- L'utilisateur peut ajouter une Ligne vierge (libellé, montant, Catégorie).
- Le total du Reçu est recalculé dynamiquement à chaque modification.

#### FR-12 : Validation globale du Reçu
L'utilisateur peut valider l'ensemble du Reçu après corrections. Chaque Ligne validée est créée comme une Dépense distincte dans l'historique.

**Conséquences testables :**
- Le Solde et les Postes de dépense sont mis à jour pour chaque Ligne imputée.
- [ASSUMPTION : A-3] Les Transactions issues d'un même Reçu sont regroupées visuellement dans l'historique (tag ou section « Reçu du JJ/MM »).

**Hors périmètre :**
- OCR sur reçus manuscrits ou tickets de marchés informels.
- Mémorisation des corrections de Catégorie pour améliorer les suggestions futures. [NOTE FOR PM : À envisager en V2 si le dataset de corrections utilisateur devient exploitable.]

---

### 4.4 Gestion des Catégories

**Description :** Le système fournit une liste de Catégories prédéfinies couvrant les postes courants du marché cible. L'utilisateur peut créer, renommer et supprimer des Catégories personnalisées. Réalise UJ-1, UJ-2.

**Catégories prédéfinies (liste initiale) :** Alimentation, Transport, Santé & Pharmacie, Hygiène & Entretien, Logement & Factures, Éducation, Loisirs & Sorties, Habillement, Transferts & Épargne, Autre.

**Exigences fonctionnelles :**

#### FR-13 : Affichage des Catégories disponibles
Lors de toute saisie nécessitant une catégorisation, l'utilisateur voit la liste complète des Catégories (prédéfinies + personnalisées) dans un sélecteur.

**Conséquences testables :**
- Les Catégories prédéfinies apparaissent en premier, les personnalisées ensuite (ou triées alphabétiquement — à trancher en UX).

#### FR-14 : Création d'une Catégorie personnalisée
L'utilisateur peut créer une Catégorie personnalisée en saisissant un nom unique.

**Conséquences testables :**
- Le nom doit être unique (validation insensible à la casse).
- La nouvelle Catégorie est immédiatement disponible dans tous les sélecteurs de l'app.

#### FR-15 : Modification d'une Catégorie personnalisée
L'utilisateur peut renommer une Catégorie personnalisée.

**Conséquences testables :**
- Le nouveau nom se propage à toutes les Transactions existantes qui utilisaient cette Catégorie.
- Les Catégories prédéfinies ne sont pas renommables.

#### FR-16 : Suppression d'une Catégorie personnalisée
L'utilisateur peut supprimer une Catégorie personnalisée après confirmation.

**Conséquences testables :**
- Les Transactions associées sont réaffectées à « Autre » après suppression.
- La suppression est bloquée pour les Catégories prédéfinies.

---

### 4.5 Tableau de bord

**Description :** Surface principale de consultation. Affiche le Solde courant, les Postes de dépense par Catégorie pour la Période sélectionnée, un graphique linéaire d'évolution du Solde dans le temps, et une comparaison des Postes mois/mois. L'utilisateur peut basculer entre mois calendaire et Période custom. Réalise UJ-3.

**Exigences fonctionnelles :**

#### FR-17 : Affichage du Solde
Le système affiche le Solde courant en haut du Tableau de bord, mis à jour en temps réel.

**Conséquences testables :**
- Le Solde est recalculé après chaque ajout, modification ou suppression de Transaction.
- Un Solde négatif est affiché avec une indication visuelle distincte (couleur rouge ou indicateur).

#### FR-18 : Totaux par Catégorie
Le système affiche le Poste de dépense pour chaque Catégorie active sur la Période sélectionnée, triés par montant décroissant.

**Conséquences testables :**
- Seules les Catégories ayant au moins une Transaction sur la Période s'affichent.
- La somme de tous les Postes est égale au total des Dépenses de la Période.

#### FR-19 : Graphique d'évolution du Solde
Le système affiche un graphique linéaire montrant l'évolution du Solde jour par jour sur la Période sélectionnée.

**Conséquences testables :**
- Chaque point correspond à la valeur du Solde en fin de journée (Revenus – Dépenses cumulés jusqu'à ce jour).
- Le graphique est lisible sur un écran Android 5" (éléments interactifs ≥ 44 px).

#### FR-20 : Comparaison mois/mois
Le système affiche, pour chaque Poste de dépense du mois courant, la variation en montant et en pourcentage par rapport au même Poste du mois précédent.

**Conséquences testables :**
- La variation est affichée avec un indicateur visuel directionnel (flèche ou couleur).
- Si le mois précédent n'a aucune Transaction pour un Poste, la variation affiche « — ».

#### FR-21 : Sélection de Période
L'utilisateur peut choisir d'analyser ses données par mois calendaire (navigation précédent/suivant) ou par Période custom (date de début + date de fin).

**Conséquences testables :**
- En mode mois calendaire, la navigation entre mois met à jour tous les indicateurs.
- En mode custom, une date de fin antérieure à la date de début est bloquée à la saisie.
- Le changement de Période met à jour FR-18, FR-19 et FR-20 immédiatement.

---

### 4.6 Stockage local sur l'appareil

**Description :** Toutes les données (Transactions, Catégories, session) sont stockées dans une base de données SQLite embarquée via Flutter (ex. `sqflite`). Aucune synchronisation backend. Ce choix garantit la persistance des données entre les sessions et les redémarrages de l'app, sans dépendance réseau ni coûts d'infrastructure pour le MVP. Le risque principal est la perte de données en cas de désinstallation de l'app ou de réinitialisation de l'appareil. [NOTE FOR PM : Un export JSON téléchargeable ou un backup iCloud/Google Drive est à envisager en V2 — ou dès le MVP si ce risque est signalé comme bloquant par les 20 beta.]

**Exigences fonctionnelles :**

#### FR-22 : Persistance locale des données
Toutes les Transactions, Catégories et préférences utilisateur sont lues et écrites dans la base de données locale de l'appareil, sans appel réseau (hors OCR et OTP).

**Conséquences testables :**
- Les données sont intactes après fermeture de l'app, redémarrage de l'appareil, et mise à jour de l'app.
- Le volume estimé d'un utilisateur moyen (≈ 100 Transactions/mois × 8 mois = 800 entrées) est négligeable pour une base SQLite embarquée.
- La saisie manuelle (FR-5, FR-6) fonctionne entièrement hors connexion réseau.

#### FR-23 : Avertissement de risque de perte de données
[ASSUMPTION : A-4] Lors de la première connexion réussie, l'app affiche un message informant l'utilisateur que ses données sont stockées sur l'appareil et que désinstaller l'app ou réinitialiser l'appareil les supprimera définitivement.

**Conséquences testables :**
- Le message est affiché une seule fois (flag persisté en base locale).
- L'utilisateur peut fermer le message et continuer sans action requise.

---

### 4.7 Navigation et écran d'accueil

**Description :** Surface d'entrée principale après authentification. Donne accès en un tap aux trois actions de saisie (scan, dépense, revenu) et à la navigation vers le Tableau de bord et l'historique des Transactions. Réalise l'état d'entrée de UJ-1, UJ-2, UJ-3.

**Exigences fonctionnelles :**

#### FR-24 : Accès unifié aux fonctionnalités depuis l'écran d'accueil
L'utilisateur peut accéder en un tap depuis l'écran d'accueil à : Scan de Reçu (FR-9), Saisie de Dépense (FR-5), Saisie de Revenu (FR-6), Tableau de bord (FR-17 à FR-21), et historique des Transactions.

**Conséquences testables :**
- L'écran d'accueil est le premier écran affiché après connexion réussie (FR-2).
- Toutes les fonctionnalités principales sont accessibles en ≤ 2 taps depuis l'écran d'accueil.
- Le Solde courant est visible sur l'écran d'accueil sans navigation supplémentaire.

---

## 5. NFRs transversaux

- **Performance — scan bout en bout :** Du déclenchement caméra à la validation globale du Reçu en ≤ 30 secondes pour un Reçu standard (10–20 Lignes, 4G normale). L'appel Mindee seul doit se compléter en ≤ 10 secondes ; au-delà, un timeout affiche une option de saisie manuelle.
- **Performance — navigation :** Les transitions entre écrans et les recalculs de Solde doivent être perçus comme instantanés (< 100 ms sur le thread principal).
- **Accessibilité :** Taille minimale des éléments interactifs : 44 × 44 px. Contraste texte ≥ 4.5:1.
- **Framework et distribution :** Flutter. iOS 15+ (App Store) et Android 9+ (Google Play Store).
- **Internationalisation :** Interface en français. Devise Beta V1 : XOF avec séparateur de milliers. XAF (V2) — la Devise doit être configurable dans l'architecture dès le V1. Dates au format JJ/MM/AAAA.
- **Résilience réseau :** La saisie manuelle (FR-5, FR-6) fonctionne entièrement hors connexion. Le scan (FR-9 à FR-12) et l'OTP (FR-1, FR-2) requièrent une connexion ; un message clair l'indique si le réseau est absent.

---

## 6. Contraintes et confidentialité

- **Données financières en base locale :** Les données sont stockées dans la sandbox de l'app sur l'appareil, inaccessibles aux autres apps (garantie OS). Un chiffrement de la base (SQLCipher ou équivalent) est à envisager en V2 pour les appareils rootés/jailbreakés.
- **Photo de Reçu via OCR cloud :** La photo transite par l'API tierce (Google Vision ou Mindee). Vérifier la politique de rétention d'images du fournisseur retenu avant le lancement beta. La photo ne doit pas être conservée au-delà du traitement.
- **Données collectées :** Numéro de téléphone uniquement. Aucun nom réel, adresse ou email n'est collecté.

---

## 7. Non-objectifs

- Intégration avec des APIs bancaires ou Mobile Money (Wave, Orange Money, MTN MoMo).
- Synchronisation des données entre plusieurs appareils d'un même utilisateur.
- OCR sur reçus manuscrits ou tickets de marchés informels.
- Budgets prévisionnels ou alertes de dépassement de plafond.
- Partage de compte ou collaboration multi-utilisateurs.
- Monétisation (publicité, abonnement, freemium).
- Export de données (CSV, PDF).
- Notifications push.
- Mode hors-ligne complet (la saisie manuelle est disponible hors connexion ; le scan requiert le réseau).

---

## 8. Périmètre MVP

### 8.1 Dans le périmètre

- Authentification par numéro de téléphone + OTP SMS via Africa's Talking.
- Saisie manuelle de Dépenses et Revenus, avec modification et suppression (FR-5 à FR-8).
- Scan de Reçu : OCR cloud + catégorisation IA + validation et correction Ligne par Ligne (FR-9 à FR-12).
- Gestion de Catégories prédéfinies et personnalisées (FR-13 à FR-16).
- Tableau de bord : Solde, Postes par Catégorie, graphique d'évolution, comparaison mois/mois, sélection de Période (FR-17 à FR-21).
- Stockage local persistant sur l'appareil (base de données embarquée) avec avertissement de risque de perte (FR-22, FR-23).
- Application mobile native cross-platform, iOS et Android.

### 8.2 Hors périmètre MVP

| Fonctionnalité | Raison du report |
|---|---|
| Mobile Money (Wave, Orange Money, MTN MoMo) | Partenariats commerciaux requis pays par pays (3–12 mois) |
| Authentification email | Usage marginal sur le marché cible |
| OCR reçus manuscrits / informels | OCR cloud non adapté au texte manuscrit |
| Mode hors-ligne complet | Utilisateurs 4G urbains ; la saisie manuelle couvre le cas hors connexion |
| Synchronisation cloud des données | Hors budget MVP ; les données restent sur l'appareil |
| Export CSV / PDF | [NOTE FOR PM : Fonctionnalité à fort potentiel d'adoption — à prioriser en V2 si signalée par les beta] |
| Budgets & alertes | V2 |
| Apprentissage IA des corrections de Catégorie | Requiert un dataset suffisant — V2 |
| Monétisation | Phase d'évaluation gratuite ; revenu en V2 |

---

## 9. Métriques de succès

**Primaires**
- **SM-1 : Rétention mensuelle** — Pourcentage d'utilisateurs qui reviennent le mois suivant. Cible : ≥ 90 % sur les 8 mois de beta. Valide FR-5, FR-6, FR-9.
- **SM-2 : Adoption du scan** — Pourcentage de Transactions enregistrées via le scan vs. saisie manuelle. Cible : > 50 % (valide que le flux principal est adopté, pas seulement toléré). Valide FR-9 à FR-12. *Note : cible conditionnelle à la précision OCR Mindee sur les reçus locaux — si SM-4 révèle un taux de correction > 40 %, revoir la cible.*
- **SM-3 : Fréquence d'usage** — Nombre médian de Transactions enregistrées par semaine par utilisateur actif. Cible : ≥ 3. Valide FR-5, FR-6, FR-9.

**Secondaires**
- **SM-4 : Taux de correction OCR** — Pourcentage de Lignes dont la Catégorie suggérée est corrigée par l'utilisateur. Indicateur de qualité de la catégorisation IA. Pas de cible fixe pour le MVP ; surveiller la tendance. Valide FR-10, FR-11.
- **SM-5 : Taux d'abandon du scan** — Pourcentage de sessions scan abandonnées avant validation globale. Cible : < 20 %. Valide FR-10, FR-11.

**Contre-métriques (ne pas optimiser)**
- **SM-C1 : Volume de Transactions par session** — Ne pas optimiser pour le volume brut. L'objectif est l'usage régulier et fidèle, pas la quantité de saisies. Contrebalance SM-3.

---

## 10. Questions ouvertes

1. **Modèle de catégorisation IA :** Règles de correspondance libellé → Catégorie (dictionnaire de mots-clés), modèle léger embarqué, ou appel LLM ? Impacte la latence, le coût par scan et la qualité des suggestions. À trancher avant l'implémentation de FR-10.
2. **Récupération des données :** Si un utilisateur perd ou réinitialise son appareil, ses données sont perdues sans recours. Un export JSON ou un backup iCloud/Google Drive est-il dans le budget de complexité du MVP, ou reporté en V2 ?
3. **Ordre des Catégories dans le sélecteur :** Prédéfinies d'abord puis personnalisées, ou tri alphabétique global ? À trancher en phase UX.
4. **⚠ Politique de rétention des photos OCR — BLOQUANT BETA :** Mindee conserve-t-il les images de reçus après traitement, et pendant combien de temps ? Les données financières des utilisateurs sont sensibles. Cette politique doit être vérifiée et documentée avant le lancement beta. Si les images sont conservées, activer l'option "no data retention" de Mindee ou obtenir un engagement contractuel de suppression.

*Questions résolues :* Provider OCR → Mindee (Google Vision en bascule si précision insuffisante) ; Framework → Flutter ; Devise Beta V1 → XOF, XAF prévu en V2.

---

## 11. Index des hypothèses

- **A-1** (§4.1 FR-4) — Les données de Transactions sont conservées dans la base SQLite locale après déconnexion ; seul le token de session est effacé.
- **A-2** (§4.3 FR-10) — La catégorisation IA repose sur un modèle de correspondance règles/mots-clés, sans entraînement en ligne sur les données de l'utilisateur.
- **A-3** (§4.3 FR-12) — Les Transactions issues d'un même Reçu sont regroupées visuellement dans l'historique.
- **A-4** (§4.6 FR-23) — Un message d'avertissement sur le risque de perte de données est affiché à la première connexion réussie.
