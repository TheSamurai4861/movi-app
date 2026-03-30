import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';

enum PlaylistFixtureProvider { xtream, stalker }

enum PlaylistFixtureCategory {
  clean,
  missingTmdb,
  noisyTitle,
  missingImages,
  partialMetadata,
  inconsistentMetadata,
}

enum PlaylistSupportLevel { supported, degraded, unsupported }

enum PlaylistEnrichmentExpectation {
  alreadyResolvedTmdb,
  lookupByCleanTitle,
  lookupByCleanTitleAndYear,
  notPossible,
}

enum PlaylistPosterFallbackKind {
  noneNeeded,
  useSourcePoster,
  fetchFromTmdb,
  placeholder,
}

enum PlaylistTextFallbackKind {
  noneNeeded,
  useSourceOverview,
  cleanedTitleOnly,
  genericUnavailable,
}

enum PlaylistDetailAvailability { full, degraded, hidden }

class PlaylistUiFallbackExpectation {
  const PlaylistUiFallbackExpectation({
    required this.poster,
    required this.text,
    required this.detailAvailability,
  });

  final PlaylistPosterFallbackKind poster;
  final PlaylistTextFallbackKind text;
  final PlaylistDetailAvailability detailAvailability;
}

class PlaylistAnalysisFixture {
  const PlaylistAnalysisFixture({
    required this.id,
    required this.label,
    required this.provider,
    required this.category,
    required this.playlist,
    required this.rawFields,
    required this.normalizedTitleCandidates,
    required this.enrichmentExpectation,
    required this.uiFallback,
    required this.supportLevel,
    this.notes = const <String>[],
  });

  final String id;
  final String label;
  final PlaylistFixtureProvider provider;
  final PlaylistFixtureCategory category;
  final XtreamPlaylist playlist;
  final Map<String, Object?> rawFields;
  final List<String> normalizedTitleCandidates;
  final PlaylistEnrichmentExpectation enrichmentExpectation;
  final PlaylistUiFallbackExpectation uiFallback;
  final PlaylistSupportLevel supportLevel;
  final List<String> notes;

  XtreamPlaylistItem get item => playlist.items.single;
}

