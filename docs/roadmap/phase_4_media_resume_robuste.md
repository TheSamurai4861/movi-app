# Roadmap — Reprise média “robuste à fond” (L1/L2) vs `docs/rules_nasa.md`

**Document** : `RDMP-PH4-MEDIA-RESUME-001`  
**Date** : `2026-04-02`  
**Statut** : `draft`  
**Référentiel** : `docs/rules_nasa.md` (§6, §8, §11, §14, §15, §21, §25, §27)  

---

## Objectif

Rendre la **reprise d’un média en lecture** (movie + épisode) **déterministe, observable, résiliente** et sûre en conditions dégradées :

- **reprise correcte** (position normalisée, bornée, appliquée une seule fois),
- **pas de boucle** (seek/persist/reopen),
- **offline / latence / timeouts** gérés explicitement,
- **aucune fuite** de secrets/PII dans logs/telemetry,
- **preuves reproductibles** (tests + artefacts) avant merge.

---

## Périmètre (chaîne de reprise)

### Zone fonctionnelle cible

- Détermination de la position de reprise (ex: `resolve_*_playback_selection`).
- Construction de la source player avec `resumePosition` (ex: `VideoSource`).
- Application du seek (ex: `video_player_page.dart`).
- Persistance du progrès (timer + pause + fin).
- Synchronisation éventuelle local/cloud (hybride) si présente.

### Points d’appui identifiés (références code)

- Application du seek “une fois quand la durée est disponible” : `lib/src/features/player/presentation/pages/video_player_page.dart` (logique `_resumePositionApplied`, `seekTo`).
- Chargement historique + `resumePosition` pour séries : `lib/src/features/tv/presentation/pages/tv_detail_page.dart` (récupère `historyEntry?.lastPosition`).
- Éligibilité reprise pour film : `lib/src/features/movie/domain/usecases/resolve_movie_playback_selection.dart` (normalisation via `normalizeResumePosition`).
- Player media_kit (data) : `lib/src/features/player/data/repositories/media_kit_video_player_repository.dart`.

---

## Classification (à tracer dans le lot)

- **Classe** : L2 par défaut (parcours critique UX), **L1** dès que la reprise touche :
  - intégrité d’état (boucles, corruption d’historique, “continue watching” incohérent),
  - stabilité runtime (crash/hang/stack overflow, timeouts non bornés),
  - collecte/logging pouvant exposer PII.
- **Criticité de changement** : C2 (régression majeure possible) ; C1 si modification “core” ou si le flux devient bloquant au démarrage.

---

## Invariants (à rendre testables)

### INV-MR-001 — Seek borné et idempotent

- La position appliquée est **clampée** : \(0 \le position \le duration - margin\).
- Le seek de reprise est **appliqué au plus une fois** par session de lecture.

### INV-MR-002 — Reprise déterministe

- À inputs identiques (même historique + même durée), la décision de reprise est identique.
- Pas de dépendance implicite à l’ordre des streams/frames.

### INV-MR-003 — Fail-safe / mode dégradé

- Si l’historique est indisponible/timeout/offline → lecture démarre **sans reprise** (position 0) + événement observable.
- Si la durée est instable/inconnue → reprise **différée** ou **abandonnée** de manière explicite (pas de boucle).

### INV-MR-004 — Persistance robuste

- La persistance n’écrit jamais une position négative, NaN, ou > durée.
- Les écritures sont **bornées** (périodicité, backpressure) ; pas de spam.

### INV-MR-005 — Observabilité sans fuite

- Les événements de reprise/persistance sont corrélables (opId) et **n’incluent** ni URL brute, ni token, ni email, ni identifiants sensibles.

---

## Observabilité minimale (NASA §14)

Schéma recommandé (texte structuré ou map sérialisée) :

- `feature=media_resume action=resume_decide result=skip|apply reasonCode=... opId=...`
- `feature=media_resume action=resume_apply result=success|failure reasonCode=...`
- `feature=media_resume action=progress_persist result=success|failure reasonCode=...`

**Reason codes stables** (exemples à figer) :

- `no_history`, `history_timeout`, `history_offline`, `duration_unknown`, `position_out_of_range`, `seek_failed`, `persist_failed`.

---

## Jalons (milestones) — livrables + gates

### Jalon MR-M1 — Contrats “resume” + normalisation unifiée (domain)

**Objectif** : sortir la logique “décider/normaliser la reprise” de l’UI, avec règles **déterministes**, reason codes **stables** et tests couvrant les cas limites (NASA §11/§15).

- **Classification**
  - **Classe** : `L2` (parcours critique UX) — à reclasser `L1` si le changement peut induire boucle/hang/corruption d’historique ou fuite de données (NASA §3/§21).
  - **Criticité** : `C2` par défaut ; `C1` si modification transversale “core” ou si la reprise devient bloquante (NASA §3/§27).

