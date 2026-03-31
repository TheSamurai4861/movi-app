import 'package:movi/src/core/parental/domain/entities/parental_content_candidate.dart';
import 'package:movi/src/core/parental/domain/repositories/parental_content_candidate_repository.dart';
import 'package:movi/src/core/storage/storage.dart';

/// Adaptateur d'infrastructure qui extrait des candidats neutres depuis
/// le repository IPTV local.
///
/// Cette classe reste en périphérie. Le service applicatif parental
/// ne connaît plus les détails IPTV.
class IptvParentalContentCandidateRepository
    implements ParentalContentCandidateRepository {
  const IptvParentalContentCandidateRepository(this._iptvLocal);

  final IptvLocalRepository _iptvLocal;

  @override
  Future<List<ParentalContentCandidate>> listCandidates() async {
    final rawItems = await _iptvLocal.getAllPlaylistItems();
    final candidates = <ParentalContentCandidate>[];

    for (final dynamic item in rawItems) {
      final typeName = item.type?.name?.toString().trim().toLowerCase();
      final kind = _mapKind(typeName);
      if (kind == null) {
        continue;
      }

      final title = (item.title as String?)?.trim() ?? '';
      if (title.isEmpty) {
        continue;
      }

      final normalizedTitle = _normalizeTitle(title);
      if (normalizedTitle.isEmpty) {
        continue;
      }

      candidates.add(
        ParentalContentCandidate(
          kind: kind,
          title: title,
          normalizedTitle: normalizedTitle,
          tmdbId: _normalizeTmdbId(item.tmdbId),
        ),
      );
    }

    return _deduplicate(candidates);
  }

  ParentalContentCandidateKind? _mapKind(String? typeName) {
    switch (typeName) {
      case 'movie':
      case 'vod':
        return ParentalContentCandidateKind.movie;
      case 'series':
      case 'tv':
      case 'show':
        return ParentalContentCandidateKind.series;
      default:
        return null;
    }
  }

  int? _normalizeTmdbId(Object? raw) {
    return switch (raw) {
      final int value when value > 0 => value,
      final num value when value > 0 => value.toInt(),
      final String value => int.tryParse(value.trim()),
      _ => null,
    };
  }

  List<ParentalContentCandidate> _deduplicate(
    List<ParentalContentCandidate> candidates,
  ) {
    final unique = <String, ParentalContentCandidate>{};

    for (final candidate in candidates) {
      final key = candidate.hasTmdbId
          ? '${candidate.kind.name}:tmdb:${candidate.tmdbId}'
          : '${candidate.kind.name}:title:${candidate.normalizedTitle}';

      unique.putIfAbsent(key, () => candidate);
    }

    return unique.values.toList(growable: false);
  }

  String _normalizeTitle(String rawTitle) {
    var value = rawTitle.trim().toLowerCase();

    value = value.replaceAll(RegExp(r'\([^)]*\)|\[[^\]]*\]|\{[^}]*\}'), ' ');
    value = value.replaceAll(
      RegExp(r'\b\d{3,4}p\b', caseSensitive: false),
      ' ',
    );
    value = value.replaceAll(
      RegExp(
        r'\b(4k|8k|uhd|hdr|hdr10|dv|multi|vf|vff|vfq|vo|vost|vostfr|french|truefrench|web|webrip|webdl|bluray|brrip|bdrip|remux|x264|x265|h264|h265|hevc|aac|ac3|eac3|dd|ddp|dts)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    value = value.replaceAll(RegExp(r'[|._-]+'), ' ');
    value = value.replaceAll(RegExp(r'\s+'), ' ');

    return value.trim();
  }
}
