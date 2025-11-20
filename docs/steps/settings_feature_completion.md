# Plan de complétion — Feature `settings`

Ce document liste les étapes restantes à partir de `docs/rapports/rapport_settings.md` pour finaliser la feature Paramètres.

## Étape 1 — Domain (Use cases & contrats)
- [ ] Ajouter tests: `test/features/settings/domain/load_user_profile_usecase_test.dart`
- [ ] Ajouter tests: `test/features/settings/domain/save_user_profile_usecase_test.dart`
- [ ] (Optionnel) Implémenter l’agrégat `SettingsRepository` et tests:
  - [ ] `test/features/settings/domain/get_user_preferences_usecase_test.dart`
  - [ ] `test/features/settings/domain/update_user_preferences_usecase_test.dart`

Références:
- `lib/src/features/settings/domain/entities/user_profile.dart`
- `lib/src/features/settings/domain/usecases/load_user_profile.dart`
- `lib/src/features/settings/domain/usecases/save_user_profile.dart`
- `lib/src/features/settings/domain/entities/user_preferences.dart`
- `lib/src/features/settings/domain/repositories/settings_repository.dart`

## Étape 2 — Data (Local DS & Repo)
- [ ] Ajouter tests: `test/features/settings/data/user_settings_repository_impl_test.dart` (mapping `StorageReadFailure`/`StorageWriteFailure`).
- [ ] Ajouter tests: `test/features/settings/data/user_settings_local_data_source_test.dart` (sérialisation/désérialisation; invalid → `null`).
- [ ] (Optionnel) Créer `SettingsRepositoryImpl` si l’agrégat est validé (préférences + profil).

Références:
- `lib/src/features/settings/data/datasources/user_settings_local_data_source.dart`
- `lib/src/features/settings/data/repositories/user_settings_repository_impl.dart`

## Étape 3 — Presentation (Controllers & UI)
- [ ] Ajouter tests: `test/features/settings/presentation/user_settings_controller_test.dart` (transitions: load/save, erreurs ne jettent pas).
- [ ] Ajouter tests: `test/features/settings/presentation/settings_page_widget_test.dart` (sélecteurs langue/thème/accent/audio/sous-titres; libellés i18n présents).
- [ ] Vérifier accessibilité (contraste, tailles de police, alternatives gestuelles).

Références:
- `lib/src/features/settings/presentation/providers/user_settings_providers.dart`
- `lib/src/features/settings/presentation/pages/settings_page.dart`
- `lib/src/core/state/app_state_controller.dart`

## Étape 4 — DI (enregistrement)
- [ ] Vérifier que `SettingsDataModule.register()` est appelé via `initDependencies(registerFeatureModules: true)`.
- [ ] (Optionnel) Ajouter `RegionPreferences` + enregistrement dans `lib/src/core/di/injector.dart`.

Références:
- `lib/src/features/settings/data/settings_data_module.dart`
- `lib/src/core/di/injector.dart`

## Étape 5 — Intégration (flux & cohérence)
- [ ] Vérifier que chaque sélecteur UI persiste et reflète l’état (langue, thème, accent, audio, sous-titres, intervalle IPTV).
- [ ] (Optionnel) Multi-profils: définir le design et backlog (sélection du profil actif, compatibilité avec `user_profile`).

Références:
- `lib/src/core/preferences/locale_preferences.dart`
- `lib/src/core/preferences/player_preferences.dart`
- `lib/src/core/preferences/accent_color_preferences.dart`
- `lib/src/core/preferences/iptv_sync_preferences.dart`

## Étape 6 — i18n
- [ ] Vérifier les clés manquantes/variantes dans `l10n/*.arb` pour la page Paramètres.

Références:
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_*.arb`

## Étape 7 — Documentation
- [ ] Mettre à jour `docs/rapports/rapport_settings.md` selon les décisions (agrégat, région providers, multi-profils, tests ajoutés).

Checklist synthèse (rapport):
- [x] DI core préférences (`lib/src/core/di/injector.dart:81–105`).
- [x] Repository profil + DS local.
- [x] Controller + UI de base.
- [ ] Tests Domain/Data/Presentation.
- [ ] Option Région & Multi-profils (si validé).