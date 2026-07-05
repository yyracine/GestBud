---
title: "Product Brief : GestBud"
status: final
created: 2026-06-30
updated: 2026-06-30
---

# Product Brief : GestBud

## Résumé exécutif

GestBud est une application web progressive (PWA) de gestion financière personnelle conçue pour les actifs urbains francophones d'Afrique subsaharienne. Elle permet à un utilisateur d'enregistrer chaque dépense et chaque entrée d'argent, de les ventiler par catégorie, et de visualiser en temps réel son solde et ses postes de dépense mensuels.

Là où les applications occidentales s'appuient sur des APIs bancaires inexistantes dans ce marché, GestBud fait du ticket de caisse son point d'entrée principal : l'OCR lit chaque article, l'IA propose une catégorisation, l'utilisateur valide. Ce flux — scan, suggestion, validation — remplace le cahier papier que beaucoup utilisent aujourd'hui, avec la puissance du calcul automatique et de la visualisation par catégorie.

Le MVP est un projet personnel en phase d'évaluation beta, ciblant 20 utilisateurs sur 8 mois.

---

## Le problème

En fin de mois, l'employé ou le cadre responsable d'une famille ne sait pas précisément où est passé son argent. Il connaît son solde bancaire — pas ses postes de dépense réels.

Le problème est aggravé par la nature des achats : un ticket de supermarché de 25 000 FCFA mélange alimentation, produits ménagers et hygiène. Ce montant global ne dit rien sur la répartition. Sans décomposition, impossible de réguler, d'identifier où économiser, ou de planifier le mois suivant.

La solution actuelle est un cahier. Il fonctionne pour noter des totaux, mais il ne calcule pas, ne catégorise pas, et ne décompose pas un achat mixte.

---

## Pour qui

**Persona primaire : l'employé ou cadre urbain, responsable d'une famille**

- Localisé dans une grande ville francophone (Dakar, Abidjan, Douala)
- Revenu mensuel fixe, gestionnaire des dépenses du foyer
- Tient déjà un cahier de comptes — la motivation existe, l'outil est limité
- Fait les courses en grande surface (reçus imprimés, OCR applicable)
- Connecté en 4G, Android

**Profils secondaires (non prioritaires pour le MVP)** : étudiants, commerçants.

---

## La solution

GestBud propose trois modes de saisie complémentaires :

1. **Scan de reçu (flux principal)** — L'utilisateur photographie son ticket. L'OCR cloud extrait chaque article. L'IA propose une catégorie pour chaque ligne. L'utilisateur valide ou corrige article par article. Le résultat est imputé aux bons postes de dépense.

2. **Saisie manuelle** — Pour les achats sans reçu (transport, marché, transferts), l'utilisateur saisit le montant, la catégorie et la date directement.

3. **Enregistrement d'une entrée** — Salaire, virement, ou revenu ponctuel : même logique que la dépense, avec mise à jour immédiate du solde.

En fin de mois, l'utilisateur accède à un tableau de bord : totaux par catégorie, évolution du solde, postes les plus lourds. Ces données lui donnent les moyens de réguler, d'économiser et de planifier.

---

## Ce qui différencie GestBud

**Construit pour ce marché, pas adapté.** Les apps de budget existantes (Bankin, Linxo, Mint) sont conçues autour de la synchronisation bancaire. En Afrique francophone, ces APIs n'existent pas — ces apps sont inutilisables ou incomplètes. GestBud part du ticket papier et du cash, qui sont les réalités locales.

**OCR article par article, pas seulement le total.** La majorité des apps qui proposent un scan de reçu ne lisent que le montant global. GestBud lit chaque ligne et la catégorise individuellement — c'est la seule façon de ventiler un achat mixte sans ressaisie manuelle.

**Friction minimale au moment de l'achat.** Le flux de scan est conçu pour être utilisé sur place, ticket en main : moins de 30 secondes du scan à la validation.

---

## Critères de succès

| Signal | Cible MVP |
|---|---|
| Utilisateurs beta actifs | 20 |
| Durée de la phase d'évaluation | 8 mois |
| Fréquence d'usage attendue | À chaque achat |
| Rétention mensuelle | L'utilisateur revient le mois suivant |

Le MVP est réussi si 20 utilisateurs utilisent GestBud à chaque achat pendant 8 mois consécutifs.

---

## Périmètre

### Dans le MVP

| Fonctionnalité | Détail |
|---|---|
| Authentification | Numéro de téléphone + OTP SMS (Africa's Talking) |
| Saisie de dépenses et revenus | Manuelle, avec catégories et date |
| Scan de reçu | OCR cloud (Google Vision ou Mindee) + catégorisation IA + validation ligne par ligne |
| Calcul mensuel | Totaux automatiques par catégorie |
| Visualisation | Solde et postes de dépense |
| Plateforme | PWA mobile-first, optimisée Android |

### Hors périmètre MVP

| Fonctionnalité | Raison du report |
|---|---|
| Intégration Mobile Money (Wave, Orange Money, MTN MoMo) | Requiert des partenariats commerciaux pays par pays (3–12 mois) |
| Authentification par email | Usage marginal sur le marché cible |
| Application native iOS | Android couvre +85% du marché ; PWA suffit |
| OCR reçus manuscrits / informels | OCR cloud ne fonctionne pas sur texte manuscrit |
| Monétisation | Phase d'évaluation gratuite — revenu en V2 |
| Mode hors-ligne complet | Utilisateurs urbains 4G ; hors scope pour l'instant |

---

## Hypothèses et risques

| Hypothèse | Risque si faux |
|---|---|
| Les reçus des grandes surfaces (Auchan, Carrefour) sont lisibles par OCR cloud | Précision insuffisante → abandon du scan, retour à la saisie manuelle |
| 4G fiable pour les utilisateurs urbains ciblés | Latence au scan → friction sur le flux principal |
| 20 utilisateurs beta accessibles dans l'entourage | Pas de données pour valider l'usage à 8 mois |
| L'habitude du cahier se transfère naturellement sur l'app | Résistance au changement sous-estimée |
