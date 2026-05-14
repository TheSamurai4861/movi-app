# Responsive, TV / focus et accessibilite (boot)

Reference mobile **393 x 852** (Figma Phase 4). Les surfaces concernees sont
celles du tunnel bootstrap : chargements (`BootSimpleLoadingScreen`,
`BootCatalogLoadingScreen`), recovery (`BootRecoveryPanel` via
`SplashBootstrapPage`), plus `FocusRegionScope` pour l’entree de focus.

## Principes appliques

- **Textes** : `maxLines` + `TextOverflow.ellipsis` sur messages longs
  (chargements bas, panneau recovery) pour eviter debordement horizontal /
  empilement infini.
- **Largeur recovery** : `LayoutBuilder` + `min(400, largeur parent)` pour
  colonnes etroites / fenetre desktop etroite sans depasser le viewport.
- **Focus clavier / TV** : `FocusTraversalGroup` + `OrderedTraversalPolicy` +
  `NumericFocusOrder` (1 = primaire, 2 = secondaire) sur `BootRecoveryPanel`.
- **Splash** : `SplashBootstrapPage` garde `FocusRegionScope` avec
  `resolvePrimaryEntryNode` vers l’action recovery ou le noeud chargement.

## Table surface / mobile / desktop / TV / problemes / corrections / tests

```text
surface | mobile 393x852 | desktop etroit | TV/focus | probleme | correction | test
BootSimpleLoadingScreen | OK texte bas wrap/ellipsis | OK | N/A (non interactif) | Texte tres long | maxLines + ellipsis bandeau bas | boot_simple_loading_screen_test
BootCatalogLoadingScreen | OK panneau bas | OK | N/A | Secondaire long | maxLines + ellipsis | boot_catalog_loading_screen_test
BootRecoveryPanel | OK scroll parent + largeur adaptee | maxWidth min(viewport,400) | Tab : primaire puis secondaire | Ordre focus implicite seul | FocusTraversalOrder explicite | boot_recovery_panel_test
SplashBootstrapPage | Scroll vertical recovery | idem | Entree region sur primaire ou chargement | — | Deja en place | tests integration existants / manuel
HomeErrorBanner | Etape 8 (compact <600) | Row large | Boutons focusables | — | Etape 8 | home_error_banner_test
```

## Limites / manuel recommande

- **D-pad / telecommande** : valider sur device ou emulateur TV reel ; les
  tests widget couvrent Tab clavier, pas la telecommande physique.
- **Echelle de texte systeme** : pas de plafond impose sur le bootstrap (respect
  des reglages utilisateur) ; les ellipses limitent le debordement.
- **Lisibilite a distance** : verifier manuellement tailles `headlineSmall` /
  `bodyLarge` recovery sur grand ecran.

## Definition de fini (etape 9)

- Aucun bouton critique recovery inaccessible au **Tab** (primaire puis
  secondaire) dans les tests.
- Textes longs ne provoquent pas d’exception de layout sur **393x852**.
- Focus initial coherent : deja pilote par `BootScreenModel.initialFocus` et
  `FocusRegionScope` sur la page splash.

**Statut :** corrections code + tests cibles + cette fiche.
