# Core Profile

Module de gestion des profils utilisateur type "Netflix-like".

## Objectif

- lister les profils du compte connecte ;
- creer, modifier et supprimer un profil ;
- persister localement le profil selectionne ;
- permettre au bootstrap et a l'onboarding de restaurer un profil par defaut.

## Structure

- `domain/`
  - entites et contrats metier
- `data/`
  - dtos, data sources et repository Supabase
- `application/`
  - use cases et services orientes orchestration
- `presentation/`
  - controllers Riverpod, providers et widgets/dialogs UI

## Regles de dependances

- `presentation` depend de `application` et `domain`
- `application` depend de `domain`
- `data` depend de `domain` et de l'infrastructure externe
- `domain` reste independant de la presentation

## Notes Supabase

Table attendue : `profiles`

Colonnes minimales :

- `id` (uuid)
- `account_id` (uuid) = `auth.uid()`
- `name` (text)
- `created_at` (timestamp)

Colonnes optionnelles :

- `color` (int)
- `avatar_url` (text)

RLS recommandee :

- `SELECT`, `INSERT`, `UPDATE`, `DELETE` autorises uniquement si `account_id = auth.uid()`
