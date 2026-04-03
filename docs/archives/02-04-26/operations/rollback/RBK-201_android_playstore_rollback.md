# Runbook rollback — Android (Google Play Console)

**Runbook ID** : `RBK-201`  
**Plateforme** : Android  
**Canal** : Google Play  
**Statut** : `draft` (R3)  
**Références** : `docs/operations/rollback/rollback_strategy.md`, `android/PLAY_CONSOLE_CHECKLIST.md`, `docs/rules_nasa.md` §20.1, §27.

---

## 1) Contraintes (réalité Play)

- `versionCode` doit rester **monotone** : on ne “redéploie” pas strictement un binaire plus ancien avec un `versionCode` inférieur.
- Le “rollback” Play est généralement un **revert de track / arrêt du rollout** + retour à une version précédente encore disponible, ou un **hotfix** rapide.
- Propagation progressive : délai avant que tous les utilisateurs aient la version cible.

---

## 2) Prérequis

- Accès Play Console (rôle release manager).
- Identifier la version N (en incident) et la version stable précédente (N-1) :
  - `versionName`/`versionCode`,
  - `SENTRY_RELEASE` si activé.
- Monitoring : Sentry + logs corrélables (R2).

---

## 3) Procédure opératoire (rollback “store”)

> Les intitulés exacts d’UI Play Console peuvent varier ; le but est d’avoir une checklist opérationnelle reproductible.

1. **Stopper l’escalade**
   - Suspendre ou réduire le staged rollout de la release N (si en cours).
2. **Choisir la stratégie**
   - **Revert** : sélectionner une version précédente stable sur le track (si disponible) ;
   - sinon : **hotfix** (N+1) en urgence.
3. **Déployer**
   - Publier la version cible sur le track approprié.
4. **Valider**
   - Vérifier la disponibilité en interne (test install),
   - vérifier crash rate (Sentry),
   - vérifier flux critiques (startup/auth/playback).

---

## 4) Validation post-rollback (minimum)

- Startup OK
- Login OK (si applicable)
- Playback OK
- Crash rate en baisse (Sentry)

---

## 5) Risques / pièges

- Cache client / propagation : le rollback peut être partiel pendant un temps.
- Si l’incident est lié à des données/migrations : rollback binaire peut ne pas suffire (prévoir mitigation).

