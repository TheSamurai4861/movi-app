Voici le “best of” entre ton plan et le code réel, avec un plan de fix clair par point.

Je pars de TON plan et j’indique où il est déjà couvert par le code, où on l’allège, et ce qu’il faut vraiment changer.

---

## 1. Distribution — images acteurs cassées

### Ce que dit ton plan

> Mapping actuel vers `MoviPerson` ignore la photo.

✅ Exact, et bien repéré.

### Ce que dit le code

* `PersonSummary` transporte déjà la photo TMDB via `photo` :

```dart
class PersonSummary extends Equatable {
  const PersonSummary({
    required this.id,
    this.tmdbId,
    required this.name,
    this.role,
    this.photo,
  });

  final PersonId id;
  final int? tmdbId;
  final String name;
  final String? role;
  final Uri? photo;
}
```

* Le repo movie mappe correctement cast & directors vers `PersonSummary.photo` :

```dart
PersonSummary _mapCast(TmdbMovieCastDto cast) {
  return PersonSummary(
    id: PersonId(cast.id.toString()),
    tmdbId: cast.id,
    name: cast.name,
    role: cast.character,
    photo: _images.poster(cast.profilePath), // ✅ ok
  );
}
```

* **Mais** dans le ViewModel :

```dart
final cast = credits
    .map((p) => MoviPerson(
          id: p.id.value,
          name: p.name,
          role: p.role ?? '-',
          // ❌ poster ignoré ici
        ))
    .toList(growable: false);
```

* `MoviPersonCard` attend bien `person.poster` (sinon placeholder).

### Plan de fix (très simple, fidèle à ton plan)

**Fichier** : `lib/src/features/movie/presentation/models/movie_detail_view_model.dart`

```dart
final cast = credits
    .map((p) => MoviPerson(
          id: p.id.value,
          name: p.name,
          role: p.role ?? '-',
          poster: p.photo, // ✅ utiliser l’URI TMDB déjà résolue
        ))
    .toList(growable: false);
```

> Tu n’as **rien à changer** côté DTO ni repo pour les personnes : ton plan le mentionne, mais c’est déjà fait (crew a bien `profile_path` → `photo`).

---

## 2. Rating — note TMDB non affichée

### Ce que dit ton plan

* Ajouter `voteAverage` au domaine `Movie`.
* Le mapper depuis `TmdbMovieDetailDto`.
* L’utiliser dans le ViewModel pour formatter `ratingText`.

💯 On garde exactement ça.

### Ce que dit le code

* DTO :

```dart
final double? voteAverage;
```

* Entité `Movie` **n’a pas** `voteAverage` pour l’instant :

```dart
class Movie extends Equatable {
  const Movie({
    required this.id,
    this.tmdbId,
    required this.title,
    required this.synopsis,
    required this.duration,
    required this.poster,
    this.backdrop,
    required this.releaseDate,
    this.rating,          // ContentRating
    required this.genres,
    required this.cast,
    required this.directors,
    this.tags = const [],
    this.sagaLink,
  });

  final ContentRating? rating; // pg, pg13, ...
}
```

* Repo mappe déjà un `ContentRating` interne depuis `voteAverage` :

```dart
ContentRating? _mapRating(double? voteAverage) {
  if (voteAverage == null) return null;
  if (voteAverage >= 8.0) return ContentRating.pg13;
  if (voteAverage >= 5.0) return ContentRating.pg;
  return ContentRating.unrated;
}
```

* ViewModel :

```dart
return MovieDetailViewModel(
  ...
  ratingText: '-', // ❌ hardcodé
  ...
);
```

### Plan de fix

#### 2.1. Étendre `Movie` avec `voteAverage`

**Fichier** : `lib/src/features/movie/domain/entities/movie.dart`

```dart
class Movie extends Equatable {
  const Movie({
    required this.id,
    this.tmdbId,
    required this.title,
    required this.synopsis,
    required this.duration,
    required this.poster,
    this.backdrop,
    required this.releaseDate,
    this.rating,
    this.voteAverage,           // ✅ nouveau
    required this.genres,
    required this.cast,
    required this.directors,
    this.tags = const [],
    this.sagaLink,
  });

  final ContentRating? rating;
  final double? voteAverage;    // ✅

  @override
  List<Object?> get props => [
    id,
    tmdbId,
    title,
    synopsis,
    duration,
    poster,
    backdrop,
    releaseDate,
    rating,
    voteAverage,                // ✅
    genres,
    cast,
    directors,
    tags,
    sagaLink,
  ];
}
```

