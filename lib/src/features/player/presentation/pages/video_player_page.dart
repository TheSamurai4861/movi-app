import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:media_kit/media_kit.dart';
import 'package:movi/src/features/player/data/repositories/media_kit_video_player_repository.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/features/player/presentation/widgets/video_player_controls.dart';
import 'package:movi/src/features/player/presentation/widgets/track_selection_menu.dart';
import 'package:movi/src/core/storage/storage.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/preferences/player_preferences.dart';
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
import 'package:movi/src/features/tv/presentation/models/tv_detail_view_model.dart';
import 'package:movi/src/core/security/credentials_vault.dart';
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/player/domain/utils/language_formatter.dart';

/// Page de lecture vidéo avec contrôles personnalisés
class VideoPlayerPage extends ConsumerStatefulWidget {
  const VideoPlayerPage({super.key, this.videoSource});

  final VideoSource? videoSource;

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage>
    with SingleTickerProviderStateMixin {
  late final MediaKitVideoPlayerRepository _playerRepository;
  late final VideoController _videoController;
  Timer? _hideControlsTimer;
  late final AnimationController _controlsAnimationController;
  late final Animation<double> _controlsOpacityAnimation;
  bool _showControls = true;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = false;
  bool _hasSubtitles = false;
  bool _subtitlesEnabled = false;
  List<SubtitleTrack> _subtitleTracks = [];
  List<AudioTrack> _audioTracks = [];
  SubtitleTrack? _currentSubtitleTrack;
  AudioTrack? _currentAudioTrack;
  final GlobalKey _controlsKey = GlobalKey();
  bool _tracksInitialized = false;
  bool _resumePositionApplied = false;
  VideoSource? _currentVideoSource;

  @override
  void initState() {
    super.initState();

    // Forcer le mode paysage
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Masquer la barre de statut et la barre de navigation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _playerRepository = MediaKitVideoPlayerRepository();
    _videoController = VideoController(_playerRepository.player);

    // Animation d'opacité pour les contrôles
    _controlsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controlsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _setupListeners();
    _showControlsWithAnimation();
    _startHideControlsTimer();

    // Initialiser le VideoSource actuel
    _currentVideoSource = widget.videoSource;

    if (widget.videoSource != null) {
      _playerRepository.open(widget.videoSource!);
    }
  }

  void _setupListeners() {
    _playerRepository.player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });

    _playerRepository.player.stream.position.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _playerRepository.player.stream.duration.listen((duration) {
      if (mounted && duration != Duration.zero) {
        setState(() => _duration = duration);

        // Appliquer la position de reprise une seule fois quand la durée est disponible
        if (!_resumePositionApplied) {
          // Utiliser la position de reprise du VideoSource actuel si disponible
          if (_currentVideoSource?.resumePosition != null &&
              _currentVideoSource!.resumePosition! < duration) {
            _resumePositionApplied = true;
            _playerRepository.seekTo(_currentVideoSource!.resumePosition!);
          } else {
            // Si pas de position de reprise, commencer depuis le début
            _resumePositionApplied = true;
          }
        }
      }
    });

    _playerRepository.player.stream.buffering.listen((buffering) {
      if (mounted) {
        setState(() => _isBuffering = buffering);
      }
    });

    _playerRepository.player.stream.tracks.listen((tracks) {
      if (mounted) {
        setState(() {
          _hasSubtitles = tracks.subtitle.isNotEmpty;
          _subtitleTracks = tracks.subtitle;
          _audioTracks = tracks.audio;
        });
      }
    });

