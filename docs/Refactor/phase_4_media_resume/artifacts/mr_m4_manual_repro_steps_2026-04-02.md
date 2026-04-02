# MR-M4 — Script de reproduction manuel (reprise média)

**But** : démontrer la robustesse de reprise après interruptions (MR‑M4) quand E2E n’est pas disponible.

**Référentiel** : `docs/rules_nasa.md` §11/§14/§21/§25/§27  
**Date** : `2026-04-02`  

---

## Pré-requis

- Build debug (ou profile) sur un device Android.
- Un contenu avec historique existant :
  - regarder ~5–10 minutes,
  - laisser la persistance s’écrire (timer ou pause),
  - vérifier que `duration` est connue et persistée (sinon MR‑M1 peut skipper la reprise côté selection).

## Observabilité attendue

Dans les logs diagnostics, on doit voir des événements `player_resume_apply` avec :

- `result=applied` **ou** un skip explicite (`skip_no_resume`, `skip_timeout`, etc.)
- pas de secrets/PII (pas d’email, pas de token, pas d’URL brute sensible).

---

## Scénario 1 — pause → reopen (reprise après interruption légère)

1. Démarrer la lecture.
2. Attendre quelques secondes.
3. Mettre en pause (contrôle player).
4. Quitter la page player (back).
5. Relancer le même média depuis l’écran détail / continue watching.

**Attendu** :
- La lecture reprend proche de la dernière position persistée.
- Un seul `player_resume_apply result=applied` par session de lecture.

---

## Scénario 2 — navigation rapide (dispose/recreate)

1. Démarrer la lecture.
2. Quitter immédiatement (back) avant stabilisation totale (durée/streams).
3. Relancer immédiatement le même média.

**Attendu** :
- Pas de hang.
- Si la durée n’est pas “ready”, l’orchestrateur attend puis applique, ou finit en `skip_timeout` (comportement explicite).

---

## Scénario 3 — cold start (kill app) avec historique existant

1. Démarrer la lecture, progresser (>= quelques minutes), puis pause.
2. Forcer l’arrêt de l’app (swipe / “force stop”).
3. Relancer l’app.
4. Rejouer le même média.

**Attendu** :
- Reprise correcte via historique (si disponible).
- Logs : `player_resume_apply` visible.

---

## Critères STOP (si observé)

- Boucle `duration→seek→duration→seek` ou multiples `applied` sur une seule session.
- Crash / stack overflow / freeze.
- Fuite d’information (email/token/PII) dans logs.

