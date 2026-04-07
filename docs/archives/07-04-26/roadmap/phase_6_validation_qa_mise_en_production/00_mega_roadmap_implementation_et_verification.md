# Mega roadmap - Implementation et verification du tunnel cible

## Objectif

Transformer les decisions des phases 1 a 5 en programme d'execution concret, puis verifier de facon defendable que le nouveau tunnel est:
- plus simple a comprendre
- plus rapide jusqu'a un etat utile
- plus robuste sur les cas degrades
- mieux observable
- rollbackable a chaque grande bascule

Cette roadmap couvre tout le chemin:
1. implementation par vagues
2. verification continue apres chaque vague
3. stabilisation pre-release
4. rollout progressif
5. validation finale avant generalisation

## Point de depart fige

La mega roadmap part des decisions deja verrouillees:
- phase 1: parcours cible et surfaces UX
- phase 2: systeme visuel, composants et comportements mobile/TV
- phase 3: `TunnelState`, `EntryJourneyOrchestrator`, ports et projection routeur
- phase 4: budgets, safe states, telemetry, separation pre-home / post-home
- phase 5: backlog de lots, dependances, flags, plan de migration et `definition of done`

Elle ne re-ouvre pas:
- le blueprint UX
- la spec UI
- le modele d'etat canonique
- la doctrine performance/resilience

## Principes d'execution

- `Measure before switch`: aucune bascule critique sans telemetry exploitable.
- `State before screens`: le coeur `TunnelState + Orchestrator` passe avant les surfaces finales.
- `Project, do not recalculate`: le routeur projette l'etat; il ne re-derive pas la logique metier.
- `Bound before beautify`: les politiques de timeout/retry/fallback sont posees avant les finitions UI.
- `One coherent flag per risky change`: peu de flags, chacun couvre un bloc defendable.
- `No long double source of truth`: toute coexistence legacy est bornee dans le temps.
- `Home after minimal useful readiness`: le catalogue complet `10-15 s` ne re-rentre jamais dans le pre-home.
- `Proof at every wave`: chaque vague exige des preuves fonctionnelles, telemetry et rollback.

## Non-negociables

Le programme doit respecter:
- `preparing_system <= 1200 ms` nominal
- `session_resolve <= 800 ms` nominal
- `source_validation <= 1200 ms` nominal
- `preloading_home <= 2500 ms` nominal
- `preloading_home > 5000 ms` = sortie explicite obligatoire
- `time_to_safe_state <= 2500 ms` nominal
- `catalog_minimal_ready` avant `Home`
- `catalog_full_load_completed` apres `Home`

Les safe states critiques a conserver explicitement:
- `network_required_blocked`
- `auth_required_explicit`
- `profile_selection_required`
- `source_selection_required`
- `source_recovery_required`
- `local_fallback_entry`
- `prehome_partial_recovery`
- `ready_for_home_empty`

## Lots et flags structurants

Lots critiques deja identifies:
- `B4` bascule vers la nouvelle source de verite
- `C4` validation source et recovery
- `C5` pre-home minimal
- `D2` projection routeur sur `TunnelSurface`
- `G1` hub source unifie
- `G2` ajout source + validation guidee
- `H2` separation `catalog minimal` / `catalog full`
- `H4` nettoyage final legacy

Flags cibles:
- `entry_journey_telemetry_v2`
- `entry_journey_state_model_v2`
- `entry_journey_routing_v2`
- `entry_journey_ui_v2`
- `entry_journey_source_hub_v2`
- `entry_journey_prehome_v2`
- `entry_journey_cleanup_v2`

## Strategie generale

Le programme est decoupe en 8 vagues. Chaque vague se termine par:
- une verification fonctionnelle
- une verification telemetry/performance
- une verification de rollback
- un gate `go / no-go`

Le chemin critique reste:
- observabilite
- source de verite
- contrats source / pre-home
- projection routeur
- bloc source
- pre-home borne
- cleanup legacy

## Vague 0 - Preparation operative

But:
- preparer le terrain d'execution sans encore modifier le comportement utilisateur cible

Lots principaux:
- cadrage d'equipe sur la mega roadmap
- planification des PR boundaries
- nomination des owners par epic
- mise en place des dashboards et traces de base

Entrees:
- phases 1 a 5 validees

Sorties attendues:
- backlog ordonne confirme
- responsabilites explicites
- environnements de test identifies
- dashboard minimal de suivi pret

Verification:
- revue technique de lancement
- validation que chaque lot critique a owner, flag et rollback

Gate:
- aucune implementation critique ne commence sans tableau de bord minimal et plan de rollback associe

