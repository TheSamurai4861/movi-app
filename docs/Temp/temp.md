## 1. Analyse rapide

Pour **vraiment finaliser** P0.1, je n’ai pas besoin de tout le projet. J’ai surtout besoin des **implémentations concrètes qui remplaceront les dépendances interdites de `core`**, plus du **wiring DI** qui les enregistrera.
À partir de l’arborescence, les zones critiques sont bien :

* `features/iptv` pour la source des candidats contenu
* `features/movie` pour le resolver film
* `features/tv` pour le resolver série
* `core/di` pour brancher les nouveaux ports
* possiblement `shared` si le projet a déjà un service générique de résolution TMDB réutilisable 

## 2. Règles de `rules.md` appliquées

* dépendre d’abstractions, pas d’implémentations concrètes
* garder le métier interne protégé des détails externes
* réduire le couplage
* réutiliser les patterns existants avant d’inventer une nouvelle abstraction 

## 3. Modifications proposées

### Ce qu’il me faut au minimum

#### 1) IPTV — pour finaliser `ContentCandidateRepository`

J’ai besoin de ces dossiers/fichiers :

* `lib/src/features/iptv/domain/entities/`
* `lib/src/features/iptv/application/`
* `lib/src/features/iptv/data/`
* `lib/src/core/storage/repositories/iptv_local_repository.dart`

Pourquoi :

* comprendre la vraie forme de `xtream_playlist_item.dart`
* voir si la meilleure source des candidats est `IptvLocalRepository`, un reader applicatif, ou un mapper déjà existant
* éviter de reconstruire une normalisation IPTV qui existe déjà ailleurs

#### 2) Movie — pour finaliser `MovieMetadataResolver`

J’ai besoin de :

* `lib/src/features/movie/data/datasources/`
* `lib/src/features/movie/data/repositories/`
* `lib/src/features/movie/domain/`
* idéalement `lib/src/features/movie/data/movie_data_module.dart`

Pourquoi :

* voir l’API exacte de `tmdb_movie_remote_data_source.dart`
* savoir s’il existe déjà un repository/service plus propre que la datasource brute
* enregistrer l’adaptateur concret au bon endroit 

#### 3) TV — pour finaliser `SeriesMetadataResolver`

J’ai besoin de :

* `lib/src/features/tv/data/datasources/`
* `lib/src/features/tv/data/repositories/`
* `lib/src/features/tv/domain/`
* idéalement `lib/src/features/tv/data/tv_data_module.dart`

Pourquoi :

* même logique que pour Movie
* éviter que l’adaptateur série dépende lui aussi d’un détail mal choisi 

#### 4) DI / composition root — indispensable

J’ai besoin de :

* `lib/src/core/di/injector.dart`
* si séparés, les modules :

  * `lib/src/features/movie/data/movie_data_module.dart`
  * `lib/src/features/tv/data/tv_data_module.dart`
  * `lib/src/features/iptv/data/iptv_data_module.dart`

Pourquoi :

* brancher les nouveaux ports :

  * `ParentalContentCandidateRepository`
  * `MovieMetadataResolver`
  * `SeriesMetadataResolver`
  * `ContentRatingWarmupGateway`
* éviter les fallback no-op et finaliser la vraie intégration

### Ce qui serait très utile en plus

#### 5) Shared — probablement réutilisable

Vu l’arborescence, il y a possiblement déjà des briques utiles ici :

* `lib/src/shared/domain/services/`
* `lib/src/shared/data/services/`

En particulier, je regarderais en priorité :

* `tmdb_id_resolver_service.dart`
* `iptv_content_resolver.dart`
* `iptv_content_resolver_impl.dart`
* `xtream_lookup_service.dart`
* `similarity_service.dart`

Pourquoi :

* il est possible que le bon resolver concret ne soit **pas** les datasources Movie/TV directement
* si un service partagé résout déjà un titre IPTV vers un TMDB ID, ce sera plus propre de l’adapter vers les ports du parental que de dupliquer la logique 

