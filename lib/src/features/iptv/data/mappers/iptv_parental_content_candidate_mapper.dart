import 'package:movi/src/core/parental/domain/entities/parental_content_candidate.dart';
import 'package:movi/src/features/iptv/application/services/iptv_playlist_analysis_service.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

/// Convertit un item IPTV normalisé en candidat neutre pour le module parental.
///
/// Cette classe réutilise l'analyse IPTV existante afin d'éviter de
/// dupliquer les règles de fallback et de nettoyage de titre.
class IptvParentalContentCandidateMapper {
  const IptvParentalContentCandidateMapper(this._analysisService);

  final IptvPlaylistAnalysisService _analysisService;

  ParentalContentCandidate? map(XtreamPlaylistItem item) {
    final analysis = _analysisService.analyze(item);

    if (!analysis.fallback.isSupported) {
      return null;
    }

    final resolvedTitle = _resolveDisplayTitle(
      displayTitle: analysis.displayTitle,
      rawTitle: item.title,
    );
    if (resolvedTitle.isEmpty) {
      return null;
    }

    final lookupTitle = _resolveLookupTitle(
      searchTitleCandidates: analysis.searchTitleCandidates,
      fallbackTitle: resolvedTitle,
    );
    if (lookupTitle.isEmpty) {
      return null;
    }

    return ParentalContentCandidate(
      kind: _mapKind(item.type),
      title: resolvedTitle,
      normalizedTitle: lookupTitle,
      tmdbId: _normalizeTmdbId(item.tmdbId),
    );
  }

  ParentalContentCandidateKind _mapKind(XtreamPlaylistItemType type) {
    switch (type) {
      case XtreamPlaylistItemType.movie:
        return ParentalContentCandidateKind.movie;
      case XtreamPlaylistItemType.series:
        return ParentalContentCandidateKind.series;
    }
  }

  String _resolveDisplayTitle({
    required String displayTitle,
    required String rawTitle,
  }) {
    final normalizedDisplayTitle = displayTitle.trim();
    if (normalizedDisplayTitle.isNotEmpty) {
      return normalizedDisplayTitle;
    }

    return rawTitle.trim();
  }

  String _resolveLookupTitle({
    required List<String> searchTitleCandidates,
    required String fallbackTitle,
  }) {
    for (final candidate in searchTitleCandidates) {
      final normalizedCandidate = candidate.trim();
      if (normalizedCandidate.isNotEmpty) {
        return normalizedCandidate;
      }
    }

    return fallbackTitle.trim();
  }

  int? _normalizeTmdbId(int? tmdbId) {
    if (tmdbId == null || tmdbId <= 0) {
      return null;
    }
    return tmdbId;
  }
}