Artefacts de vague 0:
- [01_vague_0_preparation_operative.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_6_validation_qa_mise_en_production/01_vague_0_preparation_operative.md)
- [02_registre_owners_criticite_et_preuves.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_6_validation_qa_mise_en_production/02_registre_owners_criticite_et_preuves.md)
- [03_pr_boundaries_et_regles_de_merge.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_6_validation_qa_mise_en_production/03_pr_boundaries_et_regles_de_merge.md)
- [04_environnements_dashboard_et_traces.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_6_validation_qa_mise_en_production/04_environnements_dashboard_et_traces.md)
- [05_gate_lancement_vague_0.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_6_validation_qa_mise_en_production/05_gate_lancement_vague_0.md)

## Vague 1 - Observabilite et garde-fous

But:
- mesurer le tunnel actuel et preparer les futures comparaisons

Lots:
- `A1` instrumentation du tunnel existant
- `A2` reason codes et correlation IDs
- `A3` flags techniques
- socle commun de `E1` si utile pour preparer les futures surfaces

Flags:
- `entry_journey_telemetry_v2`

Sorties implementation:
- evenements de stages critiques
- distinction `catalog_minimal_ready` / `catalog_full_load_completed`
- dashboards initiaux
- kill switches techniques disponibles

Verification requise:
- tests integration sur emission des evenements critiques
- verification manuelle des traces `cold start`, `warm start`, `offline`, `source invalide`
- verification que les flags desactivent proprement les nouvelles emissions si besoin

Gate go/no-go:
- oui si les temps actuels et les failures critiques sont lisibles
- non si les transitions majeures restent opaques

Rollback:
- desactivation de `entry_journey_telemetry_v2`

## Vague 2 - Coeur canonique en shadow mode

But:
- introduire la nouvelle source de verite sans casser le tunnel legacy

Lots:
- `B1` modele `TunnelState`
- `B2` bridge `legacy -> TunnelState`
- `B3` `EntryJourneyOrchestrator` en shadow mode
- `C1` contrat session/auth
- `C2` contrat profils
- `C3` contrat sources

Flags:
- `entry_journey_state_model_v2`

Sorties implementation:
- `TunnelState` derive de l'existant
- orchestrateur capable de calculer le tunnel cible en parallele
- ports metier minimaux disponibles pour session, profils et sources

Verification requise:
- tests unitaires de transitions sur `TunnelState`
- comparatif legacy vs shadow sur scenarios nominaux et degrades
- verification que l'orchestrateur detecte correctement:
  - session absente
  - session expiree
  - profil requis
  - source requise

Gate go/no-go:
- oui si le shadow mode converge sur les memes decisions que l'existant la ou attendu, et sur de meilleures decisions la ou la cible l'exige
- non si les derives divergent sans explication defendable

Rollback:
- desactivation de `entry_journey_state_model_v2`

## Vague 3 - Bascule du coeur et projection routeur

But:
- faire du nouveau coeur la source de verite et projeter les surfaces depuis cet etat

Lots:
- `B4` bascule de la source de verite
- `D1` derive `TunnelSurface`
- `D2` routeur projete sur `TunnelSurface`
- `D3` simplification des guards legacy

Flags:
- `entry_journey_state_model_v2`
- `entry_journey_routing_v2`

Sorties implementation:
- le routeur ne re-derive plus la logique auth/profile/source
- la navigation depend du `TunnelState`
- reduction des branches implicites dans `LaunchRedirectGuard`

Verification requise:
- tests integration navigation `cold`, `warm`, `resume`, `retry`
- verification absence de loops de redirection
- verification du temps vers premier safe state
- verification rollback sur flags `state_model` puis `routing`

Gate go/no-go:
- oui si la navigation reste stable, lisible et reversible
- non si des loops, incoherences de surface ou etats muets apparaissent

Rollback:
- d'abord couper `entry_journey_routing_v2`
- si necessaire couper `entry_journey_state_model_v2`

## Vague 4 - Composants partages et surfaces amont

But:
- migrer les briques UI communes puis les surfaces `Preparation systeme`, `Auth`, `Creation profil`, `Choix profil`

Lots:
- `E2` composants de selection et feedback
- `E3` focus TV commun
- `F1` `Preparation systeme`
- `F2` `Auth`
- `F3` `Creation profil`
- `F4` `Choix profil`

Flags:
- `entry_journey_ui_v2`

Sorties implementation:
- `TunnelPageShell`, `TunnelHeroBlock`, `TunnelFormShell`, feedbacks inline cibles
- splash cible avec logo centre, indicateur de chargement et message bas
- surfaces amont conformes a la spec UI phase 2

