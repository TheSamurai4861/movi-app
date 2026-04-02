# Roadmap — Phase 4 : Refondation du noyau critique (L1)

## Références et conformité
- **Plan source** : `movi_nasa_refactor_plan_v3.md` — §14 “Phase 4 — Refondation du noyau critique” (lignes 504–547).
- **Règles applicables** : `docs/rules_nasa.md` (architecture §5, risques §8/§9, erreurs/résilience §11, observabilité §14, tests §15, revue §16, preuves §25, quality gates §27).
- **Préconditions issues Phase 3** : invariants + traçabilité + vérification (ex. `docs/traceability/invariant_matrix.md`, `docs/traceability/requirements_traceability.md`, `docs/traceability/verification_matrix.md`).
- **Gate pré-Phase 4** : `docs/traceability/pre_phase4_gate_checklist.md`.
- **Traçabilité changement** : `docs/traceability/change_logbook.md` (un lot = une entrée traçable).
- **Index des preuves** : `docs/quality/validation_evidence_index.md` (référencer ADR, rapports CI, preuves de tests, deltas d’architecture).

## Objectif (Phase 4)
Stabiliser les domaines **L1** avant tout refactor large de surface, en rendant explicites :
- les **contrats** du noyau critique,
- les **effets de bord** et leurs **adapters**,
- les **transitions d’état** critiques,
- les **modes dégradés** sûrs,
- les **tests de non-régression** (nominal + dégradé),
- et une **réduction mesurable** des dépendances interdites.

## Ordre recommandé (lots L1)
1. `core/startup`
2. `core/auth`
3. `core/storage`
4. `core/network`
5. `core/parental`
6. `core/profile` (si impact sécurité ou données)

## Principes d’exécution (non négociables)
- **Contracts first** : stabiliser les interfaces/contrats avant de déplacer/implémenter.
- **Side effects encapsulated** : aucun effet de bord non identifié dans le domaine.
- **Transitions d’état explicites** : pas d’état implicite sur chemin critique.
- **Pas de mélange UI / logique métier / infrastructure** (aligné `docs/rules_nasa.md` §5).
- **Un lot par sous-domaine critique** : exécution séquentielle, rollback démontré à chaque lot.

## Quality gates (bloquants)
- **No evidence, no merge** : chaque lot produit au minimum 1 preuve indexée (tests + delta architecture + ADR si frontière).
- **Aucune régression L1** : si un invariant `C1/C2` du sous-domaine est en échec, le lot ne passe pas.
- **Réduction mesurable des dépendances interdites** : un rapport (ou delta) doit prouver l’amélioration.
- **Rollback démontrable** : procédure + capacité d’annulation (ou dérogation formelle `docs/rules_nasa.md` §26).

## Travaux obligatoires (à appliquer pour chaque lot)
1. **Extraire/clarifier les contrats du domaine** (ports, types, erreurs, invariants).
2. **Déplacer SDK/DB/HTTP** vers `data` / `infrastructure` (domain ne dépend pas des détails).
3. **Introduire use cases / orchestrators / policies** pour les flux critiques.
4. **Encapsuler la DI au niveau module** (composition root locale, pas de fuite vers UI).
5. **Remplacer les accès directs UI** aux implémentations concrètes (UI consomme des ports).
6. **Ajouter tests de non-régression avant découpage lourd** (nominal + dégradé).

## Livrables attendus (par lot)
- **ADR** de frontière critique (si création/changement d’un contrat public, d’un flux critique ou d’un pattern d’injection).
- **Ports/Adapters** introduits (contrats + implémentations isolées).
- **Lot de tests** correspondant (unit/widget/intégration/E2E selon criticité).
- **Rollback documenté** (procédure + limites + signaux de déclenchement).

## Roadmap (WBS) — jalons, critères d’acceptation et preuves

### Jalon M0 — Gate “pré-lot” (obligatoire avant chaque sous-domaine)
**But** : ne pas démarrer un lot L1 sans filet de sécurité (invariants/tests/rollback).

