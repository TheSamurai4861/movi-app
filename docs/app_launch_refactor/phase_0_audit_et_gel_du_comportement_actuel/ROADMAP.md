# Phase 0 - Audit et gel du comportement actuel

## Objectif

Stabiliser le point de depart avant toute modification structurante du boot.

Cette phase ne doit pas modifier le comportement applicatif. Elle sert a
cartographier l'existant, identifier les doublons, figer les comportements a
preserver et preparer les phases de refactor suivantes.

## Regles de travail

- Ne pas modifier la logique de boot pendant cette phase.
- Ne pas supprimer de route, widget ou test.
- Produire des documents factuels, bases sur le code et les tests existants.
- Distinguer ce qui est observe dans le code de ce qui est une hypothese.
- Garder les reason codes internes dans la documentation technique, pas dans les
  textes utilisateur.

## Etape 1 - Inventaire des points d'entree

### But

Comprendre comment l'application entre dans le tunnel de boot.

### Actions

- Lire `lib/main.dart`.
- Lire `lib/src/app.dart`.
- Identifier le premier widget applicatif affiche.
- Identifier le provider ou controller qui lance le boot.
- Identifier les feature flags qui influencent le boot.

### Sortie attendue

Completer une table :

```text
point d'entree | fichier | responsabilite | dependances boot | notes
```

### Definition de fini

- Le chemin depuis `main` jusqu'au premier ecran de boot est documente.
- Les flags qui changent le comportement de lancement sont listes.

## Etape 2 - Cartographie du routage boot

### But

Identifier toutes les routes impliquees dans le lancement et qui decide de les
atteindre.

### Actions

- Lire le catalogue de routes.
- Lire `LaunchRedirectGuard`.
- Rechercher les usages des destinations :
  - `launch` ;
  - `auth` ;
  - `welcomeUser` ;
  - `welcomeSources` ;
  - `welcomeSourceSelect` ;
  - `welcomeSourceLoading` ;
  - `home`.
- Pour chaque route, identifier :
  - le widget affiche ;
  - le guard eventuel ;
  - le declencheur ;
  - la condition d'entree ;
  - la condition de sortie.

### Sortie attendue

Completer une table :

```text
route | widget | declencheur | condition d'entree | condition de sortie | source de decision
```

### Definition de fini

- Toutes les routes boot sont reliees a un widget.
- Les navigations directes depuis les widgets sont identifiees.
- Les decisions prises par le router sont distinguees des decisions prises par
  l'orchestrateur.

## Etape 3 - Cartographie de l'orchestration

### But

Comprendre l'etat actuel de `AppLaunchOrchestrator` et ses transitions.

### Actions

- Lire `AppLaunchOrchestrator`.
- Identifier les phases `AppLaunchPhase`.
- Identifier les transitions autorisees.
- Identifier les criteres `AppLaunchCriteria`.
- Identifier les points ou `AppLaunchState` est mis a jour.
- Identifier les points ou `TunnelStateRegistry` est mis a jour.
- Identifier les logs emis pendant le boot.
- Identifier les chemins success/failure.

### Sortie attendue

Completer une table :

```text
phase | entree | operation | sortie success | sortie failure | reason code/log | destination
```

### Definition de fini

- Les phases actuelles sont documentees.
- Les transitions implicites et explicites sont separees.
- Les etats qui n'ont pas encore de phase dediee sont listes.

## Etape 4 - Cartographie des contrats boot

### But

Savoir quels concepts existent deja avant d'ajouter ou modifier des modeles.

### Actions

- Lire les fichiers de contrats dans `lib/src/core/startup/domain`.
- Cartographier :
  - `BootContracts` ;
  - `EntryDecision` ;
  - `HomeReadiness` ;
  - `CatalogMode` ;
  - `StartupRecoveryReasonCodes` ;
  - `AppLaunchState` ;
  - `AppLaunchPhase` ;
  - `AppLaunchRecovery`.
- Identifier les correspondances entre contrats.
- Identifier les doublons de sens.
- Identifier les trous par rapport a la spec Figma.

### Sortie attendue

Completer une table :

```text
concept | fichier | role | valeurs actuelles | equivalent Figma | manque identifie
```

### Definition de fini

- Les contrats reutilisables sont marques comme tels.
- Les concepts a etendre sont identifies.
- Les concepts a ne pas dupliquer sont identifies.

## Etape 5 - Cartographie catalogue et source

### But

Documenter le chemin critique observe dans le run Windows : snapshot absent,
refresh IPTV bloquant, puis Home.

### Actions

- Lire `CatalogSnapshotReader`.
- Lire `ResolveCatalogReadiness`.
- Lire les appels a `RefreshXtreamCatalog`.
- Lire les appels a `RefreshStalkerCatalog`.
- Lire `_ensureIptvCatalogReady`.
- Identifier les controles :
  - source active ;
  - source connue localement ;
  - snapshot present ;
  - playlists presentes ;
  - refresh necessaire ;
  - refresh reussi ;
  - refresh timeout ;
  - refresh provider error ;
  - catalogue vide.
- Verifier ou le snapshot est persiste apres refresh.

### Sortie attendue

Completer une table :

```text
condition catalogue | detection actuelle | action actuelle | log actuel | etat cible probable | risque
```

### Definition de fini

- Le chemin `catalog_snapshot_missing -> refresh -> cached -> home` est
  documente.
