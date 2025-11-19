## 1️⃣ Résumé global

La feature `library` offre une bibliothèque utilisateur assez bien structurée, avec une séparation claire Domain / Data / Presentation et un bon niveau d’abstraction pour les favoris, l’historique et les playlists.  
Le Domain reste fin (repositories + 2 use cases ciblés) et ne dépend pas de Flutter, la Data s’appuie proprement sur les repositories locaux existants (`WatchlistLocalRepository`, `HistoryLocalRepository`, `PlaylistRepository`, `PersonRepository`), et la Presentation est construite autour de providers Riverpod et de pages/widgets dédiés.  
La complexité est globalement maîtrisée, même si certains widgets (notamment `LibraryPlaylistDetailPage`) commencent à devenir longs et multi‑responsabilités (tri, navigation, UI hero, gestion modale, suppression, enrichissement TMDB).  
Les bonnes pratiques Flutter/Riverpod sont globalement respectées, avec un usage correct des `FutureProvider`, `NotifierProvider` et une intégration propre avec le router.  
Les points à améliorer concernent surtout le découpage de certains widgets “fourre‑tout”, la centralisation de certaines logiques métier (filtrage historique, enrichissement TMDB, tri) et une meilleure testabilité des providers clés.  
Dans l’ensemble, la feature est solide et proche d’un niveau pro, avec quelques refactors ciblés qui la rendraient plus facile à faire évoluer (nouveaux types de playlists, nouvelles vues de la bibliothèque).

---

## 2️⃣ Architecture & organisation

### Rôle du dossier

- `lib/src/features/library/` : gère la **bibliothèque utilisateur** :
  - favoris (films, séries, sagas, personnes),
  - historique (terminé / en cours),
  - playlists utilisateur,
  - présentation unifiée sous forme de “playlists” (in progress, favoris, historique, playlists perso, sagas, artistes).

Sous‑dossiers :
- `domain/` : contrats de repositories (`LibraryRepository`, `FavoritesRepository`, `HistoryRepository`) et use cases `LikePerson` / `UnlikePerson`.  
- `data/` : implémentations concrètes des repositories à partir du storage local et des repositories existants (playlist, person).  
- `presentation/` : pages (`LibraryPage`, `LibraryPlaylistDetailPage`), providers Riverpod (`library_providers.dart`) et widgets (pills de filtre, cartes de playlists, modal d’ajout de médias).

### Domain

- `library_repository.dart` :
  - Fournit une API agrégée pour la bibliothèque (getLikedMovies/Shows/Sagas/Persons, getHistoryCompleted/InProgress, getUserPlaylists).  
  - S’appuie sur des types de domaine déjà existants (`MovieSummary`, `TvShowSummary`, `SagaSummary`, `PersonSummary`, `ContentReference`, `PlaylistSummary`).
- `favorites_repository.dart` :
  - Interface simple pour liker/déliker une personne via `PersonId`.  
- `history_repository.dart` :
  - Interface pour exposer l’historique complété / en cours sous forme de `ContentReference`.
- `like_person.dart` / `unlike_person.dart` :
  - Use cases ultra‑fins encapsulant l’appel au `FavoritesRepository`.

**Appréciation** : Domain est minimaliste, cohérent, sans dépendance à Flutter, conforme à une Clean Arch simple. On pourrait à terme enrichir en use cases plus riches (ex : “charger la bibliothèque initiale” ou “charger une playlist détaillée de bibliothèque”), mais ce n’est pas bloquant.

### Data

- `library_data_module.dart` :
  - Enregistre `LibraryRepositoryImpl`, `FavoritesRepositoryImpl`, `HistoryRepositoryImpl` dans le locator `sl`, en s’appuyant sur les repositories locaux (`WatchlistLocalRepository`, `HistoryLocalRepository`, `PlaylistRepository`, `PersonRepository`).  
- `library_repository_impl.dart` :
  - Implémente `LibraryRepository` en :
    - lisant les entrées de watchlist pour films/séries/sagas/personnes,  
    - convertissant en `MovieSummary`, `TvShowSummary`, `SagaSummary`, `PersonSummary` (avec fallback d’avatar via `PersonRepository.getPerson`),  
    - lisant l’historique via `HistoryLocalRepository` et filtrant via `_filterCompleted` / `_filterInProgress` en `ContentReference`,  
    - déléguant `getUserPlaylists` à `PlaylistRepository`.  
  - Gère en interne un `userId` (par défaut `'default'`), ce qui permet une multi‑session basique.
