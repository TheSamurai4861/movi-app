# Validation finale - Phase 4 Performance et resilience du tunnel

## Objectif de cloture

Confirmer que la phase 4 est suffisamment stable pour lancer l'implementation technique et la QA du nouveau tunnel, sans re-ouvrir les decisions des phases 1, 2 et 3.

## Synthese finale de la cible

La phase 4 fige une cible claire:
- le tunnel a des budgets de temps explicites
- les contrats critiques ont des politiques de timeout et retry bornees
- le pre-home ne garde que le strict necessaire
- le catalogue complet `10-15 s` ne bloque plus l'entree dans `Home`
- les erreurs critiques convergent vers des safe states lisibles
- toutes les transitions critiques deviennent mesurables

En pratique, la promesse retenue est:
- `Home` apparait quand le minimum utile est pret
- le reste peut continuer apres `Home`
- si le nominal echoue, le tunnel doit atteindre vite un etat comprehensible

## Recap des decisions prises

### 1. Budgets

Les budgets critiques retenus sont:
- `preparing_system <= 1200 ms` nominal
- `session_resolve <= 800 ms` nominal
- `source_validation <= 1200 ms` nominal
- `preloading_home <= 2500 ms` nominal
- `time_to_safe_state <= 2500 ms` nominal

Le seuil global le plus structurant reste:
- `preloading_home > 5000 ms` n'est plus une attente acceptable sans sortie explicite

### 2. Timeout, retry, fallback

Les decisions structurantes sont:
- aucun contrat critique ne retrye indefiniment
- la plupart des contrats reseau ont `1` retry automatique maximum
- certains contrats de selection ne retryent pas et renvoient directement vers le choix utilisateur
- le fallback local est autorise seulement si une continuation sure existe

### 3. Separation pre-home / post-home

Decision structurante:
- le catalogue complet n'appartient plus au tunnel pre-home

Avant `Home`, on attend seulement:
- session
- profil
- source
- validation source
- catalogue minimal exploitable
- bibliotheque minimale
- preload minimal de `Home`

Apres `Home`, on peut poursuivre:
- catalogue complet
- enrichissements secondaires
- sync de confort

### 4. Instrumentation

La phase 4 impose:
- des evenements de stage
- des evenements de contrats
- des evenements de retry et recovery
- une telemetry distincte entre `catalog_minimal_ready` et `catalog_full_load_completed`

Sans cela, les budgets et les safe states ne sont pas pilotables.

### 5. Safe states

Les safe states critiques retenus sont:
- `network_required_blocked`
- `auth_required_explicit`
- `profile_selection_required`
- `source_selection_required`
- `source_recovery_required`
- `local_fallback_entry`
- `prehome_partial_recovery`
- `ready_for_home_empty`

Decision structurante:
- aucune de ces situations ne doit recreer une page technique non prevue en phases 1 et 2

### 6. Optimisations obligatoires avant release

Le noyau `mandatory` retenu est:
- sortir le catalogue complet du pre-home
- borner `preloading_home`
- centraliser la decision tunnel
- borner les contrats critiques
- rendre explicites les recoveries `offline`, `session invalide`, `source invalide`
- instrumenter les transitions critiques

## Coherence avec les phases precedentes

La phase 4 reste coherente avec:
- phase 1: pas de re-ouverture du parcours UX
- phase 2: pas de nouvelle surface UI ajoutee
- phase 3: alignement complet avec `TunnelState`, l'orchestrateur cible, les ports et la projection routeur

Points explicitement respectes:
- `Home vide` reste une issue fonctionnelle, pas un echec tunnel
- `Choix / ajout source` reste la surface de recovery source
- `Auth` reste la surface de reprise session
- le routeur n'est plus cense attendre un preload exhaustif

## Sujets deferes a l'implementation

Les sujets suivants sont volontairement deferes a l'implementation:
- choix exact des APIs et classes de telemetry
- strategie de cancellation concrete des jobs pre-home
- parallelisation fine des resolutions selon les contraintes reelles du code
- details d'integration entre orchestrateur, ports et providers
- tuning fin des seuils par plateforme apres mesures reelles

## Sujets deferes a la QA

La QA devra verifier en priorite:
- respect des budgets critiques sur scenarios cold et warm
- mesure de `time_to_safe_state`
- parcours `offline`
- parcours `session expiree`
- parcours `source invalide`
- separation effective entre `catalog_minimal_ready` et `catalog_full_load_completed`
- absence de blocage sur catalogue exhaustif long

## Risques restants

Les risques restants les plus importants sont:
- la migration legacy peut laisser des attentes encore cachees avant `Home`
- le routeur ou certains guards peuvent encore projeter des hypotheses anciennes
- la validation source peut rester le hotspot principal
- la frontiere exacte entre `degraded` et `blocked` demandera sans doute un ajustement apres telemetry

Ces risques sont acceptables a ce stade car ils sont:
- identifies
- relies a des points de mesure
- relies a des optimisations mandatory

## Liste des artefacts produits

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

## Verdict final

La phase 4 est suffisamment stable pour passer a la suite.

Cela signifie que:
- les budgets de performance sont verrouilles a un niveau defendable
- les policies de timeout/retry/fallback sont explicites
- les safe states critiques sont definis
- l'instrumentation minimale est fixee
- le minimum technique avant release est priorise

La suite logique est:
1. transformer ces decisions en plan d'implementation concret
2. brancher la telemetry et les safe states dans le tunnel refactorise
3. preparer la strategie QA et les scenarios de validation automatisables