#### 2.2. Mapper `voteAverage` dans le repo

**Fichier** : `lib/src/features/movie/data/repositories/movie_repository_impl.dart`

Dans `_mapDetail` :

```dart
return Movie(
  id: MovieId(dto.id.toString()),
  tmdbId: dto.id,
  title: MediaTitle(dto.title),
  synopsis: Synopsis(dto.overview),
  duration: Duration(minutes: dto.runtime ?? 0),
  poster: poster,
  backdrop: backdrop,
  releaseDate:
      _parseDate(dto.releaseDate) ?? DateTime.fromMillisecondsSinceEpoch(0),
  rating: _mapRating(dto.voteAverage),
  voteAverage: dto.voteAverage,       // ✅ ici
  genres: dto.genres,
  cast: dto.cast.take(10).map(_mapCast).toList(),
  directors: dto.directors.map(...).toList(),
  tags: dto.genres,
  sagaLink: _mapSagaLink(dto),
);
```

#### 2.3. Formatage dans le ViewModel (pills)

**Fichier** : `lib/src/features/movie/presentation/models/movie_detail_view_model.dart`

```dart
return MovieDetailViewModel(
  title: detail.title.display,
  yearText: detail.releaseDate.year.toString(),
  durationText: '${h}h ${mn}m',
  ratingText: detail.voteAverage != null
      ? (detail.voteAverage! >= 10
          ? detail.voteAverage!.toStringAsFixed(0)
          : detail.voteAverage!.toStringAsFixed(1))  // ✅ ton format
      : '—',
  overviewText: detail.synopsis.value,
  cast: cast,
  recommendations: recos,
  poster: detail.poster,
  backdrop: detail.backdrop,
  language: language,
);
```

> Ça respecte ton objectif : note TMDB, arrondi 1 décimale (sauf 10 → entier), affichée dans la pill.

---

## 3. Hero image — alignement avec l’accueil

Tu proposes un truc assez ambitieux (util partagé + fetch images dédié).
Vu le code actuel, on peut faire **plus simple** pour le même résultat.

### Ce que fait déjà le backend

* `TmdbMovieDetailDto.fromJson` gère déjà la sélection d’un **poster “background”** avec logique `iso_639_1=null → en → first ok` via `_selectPosterBackground`.
* `MovieRepositoryImpl._mapDetail` :

```dart
final posterCandidate = dto.posterBackground ?? dto.posterPath;
final poster = _images.poster(posterCandidate, size: 'w342'); // ✅ déjà via TmdbImageResolver
final backdrop = _images.backdrop(dto.backdropPath);
...
return Movie(
  ...
  poster: poster,
  backdrop: backdrop,
  ...
);
```

* `MovieDetailViewModel` transporte déjà `poster` et `backdrop` :

```dart
final Uri? poster;
final Uri? backdrop;

poster: detail.poster,
backdrop: detail.backdrop,
```

👉 Donc la **sélection d’image** type “poster-no-lang, fallback backdrop” est déjà couverte côté data.
Le **seul problème** : la page détail n’affiche jamais ces images dans le hero.

### Ce que fait aujourd’hui la page détail

Dans `MovieDetailPage._buildWithValues` :

* Le hero ne contient que :

```dart
Container(color: AppColors.darkSurface), // pas d'image
// + overlays dégradés
```

### Plan de fix (simplifié vs ton plan, mais cohérent)

On garde ton intention (“poster-no-lang, fallback backdrop”) mais **sans** rajouter un fetch images ou un util global : on a déjà les URIs.

1. **Étendre `_buildWithValues` pour recevoir `poster`/`backdrop`**

```dart
Widget _buildWithValues({
  required String mediaTitle,
  required String yearText,
  required String durationText,
  required String ratingText,
  required String overviewText,
  required List<MoviPerson> cast,
  required List<MoviMedia> recommendations,
  required bool isLoading,
  Uri? poster,     // ✅
  Uri? backdrop,   // ✅
})
```

Dans `build()` :

```dart
return vmAsync.when(
  loading: () => _buildWithValues(
    mediaTitle: mediaTitle,
    yearText: yearText,
    durationText: '—',
    ratingText: ratingText,
    overviewText: '',
    cast: const [],
    recommendations: const [],
    isLoading: true,
    poster: widget.media?.poster, // fallback IPTV pendant le chargement
    backdrop: null,
  ),
  error: (e, st) => _buildErrorScaffold(e),
  data: (vm) => _buildWithValues(
    mediaTitle: vm.title,
    yearText: vm.yearText,
    durationText: vm.durationText,
    ratingText: vm.ratingText,
    overviewText: vm.overviewText,
    cast: vm.cast,
    recommendations: vm.recommendations,
    isLoading: false,
    poster: vm.poster,
    backdrop: vm.backdrop,
  ),
);
```

