# Phase 4 - Etape 4 - Chargement catalogue enrichi

## Objectif

Presenter `catalog_preparing` comme une **attente normale** : surface dediee,
textes courts et non techniques, **aucun** bouton (pas de « Changer de source »
pendant la preparation). Quand le cache catalogue est deja pret cote critere
(`AppLaunchCriteria.hasIptvCatalogReady`), un **sous-message rassurant**
indique que les donnees locales sont disponibles — sans le presenter comme une
erreur source.

## Widget

| Fichier | Role |
|---------|------|
| `lib/src/core/startup/presentation/widgets/boot_catalog_loading_screen.dart` | `BootCatalogLoadingScreen` : logo centre, panneau bas arrondi (`surfaceContainerHighest`), indicateur + ligne principale + sous-message optionnel |
| `lib/src/core/startup/presentation/widgets/boot_simple_loading_screen.dart` | `BootLoadingElapsedLabel` partage (ligne avec duree · Ns) |

## Table etat catalogue | modele | widget | action visible | focus | test

```text
catalog_preparing (running, preloadCompleteHome) | BootScreenType.catalogLoading, reason catalog_preparing, isInteractive false | BootCatalogLoadingScreen | aucune | none / focus neutre splash | boot_catalog_loading_screen_test, boot_screen_mapper_test
cache IPTV pret (criteria.hasIptvCatalogReady) | idem + metadata catalogCacheReady true | idem + l10n bootCatalogLocalCacheReady en sous-texte | aucune | idem | idem
```

Les **reason codes** et logs ne sont pas affiches dans l’UI.

## Integration

- `SplashBootstrapPage` : si `bootModel.screenType == catalogLoading`, rend
  `BootCatalogLoadingScreen` avec `message` = ligne principale (l10n selon
  `HomeBootstrapProgressStage` en phase preload) et `secondaryMessage` =
  `l10n.bootCatalogLocalCacheReady` lorsque `launchState.criteria.hasIptvCatalogReady`.
- `BootScreenMapper` : metadata `catalogCacheReady` alignee sur
  `state.criteria.hasIptvCatalogReady` pour la phase catalogue.

## i18n

Cle `bootCatalogLocalCacheReady` dans les fichiers `app_*.arb`.

## Definition de fini (roadmap)

- [x] Surface Flutter dediee pour la preparation catalogue.
- [x] Aucun bouton pendant l’attente normale.
- [x] Etat cache presente comme information positive, pas comme erreur.
