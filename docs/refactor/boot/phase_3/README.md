# Phase 3 - Revoir le contrat catalogue

## Contrat d'execution

Cette phase doit etre executee en appliquant strictement :

- `docs/codex_execution_contract.md` ;
- `docs/rules.md` ;
- `docs/run_logs_commands.md` uniquement si une reproduction runtime ou une
  capture de logs devient necessaire.

La phase 3 doit separer l'etat du catalogue local de la synchronisation reseau.
Le demarrage ne doit plus bloquer Home quand un snapshot catalogue local
exploitable existe deja.

## Objectif

Construire un contrat explicite pour repondre a deux questions distinctes :

```text
Le catalogue local permet-il d'ouvrir Home ?
Faut-il lancer une preparation source bloquante ou seulement un refresh
arriere-plan ?
```

Resultat attendu :

- si un snapshot local exploitable existe, ouvrir Home en mode `fresh`,
  `cached` ou `stale` ;
- si aucun snapshot local exploitable n'existe, lancer une preparation source
  bloquante ;
- si cette preparation echoue sans snapshot, router vers une recuperation source
  actionnable ;
- si Home s'ouvre depuis un snapshot, lancer le refresh catalogue en
  arriere-plan.

## Non-objectifs

Ne pas faire dans cette phase :

- modifier les routes publiques ;
- modifier les textes utilisateur ;
- traiter les erreurs feed Home ou bibliotheque ;
- supprimer `AppLaunchOrchestrator` ;
- remplacer toute la logique de preload Home ;
- creer les surfaces UI finales de recuperation source ;
- changer la strategie auth/profil/source extraite en phase 2.

Ces sujets appartiennent aux phases suivantes. La phase 3 doit uniquement
clarifier et brancher le contrat catalogue.

## Fichiers a inspecter avant modification

Avant toute modification de code, lire au minimum :

- `lib/src/core/startup/app_launch_orchestrator.dart`
- `lib/src/core/startup/domain/boot_contracts.dart`
- `lib/src/core/startup/domain/resolve_entry_decision.dart`
- `lib/src/core/startup/domain/startup_recovery_mapper.dart`
- `lib/src/core/storage/repositories/iptv_local_repository.dart`
- `lib/src/core/storage/repositories/iptv/iptv_playlist_query_store.dart`
- `lib/src/core/storage/repositories/iptv/iptv_playlist_store.dart`
- `lib/src/core/storage/repositories/iptv/iptv_storage_tables.dart`
- `lib/src/features/iptv/presentation/providers/iptv_providers.dart`
- `lib/src/features/home/presentation/providers/home_providers.dart`

Verifier aussi les tests existants :

```powershell
rg --files test | rg "startup|iptv|catalog|home"
```

## Etat actuel a corriger

Le lancement force actuellement `_ensureIptvCatalogReadyForLaunch()` avant Home.
Ce chemin :

- appelle `_ensureIptvCatalogReady(...)` avec timeout ;
- retry jusqu'a epuisement ;
- echoue en `iptvNetworkTimeout` si le refresh prend trop longtemps ;
- echoue en `iptvEmptyData` si aucun item n'est present apres refresh ;
- transforme donc certains cas recuperables en blocage de demarrage.

Le repository expose deja des lectures utiles :

- `getPlaylists(accountId, itemLimit: ...)` pour detecter les playlists ;
- `hasAnyPlaylistItems(accountIds: ...)` pour detecter les items ;
- les tables v2 `iptv_playlists_v2` et `iptv_playlist_items_v2`.

La phase 3 doit formaliser ces lectures en snapshot unique et eviter qu'un
refresh reseau soit le seul moyen de declarer Home ouvrable.

## Contrat catalogue cible

Ajouter un snapshot local explicite, par exemple dans le domaine startup :

```dart
final class CatalogSnapshot {
  const CatalogSnapshot({
    required this.sourceId,
    required this.exists,
    required this.hasPlaylists,
    required this.hasItems,
    required this.mode,
    this.age,
  });

  final String sourceId;
  final bool exists;
  final bool hasPlaylists;
  final bool hasItems;
  final CatalogMode mode;
  final Duration? age;

  bool get canOpenHome => mode.canOpenHome;
}
```

Le nom exact peut etre ajuste si un nom deja etabli est plus coherent. Le contrat
doit rester framework-agnostic si possible.

### Definition des modes

