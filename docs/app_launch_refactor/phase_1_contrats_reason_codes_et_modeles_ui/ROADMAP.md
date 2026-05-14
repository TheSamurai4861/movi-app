# Phase 1 - Contrats, reason codes et modeles UI

## Objectif

Transformer les decisions de boot en contrat stable entre orchestration,
routage et UI.

Cette phase doit partir des contrats existants inventories en phase 0. Elle ne
doit pas creer un second systeme parallele : les nouveaux modeles doivent
adapter, completer ou projeter les contrats actuels.

## Regles de travail

- Conserver les contrats existants quand ils sont suffisants.
- Ajouter les etats manquants au plus pres de leur responsabilite.
- Garder les reason codes dans les logs et les tests, jamais dans les textes
  utilisateur.
- Separer les decisions metier du modele d'affichage.
- Ne pas commencer le remplacement complet des widgets legacy dans cette phase.
- Tester le mapping avant de brancher les nouveaux ecrans Figma.

## Etape 1 - Relecture cible des contrats existants

### But

Verifier quels contrats peuvent etre reutilises tels quels avant toute
modification.

### Actions

- Relire les fichiers de `lib/src/core/startup/domain`.
- Relire `AppLaunchState`, `AppLaunchPhase`, `AppLaunchRecovery` et
  `AppLaunchCriteria`.
- Relire `StartupRecoveryReasonCodes`.
- Relire les resolvers :
  - `ResolveEntryDecision` ;
  - `ResolveCatalogReadiness` ;
  - `ResolveHomeDegradation`.
- Marquer chaque concept comme :
  - reutilisable tel quel ;
  - a etendre ;
  - a projeter vers UI ;
  - a ne pas dupliquer.

### Sortie attendue

Completer une table :

```text
concept | decision | justification | fichier cible | test concerne
```

### Definition de fini

- Les contrats a conserver sont identifies.
- Les contrats a modifier sont limites au strict necessaire.
- Aucun doublon de concept n'est introduit dans le plan.

## Etape 2 - Normalisation des etats cibles

### But

Transformer la liste d'etats cibles en vocabulaire stable et testable.

### Actions

- Reprendre les etats minimaux :
  - `technical_startup` ;
  - `session_check` ;
  - `auth_required` ;
  - `profile_check` ;
  - `profile_required` ;
  - `profile_selection_required` ;
  - `source_check` ;
  - `source_required` ;
  - `source_selection_required` ;
  - `catalog_preparing` ;
  - `catalog_cached_ready` ;
  - `catalog_snapshot_missing` ;
  - `source_timeout` ;
  - `provider_error` ;
  - `credentials_invalid` ;
  - `catalog_empty` ;
  - `technical_failure` ;
  - `opening_home` ;
  - `home_ready` ;
  - `home_sections_failed` ;
  - `library_failed` ;
  - `iptv_sections_empty` ;
  - `multiple_degradations`.
- Decider pour chaque etat s'il appartient a :
  - une phase runtime ;
  - un reason code ;
  - un type d'ecran UI ;
  - une degradation Home ;
  - une destination router.
- Identifier les etats qui doivent rester internes.
- Identifier les etats visibles utilisateur.

### Sortie attendue

Completer une table :

```text
etat cible | categorie | visible utilisateur | contrat existant | ajout requis
```

### Definition de fini

- Tous les etats cibles ont une categorie.
- Les etats internes et les etats UI sont separes.
- Les etats Home partiel ne sont pas melanges avec la recovery source avant
  Home.

## Etape 3 - Decision `cached/stale`

### But

Figer le comportement produit et technique des snapshots exploitables.

### Actions

- Documenter la decision pour `catalogSnapshotCached`.
- Documenter la decision pour `catalogSnapshotStale`.
- Confirmer qu'un snapshot exploitable ouvre Home rapidement.
- Definir si l'UI affiche seulement `opening_home` ou aussi un warning discret.
- Confirmer que `cached/stale` ne doit pas etre traite comme une erreur source.
- Identifier les logs attendus pour ces cas.

### Sortie attendue

Creer ou completer :

```text
docs/app_launch_refactor/phase_1_contrats_reason_codes_et_modeles_ui/CATALOG_CACHE_DECISION.md
```

### Definition de fini

- La decision `cached/stale` est explicite.
- Home rapide reste l'invariant principal.
- Les erreurs source restent reservees aux snapshots non exploitables ou aux
  refreshs en echec.

## Etape 4 - Ajout ou projection de la preparation catalogue

### But

Rendre visible et testable l'etat actuellement cache dans
`preloadCompleteHome`.

