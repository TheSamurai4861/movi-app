# Phase 4 - Etape 5 - Panneau recovery boot (`BootRecoveryPanel`)

## Objectif

Surface presentation-only alignee sur `BootScreenModel` pour les etats
**actionRequired** et **technicalFailure** : titre, message, sous-message
optionnel, action principale, action secondaire optionnelle. Les actions
emetent des `BootActionIntent` consommes par `executeBootAction` /
`BootActionHandler`.

## Widget

| Fichier | Role |
|---------|------|
| `lib/src/core/startup/presentation/widgets/boot_recovery_panel.dart` | `BootRecoveryPanel` + `fromBootModel` |
| `lib/src/core/widgets/launch_error_panel.dart` | Delegue vers `BootRecoveryPanel` (gravite erreur, message seul possible) |

## Usages `LaunchRecoveryBanner` (non migres en etape 5)

Bandeau compact (welcome / shell) : `welcome_user_page.dart`,
`welcome_source_page.dart`, `welcome_source_select_page.dart`,
`app_shell_page.dart`. Layout ligne different du panneau centre ; migration
eventuelle etape 6+ si alignement Figma.

## Table recovery | titre | action principale | action secondaire | widget | focus | test

Les titres / libelles viennent du `BootScreenMapper` (`boot_screen_mapper.dart`)
sauf erreur launch pure ou les libelles `AppLocalizations` restent via
`LaunchErrorPanel` -> `BootRecoveryPanel`.

```text
Erreur technique launch (failure + error) | Lancement interrompu | Reessayer | Exporter les logs | BootRecoveryPanel.fromBootModel | primary puis secondary | splash + boot_recovery_panel_test
Auth requise | Connexion requise | Se connecter | — | idem | primary | mapper
Profil requis | Profil requis | Continuer | — | idem | primary | idem
Source requise | Source requise | Ajouter / Reessayer | Changer de source si retry | idem | primary + secondary | idem
Selection source | Selection de source | Choisir une source | — | idem | primary | idem
Recovery plan (timeout, provider, credentials, empty) | titres _sourceRecoveryTitle | actions plan | secondaire si plan | idem | primary + secondary | mapper
Ecran erreurs hors boot (recherche, etc.) | — | libelle retry | — | LaunchErrorPanel -> BootRecoveryPanel | primary | existant
```

Aucun **reason code** brut dans l’UI du panneau.

## Integration

- `SplashBootstrapPage` : si `launchState.error != null` **ou**
  `bootModel.isInteractive`, affiche `BootRecoveryPanel.fromBootModel` dans un
  `SingleChildScrollView` ; `onAction` -> `executeBootAction` avec
  `BootActionRequest(intent, reasonCode: model.reasonCode)`.
- `FocusRegionScope` : noeud d’entree = action principale en mode recovery,
  sinon noeud de chargement.

## Focus clavier / TV

- `MoviPrimaryButton` recoit `primaryFocusNode` et `autofocus` aligne sur
  `BootFocusTarget.primaryAction`.
- `TextButton` secondaire recoit `secondaryFocusNode` ; ordre visuel : primaire
  au-dessus, secondaire en dessous (Tab naturel).

## Definition de fini

- [x] Panneau `BootRecoveryPanel` et factory `fromBootModel`.
- [x] Splash bootstrap branche sur le modele interactif et sur l’echec launch.
- [x] `LaunchErrorPanel` reutilise le panneau (gravite erreur).
- [x] Intentions boot via `executeBootAction`.
- [x] Aucun reason code affiche dans les tests de non-regression.