- `favorites_repository_impl.dart` :
  - Mappe `likePerson` / `unlikePerson` sur des opérations `WatchlistLocalRepository.upsert` / `remove` avec `ContentType.person`.
- `history_repository_impl.dart` :
  - Variante simplifiée pour exposer `getCompleted` / `getInProgress` en `ContentReference`, avec le même filtrage de progression que `LibraryRepositoryImpl`.

**Appréciation** : La couche Data est propre, découplée du UI, et se contente d’agréger/mapper les données de stockage. Il y a un léger **chevauchement** entre `LibraryRepositoryImpl` et `HistoryRepositoryImpl` (logique de filtrage historique dupliquée), qui pourrait être factorisé.

### Presentation

- `library_providers.dart` :
  - `libraryRepositoryProvider` : expose `LibraryRepositoryImpl` à la présentation en l’initialisant avec l’`userId` courant (via `currentUserIdProvider`), ce qui découple la présentation du locator direct.  
  - `libraryPlaylistsProvider` : construit la liste de `LibraryPlaylistItem` à partir :
    - de l’historique (in progress + history completed),  
    - des favoris films/séries,  
    - des playlists utilisateur (avec recomptage des items en temps réel via `PlaylistRepository.getPlaylist`),  
    - des `PersonSummary` likés (type `actor`),  
    - des sagas likées (type `saga_…`).  
  - `filteredLibraryPlaylistsProvider` : applique le filtre (playlists / sagas / artistes) et la recherche textuelle.  
  - Providers supplémentaires pour charger les items d’une playlist (`playlistItemsProvider`, `playlistContentReferencesProvider`) avec enrichissement optionnel via TMDB pour les années manquantes.
- `library_page.dart` :
  - Ecran principal de la bibliothèque : en‑tête (titre, recherche, bouton +), champ de recherche animé, pills de filtre, liste des playlists (via `LibraryPlaylistCard`), création de playlists (dialog Cupertino + use case `CreatePlaylist`), renommage/suppression de playlists.  
  - Contient pas mal de logique d’UI + un peu d’orchestration (appel des providers, navigation).
- `library_playlist_detail_page.dart` :
  - Détail d’une playlist (user ou “système”) :
    - hero custom (gradient, icône selon type de playlist, compteur d’éléments),  
    - boutons “Lire aléatoirement”, “Ajouter”, “Trier”,  
    - tri des items par titre / date d’ajout / année (croissant/décroissant) avec `_sortItems`,  
    - chargement des items via `playlistContentReferencesProvider` ou `_otherPlaylistItemsProvider`,  
    - enrichissement TMDB pour backdrop et années,  
    - suppression d’items (swipe/dismissible + modale) pour playlists utilisateur,  
    - navigation vers pages movie/TV.

**Appréciation** : l’architecture presentation est globalement saine (Riverpod + routing GoRouter). Les deux pages sont cependant massives, surtout `LibraryPlaylistDetailPage`, qui mélange UI complexe + logique de tri + logique d’enrichissement TMDB + contrôle des playlists utilisateur.

---

## 3️⃣ Problèmes identifiés (classés par sévérité)

### 🔴 Critique

Aucun problème bloquant critique n’est apparu : la feature est cohérente, bien séparée, et ne semble pas introduire de debt majeure qui casserait l’architecture globale.

---

### 🟠 Important

#### 3.1 `LibraryPlaylistDetailPage` est une “god widget” locale

- **Fichier** : `presentation/pages/library_playlist_detail_page.dart`.  
- **Problème** :
  - La classe `_LibraryPlaylistDetailPageState` gère :
    - la logique de tri (`_sortType`, `_sortItems`),  
    - la logique de menu playlist (renommer/supprimer),  
    - la logique d’ajout/retrait d’items (dialogs + appels use cases),  
    - la logique d’enrichissement (backdrop TMDB, durée/saisons),  
    - et toute la construction UI (hero, boutons, liste).  
  - Le fichier est long et mélange UI + règles métier (sélection du bon provider selon type de playlist, logique de tri par date d’ajout, etc.).  
- **Pourquoi c’est un problème** :
  - Complexité cognitive élevée, difficile à tester unitairement.  
  - Toute évolution (nouveau type de tri, nouvelle présentation) risque d’alourdir encore ce widget.  
