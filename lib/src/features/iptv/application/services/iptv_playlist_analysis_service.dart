import 'package:movi/src/features/iptv/application/services/iptv_playlist_fallback_policy.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

enum IptvPlaylistDiagnosticCode {
  missingMeaningfulTitle,
  missingStableSourceIdentifier,
  sourcePosterUnavailable,
  sourceSynopsisUnavailable,
  sourceYearUnavailable,
  sourceRatingUnavailable,
  tmdbIdentifierUnavailable,
  externalLookupUnavailable,
}

class IptvPlaylistAnalysisContext {
  const IptvPlaylistAnalysisContext({this.tmdbLookupAvailable = true});

  final bool tmdbLookupAvailable;
}

class IptvPlaylistAnalysis {
  const IptvPlaylistAnalysis({
    required this.sourceItem,
    required this.displayTitle,
    required this.searchTitleCandidates,
    required this.normalizedYear,
    required this.fallback,
    required this.diagnostics,
  });

  final XtreamPlaylistItem sourceItem;
  final String displayTitle;
  final List<String> searchTitleCandidates;
  final int? normalizedYear;
  final IptvPlaylistFallbackResult fallback;
  final List<IptvPlaylistDiagnosticCode> diagnostics;
}

class IptvPlaylistAnalysisService {
  const IptvPlaylistAnalysisService({
    IptvPlaylistFallbackPolicy fallbackPolicy =
        const IptvPlaylistFallbackPolicy(),
  }) : _fallbackPolicy = fallbackPolicy;

  final IptvPlaylistFallbackPolicy _fallbackPolicy;

  IptvPlaylistAnalysis analyze(
    XtreamPlaylistItem item, {
    IptvPlaylistAnalysisContext context = const IptvPlaylistAnalysisContext(),
  }) {
    final fallback = _fallbackPolicy.evaluate(
      item,
      tmdbLookupAvailable: context.tmdbLookupAvailable,
    );

    return IptvPlaylistAnalysis(
      sourceItem: item,
      displayTitle: fallback.displayTitle,
      searchTitleCandidates: fallback.searchTitleCandidates,
      normalizedYear: fallback.normalizedYear,
      fallback: fallback,
      diagnostics: _buildDiagnostics(item, fallback),
    );
  }

  List<IptvPlaylistDiagnosticCode> _buildDiagnostics(
    XtreamPlaylistItem item,
    IptvPlaylistFallbackResult fallback,
  ) {
    final diagnostics = <IptvPlaylistDiagnosticCode>[];

    if (!fallback.contract.hasMeaningfulTitle) {
      diagnostics.add(IptvPlaylistDiagnosticCode.missingMeaningfulTitle);
    }
    if (!fallback.contract.hasStableSourceIdentifier) {
      diagnostics.add(IptvPlaylistDiagnosticCode.missingStableSourceIdentifier);
    }
    if (fallback.posterDecision !=
        IptvPosterFallbackDecision.keepSourcePoster) {
      diagnostics.add(IptvPlaylistDiagnosticCode.sourcePosterUnavailable);
    }
    if (fallback.synopsisDecision !=
        IptvSynopsisFallbackDecision.keepSourceSynopsis) {
      diagnostics.add(IptvPlaylistDiagnosticCode.sourceSynopsisUnavailable);
    }
    if (fallback.yearDecision != IptvYearFallbackDecision.keepSourceYear) {
      diagnostics.add(IptvPlaylistDiagnosticCode.sourceYearUnavailable);
    }
    if (fallback.ratingDecision !=
        IptvRatingFallbackDecision.keepSourceRating) {
      diagnostics.add(IptvPlaylistDiagnosticCode.sourceRatingUnavailable);
    }
    if (item.tmdbId == null || item.tmdbId! <= 0) {
      diagnostics.add(IptvPlaylistDiagnosticCode.tmdbIdentifierUnavailable);
    }
    if (fallback.disposition == IptvFallbackDisposition.technicalFailure) {
      diagnostics.add(IptvPlaylistDiagnosticCode.externalLookupUnavailable);
    }

    return List<IptvPlaylistDiagnosticCode>.unmodifiable(diagnostics);
  }
}