- **Travaux**
  - Exécuter la checklist `docs/traceability/pre_phase4_gate_checklist.md` pour le sous-domaine visé.
  - Identifier invariants `C1/C2` pertinents et confirmer qu’ils ont des vérifications (tests existants ou à ajouter avant refactor).
  - Définir les critères d’arrêt spécifiques au lot (voir section “Critères d’arrêt”).
- **Critères d’acceptation**
  - Les invariants critiques du sous-domaine sont listés + reliés à une vérification.
  - Le rollback “N-1” (ou mécanisme équivalent) est plausible et documenté.
- **Preuves à indexer**
  - Snapshot daté de la checklist + liens vers matrices invariants/vérification pertinentes.

### Jalon M1 — `core/startup` : orchestration de démarrage stabilisée
**But** : rendre le démarrage déterministe, observable et safe en dégradé.

- **Travaux**
  - Extraire un contrat de “startup orchestration” (états, transitions, erreurs, timeouts/annulation).
  - Encapsuler les effets de bord (IO, initialisation SDK, lecture storage, config runtime) derrière adapters.
  - Introduire use case/orchestrator de démarrage (sans dépendance UI).
  - Définir le mode dégradé “startup partiel” (état sûr + UX minimale) et le rendre observable.
- **Critères d’acceptation**
  - Les transitions d’état de démarrage sont explicites et testables.
  - Échecs critiques détectables (logs/events) sans exposition de données sensibles.
  - Aucun accès direct UI à une implémentation concrète critique.
- **Preuves à indexer**
  - Tests de non-régression “startup nominal + offline/timeout/storage indispo”.
  - Delta “violations architecture” montrant une réduction (au minimum sur imports/UI→infra).

### Jalon M2 — `core/auth` : session/auth sécurisées, erreurs maîtrisées
**But** : fiabiliser auth/session sans fuite d’implémentation et avec comportement fail-safe.

- **Travaux**
  - Stabiliser les ports : session store, token provider, auth client, policies (ex: refresh, logout).
  - Isoler SDK/HTTP/token storage (adapters) et formaliser les erreurs (catégorisées).
  - Définir explicitement les transitions : *unknown → authenticated/unauthenticated*, expirations, invalidations, logout.
  - Ajuster l’observabilité (événements, corrélation) sans secrets.
- **Critères d’acceptation**
  - Pas de token/secret dans logs (conforme `docs/rules_nasa.md` §12/§13).
  - Les chemins “session invalide / refresh échoue / offline” ont un état sûr documenté et testé.
  - Le domaine n’importe aucun client HTTP/SDK concret.
- **Preuves à indexer**
  - Tests (au moins intégration) couvrant nominal + dégradé (offline/timeout/session invalide).
  - ADR si un nouveau modèle d’erreur ou de session est introduit.

### Jalon M3 — `core/storage` : intégrité données locales, migrations et rollback
**But** : empêcher perte/corruption, rendre migrations sûres et réexécutables lorsque possible.

- **Travaux**
  - Définir les contrats : keyspaces, schémas, migrations, chiffrement/obfuscation si applicable.
  - Déplacer DB/FS/KV stores concrets en adapters ; domaine expose uniquement des ports.
  - Formaliser les erreurs storage (corruption, accès refusé, disque plein, version incompatible).
  - Définir une stratégie de migration et de rollback (incluant “lecture ancienne version” si nécessaire).
- **Critères d’acceptation**
  - Aucun flux critique ne “silence” une erreur storage.
  - La perte de données locales est détectable et traitée par état sûr (ou dérogation explicite).
  - Les migrations sont testées (au moins sur échantillon de données/fixtures).
- **Preuves à indexer**
  - Tests de migration + tests de corruption/échec (dégradé) + preuve CI.
  - Rollback documenté (procédure + limitations).

