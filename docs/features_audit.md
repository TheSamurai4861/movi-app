# Audit du dossier `lib/src/features`

## Diagnostic global
- L’architecture Clean est amorcée (data/domain/presentation), mais chaque feature l’applique différemment : certaines n’ont pas de usecases, d’autres contiennent encore de la logique data dans la présentation.
- Deux patterns de DI cohabitent (GetIt et Riverpod) sans frontière claire : la présentation puise directement dans le service locator global, ce qui rend les contrôleurs difficiles à tester et à remplacer.
- Le code lié à l’IPTV est dupliqué dans Home, Category Browser et Search ; chaque module reformate lui-même les playlists, ce qui introduit du couplage transversal et des incohérences de mapping.
- Plusieurs éléments du domaine dépendent directement des repositories locaux `storage` (ex.: watchlist, history), ce qui casse la séparation clean architecture et limite les scénarios offline/tests.
- Des contrôleurs Riverpod très volumineux (Home, Search, IPTV connect) portent des responsabilités réseau, cache, cancellation et navigation, produisant des fichiers de plusieurs centaines de lignes difficiles à maintenir.

## Problèmes majeurs

### 1. Logique métier et technique logée dans la présentation Home
- **Ce qui ne va pas** : `HomeController` orchestre la concurrence réseau, la fusion de patches et la récupération des sections (`lib/src/features/home/presentation/providers/home_providers.dart:57-304`). Les appels à `HomeFeedRepository` sont faits directement depuis la présentation, et le provider déclenche `..load()` lors de sa création.
- **Pourquoi c’est problématique** : la présentation dépend d’implémentations techniques (CancelToken, LoggingService) et devient impossible à tester sans réseau ou TMDB. Tout changement de stratégie (priorités, limitation, logs) oblige à modifier la couche UI.
- **Solution clean & scalable** : introduire de vrais usecases côté domaine (`LoadHero`, `LoadContinueWatching`, `LoadIptvSections`, `EnrichCategoryWindow`) qui encapsulent la logique d’orchestration. Le `HomeController` n’orchestrera que des `AsyncValue`/`State` issus de ces usecases. Relancer `load()` doit passer par une méthode publique et non via un side-effect dans le provider.
- **Impact attendu** : contrôleur raccourci, tests unitaires possibles sur les usecases, possibilité de réutiliser la logique (ex. rafraîchir depuis IPTV connect) sans dépendance directe à la présentation.

### 2. Couplage transversal des features via les artefacts IPTV
- **Ce qui ne va pas** : `CategoryLocalDataSource` importe un type interne de Home (`home_feed_repository_impl.dart` via `show XtreamAccountLite`, lignes `8-63`) et duplique toutes les fonctions `_safeGetAccounts`, `_cleanCategoryTitle`, `_safePosterUri`. `SearchRepositoryImpl` lit lui-même les playlists `IptvLocalRepository` et recompose des `MovieSummary`/`TvShowSummary` (`lib/src/features/search/data/search_repository_impl.dart:33-156`). `IptvConnectController` notifie directement `homeControllerProvider` (`lib/src/features/settings/presentation/providers/iptv_connect_providers.dart:73-81`).
- **Pourquoi c’est problématique** : modifications du stockage IPTV ou de la manière de nettoyer les catégories nécessitent de mettre à jour trois features. Les tests d’intégration doivent instancier toute la feature Home pour vérifier Category Browser. Les cross-imports brisent la modularité.
- **Solution clean & scalable** : extraire un service `IptvCatalogReader` unique (par ex. dans `lib/src/features/iptv/application/`) qui expose des projections (`listAccounts`, `listCategoryItems`, `searchCatalog`). Les features consomment ce service via leurs usecases, sans jamais connaître `IptvLocalRepository`. Faire remonter les notifications (refresh Home) via un bus/app-layer (`AppStateController`, `StatefulShell`) plutôt qu’en lisant la Home directement.
- **Impact attendu** : suppression des imports transverses, consolidations des règles de mapping, réduction de la duplication et alignement naturel entre Home, Search et Category Browser.

