# Plan d’implémentation – Feature Welcome

## Objectifs
- Sécuriser l’orchestration de bootstrap (éviter fuites de listeners).
- Corriger `WelcomeUiState.copyWith` pour un état prévisible.
- Nettoyer/brancher le code non utilisé (test de connexion, error presenter).
- Localiser totalement l’UI et centraliser la navigation.
- Polishing et tests ciblés pour fiabiliser la feature.

## Étape 1 — Sécuriser le bootstrap
- Conserver la `StreamSubscription` de l’event bus et l’annuler dans `ref.onDispose`.
- Vérifier l’appel unique de `start()` via un flag interne.
- Fichiers:
  - `lib/src/features/welcome/presentation/providers/bootstrap_providers.dart`

## Étape 2 — Corriger WelcomeUiState.copyWith
- Implémenter le pattern: ne rien passer ⇒ conserver; passer explicitement `null` ⇒ effacer.
- Ajouter des flags explicites `clearErrorMessage` et `clearEndpointPreview` si nécessaire.
- Adapter les appels (`toggleObscure`, `clearError`, etc.).
- Fichiers:
  - `lib/src/features/welcome/presentation/providers/welcome_providers.dart`

## Étape 3 — Tester la connexion & Error Presenter
- Choisir l’orientation:
  - Option A: Brancher un bouton “Tester la connexion” utilisant `WelcomeController.testConnection()` et `error_presenter.presentFailure`.
  - Option B: Supprimer le code non utilisé pour alléger la feature.
- Fichiers:
  - `lib/src/features/welcome/presentation/widgets/welcome_form.dart`
  - `lib/src/features/welcome/presentation/utils/error_presenter.dart`
  - `lib/src/features/welcome/presentation/providers/welcome_providers.dart`

## Étape 4 — Localisation & Navigation
- Remplacer les chaînes FR en dur par `AppLocalizations`.
- Centraliser la navigation via route names/helpers (GoRouter).
- Fichiers:
  - `lib/src/features/welcome/presentation/widgets/welcome_header.dart`
  - `lib/src/features/welcome/presentation/widgets/welcome_faq_row.dart`
  - `lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart`
  - `lib/src/features/welcome/presentation/pages/welcome_page.dart`
  - `lib/src/features/welcome/presentation/pages/welcome_source_page.dart`
  - `lib/src/features/welcome/presentation/pages/welcome_user_page.dart`
  - `lib/src/core/router/router.dart` (helpers/route names si manquants)

## Étape 5 — Polishing & Tests
- Passer les widgets statiques en `const` (SizedBox, Padding, Text).
- Ajouter tests:
  - Unitaires: `WelcomeController` (toggle, preview, copyWith).
  - Asynchrones: `appPreloadProvider` (success/timeout/partial).
  - Widget: `SplashBootstrapPage` selon `AsyncValue` (loading/error/success).
- Fichiers de test (proposés):
  - `test/features/welcome/presentation/welcome_controller_test.dart`
  - `test/features/welcome/presentation/app_preload_provider_test.dart`
  - `test/features/welcome/presentation/splash_bootstrap_page_test.dart`

## Checklist d’acceptation
- Aucun listener/timer persistant après disposal.
- `copyWith` conserve/efface correctement selon les paramètres.
- Aucun texte FR en dur dans l’UI Welcome.
- Navigation utilise des routes centralisées (noms/helpers).
- Tests verts et analyse statique sans warning (`flutter analyze`).

## Notes d’architecture
- Respect Clean Architecture: logique dans providers/controllers; pages/widgets “dumb”.
- Logging via `AppLogger` uniquement, pas de `print`.
- Null-safety stricte: éviter `!`, préférer checks explicites.