### Actions

- Decider si `catalogPreparing` doit etre :
  - une nouvelle valeur de `AppLaunchPhase` ;
  - un sous-etat derive dans le modele UI ;
  - les deux.
- Identifier le point exact dans `AppLaunchOrchestrator` ou l'etat commence.
- Identifier le point exact ou l'etat se termine.
- Associer les reason codes :
  - `catalogSnapshotMissing` ou equivalent ;
  - `catalogPreparing` ou equivalent ;
  - timeout/provider/credentials/empty en sortie failure.
- Verifier que les logs n'exposent pas de texte utilisateur.

### Sortie attendue

Completer une table :

```text
transition | signal code | phase/runtime | reason code | ecran UI | destination
```

### Definition de fini

- La preparation catalogue n'est plus implicite.
- Le premier run sans snapshot peut afficher un etat dedie.
- Le second run avec snapshot peut eviter cet etat bloquant.

## Etape 5 - Verification `credentials_invalid`

### But

S'assurer que l'etat `credentials_invalid` peut etre emis depuis les erreurs
IPTV reelles.

### Actions

- Lire les resultats de `RefreshXtreamCatalog`.
- Lire les resultats de `RefreshStalkerCatalog`.
- Identifier ou `CatalogRefreshOutcome.credentialsInvalid` est produit ou
  pourrait etre produit.
- Identifier les exceptions provider qui correspondent a des identifiants
  invalides.
- Decider si le mapping doit etre ajoute au provider, au refresh use case ou a
  l'orchestrateur.
- Ajouter les tests attendus a la liste Phase 1 si l'emission manque.

### Sortie attendue

Completer une table :

```text
provider | erreur detectee | outcome actuel | outcome cible | changement requis | test
```

### Definition de fini

- Le chemin credentials invalid est documente.
- L'emplacement du changement est identifie.
- Le reason code cible ne depend pas d'une erreur generique.

## Etape 6 - Definition de `BootScreenModel`

### But

Definir le contrat d'affichage qui relie l'etat de boot aux ecrans Figma.

### Actions

- Definir les champs du modele :
  - type d'ecran ;
  - titre utilisateur ;
  - message ;
  - sous-message optionnel ;
  - action principale optionnelle ;
  - action secondaire optionnelle ;
  - destination router optionnelle ;
  - reason code log-safe ;
  - indicateur d'interaction ;
  - indicateur focus initial.
- Definir les types d'ecran minimaux :
  - loading simple ;
  - loading catalogue ;
  - action requise ;
  - recovery ;
  - opening Home ;
  - Home partial notice ;
  - technical failure.
- Definir les actions boot minimales :
  - retry ;
  - login ;
  - createProfile ;
  - chooseProfile ;
  - addSource ;
  - chooseSource ;
  - reconnectSource ;
  - resyncSource ;
  - openHome ;
  - exportLogs si conserve.
- Decider si le modele vit dans `core/startup/presentation` ou dans un module
  startup/domain avec projection UI separee.

### Sortie attendue

Completer une table :

```text
champ | type | obligatoire | source | usage UI | test
```

### Definition de fini

- Le modele UI est assez stable pour implementer les ecrans Figma.
- Les actions sont des intentions techniques, pas des callbacks ad hoc.
- Les reason codes restent log-safe et non affiches.

## Etape 7 - Mapping reason code vers modele UI

### But

Construire la table centrale du contrat entre runtime et UI.

### Actions

- Mapper chaque reason code ou etat technique vers :
  - un `BootScreenModel` ;
  - une action principale ;
  - une action secondaire optionnelle ;
  - une destination router ;
  - un niveau de severite ou type d'ecran.
- Couvrir les cas nominaux :
  - startup technique ;
  - verification session ;
  - verification profil ;
  - verification source ;
  - preparation catalogue ;
  - ouverture Home.
- Couvrir les cas action requise :
  - auth ;
  - profil requis ;
  - selection profil ;
  - source requise ;
  - selection source.
- Couvrir les recoveries :
  - timeout source ;
  - provider error ;
  - credentials invalides ;
  - catalogue vide ;
  - technical failure.
- Couvrir Home partiel :
  - sections Home failed ;
  - library failed ;
  - IPTV sections empty ;
  - multiple degradations.

### Sortie attendue

Creer ou completer :

```text
docs/app_launch_refactor/phase_1_contrats_reason_codes_et_modeles_ui/BOOT_SCREEN_MAPPING.md
```

Avec une table :

```text
etat/reason code | screen type | titre | message | action principale | action secondaire | destination | notes
```