Verification requise:
- widget tests des composants communs
- tests integration des parcours:
  - premiere connexion
  - session expiree
  - profil requis
  - TV focus sur formulaires et galerie profils
- verification visuelle mobile/TV sur ecrans critiques

Gate go/no-go:
- oui si les surfaces amont sont visuellement coherentes et alignees sur le nouvel etat canonique
- non si elles reintroduisent des decisions metier locales ou cassent la navigation TV

Rollback:
- desactivation de `entry_journey_ui_v2`

## Vague 5 - Bloc source et recoveries

But:
- livrer le hub source unifie avec validation guidee et recovery explicite

Lots:
- `C4` contrat validation source / recovery
- `G1` hub source unifie
- `G2` ajout source + validation guidee
- `G3` recovery source

Flags:
- `entry_journey_source_hub_v2`

Sorties implementation:
- surface unique `Choix / ajout source`
- messages inline et recoveries cibles
- choix manuel obligatoire si source active absente/invalide
- `catalog empty` traite comme issue fonctionnelle, pas erreur tunnel

Verification requise:
- integration sur scenarios:
  - aucune source
  - une source valide
  - plusieurs sources
  - source active invalide
  - erreur reseau lors de validation
  - retry et retour arriere
- verification `time_to_safe_state` sur erreurs source
- verification TV focus sur galerie/liste source

Gate go/no-go:
- oui si le bloc source est plus lisible que l'existant et converge toujours vers une issue claire
- non si la validation source reste opaque, bloquante sans issue ou ambigue

Rollback:
- desactivation de `entry_journey_source_hub_v2`

## Vague 6 - Pre-home borne et separation minimal/full

But:
- rendre `preloading_home` borne, explicite et conforme aux budgets

Lots:
- `C5` contrat pre-home minimal
- `H1` surface `Chargement medias`
- `H2` separation `catalog minimal` / `catalog full`

Flags:
- `entry_journey_prehome_v2`

Sorties implementation:
- `Home` affichee sur seuil minimal utile
- chargement complet poursuit apres `Home`
- surface `Chargement medias` alignee sur la spec UI et les safe states
- `ready_for_home_empty` gere proprement

Verification requise:
- integration:
  - nominal warm start
  - nominal cold start
  - preload long
  - preload partiel
  - catalogue vide
- verification budgets:
  - `preloading_home <= 2500 ms` nominal
  - sortie explicite avant `> 5000 ms`
- verification telemetry:
  - `catalog_minimal_ready`
  - `catalog_full_load_started`
  - `catalog_full_load_completed`

Gate go/no-go:
- oui si `Home` n'attend plus le catalogue complet et que les safe states restent lisibles
- non si le tunnel attend encore une charge exhaustive avant `Home`

Rollback:
- desactivation de `entry_journey_prehome_v2`

## Vague 7 - Convergence et nettoyage legacy

But:
- supprimer les branchements obsoletes et fermer la coexistence temporaire

Lots:
- `H3` sortie des preferences hors logique metier
- `H4` nettoyage final legacy

Preconditions:
- `state_model`, `routing`, `ui`, `source_hub` et `prehome` stabilises

Flags:
- `entry_journey_cleanup_v2`

Sorties implementation:
- reduction forte des fichiers/branches legacy inutiles
- retrait progressif des anciennes pages `welcome/*` non conservees
- guards et derives anciennes voies supprimes ou neutralises

Verification requise:
- grep de references legacy
- verification compile + tests regression
- verification qu'aucune surface cible ne depend encore d'une decision legacy cachee

Gate go/no-go:
- oui si le nettoyage retire de la complexite sans perte de couverture fonctionnelle
- non si `H4` devient un lot fourre-tout ou masque encore une dependance critique

Rollback:
- reactivation temporaire du flag `entry_journey_cleanup_v2` a `off`

## Vague 8 - Verification finale et generalisation

But:
- confirmer que le nouveau tunnel est objectivement meilleur avant generalisation

Scope:
- regression fonctionnelle complete
- comparaison avant/apres
- verification production safe
- rollout progressif puis generalisation

### 8.1 Verification fonctionnelle obligatoire

Scenarios prioritaires:
- premier lancement
- session valide
- session expiree
- utilisateur offline
- aucune source
- une seule source
- plusieurs sources
- source invalide
- preload partiel
- catalogue vide
- reprise apres fermeture au milieu du tunnel