| Snapshot local | Mode | Home | Refresh |
| --- | --- | --- | --- |
| playlists + items presents, fraicheur OK | `fresh` | ouvrir | arriere-plan optionnel |
| playlists + items presents, fraicheur inconnue | `cached` | ouvrir | arriere-plan |
| playlists + items presents, age depasse | `stale` | ouvrir | arriere-plan prioritaire |
| aucune donnee locale exploitable | `missing` | preparation source | bloquant |
| sync terminee mais aucun contenu utile | `empty` | recuperation source | non bloquant ensuite |
| lecture impossible ou incoherente | `unavailable` | recuperation source ou erreur technique selon cause | non determine |

Invariant principal :

- `fresh`, `cached` et `stale` ouvrent Home ;
- `missing`, `empty` et `unavailable` n'ouvrent pas Home comme si le catalogue
  etait vide par choix utilisateur.

## Service recommande

Ajouter un service dedie, pur cote decision et adapte cote infrastructure :

```text
lib/src/core/startup/domain/catalog_snapshot_contracts.dart
lib/src/core/startup/domain/resolve_catalog_readiness.dart
lib/src/core/startup/catalog_snapshot_reader.dart
```

Alternative acceptable si le codebase prefere moins de fichiers :

```text
lib/src/core/startup/domain/catalog_readiness.dart
```

Roles :

- `CatalogSnapshot` : resultat de lecture locale ;
- `ResolveCatalogReadiness` : transforme le snapshot et le resultat de refresh
  en `HomeReadiness` ou en action de recuperation ;
- `CatalogSnapshotReader` : lit le repository local et construit le snapshot ;
- `AppLaunchOrchestrator` : adapte le legacy, lance le refresh bloquant
  uniquement si necessaire, puis traduit vers la destination existante.

## Regles de decision catalogue

Ordre attendu :

1. Lire le snapshot local de la source selectionnee.
2. Si `snapshot.canOpenHome`, produire un mode `fresh`, `cached` ou `stale`.
3. Dans ce cas, ne pas attendre le refresh reseau pour ouvrir Home.
4. Lancer le refresh catalogue en arriere-plan apres l'ouverture Home ou via le
   chemin background existant.
5. Si le snapshot est `missing`, lancer une preparation source bloquante.
6. Si la preparation reussit, relire le snapshot et ouvrir Home si exploitable.
7. Si la preparation echoue sans snapshot exploitable, produire
   `SourceRecoveryRequired`.
8. Si la preparation reussit mais ne produit aucun contenu utile, produire
   `SourceRecoveryRequired` avec `catalog_empty`.

Reason codes recommandes :

| Situation | Reason code | Actions |
| --- | --- | --- |
| Snapshot exploitable et frais | `catalog_snapshot_fresh` | `openHomeCached` |
| Snapshot exploitable, fraicheur inconnue | `catalog_snapshot_cached` | `openHomeCached`, `resyncSource` |
| Snapshot exploitable mais ancien | `catalog_snapshot_stale` | `openHomeCached`, `resyncSource` |
| Aucun snapshot exploitable | `catalog_snapshot_missing` | `resyncSource`, `chooseSource` |
| Refresh timeout sans snapshot | `catalog_sync_timeout` | `retry`, `chooseSource` |
| Provider IPTV en erreur sans snapshot | `catalog_provider_error` | `retry`, `chooseSource` |
| Credentials invalides | `catalog_credentials_invalid` | `reconnectSource` |
| Refresh OK mais catalogue vide | `catalog_empty` | `resyncSource`, `chooseSource` |
| Lecture locale impossible | `catalog_snapshot_unavailable` | `retry`, `exportLogs` |

## Roadmap phase 3

### Etape 1 - Audit cible sans modification

Objectif : confirmer les donnees locales disponibles et les points de blocage.

Actions :

- lire les fichiers listes dans "Fichiers a inspecter avant modification" ;
- lister les appels actuels a `_ensureIptvCatalogReadyForLaunch`,
  `_ensureIptvCatalogReady`, `getPlaylists` et `hasAnyPlaylistItems` ;
- confirmer comment identifier la source active et l'`accountId` local ;
- verifier si une information de fraicheur existe deja en storage ;
- lister les tests startup/IPTV/Home existants.

Livrable :

- aucune modification de code ;
- decision sur les fichiers a creer et sur la source de fraicheur disponible.

Verification :

- aucune commande Flutter obligatoire.

### Etape 2 - Ajouter le contrat `CatalogSnapshot`

Objectif : modeliser l'etat local du catalogue sans brancher le refresh.

Actions :

- creer le modele de snapshot local ;
- reutiliser `CatalogMode` existant ;
- documenter les invariants `canOpenHome` ;
- ne pas importer Flutter UI, Riverpod, repositories ou storage dans le contrat
  domaine ;
