# MOVI — Vue d’ensemble du projet

## 1. Description

MOVI est une plateforme de découverte et de consultation de contenus vidéo (films, séries, sagas, playlists, fiches personnes). L’application Flutter vise une base code unique pour iOS, Android, desktop et, à terme, TV. L’objectif est d’offrir un accès unifié au catalogue, à la reprise de lecture et aux recommandations personnalisées, tout en préparant la connexion à des APIs IPTV et à des services de préférences utilisateurs.

## 2. Fonctionnalités

### 2.1 Fonctionnalités présentes dans le code actuel

- Architecture modulaire `core/` vs `features/` avec GoRouter et GetIt en place.
- Thème complet (mode clair/sombre, typographies, palette MOVI).
- Composants UI transverses : bottom nav, boutons primaires, pillules, textes défilants.
- Pages *Home*, *Recherche*, *Bibliothèque*, *Paramètres* prêtes à être alimentées (placeholders explicites en attente de data/domain).
- Workflow Codemagic pour générer une IPA non signée (`flutter build ipa --no-codesign`).

### 2.2 Fonctionnalités souhaitées à court terme

- Implémenter la couche **domain** (entités, use cases, repositories) et la connecter aux pages existantes.
- Construire la couche **data** (sources remote/local, mapping DTO → domain, gestion d’erreurs).
- Brancher la page Home à un `HomeFeed` réel (hero, continue watching, recommandations, distribution).
- Mettre en place une persistance des préférences (thème, favoris, watchlist) et la synchronisation future.
- Ajouter des tests unitaires/domain + widget pour valider la structure.

### 2.3 Fonctionnalités futures (vision)

- Navigation avancée (deep links, profils multiples, TV remote support).
- Intégration des APIs IPTV (auth, catalogues, streaming, DRM).
- Pages détaillées complètes (films, séries, sagas, personnes) avec recommandations croisées.
- Gestion de la bibliothèque (playlists éditables, téléchargements, suivi de progression).
- Analytics, monitoring et personnalisation (A/B testing, métriques clés).

## 3. Roadmap hiérarchisée

### 3.1 Cadre & préparation

1.1 Vision produit, personas, cas d’usage — **Validé**  
1.2 Analyse des sources IPTV et contraintes — **Validé**  
1.3 Choix d’architecture (Flutter + Clean modulaire) — **Validé**  
1.4 Environnement dev & CI/CD de base (Codemagic) — **Validé (IPA non signée)**  
1.5 Charte graphique initiale — **Validé**

### 3.2 Infrastructure applicative

2.1 Squelette Flutter (modules `core`/`features`, routing) — **Terminé**  
2.2 Navigation GoRouter — **Terminé (routes principales)**  
2.3 Gestion des dépendances — **Partiellement : GetIt prêt, services réels à brancher**  
2.4 Modèles de données — **À faire**  
2.5 Couche d’accès data/domain — **À faire (questions rédigées)**

### 3.3 Page d’accueil (Home)

3.1 Hero (structure UI) — **Terminé (placeholder prêt, données manquantes)**  
3.2 Reprendre la lecture — **À faire (attend data)**  
3.3 Listes recommandations — **À faire**  
3.4 Navigation vers détails — **À valider (routes en place, pas de data)**  
3.5 États vides/tests — **En cours (placeholder défini, tests à écrire)**

### 3.4 Recherche

4.1 Champ de recherche + UX — **En place (UI)**  
4.2 Résultats/pagination — **À faire**  
4.3 Historique local — **À faire**  
4.4 Filtres avancés — **À faire**  
4.5 États de chargement/erreur — **À faire**

### 3.5 Détail film/série/saga/personne

5.x / 6.x / 7.x / 8.x — **Structure des pages présentes sous `features/*/presentation`, mais entièrement à implémenter (data + UI)**

### 3.6 Bibliothèque & Paramètres

9.1–9.5 Bibliothèque — **Placeholders, logique à implémenter**  
10.1–10.5 Paramètres — **Placeholders, gestion prefs à définir**

### 3.7 Données & synchronisation (Data Layer — État & TODO)

- Core storage — État
  - OK: `content_cache`, `watchlist`, `continue_watching`, `history` tables + repos (`lib/src/core/storage/repositories/*`).
  - OK: TTL via `CachePolicy`, migrations SQLite v3.
  - OK: IPTV cache local + TTL snapshots + service de sync planifiée.

- Movies — État
  - OK: remote (`TmdbMovieRemoteDataSource`), local (`MovieLocalDataSource`), repo offline‑first, watchlist, continue_watching.
  - TODO: tests unitaires repo (succès/fallback).

- TV — État
  - OK: remote/local, repo offline‑first, continue_watching.
  - TODO: implémenter `getUserWatchlist()` via `WatchlistLocalRepository.readAll(ContentType.series)` → `TvShowSummary` (fallback sans réseau). Fichier: `lib/src/features/tv/data/repositories/tv_repository_impl.dart`.
  - TODO: tests unitaires repo.

- Persons — État
  - OK: remote/local, repo offline‑first, DI.
  - TODO: tests unitaires (repo + DS locale, erreurs mappées).

- Sagas — État
  - OK: remote/local, repo offline‑first (enrichissement runtime), DI.
  - Décision produit: pas de "featured sagas". Méthode supprimée; garder `getSaga`, `searchSagas`, `getUserSagas`.
  - TODO: implémenter `getUserSagas(userId)` si nécessaire + tests repo.

- Search — État
  - TODO: data layer non implémentée (datasources/dtos/repositories vides). Concevoir un repo d’agrégation inter-features (movie/tv/person/saga) + pagination.

- Playlists — État
  - TODO: data layer absente. Définir stockage local (table playlists + items), repo (CRUD, ordre), data module, mapping domain.

- Home/Library — État
  - TODO: pas de repo d’agrégation (HomeFeed/Library). Concevoir un service data qui compose: continue_watching, watchlist, featured, recommandations.

- Qualité
  - TODO: compléter tests unitaires ciblés (Person/Saga/Movie/TV + dépôts locaux), éviter dépendances UI.
  - TODO: valider erreurs réseau → types internes (pas d’exceptions brutes) sur tous les repos.

### 3.8 Qualité & déploiement

13.1 Tests unitaires/widget/integration — **À écrire**  
13.2 Automatisation CI/CD — **Débuté (Codemagic) ; pipeline complet à étendre**  
13.3 Environnements (staging/prod) — **Non défini**  
13.4 Performance build — **À surveiller**  
13.5 Support post-lancement — **À documenter**

### 3.9 Lancements incrémentaux

14.1 Jalons (MVP, bêtas) — **À formaliser**  
14.2 Communication produit — **À définir**  
14.3 Collecte feedback — **À définir**  
14.4 Itérations roadmap — **En attente de données**  
14.5 Documentation des apprentissages — **Démarrée (questions + overview)**

## 4. Prochaines actions recommandées

1. Implémenter `TV.getUserWatchlist()` (local only) et `Saga.getFeaturedSagas()/getUserSagas()`; ajouter tests.  
2. Concevoir/implémenter la data layer de Search (agrégation TMDB).  
3. Concevoir/implémenter la data layer de Playlists (tables + repo + DI).  
4. Créer un `HomeFeedRepository` qui compose continue_watching, watchlist, featured et recommandations.  
5. Étendre la couverture de tests (repos + dépôts locaux) et brancher vérifications dans CI.
