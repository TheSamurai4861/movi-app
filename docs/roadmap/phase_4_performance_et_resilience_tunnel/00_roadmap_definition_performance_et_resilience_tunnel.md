# Phase 4 - Performance et resilience du tunnel

## Objectif

Rendre le tunnel d'entree plus rapide, plus previsible et plus robuste, sans re-ouvrir les decisions UX, UI ou architecture deja figees en phases 1, 2 et 3.

La phase 4 ne redefinit pas:
- le parcours cible
- les surfaces UI cibles
- l'architecture cible du tunnel

Elle fixe:
- les budgets de temps par etape
- les politiques de timeout, retry, preload et fallback
- les safe states de nominal, degrade et recovery
- l'instrumentation du tunnel
- la liste des optimisations obligatoires avant release

## Entrees de reference

La phase 4 s'appuie directement sur les artefacts valides des phases 1, 2 et 3:
- [09_validation_finale_phase_1.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/09_validation_finale_phase_1.md)
- [09_validation_finale_phase_2.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/09_validation_finale_phase_2.md)
- [09_validation_finale_phase_3.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/09_validation_finale_phase_3.md)
- [02_modele_etat_canonique_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/02_modele_etat_canonique_tunnel.md)
- [05_contrats_backend_et_infra_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/05_contrats_backend_et_infra_tunnel.md)
- [06_composition_root_routing_et_state_management.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/06_composition_root_routing_et_state_management.md)
- [07_strategie_migration_feature_flags_rollout.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/07_strategie_migration_feature_flags_rollout.md)
- [08_schema_architecture_cible.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/08_schema_architecture_cible.md)

## Resultat attendu

A la fin de la phase 4:
- chaque etape critique du tunnel a un budget de temps
- chaque timeout et retry a une politique explicite
- le preload pre-home est borne et decoupe en `must-have` vs `can-load-after-home`
- chaque transition critique est instrumentee
- chaque erreur majeure a un safe state et un comportement de recovery
- la liste des optimisations obligatoires avant release est priorisee

## Avancement courant

- sous-phase `4.0` : complete via [01_preparation_alignement_performance_resilience.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/01_preparation_alignement_performance_resilience.md)
- sous-phase `4.1` : complete via [02_budgets_performance_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/02_budgets_performance_tunnel.md)
- sous-phase `4.2` : complete via [03_politique_timeout_retry_preload_fallback.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/03_politique_timeout_retry_preload_fallback.md)
- sous-phase `4.3` : complete via [04_separation_charges_pre_home.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/04_separation_charges_pre_home.md)
- sous-phase `4.4` : complete via [05_plan_instrumentation_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/05_plan_instrumentation_tunnel.md)
- sous-phase `4.5` : complete via [06_matrice_nominal_degrade_recovery.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/06_matrice_nominal_degrade_recovery.md)
- sous-phase `4.6` : complete via [07_optimisations_obligatoires_avant_release.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/07_optimisations_obligatoires_avant_release.md)
- sous-phase `4.7` : complete via [09_validation_finale_phase_4.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/09_validation_finale_phase_4.md)

## Principes directeurs de la phase 4

- `Fast by contract`: chaque etape a un budget cible, pas seulement une impression de vitesse.
- `Degrade deliberately`: un etat lent ou partiel doit etre traite comme un mode de service explicite.
- `Must-have first`: ce qui n'est pas requis pour tenir la promesse pre-home doit sortir du tunnel.
- `Observable by default`: aucune transition critique ne doit rester opaque.
- `Retry with limits`: pas de retries implicites infinis ou non traces.
- `Safe states over crashes`: chaque echec critique doit deboucher sur un etat de repli defendable.

## Sous-phases proposees

### Sous-phase 4.0 - Preparation et alignement performance/resilience

But: cadrer les hypotheses de performance et de robustesse avant de fixer des budgets.

Travaux:
- relire les validations des phases 1, 2 et 3
- reprendre les etapes canoniques du tunnel
- lister les points deja identifies comme couteux ou instables:
  - startup
  - restore session
  - chargement profils
  - chargement sources
  - validation source
  - preload `home`