### 3. Mélange Riverpod/GetIt et dépendances globales dans les contrôleurs
- **Ce qui ne va pas** : la plupart des providers exposent directement des singletons GetIt (`searchRepositoryProvider`, `homeFeedRepositoryProvider`, `libraryRepositoryProvider`, etc.) et plusieurs fichiers importent `flutter_riverpod/legacy.dart` uniquement pour `StateNotifier`. De plus, certains providers exécutent du code au moment de l’initialisation (`homeControllerProvider` avec `..load()`, `UserSettingsController` qui lance `load()` dans le constructeur)
- **Pourquoi c’est problématique** : impossible de mocker proprement via `ProviderScope` sans reconfigurer GetIt ; les side-effects déclenchés dans les constructeurs compliquent les tests widget et peuvent s’exécuter plusieurs fois lors des hot-reload. L’import `legacy` sera supprimé dans Riverpod 3.
- **Solution clean & scalable** : inverser la dépendance : créer des `Provider` Riverpod pour chaque interface (en remontant les instances GetIt via `ProviderContainer.read(slProvider)` ou en basculant entièrement vers Riverpod pour la DI). Déplacer les chargements initiaux dans `ref.listen`/`AsyncNotifier` plutôt que dans les constructeurs. Migrer vers `riverpod_annotation` ou `StateNotifier` depuis `package:state_notifier` pour supprimer `flutter_riverpod/legacy.dart`.
- **Impact attendu** : testabilité accrue (override facile des providers), suppression de comportements non déterministes au hot-reload, migration fluide vers les futures versions de Riverpod.

### 4. Domaine dépendant d’implémentations `storage`
- **Ce qui ne va pas** : les usecases `LikePerson`/`UnlikePerson` importent `package:movi/src/core/storage/storage.dart` et manipulent directement `WatchlistLocalRepository` (`lib/src/features/library/domain/usecases/like_person.dart:1-24`). Les repositories domaine de Library agrègent `WatchlistLocalRepository`, `HistoryLocalRepository`, `PlaylistRepository` directement (`lib/src/features/library/data/repositories/library_repository_impl.dart`).
- **Pourquoi c’est problématique** : la couche domain connaît les détails de persistance et ne peut pas être testée sans base SQLite. On ne peut pas brancher de source distante (cloud sync) ni injecter un faux repository.
- **Solution clean & scalable** : définir des interfaces domain (ex. `FavoritesRepository`, `HistoryRepository`) et déplacer les dépendances `storage` dans l’implémentation data. Les usecases ne manipulent que ces interfaces. On garde `WatchlistLocalRepository` dans `lib/src/features/library/data/datasources`.
- **Impact attendu** : un domaine découplé réutilisable (ex. pour expose API), scénarios offline/online plus simples et tests unitaires rapides.

### 5. Fichiers monolithiques et responsabilités multiples (Search & Settings)
- **Ce qui ne va pas** : `search_providers.dart` combine providers DI, deux contrôleurs, deux `State` et toute la logique de pagination (>350 lignes). `IptvConnectController` traite UI state, logique métier (activation des sources) et navigation (rafraîchissement Home).
- **Pourquoi c’est problématique** : revues difficiles, effets secondaires cachés, duplication de patterns (timers de debounce, traitement d’erreurs). Toute modification de pagination impose de relire un gros fichier.
- **Solution clean & scalable** : découper par responsabilité (ex.: `search/application/search_controller.dart`, `search/presentation/providers/search_list_provider.dart`). Introduire des usecases `SearchInstant` et `SearchPaginated`. Pour IPTV connect, déplacer la logique métier dans un service/application qui expose un `Result` et laisse la présentation réagir.
- **Impact attendu** : code auto-documenté, couverture test améliorée et onboarding simplifié pour de nouvelles features (ex.: suggestions, historiques).

## Liste d’améliorations ciblées
- Isoler toute la lecture des playlists IPTV dans un service commun (conversion → `ContentReference`, clean title, poster safe) et le partager entre Home, Category Browser et Search.
- Introduire des usecases explicites pour Home (load hero, load CW, enrich IPTV window) et faire dépendre la présentation de ces usecases plutôt que des repositories.
- Remplacer l’import `flutter_riverpod/legacy.dart` par `package:state_notifier/state_notifier.dart` ou `AsyncNotifier`, et supprimer les side-effects dans les constructeurs.
- Redéfinir les interfaces domaine pour la bibliothèque (favorites/history) afin que les usecases ne dépendent plus de `storage`.
- Séparer les providers Search en modules plus petits (providers de dépendances, contrôleurs instantanés, contrôleur paginé) et alléger la pagination (state `AsyncValue`, requêtes via usecase paginé qui renvoie `SearchPage`).
- Mettre en place un canal d’événements (ex.: `AppStateController`, `EventBus`) pour signaler les rafraîchissements Home après une synchro IPTV plutôt que d’accéder directement aux providers d’une autre feature.

