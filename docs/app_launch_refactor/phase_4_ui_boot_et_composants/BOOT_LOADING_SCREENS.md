# Phase 4 - Etape 3 - Ecrans de chargement simples

## Objectif

Surfaces Flutter non interactives : logo **centre**, texte (et indicateur) **bas
d’ecran**, bandeau bas **hors flux** du logo (implementation `Stack` +
`Positioned`).

## Widget

| Fichier | Role |
|---------|------|
| `lib/src/core/startup/presentation/widgets/boot_simple_loading_screen.dart` | `BootSimpleLoadingScreen` : logo `MoviAssetIcon` + `AppAssets.iconAppLogoSvg`, texte bas, spinner optionnel |
| `lib/src/core/startup/presentation/widgets/boot_catalog_loading_screen.dart` | `BootCatalogLoadingScreen` (etape 4) : preparation catalogue, panneau bas distinct |
| `lib/src/core/widgets/overlay_splash.dart` | Delegue vers `BootSimpleLoadingScreen` (meme rendu qu’avant pour les usages hors boot) |

Factory `BootSimpleLoadingScreen.forBootModel` : **assert** en debug si le
modele est interactif ou si le `BootScreenType` n’est pas l’un de
`simpleLoading` ou `openingHome` (le catalogue utilise
`BootCatalogLoadingScreen`, etape 4).

## Table etat / reason / texte / widget

Les textes par defaut viennent du `BootScreenMapper` (`boot_screen_mapper.dart`),
sauf phase `preloadCompleteHome` sur `SplashBootstrapPage` ou les libelles
`AppLocalizations` (films, categories, ouverture Home) remplacent la ligne
principale affichee.

```text
etat (phase / destination) | reason code | texte (mapper ou l10n) | widget | logo centre | texte bas | test
demarrage technique (idle, init, startup) | technical_startup | Preparation du lancement | BootSimpleLoadingScreen | oui | oui | boot_simple_loading_screen_test
verification session (auth) | session_check | Verification de la session | idem | oui | oui | idem
verification profil (profiles) | profile_check | Verification du profil | idem | oui | oui | idem
verification source (sources, localAccounts, sourceSelection) | source_check | Verification de la source | idem | oui | oui | idem
preparation catalogue (preloadCompleteHome) | catalog_preparing | l10n selon `HomeBootstrapProgressStage` (+ sous-texte cache si pret) | BootCatalogLoadingScreen | oui | oui | boot_catalog_loading_screen_test
ouverture Home (done / success home) | opening_home / home_ready | Ouverture de l'accueil (+ l10n si etape catalogue) | idem | oui | oui | idem
```

Aucun bouton sur ces etats. Les reason codes ne sont **pas** affiches dans l’UI.

## Integration

- `SplashBootstrapPage` consomme `bootScreenModelProvider` et affiche
  `BootCatalogLoadingScreen` pour `catalogLoading`, sinon
  `BootSimpleLoadingScreen.forBootModel` pour `simpleLoading` et `openingHome` ;
  fallback `BootSimpleLoadingScreen` sans factory pour les autres types.

## Responsive (validation cible)

| Format | Reference | Statut |
|--------|-----------|--------|
| Mobile | 393 x 852 | A valider manuellement (padding horizontal 20 sur le bloc bas) |
| Desktop | largeur contrainte | A valider manuellement |

## Tests widget

`test/core/startup/boot_simple_loading_screen_test.dart` : logo present,
message visible, aucun bouton material courant.

`test/core/startup/boot_catalog_loading_screen_test.dart` : surface catalogue,
sous-message optionnel, pas de boutons.
