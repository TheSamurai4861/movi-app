# ADR-PH4-001 — Orchestrateurs de reprise média (MR-M1..MR-M4)

**Date** : `2026-04-02`  
**Statut** : `accepté`  
**Référentiel** : `docs/rules_nasa.md` (§5, §11, §14, §15, §21, §25, §27)  

---

## Contexte

La reprise de lecture implique plusieurs responsabilités :

- décision “reprendre ou non” à partir de l’historique (position/durée),
- application du seek dans le player quand la durée devient exploitable,
- persistance robuste de la progression (écriture bornée, valeurs valides),
- comportement explicite en cas d’interruptions et conditions dégradées.

Historiquement, une partie de cette logique vivait dans l’UI (`VideoPlayerPage`) et variait selon movie/TV.

---

## Décision

1. **Extraire la logique métier de reprise** en services purs et déterministes :
   - `decideResume(...)` (MR‑M1) avec `ResumeDecision` + `ResumeReasonCode` stables.
2. **Isoler l’orchestration seek** dans un orchestrateur dédié (MR‑M2) :
   - `PlayerResumeOrchestrator` applique `seekTo` au plus une fois,
   - attente bornée (`maxWait`) pour éviter hang,
   - télémétrie via callback (sans secrets/PII).
3. **Sanitizer write-path** pour la persistance (MR‑M3) :
   - `sanitizePlaybackProgress(position,duration)` clamp/drop invalid,
   - appliqué dans les repositories de persistance (local/hybride).
4. **Preuves MR‑M4** :
   - tests “interruption” au minimum (dispose/recreate + timeout),
   - script manuel versionné si E2E indisponible.

---

## Conséquences

- **+ Déterminisme** : décisions uniformisées movie/TV.
- **+ Anti-boucle** : seek appliqué une fois, comportement explicite en cas de durée instable.
- **+ Robustesse données** : write-path protège contre positions incohérentes.
- **+ Observabilité** : événements `player_resume_apply` et reason codes exploitables.
- **± Code ajouté** : nouveaux services/tests à maintenir (accepté vs gain de preuve).

---

## Preuves / validation

- `flutter test` vert ; `flutter analyze` vert.
- Index preuves : `docs/quality/validation_evidence_index.md` (`PH4-EVD-009..012`).

