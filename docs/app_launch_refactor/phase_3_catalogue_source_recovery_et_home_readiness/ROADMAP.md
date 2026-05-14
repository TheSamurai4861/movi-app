# Phase 3 - Catalogue, source recovery et Home readiness

## Objectif

Regler le probleme principal observe : un snapshot absent ne doit plus produire
une attente opaque de 10 secondes.

Cette phase stabilise le chemin critique catalogue avant le remplacement complet
des ecrans boot. Elle doit garantir qu'un snapshot exploitable ouvre Home
rapidement, qu'un snapshot absent affiche une preparation explicite, et que les
erreurs source restent separees de Home partiel.

## Regles de travail

- Commencer par verifier le comportement actuel du resolver et de
  l'orchestrateur avant toute modification.
- Ne pas deplacer la logique catalogue critique dans les widgets.
- Ne pas introduire de nouveau systeme parallele a `ResolveCatalogReadiness`,
  `HomeReadiness` ou `AppLaunchOrchestrator`.
- Un snapshot exploitable doit rester prioritaire sur toute sync de fond.
- Un refresh bloquant doit avoir un timeout explicite et testable.
- Les erreurs source avant Home ne doivent pas etre converties en Home partiel.
- Les logs doivent aider a diagnostiquer la transition sans exposer de secrets
  source ni de messages utilisateur bruts.

## Etape 1 - Relecture cible du chemin catalogue actuel

### But

Verifier l'etat exact de la lecture snapshot, des refreshs IPTV et de la
decision Home avant modification.

### Nature

Documentation uniquement. Aucune modification de code applicatif attendue.

### Actions

- Relire `CatalogSnapshotReader`.
- Relire `ResolveCatalogReadiness`.
- Relire `HomeReadiness` et `CatalogMode`.
- Relire les appels a `RefreshXtreamCatalog`.
- Relire les appels a `RefreshStalkerCatalog`.
- Relire le chemin orchestrateur qui declenche la preparation Home.
- Identifier les controles actuels :
  - source active ;
  - source localement connue ;
  - snapshot present ;
  - snapshot exploitable ;
  - snapshot vide ;
  - snapshot indisponible ;
  - refresh necessaire ;
  - refresh reussi ;
  - refresh en erreur.

### Sortie attendue

Completer une table :

```text
condition | detection actuelle | decision actuelle | decision cible | fichier | risque
```

### Definition de fini

- Le chemin actuel `snapshot absent -> refresh -> Home` est documente.
- Les cas deja distinguables par le code sont identifies.
- Les cas melanges ou implicites sont listes avant implementation.

## Etape 2 - Contrat de readiness catalogue

### But

Figer les etats catalogue que l'orchestrateur peut consommer sans deviner.

### Nature

Documentation puis implementation si le contrat actuel ne couvre pas les cas
cibles. Cette etape peut modifier les contrats domaine et leurs tests.

### Actions

- Classer les etats cibles :
  - snapshot exploitable ;
  - snapshot absent ;
  - snapshot vide ;
  - snapshot indisponible ;
  - refresh requis ;
  - refresh timeout ;
  - provider error ;
  - credentials invalides ;
  - catalogue vide.
- Verifier si chaque etat existe deja dans `ResolveCatalogReadiness`,
  `HomeReadiness`, `CatalogMode` ou les reason codes.
- Ajouter uniquement les valeurs manquantes.
- Clarifier le sens de `catalogSnapshotCached` :
  - cache present ;
  - cache exploitable ;
  - Home autorisee sans refresh bloquant.
- Clarifier le sens de `catalogSnapshotMissing` :
  - pas de Home rapide ;
  - preparation catalogue visible ;
  - refresh bloquant mesure et borne.

### Sortie attendue

Completer une table :

```text
etat catalogue | contrat existant | ajout requis | reason code | destination | test
```

### Definition de fini

- Les etats catalogue critiques sont representes par un contrat stable.
- `cached` et `missing` ne peuvent plus etre confondus.
- Les erreurs source ont des sorties dediees avant Home.

## Etape 3 - Tests unitaires `ResolveCatalogReadiness`

### But

Verrouiller la decision catalogue independamment du router et de l'UI.

### Nature

Implementation tests attendue. Cette etape peut ajuster le resolver si les
tests revelent un ecart avec le contrat cible.

### Actions