### Jalon M4 — `core/network` : résilience, timeouts, retry contrôlé, idempotence
**But** : rendre les appels réseau prévisibles, cancelables, et sûrs en dégradé.

- **Travaux**
  - Stabiliser les ports réseau (client, connectivité, policies retry/backoff/timeout).
  - Encapsuler HTTP/SDK concrets (adapters) ; domaine ne dépend d’aucun détail.
  - Formaliser la taxonomie d’erreurs (timeout/offline/5xx/4xx/parse) et les comportements attendus.
  - Définir l’observabilité minimale (taux d’échec, latences, causes).
- **Critères d’acceptation**
  - Timeouts et annulation gérés explicitement sur chemins critiques.
  - Retries contrôlés (pas de boucle cachée) ; idempotence définie si nécessaire.
  - UI ne dépend pas d’un client réseau concret.
- **Preuves à indexer**
  - Tests d’intégration simulant offline/timeout/5xx et vérifiant l’état sûr.
  - Delta d’architecture (réduction imports interdits, notamment UI→network impl).

### Jalon M5 — `core/parental` : politiques et contrôles explicites (fail-closed si L1)
**But** : garantir la sûreté des restrictions et éviter tout contournement implicite.

- **Travaux**
  - Clarifier les contrats : règles, policies, sources de vérité (profil/settings), erreurs et audit.
  - Encapsuler stockage/SDK éventuels ; introduire orchestrator/policy engine.
  - Définir les transitions d’état : changement de profil, activation/désactivation, synchronisation.
  - Définir le comportement “données manquantes / incohérentes” (état sûr).
- **Critères d’acceptation**
  - Le mode dégradé est **fail-closed** quand pertinent (restrictions conservées si incertitude).
  - Les décisions parentales critiques sont observables (sans PII inutile).
  - Aucun accès direct UI à des implémentations concrètes de policy.
- **Preuves à indexer**
  - Tests (au minimum unit + intégration) sur scénarios limites/contournement.
  - ADR si une règle/stratégie de sûreté est introduite ou changée.

### Jalon M6 — `core/profile` (conditionnel) : si impact sécurité ou données
**But** : isoler profil/properties critiques si elles influencent auth/parental/storage.

- **Travaux**
  - Stabiliser les contrats et isoler les adapters (storage/network) si le profil traverse des couches.
  - Rendre explicites les transitions (switch profil, suppression, sync) et l’état sûr.
- **Critères d’acceptation**
  - Aucun impact critique implicite sur auth/parental/storage.
- **Preuves à indexer**
  - Tests ciblés sur transitions + preuve CI.

## Gate de sortie (Phase 4)
La phase ne se clôture que si :
- réduction mesurable des dépendances interdites sur les sous-domaines traités ;
- contrats explicités et utilisés via ports (UI → ports, pas UI → impl) ;
- comportement critique nominal **et** dégradé couvert par tests adaptés ;
- rollback démontrable pour chaque lot exécuté (ou dérogation formelle).

## Critères d’arrêt (stop immédiat)
- **régression startup/auth** (invariant `C1/C2` cassé) ;
- **perte de données locales** (ou risque non maîtrisé de perte/corruption) ;
- **stockage sensible non maîtrisé** (secrets/PII exposés, logs, persistance) ;
- **rollback non démontrable** pour un lot à risque (ou dérogation absente).

## Checklist “fin de phase” (à cocher avant clôture)
- [ ] Lots exécutés dans l’ordre recommandé (ou déviation justifiée et tracée)
- [ ] Pour chaque lot : contrats explicités + ports/adapters en place
- [ ] Pour chaque lot : DI encapsulée au niveau module (pas de fuite vers UI)
- [ ] Pour chaque lot : tests nominal + dégradé + preuves CI indexées
- [ ] Pour chaque lot : rollback documenté et praticable
- [ ] Gates `docs/rules_nasa.md` respectés (preuves, traçabilité, revue renforcée si C1/L1)
