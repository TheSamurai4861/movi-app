# Journal – Feature Person / Domain Layer

## 2024-XX-XX — Modélisation des entités
- Ajout du dossier `lib/src/features/person/domain/entities/` contenant :
  - `Person` : fiche complète (id, nom, bio, photo, dates, lieu de naissance, rôles, filmographie).
  - `PersonCredit` : participation d’une personne à un contenu (`ContentReference`, rôle, année).
- Dépendances partagées : `PersonId`, `MediaTitle`, `ContentReference`, `PersonSummary` (réutilisable côté Movie).

## 2024-XX-XX — Contrat de repository
- Interface `PersonRepository` (`lib/src/features/person/domain/repositories/person_repository.dart`) définie avec :
  - `getPerson` (fiche principale),
  - `getFilmography`,
  - `searchPeople`,
  - `getFeaturedPeople`.
- Ces signatures couvrent les besoins envisagés (détails, filmographie, recherche, mise en avant).

## 2024-XX-XX — Use cases
- Ajout du dossier `lib/src/features/person/domain/usecases/` avec :
  - `GetPersonDetail`, `GetPersonFilmography`, `SearchPeople`, `GetFeaturedPeople`.
- Chaque use case encapsule un appel au repository pour faciliter l’injection et la testabilité.

## TODO prochains steps
- Définir les DTO et mappers dans `features/person/data/dtos`.
- Implémenter `PersonRepository` côté data (sources remote/local).
- Ajouter des value objects complémentaires si besoin (biographie courte, métriques d’audience).
