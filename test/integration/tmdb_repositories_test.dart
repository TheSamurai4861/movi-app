import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/config/config_module.dart';
import 'package:movi/src/core/config/env/dev_environment.dart';
import 'package:movi/src/core/config/services/secret_store.dart';
import 'package:movi/src/core/di/injector.dart';
import 'package:movi/src/core/di/test_injector.dart';
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
import 'package:movi/src/features/person/domain/repositories/person_repository.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import '../helpers/database_initializer.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase();
    final flavor = DevEnvironment();
    final secretStore = SecretStore();
    final config = await registerConfig(flavor: flavor, secretStore: secretStore);
    await initTestDependencies(appConfig: config, secretStore: secretStore);
  });

  group('TMDB integration', () {
    test('movie detail + credits + recommendations + search', () async {
      final repo = sl<MovieRepository>();
      final movie = await repo.getMovie(const MovieId('550')); // Fight Club
      expect(movie.title.value.isNotEmpty, isTrue);
      expect(movie.tmdbId, 550);
      expect(movie.poster.path.isNotEmpty, isTrue);
      expect(movie.cast, isNotEmpty);
      expect(movie.directors, isNotEmpty);

      final credits = await repo.getCredits(const MovieId('550'));
      expect(credits, isNotEmpty);
      expect(credits.first.role?.isNotEmpty ?? false, isTrue);

      final recommendations = await repo.getRecommendations(const MovieId('550'));
      expect(recommendations, isNotEmpty);

      final searchResults = await repo.searchMovies('matrix');
      expect(searchResults, isNotEmpty);

      // Watchlist toggles are local but part of repository contract.
      expect(await repo.isInWatchlist(const MovieId('550')), isFalse);
      await repo.setWatchlist(const MovieId('550'), saved: true);
      expect(await repo.isInWatchlist(const MovieId('550')), isTrue);
      await repo.setWatchlist(const MovieId('550'), saved: false);
      expect(await repo.isInWatchlist(const MovieId('550')), isFalse);
    });

    test('tv detail + seasons + search', () async {
      final repo = sl<TvRepository>();
      final show = await repo.getShow(const SeriesId('1399')); // Game of Thrones
      expect(show.title.value.isNotEmpty, isTrue);
      expect(show.tmdbId, 1399);
      expect(show.seasons, isNotEmpty);
      expect(show.seasons.first.episodes, isNotEmpty);

      final seasons = await repo.getSeasons(const SeriesId('1399'));
      expect(seasons, isNotEmpty);

      final episodes = await repo.getEpisodes(const SeriesId('1399'), SeasonId('1'));
      expect(episodes, isNotEmpty);

      final searchResults = await repo.searchShows('got');
      expect(searchResults, isNotEmpty);

      expect(await repo.isInWatchlist(const SeriesId('1399')), isFalse);
      await repo.setWatchlist(const SeriesId('1399'), saved: true);
      expect(await repo.isInWatchlist(const SeriesId('1399')), isTrue);
      await repo.setWatchlist(const SeriesId('1399'), saved: false);
      expect(await repo.isInWatchlist(const SeriesId('1399')), isFalse);
    });

    test('person detail + filmography + search', () async {
      final repo = sl<PersonRepository>();
      final person = await repo.getPerson(const PersonId('287')); // Brad Pitt
      expect(person.name.value.isNotEmpty, isTrue);
      expect(person.tmdbId, 287);
      expect(person.filmography, isNotEmpty);

      final filmography = await repo.getFilmography(const PersonId('287'));
      expect(filmography, isNotEmpty);

      final searchResults = await repo.searchPeople('brad');
      expect(searchResults, isNotEmpty);
    });

    test('saga detail + search', () async {
      final repo = sl<SagaRepository>();
      final saga = await repo.getSaga(const SagaId('10')); // Star Wars Collection
      expect(saga.title.value.isNotEmpty, isTrue);
      expect(saga.timeline, isNotEmpty);

      final searchResults = await repo.searchSagas('star');
      expect(searchResults, isNotEmpty);
    });
  });
}