- lister les signaux de lenteur et de recovery deja connus
- lister les inconnues de mesure a borner

Livrables:
- perimetre performance/resilience de la phase
- liste des zones critiques a budgeter
- liste des inconnues a mesurer

Gate:
- le perimetre des mesures et des risques est verrouille

### Sous-phase 4.1 - Budgets de performance du tunnel

But: definir les budgets de temps par etape et les seuils de lenteur.

Travaux:
- fixer un budget cible par etape:
  - `preparing_system`
  - `auth_required` et resolution auth
  - `profile_required`
  - `source_required`
  - `preloading_home`
- definir:
  - budget nominal
  - seuil de degradation
  - seuil de blocage
- fixer les budgets agreges:
  - cold start
  - warm start
  - retour utilisateur sain
  - premier parcours

Livrables:
- tableau des budgets du tunnel
- seuils `nominal / slow / blocked`

Gate:
- chaque etape critique a un budget de temps defendable

### Sous-phase 4.2 - Politique de timeout, retry, preload et fallback

But: borner les comportements de patience et de recovery du tunnel.

Travaux:
- definir les timeouts par contrat critique
- definir les retries autorises, leur nombre et leur backoff
- definir les conditions d'arret du preload
- definir les conditions d'entree en fallback local
- definir les cas ou l'on bloque vs degrade

Livrables:
- politique timeout/retry du tunnel
- politique de preload borne
- politique de fallback et reprise

Gate:
- aucun comportement critique n'est laisse implicite ou infini

### Sous-phase 4.3 - Optimisation pre-home et separation des charges

But: eliminer les chargements inutiles avant `home` et clarifier ce qui peut etre differe.

Travaux:
- reprendre la liste `must-have before home`
- reprendre la liste `can-load-after-home`
- verifier chaque charge pre-home:
  - utile
  - differrable
  - supprimable
  - parallelisable
- definir les optimisations de sequence:
  - fusion
  - anticipation
  - lazy load
  - cache

Livrables:
- matrice `must-have / can-load-after-home`
- liste des chargements a sortir du tunnel
- decisions d'optimisation de sequence

Gate:
- le tunnel ne garde avant `home` que le strict necessaire

### Sous-phase 4.4 - Instrumentation, telemetry et reason codes de mesure

But: rendre toutes les transitions critiques observables.

Travaux:
- definir les evenements de mesure du tunnel
- definir les champs telemetry obligatoires
- definir les reason codes de lenteur, retry, fallback et blocage
- definir la granularite:
  - etape
  - contrat
  - transition
  - result
- definir les KPI de suivi post-release

Livrables:
- plan d'instrumentation
- catalogue des evenements de mesure
- reason codes de performance et resilience

Gate:
- chaque transition critique du tunnel est instrumentee

### Sous-phase 4.5 - Matrice nominal / degrade / recovery et safe states

But: definir les etats de repli robustes pour les erreurs critiques.

Travaux:
- definir les safe states pour:
  - offline
  - timeout
  - session invalide
  - source invalide
  - preload partiel
- construire la matrice:
  - etat detecte
  - comportement systeme
  - surface visible
  - action primaire
  - action secondaire
  - issue attendue
- verifier la coherence avec `TunnelState` et les surfaces UI

Livrables:
- matrice nominal / degrade / recovery
- catalogue des safe states critiques

Gate:
- chaque erreur critique a un etat de repli defini

### Sous-phase 4.6 - Optimisations obligatoires avant release

But: lister ce qui est mandatory pour sortir un tunnel suffisamment rapide et robuste.

Travaux:
- consolider les optimisations identifiees
- classer:
  - obligatoire avant release
  - souhaitee mais differrable
  - nice-to-have
- relier chaque optimisation a:
  - un budget
  - un risque
  - un point de mesure

Livrables:
- liste des optimisations obligatoires avant release
- priorisation `mandatory / should / later`

Gate:
- la release du nouveau tunnel a un minimum technique clair

