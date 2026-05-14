# Etape 5.5 - Textes et messages contradictoires

## Cible

Retirer les messages generiques restants dans les surfaces boot/welcome qui
contredisaient le tunnel unifie ou manquaient de contexte utilisateur.

## Changements appliques

- `welcome_source_loading_page.dart`
  - `"Préparation de l'accueil..."` -> `"Reprise du lancement..."`.
- `app_launch_orchestrator.dart`
  - `recoveryMessage` `"Préparation de l'accueil en cours..."` ->
    `"Ouverture de l'accueil en cours..."`.
- `welcome_source_select_page.dart`
  - message d'erreur `errorUnknown` + exception brute ->
    `errorLoadingPlaylistsWithMessage(...)` (message contextualise).
- `welcome_user_page.dart`
  - fallback `errorUnknown` remplace par
    `"Impossible de charger les profils."` sur le parcours boot/welcome.
- l10n boot principal (`app_fr.arb`, `app_en.arb`)
  - `overlayPreparingHome` raffine (`Initialisation...` / `Initializing...`).
  - `errorPrepareHome` remplace `Impossible de préparer la page d'accueil` par
    un message de lancement interrompu.

## Verification

- `flutter gen-l10n`
- `flutter analyze` sur les fichiers modifies
- `flutter test`:
  - `test/core/startup/boot_screen_mapper_test.dart`
  - `test/core/startup/boot_critical_screens_widget_test.dart`
  - `test/features/welcome/presentation/welcome_source_loading_page_test.dart`

Toutes ces commandes passent.

## Note

La cle `errorUnknown` reste disponible dans le produit pour d'autres contextes
hors boot (ex: bibliotheque/settings), mais n'est plus le fallback principal
dans les surfaces boot/welcome touchees ici.
