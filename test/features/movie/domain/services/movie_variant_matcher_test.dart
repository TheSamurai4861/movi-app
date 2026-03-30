import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/movie/domain/entities/movie_variant_match_result.dart';
import 'package:movi/src/features/movie/domain/services/movie_variant_matcher.dart';

void main() {
  const matcher = MovieVariantMatcher();

  test('matches strictly when tmdb ids are identical', () {
    final result = matcher.match(
      referenceItem: _item(
        streamId: 101,
        title: 'Dune.2021.1080p',
        tmdbId: 438631,
      ),
      candidateItem: _item(
        streamId: 202,
        title: 'Dune.2021.VOSTFR.2160p',
        tmdbId: 438631,
      ),
    );

    expect(result.kind, MovieVariantMatchKind.strict);
    expect(result.reason, MovieVariantMatchReason.sameTmdbId);
  });

  test('matches as compatible when cleaned title and year are aligned', () {
    final result = matcher.match(
      referenceItem: _item(streamId: 101, title: 'Dune.2021.TRUEFRENCH.1080p'),
      candidateItem: _item(streamId: 202, title: 'Dune.2021.VOSTFR.2160p'),
    );

    expect(result.kind, MovieVariantMatchKind.compatible);
    expect(result.reason, MovieVariantMatchReason.sameCleanTitleAndYear);
  });

  test(
    'matches as compatible when years are missing but cleaned title is stable',
    () {
      final result = matcher.match(
        referenceItem: _item(streamId: 101, title: 'Alien.TRUEFRENCH.1080p'),
        candidateItem: _item(streamId: 202, title: 'Alien.VOSTFR.2160p'),
      );

      expect(result.kind, MovieVariantMatchKind.compatible);
      expect(result.reason, MovieVariantMatchReason.sameCleanTitleWithoutYear);
    },
  );

  test('rejects weak title fallback when years conflict', () {
    final result = matcher.match(
      referenceItem: _item(streamId: 101, title: 'Dune.2021.TRUEFRENCH.1080p'),
      candidateItem: _item(streamId: 202, title: 'Dune.2024.VOSTFR.2160p'),
    );

    expect(result.kind, MovieVariantMatchKind.none);
    expect(result.reason, MovieVariantMatchReason.conflictingYear);
  });

  test('rejects false positives when cleaned titles do not match exactly', () {
    final result = matcher.match(
      referenceItem: _item(
        streamId: 101,
        title: 'Avatar.2009.TRUEFRENCH.1080p',
        tmdbId: 19995,
      ),
      candidateItem: _item(
        streamId: 202,
        title: 'Avatar.The.Way.of.Water.2022.VOSTFR.2160p',
        tmdbId: 76600,
      ),
    );

    expect(result.kind, MovieVariantMatchKind.none);
    expect(result.reason, MovieVariantMatchReason.cleanTitleMismatch);
  });

  test(
    'reports conflicting tmdb ids only for plausible same-title candidates',
    () {
      final result = matcher.match(
        referenceItem: _item(
          streamId: 101,
          title: 'Dune.2021.TRUEFRENCH.1080p',
          tmdbId: 438631,
        ),
        candidateItem: _item(
          streamId: 202,
          title: 'Dune.2021.VOSTFR.2160p',
          tmdbId: 999999,
        ),
      );

      expect(result.kind, MovieVariantMatchKind.none);
      expect(result.reason, MovieVariantMatchReason.conflictingTmdbId);
    },
  );
}

XtreamPlaylistItem _item({
  required int streamId,
  required String title,
  int? tmdbId,
}) {
  return XtreamPlaylistItem(
    accountId: 'source-a',
    categoryId: 'movies',
    categoryName: 'Movies',
    streamId: streamId,
    title: title,
    type: XtreamPlaylistItemType.movie,
    tmdbId: tmdbId,
  );
}