Niveaux de test attendus:
- unit: etat, derives, reason codes, policies
- widget: composants tunnel critiques
- integration: tunnel par surface et transitions
- e2e: parcours nominaux et degrades sur device cible

### 8.2 Verification performance et resilience

Checks obligatoires:
- comparaison `cold start` avant/apres
- comparaison `warm start` avant/apres
- mesure `time_to_safe_state`
- verification du respect des budgets critiques
- verification que `catalog full` n'allonge plus le pre-home
- verification des retries bornes et des sorties degradees

### 8.3 Verification observabilite

Le rollout ne generalise pas tant que les evenements suivants ne sont pas lisibles:
- `entry_journey_started`
- `entry_journey_stage_entered`
- `entry_journey_stage_completed`
- `entry_journey_stage_slow`
- `entry_journey_stage_blocked`
- `entry_journey_safe_state_reached`
- `source_validation_completed`
- `catalog_minimal_ready`
- `catalog_full_load_completed`
- `entry_journey_completed`

### 8.4 Rollout recommande

Ordre recommande:
1. internal dogfood
2. beta/QA elargie
3. exposition ciblee derriere flags
4. generalisation progressive
5. retrait final des flags devenus inutiles

Conditions minimales avant generalisation:
- aucune regression critique ouverte
- budgets defendables sur scenarios principaux
- safe states observes en telemetry
- rollback confirme en environnement reel

## Matrice de verification par jalon

### Jalon 1 - Mesure et lisibilite

Sortie attendue:
- tunnel actuel mesure
- flags et events en place

Preuve:
- dashboard de base lisible
- traces sur 5 scenarios critiques

### Jalon 2 - Nouveau coeur lisible

Sortie attendue:
- `TunnelState` et orchestrateur en shadow fiables

Preuve:
- comparatif legacy/shadow
- divergences expliquees et bornees

### Jalon 3 - Projection routeur stable

Sortie attendue:
- navigation gouvernee par `TunnelSurface`

Preuve:
- aucun loop
- aucun ecran technique parasite

### Jalon 4 - Surfaces amont conformes

Sortie attendue:
- `Preparation systeme`, `Auth`, `Profil` alignes sur la cible

Preuve:
- widget/integration tests verts
- revue visuelle mobile/TV

### Jalon 5 - Bloc source cible

Sortie attendue:
- hub source unifie stable

Preuve:
- recoveries testees
- `source invalide` et `retry` lisibles

### Jalon 6 - Pre-home borne

Sortie attendue:
- `Home` apres readiness minimale

Preuve:
- separation `minimal/full` mesuree
- pas d'attente sur catalogue complet

### Jalon 7 - Tunnel cible propre

Sortie attendue:
- legacy ferme
- flags reducibles

Preuve:
- branches legacy critiques retirees
- tunnel cible plus simple a raisonner

## Checklist go/no-go finale

Le tunnel peut etre generalise seulement si:
- les surfaces UX cibles sont bien celles validees en phase 1
- la spec UI phase 2 est respectee sur mobile et TV
- `TunnelState` et l'orchestrateur pilotent vraiment le tunnel
- le routeur ne recalcule plus les decisions metier
- `catalog_minimal_ready` et `catalog_full_load_completed` sont separes
- les safe states critiques ont tous ete verifies
- les budgets principaux sont tenus ou documentes avec exception defendable
- le rollback fonctionne encore tant que le nettoyage final n'est pas termine
- la telemetry de bout en bout est exploitable

## Risques a surveiller pendant l'execution

- `B4` trop large: a recouper si la bascule du coeur melange trop d'adaptations
- `D2` loops de routing: a tester en continu des qu'un flag de projection est active
- `G1/G2` complexite source: a isoler des finitions UI non critiques
- `H2` tentation de recharger trop avant `Home`: a refuser explicitement
- `H4` cleanup fourre-tout: a decouper si des suppressions non liees s'y accumulent
- coexistence trop longue: a limiter par jalons fermes

## Resultat attendu

Si la mega roadmap est suivie correctement, le resultat attendu est:
- un tunnel d'entree gouverne par un seul modele d'etat
- des surfaces UX/UI plus lisibles et plus coherentes
- une entree dans `Home` plus rapide jusqu'a un etat utile
- des recoveries explicites sur les cas critiques
- une architecture plus simple a maintenir
- une verification defendable avant generalisation

## Prochaine etape recommandee

Lancer la vague 0 puis la vague 1 sans attendre, puis ne pas engager `B4`, `D2`, `G1/G2` ou `H2` tant que:
- la telemetry n'est pas exploitable
- les tests de base ne sont pas poses
- les points de rollback ne sont pas verifies
