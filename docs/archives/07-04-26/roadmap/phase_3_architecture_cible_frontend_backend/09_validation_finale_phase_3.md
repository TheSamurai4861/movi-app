# Sous-phase 3.7 - Validation finale de la phase 3

## Objectif

Clore la phase 3 `Architecture cible frontend et backend` avec:
- une synthese de la cible architecture finale
- un recap des decisions architecture prises
- les sujets deferes a l'implementation et a la phase performance
- les risques restants
- la liste des artefacts produits
- un verdict explicite sur la stabilite de la phase

## Cible architecture finale du tunnel

La cible architecture retenue repose sur un principe simple:
- un seul modele d'etat canonique pour le tunnel
- un seul orchestrateur de parcours
- un routeur qui projette l'etat au lieu de le recalculer
- une UI qui consomme un state et emet des intentions
- une infra branchee via des ports explicites

Cette cible se decompose ainsi:

### Source de verite

- `TunnelState` comme modele canonique unique
- qualifiers transverses pour nominal, degrade, blocked et empty content
- `TunnelCriteriaSnapshot` comme lecture des conditions reelles

### Moteur de parcours

- `EntryJourneyOrchestrator` comme point central de decision
- calcul des gardes, transitions et reason codes
- publication d'un etat observable par l'UI et le routeur

### Couches

- `presentation` pour les surfaces tunnel
- `application` pour l'orchestration
- `domain` pour les policies, state model et ports
- `data / infrastructure` pour les adapters et SDKs concrets

### Composition

- `GetIt` pour assembler
- `Riverpod` pour exposer
- `GoRouter` pour projeter

### Migration

- migration par paliers
- coexistence temporaire des ponts legacy
- feature flags limites et scopes
- rollback simple a chaque palier

## Decisions architecture principales actees

### Modele d'etat

- abandon du modele purement `destination + phase + status` comme source de verite metier
- adoption d'un `TunnelState` canonique
- `Home vide` reste un mode d'arrivee de `home`, pas un etat tunnel distinct

### Orchestrateur

- l'idee d'un orchestrateur unique est conservee
- l'orchestrateur actuel sert de base de transition
- la cible est un composant application pilote par ports

### Separation des couches

- un module transversal `entry_journey` est recommande
- `startup` reste recentre sur le bootstrap technique
- `auth`, `profile`, `iptv` restent des domaines sources au service du tunnel

### Contrats

- les resolutions critiques du tunnel deviennent des contrats explicites
- `startup`, `connectivity`, `session`, `profiles`, `sources`, `source validation`, `pre-home`, `continuity` sont cadres
- la frontiere `must-have before home` vs `can-load-after-home` est explicite

### Composition et routing

- `GetIt` reste le conteneur d'assemblage
- `Riverpod` devient la couche d'exposition officielle vers l'UI
- `slProvider` devient un bridge de transition, plus la porte d'entree cible
- le routeur lit un derive stable `TunnelSurface`
- `LaunchRedirectGuard` est ramene a un role de protection et de compatibilite

### Migration

- migration par paliers preferee au `big bang`
- la source de verite migre avant les ecrans
- les flags restent peu nombreux et portent des blocs coherents

## Schema de reference

Le schema de synthese de l'architecture cible est documente ici:
- [08_schema_architecture_cible.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/08_schema_architecture_cible.md)

## Coherence avec les phases 1 et 2

La phase 3 reste coherente avec la phase 1 car:
- le tunnel retenu est respecte
- les etats principaux du parcours sont couverts
- la logique `home seulement quand l'etat requis est pret` est preservee

La phase 3 reste coherente avec la phase 2 car:
- les surfaces UI restent derivees de l'etat
- le tunnel TV n'est pas separe techniquement du tunnel mobile
- les etats inline, loading et recovery peuvent etre servis sans multiplier les ecrans

## Sujets deferes a l'implementation

Ces sujets sont cadres, mais doivent encore etre concretises en code:

- creation du module `entry_journey`
- implementation concrete de `TunnelState`
- implementation concrete des ports du tunnel
- branchement du nouvel orchestrateur
- derive `TunnelSurface`
- refactor progressif de `LaunchRedirectGuard`
- refactor progressif des pages `welcome/*`
- extraction des adapters `home preload`

## Sujets deferes a la phase performance ou fiabilisation

Ces sujets ne remettent pas en cause la cible architecture, mais devront etre traites ensuite:

- timeouts et seuils exacts du `preload_slow`
- telemetry fine des transitions et retries
- instrumentation des rollbacks de migration
- optimisation des lectures croisees `cloud / local`
- verification charge froide mobile vs TV

## Risques restants

Les principaux risques encore ouverts sont:

- laisser coexister trop longtemps `TunnelState` et `BootstrapDestination`
- conserver trop de logique metier dans le routeur pendant la migration
- reintroduire de la logique de sequence dans les pages refondues
- multiplier les flags au-dela de ce qui est necessaire
- sous-estimer l'effort de refactor des providers qui lisent `slProvider`
- garder `AppStateController` trop central dans le tunnel

## Artefacts produits dans cette phase

- [01_preparation_alignement_architecture.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/01_preparation_alignement_architecture.md)
- [02_modele_etat_canonique_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/02_modele_etat_canonique_tunnel.md)
- [03_entry_journey_orchestrator.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/03_entry_journey_orchestrator.md)
- [04_separation_couches_et_modules.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/04_separation_couches_et_modules.md)
- [05_contrats_backend_et_infra_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/05_contrats_backend_et_infra_tunnel.md)
- [06_composition_root_routing_et_state_management.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/06_composition_root_routing_et_state_management.md)
- [07_strategie_migration_feature_flags_rollout.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/07_strategie_migration_feature_flags_rollout.md)
- [08_schema_architecture_cible.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_3_architecture_cible_frontend_backend/08_schema_architecture_cible.md)

## Verdict de stabilite

Verdict:
- la phase 3 est suffisamment stable pour passer au decoupage d'implementation puis a la construction du nouveau tunnel

Pourquoi:
- le modele d'etat est fixe
- l'orchestrateur cible est clair
- les couches et dependances sont cadrees
- les contrats backend et infra sont assez stables
- la composition `GetIt / Riverpod / GoRouter` est clarifiee
- la migration progressive est bornee

Ce qui n'est pas encore final:

- le code de l'orchestrateur cible
- les implementations concretes de tous les ports
- le plan de stories d'implementation
- les seuils de performance et d'observabilite finaux

## Recommandation de suite

La suite recommandee est:
1. decouper l'implementation du tunnel en lots techniques
2. commencer par le coeur `entry_journey` avant les ecrans
3. migrer ensuite le routeur et les surfaces UI dans l'ordre defini en `3.6`

## Conclusion

La phase 3 a converti les decisions UX et UI en une cible architecture defendable, migrable et testable. Le projet peut maintenant avancer vers le decoupage d'implementation et la construction du nouveau tunnel sans re-ouvrir les arbitrages structurants, sauf changement produit volontaire.
