# Verification credentials_invalid

## Synthese

Le contrat existe deja, mais l'emission runtime n'est pas encore complete.

Existant confirme :

- `CatalogRefreshOutcome.credentialsInvalid` existe.
- `ResolveCatalogReadiness` mappe cet outcome vers
  `StartupRecoveryReasonCodes.catalogCredentialsInvalid`.
- L'action associee est `RecoveryAction.reconnectSource`.
- `StartupRecoveryMapper.mapHomeFailure` sait deja mapper
  `catalog_credentials_invalid`.

Manque observe :

- `AppLaunchErrorCode` ne contient pas de valeur credentials invalid.
- `_catalogRefreshOutcomeForLaunchError` ne peut donc pas retourner
  `CatalogRefreshOutcome.credentialsInvalid`.
- `_mapIptvFailureToLaunchStep` mappe les erreurs Xtream
  `authInvalidCredentials` vers `iptvProviderError`.
- Les erreurs Stalker de handshake/profile/token sont des `AuthFailure`, mais le
  refresh Stalker les avale ou les ignore dans le chemin boot actuel.

Conclusion : le reason code cible ne doit pas dependre de l'erreur generique
`provider_error`. Le mapping doit etre ajoute dans l'orchestrateur, avec un
petit ajustement des chemins provider si necessaire.

## Table de verification

| provider | erreur detectee | outcome actuel | outcome cible | changement requis | test |
| --- | --- | --- | --- | --- | --- |
| Xtream | `XtreamRouteExecutionFailure(errorKind: authInvalidCredentials)`, code `xtream_auth_invalid_credentials`, produit par `IptvRepositoryImpl._refreshAccountAuthInfo` quand `remote.authenticate` retourne non autorise. | `_mapIptvFailureToLaunchStep` retourne `AppLaunchErrorCode.iptvProviderError`, puis `_catalogRefreshOutcomeForLaunchError` retourne `CatalogRefreshOutcome.providerError`. | `CatalogRefreshOutcome.credentialsInvalid`, puis `catalog_credentials_invalid`, action `reconnectSource`. | Ajouter `AppLaunchErrorCode.iptvCredentialsInvalid`; mapper `SourceProbeErrorKind.authInvalidCredentials` vers ce code; mapper ce code vers `CatalogRefreshOutcome.credentialsInvalid`. | `app_launch_orchestrator_credentials_invalid_test.dart` : refresh Xtream `XtreamRouteExecutionFailure(authInvalidCredentials)` sans snapshot redirige recovery source avec log `catalog_credentials_invalid` et action reconnect dans le futur mapper UI. |
| Xtream | `AuthFailure` direct ou `MissingCredentialsFailure` depuis le repository/vault. | `AuthFailure` est transforme en `XtreamRouteExecutionFailure(authInvalidCredentials)` par `XtreamRouteExecutionService`; `MissingCredentialsFailure` tombe aujourd'hui dans fallback provider si non mappe. | `CatalogRefreshOutcome.credentialsInvalid`. | Mapper aussi `AuthFailure` et `MissingCredentialsFailure` vers `AppLaunchErrorCode.iptvCredentialsInvalid` dans `_mapIptvFailureToLaunchStep`, en plus du cas route execution. | Test unitaire orchestrateur avec `Err(AuthFailure(...))` ou `Err(MissingCredentialsFailure(...))` si les fakes le permettent. |
| Xtream | HTTP `401` / `UnauthorizedFailure` pendant une route catalogue. | `XtreamRouteExecutionService` mappe en `SourceProbeErrorKind.httpDenied`; `_shouldTryNext` peut essayer d'autres routes; si echec final, boot voit provider/network selon mapping actuel. | Rester `provider_error` sauf preuve que l'API Xtream utilise 401 pour identifiants invalides dans ce contexte. | Ne pas mapper automatiquement `httpDenied` vers credentials invalid pour eviter les faux positifs proxy/provider. | Test non prioritaire : `httpDenied` reste provider/network selon decision route. |
| Stalker | Handshake retourne `isAuthorized=false` ou token vide, `StalkerRepositoryImpl.addSource` leve `AuthFailure`. | Hors refresh boot d'ajout source, deja distingue a l'ajout; pas de `CatalogRefreshOutcome`. | Pour boot refresh, `AuthFailure` doit devenir `credentialsInvalid`. | Si `refreshCatalog` rencontre `AuthFailure`, le use case le retourne deja en `Err`; l'orchestrateur doit mapper `AuthFailure` vers `iptvCredentialsInvalid`. | `app_launch_orchestrator_stalker_credentials_invalid_test.dart` avec fake refresh Stalker `Err(AuthFailure(...))`. |
| Stalker | `_refreshAccountAuthInfo` detecte handshake/profile non autorise. | Le code met parfois le compte en erreur, mais ne throw pas quand handshake non autorise; les exceptions sont catch puis log debug. Le refresh continue avec l'ancien token et peut finir en provider error ou catalogue vide. | `CatalogRefreshOutcome.credentialsInvalid` quand l'auth refresh prouve que la MAC/token/session est invalide. | Dans `StalkerRepositoryImpl._refreshAccountAuthInfo`, lever `AuthFailure` quand handshake/profile non autorise ou token absent pendant refresh, au moins pour le chemin de refresh bloquant boot. | Test repository/use case Stalker : auth non autorisee retourne `Err(AuthFailure)`; test orchestrateur : outcome `credentialsInvalid`. |
| Stalker | Token absent dans `_refreshCatalogLowResources` ou `_fetchRemoteData`. | `AuthFailure('No token available...')` peut remonter si non avale. | `CatalogRefreshOutcome.credentialsInvalid`. | Mapper `AuthFailure` vers `iptvCredentialsInvalid` dans l'orchestrateur. | Test orchestrateur Stalker avec `Err(AuthFailure('No token...'))`. |
| Stalker | Categories/content retournent response vide/detail auth. | Souvent parse comme listes vides, puis catalogue vide. | `catalog_empty` si le provider repond mais ne fournit aucun contenu; `credentialsInvalid` seulement si auth invalide est explicite. | Ne pas deduire credentials invalid depuis contenu vide seul. | Test `catalog_empty` conserve action `resyncSource` + `chooseSource`. |

