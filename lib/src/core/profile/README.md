# Core ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Profile

Module ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œprofilÃƒÂ¢Ã¢â€šÂ¬Ã‚Â (Netflix-like) : gÃƒÆ’Ã‚Â©rer plusieurs profils par compte Supabase.

## Objectif
- Lister les profils de l'utilisateur connectÃƒÆ’Ã‚Â©
- CrÃƒÆ’Ã‚Â©er / modifier / supprimer un profil
- Persister un profil sÃƒÆ’Ã‚Â©lectionnÃƒÆ’Ã‚Â© localement (Secure Storage)
- Permettre au bootstrap / onboarding de choisir un profil par dÃƒÆ’Ã‚Â©faut

## Structure (Clean Architecture)
- `domain/`
  - `entities/profile.dart` : entitÃƒÆ’Ã‚Â© mÃƒÆ’Ã‚Â©tier (sans JSON)
  - `repositories/profile_repository.dart` : contrat mÃƒÆ’Ã‚Â©tier
- `data/`
  - `dtos/profile_dto.dart` : parsing DB/JSON
  - `repositories/supabase_profile_repository.dart` : impl Supabase de `ProfileRepository`
  - (optionnel) `datasources/` + `mappers/` si tu veux sÃƒÆ’Ã‚Â©parer I/O et mapping
- `application/`
  - `services/selected_profile_service.dart` : encapsule la persistance locale du profil choisi
  - `usecases/` : actions unitaires (GetProfiles, CreateProfile, etc.)
- `presentation/`
  - `controllers/` : logique Riverpod (AsyncNotifier/Notifier)
  - `providers/` : wiring/DI Riverpod
  - `ui/` : widgets/dialogs/constants UI (palette, chips, pickerÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦)

## RÃƒÆ’Ã‚Â¨gles de dÃƒÆ’Ã‚Â©pendances
- `presentation` dÃƒÆ’Ã‚Â©pend de `application` + `domain`
- `application` dÃƒÆ’Ã‚Â©pend de `domain`
- `data` dÃƒÆ’Ã‚Â©pend de `domain` (et de Supabase)
- `domain` ne dÃƒÆ’Ã‚Â©pend de rien

## Notes Supabase (table `profiles`)
Colonnes attendues:
- `id` (uuid)
- `account_id` (uuid) = `auth.uid()`
- `name` (text)
- `created_at` (timestamp)
Optionnel:
- `color` (int)
- `avatar_url` (text)

RLS recommandÃƒÆ’Ã‚Â©e:
- SELECT/INSERT/UPDATE/DELETE autorisÃƒÆ’Ã‚Â©s uniquement si `account_id = auth.uid()`.
