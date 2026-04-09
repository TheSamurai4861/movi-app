import 'package:movi/src/features/home/domain/entities/in_progress_media.dart';
import 'package:movi/src/features/home/domain/services/continue_watching_enrichment_service.dart';

/// Use case pour charger la liste des médias "en cours" pour la Home.
class LoadContinueWatchingMedia {
  const LoadContinueWatchingMedia(this._service);

  final ContinueWatchingEnrichmentService _service;

  Future<List<InProgressMedia>> call({String userId = 'default'}) {
    return _service.loadInProgress(userId: userId);
  }
}