## Plan d’action final

### Priorité (impact décroissant)
| # | Étape | Impact | Effort | Risque |
|---|-------|--------|--------|--------|
| 1 | Extraire `IptvCatalogReader` + suppr. des imports transverses dans Home/Category/Search | 🌟🌟🌟 | 🌟🌟 | Moyen (touches plusieurs features) |
| 2 | Introduire des usecases Home + simplifier `HomeController` (pas d’I/O direct) | 🌟🌟🌟 | 🌟🌟🌟 | Moyen (nécessite refactoring state) |
| 3 | Refactor DI (providers dédiés, suppression `legacy`, pas de side-effects constructeur) | 🌟🌟 | 🌟🌟 | Faible |
| 4 | Redéfinir les contrats domain pour Library (favorites/history) et adapter les usecases | 🌟🌟 | 🌟 | Faible |
| 5 | Scinder Search providers (instant vs paginé) + encapsuler la pagination dans des usecases | 🌟 | 🌟🌟 | Faible |
| 6 | Remplacer l’appel direct à `homeControllerProvider` depuis IPTV Connect par un événement/app-service | 🌟 | 🌟 | Très faible |

### Mode "low risk first"
1. Refactor DI.
2. Isoler l’événement de rafraîchissement Home (débrancher la dépendance directe).
3. Introduire les interfaces domain Library puis adapter les usecases existants.
4. Extraire `IptvCatalogReader` (après DI stabilisée).
5. Refondre Home (nouveaux usecases) puis Search.

## Exemples de code amélioré

### 1. Factorisation de la lecture IPTV (avant/après)
**Avant** (`lib/src/features/category_browser/data/datasources/category_local_data_source.dart:8-63`)
```dart
import 'package:movi/src/features/home/data/repositories/home_feed_repository_impl.dart'
    show XtreamAccountLite; // reuse lite projection
...
final accounts = await _safeGetAccounts();
final playlist = playlists.where((pl) => _cleanCategoryTitle(pl.title) == cleaned).first;
```

**Après** (nouveau service `lib/src/features/iptv/application/iptv_catalog_reader.dart` utilisé par Home/Categories/Search)
```dart
class IptvCatalogReader {
  const IptvCatalogReader(this._local);
  final IptvLocalRepository _local;

  Future<List<ContentReference>> listCategory(CategoryKey key) async {
    final playlist = await _local.findPlaylist(alias: key.alias, title: key.title);
    return playlist.items.map(_toReference).toList(growable: false);
  }

  ContentReference _toReference(XtreamPlaylistItem it) => ContentReference(
        id: it.tmdbId?.toString() ?? 'xtream:${it.streamId}',
        title: MediaTitle(it.title),
        type: it.type == XtreamPlaylistItemType.series
            ? ContentType.series
            : ContentType.movie,
        poster: PosterSanitizer.ensureHttps(it.posterUrl),
        year: it.releaseYear,
        rating: it.rating,
      );
}
```
Les features consomment désormais `IptvCatalogReader` via leurs propres usecases, aucun import croisé n’est nécessaire.

### 2. Séparation usecase/contrôleur Home
**Avant** (`lib/src/features/home/presentation/providers/home_providers.dart:303-305`)
```dart
final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) => HomeController(ref.read(homeFeedRepositoryProvider))..load(),
);
```
Le contrôleur déclenche `load()` au constructeur et contient toute la logique réseau.

**Après** (pseudo-code)
```dart
final loadHomeFeedProvider = Provider((ref) => LoadHomeFeed(ref.watch(homeFeedRepositoryProvider)));

final homeControllerProvider = AsyncNotifierProvider<HomeController, HomeState>(HomeController.new);

class HomeController extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    final loadHome = ref.watch(loadHomeFeedProvider);
    final hero = await loadHome.hero();
    final cw = await Future.wait([loadHome.movies(), loadHome.shows()]);
    return HomeState(hero: hero, cwMovies: cw[0], cwShows: cw[1]);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}
```
La logique métier reste dans `LoadHomeFeed`, le contrôleur ne gère plus que l’état, ce qui simplifie drastiquement les tests.
