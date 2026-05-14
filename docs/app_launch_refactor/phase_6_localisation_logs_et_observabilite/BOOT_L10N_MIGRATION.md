# Etape 6.2 - Localisation (l10n)

## Cible

Remplacer les textes boot/welcome encore en dur par des cles l10n, avec des
messages courts et actionnables, sans exposer de codes internes.

## Changements appliques

- `lib/l10n/app_fr.arb` et `lib/l10n/app_en.arb`
  - ajout des cles boot manquantes (loading, recovery source, echec technique,
    labels d'actions boot) ;
  - ajout des cles welcome source/user manquantes (sections, labels de champs,
    tooltip refresh, expiration, dialogue profil verrouille).
- `lib/src/core/startup/presentation/boot_screen_localizer.dart`
  - nouveau localizer de `BootScreenModel` (titre/message/actions) base sur
    `reasonCode`, destination et type d'ecran.
- `lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart`
  - application du localizer avant rendu (`BootScreenRenderer`).
- `lib/src/core/startup/presentation/widgets/launch_recovery_banner.dart`
  - CTA retry bascule sur `l10n.actionRetry`.
- `lib/src/features/welcome/presentation/pages/welcome_source_page.dart`
  - migration des labels/titres/tooltip/formulaires/messages de section vers
    l10n.
- `lib/src/features/welcome/presentation/pages/welcome_user_page.dart`
  - migration du texte du dialogue PIN verrouille et des erreurs de chargement
    profils vers l10n.
- `test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart`
  - expectations alignees avec la locale par defaut (anglais).

## Verification

- `flutter gen-l10n`
- `flutter analyze` (fichiers modifies)
- `flutter test test/features/welcome/presentation/welcome_user_page_auth_priority_test.dart`
- `flutter test test/features/welcome/presentation/splash_bootstrap_page_progress_test.dart`

Toutes ces commandes passent.

## Note

Le `BootScreenMapper` conserve des libelles de secours internes, mais les
surfaces utilisateur boot passent desormais par un localizer avant rendu afin
de garantir une presentation localisee et sans fuite de `reasonCode`.
