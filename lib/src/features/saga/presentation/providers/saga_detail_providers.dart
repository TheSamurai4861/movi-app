import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/state/app_state_provider.dart';
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/shared/domain/value_objects/synopsis.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/data/services/tmdb_client.dart';
import 'package:movi/src/features/saga/data/datasources/tmdb_saga_remote_data_source.dart';

/// Provider pour charger les détails d'une saga avec poster en langue null
final sagaDetailProvider = FutureProvider.family<SagaDetailViewModel, String>((ref, sagaId) async {
  final lang = ref.watch(currentLanguageCodeProvider);
  final remoteDataSource = ref.watch(slProvider)<TmdbSagaRemoteDataSource>();
  final images = ref.watch(slProvider)<TmdbImageResolver>();
  
  // Récupérer la saga avec la langue choisie
  final sagaIdInt = int.parse(sagaId);
  final dto = await remoteDataSource.fetchSaga(sagaIdInt, language: lang);
  
  // Construire la saga avec les métadonnées dans la langue choisie
  final saga = Saga(
    id: SagaId(sagaId),
    tmdbId: dto.id,
    title: MediaTitle(dto.name),
    synopsis: dto.overview.isEmpty ? null : Synopsis(dto.overview),
    cover: images.poster(dto.posterPath),
    timeline: dto.parts.map((part) {
      return SagaEntry(
        reference: ContentReference(
          id: part.id.toString(),
          title: MediaTitle(part.title),
          type: ContentType.movie,
          poster: images.poster(part.posterPath),
        ),
        timelineYear: _parseDate(part.releaseDate)?.year,
      );
    }).toList(),
    tags: const [],
    updatedAt: DateTime.now(),
  );
  
  // Récupérer le poster et backdrop en langue null
  Uri? posterWithNullLanguage;
  Uri? backdropWithNullLanguage;
  if (saga.tmdbId != null) {
    final imagesData = await _getImagesWithNullLanguage(saga.tmdbId!);
    posterWithNullLanguage = imagesData.poster;
    backdropWithNullLanguage = imagesData.backdrop;
  }
  
  // Utiliser le poster avec langue null si disponible, sinon le cover par défaut
  final poster = posterWithNullLanguage ?? saga.cover;
  
  // Calculer le nombre de films et la durée totale
  final movies = saga.timeline.where((entry) => entry.reference.type == ContentType.movie).toList();
  final movieCount = movies.length;
  
  // Calculer la durée totale (nécessite de récupérer les durées depuis TMDB)
  Duration totalDuration = Duration.zero;
  for (final entry in movies) {
    try {
      final movieId = int.tryParse(entry.reference.id);
      if (movieId != null) {
        final runtimeMinutes = await remoteDataSource.fetchMovieRuntime(movieId);
        if (runtimeMinutes != null && runtimeMinutes > 0) {
          totalDuration += Duration(minutes: runtimeMinutes);
        }
      }
    } catch (_) {
      // Ignorer les erreurs
    }
  }
  
  return SagaDetailViewModel(
    saga: saga,
    poster: poster,
    backdrop: backdropWithNullLanguage,
    movieCount: movieCount,
    totalDuration: totalDuration,
  );
});

/// Structure pour stocker les images (poster et backdrop) sans langue
class _SagaImages {
  const _SagaImages({this.poster, this.backdrop});
  
  final Uri? poster;
  final Uri? backdrop;
}

/// Récupère le poster et backdrop avec langue null depuis l'API images TMDB pour une collection
Future<_SagaImages> _getImagesWithNullLanguage(int collectionId) async {
  try {
    final tmdbClient = sl<TmdbClient>();
    final images = sl<TmdbImageResolver>();
    
    final jsonImages = await tmdbClient.getJson(
      'collection/$collectionId/images',
      query: {'include_image_language': 'null'},
    );
    
    // Récupérer le poster
    final posters = jsonImages['posters'] as List<dynamic>?;
    Uri? posterUri;
    if (posters != null && posters.isNotEmpty) {
      // Sélectionner le poster avec iso_639_1 == null
      final noLangPosters = posters
          .whereType<Map<String, dynamic>>()
          .where((m) => m['iso_639_1'] == null)
          .toList();
      
      if (noLangPosters.isNotEmpty) {
        final posterPath = noLangPosters.first['file_path']?.toString();
        if (posterPath != null) {
          posterUri = images.poster(posterPath, size: 'w500');
        }
      }
      
      // Fallback sur le premier poster disponible
      if (posterUri == null) {
        final firstPoster = posters.first as Map<String, dynamic>?;
        final posterPath = firstPoster?['file_path']?.toString();
        if (posterPath != null) {
          posterUri = images.poster(posterPath, size: 'w500');
        }
      }
    }
    
    // Récupérer le backdrop
    final backdrops = jsonImages['backdrops'] as List<dynamic>?;
    Uri? backdropUri;
    if (backdrops != null && backdrops.isNotEmpty) {
      // Sélectionner le backdrop avec iso_639_1 == null
      final noLangBackdrops = backdrops
          .whereType<Map<String, dynamic>>()
          .where((m) => m['iso_639_1'] == null)
          .toList();
      
      if (noLangBackdrops.isNotEmpty) {
        final backdropPath = noLangBackdrops.first['file_path']?.toString();
        if (backdropPath != null) {
          backdropUri = images.backdrop(backdropPath, size: 'w780');
        }
      }
      
      // Fallback sur le premier backdrop disponible
      if (backdropUri == null) {
        final firstBackdrop = backdrops.first as Map<String, dynamic>?;
        final backdropPath = firstBackdrop?['file_path']?.toString();
        if (backdropPath != null) {
          backdropUri = images.backdrop(backdropPath, size: 'w780');
        }
      }
    }
    
    return _SagaImages(poster: posterUri, backdrop: backdropUri);
  } catch (_) {
    return const _SagaImages();
  }
}

DateTime? _parseDate(String? date) =>
    date == null || date.isEmpty ? null : DateTime.tryParse(date);

/// Provider pour vérifier si un film de la saga est en cours de visionnage
final sagaInProgressMovieProvider = FutureProvider.family<String?, String>((ref, sagaId) async {
  final sagaRepo = ref.watch(slProvider)<SagaRepository>();
  final saga = await sagaRepo.getSaga(SagaId(sagaId));
  final historyRepo = ref.watch(slProvider)<HistoryLocalRepository>();
  
  // Récupérer tous les historiques de films
  final allHistory = await historyRepo.readAll(ContentType.movie);
  final historyMap = {
    for (final h in allHistory) h.contentId: h,
  };
  
  // Vérifier chaque film de la saga
  for (final entry in saga.timeline) {
    if (entry.reference.type == ContentType.movie) {
      final history = historyMap[entry.reference.id];
      if (history != null && history.duration != null && history.duration! > Duration.zero) {
        final progress = history.lastPosition?.inSeconds ?? 0;
        final total = history.duration!.inSeconds;
        // Considérer comme "en cours" si moins de 90% visionné
        if (progress < total * 0.9) {
          return entry.reference.id;
        }
      }
    }
  }
  
  return null;
});

/// ViewModel pour la page de détail de saga
class SagaDetailViewModel {
  const SagaDetailViewModel({
    required this.saga,
    required this.poster,
    this.backdrop,
    required this.movieCount,
    required this.totalDuration,
  });

  final Saga saga;
  final Uri? poster;
  final Uri? backdrop;
  final int movieCount;
  final Duration totalDuration;
}