- Ajouter ou completer les tests pour :
  - source active absente ;
  - snapshot present et exploitable ;
  - snapshot present mais vide ;
  - snapshot absent ;
  - snapshot indisponible ;
  - cache stale mais exploitable ;
  - refresh requis ;
  - catalogue vide apres refresh si le resolver en porte la responsabilite.
- Verifier que les fixtures representent des donnees metier plausibles.
- Nommer les tests avec l'intention produit :
  - Home rapide quand cache exploitable ;
  - preparation quand snapshot absent ;
  - recovery quand catalogue vide.

### Sortie attendue

Completer une table :

```text
test | scenario | entree | resultat attendu | raison metier | fichier
```

### Definition de fini

- Les decisions catalogue importantes echouent si le resolver regresse.
- Les tests encodent pourquoi Home est autorisee ou bloquee.
- Aucun test ne valide seulement une valeur technique sans intention.

## Etape 4 - Persistance du snapshot apres refresh reussi

### But

Garantir qu'un refresh reussi produit un snapshot exploitable pour le run
suivant.

### Nature

Implementation attendue si la persistance n'est pas deja garantie. Cette etape
peut modifier les use cases de refresh, repositories ou adaptateurs source.

### Actions

- Identifier ou le refresh reussi ecrit les donnees catalogue.
- Verifier que l'ecriture produit le meme format que
  `CatalogSnapshotReader` sait relire.
- Verifier que les listes essentielles sont presentes :
  - live ;
  - movies ;
  - series ;
  - metadata minimale si requise par Home.
- Verifier que les erreurs d'ecriture sont visibles dans le resultat du refresh
  ou dans les logs.
- Ajouter un test second run :
  - premier run sans snapshot ;
  - refresh reussi ;
  - snapshot persiste ;
  - second run `catalogSnapshotCached` ;
  - aucune attente longue.

### Sortie attendue

Completer une table :

```text
refresh | ecriture snapshot | lecture second run | failure possible | test
```

### Definition de fini

- Un refresh success ne se termine pas tant que le snapshot exploitable n'est
  pas persiste ou que l'echec n'est pas explicite.
- Le second run peut prouver que le cache est reutilise.
- Le chemin success ne depend pas seulement de donnees en memoire.

## Etape 5 - Timeout explicite du refresh bloquant

### But

Remplacer l'attente opaque par une attente bornee et diagnosable.

### Nature

Implementation attendue. Cette etape peut modifier l'orchestrateur ou le use
case qui execute le refresh bloquant.

### Actions

- Identifier le point exact ou le refresh bloque l'ouverture Home.
- Ajouter un timeout explicite a ce point, avec une duree nommee.
- Eviter les timeouts disperses dans les providers bas niveau sauf besoin
  technique deja existant.
- Mapper le timeout vers :
  - reason code `source_timeout` ou equivalent ;
  - recovery `La source ne repond pas` ;
  - action principale `Reessayer` ;
  - action secondaire `Changer de source` seulement apres delai ou si permise.
- Tester le timeout avec un fake controllable, pas avec une vraie attente.

### Sortie attendue

Completer une table :

```text
operation bloquante | timeout | reason code | recovery | action | test
```

### Definition de fini

- Le refresh bloquant ne peut plus attendre indefiniment ou de facon opaque.
- Le timeout produit une recovery source, pas Home partiel.
- Le test ne ralentit pas la suite automatisée.

## Etape 6 - Mapping des erreurs refresh vers recovery source

### But

Separer clairement les sorties provider, credentials et catalogue vide.

### Nature

Implementation attendue si les outcomes actuels sont trop generiques. Cette
etape peut modifier les mappers d'erreurs, outcomes refresh et tests
orchestrateur.

### Actions

- Mapper les sorties refresh :
  - success avec contenu ;
  - success mais catalogue vide ;
  - timeout ;
  - provider error ;
  - credentials invalides ;
  - erreur technique inconnue.
- Verifier les exceptions ou resultats Xtream.
- Verifier les exceptions ou resultats Stalker.
- Eviter de classer une source vide comme provider error.
- Eviter de classer des credentials invalides comme timeout.
- Definir le fallback uniquement pour les erreurs non classifiables.

### Sortie attendue

Completer une table :

```text
source | resultat brut | outcome catalogue | reason code | recovery | test
```

### Definition de fini

- `La source ne repond pas` correspond a un timeout.
- `Impossible de charger la source` correspond a une erreur provider.
- `Connexion a la source impossible` correspond a des credentials invalides.
- `Aucun contenu trouve` correspond a un catalogue vide.

