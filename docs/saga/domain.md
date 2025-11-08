# Journal – Feature Saga / Domain Layer

## 2024-XX-XX — Modélisation des entités
- `Saga` : id, titre, synopsis, cover, timeline (liste d’entrées), tags, dates de mise à jour.
- `SagaEntry` : référence contenu (`ContentReference`), ordre, année chronologique, notes.
- `SagaSummary` : aperçu (id, titre, cover, nombre d’items).

## 2024-XX-XX — Contrat de repository
- Interface `SagaRepository` (`lib/src/features/saga/domain/repositories/saga_repository.dart`) avec :
  - `getSaga`, `getUserSagas`, `searchSagas`.

## 2024-XX-XX — Use cases
- Dossier `lib/src/features/saga/domain/usecases/` avec :
  - `GetSagaDetail`, `GetUserSagas`, `SearchSagas`.

## TODO prochains steps
- Créer les DTO/mappers côté data pour saga/timeline.
- Ajouter des use cases additionnels (ex. ajout manuel d’un contenu à une saga custom) si nécessaire.