- Les erreurs source distinguables sont listees.
- Les points ou l'UI reste opaque sont identifies.

## Etape 6 - Cartographie des widgets legacy

### But

Identifier les surfaces UI actuelles qui affichent le boot ou ses erreurs.

### Actions

- Lire :
  - `SplashBootstrapPage` ;
  - `WelcomeSourcePage` ;
  - `WelcomeSourceSelectPage` ;
  - `WelcomeSourceLoadingPage` ;
  - `LaunchErrorPanel` ;
  - `LaunchRecoveryBanner` ;
  - `OverlaySplash`.
- Pour chaque widget, identifier :
  - son role ;
  - les providers lus ;
  - les actions utilisateur ;
  - les routes appelees ;
  - les messages affiches ;
  - les focus nodes ;
  - la logique metier embarquee.

### Sortie attendue

Completer une table :

```text
widget | role actuel | providers/controllers | actions | routes | messages | logique a garder | logique a extraire
```

### Definition de fini

- Les widgets a conserver, adapter ou remplacer sont classes.
- Les messages generiques a supprimer sont listes.
- Les duplications logique UI/orchestrateur sont identifiees.

## Etape 7 - Cartographie des composants UI reutilisables

### But

Eviter de recreer des composants deja presents.

### Actions

- Lire :
  - `MoviPrimaryButton` ;
  - `AppLabeledTextField` ;
  - `ProfileAvatarChip` ;
  - `MoviAssetIcon` ;
  - `AppAssets` ;
  - composants focus utiles.
- Comparer avec les JSON Figma :
  - `button-structure.json` ;
  - `text-input-structure.json` ;
  - `profile-avatar-structure.json` ;
  - ecrans de chargement ;
  - ecrans recovery.
- Identifier les adaptations necessaires.

### Sortie attendue

Completer une table :

```text
besoin Figma | composant existant | ecart | action recommandee
```

### Definition de fini

- Les composants reutilisables sont confirmes.
- Les variantes a creer sont listees.
- Le logo asset reel est identifie.

## Etape 8 - Inventaire des tests existants

### But

Connaitre la couverture avant refactor.

### Actions

- Lister les tests dans :
  - `test/core/startup` ;
  - `test/core/router` ;
  - `test/features/welcome` ;
  - tests auth/profil/source lies au lancement ;
  - tests Home partial/recovery.
- Pour chaque test, identifier :
  - le comportement couvert ;
  - le contrat teste ;
  - les mocks/fakes utilises ;
  - les trous de couverture.

### Sortie attendue

Completer une table :

```text
test | fichier | comportement couvert | type | dependances | trou restant
```

### Definition de fini

- Les tests a conserver sont identifies.
- Les tests a adapter apres refactor sont listes.
- Les nouveaux tests necessaires sont proposes.

## Etape 9 - Comportements a preserver

### But

Figer les invariants fonctionnels avant modification.

### Actions

- Documenter les comportements a preserver :
  - ouverture Home rapide avec snapshot exploitable ;
  - redirection auth si session requise ;
  - creation ou selection profil ;
  - ajout ou selection source ;
  - refresh source quand aucun snapshot exploitable n'existe ;
  - Home partiel pour erreurs non critiques ;
  - logs de boot exploitables ;
  - focus TV sur action principale.
- Pour chaque comportement, associer :
  - un signal code ;
  - un test existant ou futur ;
  - un risque de regression.

### Sortie attendue

Completer une table :

```text
comportement | signal actuel | test existant | test manquant | risque
```

### Definition de fini

- Les invariants sont explicites.
- Les risques de regression sont connus.
- Les phases suivantes peuvent changer le code avec un filet de securite.

## Etape 10 - Synthese Phase 0

### But

Transformer l'audit en plan d'action pour les phases suivantes.

### Actions

- Produire une synthese courte :
  - etats deja couverts ;
  - etats partiellement couverts ;
  - etats manquants ;
  - doublons ;
  - widgets a remplacer ;
  - widgets a conserver ;
  - tests a renforcer.
- Mettre a jour la checklist de definition de fini.

### Sortie attendue

Creer ou completer :

```text
docs/app_launch_refactor/phase_0_audit_et_gel_du_comportement_actuel/AUDIT.md
```

### Definition de fini

- Les chemins existants sont connus.
- Les fichiers a modifier sont identifies.
- Les comportements a ne pas casser sont explicites.
- La phase 1 peut demarrer sans nouvelle exploration large.

## Livrables de la phase

- `ROADMAP.md` : plan d'execution de la phase.
- `AUDIT.md` : resultats factuels de l'audit.
- `boot_routes.md` : table routes/widgets/decisions si le contenu devient trop
  volumineux pour `AUDIT.md`.
- `legacy_widgets.md` : cartographie detaillee des widgets legacy si necessaire.
- `existing_tests.md` : inventaire des tests si necessaire.

## Checklist de fin de phase

- [x] Points d'entree documentes.
- [x] Routes boot documentees.
- [x] Orchestration actuelle documentee.
- [x] Contrats boot existants documentes.
- [x] Chemin catalogue/source documente.
- [x] Widgets legacy documentes.
- [x] Composants UI reutilisables documentes.
- [x] Tests existants inventories.
- [x] Comportements a preserver figes.
- [x] Doublons et messages generiques listes.
- [x] Fichiers candidats au refactor listes.
