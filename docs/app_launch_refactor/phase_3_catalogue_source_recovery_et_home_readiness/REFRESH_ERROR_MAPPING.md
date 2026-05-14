# Phase 3 - Etape 6 - Mapping des erreurs refresh

## Objectif

Separer clairement les sorties provider, credentials et catalogue vide.

Cette etape stabilise le mapping entre les erreurs brutes des refreshs IPTV et
les recoveries source avant Home.

## Table de mapping

```text
source | resultat brut | outcome catalogue | reason code | recovery | test
Xtream | TimeoutFailure, ConnectionFailure, BadCertificateFailure | CatalogRefreshOutcome.timedOut | catalog_sync_timeout | La source ne repond pas | routes to source recovery when no snapshot exists and refresh times out
Xtream | timeout Future.timeout autour du refresh bloquant | CatalogRefreshOutcome.timedOut | catalog_sync_timeout | La source ne repond pas | routes to source recovery when blocking refresh exceeds its timeout
Xtream | UnknownFailure, CancelledFailure, failure provider non classifiee | CatalogRefreshOutcome.providerError | catalog_provider_error | Impossible de charger la source | routes to source recovery when no snapshot exists and provider refresh fails
Xtream | AuthFailure, MissingCredentialsFailure, UnauthorizedFailure | CatalogRefreshOutcome.credentialsInvalid | catalog_credentials_invalid | Connexion a la source impossible | routes to credentials recovery when Xtream refresh reports invalid credentials
Xtream | XtreamRouteExecutionFailure authInvalidCredentials | CatalogRefreshOutcome.credentialsInvalid | catalog_credentials_invalid | Connexion a la source impossible | couvert par mapping code, pas par test dedie dans cette etape
Xtream | XtreamRouteExecutionFailure DNS/TCP/TLS/HTTP timeout/route blocked | CatalogRefreshOutcome.timedOut | catalog_sync_timeout | La source ne repond pas | couvert par mapping code, tests timeout existants
Xtream | refresh success mais aucun item local apres relecture | CatalogRefreshOutcome.empty | catalog_empty | Aucun contenu trouve | routes to source recovery when refresh leaves catalog empty
Stalker | Err(UnknownFailure) ou failure provider non classifiee | CatalogRefreshOutcome.providerError | catalog_provider_error | Impossible de charger la source | routes to source recovery when Stalker refresh fails
Stalker | Err(AuthFailure), MissingCredentialsFailure, UnauthorizedFailure | CatalogRefreshOutcome.credentialsInvalid | catalog_credentials_invalid | Connexion a la source impossible | couvert par mapping commun, test Xtream dedie
Stalker | refresh success mais aucun item local apres relecture | CatalogRefreshOutcome.empty | catalog_empty | Aucun contenu trouve | couvert par chemin commun empty
```

## Changements de code

### `AppLaunchErrorCode`

Ajout de :

```text
iptvCredentialsInvalid
```

Mapping :

```text
AppLaunchErrorCode.iptvCredentialsInvalid
-> CatalogRefreshOutcome.credentialsInvalid
-> catalog_credentials_invalid
```

### `_mapIptvFailureToLaunchStep`

Le mapper classe maintenant :

- `AuthFailure` ;
- `MissingCredentialsFailure` ;
- `UnauthorizedFailure` ;
- `XtreamRouteExecutionFailure.authInvalidCredentials`.

Ces erreurs produisent `iptvCredentialsInvalid` au lieu de tomber dans
`iptvProviderError`.

### Refresh Stalker

Le chemin Stalker propage maintenant les `Err` comme le chemin Xtream :

```text
Err(failure) -> _mapIptvFailureToLaunchStep(...) -> _LaunchStepException
```

Avant cette etape, l'erreur Stalker etait seulement loggee en debug dans le
bloc `fold`, puis `refreshed=true` pouvait etre pose malgre l'echec.

## Decisions explicites

- Timeout reseau et timeout du refresh bloquant restent `catalog_sync_timeout`.
- Credentials invalides ne sont plus classes comme provider error.
- Provider error reste le fallback pour les failures non classifiables.
- Catalogue vide reste decide apres relecture locale : un refresh techniquement
  success ne suffit pas si aucun item exploitable n'est persiste.
- Les erreurs source avant Home restent des `SourceRecoveryRequired`, jamais des
  degradations Home partielles.

## Risques restants

- Les credentials invalides sont encore retries par la politique generique de
  `_runWithRetry`. Cette etape stabilise le reason code final, mais ne change
  pas la strategie de retry.
- Le mapping `ForbiddenFailure` reste provider error. Un 403 peut representer
  plusieurs situations : credentials invalides, IP bloquee ou provider refuse.
  Le mapping plus fin doit venir du provider ou de `XtreamRouteExecutionFailure`.
- Les tests dedies couvrent Xtream credentials et Stalker provider. Les chemins
  Stalker credentials reutilisent le mapper commun mais n'ont pas encore un test
  dedie.

## Definition de fini de l'etape 6

- [x] `La source ne repond pas` correspond a un timeout.
- [x] `Impossible de charger la source` correspond a une erreur provider.
- [x] `Connexion a la source impossible` correspond a des credentials invalides.
- [x] `Aucun contenu trouve` correspond a un catalogue vide.