- prevoir `age` nullable si la fraicheur n'est pas encore disponible.

Livrable :

- contrat catalogue dans `lib/src/core/startup/domain/` ;
- aucun changement de navigation.

Verification :

```powershell
flutter analyze
```

Cette verification peut etre reportee a l'etape 4 si les tests sont ajoutes dans
la meme session.

### Etape 3 - Ajouter le lecteur de snapshot local

Objectif : centraliser la lecture locale du catalogue pour une source donnee.

Actions :

- creer un lecteur applicatif qui depend de `IptvLocalRepository` ;
- lire l'existence de playlists avec une requete peu couteuse ;
- lire l'existence d'items avec `hasAnyPlaylistItems(accountIds: {sourceId})` ou
  l'equivalent correct pour l'`accountId` local ;
- ne pas charger tout le catalogue au demarrage si une requete d'existence
  suffit ;
- mapper les resultats vers `CatalogSnapshot`.

Livrable :

- lecteur de snapshot testable avec fake repository ou fake store ;
- aucune modification du refresh reseau.

Verification :

- poursuivre vers les tests de l'etape 4 ;
- lancer `flutter analyze` si le lecteur est ajoute sans tests dans la meme
  session.

### Etape 4 - Couvrir le snapshot par tests unitaires

Objectif : verrouiller la definition de "catalogue exploitable".

Actions :

- tester snapshot avec playlists + items -> mode ouvrable ;
- tester playlists sans items -> mode non ouvrable ou `empty` selon contexte ;
- tester aucun snapshot -> `missing` ;
- tester lecture impossible -> `unavailable` ;
- tester snapshot ancien si la fraicheur est disponible ;
- tester que seuls `fresh`, `cached`, `stale` ouvrent Home.

Verification recommandee :

```powershell
flutter test test/core/startup/catalog_snapshot_test.dart
flutter analyze
```

Le nom exact du test peut changer selon les fichiers crees.

### Etape 5 - Extraire la decision de readiness catalogue

Objectif : decider si le demarrage doit ouvrir Home ou preparer la source.

Actions :

- creer un service pur du type `ResolveCatalogReadiness` ;
- entrer un `CatalogSnapshot` et, si necessaire, un resultat de refresh ;
- produire `HomeReady`, `HomePartial` ou `SourceRecoveryRequired` ;
- mapper les echecs refresh vers les `reasonCode` existants ;
- ne pas lancer le refresh dans le service pur ;
- ne pas logger dans le service pur.

Livrable :

- decision catalogue testable sans storage ni reseau ;
- reason codes stables et logs-safe.

Verification :

```powershell
flutter test test/core/startup/resolve_catalog_readiness_test.dart
flutter analyze
```

### Etape 6 - Brancher l'orchestrateur sans changer les routes publiques

Objectif : remplacer le blocage systematique par la strategie snapshot d'abord.

Actions :

- dans `AppLaunchOrchestrator`, lire le snapshot local apres resolution profil et
  source ;
- si le snapshot ouvre Home, ne pas appeler le refresh bloquant avant Home ;
- conserver les preloads Home existants autant que possible ;
- lancer le refresh catalogue en arriere-plan apres l'ouverture Home ;
- si le snapshot est absent, appeler le refresh bloquant existant ;
- apres refresh bloquant, relire le snapshot avant de declarer Home ouvrable ;
- si refresh echoue sans snapshot, router vers la recuperation source existante
  la plus proche ou conserver une erreur actionnable via le mapper ;
- ne pas changer les routes `auth`, `welcomeUser`, `welcomeSources`,
  `chooseSource`, `home`.

Livrable :

- Home peut s'ouvrir avec un catalogue local exploitable meme si le refresh
  reseau est lent ou echoue ;
- les cas sans snapshot restent proteges par une preparation source.

Verification :

```powershell
flutter test test/core/startup/resolve_entry_decision_test.dart
flutter test test/core/startup/app_launch_orchestrator_local_mode_test.dart
flutter analyze
```

Ajouter ou lancer les tests catalogue crees aux etapes precedentes.

### Etape 7 - Ajouter les tests de regression du lancement catalogue

Objectif : proteger les cas qui menaient au blocage generique.

Actions :

- tester snapshot local exploitable + refresh timeout -> destination `home` ;
- tester snapshot local exploitable + refresh provider error -> destination
  `home` ;
- tester snapshot absent + refresh OK -> destination `home` ;
- tester snapshot absent + refresh timeout -> recuperation source ou erreur
  actionnable ;
