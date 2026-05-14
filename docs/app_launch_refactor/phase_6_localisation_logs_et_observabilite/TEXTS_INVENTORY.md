# Etape 6.1 - Inventaire textes boot

Objectif: recenser les textes du tunnel boot et des surfaces welcome associees,
puis distinguer ce qui doit etre localise (UI utilisateur) de ce qui reste
diagnostic (logs/dev).

## Perimetre analyse

- `lib/src/core/startup/presentation/boot_screen_mapper.dart`
- `lib/src/core/startup/presentation/widgets/*`
- `lib/src/features/welcome/presentation/pages/*` (surfaces liees au tunnel)
- `lib/src/core/startup/app_launch_orchestrator.dart` (messages runtime)
- `lib/src/core/startup/domain/startup_recovery_mapper.dart` (messages de plan)

## 1) Textes UI encore en dur (a migrer l10n en 6.2)

| Fichier | Type | Exemples | Cible 6.2 |
| --- | --- | --- | --- |
| `boot_screen_mapper.dart` | Messages/titres/labels boot | `Preparation du lancement`, `Verification de la session`, `Connexion requise`, `Source requise`, `Reessayer`, `Ajouter une source`, `Lancement interrompu` | Remplacer par cles l10n boot dediees (mapper + actions) |
| `launch_recovery_banner.dart` | Label CTA | `Reessayer` | Passer le label via l10n ou prop explicite |
| `welcome_source_page.dart` | Titres/infos/tooltip | `Sources sauvegardées`, `Activer une source`, `Aucune source trouvée...`, `Rafraîchir` | Migrer vers l10n welcome/boot |
| `welcome_user_page.dart` | Texte dialogue PIN | `Profil verrouillé`, `Saisis le PIN...` | Migrer vers l10n welcome/parental |

## 2) Textes UI deja localises (base stable)

| Zone | Exemples |
| --- | --- |
| Splash/bootstrap page | `overlayPreparingHome`, `overlayLoadingMoviesAndSeries`, `overlayOpeningHome`, `bootCatalogLocalCacheReady` |
| Startup gate erreurs | `errorPrepareHome`, `actionRetry` |
| Pages welcome (partiel) | `welcome*`, `errorFillFields`, `errorConnectionFailed`, `snackbarSourceAddedBackground` |

## 3) Textes diagnostic/dev (a ne pas exposer UI)

| Fichier | Exemples | Decision |
| --- | --- | --- |
| `startup_recovery_mapper.dart` | `IPTV provider failed at step...`, `Home failed.` | Conserver cote logs/plan; ne pas rendre en UI |
| `app_launch_orchestrator.dart` | `Catalog recovery required.` | Conserver interne; verifier non exposition utilisateur |
| `logging` dans pages welcome | traces `WelcomeSources: ...` | Conserver instrumentation, hors UI |

## 4) Risques identifies

- Le mapper boot concentre encore beaucoup de FR hardcode: risque de divergence
  multi-langue si non migre en 6.2.
- Quelques labels legacy welcome peuvent rester incoherents visuellement avec le
  tunnel boot unifie.
- Les messages diagnostic anglais dans des structures de recovery doivent rester
  cloisonnes aux logs.

## 5) Backlog actionnable (entree 6.2)

1. Ajouter les cles l10n pour les textes de `BootScreenMapper`.
2. Injecter l10n dans le mapper ou introduire un presenter localise.
3. Remplacer les hardcodes welcome critiques (`welcome_source_page`,
   `welcome_user_page`, `launch_recovery_banner`).
4. Verrouiller via tests:
   - pas de reason code/code interne visible ;
   - pas de fallback generique contradictoire.

## Sortie 6.1

- Inventaire produit: `TEXTS_INVENTORY.md`.
- Classification faite: UI a localiser vs diagnostic interne.