- **Livrables**
  - Une fonction/VO de normalisation unifiée (movie + tv) avec règles **opposables** :
    - clamp position \([0 ; duration - margin]\),
    - “near end” => `skip`,
    - `duration == null|0` => `skip` (reason code `duration_unknown`).
  - Un modèle de décision explicite `ResumeDecision` :
    - `apply(targetMs)` ou `skip`,
    - `reasonCode` **stable** (liste figée au niveau du module).

- **Preuves**
  - Tests unitaires **déterministes** couvrant au minimum :
    - `null`, `0`, négatif, `> durée`, durée inconnue, “near end” (marge),
    - idempotence (mêmes inputs → même `ResumeDecision`),
    - non-régression : bug reproduit → test ajouté (NASA §15.1).
  - Commande de référence : `flutter test test/**/resume*_test.dart` (ou équivalent) + sortie archivable si campagne de preuve (NASA §25).

- **STOP**
  - Si l’idempotence (INV-MR-001) ou le déterminisme (INV-MR-002) ne sont pas démontrables par tests.
  - Si la liste des reason codes n’est pas stable (diagnostic “flottant” en prod).
  - Si un chemin dégradé (duration inconnue / historique indisponible) n’a pas de comportement explicite + test (NASA §11).

### Jalon MR-M2 — Orchestrateur “reprise” côté player (application)

**Objectif** : centraliser l’application du seek et la protection contre boucles/races.

- **Livrables**
  - Un orchestrateur/contrôleur de reprise (ex: `ResumeOrchestrator`) qui :
    - attend les préconditions (durée stable, source chargée),
    - applique `seekTo(target)` **une fois**,
    - émet événements observables.
  - Timeouts explicites sur opérations asynchrones critiques (borne anti-hang).
- **Preuves**
  - Tests composant (widget/logic) simulant streams : durée arrive tard, durée change, position stream spam.
- **STOP**
  - Toute boucle “durée→seek→durée→seek” observée.

### Jalon MR-M3 — Persistance progrès robuste + backpressure (data)

**Objectif** : rendre l’écriture d’historique robuste (offline, latence, collisions).

- **Livrables**
  - API de persistance idempotente (upsert) avec validation/clamp côté write-path.
  - Politique de fréquence d’écriture (timer) + flush sur pause/exit.
  - Gestion des erreurs : retry contrôlé ou best-effort explicitement choisi.
- **Preuves**
  - Tests d’intégration (repo local) : writes bornées, valeurs invalides rejetées, “pause” flush.
  - Preuve “no secrets/PII” sur logs persist (scan patterns).

### Jalon MR-M4 — Robustesse interruptions runtime (platform)

**Objectif** : reprendre correctement après interruptions : background/foreground, kill, changement route, PiP.

- **Livrables**
  - Scénarios intégration : 
    - pause→reopen,
    - navigation rapide (dispose/recreate),
    - reprise après cold start (history exists).
  - Observabilité : événements “resume_apply” visibles.
- **Preuves**
  - Tests d’intégration Flutter (au minimum) + script de reproduction manuel versionné (si E2E non dispo).

### Jalon MR-M5 — Gates “mission-grade” (preuve + docs)

**Objectif** : consolider preuves et gouvernance pour merge/release.

- **Livrables**
  - Mise à jour `docs/quality/validation_evidence_index.md` : entrées preuves MR (tests, logs, commandes).
  - Entrée `docs/traceability/change_logbook.md` : lot + risques + rollback.
  - (Option) ADR si refonte des frontières (extraction orchestrator, ports).
- **Preuves**
  - `flutter test` vert, `flutter analyze` vert.
  - Artefacts de logs/tests datés si campagne “preuve” est exigée.

---

## Risques (NASA §8) et mitigations

- **Risque** : boucle seek/persist → CPU/jank, corruption d’historique.  
  - **Mitigation** : idempotence (flag/état), clamp, timeouts, tests de course.
- **Risque** : reprise au mauvais endroit (durée instable, offset audio/sub).  
  - **Mitigation** : attendre durée stable, marge fin, revalidation.
- **Risque** : spam d’écritures DB/cloud.  
  - **Mitigation** : backpressure (timer), coalescing, best-effort contrôlé.
- **Risque** : fuite d’infos (URL, headers, userId, email).  
  - **Mitigation** : redaction systématique + tests “no leak”.

---

## Rollback / containment (NASA §20/§25)

- Changements par jalons (PRs petites).  
- Feature flag possible : désactiver la reprise (fallback “start at 0”) si anomalie C1/C2.
- Rollback technique : revert des modules “resume orchestrator” + conservation persistance existante.

---

## Critères d’acceptation (Gate §27)

- **Determinisme** : MR-M1 tests verts, décisions stables.
- **Robustesse** : offline/timeout → lecture sans reprise (fail-safe) + événements.
- **Absence de boucle** : prouvée par tests et instrumentation.
- **Observabilité** : événements corrélables (opId) + reason codes stables.
- **Sécurité** : aucune fuite secrets/PII dans logs/tests.
- **Qualité** : `flutter test` vert ; `flutter analyze` vert.

