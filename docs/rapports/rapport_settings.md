# Plan d’implémentation — Feature « Paramètres / Settings »

Ce document décrit l’implémentation des paramètres utilisateurs de Movi, alignée sur les règles du projet (Clean Architecture, Riverpod, DI, tests, i18n, accessibilité). Il s’appuie sur les briques déjà présentes et précise les compléments nécessaires.

## Objectifs
- Centraliser et persister les préférences: langue de l’app, thème, couleur d’accent, langues audio/sous-titres du lecteur, fréquence de synchronisation IPTV.
- Gérer le profil utilisateur (prénom + langue), exploitable pour le scoping des données locales.
- Assurer une UX localisée, claire et cohérente (Material 3), avec feedback et états déterministes.
- Couvrir par des tests Domain/Data/Presentation, min. 80%.

## Portée
- Langue de l’application et thème: via `LocalePreferences` et `AppStateController`.
- Couleur d’accent personnalisable: via `AccentColorPreferences`.
- Préférences de lecture: `PlayerPreferences` (audio/subtitles).
- Fréquence de synchronisation IPTV: `IptvSyncPreferences` + `XtreamSyncService`.
- Profil utilisateur: `UserProfile` + `UserSettingsRepository`.
- Optionnel (à cadrer): région de recherche providers (ex. TMDB « FR ») via une `RegionPreferences` dédiée et intégration dans la recherche.

## Architecture

### Domain
- Entités:
  - `UserProfile` (`lib/src/features/settings/domain/entities/user_profile.dart`) — `firstName`, `languageCode`.
  - `UserPreferences` (`lib/src/features/settings/domain/entities/user_preferences.dart`) — thème, langue, notifications, autoplay.
- Value Objects:
  - `FirstName`, `LanguageCode` (déjà présents).
- Repositories (contrats):
  - `UserSettingsRepository` (save/load profil): `lib/src/features/settings/domain/repositories/user_settings_repository.dart`.
  - `SettingsRepository` (agrégat préférences + profil): `lib/src/features/settings/domain/repositories/settings_repository.dart`.
- Use cases:
  - Profil: `LoadUserProfile`, `SaveUserProfile` (existant), `GetUserProfile`, `UpdateUserProfile` (pour repo agrégat si nécessaire).
  - Préférences: `GetUserPreferences`, `UpdateUserPreferences`.
  - App: changement de langue/thème piloté via `AppStateController` et `LocalePreferences` (setter dédié).
  - Lecteur: setters audio/sous-titres via `PlayerPreferences`.
  - Accent: setter via `AccentColorPreferences`.
  - IPTV: setter d’intervalle via `IptvSyncPreferences` et synchronisation `XtreamSyncService`.

### Data
- Local Data Sources:
  - `UserSettingsLocalDataSource` (`lib/src/features/settings/data/datasources/user_settings_local_data_source.dart`) — persistance `user_profile` dans `ContentCacheRepository`.
  - Préférences sécurisées: `LocalePreferences`, `PlayerPreferences`, `AccentColorPreferences`, `IptvSyncPreferences` (stockage `FlutterSecureStorage`).
- Repositories:
  - `UserSettingsRepositoryImpl` (`lib/src/features/settings/data/repositories/user_settings_repository_impl.dart`) — mappe `StorageRead/WriteFailure`.
  - `SettingsRepositoryImpl` — à créer si l’agrégat est nécessaire; sinon conserver `UserSettingsRepository` + préférences unitaires.
- Cache/TTL: non requis pour les préférences; cohérence temps-réel via streams.

### Presentation
- Pages:
  - `SettingsPage` (`lib/src/features/settings/presentation/pages/settings_page.dart`) — UI localisée, sections Comptes/IPTV/App/Lecture, actions en `CupertinoActionSheet`.
- Controllers/Providers:
  - `UserSettingsController` (`lib/src/features/settings/presentation/providers/user_settings_providers.dart`) — état déterministe `UserSettingsState` (`profile`, `isSaving`, `error`).
  - App state (`lib/src/core/state/app_state_controller.dart`) — expose `preferredLocale`, `themeMode`, et providers `asp.*` pour lecture/écriture.
