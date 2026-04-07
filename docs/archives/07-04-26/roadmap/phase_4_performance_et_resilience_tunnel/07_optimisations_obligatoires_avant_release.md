# Sous-phase 4.6 - Optimisations obligatoires avant release

## Objectif

Transformer les budgets, politiques de timeout/retry, safe states et contrats d'instrumentation en une liste d'optimisations priorisee avant release.

Cette sous-phase ne re-ouvre pas:
- le blueprint UX
- la spec UI
- le modele canonique du tunnel

Elle fixe:
- ce qui est mandatory avant release
- ce qui est souhaite mais differrable
- ce qui peut attendre une iteration ulterieure

## Principe directeur

Une optimisation n'est `mandatory` que si son absence menace directement:
- un budget de `4.1`
- une politique critique de `4.2`
- la separation pre-home / post-home de `4.3`
- l'observabilite minimale de `4.4`
- un safe state critique de `4.5`

Le reste doit etre classe en `should` ou `later`, pour ne pas diluer la release.

## Regles de priorisation

### `mandatory`

A faire avant release si l'absence de l'optimisation:
- empeche de tenir les budgets principaux
- laisse un retry ou une attente infinie
- casse un safe state critique
- rend le tunnel non mesurable
- maintient une charge lourde inutile avant `home`

### `should`

A faire idealement avant release si l'optimisation:
- ameliore sensiblement la vitesse ou la robustesse
- reduit le bruit technique
- prepare mieux la migration

Mais son absence ne casse pas la promesse minimale de release.

### `later`

A faire apres release si l'optimisation:
- est utile mais non structurante
- affine les performances sans changer la robustesse du tunnel
- releve plus du confort ou d'une optimisation secondaire

## Liste des optimisations `mandatory`

| ID | Optimisation | Pourquoi c'est mandatory | Budget / risque / safe state lie |
| --- | --- | --- | --- |
| `M1` | Sortir le catalogue complet du pre-home et ne garder qu'un `catalogue minimal exploitable` avant `home` | sans cela, le tunnel reste prisonnier d'un chargement legitime de `10-15 s` | `catalog_ready`, `preloading_home`, risque "trop de travail avant home" |
| `M2` | Borner `preloading_home` avec une limite globale dure et couper les enrichissements differrables apres cette borne | sans borne globale, le tunnel peut rester dans une attente implicite non defendable | `preloading_home_global`, safe state `prehome_partial_recovery` |
| `M3` | Implementer un `EntryJourneyOrchestrator` unique comme source de verite du tunnel | sans moteur unique, les budgets et safe states restent incoherents entre routeur, pages et preload | risque "couplage routeur / pages / orchestrateur", coherence `TunnelState` |
| `M4` | Remplacer les deductions basees sur booleans disperses par un derive stable du `TunnelState` | sans source de verite canonique, les branches degradees restent fragiles | risque "double source de verite", safe states `auth_required`, `source_required` |
| `M5` | Borner tous les contrats critiques avec timeouts et retries explicites conformes a `4.2` | sans cela, on conserve des attentes ou retries silencieux | politiques `session_resolve`, `sources_inventory`, `source_validation`, `preloading_home` |
| `M6` | Faire de `offline` un vrai state bloque visible avec action `Retry` | sans cela, l'utilisateur reste sur un spinner ou un echec opaque | safe state `network_required_blocked`, budget `time_to_safe_state` |
| `M7` | Faire revenir toute `source invalide` vers le hub source avec message explicatif et action claire | sans cela, la recovery source reste technique et non guidee | safe states `source_selection_required`, `source_recovery_required` |
| `M8` | Faire revenir toute `session invalide` ou expiree vers `Auth` sans etat intermediaire ambigu | sans cela, le tunnel garde des etats hybrides difficiles a comprendre | safe state `auth_required_explicit`, budget `auth_surface_ready` |
| `M9` | Instrumenter toutes les transitions critiques du tunnel avec les evenements minimaux de `4.4` | sans observabilite, impossible de verifier budgets, retries et safe states | plan d'instrumentation, KPI release |
| `M10` | Instrumenter separement `catalog_minimal_ready` et `catalog_full_load_completed` | sans cette separation, les KPI du tunnel sont pollues par le catalogue complet | separation `must-have / can-load-after-home` |
| `M11` | Annuler ou court-circuiter les chargements pre-home devenus inutiles quand le tunnel change de branche | sans cancellation, le tunnel continue du travail couteux qui ne sert plus l'issue courante | risque "charges inutiles avant home", performance reseau et CPU |
| `M12` | Garder `Home vide` comme issue fonctionnelle et non comme echec tunnel | sans cela, un catalogue vide devient un faux negatif de fiabilite | safe state `ready_for_home_empty`, reason code `source_catalog_empty` |
| `M13` | Garantir qu'un safe state comprehensible est atteint dans la fenetre `time_to_safe_state` | sans cela, la robustesse percue de l'app reste mauvaise meme si les contrats finissent par repondre | budget `time_to_safe_state`, safe states `offline`, `source recovery`, `local fallback` |
| `M14` | Tracer chaque retry automatique et manuel comme evenement de premiere classe | sans cela, impossible de relier lenteur reelle et comportement de recovery | telemetry retry, risque "retry cache" |
| `M15` | Eviter toute attente du preload exhaustif avant `Home` dans le routeur ou les guards | sans cela, la phase 4 est contredite par la projection de navigation | risque "routeur <-> logique tunnel", budgets agreges warm/cold start |

