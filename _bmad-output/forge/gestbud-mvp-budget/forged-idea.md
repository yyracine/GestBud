# GestBud — Idée forgée

## Ce qui a survécu

**Différenciateur central**
Première app de finance personnelle construite pour l'économie urbaine francophone africaine. Pas de dépendance aux APIs bancaires (inexistantes sur ce marché) — l'OCR de reçus physiques est le mode de saisie primaire, pas un bonus.

**Périmètre MVP verrouillé**
- Auth : numéro de téléphone + OTP SMS (Africa's Talking)
- Saisie manuelle dépenses / revenus avec catégories
- Calcul automatique des totaux mensuels + visualisation du solde
- OCR cloud (Google Vision ou Mindee) pour reçus imprimés de commerces formels
- Plateforme : PWA mobile-first (Android, pas de store nécessaire)
- Monétisation : gratuit — objectif = prouver l'usage

**Marché cible**
Urbain francophone (Dakar, Abidjan, Douala), 4G fiable, Android dominant.

---

## Ce qui a été tué et pourquoi

| Décision | Raison |
|---|---|
| Mobile Money en V1 | Nécessite partenariats commerciaux pays par pays (3–12 mois). Repoussé en V2 dès traction prouvée. |
| OCR on-device | Précision insuffisante. Cloud validé par hypothèse 4G urbain. |
| Email comme auth | Usage marginal sur le marché cible. Le numéro de téléphone est l'identité numérique primaire. |
| iOS en priorité | Android représente +85% du marché. PWA couvre les deux sans effort supplémentaire. |
| Monétisation au MVP | Contradiction avec l'objectif de prouver l'usage. Revenu = V2. |
| OCR reçus informels / manuscrits | OCR cloud ne fonctionne pas sur texte manuscrit. Cas d'usage hors périmètre MVP. |

---

## V2 (après traction)
Mobile Money (Wave, Orange Money, MTN MoMo) + freemium payant via Mobile Money.

---

*Peut alimenter `bmad-prd` ou `bmad-product-brief` directement.*
