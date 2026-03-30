import 'package:movi/src/core/utils/title_cleaner.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

enum IptvFallbackDisposition {
  ready,
  partialData,
  technicalFailure,
  unsupportedData,
}

enum IptvPosterFallbackDecision { keepSourcePoster, fetchFromTmdb, placeholder }

enum IptvSynopsisFallbackDecision { keepSourceSynopsis, genericUnavailable }

enum IptvYearFallbackDecision { keepSourceYear, inferFromTitle, hideYear }

enum IptvRatingFallbackDecision { keepSourceRating, hideRating }

enum IptvTmdbFallbackDecision {
  keepProvidedTmdbId,
  searchByTitleAndYear,
  searchByTitleOnly,
  unavailable,
}

class IptvMinimalPlaylistContract {
  const IptvMinimalPlaylistContract({
    required this.hasMeaningfulTitle,
    required this.hasReliableContentType,
    required this.hasStableSourceIdentifier,
  });

  final bool hasMeaningfulTitle;
  final bool hasReliableContentType;
  final bool hasStableSourceIdentifier;

  bool get isSatisfied =>
      hasMeaningfulTitle && hasReliableContentType && hasStableSourceIdentifier;
}

class IptvPlaylistFallbackResult {
  const IptvPlaylistFallbackResult({
    required this.contract,
    required this.disposition,
    required this.displayTitle,
    required this.searchTitleCandidates,
    required this.normalizedYear,
    required this.posterDecision,
    required this.synopsisDecision,
    required this.yearDecision,
    required this.ratingDecision,
    required this.tmdbDecision,
  });

  final IptvMinimalPlaylistContract contract;
  final IptvFallbackDisposition disposition;
  final String displayTitle;
  final List<String> searchTitleCandidates;
  final int? normalizedYear;
  final IptvPosterFallbackDecision posterDecision;
  final IptvSynopsisFallbackDecision synopsisDecision;
  final IptvYearFallbackDecision yearDecision;
  final IptvRatingFallbackDecision ratingDecision;
  final IptvTmdbFallbackDecision tmdbDecision;

  bool get isSupported =>
      disposition != IptvFallbackDisposition.unsupportedData;
}

class IptvPlaylistFallbackPolicy {
  const IptvPlaylistFallbackPolicy();

  IptvPlaylistFallbackResult evaluate(
    XtreamPlaylistItem item, {
    bool tmdbLookupAvailable = true,
  }) {
    final normalizedTitle = _normalizeTitle(item.title);
    final normalizedYear = _normalizeYear(item);
    final contract = IptvMinimalPlaylistContract(
      hasMeaningfulTitle: normalizedTitle.isNotEmpty,
      hasReliableContentType: true,
      hasStableSourceIdentifier: _hasStableSourceIdentifier(item),
    );

    final posterDecision = _decidePoster(item, tmdbLookupAvailable);
    final synopsisDecision = _decideSynopsis(item);
    final yearDecision = _decideYear(item, normalizedYear);
    final ratingDecision = _decideRating(item);
    final tmdbDecision = _decideTmdb(
      item,
      normalizedTitle,
      normalizedYear,
      tmdbLookupAvailable,
    );
    final requiresExternalLookup = _requiresExternalLookup(
      item: item,
      normalizedTitle: normalizedTitle,
    );
    final searchTitleCandidates = _buildSearchTitleCandidates(
      originalTitle: item.title,
      normalizedTitle: normalizedTitle,
    );

    final disposition = _decideDisposition(
      contract: contract,
      posterDecision: posterDecision,
      synopsisDecision: synopsisDecision,
      yearDecision: yearDecision,
      ratingDecision: ratingDecision,
      tmdbDecision: tmdbDecision,
      requiresExternalLookup: requiresExternalLookup,
      tmdbLookupAvailable: tmdbLookupAvailable,
    );

    return IptvPlaylistFallbackResult(
      contract: contract,
      disposition: disposition,
      displayTitle: normalizedTitle.isNotEmpty
          ? normalizedTitle
          : item.title.trim(),
      searchTitleCandidates: searchTitleCandidates,
      normalizedYear: normalizedYear,
      posterDecision: posterDecision,
      synopsisDecision: synopsisDecision,
      yearDecision: yearDecision,
      ratingDecision: ratingDecision,
      tmdbDecision: tmdbDecision,
    );
  }

  String _normalizeTitle(String rawTitle) {
    final original = rawTitle.trim();
    if (original.isEmpty) return '';
    final cleaned = TitleCleaner.cleanWithYear(original).cleanedTitle.trim();
    if (_isMeaningfulTitle(cleaned)) {
      return cleaned;
    }
    return _isMeaningfulTitle(original) ? original : '';
  }

  int? _normalizeYear(XtreamPlaylistItem item) {
    if (_isValidYear(item.releaseYear)) {
      return item.releaseYear;
    }

    final extracted = TitleCleaner.cleanWithYear(item.title).year;
    if (_isValidYear(extracted)) {
      return extracted;
    }

    final embeddedInTitle = _extractYearFromRawTitle(item.title);
    if (_isValidYear(embeddedInTitle)) {
      return embeddedInTitle;
    }

    return null;
  }

  bool _hasStableSourceIdentifier(XtreamPlaylistItem item) {
    return item.streamId > 0 || (item.tmdbId != null && item.tmdbId! > 0);
  }

