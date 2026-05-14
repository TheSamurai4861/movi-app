# Banniere Home partiel

Surface **non bloquante** en tete du scroll Home (`HomeErrorBanner`) lorsque
`homeDegradationNoticeProvider` expose un `HomeDegradationNotice` ou lorsque
`HomeState.error` est non nul sans notice (message generique swipe-to-retry).

Les degradations sont resolues cote domaine par `ResolveHomeDegradation` et
`StartupRecoveryReasonCodes` ; la banniere ne doit **pas** afficher de reason
code brut.

## Separation avec recovery source avant Home

- `SourceRecoveryRequired` et `CatalogPreparationRequired` declenchent
  `_clearHomeDegradationNotice()` dans `AppLaunchOrchestrator` (`_logHomeReadiness`).
- Les erreurs feed / IPTV vides / preload bibliotheque apres Home alimentent
  `HomePartial` puis `homeDegradationNoticeProvider` (preload Home / merge
  preload bibliotheque).

## Actions (`handleHomeDegradationAction`)

| Action | Comportement |
| --- | --- |
| `retryHomeSections` | `HomeController.refresh` (`homeDegradationRetry`) |
| `retryLibrary` | `invalidate(homeInProgressProvider)` |
| `resyncSource` | `libraryCloudSyncController.syncNow` puis refresh Home + invalidate in-progress |
| Autre | `refresh` (fallback) |

Chaque branche se termine par un `return` explicite (pas de fall-through).

## Table degradation / message / action / layout

Les messages et libelles boutons sont dans `lib/l10n/app_*.arb` (cles
`homePartialBanner*` et `homePartialAction*`).

```text
degradation (reasonCode logique) | message (cle l10n) | actions | mobile | desktop | test
home_feed_failed | homePartialBannerFeedFailed | retryHomeSections | Colonne compacte : icone + texte, boutons Wrap dense | Row : texte Expanded, boutons a droite | home_error_banner_test.dart
library_preload_timeout / library_preload_failed | homePartialBannerLibraryUnavailable | retryLibrary | idem | idem | library-only degradation shows library message
home_iptv_sections_empty | homePartialBannerIptvEmpty | retryHomeSections + resyncSource | idem | idem | keeps banner actions focusable
home_partial ou plusieurs reasonCodes | homePartialBannerMultiple | selon notice | idem | idem | prioritizes Home sections when multiple actions exist
fallback inconnu | homePartialBannerGeneric | selon notice | idem | idem | -
erreur sans notice | homeErrorSwipeToRetry | aucun bouton (onAction null) | idem | idem | -
```

## Fichiers

- `lib/src/features/home/presentation/widgets/home_error_banner.dart`
- `lib/src/features/home/presentation/providers/home_providers.dart` (`HomeDegradationNotice`)
- `lib/src/core/startup/domain/resolve_home_degradation.dart`
- `test/features/home/presentation/widgets/home_error_banner_test.dart`

## Seuil responsive

Largeur `< 600` : padding reduit, `VisualDensity.compact` sur les boutons,
empilement `Column` + `Wrap` pour les actions.
