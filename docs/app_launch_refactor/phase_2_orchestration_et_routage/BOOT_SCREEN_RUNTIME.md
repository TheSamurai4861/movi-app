# Branchement minimal du BootScreenModel

## Decision

Le point d'exposition runtime du modele UI est :

```text
bootScreenModelProvider
```

Emplacement :

```text
lib/src/core/startup/presentation/boot_screen_providers.dart
```

Ce provider observe `appLaunchStateProvider` et projette son etat via
`BootScreenMapper`.

Le branchement est volontairement minimal :

- pas de renderer Flutter branche ;
- pas de navigation ;
- pas de log ;
- pas de refresh ;
- pas de suppression des widgets legacy.

## Fichiers ajoutes

| fichier | role |
| --- | --- |
| `lib/src/core/startup/presentation/boot_screen_model.dart` | Contrat d'affichage `BootScreenModel`, types d'ecran, focus, severity. |
| `lib/src/core/startup/presentation/boot_screen_mapper.dart` | Projection pure `AppLaunchState -> BootScreenModel`. |
| `lib/src/core/startup/presentation/boot_screen_providers.dart` | Providers `bootScreenMapperProvider` et `bootScreenModelProvider`. |
| `test/core/startup/boot_screen_mapper_test.dart` | Tests du mapping runtime -> UI. |
| `test/core/startup/boot_screen_providers_test.dart` | Test du provider avec override de `appLaunchStateProvider`. |

## Table d'integration

| source | projection | provider | consommateur temporaire | consommateur cible | fallback |
| --- | --- | --- | --- | --- | --- |
| `appLaunchStateProvider` | `BootScreenMapper.fromLaunchState(AppLaunchState)` | `bootScreenModelProvider` | Aucun widget branche pour l'instant. `_LaunchGate` et `SplashBootstrapPage` restent legacy. | Renderer boot Phase 4 sur `/launch` puis `/bootstrap`. | Tant qu'aucun consommateur n'est branche, le fallback est le comportement legacy existant. |
| `AppLaunchStatus.idle` | `simpleLoading`, reason `technical_startup`. | `bootScreenModelProvider` | `OverlaySplash` legacy. | `BootLoadingScreen`. | `_LaunchGate` existant. |
| `AppLaunchStatus.running` + phase auth/profiles/sources | `simpleLoading`, reason `session_check`, `profile_check` ou `source_check`. | `bootScreenModelProvider` | Pages/loader legacy. | Chargement simple Figma. | Routes auth/welcome existantes. |
| `AppLaunchStatus.running` + `preloadCompleteHome` | `catalogLoading`, reason `catalog_preparing`. | `bootScreenModelProvider` | `SplashBootstrapPage` / `WelcomeSourceLoadingPage`. | Ecran catalogue Figma. | Fallback legacy tant que `catalogPreparing` runtime n'est pas extrait. |
| `success + destination=auth` | `actionRequired`, action `login`. | `bootScreenModelProvider` | `AuthPasswordPage` / `AuthOtpPage`. | Ecran action auth ou page auth wrapper. | Route `/auth/otp`. |
| `success + destination=welcomeUser` | `actionRequired`, action `createProfile`. | `bootScreenModelProvider` | `WelcomeUserPage`. | Ecran profil Figma. | Route `/welcome/user`. |
| `success + destination=welcomeSources` | `actionRequired`, action `addSource` ou `resyncSource`. | `bootScreenModelProvider` | `WelcomeSourcePage`. | Ecran source/recovery Figma. | Route `/welcome/sources`. |
| `success + destination=chooseSource` | `actionRequired`, action `chooseSource`. | `bootScreenModelProvider` | `WelcomeSourceSelectPage`. | Ecran selection source Figma. | Route `/welcome/sources/select`. |
| `success + destination=home` | `openingHome`, destination Home. | `bootScreenModelProvider` | Guard ouvre Home. | Ecran bref `openingHome`. | Route `/`. |
| `failure` | `technicalFailure`, actions `retry` + `exportLogs`. | `bootScreenModelProvider` | `/bootstrap` + `LaunchErrorPanel` selon cas. | Ecran failure Figma. | `SplashBootstrapPage` / `LaunchErrorPanel`. |

## Interaction avec LaunchRedirectGuard

`bootScreenModelProvider` ne remplace pas `LaunchRedirectGuard`.

Regles :

- le provider expose un modele d'affichage ;
- le guard reste responsable d'appliquer les routes ;
- `BootScreenModel.destination` est une information de presentation/action, pas
  une decision router prioritaire ;
- le provider ne lit pas `GoRouter`, `BuildContext`, storage, reseau ou
  controllers.

## Limites pour la Phase 4

- Les textes sont encore des libelles contractuels, pas des cles l10n finales.
- Le renderer `BootScreenModel -> Widget` n'est pas implemente.
- Les widgets legacy ne consomment pas encore le provider.
- `catalog_preparing` est derive de `preloadCompleteHome`; la phase runtime
  dediee reste a extraire en Phase 3.
- Home partiel apres Home demandera une projection plus fine depuis
  `HomeReadiness` ou la notice Home existante.

## Definition de fini - etape 4

- Le point d'exposition runtime du modele UI est connu :
  `bootScreenModelProvider`.
- Le fallback legacy est explicite : aucun consommateur n'est branche tant que
  le renderer Phase 4 n'existe pas.
- La Phase 4 pourra consommer le meme provider sans redefinir les contrats.