- **Suggestion de correction** :
  - Extraire des sous‑widgets et/ou des classes de service :
    - `LibraryPlaylistHero` (hero + compteur).  
    - `LibraryPlaylistActionsBar` (boutons Lire aléatoirement / Ajouter / Trier).  
    - Un `LibraryPlaylistSorter` (service ou utilitaire) contenant `_sortItems`.  
  - Envisager un provider dédié pour le tri et l’état de la playlist détail, afin de sortir la logique du widget d’UI.

#### 3.2 Duplication de la logique de filtrage historique

- **Fichiers** :
  - `data/repositories/library_repository_impl.dart` (`_filterCompleted`, `_filterInProgress`).  
  - `data/repositories/history_repository_impl.dart` (mêmes méthodes avec structure quasi identique).  
- **Problème** :
  - La logique `progress >= 0.9` / `0 < progress < 0.9` est dupliquée dans deux repositories.  
  - Le calcul `_progress` est lui aussi dupliqué.  
- **Pourquoi c’est un problème** :
  - Si la définition de “terminé” / “en cours” évolue, il faudra modifier plusieurs endroits, avec risque d’incohérence.  
- **Suggestion de correction** :
  - Créer un petit service ou helper commun (par ex. `HistoryFilterService` dans `library/domain` ou un utilitaire partagé) qui reçoit une liste de `HistoryEntry` et renvoie `completed` / `inProgress`.  
  - `LibraryRepositoryImpl` et `HistoryRepositoryImpl` l’utiliseraient tous deux, ce qui garantit une seule source de vérité.

#### 3.3 Accès direct au `sl` dans la présentation pour les playlists

- **Fichier** : `presentation/providers/library_providers.dart` + pages.  
- **Problème** :
  - Certains use cases sont encore créés directement dans la présentation à partir de `sl` (`CreatePlaylist`, `RenamePlaylist`, `DeletePlaylist`, `RemovePlaylistItem`).  
- **Pourquoi c’est un problème** :
  - Cela recouple légèrement la présentation au service locator global, alors que pour `LibraryRepository` tu es déjà passé par un provider.  
- **Suggestion de correction** :
  - Exposer des providers pour ces use cases / repositories (ex: `createPlaylistProvider`, `renamePlaylistProvider`, etc.) dans un fichier de providers ciblé (ou dans `playlist` feature), afin que la présentation ne dépende que de Riverpod.

---

### 🟢 Nice to have

#### 3.4 Use cases `LikePerson` / `UnlikePerson` très fins mais peu utilisés

- **Fichier** : `domain/usecases/like_person.dart`, `unlike_person.dart`.  
- **Problème** :
  - Use cases très simples, qui ne font qu’appeler `FavoritesRepository`; on ne voit pas encore d’usage dans la présentation (selon le code visible).  
- **Pourquoi c’est un problème** :
  - Si non utilisés, ils encombrent légèrement le domaine.  
  - S’ils sont utilisés, ce sont des wrappers corrects, mais il peut être intéressant de les intégrer dans un pattern d’usage plus large (ex : “gérer les favoris personne” avec un provider dédié).  
- **Suggestion de correction** :
  - Vérifier s’ils sont réellement consommés.  
  - Si oui, c’est très bien comme entrées Domain (pas de changement nécessaire).  
  - Si non, soit les supprimer, soit les brancher via un provider de use case pour les futurs écrans People.

#### 3.5 Enrichissement TMDB dans `playlistContentReferencesProvider`

- **Fichier** : `presentation/providers/library_providers.dart`.  
- **Problème** :
  - `playlistContentReferencesProvider` enrichit les années via des appels directs à `TmdbClient` (movie/tv) depuis la présentation.  
  - La logique de parsing des dates (split sur `'-'`, year première partie) est dupliquée ici.  
- **Pourquoi c’est un problème** :
  - Mélange (léger) de logique d’accès données dans la couche Presentation.  
  - Parsing des dates fragile (connaissance du format TMDB) qui pourrait être partagé avec d’autres features.  
- **Suggestion de correction** :
  - Extraire cette logique d’enrichissement dans un petit service (par ex. `PlaylistEnrichmentService` dans `library/domain` ou `shared/domain/services`), consommé par le provider.  
  - Centraliser la fonction “extrait l’année TMDB depuis une date string” pour éviter la duplication.