## Etape 7 - Orchestration des chemins Home et recovery

### But

Faire appliquer les decisions catalogue par `AppLaunchOrchestrator` sans
navigation concurrente ni Home partiel abusif.

### Nature

Implementation attendue. Cette etape peut modifier l'orchestrateur, ses states,
les transitions et les tests associes.

### Actions

- Brancher les decisions catalogue :
  - snapshot exploitable -> Home rapide ;
  - snapshot absent -> `catalog_preparing` ;
  - refresh success -> Home ;
  - refresh timeout -> source recovery ;
  - provider error -> source recovery ;
  - credentials invalides -> source recovery ;
  - catalogue vide -> source recovery.
- Verifier que Home partiel reste reserve aux degradations apres ouverture Home.
- Verifier que les syncs de fond restent lancees sans bloquer Home quand le
  snapshot est exploitable.
- Verifier que les transitions mettent a jour `TunnelStateRegistry` si requis.
- Verifier que `LaunchRedirectGuard` applique les destinations sans refaire la
  decision catalogue.

### Sortie attendue

Completer une table :

```text
etat catalogue | phase orchestrateur | destination | Home autorisee | sync fond | test
```

### Definition de fini

- Le premier run sans snapshot affiche `catalog_preparing`.
- Le refresh reussi ouvre Home.
- Les erreurs source avant Home n'ouvrent pas Home partiel.
- Un snapshot exploitable autorise Home sans refresh bloquant.

## Etape 8 - Action secondaire prudente `Changer de source`

### But

Donner une sortie utilisateur utile sans encourager une navigation prematuree
pendant une preparation normale.

### Nature

Documentation puis implementation si le modele d'action est deja disponible.
Cette etape peut modifier le mapper `BootScreenModel`, `BootActionHandler` ou
les tests d'actions.

### Actions

- Definir quand `Changer de source` est disponible :
  - apres timeout ;
  - apres provider error ;
  - apres credentials invalides si plusieurs sources existent ;
  - apres catalogue vide ;
  - pas immediatement pendant une preparation normale sauf decision produit.
- Verifier la destination :
  - selection source existante ;
  - ajout source si aucune alternative ;
  - source settings si reconnecter est plus adapte.
- Verifier que l'action principale reste le choix le plus prudent :
  - `Reessayer` ;
  - `Reconnecter la source` ;
  - `Resynchroniser`.

### Sortie attendue

Completer une table :

```text
recovery | action principale | action secondaire | condition | destination | test
```

### Definition de fini

- `Changer de source` n'apparait pas pendant une attente normale non echouee.
- L'action est disponible quand elle aide reellement a sortir du blocage.
- Le handler cible est testable.

## Etape 9 - Logs de transition catalogue

### But

Rendre le chemin catalogue lisible pendant un run sans augmenter le bruit.

### Nature

Implementation attendue si les logs actuels ne permettent pas de diagnostiquer
les transitions. Cette etape peut modifier les logs orchestrateur/use case et
ajouter des tests ou snapshots de logs.

### Actions

- Ajouter ou normaliser les evenements :
  - `catalog_snapshot_checked` ;
  - `catalog_snapshot_cached` ;
  - `catalog_snapshot_missing` ;
  - `catalog_preparation_started` ;
  - `catalog_preparation_completed` ;
  - `catalog_preparation_failed`.
- Inclure les champs utiles :
  - run id ;
  - source id anonymisee ou log-safe ;
  - phase ;
  - reason code ;
  - duree ;
  - outcome ;
  - destination.
- Exclure les champs sensibles :
  - url complete ;
  - username ;
  - password ;
  - token ;
  - contenu brut provider.

### Sortie attendue

Completer une table :

```text
evenement | declencheur | champs | exemple log-safe | test
```

### Definition de fini

- Un run sans snapshot se lit dans les logs.
- Un second run cached se distingue clairement d'un refresh bloquant.
- Les erreurs source ont un reason code lisible et stable.

## Etape 10 - Tests orchestrateur et validation runtime

### But

Valider le comportement complet sur les chemins critiques de la phase.

### Nature

Implementation tests attendue, puis validation manuelle ciblee si possible.

### Actions

- Ajouter ou completer les tests orchestrateur pour :
  - refresh success ;
  - refresh timeout ;
  - provider error ;
  - credentials invalides ;
  - catalogue vide ;
  - snapshot cached ;
  - second run apres refresh success.