### Sous-phase 4.7 - Validation finale de la phase 4

But: clore la phase performance/resilience avec une cible suffisamment stable pour implementation et QA.

Travaux:
- verifier la coherence avec les phases 1, 2 et 3
- confirmer les budgets de temps
- confirmer les politiques timeout/retry/fallback
- confirmer l'instrumentation et les safe states
- lister les points deferes a l'implementation ou a la QA

Livrables:
- synthese finale de la phase 4
- recap des decisions performance/resilience prises
- sujets deferes
- verdict de stabilite

Gate:
- chaque etape a un budget
- chaque erreur critique a un safe state

## Sequence de travail recommandee

Ordre conseille:
1. preparation et alignement
2. budgets de performance
3. timeouts, retries, preload et fallback
4. separation `must-have / can-load-after-home`
5. instrumentation et telemetry
6. safe states et matrice recovery
7. optimisations obligatoires
8. validation finale

## Liste des artefacts attendus dans le dossier

- [00_roadmap_definition_performance_et_resilience_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/00_roadmap_definition_performance_et_resilience_tunnel.md)
- [01_preparation_alignement_performance_resilience.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/01_preparation_alignement_performance_resilience.md)
- [02_budgets_performance_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/02_budgets_performance_tunnel.md)
- [03_politique_timeout_retry_preload_fallback.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/03_politique_timeout_retry_preload_fallback.md)
- [04_separation_charges_pre_home.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/04_separation_charges_pre_home.md)
- [05_plan_instrumentation_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/05_plan_instrumentation_tunnel.md)
- [06_matrice_nominal_degrade_recovery.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/06_matrice_nominal_degrade_recovery.md)
- [07_optimisations_obligatoires_avant_release.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/07_optimisations_obligatoires_avant_release.md)
- [08_schema_performance_resilience_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/08_schema_performance_resilience_tunnel.md)
- [09_validation_finale_phase_4.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_4_performance_et_resilience_tunnel/09_validation_finale_phase_4.md)

## Checkpoints de validation recommandes

- checkpoint 1: validation des zones critiques et hypotheses de mesure
- checkpoint 2: validation des budgets de temps
- checkpoint 3: validation des politiques timeout/retry/fallback
- checkpoint 4: validation des safe states critiques
- checkpoint 5: validation finale de la phase

## Prompts a me redonner pour lancer chaque sous-phase

Tu peux copier-coller ces prompts tels quels pour demarrer chaque sous-phase.

### Lancer la sous-phase 4.0

Nous lancons la sous-phase 4.0 de preparation et alignement performance/resilience pour le tunnel welcome -> auth -> source -> pre-home.
Travaille sur cette sous-phase uniquement.
Je veux:
- la liste des zones critiques a budgeter
- la liste des risques de lenteur et de fragilite deja connus
- la liste des inconnues a mesurer ou borner
- les ambiguities restantes a lever avant la sous-phase 4.1
Mets a jour la documentation dans docs/roadmap/phase_4_performance_et_resilience_tunnel/ si necessaire.

### Lancer la sous-phase 4.1

Nous lancons la sous-phase 4.1 de budgets de performance du tunnel.
Travaille sur cette sous-phase uniquement.
Je veux:
- un budget cible par etape du tunnel
- les seuils nominal / slow / blocked
- les budgets agreges cold start, warm start, retour utilisateur sain et premier parcours
- les arbitrages de budget encore ouverts
Mets a jour la documentation dans docs/roadmap/phase_4_performance_et_resilience_tunnel/ si necessaire.

### Lancer la sous-phase 4.2

Nous lancons la sous-phase 4.2 de politique timeout, retry, preload et fallback.
Travaille sur cette sous-phase uniquement.
Je veux:
- les timeouts par contrat critique
- les retries autorises et leur borne
- les regles de preload borne
- les conditions de fallback local, de blocage et de reprise
Mets a jour la documentation dans docs/roadmap/phase_4_performance_et_resilience_tunnel/ si necessaire.

### Lancer la sous-phase 4.3