## Emplacement du changement

### Changement principal

Ajouter le mapping dans `AppLaunchOrchestrator` :

```text
AppLaunchErrorCode.iptvCredentialsInvalid
  -> CatalogRefreshOutcome.credentialsInvalid
  -> StartupRecoveryReasonCodes.catalogCredentialsInvalid
  -> RecoveryAction.reconnectSource
```

Points precis :

- ajouter `iptvCredentialsInvalid` a `AppLaunchErrorCode` ;
- dans `_mapIptvFailureToLaunchStep` :
  - `XtreamRouteExecutionFailure(errorKind: authInvalidCredentials)` ->
    `iptvCredentialsInvalid` ;
  - `AuthFailure` -> `iptvCredentialsInvalid` ;
  - `MissingCredentialsFailure` -> `iptvCredentialsInvalid` ;
- dans `_catalogRefreshOutcomeForLaunchError` :
  - `iptvCredentialsInvalid` -> `CatalogRefreshOutcome.credentialsInvalid`.

### Changement provider/repository a prevoir

Stalker doit cesser d'aplatir les erreurs auth pendant le refresh bloquant.

Point a corriger :

- `StalkerRepositoryImpl._refreshAccountAuthInfo` catch actuellement les erreurs
  et logge seulement en debug ;
- si handshake/profile prouve une auth invalide, le refresh doit retourner un
  `AuthFailure` au lieu de continuer jusqu'a provider error/catalogue vide.

Ce changement peut rester dans le repository Stalker ou dans une variante
dediee au refresh bloquant, mais il ne doit pas etre fait dans l'UI.

## Ce qu'il ne faut pas faire

- Ne pas mapper toutes les erreurs HTTP 401/403 en credentials invalid : elles
  peuvent venir du proxy, d'un blocage IP ou d'une route provider.
- Ne pas afficher le message `AuthFailure.message` tel quel a l'utilisateur.
- Ne pas creer un nouveau reason code parallele a
  `catalog_credentials_invalid`.
- Ne pas deduire credentials invalid d'un catalogue simplement vide.

## Tests attendus

| test | comportement couvert | assertion critique |
| --- | --- | --- |
| `app_launch_orchestrator_credentials_invalid_test.dart` | Refresh Xtream renvoie `XtreamRouteExecutionFailure(authInvalidCredentials)` sans snapshot local. | Destination recovery source, log `catalog_credentials_invalid`, pas `catalog_provider_error`. |
| `app_launch_orchestrator_missing_credentials_test.dart` | Refresh Xtream renvoie `MissingCredentialsFailure`. | Outcome `credentialsInvalid`, action cible `reconnectSource`. |
| `app_launch_orchestrator_stalker_credentials_invalid_test.dart` | Refresh Stalker renvoie `AuthFailure`. | Outcome `credentialsInvalid`, pas `catalog_empty`. |
| `stalker_repository_refresh_auth_failure_test.dart` | Handshake/profile Stalker non autorise pendant refresh. | Le use case retourne `Err(AuthFailure)` au lieu de continuer silencieusement. |
| `boot_ui_state_mapper_test.dart` | Reason code `catalog_credentials_invalid`. | Ecran recovery credentials, action principale `reconnectSource`, reason code non affiche. |

## Definition de fini - etape 5

- Le chemin credentials invalid est documente.
- L'emplacement du changement est identifie.
- Le reason code cible ne depend pas d'une erreur generique.
