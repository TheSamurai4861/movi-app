# Decisions — Phase 4 UI boot et composants (synthese)

Date de synthese : mai 2026. Portee : `docs/app_launch_refactor/phase_4_ui_boot_et_composants/`.

## 1. Widgets crees ou adaptes

| Widget / module | Role |
| --- | --- |
| `BootSimpleLoadingScreen` | Chargement non interactif : logo centre (`MoviAssetIcon`), texte et indicateur en bas, `BootLoadingElapsedLabel`. |
| `BootCatalogLoadingScreen` | Preparation catalogue : meme principe avec panneau bas distinct (non interactif). |
| `BootRecoveryPanel` | Recovery actionnable : titre, messages, details tronques, actions via `BootActionIntent`, focus / traversal, largeur adaptive. |
| `BootFormTokens` | Mesures Figma (largeurs max boutons/champs, styles champs pages action). |
| `HomeErrorBanner` (+ helpers l10n) | Banniere degradations Home partiel, compact mobile / desktop. |
| `LaunchErrorPanel` | **Adapte** : reutilise `BootRecoveryPanel` en interne (surface recovery partagee). |

Composants **conserves** sans remplacement total : `launch_recovery_banner` sur
certaines pages welcome / shell (bandeaux contextuels hors tunnel splash
principal).

## 2. Surfaces legacy : remplacees vs conservees

- **Splash bootstrap** (`SplashBootstrapPage`) : point d’entree unique pour
  `BootScreenModel` → chargements + recovery ; `FocusRegionScope` pour la TV /
  focus entree.
- **`OverlaySplash`** : utilise `BootSimpleLoadingScreen` pour alignement avec
  le chargement boot.
- **`AppStartupGate`** : conserve `LaunchErrorPanel` pour erreurs pre-navigation
  (hors `SplashBootstrapPage`) — panel deja aligne sur `BootRecoveryPanel`.
- **Pages welcome / selection source** : bannieres `LaunchRecoveryBanner` **conservees**
  la ou le parcours n’est pas le meme que le splash orchestrateur.
- **Recherche** (`provider_*_page`) : `LaunchErrorPanel` conserve pour erreurs
  liste resultats.

**Phase 5** : auditer chaque usage `LaunchErrorPanel` / `LaunchRecoveryBanner` /
 anciens splash pour deduplication ou suppression si doublon fonctionnel avec
 le tunnel boot.

## 3. Ecrans et parcours couverts (documentation + tests)

- Chargement simple, preparation catalogue, recovery source (timeout,
  identifiants, catalogue vide), destinations auth / profil / source / selection
  source, echec technique, ouverture Home (modele), banniere Home partiel.
- Contrats et guides : `BOOT_RENDERER_CONTRACT.md`, `BOOT_LOADING_SCREENS.md`,
  `CATALOG_LOADING_SCREEN.md`, `BOOT_RECOVERY_PANEL.md`,
  `BOOT_COMPONENT_VARIANTS.md`, `ACTION_PAGES_UI.md`, `HOME_PARTIAL_BANNER.md`,
  `RESPONSIVE_AND_FOCUS.md`, `BOOT_WIDGET_TEST_COVERAGE.md`,
  `MANUAL_UI_VALIDATION.md`.

## 4. Renderer `BootScreenModel -> Widget`

Le document `BOOT_RENDERER_CONTRACT.md` decrit un **renderer dedie** type
`BootScreenRenderer`. En fin de Phase 4, le rendu est **branche** dans
`SplashBootstrapPage` (switch sur `BootScreenType` + etat recovery), ce qui
respecte le contrat fonctionnel (pas d’orchestrateur dans les widgets feuilles).

**Decision** : ne pas extraire `BootScreenRenderer` dans cette phase pour
limiter le diff ; la **checklist** Phase 4 « Renderer boot cree ou branche »
reste **ouverte** tant qu’un widget nomme unique n’est pas extrait — le
comportement est neanmoins **operationnel** via le splash.

**Phase 5** : extraire `BootScreenRenderer` (presentation-only) + tests d’injection
  si la taille / la testabilite de `SplashBootstrapPage` devient un frein.

## 5. Tests ajoutes (rappel)

- `boot_simple_loading_screen_test`, `boot_catalog_loading_screen_test`,
  `boot_recovery_panel_test`, `boot_critical_screens_widget_test`,
  `boot_screen_mapper_test` (et suite `test/core/startup/` existante).
- `home_error_banner_test` (Home partiel).

Goldens / snapshots : **non** integres (voir `BOOT_WIDGET_TEST_COVERAGE.md`).

## 6. Validations manuelles

Substituts documentes dans `MANUAL_UI_VALIDATION.md` (tests + analyze) ;
parcours `flutter run` / TV **a completer** par l’equipe sur materiel.

## 7. Risques et suites par phase

### Phase 5 (nettoyage legacy)

- Supprimer ou fusionner les surfaces boot dupliquees une fois le renderer
  extrait et les routes stabilisees.
- Verifier les derniers ecrans qui n’utilisent pas encore `BootFormTokens` /
  `BootRecoveryPanel` pour coherence visuelle.

### Phase 6 (localisation / textes)

- Textes du `BootScreenMapper` et messages boot encore en **francais en dur**
  dans le mapper / splash strings ; aligner sur `l10n` (deja amorce pour
  `HomeErrorBanner` et parties catalogue secondaires).
- Harmoniser logs vs textes utilisateur (reason codes jamais affiches — regle
  deja testee sur les surfaces cibles).

### Phase 7 (validation globale UI)

- Reprendre les scenarios bout-en-bout (auth, profil, source, boot erreur,
  Home partiel) sur **plusieurs locales** et **accessibilite** (TalkBack /
  VoiceOver) avec la checklist `MANUAL_UI_VALIDATION.md`.

## 8. Definition de fini (etape 12)

- La Phase 5 sait **quoi auditer** (legacy panels / bannieres) et que le rendu
  boot est **centralise** dans le splash + tokens partages.
- La Phase 6 sait **ou migrer les chaines** (mapper boot, messages residuels).
- La Phase 7 sait **quels parcours** rejouer en validation globale.

**Statut :** synthese produite — ce fichier ; mise a jour `ROADMAP.md` etape 12.