#### 3.6 Centralisation de constantes magiques (IDs / thresholds)

- **Fichiers** : `library_repository_impl.dart`, `history_repository_impl.dart`, `library_providers.dart`.  
- **Problème** :
  - Seuil des 90% (`0.9`) pour l’historique, IDs “in_progress”, “favorite_movies”, etc., sont des constantes inline.  
- **Suggestion de correction** :
  - Regrouper ces valeurs dans un petit fichier de constantes de feature (ex: `library_constants.dart`) pour faciliter les modifications et éviter les typos.

---

## 4️⃣ Plan de refactorisation par étapes

### Étape 1 – Isoler la logique historique

- Extraire la logique `_filterCompleted` / `_filterInProgress` / `_progress` dans un service ou helper commun (`HistoryFilterService` ou équivalent) utilisé par `LibraryRepositoryImpl` et `HistoryRepositoryImpl`.  
- Ajouter éventuellement un test unitaire simple pour vérifier le comportement sur quelques `HistoryEntry`.

### Étape 2 – Décomposer `LibraryPlaylistDetailPage`

- Extraire au moins :
  - un widget `LibraryPlaylistHero` (hero + compteur d’items),  
  - un widget `LibraryPlaylistActions` (Lire aléatoirement, Ajouter, Trier),  
  - et, si possible, sortir `_sortItems` dans une classe utilitaire ou un service.  
- Laisser la page orchestrer ces composants plutôt que tout gérer dans une seule classe.

### Étape 3 – Découpler davantage la présentation du service locator

- Créer des providers pour :
  - `PlaylistRepository` (déjà fait),  
  - et/ou pour les use cases `CreatePlaylist`, `RenamePlaylist`, `DeletePlaylist`, `RemovePlaylistItem`.  
- Dans `LibraryPage` et `LibraryPlaylistDetailPage`, remplacer les accès directs à `sl` par ces providers.

### Étape 4 – Extraire l’enrichissement TMDB de `playlistContentReferencesProvider`

- Créer un petit service `PlaylistTmdbEnrichmentService` dans le domaine ou le shared, prenant une `ContentReference` et retournant une version enrichie (`year`) via `TmdbClient`.  
- Le provider n’appellerait plus directement `TmdbClient`, mais ce service, ce qui rendra aussi la testabilité plus simple.

### Étape 5 – Centraliser les constantes de la feature Library

- Introduire un fichier `library_constants.dart` contenant :
  - les IDs logiques (`'in_progress'`, `'favorite_movies'`, etc.),  
  - les seuils de progression (ex : `completedThreshold = 0.9`).  
- Remplacer les valeurs inline par ces constantes dans `LibraryRepositoryImpl`, `HistoryRepositoryImpl`, `library_providers.dart`, etc.

### Étape 6 – Tests ciblés sur les providers clés

- Ajouter des tests unitaires (ou des tests de providers Riverpod) pour :
  - `libraryPlaylistsProvider` (construction correcte des `LibraryPlaylistItem` pour différentes situations),  
  - `filteredLibraryPlaylistsProvider` (filtres playlists/sagas/artistes + recherche),  
  - potentiellement `playlistContentReferencesProvider` avec un `TmdbClient` mocké.

---

## 5️⃣ Bonnes pratiques à adopter pour la suite

- **Garder la logique métier hors des widgets** : privilégier des services ou providers pour le tri, le filtrage, l’enrichissement, plutôt que de grossir les State classes.  
- **Unifier les règles métier partagées** (comme la notion de “terminé” vs “en cours” pour l’historique) dans des helpers/services communs.  
- **Limiter l’accès direct au service locator dans la présentation** : préférer des providers Riverpod pour exposer les repositories et use cases.  
- **Tester les providers structurants** (comme `libraryPlaylistsProvider`) pour verrouiller le comportement de la bibliothèque face aux évolutions de storage.  
- **Centraliser les constantes métier** de la feature dans un fichier dédié (`library_constants.dart`) afin d’éviter les duplications et les magic strings.  
- **Continuer à utiliser des modèles de domaine riches** (`MovieSummary`, `TvShowSummary`, `SagaSummary`, `PersonSummary`) et des `ContentReference` pour garder une API claire entre couches.  
- **Soigner l’UX tout en gardant la lisibilité du code** : extraire les gros morceaux d’UI (dialogs, hero, actions bar) en widgets réutilisables pour limiter la taille des pages principales.  

