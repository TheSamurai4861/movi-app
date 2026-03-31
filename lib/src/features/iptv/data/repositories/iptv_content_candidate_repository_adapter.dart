import 'package:movi/src/core/parental/domain/entities/parental_content_candidate.dart';
import 'package:movi/src/core/parental/domain/repositories/parental_content_candidate_repository.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/data/mappers/iptv_parental_content_candidate_mapper.dart';

/// Adaptateur concret du port parental basé sur le catalogue IPTV local.
///
/// Source retenue :
/// - `IptvLocalRepository.getAllPlaylistItems()`
///
/// Pourquoi :
/// - les items sont déjà normalisés côté persistance locale ;
/// - la source couvre Xtream et Stalker via le modèle commun `XtreamPlaylistItem`;
/// - on peut réutiliser `IptvPlaylistAnalysisService` pour le nettoyage/fallback
///   sans dupliquer la logique dans le parental.
class IptvContentCandidateRepositoryAdapter
    implements ParentalContentCandidateRepository {
  const IptvContentCandidateRepositoryAdapter({
    required IptvLocalRepository iptvLocalRepository,
    required IptvParentalContentCandidateMapper mapper,
    this.activeSourceIdsProvider,
  }) : _iptvLocalRepository = iptvLocalRepository,
       _mapper = mapper;

  final IptvLocalRepository _iptvLocalRepository;
  final IptvParentalContentCandidateMapper _mapper;
  final Set<String>? Function()? activeSourceIdsProvider;

  @override
  Future<List<ParentalContentCandidate>> listCandidates() async {
    final activeSourceIds = _normalizeActiveSourceIds(
      activeSourceIdsProvider?.call(),
    );

    final playlistItems = await _iptvLocalRepository.getAllPlaylistItems(
      accountIds: activeSourceIds,
    );

    final candidates = <ParentalContentCandidate>[];
    for (final item in playlistItems) {
      final candidate = _mapper.map(item);
      if (candidate != null) {
        candidates.add(candidate);
      }
    }

    return _deduplicateCandidates(candidates);
  }

  Set<String>? _normalizeActiveSourceIds(Set<String>? rawSourceIds) {
    if (rawSourceIds == null) {
      return null;
    }

    final normalized = rawSourceIds
        .map((sourceId) => sourceId.trim())
        .where((sourceId) => sourceId.isNotEmpty)
        .toSet();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  List<ParentalContentCandidate> _deduplicateCandidates(
    List<ParentalContentCandidate> candidates,
  ) {
    final candidatesByTmdbId = <String, ParentalContentCandidate>{};
    final candidatesByTitle = <String, ParentalContentCandidate>{};

    for (final candidate in candidates) {
      final hasTmdbId = candidate.tmdbId != null && candidate.tmdbId! > 0;

      if (hasTmdbId) {
        final key = '${candidate.kind.name}:${candidate.tmdbId}';
        candidatesByTmdbId[key] = candidate;
        continue;
      }

      final key = '${candidate.kind.name}:${candidate.normalizedTitle}';
      candidatesByTitle.putIfAbsent(key, () => candidate);
    }

    return <ParentalContentCandidate>[
      ...candidatesByTmdbId.values,
      ...candidatesByTitle.values,
    ];
  }
}