- tester snapshot absent + refresh vide -> recuperation source `catalog_empty` ;
- tester snapshot stale -> destination `home` avec refresh arriere-plan ;
- verifier que les erreurs feed/bibliotheque ne sont pas traitees dans cette
  phase.

Verification :

```powershell
flutter test test/core/startup/app_launch_orchestrator_local_mode_test.dart
flutter analyze
```

Si de nouveaux fichiers de tests sont crees, lancer aussi ces fichiers
explicitement.

### Etape 8 - Revue de fin de phase

Objectif : confirmer que la phase 3 peut preparer la phase 4 sans dette cachee.

Checklist :

- le snapshot catalogue local est explicite ;
- la presence de playlists et d'items est distinguee ;
- la fraicheur est representee ou documentee comme indisponible ;
- un refresh bloquant n'est lance que sans snapshot exploitable ;
- un echec refresh avec snapshot n'empeche pas Home ;
- un echec refresh sans snapshot mene a une recuperation source actionnable ;
- les logs utilisent des `reasonCode`, pas des IDs bruts ;
- les tests cibles passent ;
- `flutter analyze` passe.

Livrable :

- note finale avec fichiers modifies, commandes executees, resultats et risques
  restants, conformement a `docs/codex_execution_contract.md`.

## Tests attendus

Tests unitaires minimaux :

```text
test/core/startup/catalog_snapshot_test.dart
test/core/startup/resolve_catalog_readiness_test.dart
```

Tests d'integration ou existants a lancer si l'orchestrateur est modifie :

```powershell
rg --files test | rg "startup|iptv|catalog|home"
```

Puis lancer les tests pertinents trouves.

## Criteres d'acceptation

- Le demarrage lit explicitement le snapshot catalogue local.
- Le contrat distingue au minimum :
  - existence du snapshot ;
  - presence de playlists ;
  - presence d'items ;
  - age ou fraicheur, meme si la valeur est temporairement inconnue.
- Home s'ouvre si un snapshot local exploitable existe.
- Le refresh bloquant n'est lance que si aucun snapshot exploitable n'existe.
- Un refresh echoue sans snapshot mene a une recuperation source actionnable.
- Un refresh echoue avec snapshot n'affiche pas un blocage generique.
- Les destinations auth/profil/source de la phase 2 restent intactes.
- `flutter analyze` passe apres integration.

## Risques a surveiller

- Confondre "catalogue vide" et "snapshot absent" : un refresh termine avec
  zero contenu doit produire `catalog_empty`, pas `missing`.
- Lire trop de donnees au boot : preferer des requetes d'existence et des limites
  plutot que charger toutes les playlists.
- Utiliser un mauvais identifiant source/account : verifier la correspondance
  entre source selectionnee, compte local Xtream/Stalker et `accountId`.
- Ouvrir Home avec un snapshot qui contient des playlists sans items : Home peut
  paraitre vide alors qu'une recuperation source est necessaire.
- Masquer un probleme credentials en ouvrant Home stale sans signal : le refresh
  arriere-plan doit garder un reason code exploitable.

## Definition of done

La phase 3 est terminee quand :

1. le contrat `CatalogSnapshot` ou equivalent existe ;
2. la lecture locale du snapshot est centralisee ;
3. la readiness catalogue est testee ;
4. l'orchestrateur utilise la strategie snapshot d'abord ;
5. les cas avec snapshot ouvrent Home malgre un refresh echoue ;
6. les cas sans snapshot routent vers une recuperation source actionnable ;
7. les tests cibles passent ;
8. `flutter analyze` passe ;
9. une note de revue de fin de phase documente commandes, resultats et risques.

## Note de revue de fin de phase

Date de revue : 2026-04-28.

### Fichiers modifies

- `lib/src/core/startup/domain/boot_contracts.dart`
- `lib/src/core/startup/domain/catalog_snapshot_contracts.dart`
- `lib/src/core/startup/catalog_snapshot_reader.dart`
- `lib/src/core/startup/domain/resolve_catalog_readiness.dart`
- `lib/src/core/startup/domain/resolve_entry_decision.dart`
- `lib/src/core/startup/domain/startup_recovery_mapper.dart`
- `lib/src/core/startup/app_launch_orchestrator.dart`
- `test/core/startup/catalog_snapshot_test.dart`
- `test/core/startup/resolve_catalog_readiness_test.dart`
- `test/core/startup/resolve_entry_decision_test.dart`
- `test/core/startup/startup_recovery_mapper_test.dart`
- `test/core/startup/app_launch_orchestrator_local_mode_test.dart`