  IptvPosterFallbackDecision _decidePoster(
    XtreamPlaylistItem item,
    bool tmdbLookupAvailable,
  ) {
    if (_hasHttpPoster(item.posterUrl)) {
      return IptvPosterFallbackDecision.keepSourcePoster;
    }
    if (tmdbLookupAvailable && item.tmdbId != null && item.tmdbId! > 0) {
      return IptvPosterFallbackDecision.fetchFromTmdb;
    }
    return IptvPosterFallbackDecision.placeholder;
  }

  IptvSynopsisFallbackDecision _decideSynopsis(XtreamPlaylistItem item) {
    final overview = item.overview?.trim();
    if (overview != null && overview.isNotEmpty) {
      return IptvSynopsisFallbackDecision.keepSourceSynopsis;
    }
    return IptvSynopsisFallbackDecision.genericUnavailable;
  }

  IptvYearFallbackDecision _decideYear(
    XtreamPlaylistItem item,
    int? normalizedYear,
  ) {
    if (_isValidYear(item.releaseYear)) {
      return IptvYearFallbackDecision.keepSourceYear;
    }
    if (normalizedYear != null) {
      return IptvYearFallbackDecision.inferFromTitle;
    }
    return IptvYearFallbackDecision.hideYear;
  }

  IptvRatingFallbackDecision _decideRating(XtreamPlaylistItem item) {
    final rating = item.rating;
    if (rating != null && rating >= 0 && rating <= 10) {
      return IptvRatingFallbackDecision.keepSourceRating;
    }
    return IptvRatingFallbackDecision.hideRating;
  }

  IptvTmdbFallbackDecision _decideTmdb(
    XtreamPlaylistItem item,
    String normalizedTitle,
    int? normalizedYear,
    bool tmdbLookupAvailable,
  ) {
    if (item.tmdbId != null && item.tmdbId! > 0) {
      return IptvTmdbFallbackDecision.keepProvidedTmdbId;
    }
    if (!tmdbLookupAvailable || normalizedTitle.isEmpty) {
      return IptvTmdbFallbackDecision.unavailable;
    }
    if (normalizedYear != null) {
      return IptvTmdbFallbackDecision.searchByTitleAndYear;
    }
    return IptvTmdbFallbackDecision.searchByTitleOnly;
  }

  List<String> _buildSearchTitleCandidates({
    required String originalTitle,
    required String normalizedTitle,
  }) {
    final candidates = <String>[];
    void addCandidate(String value) {
      final trimmed = value.trim();
      if (!_isMeaningfulTitle(trimmed)) return;
      if (candidates.contains(trimmed)) return;
      candidates.add(trimmed);
    }

    addCandidate(normalizedTitle);
    addCandidate(originalTitle);
    return List<String>.unmodifiable(candidates);
  }

  IptvFallbackDisposition _decideDisposition({
    required IptvMinimalPlaylistContract contract,
    required IptvPosterFallbackDecision posterDecision,
    required IptvSynopsisFallbackDecision synopsisDecision,
    required IptvYearFallbackDecision yearDecision,
    required IptvRatingFallbackDecision ratingDecision,
    required IptvTmdbFallbackDecision tmdbDecision,
    required bool requiresExternalLookup,
    required bool tmdbLookupAvailable,
  }) {
    if (!contract.isSatisfied) {
      return IptvFallbackDisposition.unsupportedData;
    }

    if (requiresExternalLookup && !tmdbLookupAvailable) {
      return IptvFallbackDisposition.technicalFailure;
    }

    final usesFallback =
        posterDecision != IptvPosterFallbackDecision.keepSourcePoster ||
        synopsisDecision != IptvSynopsisFallbackDecision.keepSourceSynopsis ||
        yearDecision != IptvYearFallbackDecision.keepSourceYear ||
        ratingDecision != IptvRatingFallbackDecision.keepSourceRating ||
        tmdbDecision != IptvTmdbFallbackDecision.keepProvidedTmdbId;

    return usesFallback
        ? IptvFallbackDisposition.partialData
        : IptvFallbackDisposition.ready;
  }

  bool _requiresExternalLookup({
    required XtreamPlaylistItem item,
    required String normalizedTitle,
  }) {
    final missingPoster = !_hasHttpPoster(item.posterUrl);
    final hasTmdbId = item.tmdbId != null && item.tmdbId! > 0;
    final missingTmdbButResolvable = !hasTmdbId && normalizedTitle.isNotEmpty;
    return (missingPoster && hasTmdbId) || missingTmdbButResolvable;
  }

  bool _hasHttpPoster(String? rawPoster) {
    if (rawPoster == null || rawPoster.trim().isEmpty) return false;
    final uri = Uri.tryParse(rawPoster.trim());
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  bool _isMeaningfulTitle(String value) {
    final compact = value.trim();
    if (compact.isEmpty) return false;
    return RegExp(r'[A-Za-z0-9]{2,}').hasMatch(compact);
  }

  bool _isValidYear(int? year) {
    if (year == null) return false;
    return year >= 1900 && year <= 2100;
  }

  int? _extractYearFromRawTitle(String rawTitle) {
    final match = RegExp(r'(19\d{2}|20\d{2})').firstMatch(rawTitle);
    return int.tryParse(match?.group(1) ?? '');
  }
}