## Commentaire sur les `mandatory`

Le noyau dur de release est:
- borner le pre-home
- rendre le tunnel explicite quand il degrade
- rendre les mesures fiables

Si une optimisation n'aide pas directement ces trois objectifs, elle ne doit pas monter artificiellement en `mandatory`.

## Liste des optimisations `should`

| ID | Optimisation | Valeur attendue | Lien principal |
| --- | --- | --- | --- |
| `S1` | Paralleliser davantage les resolutions independantes `profiles`, `sources`, `library` quand le contrat le permet | gain de latence sur warm et cold start | budgets `profiles_inventory`, `sources_inventory`, `library_ready` |
| `S2` | Ajouter un cache memoise court terme pour les snapshots locaux critiques | reduit les resolutions repetitives sur reprise rapide | `selected_profile_resolve`, `selected_source_resolve` |
| `S3` | Preparer un fallback automatique vers une autre source deja validee quand il y en a une | diminue le passage par recovery manuel | safe state `source_recovery_required` |
| `S4` | Enrichir les reason codes source pour separer timeout, auth invalide, source vide et reponse incoherente | meilleure precision de QA et support | `source_validation_completed`, `source_invalid` |
| `S5` | Ajouter une correlation forte entre `TunnelState`, route projetee et surface effectivement peinte | facilite le debug des regressions de navigation | observabilite et QA |
| `S6` | Optimiser le premier paint utile de `Home` apres `ready_for_home` | ameliore la perception globale de vitesse | budget `ready_for_home -> first_home_paint_useful` |
| `S7` | Isoler les chargements cloud confort de la bibliotheque dans des jobs post-home mieux traces | diminue le bruit pre-home et clarifie les mesures | separation pre/post-home |
| `S8` | Ajouter un resume de recovery source plus specifique cote UI | meilleure comprehension utilisateur | safe states source |

## Liste des optimisations `later`

| ID | Optimisation | Pourquoi plus tard | Lien principal |
| --- | --- | --- | --- |
| `L1` | Ajuster finement les seuils `slow` par device class apres observation terrain | demande des mesures reelles post-release | instrumentation et KPI |
| `L2` | Auto-tuning des timeouts selon qualite reseau observee | plus complexe, utile apres baseline | politiques `timeout` |
| `L3` | Prechauffage opportuniste de sections secondaires de `Home` avant interaction utilisateur | utile mais non critique | confort post-home |
| `L4` | Heuristiques de prediction de source ou profil a pre-resoudre | optimisation de confort | warm return |
| `L5` | Dashboard avance par cohortes `mobile`, `TV`, `cold`, `warm`, `local_fallback` | utile pour pilotage avance, non bloquant release | observabilite |

## Priorisation recommandee d'implementation

## Vague 1 - A faire en premier

Ces optimisations ouvrent la possibilite de tenir la release:
- `M1` sortir le catalogue complet du pre-home
- `M2` borner `preloading_home`
- `M3` moteur unique de tunnel
- `M5` timeouts et retries bornes
- `M6` safe state `offline`
- `M8` retour clair vers `Auth`
- `M9` instrumentation critique
- `M10` separation telemetry `catalog minimal` / `catalog full`

## Vague 2 - A faire juste apres

Ces optimisations securisent les branches de recovery:
- `M4` derive stable du `TunnelState`
- `M7` recovery source claire
- `M11` cancellation des charges inutiles
- `M12` `Home vide` traite comme succes fonctionnel
- `M13` garantie de temps vers safe state
- `M14` retry comme evenement trace
- `M15` routeur sans attente du preload exhaustif

## Vague 3 - A viser si la marge le permet

Ces optimisations ameliorent nettement le ressenti, mais ne doivent pas retarder la stabilisation:
- `S1`
- `S2`
- `S3`
- `S4`
- `S5`
- `S6`
- `S7`
- `S8`

## Definition of done minimale avant release

La release du nouveau tunnel ne doit pas partir tant que les conditions suivantes ne sont pas vraies:

1. aucun chargement exhaustif de catalogue n'est encore bloque avant `Home`
2. tous les contrats critiques ont un timeout et un retry bornes
3. `offline`, `session invalide` et `source invalide` ont chacun un safe state visible
4. le tunnel emet les evenements critiques definis en `4.4`
5. `time_to_safe_state` est mesurable
6. `Home vide` n'est plus traitee comme une panne

## Risques si l'on coupe dans les `mandatory`

Si `M1` ou `M2` saute:
- la promesse de rapidite du tunnel devient non credible

Si `M5`, `M6`, `M7` ou `M8` saute:
- la robustesse percue reste faible

Si `M9` ou `M10` saute:
- la phase 4 devient non pilotable apres release

Si `M15` saute:
- des regressions cachees peuvent maintenir de la logique legacy avant `Home`

## Verdict

La sous-phase `4.6` est suffisamment stable si l'on retient ces points:
- le noyau `mandatory` de release est clair
- le `should` est separe sans brouiller le minimum technique
- le `later` est assume comme post-release

La suite logique est la sous-phase `4.7`, pour clore la phase 4 avec une validation finale de stabilite.