### Checklist phase 3

- Snapshot catalogue local explicite : oui, via `CatalogSnapshot`.
- Presence de playlists et d'items distinguee : oui, via `hasPlaylists` et
  `hasItems`.
- Fraicheur representee : oui, via `age`, nullable tant que le storage ne fournit
  pas une fraicheur fiable pour toutes les sources IPTV.
- Refresh bloquant limite aux snapshots non exploitables : oui, dans
  `AppLaunchOrchestrator`.
- Echec refresh avec snapshot : Home reste ouvrable et le refresh foreground
  n'est pas attendu.
- Echec refresh sans snapshot : routage vers la recuperation source existante
  avec reason code actionnable.
- Logs : les logs catalogue utilisent des `reasonCode` stables
  (`catalog_snapshot_*`, `catalog_sync_timeout`, `catalog_provider_error`,
  `catalog_empty`) et pas les IDs bruts.
- Routes publiques conservees : `auth`, `welcomeUser`, `welcomeSources`,
  `chooseSource`, `home`.
- Tests cibles : non valides dans cette session, voir "Commandes executees".
- `flutter analyze` : non valide dans cette session, voir "Commandes
  executees".

### Commandes executees

```powershell
rg --files test | rg "startup|iptv|catalog|home"
dart format lib/src/core/startup/domain/catalog_snapshot_contracts.dart lib/src/core/startup/catalog_snapshot_reader.dart
dart format lib/src/core/startup/app_launch_orchestrator.dart lib/src/core/startup/catalog_snapshot_reader.dart lib/src/core/startup/domain/catalog_snapshot_contracts.dart test/core/startup/app_launch_orchestrator_local_mode_test.dart
D:\SDK\flutter\bin\cache\dart-sdk\bin\dart.exe format lib/src/core/startup/app_launch_orchestrator.dart lib/src/core/startup/catalog_snapshot_reader.dart lib/src/core/startup/domain/catalog_snapshot_contracts.dart lib/src/core/startup/domain/resolve_catalog_readiness.dart test/core/startup/app_launch_orchestrator_local_mode_test.dart test/core/startup/resolve_catalog_readiness_test.dart
flutter test test/core/startup/app_launch_orchestrator_local_mode_test.dart --plain-name "opens home from an exploitable local catalog snapshot without foreground refresh"
flutter test test/core/startup/resolve_catalog_readiness_test.dart
flutter analyze --no-pub
D:\SDK\flutter\bin\cache\dart-sdk\bin\dart.exe analyze lib/src/core/startup test/core/startup
```

Resultats :

- la recherche de tests a confirme les tests startup/IPTV/Home disponibles ;
- le formatage a ete applique sur les fichiers cibles, mais `dart format` a
  retourne `exit 1` car Dart n'a pas pu mettre a jour
  `C:\Users\matte\AppData\Roaming\.dart-tool\dart-flutter-telemetry-session.json`
  (`OS Error: Acces refuse`) ;
- le test cible `app_launch_orchestrator_local_mode_test.dart` a expire sans
  sortie apres 600 secondes ;
- le test cible `resolve_catalog_readiness_test.dart` a expire sans sortie apres
  300 secondes ;
- `flutter analyze --no-pub` a ete interrompu apres blocage ;
- `dart analyze lib/src/core/startup test/core/startup` a echoue avec
  `CreateFile failed 5` / acces refuse au demarrage de `dartaotruntime.exe`.

Conclusion verification : non concluante dans cet environnement. Les tests et
`flutter analyze` doivent etre relances hors blocage SDK avant merge.

### Risques restants

- La phase est fonctionnellement cablee, mais la definition of done n'est pas
  totalement validee tant que les tests cibles et `flutter analyze` ne passent
  pas dans un environnement Dart/Flutter sain.
- `CatalogSnapshotReader` produit actuellement `cached`, `missing`, `empty` ou
  `unavailable`. Le mode `stale` est couvert dans le resolver pur, mais pas
  encore produit par le reader tant que la fraicheur storage n'est pas fiable.
- La recuperation source utilise la destination existante la plus proche
  (`welcomeSources`) avec reason code catalogue. Les surfaces UI finales de
  recuperation source restent hors perimetre de cette phase.
- Les commandes Dart/Flutter locales rencontrent des refus d'acces Windows sur
  la telemetry Dart ou `dartaotruntime.exe`, plus des timeouts sans sortie. Ce
  blocage empeche de certifier les tests dans cette session.
