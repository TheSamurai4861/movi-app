import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/src/core/widgets/widgets.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';
import 'package:movi/src/core/router/router.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
    as hp;
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart'
    as mdp;
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
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
import 'package:movi/src/core/parental/parental.dart' as parental;
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/core/parental/presentation/utils/parental_reason_localizer.dart';
import 'package:movi/src/core/parental/presentation/widgets/restricted_content_sheet.dart';
import 'package:movi/src/core/reporting/presentation/widgets/report_problem_sheet.dart';

class MovieDetailPage extends ConsumerStatefulWidget {
  const MovieDetailPage({super.key, required this.movieId});

  final String movieId;

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
    _startAutoRefreshTimer();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    final mediaId = widget.movieId;
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

  @override
  Widget build(BuildContext context) {
    final movieId = widget.movieId;
    final profile = ref.watch(currentProfileProvider);
    final hasRestrictions = profile != null && (profile.isKid || profile.pegiLimit != null);

    if (hasRestrictions) {
      final content = ContentReference(
        id: movieId,
        type: ContentType.movie,
        title: MediaTitle(movieId),
      );
      final decisionAsync = ref.watch(parental.contentAgeDecisionProvider(content));

      return decisionAsync.when(
        loading: () => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: const OverlaySplash(),
        ),
        error: (_, __) => _buildAllowedDetailScaffold(context, movieId),
        data: (decision) {
          if (decision.isAllowed) {
            return _buildAllowedDetailScaffold(context, movieId);
          }

          final l10n = AppLocalizations.of(context)!;
          final localizedReason = getLocalizedParentalReason(context, decision.reason);
          final displayMessage = localizedReason ?? l10n.parentalContentRestrictedDefault;

          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(title: Text(l10n.parentalContentRestricted)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      displayMessage,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final ok = await RestrictedContentSheet.show(
                          context,
                          ref,
                          profile: profile,
                          reason: decision.reason,
                        );
                        if (!ok) return;
                        ref.invalidate(parental.contentAgeDecisionProvider(content));
                        if (mounted) setState(() {});
                      },
                      child: Text('${l10n.parentalUnlockButton} (PIN)'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return _buildAllowedDetailScaffold(context, movieId);
  }

  Widget _buildAllowedDetailScaffold(BuildContext context, String movieId) {
    final vmAsync = ref.watch(mdp.movieDetailControllerProvider(movieId));

    // Détecter les erreurs et relancer automatiquement
    vmAsync.whenOrNull(
      error: (e, st) {
        if (mounted && _retryCount < _maxRetries) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _retryCount++;
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  ref.invalidate(mdp.movieDetailControllerProvider(movieId));
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
          movieId: movieId,
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
                  child: SyncableRefreshIndicator(
                    onRefresh: () async {
                      // Rafraîchir aussi le contenu local après la sync
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
                                  currentMovieId: widget.movieId,
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
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        const SnackBar(content: Text('Chargement des playlists...')),
      );

      final playlists = await ref.read(libraryPlaylistsProvider.future);

      // Récupérer les données du film depuis le provider
      // Vérifier que le widget est encore monté avant d'utiliser ref
      if (!mounted || !context.mounted) {
        messenger?.hideCurrentSnackBar();
        return;
      }
      messenger?.hideCurrentSnackBar();
      final vmAsync = ref.read(mdp.movieDetailControllerProvider(movieId));
      final vm = vmAsync.value;

      // Utiliser les données du widget si le view model n'est pas disponible
      final title = vm?.title ?? mediaTitle;
      final yearTextValue = vm?.yearText ?? yearText;
      final poster = vm?.poster;

      // Filtrer les playlists selon le type de contenu
      final availablePlaylists = <LibraryPlaylistItem>[];

      for (final playlist in playlists) {
        // Exclure les sagas et acteurs
        if (playlist.id.startsWith('saga_') ||
            playlist.type == LibraryPlaylistType.actor) {
          continue;
        }

        // Playlists utilisateur uniquement
        if (playlist.type == LibraryPlaylistType.userPlaylist &&
            playlist.playlistId != null) {
          availablePlaylists.add(playlist);
        }
      }

      if (availablePlaylists.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune playlist disponible. Créez en une'),
            ),
          );
        }
        return;
      }

      if (!mounted || !context.mounted) return;

      final container = ProviderScope.containerOf(context, listen: false);
      final playlistRepository = ref.read(slProvider)<PlaylistRepository>();
      final logger = ref.read(slProvider)<AppLogger>();
      final addPlaylistItem = AddPlaylistItem(playlistRepository);

      showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) {
          final actions = <CupertinoActionSheetAction>[];

          // Ajouter les playlists existantes
          actions.addAll(availablePlaylists.map((playlist) {
            return CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final canNotify = mounted && context.mounted;
                final l10n = AppLocalizations.of(context)!;
                final messenger = ScaffoldMessenger.maybeOf(context);
                final playlistIdToInvalidate = playlist.playlistId;

                try {
                  // Ajouter à la playlist utilisateur
                  // Utiliser les données disponibles
                  final year =
                      yearTextValue != '—' ? int.tryParse(yearTextValue) : null;

                  await addPlaylistItem.call(
                    playlistId: PlaylistId(playlist.playlistId!),
                    item: PlaylistItem(
                      reference: ContentReference(
                        id: movieId,
                        title: MediaTitle(title),
                        type: ContentType.movie,
                        poster: poster,
                        year: year,
                      ),
                      addedAt: DateTime.now(),
                    ),
                  );

                  // Vérifier que le widget est encore monté avant d'utiliser ref
                  // Invalider tous les providers nécessaires
                  // Note: Ces invalidations ne causeront pas de rebuild du dialogue
                  // car nous utilisons ref.read au lieu de ref.watch
                  container.invalidate(
                    playlistItemsProvider(playlistIdToInvalidate!),
                  );
                  container.invalidate(
                    playlistContentReferencesProvider(
                      playlistIdToInvalidate,
                    ),
                  );
                  container.invalidate(libraryPlaylistsProvider);

                  if (canNotify && messenger != null) {
                    _showTopNotification(
                      l10n,
                      messenger,
                      l10n.playlistAddedTo(playlist.title),
                    );
                  }
                } catch (e, stackTrace) {
                  // Logger l'erreur pour le debug (logger déjà capturé)
                  logger.log(
                    LogLevel.error,
                    'Erreur lors de l\'ajout à la playlist: $e',
                    error: e,
                    stackTrace: stackTrace,
                    category: 'movie_detail',
                  );

                  if (canNotify) {
                    // Gérer spécifiquement l'erreur de doublon
                    String errorMessage;
                    if (e is StateError &&
                        e.message.contains(
                          'déjà dans cette playlist',
                        )) {
                      errorMessage = 'Ce média est déjà dans cette playlist';
                    } else {
                      errorMessage = l10n.errorWithMessage(e.toString());
                    }

                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              child: Text(playlist.title),
            );
          }));

          return CupertinoActionSheet(
            title: Text(AppLocalizations.of(context)!.actionAddToList),
            actions: actions,
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(AppLocalizations.of(context)!.actionCancel),
            ),
          );
        },
      );
    } catch (e) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des playlists: $e'),
          ),
        );
      }
    }
  }

  void _showTopNotification(
    AppLocalizations l10n,
    ScaffoldMessengerState messenger,
    String message,
  ) {
    if (!mounted) return;
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: Text(l10n.actionConfirm),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      messenger.hideCurrentMaterialBanner();
    });
  }

  void _showMoreMenu() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final movieId = widget.movieId;
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
                  final tmdbId = int.tryParse(movieId);
                  if (tmdbId == null || tmdbId <= 0) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Signalement indisponible pour ce contenu.'),
                        ),
                      );
                    }
                    return;
                  }
                  unawaited(
                    ReportProblemSheet.show(
                      context,
                      ref,
                      contentType: ContentType.movie,
                      tmdbId: tmdbId,
                      contentTitle: mediaTitle,
                    ),
                  );
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
      final userId = ref.read(currentUserIdProvider);
      final poster = ref
          .read(mdp.movieDetailControllerProvider(movieId))
          .value
          ?.poster;
      await usecase(
        movieId: movieId,
        title: title,
        poster: poster,
        userId: userId,
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
      final userId = ref.read(currentUserIdProvider);
      await usecase(movieId, userId: userId);

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
      final movieId = widget.movieId;
      Uri? posterUri =
          ref.read(mdp.movieDetailControllerProvider(movieId)).value?.poster;
      if (posterUri == null) {
        final vmAsync = ref.read(mdp.movieDetailControllerProvider(movieId));
        vmAsync.whenData((vm) {
          posterUri = vm.poster;
        });
      }
      final args = (movieId: movieId, title: title, poster: posterUri);
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