### Definition de fini

- Chaque etat cible minimal est mappe.
- Aucun etat utilisateur important ne tombe sur un message generique.
- Les actions Figma ont une intention technique stable.

## Etape 8 - Tests unitaires du mapping

### But

Verrouiller le contrat avant les changements de routage et d'UI.

### Actions

- Ajouter ou preparer les tests pour :
  - `BootScreenModel` ;
  - le mapper etat/reason code vers UI ;
  - `cached/stale` ;
  - preparation catalogue ;
  - credentials invalid ;
  - Home partiel.
- Verifier que chaque action principale attendue est presente.
- Verifier que les textes utilisateur ne contiennent pas de reason code brut.
- Verifier que les etats non interactifs n'ont pas d'action focusable.
- Verifier que les etats actionnables declarent une action principale.

### Sortie attendue

Completer une table :

```text
test | comportement couvert | contrat teste | donnees d'entree | assertion critique
```

### Definition de fini

- Le mapping est couvert par des tests unitaires.
- Les tests echouent si un etat cible n'a pas de modele UI.
- Les reason codes internes ne peuvent pas fuiter dans les textes UI.

## Etape 9 - Integration minimale au runtime

### But

Preparer le branchement du modele sans remplacer encore toutes les surfaces UI.

### Actions

- Identifier le provider qui exposera le `BootScreenModel`.
- Decider s'il observe directement `AppLaunchState` ou une projection
  intermediaire.
- Verifier l'interaction avec `TunnelStateRegistry`.
- Verifier l'interaction avec `LaunchRedirectGuard`.
- Definir le fallback temporaire vers les widgets legacy.
- Documenter les limites de cette integration pour la phase 2.

### Sortie attendue

Completer une table :

```text
source runtime | projection | provider expose | consommateur actuel | consommateur cible | fallback
```

### Definition de fini

- Le point de branchement UI est connu.
- La phase 2 peut raccorder orchestration/routage sans redecouvrir les contrats.
- Le fallback legacy est explicite pendant la migration.

## Etape 10 - Synthese Phase 1

### But

Transformer les decisions de contrats en plan d'implementation pour les phases
2, 3 et 4.

### Actions

- Produire une synthese courte :
  - contrats conserves ;
  - contrats modifies ;
  - nouveaux modeles ;
  - reason codes ajoutes ou clarifies ;
  - etats UI couverts ;
  - etats encore bloques ;
  - tests a ajouter avant integration.
- Mettre a jour la checklist de definition de fini.

### Sortie attendue

Creer ou completer :

```text
docs/app_launch_refactor/phase_1_contrats_reason_codes_et_modeles_ui/DECISIONS.md
```

### Definition de fini

- La table `reason code -> screen model -> actions -> destination` existe.
- La decision `cached/stale` est documentee.
- Les changements requis avant phase 2 sont identifies.
- La phase 2 peut demarrer sans nouvelle exploration large des contrats.

## Livrables de la phase

- `ROADMAP.md` : plan d'execution de la phase.
- `CONTRACTS_REVIEW.md` : relecture cible des contrats existants.
- `TARGET_STATES.md` : normalisation des etats cibles.
- `CATALOG_CACHE_DECISION.md` : decision produit/technique sur cached/stale.
- `CATALOG_PREPARING_DECISION.md` : decision sur l'etat preparation catalogue.
- `CREDENTIALS_INVALID_VERIFICATION.md` : verification de l'emission
  credentials invalid.
- `BOOT_SCREEN_MODEL.md` : contrat d'affichage boot vers ecrans Figma.
- `BOOT_SCREEN_MAPPING.md` : table reason code/etat vers modele UI.
- `MAPPING_TEST_PLAN.md` : plan des tests unitaires du modele et du mapper.
- `RUNTIME_INTEGRATION.md` : point de branchement runtime et fallback legacy.
- `DECISIONS.md` : synthese finale de la phase.
- Tests unitaires du mapping, si la phase passe a l'implementation.

## Checklist de fin de phase

- [x] Contrats existants classes conserver/etendre/projeter.
- [x] Etats cibles normalises.
- [x] Decision `cached/stale` documentee.
- [x] Preparation catalogue explicitee.
- [x] Emission `credentials_invalid` verifiee.
- [x] `BootScreenModel` defini.
- [x] Actions boot stables definies.
- [x] Mapping reason code vers UI documente.
- [x] Tests unitaires du mapping listes ou ajoutes.
- [x] Point de branchement runtime identifie.
- [x] Synthese Phase 1 produite.