Nous lancons la sous-phase 4.3 de separation des charges pre-home.
Travaille sur cette sous-phase uniquement.
Je veux:
- la matrice `must-have before home` vs `can-load-after-home`
- la liste des chargements a sortir du tunnel
- les optimisations de sequence recommandees
- les points qui restent a arbitrer
Mets a jour la documentation dans docs/roadmap/phase_4_performance_et_resilience_tunnel/ si necessaire.

### Lancer la sous-phase 4.4

Nous lancons la sous-phase 4.4 d'instrumentation, telemetry et reason codes de mesure.
Travaille sur cette sous-phase uniquement.
Je veux:
- le plan d'instrumentation du tunnel
- la liste des evenements de mesure
- la liste des champs telemetry obligatoires
- les reason codes de performance et resilience
Mets a jour la documentation dans docs/roadmap/phase_4_performance_et_resilience_tunnel/ si necessaire.

### Lancer la sous-phase 4.5

Nous lancons la sous-phase 4.5 de matrice nominal / degrade / recovery et safe states.
Travaille sur cette sous-phase uniquement.
Je veux:
- la matrice des cas nominaux, degrades et de recovery
- les safe states critiques
- le mapping etat detecte -> surface -> action -> issue
- les zones de fragilite restantes
Mets a jour la documentation dans docs/roadmap/phase_4_performance_et_resilience_tunnel/ si necessaire.

### Lancer la sous-phase 4.6

Nous lancons la sous-phase 4.6 de liste des optimisations obligatoires avant release.
Travaille sur cette sous-phase uniquement.
Je veux:
- la liste des optimisations mandatory
- la liste des optimisations souhaitables mais differrables
- la priorisation des optimisations
- le lien de chaque optimisation avec un budget ou un risque
Mets a jour la documentation dans docs/roadmap/phase_4_performance_et_resilience_tunnel/ si necessaire.

### Lancer la sous-phase 4.7

Nous lancons la sous-phase 4.7 de validation finale de la phase 4.
Travaille sur cette sous-phase uniquement.
Je veux:
- la synthese finale de la cible performance/resilience
- le recap des decisions prises
- les sujets deferes a l'implementation ou a la QA
- le verdict explicite de stabilite de la phase
Mets a jour la documentation dans docs/roadmap/phase_4_performance_et_resilience_tunnel/ si necessaire.

## Prompts de cloture de sous-phase

Tu peux aussi me redonner ces prompts a la fin de chaque sous-phase si tu veux un point de sortie formel.

### Fin de la sous-phase 4.0

Cloture la sous-phase 4.0.
Je veux:
- un verdict clair sur ce qui est verrouille
- les questions restantes avant 4.1
- la recommandation de prochaine etape

### Fin de la sous-phase 4.1

Cloture la sous-phase 4.1.
Je veux:
- le recap des budgets valides
- les seuils encore ouverts
- la recommandation de prochaine etape

### Fin de la sous-phase 4.2

Cloture la sous-phase 4.2.
Je veux:
- le recap des politiques timeout/retry/fallback retenues
- les points encore sensibles
- la recommandation de prochaine etape

### Fin de la sous-phase 4.3

Cloture la sous-phase 4.3.
Je veux:
- le recap `must-have / can-load-after-home`
- les charges sorties du tunnel
- la recommandation de prochaine etape

### Fin de la sous-phase 4.4

Cloture la sous-phase 4.4.
Je veux:
- le recap du plan d'instrumentation
- les evenements et reason codes critiques
- la recommandation de prochaine etape

### Fin de la sous-phase 4.5

Cloture la sous-phase 4.5.
Je veux:
- le recap des safe states critiques
- les cas encore fragiles
- la recommandation de prochaine etape

### Fin de la sous-phase 4.6

Cloture la sous-phase 4.6.
Je veux:
- la liste des optimisations obligatoires retenues
- ce qui peut etre differe
- la recommandation de prochaine etape

### Fin de la sous-phase 4.7

Cloture la phase 4.
Je veux:
- le verdict final de stabilite
- les risques restants
- la recommandation de suite
