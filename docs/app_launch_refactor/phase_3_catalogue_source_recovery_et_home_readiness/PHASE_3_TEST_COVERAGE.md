# Phase 3 - Etape 10 - Couverture tests et validation runtime

## Objectif

Valider les chemins critiques catalogue de bout en bout dans l'orchestrateur :
preparation visible, refresh borne, recovery source typee, Home rapide avec
snapshot exploitable, et second run sans blocage long.

## Matrice de validation

```text
scenario | test automatique | validation runtime | resultat | log attendu | risque restant
refresh success sans snapshot | opens home when blocking refresh creates the missing local snapshot | fake local SQLite + fake refresh | Home ouverte, snapshot persiste, homeController appele | catalog_preparation_started, catalog_preparation_completed, catalog_snapshot_cached | valide le contrat orchestrateur-reader, pas un provider distant reel
second run apres refresh success | opens home when blocking refresh creates the missing local snapshot | meme fake, second run avec refresh configure en erreur | Home ouverte sans nouvel appel refresh | catalog_snapshot_cached | ne mesure pas un temps UI reel, mais prouve l'absence de refresh bloquant
catalog_preparing visible | exposes catalog preparing while first run waits for missing snapshot refresh | fake refresh bloque par Completer | phase preloadCompleteHome running, BootScreenModel catalog_preparing, tunnel preloadingHome | catalog_preparation_started | pas de capture visuelle UI, seulement modele boot/tunnel
refresh timeout provider-result | routes to source recovery when no snapshot exists and refresh times out | fake refresh Err(TimeoutFailure) | welcomeSources, aucun Home partial | catalog_sync_timeout | couvre failure typed, pas socket reel
refresh timeout Future.timeout | routes to source recovery when blocking refresh exceeds its timeout | fake refresh suspendu + timeout test reduit | welcomeSources sous 1s, aucun Home partial | catalog_preparation_failed, catalog_sync_timeout | duree production non attendue en test
provider error Xtream | routes to source recovery when no snapshot exists and provider refresh fails | fake refresh Err(UnknownFailure) | welcomeSources, Home non chargee | catalog_provider_error | provider reel non interroge
credentials invalides Xtream | routes to credentials recovery when Xtream refresh reports invalid credentials | fake AuthFailure | welcomeSources, action reconnecter source | catalog_credentials_invalid | credentials reels non manipules en test
credentials invalides avec alternative | offers change source after credentials recovery when another source exists | deux sources locales + AuthFailure | action secondaire Changer de source | catalog_credentials_invalid | condition locale seulement, pas remote alternatives
provider error Stalker | routes to source recovery when Stalker refresh fails | fake Stalker Err(UnknownFailure) | welcomeSources, Home non chargee | catalog_provider_error, refresh_stalker failure | provider reel non interroge
catalogue vide | routes to source recovery when refresh leaves catalog empty | fake refresh success sans playlist item | welcomeSources, Home non chargee | catalog_empty | contenu distant reel non verifie
snapshot cached | opens home from a local catalog snapshot even if foreground refresh would fail | snapshot local exploitable + refresh en erreur | Home ouverte, refresh bloquant non appele | catalog_snapshot_cached | freshness fine non couverte par reader actuel
snapshot cached + timeout potentiel | opens home from a local catalog snapshot even if foreground refresh would time out | snapshot local exploitable + fake refresh suspendu | Home ouverte sans attendre le fake | catalog_snapshot_cached | pas de mesure UI, mais blocage evite par compteur refresh
Home partial apres snapshot exploitable | opens Home partially when Home preload reports feed error / IPTV sections empty / library timeout | snapshot local exploitable + degradations Home | destination Home avec notice Home partial | home_* ou library_* sans catalog_empty/provider | utile pour verifier la non-confusion source recovery/Home partial
resolver catalogue | resolve_catalog_readiness_test.dart | tests unitaires purs | reason codes et actions catalogue verrouilles | n/a | pas de routing, complete par tests orchestrateur
actions boot recovery | boot_screen_mapper_test.dart + boot_action_handler_test.dart | tests purs presentation/planner | actions principales/secondaires et destinations stables | n/a | execution concrete UI/router non testee ici
```

## Validation runtime

Validation runtime manuelle non executee dans cette etape : elle demanderait une
source IPTV reelle ou des donnees locales d'application existantes, avec risque
de dependance a des credentials et a un provider externe.

La validation ciblee possible dans ce contexte est couverte par les fakes
orchestrateur :

- SQLite local reel en memoire ;
- repositories locaux reels ;
- refresh Xtream/Stalker controlables ;
- timeout reduit et deterministe ;
- lecture du `BootScreenModel` et du `TunnelStateRegistry`.

Cette validation suffit pour la phase 3 car l'objectif est le contrat
orchestrateur/catalogue avant branchement UI complet. La validation manuelle
avec source reelle reste a reprendre en phase 7 ou sur environnement de recette.

## Commandes executees

```text
flutter test test/core/startup/resolve_catalog_readiness_test.dart test/core/startup/startup_recovery_mapper_test.dart test/core/startup/boot_screen_mapper_test.dart test/core/startup/boot_action_handler_test.dart test/core/startup/app_launch_orchestrator_local_mode_test.dart
flutter analyze lib/src/core/startup/app_launch_orchestrator.dart lib/src/core/startup/domain/resolve_catalog_readiness.dart lib/src/core/startup/domain/startup_recovery_mapper.dart lib/src/core/startup/presentation/boot_screen_mapper.dart test/core/startup/resolve_catalog_readiness_test.dart test/core/startup/startup_recovery_mapper_test.dart test/core/startup/boot_screen_mapper_test.dart test/core/startup/boot_action_handler_test.dart test/core/startup/app_launch_orchestrator_local_mode_test.dart
```

## Definition de fini de l'etape 10

- [x] Premier run sans snapshot affiche `catalog_preparing`.
- [x] Refresh reussi ouvre Home et persiste le snapshot.
- [x] Second run avec snapshot ouvre Home rapidement.
- [x] Les erreurs source ne sont pas confondues avec Home partiel.
- [x] La validation runtime manuelle non executee est documentee avec raison.