- i18n: clés déjà présentes dans `l10n/*.arb` (`settingsTitle`, `settingsAccountsSection`, …).
- Accessibilité: contrastes, tailles de police, gestures alternatives (tap/chevron), feedback SnackBar.

## Dependency Injection
- Core: `LocalePreferences`, `PlayerPreferences`, `AccentColorPreferences`, `IptvSyncPreferences` créés et enregistrés dans `lib/src/core/di/injector.dart`.
- Feature Settings: `SettingsDataModule.register()` (`lib/src/features/settings/data/settings_data_module.dart`) — enregistre `UserSettingsLocalDataSource` + `UserSettingsRepositoryImpl`.
- Option Region: si validé, enregistrer `RegionPreferences` dans `injector.dart` et l’exposer via `asp.currentRegionProvider`.

## Flux clés
- Changement de langue app:
  - UI → `LocalePreferences.setLanguageCode(code)` → stream → `AppStateController` met à jour `preferredLocale`.
- Thème:
  - UI → `LocalePreferences.setThemeMode(mode)` → stream → `AppStateController` met à jour `themeMode`.
- Accent color:
  - UI → `AccentColorPreferences.setAccentColor(color)` → stream → `asp.currentAccentColorProvider`.
- Audio/Subtitles:
  - UI → `PlayerPreferences.setPreferredAudioLanguage(code)`/`setPreferredSubtitleLanguage(codeOrNull)`.
- IPTV Sync:
  - UI → `IptvSyncPreferences.setSyncInterval(interval)` + `XtreamSyncService.setInterval(interval)`.
- Profil:
  - `UserSettingsController.save(profile)` → `SaveUserProfile` → `UserSettingsRepositoryImpl` → `UserSettingsLocalDataSource`.

## États & Erreurs
- États prédictibles côté UI (`UserSettingsState`): loading/saving/success/error.
- Erreurs typées en Data (`StorageReadFailure`, `StorageWriteFailure`) mappées vers messages localisés.
- Pas de `print`; logs via logger central si besoin.

## Tests
- Domain:
  - `load_user_profile_usecase_test.dart` — succès/erreur.
  - `save_user_profile_usecase_test.dart` — succès/erreur.
  - `update/get_user_preferences_usecase_test.dart` — si `SettingsRepository` agrégat utilisé.
- Data:
  - `user_settings_repository_impl_test.dart` — mappe exceptions vers failures.
  - `user_settings_local_data_source_test.dart` — sérialisation/désérialisation `user_profile` (valeurs invalides → `null`).
- Presentation:
  - `user_settings_controller_test.dart` — transitions d’état (load/save, erreurs non-propagées en exceptions).
  - `settings_page_widget_test.dart` — interactions basiques (sélecteurs langue/thème/accent/audio/subtitles), présence des libellés i18n.

## Sécurité & Données
- Persistance préférences dans `FlutterSecureStorage` (chiffré) — compliant RGPD.
- Éviter stockage de secrets en clair; pas d’API keys exposées.

## Évolutions
- Multi-profils: étendre `UserSettingsLocalDataSource` pour stocker une liste de profils et sélectionner l’actif; garder compatibilité avec `user_profile` clé unique.
- Région providers: introduire `RegionPreferences` et brancher la recherche (`watch_providers_provider`) sur la région choisie.
- Synchronisation cloud: optionnelle; prévoir une abstraction de sync plus tard.

## Checklist de complétion
- [x] DI core: `LocalePreferences`, `PlayerPreferences`, `AccentColorPreferences`, `IptvSyncPreferences` (`lib/src/core/di/injector.dart:81–105`).
- [x] Repository profil: `UserSettingsRepositoryImpl` + DataSource local.
- [x] Controller: `UserSettingsController` exposé via provider.
- [x] UI Settings: sections Comptes/IPTV/App/Lecture, actions fonctionnelles.
- [ ] Tests Domain/Data/Presentation (ajouter/compléter les fichiers listés ci-dessus).
- [ ] Option Région: décider et implémenter si validé par produit.