const representativePlaylistAnalysisFixtures = <PlaylistAnalysisFixture>[
  PlaylistAnalysisFixture(
    id: 'xtream_clean_movie',
    label: 'Playlist propre avec metadonnees completes',
    provider: PlaylistFixtureProvider.xtream,
    category: PlaylistFixtureCategory.clean,
    playlist: XtreamPlaylist(
      id: 'fixture_movies_clean',
      accountId: 'fixture.xtream',
      title: 'Films premium',
      type: XtreamPlaylistType.movies,
      items: <XtreamPlaylistItem>[
        XtreamPlaylistItem(
          accountId: 'fixture.xtream',
          categoryId: '10',
          categoryName: 'Films premium',
          streamId: 101,
          title: 'Dune: Part Two',
          type: XtreamPlaylistItemType.movie,
          overview: 'Paul Atreides rallies the Fremen against House Harkonnen.',
          posterUrl: 'https://cdn.example.test/posters/dune-part-two.jpg',
          containerExtension: 'mp4',
          rating: 8.6,
          releaseYear: 2024,
          tmdbId: 693134,
          imdbId: 'tt15239678',
        ),
      ],
    ),
    rawFields: <String, Object?>{
      'name': 'Dune: Part Two',
      'stream_id': 101,
      'category_id': '10',
      'stream_icon': 'https://cdn.example.test/posters/dune-part-two.jpg',
      'plot': 'Paul Atreides rallies the Fremen against House Harkonnen.',
      'year': '2024',
      'tmdb_id': '693134',
      'imdb_id': 'tt15239678',
    },
    normalizedTitleCandidates: <String>['Dune: Part Two'],
    enrichmentExpectation: PlaylistEnrichmentExpectation.alreadyResolvedTmdb,
    uiFallback: PlaylistUiFallbackExpectation(
      poster: PlaylistPosterFallbackKind.noneNeeded,
      text: PlaylistTextFallbackKind.noneNeeded,
      detailAvailability: PlaylistDetailAvailability.full,
    ),
    supportLevel: PlaylistSupportLevel.supported,
  ),
  PlaylistAnalysisFixture(
    id: 'xtream_missing_tmdb_movie',
    label: 'Playlist sans TMDB mais encore identifiable',
    provider: PlaylistFixtureProvider.xtream,
    category: PlaylistFixtureCategory.missingTmdb,
    playlist: XtreamPlaylist(
      id: 'fixture_movies_missing_tmdb',
      accountId: 'fixture.xtream',
      title: 'Films sans TMDB',
      type: XtreamPlaylistType.movies,
      items: <XtreamPlaylistItem>[
        XtreamPlaylistItem(
          accountId: 'fixture.xtream',
          categoryId: '11',
          categoryName: 'Films sans TMDB',
          streamId: 102,
          title: 'Inception',
          type: XtreamPlaylistItemType.movie,
          overview: null,
          posterUrl: 'https://cdn.example.test/posters/inception-provider.jpg',
          containerExtension: 'mkv',
          rating: 8.1,
          releaseYear: 2010,
          tmdbId: null,
          imdbId: null,
        ),
      ],
    ),
    rawFields: <String, Object?>{
      'name': 'Inception',
      'stream_id': 102,
      'category_id': '11',
      'stream_icon': 'https://cdn.example.test/posters/inception-provider.jpg',
      'plot': null,
      'year': '2010',
      'tmdb_id': null,
    },
    normalizedTitleCandidates: <String>['Inception'],
    enrichmentExpectation:
        PlaylistEnrichmentExpectation.lookupByCleanTitleAndYear,
    uiFallback: PlaylistUiFallbackExpectation(
      poster: PlaylistPosterFallbackKind.useSourcePoster,
      text: PlaylistTextFallbackKind.genericUnavailable,
      detailAvailability: PlaylistDetailAvailability.degraded,
    ),
    supportLevel: PlaylistSupportLevel.degraded,
    notes: <String>[
      'Le media doit rester visible meme si le resume TMDB manque.',
    ],
  ),
  PlaylistAnalysisFixture(
    id: 'xtream_noisy_title_movie',
    label: 'Titre bruite avec qualite, langue et ponctuation parasite',
    provider: PlaylistFixtureProvider.xtream,
    category: PlaylistFixtureCategory.noisyTitle,
    playlist: XtreamPlaylist(
      id: 'fixture_movies_noisy_title',
      accountId: 'fixture.xtream',
      title: 'Films bruites',
      type: XtreamPlaylistType.movies,
      items: <XtreamPlaylistItem>[
        XtreamPlaylistItem(
          accountId: 'fixture.xtream',
          categoryId: '12',
          categoryName: 'Films bruites',
          streamId: 103,
          title: 'The.Matrix.1999.MULTi.TRUEFRENCH.1080p.BluRay.x264',
          type: XtreamPlaylistItemType.movie,
          overview: null,
          posterUrl: null,
          containerExtension: 'mkv',
          rating: null,
          releaseYear: null,
          tmdbId: null,
          imdbId: null,
        ),
      ],
    ),
    rawFields: <String, Object?>{
      'name': 'The.Matrix.1999.MULTi.TRUEFRENCH.1080p.BluRay.x264',
      'stream_id': 103,
      'category_id': '12',
      'stream_icon': null,
      'plot': null,
      'year': null,
      'tmdb_id': null,
    },
    normalizedTitleCandidates: <String>['The Matrix', 'Matrix'],
    enrichmentExpectation: PlaylistEnrichmentExpectation.lookupByCleanTitle,
    uiFallback: PlaylistUiFallbackExpectation(
      poster: PlaylistPosterFallbackKind.placeholder,
      text: PlaylistTextFallbackKind.cleanedTitleOnly,
      detailAvailability: PlaylistDetailAvailability.degraded,
    ),
    supportLevel: PlaylistSupportLevel.degraded,
    notes: <String>[
      'La normalisation du titre est critique avant toute recherche TMDB.',
    ],
  ),
  PlaylistAnalysisFixture(
    id: 'stalker_missing_images_series',
    label: 'Serie Stalker sans image mais avec TMDB fiable',
    provider: PlaylistFixtureProvider.stalker,
    category: PlaylistFixtureCategory.missingImages,
    playlist: XtreamPlaylist(
      id: 'fixture_series_missing_images',
      accountId: 'fixture.stalker',
      title: 'Series sans image',
      type: XtreamPlaylistType.series,
      items: <XtreamPlaylistItem>[
        XtreamPlaylistItem(
          accountId: 'fixture.stalker',
          categoryId: '20',
          categoryName: 'Series sans image',
          streamId: 201,
          title: 'Breaking Bad',
          type: XtreamPlaylistItemType.series,
          overview:
              'A high school chemistry teacher turns to making methamphetamine.',
          posterUrl: null,
          containerExtension: null,
          rating: 9.4,
          releaseYear: 2008,
          tmdbId: 1396,
          imdbId: null,
        ),
      ],
    ),
    rawFields: <String, Object?>{
      'name': 'Breaking Bad',
      'id': '201',
      'category_id': '20',
      'screenshot_uri': null,
      'description':
          'A high school chemistry teacher turns to making methamphetamine.',
      'year': '2008',
      'tmdb_id': '1396',
    },
    normalizedTitleCandidates: <String>['Breaking Bad'],
    enrichmentExpectation: PlaylistEnrichmentExpectation.alreadyResolvedTmdb,
    uiFallback: PlaylistUiFallbackExpectation(
      poster: PlaylistPosterFallbackKind.fetchFromTmdb,
      text: PlaylistTextFallbackKind.useSourceOverview,
      detailAvailability: PlaylistDetailAvailability.full,
    ),
    supportLevel: PlaylistSupportLevel.supported,
  ),
  PlaylistAnalysisFixture(
    id: 'stalker_partial_metadata_series',
    label: 'Donnees partiellement exploitables',
    provider: PlaylistFixtureProvider.stalker,
    category: PlaylistFixtureCategory.partialMetadata,
    playlist: XtreamPlaylist(
      id: 'fixture_series_partial',
      accountId: 'fixture.stalker',
      title: 'Series partielles',
      type: XtreamPlaylistType.series,
      items: <XtreamPlaylistItem>[
        XtreamPlaylistItem(
          accountId: 'fixture.stalker',
          categoryId: '21',
          categoryName: 'Series partielles',
          streamId: 202,
          title: 'Dark',
          type: XtreamPlaylistItemType.series,
          overview: null,
          posterUrl: null,
          containerExtension: null,
          rating: null,
          releaseYear: 2017,
          tmdbId: null,
          imdbId: null,
        ),
      ],
    ),
    rawFields: <String, Object?>{
      'name': 'Dark',
      'id': '202',
      'category_id': '21',
      'screenshot_uri': null,
      'description': null,
      'year': '2017',
      'tmdb_id': null,
    },
    normalizedTitleCandidates: <String>['Dark'],
    enrichmentExpectation:
        PlaylistEnrichmentExpectation.lookupByCleanTitleAndYear,
    uiFallback: PlaylistUiFallbackExpectation(
      poster: PlaylistPosterFallbackKind.placeholder,
      text: PlaylistTextFallbackKind.genericUnavailable,
      detailAvailability: PlaylistDetailAvailability.degraded,
    ),
    supportLevel: PlaylistSupportLevel.degraded,
    notes: <String>[
      'Cas utile pour verifier les pages liste, home et detail en mode degrade.',
    ],
  ),
  PlaylistAnalysisFixture(
    id: 'xtream_inconsistent_unsupported',
    label: 'Metadonnees incoherentes non supportees pour cette iteration',
    provider: PlaylistFixtureProvider.xtream,
    category: PlaylistFixtureCategory.inconsistentMetadata,
    playlist: XtreamPlaylist(
      id: 'fixture_unsupported',
      accountId: 'fixture.xtream',
      title: 'Elements incoherents',
      type: XtreamPlaylistType.movies,
      items: <XtreamPlaylistItem>[
        XtreamPlaylistItem(
          accountId: 'fixture.xtream',
          categoryId: '',
          categoryName: 'Sans categorie',
          streamId: 0,
          title: '---',
          type: XtreamPlaylistItemType.movie,
          overview: null,
          posterUrl: null,
          containerExtension: null,
          rating: null,
          releaseYear: 3024,
          tmdbId: null,
          imdbId: null,
        ),
      ],
    ),
    rawFields: <String, Object?>{
      'name': '---',
      'stream_id': 'abc',
      'category_id': '',
      'stream_icon': null,
      'plot': null,
      'year': '3024',
      'tmdb_id': 'not_a_number',
    },
    normalizedTitleCandidates: <String>[],
    enrichmentExpectation: PlaylistEnrichmentExpectation.notPossible,
    uiFallback: PlaylistUiFallbackExpectation(
      poster: PlaylistPosterFallbackKind.placeholder,
      text: PlaylistTextFallbackKind.genericUnavailable,
      detailAvailability: PlaylistDetailAvailability.hidden,
    ),
    supportLevel: PlaylistSupportLevel.unsupported,
    notes: <String>[
      'Ce cas doit etre isole ou masque plutot que forcer une experience detail cassable.',
    ],
  ),
];