- Verifier les assertions critiques :
  - phase `catalog_preparing` visible ;
  - Home ouverte apres success ;
  - snapshot persiste ;
  - Home rapide au second run ;
  - recovery correcte par type d'erreur ;
  - aucune confusion avec Home partiel.
- Executer les tests cibles.
- Faire une validation runtime si les fakes ou donnees locales le permettent :
  - run sans snapshot ;
  - run avec snapshot ;
  - run timeout simule ;
  - run catalogue vide simule.

### Sortie attendue

Completer une table :

```text
scenario | test automatique | validation runtime | resultat | log attendu | risque restant
```

### Definition de fini

- Premier run sans snapshot affiche `catalog_preparing`.
- Refresh reussi ouvre Home et persiste le snapshot.
- Second run avec snapshot ouvre Home rapidement.
- Les erreurs source ne sont pas confondues avec Home partiel.

## Etape 11 - Synthese Phase 3

### But

Documenter les decisions prises et preparer les phases UI, logs et tests
globaux.

### Nature

Documentation uniquement, sauf mise a jour mineure de checklist.

### Actions

- Produire une synthese courte :
  - decisions catalogue stabilisees ;
  - contrats modifies ;
  - refresh bloquant borne ;
  - chemins recovery ajoutes ;
  - tests ajoutes ;
  - validations runtime faites ou impossibles ;
  - risques restants pour Phase 4 et Phase 7.
- Mettre a jour la checklist de definition de fini.

### Sortie attendue

Creer ou completer :

```text
docs/app_launch_refactor/phase_3_catalogue_source_recovery_et_home_readiness/DECISIONS.md
```

### Definition de fini

- La phase 4 peut brancher l'UI sur des etats catalogue stables.
- La phase 7 peut reprendre les scenarios critiques sans redecouvrir le
  comportement.
- Les incertitudes restantes sont explicites.

## Livrables de la phase

- `ROADMAP.md` : plan d'execution de la phase.
- `CATALOG_CURRENT_FLOW.md` : relecture cible du chemin catalogue actuel.
- `CATALOG_READINESS_CONTRACT.md` : etats catalogue et reason codes cibles.
- `RESOLVE_CATALOG_READINESS_TESTS.md` : plan ou bilan des tests resolver.
- `SNAPSHOT_PERSISTENCE.md` : verification de la persistance apres refresh.
- `BLOCKING_REFRESH_TIMEOUT.md` : timeout, duree, mapping recovery et tests.
- `REFRESH_ERROR_MAPPING.md` : table provider/timeout/credentials/empty.
- `ORCHESTRATOR_CATALOG_TRANSITIONS.md` : transitions catalogue dans le boot.
- `CATALOG_RECOVERY_ACTIONS.md` : actions principales et secondaires.
- `CATALOG_TRANSITION_LOGS.md` : evenements logs log-safe.
- `PHASE_3_TEST_COVERAGE.md` : tests orchestrateur et validation runtime.
- `DECISIONS.md` : synthese finale de la phase.
- Tests unitaires `ResolveCatalogReadiness`.
- Tests orchestrateur pour refresh success, timeout, provider, credentials et
  empty.

## Checklist Phase 3

- [x] Chemin catalogue actuel relu et documente.
- [x] Contrat de readiness catalogue stabilise.
- [x] Tests unitaires `ResolveCatalogReadiness` ajoutes ou mis a jour.
- [x] Persistance du snapshot apres refresh reussi verifiee.
- [x] Second run apres refresh success couvert.
- [x] Timeout explicite du refresh bloquant ajoute ou confirme.
- [x] Timeout mappe vers source recovery.
- [x] Provider error mappe vers source recovery.
- [x] Credentials invalides mappe vers source recovery.
- [x] Catalogue vide mappe vers source recovery.
- [x] `catalog_preparing` visible pendant le premier run sans snapshot.
- [x] Snapshot exploitable ouvre Home rapidement.
- [x] Syncs de fond conservees sans bloquer Home cached.
- [x] Action secondaire `Changer de source` conditionnee.
- [x] Logs de transition catalogue lisibles et log-safe.
- [x] Tests orchestrateur des chemins critiques ajoutes ou mis a jour.
- [x] Validation runtime faite ou impossibilite documentee.
- [x] Synthese Phase 3 produite.
