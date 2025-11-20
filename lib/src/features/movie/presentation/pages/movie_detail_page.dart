import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/core/models/models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart'
    as mdp;
import 'package:movi/src/core/utils/app_spacing.dart';
import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
import 'package:movi/src/features/playlist/playlist.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_detail_hero_section.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_detail_main_actions.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_detail_synopsis_section.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_detail_cast_section.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_detail_saga_section.dart';
import 'package:movi/src/features/movie/presentation/widgets/movie_detail_recommendations_section.dart';

class MovieDetailPage extends ConsumerStatefulWidget {
  const MovieDetailPage({super.key, this.media});

  final MoviMedia? media;

  @override
  ConsumerState<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends ConsumerState<MovieDetailPage>
    with TickerProviderStateMixin {
  bool _isTransitioningFromLoading = true;
  String mediaTitle = '—';
  String yearText = '—';
  String durationText = '—';
  String ratingText = '—';
  String overviewText = '';
  List<MoviPerson> cast = const [];
  List<MoviMedia> recommendations = const [];
  Timer? _autoRefreshTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _loadingTimeout = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _isTransitioningFromLoading = true;
    _primeFromArgs();
    // Ne démarrer le timer que si un média est présent
    if (widget.media != null) {
      _startAutoRefreshTimer();
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    final mediaId = widget.media?.id;
    if (mediaId == null) return;
    _autoRefreshTimer = Timer(_loadingTimeout, () {
      if (!mounted || _retryCount >= _maxRetries) return;
      final vmAsync = ref.read(mdp.movieDetailControllerProvider(mediaId));
      // Si toujours en chargement après le timeout, relancer
      if (vmAsync.isLoading) {
        _retryCount++;
        ref.invalidate(mdp.movieDetailControllerProvider(mediaId));
        _startAutoRefreshTimer();
      }
    });
  }

  void _primeFromArgs() {
    final m = widget.media;
    if (m != null) {
      mediaTitle = m.title;
      yearText = m.year?.toString() ?? '—';
      ratingText = m.rating?.toStringAsFixed(1) ?? '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    if (media == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.movieNoMedia,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    final vmAsync = ref.watch(mdp.movieDetailControllerProvider(media.id));

    // Détecter les erreurs et relancer automatiquement
    vmAsync.whenOrNull(
      error: (e, st) {
        if (mounted && _retryCount < _maxRetries) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _retryCount++;
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  ref.invalidate(mdp.movieDetailControllerProvider(media.id));
                  _startAutoRefreshTimer();
                }
              });
            }
          });
        }
      },
      data: (_) {
        // Le chargement a réussi, annuler le timer et réinitialiser
        _autoRefreshTimer?.cancel();
        _retryCount = 0;
      },
    );

    return vmAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const OverlaySplash(),
      ),
      error: (e, st) => _buildErrorScaffold(e),
      data: (vm) {
        // Démarrer la transition d'opacité après un court délai
        if (_isTransitioningFromLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Future.delayed(const Duration(milliseconds: 50), () {
                if (mounted) {
                  setState(() {
                    _isTransitioningFromLoading = false;
                  });
                }
              });
            }
          });
        }
        return _buildWithValues(
          mediaTitle: vm.title,
          yearText: vm.yearText,
          durationText: vm.durationText,
          ratingText: vm.ratingText,
          overviewText: vm.overviewText,
          cast: vm.cast,
          recommendations: vm.recommendations,
          isLoading: _isTransitioningFromLoading,
          poster: vm.poster,
          backdrop: vm.backdrop,
          sagaLink: vm.sagaLink,
          movieId: media.id,
        );
      },
    );
  }

  Widget _buildErrorScaffold(Object e) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Text(
          AppLocalizations.of(context)!.errorWithMessage(e.toString()),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildWithValues({
    required String mediaTitle,
    required String yearText,
    required String durationText,
    required String ratingText,
    required String overviewText,
    required List<MoviPerson> cast,
    required List<MoviMedia> recommendations,
    required bool isLoading,
    Uri? poster,
    Uri? backdrop,
    SagaSummary? sagaLink,
    required String movieId,
  }) {
    final cs = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.headlineSmall;
    const heroHeight = 400.0;
    const overlayHeight = 200.0;
    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          top: true,
          bottom: true,
          child: AnimatedOpacity(
            opacity: isLoading ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(
                        mdp.movieDetailControllerProvider(movieId),
                      );
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MovieDetailHeroSection(
                            poster: poster,
                            backdrop: backdrop,
                            onBack: () => context.pop(),
                            onMore: _showMoreMenu,
                            height: heroHeight,
                            overlayHeight: overlayHeight,
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 20,
                              end: 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: AppSpacing.m),
                                Text(
                                  mediaTitle,
                                  style: titleStyle,
                                  textAlign: TextAlign.left,
                                ),
                                const SizedBox(height: AppSpacing.m),
                                MovieDetailMainActions(
                                  mediaTitle: mediaTitle,
                                  yearText: yearText,
                                  durationText: durationText,
                                  ratingText: ratingText,
                                  movieId: movieId,
                                  onPlay: () => _playMovie(context, mediaTitle),
                                ),
                                const SizedBox(height: AppSpacing.s),
                                MovieDetailSynopsisSection(text: overviewText),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 20,
                                  end: 20,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.castTitle,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.s),
                              MovieDetailCastSection(cast: cast),
                              const SizedBox(height: AppSpacing.l),
                              // Section saga (si le film fait partie d'une saga)
                              if (sagaLink != null)
                                MovieDetailSagaSection(
                                  sagaLink: sagaLink,
                                  currentMovieId: widget.media?.id,
                                ),
                              // Section recommandations
                              MovieDetailRecommendationsSection(
                                items: recommendations,
                              ),
                              const SizedBox(height: 70),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddToListDialog(
    BuildContext context,
    WidgetRef ref,
    String movieId,
  ) async {
    try {
      final playlistsAsync = ref.read(libraryPlaylistsProvider);
      final playlists = playlistsAsync.value;

      if (playlists == null || playlists.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.movieNoPlaylistsAvailable,
              ),
            ),
          );
        }
        return;
      }

      // Récupérer les données du film depuis le provider
      final vmAsync = ref.read(mdp.movieDetailControllerProvider(movieId));
      final vm = vmAsync.value;

      // Utiliser les données du widget si le view model n'est pas disponible
      final title = vm?.title ?? mediaTitle;
      final yearTextValue = vm?.yearText ?? yearText;
      final poster = widget.media?.poster ?? vm?.poster;

      // Filtrer les playlists selon le type de contenu
      final playlistRepository = ref.read(slProvider)<PlaylistRepository>();
      final availablePlaylists = <LibraryPlaylistItem>[];

      for (final playlist in playlists) {
        // Exclure les sagas et acteurs
        if (playlist.id.startsWith('saga_') ||
            playlist.type == LibraryPlaylistType.actor) {
          continue;
        }

        // Playlists favorites : films uniquement pour les films
        if (playlist.type == LibraryPlaylistType.favoriteMovies) {
          availablePlaylists.add(playlist);
          continue;
        }

        // Playlists favorites séries : exclure pour les films
        if (playlist.type == LibraryPlaylistType.favoriteSeries) {
          continue;
        }

        // Playlists utilisateur : vérifier le contenu
        if (playlist.type == LibraryPlaylistType.userPlaylist &&
            playlist.playlistId != null) {
          try {
            final playlistDetail = await playlistRepository.getPlaylist(
              PlaylistId(playlist.playlistId!),
            );

            // Si la playlist est vide, on peut ajouter
            if (playlistDetail.items.isEmpty) {
              availablePlaylists.add(playlist);
              continue;
            }

            // Vérifier si la playlist contient uniquement des films
            final hasOnlyMovies = playlistDetail.items.every(
              (item) => item.reference.type == ContentType.movie,
            );

            // Si la playlist contient uniquement des films, on peut ajouter le film
            if (hasOnlyMovies) {
              availablePlaylists.add(playlist);
            }
            // Si la playlist contient des séries, on ne peut pas ajouter un film
          } catch (_) {
            // En cas d'erreur, on inclut la playlist pour ne pas bloquer l'utilisateur
            availablePlaylists.add(playlist);
          }
        }
      }

      if (!mounted || !context.mounted) return;
      if (availablePlaylists.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.movieNoPlaylistsAvailable,
            ),
          ),
        );
        return;
      }

      showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(AppLocalizations.of(context)!.actionAddToList),
          actions: availablePlaylists.map((playlist) {
            return CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(ctx).pop();

                try {
                  if (playlist.type == LibraryPlaylistType.favoriteMovies) {
                    // Toggle favori
                    await ref
                        .read(mdp.movieToggleFavoriteProvider.notifier)
                        .toggle(movieId);
                    ref.invalidate(mdp.movieIsFavoriteProvider(movieId));

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                              context,
                            )!.playlistAddedTo(playlist.title),
                          ),
                        ),
                      );
                    }
                  } else if (playlist.type ==
                          LibraryPlaylistType.userPlaylist &&
                      playlist.playlistId != null) {
                    final usecase = ref.read(
                      mdp.addMovieToPlaylistUseCaseProvider,
                    );
                    final year = yearTextValue != '—'
                        ? int.tryParse(yearTextValue)
                        : null;
                    await usecase(
                      playlistId: playlist.playlistId!,
                      movieId: movieId,
                      title: title,
                      poster: poster,
                      year: year,
                    );

                    // Invalider tous les providers nécessaires
                    ref.invalidate(playlistItemsProvider(playlist.playlistId!));
                    ref.invalidate(
                      playlistContentReferencesProvider(playlist.playlistId!),
                    );
                    ref.invalidate(libraryPlaylistsProvider);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                              context,
                            )!.playlistAddedTo(playlist.title),
                          ),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                            context,
                          )!.errorWithMessage(e.toString()),
                        ),
                      ),
                    );
                  }
                }
              },
              child: Text(playlist.title),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.actionCancel),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorLoadingPlaylists(e.toString()),
            ),
          ),
        );
      }
    }
  }

  void _showMoreMenu() {
    final media = widget.media;
    if (media == null) return;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final movieId = media.id;
            final isAvailableAsync = ref.watch(
              mdp.movieAvailabilityProvider(movieId),
            );
            final isSeenAsync = ref.watch(mdp.movieSeenProvider(movieId));

            final isAvailable = isAvailableAsync.value ?? false;
            final isSeen = isSeenAsync.value ?? false;

            final actions = <Widget>[
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _onChangeMetadata();
                },
                child: Text(AppLocalizations.of(context)!.actionChangeMetadata),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showAddToListDialog(context, ref, movieId);
                },
                child: Text(AppLocalizations.of(context)!.actionAddToList),
              ),
            ];

            // Ajouter l'option vu/non vu seulement si le film est disponible
            if (isAvailable) {
              if (isSeen) {
                actions.add(
                  CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _markAsUnseen(movieId);
                    },
                    child: Text(AppLocalizations.of(context)!.actionMarkUnseen),
                  ),
                );
              } else {
                actions.add(
                  CupertinoActionSheetAction(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _markAsSeen(movieId, mediaTitle);
                    },
                    child: Text(AppLocalizations.of(context)!.actionMarkSeen),
                  ),
                );
              }
            }

            actions.add(
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text(AppLocalizations.of(context)!.actionReportProblem),
              ),
            );

            return CupertinoActionSheet(
              title: Text(mediaTitle),
              actions: actions,
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppLocalizations.of(context)!.actionCancel),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _markAsSeen(String movieId, String title) async {
    try {
      final usecase = ref.read(mdp.markMovieAsSeenUseCaseProvider);
      await usecase(
        movieId: movieId,
        title: title,
        poster: widget.media?.poster,
      );

      // Invalider les providers pour mettre à jour l'UI
      ref.invalidate(
        hp.mediaHistoryProvider((contentId: movieId, type: ContentType.movie)),
      );
      ref.invalidate(mdp.movieHistoryProvider(movieId));
      ref.invalidate(mdp.movieSeenProvider(movieId));
      ref.invalidate(libraryPlaylistsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.actionMarkSeen)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorWithMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _markAsUnseen(String movieId) async {
    try {
      final usecase = ref.read(mdp.markMovieAsUnseenUseCaseProvider);
      await usecase(movieId);

      // Invalider les providers pour mettre à jour l'UI
      ref.invalidate(
        hp.mediaHistoryProvider((contentId: movieId, type: ContentType.movie)),
      );
      ref.invalidate(mdp.movieHistoryProvider(movieId));
      ref.invalidate(mdp.movieSeenProvider(movieId));
      ref.invalidate(libraryPlaylistsProvider);
      ref.invalidate(hp.homeControllerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.actionMarkUnseen),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorWithMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  void _onChangeMetadata() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.featureComingSoon)),
    );
  }

  Future<void> _playMovie(BuildContext context, String title) async {
    final logger = ref.read(slProvider)<AppLogger>();
    try {
      final media = widget.media;
      if (media == null) return;
      Uri? posterUri = media.poster;
      if (posterUri == null) {
        final vmAsync = ref.read(mdp.movieDetailControllerProvider(media.id));
        vmAsync.whenData((vm) {
          posterUri = vm.poster;
        });
      }
      final args = (movieId: media.id, title: title, poster: posterUri);
      final source = await ref.read(
        mdp.buildMovieVideoSourceProvider(args).future,
      );
      if (source == null) {
        if (!mounted || !context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.movieNotAvailableInPlaylist,
            ),
          ),
        );
        return;
      }

      if (!mounted || !context.mounted) return;
      context.push(AppRouteNames.player, extra: source);
    } catch (e, st) {
      logger.error(
        AppLocalizations.of(context)!.errorPlaybackFailed(e.toString()),
        e,
        st,
      );
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorWithMessage(e.toString()),
          ),
        ),
      );
    }
  }
}