2. **Dessiner l’image dans le hero**

Ajouter un helper :

```dart
Widget _buildHeroImage(Uri? poster, Uri? backdrop) {
  // poster-no-lang, fallback backdrop
  final uri = poster ?? backdrop;
  if (uri == null) {
    return Container(color: AppColors.darkSurface);
  }
  return Image.network(
    uri.toString(),
    fit: BoxFit.cover,
    gaplessPlayback: true,
    filterQuality: FilterQuality.low,
  );
}
```

Et dans le `Stack` du hero :

```dart
SizedBox(
  height: heroHeight,
  width: double.infinity,
  child: Stack(
    fit: StackFit.expand,
    children: [
      _buildHeroImage(poster, backdrop),  // ✅ image réelle
      // overlays bas & haut déjà présents
    ],
  ),
),
```

> Tu obtiens un comportement très proche du hero d’accueil sans alourdir la couche data / providers (l’algorithme de sélection d’image est déjà dans `TmdbMovieDetailDto` + `TmdbImageResolver`).

---

## 4. Bottom Nav Bar — visibilité

Ton plan :

> SafeArea bottom: true + s’assurer que le scroll ne recouvre pas la nav.

### Ce que fait le code maintenant

Dans `MovieDetailPage` :

```dart
return Scaffold(
  backgroundColor: cs.surface,
  body: SafeArea(
    top: true,
    bottom: false,              // ❌ bottom désactivé
    child: Opacity(
      ...
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(...),
          ),
          const SizedBox(height: 0),
          MoviBottomNavBar(...), // en bas de la Column
        ],
      ),
    ),
  ),
);
```

* Le scroll ne recouvre pas la nav (elle est en dehors de l’`Expanded`), donc ça va.
* Mais avec `bottom: false`, la nav peut se retrouver **trop bas** sur certains devices (gestures / safe area).

### Plan de fix (minimal + alignement UX)

**Option minimaliste (collée à ton plan)**

* Passer `bottom: true` :

```dart
body: SafeArea(
  top: true,
  bottom: true,  // ✅
  child: ...
),
```

* Garder la `Column` telle quelle : le `SingleChildScrollView` reste dans l’`Expanded` au-dessus, la nav en bas du `SafeArea`.

**Option “alignée Home” (recommandée pour cohérence)**

Copier le pattern de `HomePage` :

* `Stack` avec :

  * `Positioned.fill` contenant le contenu scrollable,
  * `Positioned` pour la nav flottante avec padding latéral + `media.padding.bottom`.

Ça donne une nav **flottante**, même style que sur l’accueil, et garantit sa visibilité.

Si tu veux rester simple pour l’instant :
➡️ active `bottom: true` maintenant, et tu pourras faire le refacto “Stack + Positioned” dans une passe UI ultérieure.

---

## Récap du plan de fix final (compact)

1. **Cast (images acteurs)**

   * [ ] Dans `MovieDetailViewModel.fromDomain`, passer `poster: p.photo` à `MoviPerson`.

2. **Rating (note TMDB)**

   * [ ] Ajouter `double? voteAverage` dans `Movie`.
   * [ ] Le mapper depuis `dto.voteAverage` dans `MovieRepositoryImpl._mapDetail`.
   * [ ] Calculer `ratingText` à partir de `detail.voteAverage` dans `MovieDetailViewModel.fromDomain` (avec ton format >=10 → 0 décimales, sinon 1).

3. **Hero image**

   * [ ] Étendre `_buildWithValues` pour accepter `poster`/`backdrop`.
   * [ ] Passer `widget.media?.poster` au loading, puis `vm.poster`/`vm.backdrop` en data.
   * [ ] Dessiner le fond avec `Image.network` dans le hero (`poster ?? backdrop`).

4. **Bottom Nav Bar**

   * [ ] Mettre `SafeArea(bottom: true)` dans `MovieDetailPage`.
   * [ ] (Optionnel mais souhaitable) aligner le layout nav sur `HomePage` (Stack + Positioned).

Si tu veux, je peux t’écrire ensuite le diff complet pour **un fichier à la fois** (par ex. `movie_detail_view_model.dart` puis `movie_detail_page.dart`) pour que tu puisses juste coller.
