# Runbook rollback — iOS (App Store)

**Runbook ID** : `RBK-203`  
**Plateforme** : iOS  
**Statut** : `draft` (R3)  
**Références** : `docs/operations/rollback/rollback_strategy.md`, `docs/rules_nasa.md` §20.1, §27.

---

## 1) Contraintes (réalité App Store)

- Le “rollback” strict (revenir à un binaire précédent pour tous) est **limité**.
- Le levier principal est :
  - **stopper** une release/phased rollout si possible,
  - **hotfix** rapide (N+1),
  - gestion de disponibilité des versions (selon la politique App Store).

---

## 2) Prérequis

- Accès App Store Connect.
- Identifier la version N en incident et la version stable précédente (N-1) au niveau métadonnées.
- Monitoring : Sentry (si activé) + logs corrélables.

---

## 3) Procédure opératoire (approche réaliste)

1. Suspendre le phased rollout (si activé) ou stopper la publication en cours.
2. Décider rollback vs hotfix :
   - si rollback store non possible : préparer hotfix N+1 immédiatement.
3. Publier hotfix, surveiller crash rate et flux critiques.

---

## 4) Validation post-action (minimum)

- Crash rate en baisse (Sentry)
- Startup/auth/playback OK sur appareil de test

---

## 5) Preuve / rehearsal

Si build iOS n’est pas exécutable sur l’hôte (Windows), la preuve de rehearsal peut dépendre d’un runner macOS (CI) : documenter la dépendance et archiver le log dès qu’exécutable.