    // Mettre à jour les pistes actuelles quand les tracks changent et sélectionner selon les préférences
    _playerRepository.player.stream.tracks.listen((tracks) {
      if (mounted) {
        // Trouver la piste de sous-titres actuellement sélectionnée
        // En comparant avec les pistes disponibles
        SubtitleTrack? currentSubtitle;
        if (_currentSubtitleTrack != null && tracks.subtitle.isNotEmpty) {
          currentSubtitle = tracks.subtitle.firstWhere(
            (t) => t.id == _currentSubtitleTrack!.id,
            orElse: () => tracks.subtitle.first,
          );
        }

        // Trouver la piste audio actuellement sélectionnée
        AudioTrack? currentAudio;
        if (_currentAudioTrack != null && tracks.audio.isNotEmpty) {
          currentAudio = tracks.audio.firstWhere(
            (t) => t.id == _currentAudioTrack!.id,
            orElse: () => tracks.audio.first,
          );
        }

        // Sélection automatique selon les préférences uniquement lors du premier chargement
        if (!_tracksInitialized) {
          _selectPreferredTracks(tracks);
          _tracksInitialized = true;
        }

        // Mettre à jour les pistes actuelles après la sélection automatique
        setState(() {
          _currentSubtitleTrack = currentSubtitle ?? _currentSubtitleTrack;
          _currentAudioTrack = currentAudio ?? _currentAudioTrack;
          _subtitlesEnabled = _currentSubtitleTrack != null;
        });
      }
    });
  }

  /// Normalise un code de langue (enlève région, convertit en minuscule, etc.)
  String? _normalizeLanguageCode(String? code) {
    if (code == null || code.isEmpty) return null;

    return code
        .replaceAll('_', '-')
        .replaceAll(' ', '-')
        .toLowerCase()
        .split('-')
        .first;
  }

  /// Compare deux codes de langue en les normalisant
  bool _matchesLanguageCode(String? trackLanguage, String? preferredCode) {
    if (trackLanguage == null || preferredCode == null) return false;

    final normalizedTrack = _normalizeLanguageCode(trackLanguage);
    final normalizedPreferred = _normalizeLanguageCode(preferredCode);

    return normalizedTrack != null &&
        normalizedPreferred != null &&
        normalizedTrack == normalizedPreferred;
  }

  /// Extrait le code de langue d'une piste audio ou sous-titre
  /// Transforme les titres en noms de langues lisibles et extrait le code correspondant
  String? _extractLanguageCodeFromTrack(dynamic track) {
    // Essayer d'abord track.language
    if (track.language != null && track.language!.isNotEmpty) {
      return _normalizeLanguageCode(track.language);
    }

    // Sinon, essayer d'extraire depuis track.title
    if (track.title != null && track.title!.isNotEmpty) {
      final title = track.title!.toLowerCase();

      // Mapping des codes de langue vers leurs noms en français et anglais
      final languagePatterns = {
        'fr': ['fr', 'french', 'français', 'francais'],
        'en': ['en', 'english', 'anglais'],
        'es': ['es', 'spanish', 'espagnol'],
        'de': ['de', 'german', 'allemand'],
        'it': ['it', 'italian', 'italien'],
        'pt': ['pt', 'portuguese', 'portugais'],
        'ru': ['ru', 'russian', 'russe'],
        'ja': ['ja', 'japanese', 'japonais'],
        'ko': ['ko', 'korean', 'coréen', 'coreen'],
        'zh': ['zh', 'chinese', 'chinois'],
        'ar': ['ar', 'arabic', 'arabe'],
        'nl': ['nl', 'dutch', 'néerlandais', 'neerlandais'],
        'pl': ['pl', 'polish', 'polonais'],
        'tr': ['tr', 'turkish', 'turc'],
        'sv': ['sv', 'swedish', 'suédois', 'suedois'],
        'da': ['da', 'danish', 'danois'],
        'no': ['no', 'norwegian', 'norvégien', 'norvegien'],
        'fi': ['fi', 'finnish', 'finnois'],
        'cs': ['cs', 'czech', 'tchèque', 'tcheque'],
        'hu': ['hu', 'hungarian', 'hongrois'],
        'ro': ['ro', 'romanian', 'roumain'],
        'el': ['el', 'greek', 'grec'],
        'he': ['he', 'hebrew', 'hébreu', 'hebreu'],
        'th': ['th', 'thai', 'thaï', 'thai'],
        'vi': ['vi', 'vietnamese', 'vietnamien'],
        'id': ['id', 'indonesian', 'indonésien', 'indonesien'],
        'hi': ['hi', 'hindi'],
        'uk': ['uk', 'ukrainian', 'ukrainien'],
      };

      // Chercher d'abord par code de langue ou nom anglais/français
      for (final entry in languagePatterns.entries) {
        if (entry.value.any((pattern) => title.contains(pattern))) {
          return entry.key;
        }
      }

      // Si aucun pattern ne correspond, essayer de détecter depuis le nom formaté
      // Par exemple, si le titre contient "Français", on cherche le code correspondant
      final formattedTitle = LanguageFormatter.formatLanguageCode(title);
      if (formattedTitle != 'Inconnu' &&
          formattedTitle != title.toUpperCase()) {
        // Le titre a été reconnu comme une langue, chercher le code correspondant
        for (final entry in languagePatterns.entries) {
          final formattedLang = LanguageFormatter.formatLanguageCode(entry.key);
          if (formattedLang.toLowerCase() == formattedTitle.toLowerCase()) {
            return entry.key;
          }
        }
      }
    }

    return null;
  }

  /// Sélectionne automatiquement les pistes selon les préférences utilisateur
  Future<void> _selectPreferredTracks(Tracks tracks) async {
    try {
      final playerPrefs = ref.read(slProvider)<PlayerPreferences>();

      // Sélection de la piste audio préférée
      if (tracks.audio.isNotEmpty && _currentAudioTrack == null) {
        final preferredAudio = playerPrefs.preferredAudioLanguage;

        if (preferredAudio != null && preferredAudio.isNotEmpty) {
          // Chercher une piste audio correspondant à la langue préférée
          AudioTrack? matchingTrack;

          for (final track in tracks.audio) {
            final trackLanguage = _extractLanguageCodeFromTrack(track);
            if (trackLanguage != null &&
                _matchesLanguageCode(trackLanguage, preferredAudio)) {
              matchingTrack = track;
              break;
            }
          }

          if (matchingTrack != null) {
            await _playerRepository.player.setAudioTrack(matchingTrack);
            if (mounted) {
              setState(() {
                _currentAudioTrack = matchingTrack;
              });
            }
          }
          // Sinon, fallback sur la première piste disponible (comportement par défaut du lecteur)
        }
        // Si preferredAudio est null/empty, laisser le lecteur choisir automatiquement
      }

      // Sélection de la piste de sous-titres préférée
      if (tracks.subtitle.isNotEmpty) {
        final preferredSubtitle = playerPrefs.preferredSubtitleLanguage;

        if (preferredSubtitle != null && preferredSubtitle.isNotEmpty) {
          // Chercher une piste de sous-titres correspondant à la langue préférée
          SubtitleTrack? matchingTrack;

          for (final track in tracks.subtitle) {
            final trackLanguage = _extractLanguageCodeFromTrack(track);
            if (trackLanguage != null &&
                _matchesLanguageCode(trackLanguage, preferredSubtitle)) {
              matchingTrack = track;
              break;
            }
          }

          if (matchingTrack != null) {
            await _playerRepository.player.setSubtitleTrack(matchingTrack);
            if (mounted) {
              setState(() {
                _currentSubtitleTrack = matchingTrack;
                _subtitlesEnabled = true;
              });
            }
          }
          // Sinon, laisser les sous-titres désactivés
        } else {
          // Si preferredSubtitle est null/empty, s'assurer que les sous-titres sont désactivés
          if (mounted) {
            setState(() {
              _currentSubtitleTrack = null;
              _subtitlesEnabled = false;
            });
          }
        }
      }
    } catch (e) {
      // En cas d'erreur, continuer sans bloquer
      debugPrint('[VideoPlayer] Error selecting preferred tracks: $e');
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_showControls) {
      // Démarrer le timer même si pas encore en lecture
      _hideControlsTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _showControls) {
          // Masquer seulement si en lecture, sinon attendre
          if (_isPlaying) {
            _hideControlsWithAnimation();
          } else {
            // Si pas encore en lecture, relancer le timer
            _startHideControlsTimer();
          }
        }
      });
    }
  }

  void _showControlsWithAnimation() {
    setState(() => _showControls = true);
    _controlsAnimationController.forward();
    _startHideControlsTimer();
  }

  void _hideControlsWithAnimation() {
    _controlsAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _onScreenTap(TapDownDetails details) {
    // Vérifier si le tap est hors des contrôles
    if (_showControls) {
      final RenderBox? controlsBox =
          _controlsKey.currentContext?.findRenderObject() as RenderBox?;

      if (controlsBox != null) {
        final localPosition = controlsBox.globalToLocal(details.globalPosition);
        final isInsideControls = controlsBox.size.contains(localPosition);

        if (!isInsideControls) {
          // Tap hors des contrôles, les masquer avec animation d'opacité
          _hideControlsWithAnimation();
          return;
        }
        // Tap sur les contrôles, ne rien faire (les contrôles gèrent leurs propres clics)
        return;
      }

      // Si les contrôles sont affichés et qu'on tape sur l'écran, les masquer avec animation
      _hideControlsWithAnimation();
    } else {
      // Si les contrôles sont masqués, les afficher avec animation
      _showControlsWithAnimation();
    }
  }

  void _onDoubleTap(TapDownDetails details) {
    // Vérifier si le double tap est hors des contrôles
    final RenderBox? controlsBox =
        _controlsKey.currentContext?.findRenderObject() as RenderBox?;

    if (controlsBox != null) {
      final localPosition = controlsBox.globalToLocal(details.globalPosition);
      final isInsideControls = controlsBox.size.contains(localPosition);

      if (isInsideControls) {
        // Double tap sur les contrôles, ne rien faire
        return;
      }
    }

    // Double tap sur l'écran : gauche = -10s, droite = +10s
    final screenWidth = MediaQuery.of(context).size.width;
    final tapX = details.globalPosition.dx;
    final isLeftSide = tapX < screenWidth / 2;

    if (isLeftSide) {
      _seekBackward(10);
    } else {
      _seekForward(10);
    }

    // Afficher les contrôles après le double tap
    _showControlsWithAnimation();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _playerRepository.pause();
    } else {
      await _playerRepository.play();
    }
    _startHideControlsTimer();
  }

  Future<void> _seekForward(int seconds) async {
    await _playerRepository.seekForward(seconds);
    _startHideControlsTimer();
  }

  Future<void> _seekBackward(int seconds) async {
    await _playerRepository.seekBackward(seconds);
    _startHideControlsTimer();
  }

  Future<void> _onSeek(double value) async {
    final position = _duration * value;
    await _playerRepository.seekTo(position);
    _startHideControlsTimer();
  }

  Future<void> _restart() async {
    await _playerRepository.seekTo(Duration.zero);
    _startHideControlsTimer();
  }

  Future<void> _goToNextEpisode() async {
    final videoSource = widget.videoSource;
    if (videoSource == null ||
        videoSource.contentType != ContentType.series ||
        videoSource.contentId == null ||
        videoSource.season == null ||
        videoSource.episode == null) {
      return;
    }

    try {
      final locator = ref.read(slProvider);
      final iptvLocal = locator<IptvLocalRepository>();
      final vault = locator<CredentialsVault>();
      final networkExecutor = locator<NetworkExecutor>();
      final urlBuilder = XtreamStreamUrlBuilder(
        iptvLocal: iptvLocal,
        vault: vault,
        networkExecutor: networkExecutor,
      );

      // Charger les données de la série
      final vmAsync = ref.read(
        tvDetailProgressiveControllerProvider(videoSource.contentId!),
      );
      final vm = vmAsync.value;

      if (vm == null || vm.seasons.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de charger les données de la série'),
            ),
          );
        }
        return;
      }

      // Trouver l'épisode suivant
      final currentSeason = videoSource.season!;
      final currentEpisode = videoSource.episode!;

      EpisodeViewModel? nextEpisode;
      int? nextSeasonNumber;
      int? nextEpisodeNumber;

      // Chercher dans la saison actuelle
      final currentSeasonData = vm.seasons.firstWhere(
        (s) => s.seasonNumber == currentSeason,
        orElse: () => vm.seasons.first,
      );

      final currentEpisodeIndex = currentSeasonData.episodes.indexWhere(
        (e) => e.episodeNumber == currentEpisode,
      );

      if (currentEpisodeIndex >= 0 &&
          currentEpisodeIndex < currentSeasonData.episodes.length - 1) {
        // Épisode suivant dans la même saison
        nextEpisode = currentSeasonData.episodes[currentEpisodeIndex + 1];
        nextSeasonNumber = currentSeason;
        nextEpisodeNumber = nextEpisode.episodeNumber;
      } else {
        // Chercher dans la saison suivante
        final currentSeasonIndex = vm.seasons.indexWhere(
          (s) => s.seasonNumber == currentSeason,
        );

        if (currentSeasonIndex >= 0 &&
            currentSeasonIndex < vm.seasons.length - 1) {
          final nextSeasonData = vm.seasons[currentSeasonIndex + 1];
          if (nextSeasonData.episodes.isNotEmpty) {
            nextEpisode = nextSeasonData.episodes.first;
            nextSeasonNumber = nextSeasonData.seasonNumber;
            nextEpisodeNumber = nextEpisode.episodeNumber;
          }
        }
      }

      if (nextEpisode == null ||
          nextSeasonNumber == null ||
          nextEpisodeNumber == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun épisode suivant disponible')),
          );
        }
        return;
      }

      // Convertir le numéro d'épisode TMDB en numéro Xtream
      int xtreamEpisodeNumber = nextEpisodeNumber;
      final isGlobal = _isSeasonUsingGlobalNumbering(
        nextSeasonNumber,
        vm.seasons,
      );
      if (isGlobal) {
        xtreamEpisodeNumber = _convertTmdbEpisodeToXtream(
          nextEpisodeNumber,
          nextSeasonNumber,
          vm.seasons,
        );
      }

      // Chercher l'item Xtream correspondant
      XtreamPlaylistItem? xtreamItem;
      final accounts = await iptvLocal.getAccounts();
      final seriesId = videoSource.contentId!;

      for (final account in accounts) {
        final playlists = await iptvLocal.getPlaylists(account.id);
        for (final playlist in playlists) {
          if (seriesId.startsWith('xtream:')) {
            final streamIdStr = seriesId.substring(7);
            final streamId = int.tryParse(streamIdStr);
            if (streamId != null) {
              try {
                final found = playlist.items.firstWhere(
                  (item) => item.streamId == streamId,
                );
                if (found.type == XtreamPlaylistItemType.series &&
                    found.streamId > 0) {
                  xtreamItem = found;
                }
              } catch (_) {
                // Continue
              }
            }
          } else {
            final tmdbId = int.tryParse(seriesId);
            if (tmdbId != null) {
              try {
                final candidates = playlist.items
                    .where(
                      (item) =>
                          item.tmdbId == tmdbId &&
                          item.type == XtreamPlaylistItemType.series,
                    )
                    .toList();

                if (candidates.isNotEmpty) {
                  final validCandidate = candidates.firstWhere(
                    (item) => item.streamId > 0,
                    orElse: () => candidates.first,
                  );

                  if (validCandidate.streamId > 0) {
                    xtreamItem = validCandidate;
                  }
                }
              } catch (_) {
                // Continue
              }
            }
          }

          if (xtreamItem != null) break;
        }
        if (xtreamItem != null) break;
      }

      if (xtreamItem == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Épisode non disponible dans la playlist'),
            ),
          );
        }
        return;
      }

      // Construire l'URL de streaming
      final streamUrl = await urlBuilder.buildStreamUrlFromSeriesItem(
        item: xtreamItem,
        seasonNumber: nextSeasonNumber,
        episodeNumber: xtreamEpisodeNumber,
      );

      if (streamUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de construire l\'URL de streaming'),
            ),
          );
        }
        return;
      }

      // Construire le titre de l'épisode
      final seriesTitle = vm.title;
      final episodeTitle = nextEpisode.title.isNotEmpty
          ? '$seriesTitle - S${nextSeasonNumber.toString().padLeft(2, '0')}E${nextEpisodeNumber.toString().padLeft(2, '0')} - ${nextEpisode.title}'
          : '$seriesTitle - S${nextSeasonNumber.toString().padLeft(2, '0')}E${nextEpisodeNumber.toString().padLeft(2, '0')}';

      // Récupérer le poster
      Uri? posterUri = videoSource.poster;
      posterUri ??= vm.poster;

      // Sauvegarder l'historique de l'épisode actuel avant de changer
      if (_duration > Duration.zero) {
        try {
          final historyRepo = ref.read(slProvider)<HistoryLocalRepository>();
          await historyRepo.upsertPlay(
            contentId: videoSource.contentId!,
            type: videoSource.contentType!,
            title: videoSource.title ?? '',
            poster: videoSource.poster,
            position: _position,
            duration: _duration,
            season: currentSeason,
            episode: currentEpisode,
          );
        } catch (_) {
          // Ignorer les erreurs
        }
      }

      // Récupérer la position de reprise depuis l'historique
      // Si pas de position sauvegardée, on reprendra à 5% lors du chargement
      Duration? resumePosition;
      try {
        final historyRepo = ref.read(slProvider)<HistoryLocalRepository>();
        final historyEntry = await historyRepo.getEntry(
          seriesId,
          ContentType.series,
          season: nextSeasonNumber,
          episode: nextEpisodeNumber,
        );
        // Ne pas utiliser resumePosition si elle est inférieure à 5% (considérée comme non commencée)
        if (historyEntry?.lastPosition != null &&
            historyEntry!.lastPosition! > Duration.zero) {
          resumePosition = historyEntry.lastPosition;
        }
      } catch (e) {
        // Ignorer les erreurs
      }

      // Créer le nouveau VideoSource pour l'épisode suivant
      final nextVideoSource = VideoSource(
        url: streamUrl,
        title: episodeTitle,
        contentId: seriesId,
        contentType: ContentType.series,
        poster: posterUri,
        season: nextSeasonNumber,
        episode: nextEpisodeNumber,
        resumePosition: resumePosition,
      );

      // Mettre à jour le VideoSource actuel
      if (mounted) {
        setState(() {
          _currentVideoSource = nextVideoSource;
          _resumePositionApplied =
              false; // Réinitialiser pour permettre la reprise
          _tracksInitialized =
              false; // Réinitialiser pour re-sélectionner les pistes
          _position = Duration.zero;
          _duration = Duration.zero;
        });
      }

      // Changer l'URL de lecture sans changer de page
      await _playerRepository.open(nextVideoSource);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  /// Détecte si une saison utilise la numérotation globale ou relative
  bool _isSeasonUsingGlobalNumbering(
    int seasonNumber,
    List<SeasonViewModel> seasons,
  ) {
    SeasonViewModel season;
    try {
      season = seasons.firstWhere((s) => s.seasonNumber == seasonNumber);
    } catch (_) {
      season = seasons.first;
    }

    if (season.episodes.isEmpty) return false;

    final firstEpisodeNumber = season.episodes.first.episodeNumber;
    if (firstEpisodeNumber > 1) {
      return true;
    }

    final lastEpisodeNumber = season.episodes.last.episodeNumber;
    if (lastEpisodeNumber > season.episodes.length) {
      return true;
    }

    return false;
  }

  /// Convertit le numéro d'épisode TMDB en numéro relatif à la saison pour Xtream
  int _convertTmdbEpisodeToXtream(
    int tmdbEpisodeNumber,
    int seasonNumber,
    List<SeasonViewModel> seasons,
  ) {
    final isGlobal = _isSeasonUsingGlobalNumbering(seasonNumber, seasons);

    if (!isGlobal) {
      return tmdbEpisodeNumber;
    }

    int totalEpisodesBefore = 0;
    for (final season in seasons) {
      if (season.seasonNumber > 0 && season.seasonNumber < seasonNumber) {
        totalEpisodesBefore += season.episodes.length;
      }
    }

    final xtreamEpisodeNumber = tmdbEpisodeNumber - totalEpisodesBefore;
    return xtreamEpisodeNumber > 0 ? xtreamEpisodeNumber : 1;
  }

  Future<void> _showSubtitleMenu() async {
    if (_subtitleTracks.isEmpty) return;

    // Ne pas masquer les contrôles pendant la sélection
    _hideControlsTimer?.cancel();

    // S'assurer que le player continue de jouer
    final wasPlaying = _isPlaying;

    await showModalBottomSheet<SubtitleTrack?>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => SubtitleTrackSelectionMenu(
        tracks: _subtitleTracks,
        currentTrack: _currentSubtitleTrack,
        onTrackSelected: (track) async {
          await _playerRepository.player.setSubtitleTrack(track);
        },
        onDisable: () async {
          // Désactiver les sous-titres
          // Note: media_kit ne supporte pas directement null, donc on garde l'état local
          if (mounted) {
            setState(() {
              _currentSubtitleTrack = null;
              _subtitlesEnabled = false;
            });
          }
        },
      ),
    );

    // S'assurer que le player continue de jouer après la sélection
    if (mounted && wasPlaying && !_isPlaying) {
      await _playerRepository.play();
    }

    // Relancer le timer après la sélection
    if (mounted) {
      _startHideControlsTimer();
    }
  }

  Future<void> _showAudioMenu() async {
    if (_audioTracks.isEmpty) return;

    // Ne pas masquer les contrôles pendant la sélection
    _hideControlsTimer?.cancel();

    // S'assurer que le player continue de jouer
    final wasPlaying = _isPlaying;

    await showModalBottomSheet<AudioTrack?>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => AudioTrackSelectionMenu(
        tracks: _audioTracks,
        currentTrack: _currentAudioTrack,
        onTrackSelected: (track) async {
          await _playerRepository.player.setAudioTrack(track);
        },
      ),
    );

    // S'assurer que le player continue de jouer après la sélection
    if (mounted && wasPlaying && !_isPlaying) {
      await _playerRepository.play();
    }

    // Relancer le timer après la sélection
    if (mounted) {
      _startHideControlsTimer();
    }
  }

  void _onChromecast() {
    // TODO: Implémenter la fonctionnalité Chromecast
    // Nécessite l'ajout d'un package comme flutter_cast ou cast_framework
    // et la configuration des services Google Cast
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fonctionnalité Chromecast à venir'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    _startHideControlsTimer();
  }

  Future<void> _onBack(BuildContext context) async {
    // Sauvegarder l'historique avant de fermer le player
    // Utiliser le VideoSource actuel (peut être mis à jour lors du changement d'épisode)
    final videoSource = _currentVideoSource ?? widget.videoSource;

    if (videoSource?.contentId != null &&
        videoSource?.contentType != null &&
        _duration > Duration.zero) {
      try {
        final historyRepo = ref.read(slProvider)<HistoryLocalRepository>();
        await historyRepo.upsertPlay(
          contentId: videoSource!.contentId!,
          type: videoSource.contentType!,
          title: videoSource.title ?? '',
          poster: videoSource.poster,
          position: _position,
          duration: _duration,
          season: videoSource.season,
          episode: videoSource.episode,
        );

        // Invalider les providers pour rafraîchir la liste
        ref.invalidate(homeInProgressProvider);
        ref.invalidate(libraryPlaylistsProvider);
      } catch (_) {
        // Ignorer les erreurs
      }
    }

    // Fermer le player
    if (context.mounted) {
      context.pop();
    }
  }

  @override
  void dispose() {
    // Sauvegarder l'historique de l'épisode actuel avant de fermer
    // (au cas où l'app se ferme sans passer par _onBack)
    // C'est l'épisode qu'on regarde actuellement qui sera sauvegardé
    // et qui sera repris lors de la prochaine ouverture
    final videoSource = _currentVideoSource ?? widget.videoSource;
    if (videoSource?.contentId != null &&
        videoSource?.contentType != null &&
        _duration > Duration.zero) {
      try {
        final historyRepo = ref.read(slProvider)<HistoryLocalRepository>();
        // Fire-and-forget : on ne peut pas attendre dans dispose()
        historyRepo
            .upsertPlay(
              contentId: videoSource!.contentId!,
              type: videoSource.contentType!,
              title: videoSource.title ?? '',
              poster: videoSource.poster,
              position: _position,
              duration: _duration,
              season: videoSource.season,
              episode: videoSource.episode,
            )
            .catchError((_) {
              // Ignorer les erreurs silencieusement
            });
      } catch (_) {
        // Ignorer les erreurs
      }
    }

    _hideControlsTimer?.cancel();
    _controlsAnimationController.dispose();

    // Restaurer les orientations par défaut
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Restaurer la barre de statut
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _playerRepository.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser le VideoSource actuel (peut être mis à jour lors du changement d'épisode)
    final videoSource =
        _currentVideoSource ??
        widget.videoSource ??
        (GoRouterState.of(context).extra as VideoSource?);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onBack(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTapDown: _onScreenTap,
          onDoubleTapDown: _onDoubleTap,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Vidéo (sans contrôles natifs)
              Center(
                child: Video(
                  controller: _videoController,
                  controls: NoVideoControls,
                ),
              ),

              // Indicateur de chargement
              if (_isBuffering)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

              // Contrôles avec animation d'opacité
              if (_showControls)
                FadeTransition(
                  opacity: _controlsOpacityAnimation,
                  child: VideoPlayerControls(
                    key: _controlsKey,
                    title: videoSource?.title ?? '',
                    subtitle: videoSource?.subtitle,
                    isPlaying: _isPlaying,
                    position: _position,
                    duration: _duration,
                    hasSubtitles: _hasSubtitles,
                    subtitlesEnabled: _subtitlesEnabled,
                    onBack: () => _onBack(context),
                    onPlayPause: _togglePlayPause,
                    onSeekForward10: () => _seekForward(10),
                    onSeekForward30: () => _seekForward(30),
                    onSeekBackward10: () => _seekBackward(10),
                    onSeekBackward30: () => _seekBackward(30),
                    onSeek: _onSeek,
                    onToggleSubtitles: _showSubtitleMenu,
                    onAudio: _showAudioMenu,
                    onChromecast: _onChromecast,
                    formatDuration: _formatDuration,
                    hasAudioTracks: _audioTracks.isNotEmpty,
                    onRestart: _restart,
                    onNextEpisode:
                        videoSource?.contentType == ContentType.series
                        ? _goToNextEpisode
                        : null,
                    isSeries: videoSource?.contentType == ContentType.series,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
