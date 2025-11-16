# Plan de correctifs — Page Détails Film

## Constat
- Images acteurs non affichées (poster manquant dans cartes personnes)
  - Mapping actuel vers `MoviPerson` ignore la photo: `lib/src/features/movie/presentation/models/movie_detail_view_model.dart:41-46`
- Note (rating) non récupérée dans la fiche
  - `ratingText` est fixé à `'-'`: `lib/src/features/movie/presentation/models/movie_detail_view_model.dart:60-61`
  - Domaine `Movie` ne transporte pas la moyenne TMDB (`vote_average`)
- Image Hero (fond) de la page détail n’utilise pas la même logique que le Hero d’accueil
  - Accueil: requête séparée `movie/{id}/images` + sélection `iso_639_1=null → en → best`: `lib/src/features/home/presentation/widgets/home_hero_section.dart:147-163`, `:620-648`
  - Détail: pas d’image de fond dédiée dans `MovieDetailPage` (seulement overlays): `lib/src/features/movie/presentation/pages/movie_detail_page.dart:176-225`
- Barre de navigation inférieure
  - Présente dans la page, mais risque d’être masquée par layout: `lib/src/features/movie/presentation/pages/movie_detail_page.dart:493-512`

## Objectifs
- Afficher les photos des acteurs et réalisateurs dans "Distribution"
- Afficher la note TMDB (arrondi à 1 décimale) dans les pills
- Afficher un fond Hero cohérent (poster-no-lang, fallback backdrop) comme l’accueil
- Garantir la visibilité de la Bottom Nav Bar sur la page détail

## Plan d’implémentation
1) Distribution — Corrections d’images
- Passer la `photo` du `PersonSummary` au `MoviPerson.poster` dans le ViewModel
  - Modifier `MovieDetailViewModel.fromDomain`: `lib/src/features/movie/presentation/models/movie_detail_view_model.dart:41-55`
    - Ajouter `poster: p.photo` dans la construction `MoviPerson`
- Directors: s’assurer de récupérer `profile_path` côté DTO et le mapper
  - DTO crew enrichi avec `profile_path`: `lib/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart:290-305`
  - Mapping vers `PersonSummary.photo`: `lib/src/features/movie/data/repositories/movie_repository_impl.dart:141-149`

2) Rating — Numérique TMDB
- Étendre `Movie` pour transporter `double? voteAverage`
  - Fichier: `lib/src/features/movie/domain/entities/movie.dart`
  - Ajouter champ `voteAverage` et l’intégrer à `props`
- Mapper depuis DTO
  - `MovieRepositoryImpl._mapDetail`: `lib/src/features/movie/data/repositories/movie_repository_impl.dart:128-154`
  - Ajouter `voteAverage: dto.voteAverage`
- ViewModel: afficher `ratingText`
  - `MovieDetailViewModel.fromDomain`: `lib/src/features/movie/presentation/models/movie_detail_view_model.dart:56-67`
  - Calculer: `ratingText = (detail.voteAverage != null) ? (detail.voteAverage! >= 10 ? detail.voteAverage!.toStringAsFixed(0) : detail.voteAverage!.toStringAsFixed(1)) : '—'`

3) Hero image — Alignement avec Hero Accueil
- Extraire le sélecteur d’images du widget accueil vers un util partagé
  - Nouveau util: `lib/src/shared/utils/image_selector.dart` (fonctions `selectPoster`, `selectLogo`)
  - Remplacer les appels internes dans `home_hero_section.dart` par util partagé
- Détail: charger images si nécessaires
  - Provider `movieDetailControllerProvider`: `lib/src/features/movie/presentation/providers/movie_detail_providers.dart:10-33`
    - Après `getMovie`, effectuer un fetch des images si `backdrop/poster_background` manquants (via `TmdbMovieRemoteDataSource.fetchMovieFull`)
    - Sélectionner poster/no-lang via util partagé; passer l’URI au ViewModel
  - ViewModel: ajouter champs optionnels `heroPoster`/`heroBackdrop` et les consommer dans `MovieDetailPage`
- UI: rendu fond Hero
  - `MovieDetailPage`: `lib/src/features/movie/presentation/pages/movie_detail_page.dart`
    - Dans le Stack du hero (lignes `176-225`), insérer un `Image.network` similaire à l’accueil (cacheWidth limité) avec l’URI résolu

4) Bottom Nav Bar — Visibilité
- SafeArea: activer le `bottom: true` pour éviter le recouvrement
  - `lib/src/features/movie/presentation/pages/movie_detail_page.dart:115-118`
- S’assurer que le `SingleChildScrollView` n’occupe pas tout l’espace sous la nav
  - Conserver la nav en dehors de l’`Expanded` (déjà le cas `493-512`), vérifier z-order et padding bas

## Validation
- Charger un film avec cast et crew disposant de `profile_path` et vérifier:
  - Cartes "Distribution" affichent des images (pas de placeholder)
  - Pill rating affiche une valeur numérique avec une décimale
  - Fond Hero est visible et bascule poster→backdrop selon disponibilité
  - Bottom Nav Bar est visible et cliquable
- Vérifier en `fr-FR` et `en-US` que la sélection d’images respecte `iso_639_1=null → en → best`

## Notes d’implémentation
- Respect CLEAN Architecture: mapping et parsing côté `data`, entités stables côté `domain`, ViewModel adapte l’affichage
- Ne pas logguer de payloads sensibles; limiter tailles images (`cacheWidth`) pour performance Desktop