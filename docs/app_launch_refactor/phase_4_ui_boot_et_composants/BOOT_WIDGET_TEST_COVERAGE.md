# Couverture tests widget boot (Phase 4 etape 10)

Objectif : verrouiller les **ecrans critiques** du tunnel bootstrap avec des
assertions explicites (logo reel, absence de CTA sur chargements, actions
recovery, pas de `reasonCode` brut visible, focus primaire quand applicable).

Les **snapshots / goldens** ne sont pas integres ici : a introduire lorsqu’une
politique d’equipe (seuils, plateformes de reference) est definie.

## Table test | ecran | entree | assertion critique | fichier

```text
test | ecran | entree BootScreenModel | assertion critique | fichier
idle simple loading | chargement simple | mapper(AppLaunchState idle) | MoviAssetIcon, pas Filled/TextButton, pas reasonCode | boot_critical_screens_widget_test
preload catalogue | preparation catalogue | running + preloadCompleteHome | idem | boot_critical_screens_widget_test
timeout sync | recovery source | welcomeSources + plan catalogSyncTimeout | Reessayer + Changer de source, pas reasonCode | boot_critical_screens_widget_test
credentials invalides | recovery source | plan catalogCredentialsInvalid | Reconnecter seul, pas TextButton secondaire | boot_critical_screens_widget_test
catalogue vide | recovery source | plan catalogEmpty | Resynchroniser + Changer de source | boot_critical_screens_widget_test
auth requise | action requise | success + destination auth | Se connecter | boot_critical_screens_widget_test
profil requis | action requise | welcomeUser | Continuer + texte profil | boot_critical_screens_widget_test
source requise | action requise | welcomeSources sans plan | Ajouter une source | boot_critical_screens_widget_test
selection source | action requise | chooseSource | Choisir une source | boot_critical_screens_widget_test
technical failure | echec technique | status failure | Reessayer + Exporter logs, focus primaire | boot_critical_screens_widget_test
Home partiel banniere | Home (hors boot mapper) | HomeDegradationNotice feed | l10n + Reload sections, pas reasonCode | boot_critical_screens_widget_test
mapper reason leak | (logique) | chooseSource | titres/labels != reasonCode | boot_screen_mapper_test
non interactifs sans actions | (logique) | plusieurs etats running/success home | isInteractive false, pas actions | boot_screen_mapper_test
chargement simple isolé | widget | BootSimpleLoadingScreen | logo, pas bouton | boot_simple_loading_screen_test
chargement simple 393x852 | widget | message long | pas exception layout | boot_simple_loading_screen_test
catalogue isolé | widget | BootCatalogLoadingScreen | logo, pas bouton | boot_catalog_loading_screen_test
catalogue 393x852 | widget | textes longs | pas exception | boot_catalog_loading_screen_test
recovery focus Tab | widget | BootRecoveryPanel | ordre focus 1 puis 2 | boot_recovery_panel_test
Home banner actions | widget | HomeErrorBanner | actions l10n | home_error_banner_test
```

## Helper test

`buildBootSurfaceForModel` dans `boot_critical_screens_widget_test.dart` reproduit
le choix **chargement simple / catalogue / panneau recovery** aligne sur
`splash_bootstrap_page` (sans orchestrateur complet).

## Commandes

```bash
flutter test test/core/startup/boot_critical_screens_widget_test.dart
flutter test test/core/startup/
```
