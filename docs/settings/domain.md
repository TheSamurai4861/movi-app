# Journal – Feature Settings / Domain Layer

## 2024-XX-XX — Entités
- `UserPreferences` : thème (system/light/dark), langue (system/en/fr…), notifications (none/important/all), autoplay.
- `UserProfile` : id, nom, email, avatar, plan d’abonnement.

## 2024-XX-XX — Repository
- `SettingsRepository` avec `getPreferences`, `updatePreferences`, `getUserProfile`, `updateProfile`.

## 2024-XX-XX — Use cases
- `GetUserPreferences`, `UpdateUserPreferences`, `GetUserProfile`, `UpdateUserProfile`.

## TODO
- Ajouter des VO spécifiques (ex. `EmailAddress`, `AvatarUrl`) si nécessaire.
- Définir la persistance réelle (local + remote).
