// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get welcomeTitle => 'Bienvenue !';

  @override
  String get welcomeSubtitle =>
      'Renseigne tes préférences pour personnaliser Movi.';

  @override
  String get labelUsername => 'Pseudo';

  @override
  String get labelPreferredLanguage => 'Langue préférée';

  @override
  String get actionContinue => 'Continuer';

  @override
  String get hintUsername => 'Ton pseudo';

  @override
  String get errorFillFields => 'Merci de remplir correctement les champs.';

  @override
  String get homeWatchNow => 'Regarder';

  @override
  String get welcomeSourceTitle => 'Bienvenue !';

  @override
  String get welcomeSourceSubtitle =>
      'Ajoute une source pour personnaliser ton expérience dans Movi.';

  @override
  String get welcomeSourceAdd => 'Ajouter une source';

  @override
  String get searchTitle => 'Recherche';

  @override
  String get searchHint => 'Tapez votre recherche';

  @override
  String get clear => 'Effacer';

  @override
  String get moviesTitle => 'Films';

  @override
  String get seriesTitle => 'Séries';

  @override
  String get noResults => 'Pas de résultats';

  @override
  String get historyTitle => 'Historique';

  @override
  String get historyEmpty => 'Aucune recherche récente';

  @override
  String get delete => 'Supprimer';

  @override
  String resultsCount(int count) {
    return '($count résultats)';
  }

  @override
  String get errorUnknown => 'Erreur inconnue';

  @override
  String errorConnectionFailed(String error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String get errorConnectionGeneric => 'Échec de la connexion';

  @override
  String get validationRequired => 'Requis';

  @override
  String get validationInvalidUrl => 'URL invalide';

  @override
  String get snackbarSourceAddedBackground =>
      'Source IPTV ajoutée. Synchronisation en arrière-plan…';

  @override
  String get snackbarSourceAddedSynced => 'Source IPTV ajoutée et synchronisée';

  @override
  String get navHome => 'Accueil';

  @override
  String get navSearch => 'Recherche';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLanguageLabel => 'Langue de l’application';

  @override
  String get settingsGeneralTitle => 'Préférences générales';

  @override
  String get settingsDarkModeTitle => 'Mode sombre';

  @override
  String get settingsDarkModeSubtitle => 'Active un thème adapté à la nuit.';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsSubtitle =>
      'Soyez averti des nouvelles sorties.';

  @override
  String get settingsAccountTitle => 'Compte';

  @override
  String get settingsProfileInfoTitle => 'Informations du profil';

  @override
  String get settingsProfileInfoSubtitle => 'Nom, avatar, préférences';

  @override
  String get settingsAboutTitle => 'À propos';

  @override
  String get settingsLegalMentionsTitle => 'Mentions légales';

  @override
  String get settingsPrivacyPolicyTitle => 'Politique de confidentialité';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionConfirm => 'Valider';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get homeErrorSwipeToRetry =>
      'Une erreur est survenue. Balayez vers le bas pour réessayer.';

  @override
  String get homeContinueWatching => 'En cours';

  @override
  String get homeNoIptvSources =>
      'Aucune source IPTV active. Ajoutez une source dans Paramètres pour voir vos catégories.';

  @override
  String get homeNoTrends => 'Aucune tendance disponible';

  @override
  String get actionRefreshMetadata => 'Rafraîchir les métadonnées';

  @override
  String get actionChangeMetadata => 'Changer les métadonnées';

  @override
  String get actionAddToList => 'Ajouter à une liste';

  @override
  String get metadataRefreshed => 'Métadonnées rafraîchies';

  @override
  String get errorRefreshingMetadata =>
      'Erreur lors du rafraîchissement des métadonnées';

  @override
  String get actionMarkSeen => 'Marquer comme vu';

  @override
  String get actionMarkUnseen => 'Marquer comme non vu';

  @override
  String get actionReportProblem => 'Signaler un problème';

  @override
  String get featureComingSoon => 'Fonctionnalité à venir';

  @override
  String get subtitlesMenuTitle => 'Sous-titres';

  @override
  String get audioMenuTitle => 'Audio';

  @override
  String get videoFitModeMenuTitle => 'Mode d\'affichage';

  @override
  String get videoFitModeContain => 'Proportions de base';

  @override
  String get videoFitModeCover => 'Tout l\'espace';

  @override
  String get actionDisable => 'Désactiver';

  @override
  String defaultTrackLabel(String id) {
    return 'Piste $id';
  }

  @override
  String get controlRewind10 => '10 s';

  @override
  String get controlRewind30 => '30 s';

  @override
  String get controlForward10 => '+ 10 s';

  @override
  String get controlForward30 => '+ 30 s';

  @override
  String get actionNextEpisode => 'Épisode suivant';

  @override
  String get actionRestart => 'Recommencer';

  @override
  String get errorSeriesDataUnavailable =>
      'Impossible de charger les données de la série';

  @override
  String get errorNextEpisodeFailed =>
      'Impossible de déterminer l\'épisode suivant';

  @override
  String get actionLoadMore => 'Charger plus';

  @override
  String get iptvServerUrlLabel => 'URL du serveur';

  @override
  String get iptvServerUrlHint => 'URL du serveur Xtream';

  @override
  String get iptvPasswordLabel => 'Mot de passe';

  @override
  String get iptvPasswordHint => 'Mot de passe Xtream';

  @override
  String get actionConnect => 'Se connecter';

  @override
  String get settingsRefreshIptvPlaylistsTitle =>
      'Rafraîchir les playlists IPTV';

  @override
  String get statusActive => 'Actif';

  @override
  String get statusNoActiveSource => 'Aucune source active';

  @override
  String get overlayPreparingHome => 'Préparation de l\'accueil…';

  @override
  String get bootstrapRefreshing => 'Rafraîchissement des listes IPTV…';

  @override
  String get bootstrapEnriching => 'Préparation des métadonnées…';

  @override
  String get errorPrepareHome => 'Impossible de préparer la page d\'accueil';

  @override
  String get overlayOpeningHome => 'Ouverture de l\'accueil…';

  @override
  String get overlayRefreshingIptvLists => 'Rafraîchissement des listes IPTV…';

  @override
  String get overlayPreparingMetadata => 'Préparation des métadonnées…';

  @override
  String get errorHomeLoadTimeout => 'Timeout de chargement de l\'accueil';

  @override
  String get faqLabel => 'FAQ';

  @override
  String get iptvUsernameLabel => 'Nom d’utilisateur';

  @override
  String get iptvUsernameHint => 'Identifiant Xtream';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionSeeAll => 'Voir tout';

  @override
  String get actionExpand => 'Agrandir';

  @override
  String get actionCollapse => 'Rétrécir';

  @override
  String providerSearchPlaceholder(String provider) {
    return 'Rechercher sur $provider...';
  }

  @override
  String get actionClearHistory => 'Supprimer l\'historique';

  @override
  String get castTitle => 'Distribution';

  @override
  String get recommendationsTitle => 'Recommandations';

  @override
  String get libraryHeader => 'Votre vidéothèque';

  @override
  String get libraryDataInfo =>
      'Les données seront affichées lorsque la couche data/domain sera implémentée.';

  @override
  String get libraryEmpty =>
      'Likez des films, séries ou acteurs pour les voir apparaître ici.';

  @override
  String get serie => 'Série';

  @override
  String get recherche => 'Recherche';

  @override
  String get notYetAvailable => 'Pas encore disponible';

  @override
  String get createPlaylistTitle => 'Créer une playlist';

  @override
  String get playlistName => 'Nom de la playlist';

  @override
  String get addMedia => 'Ajouter des médias';

  @override
  String get renamePlaylist => 'Renommer';

  @override
  String get deletePlaylist => 'Supprimer';

  @override
  String get pinPlaylist => 'Épingler';

  @override
  String get unpinPlaylist => 'Désépingler';

  @override
  String get playlistPinned => 'Playlist épinglée';

  @override
  String get playlistUnpinned => 'Playlist désépinglée';

  @override
  String get playlistDeleted => 'Playlist supprimée';

  @override
  String playlistCreatedSuccess(String name) {
    return 'Playlist \"$name\" créée';
  }

  @override
  String playlistCreateError(String error) {
    return 'Erreur lors de la création: $error';
  }

  @override
  String get addedToPlaylist => 'Ajouté';

  @override
  String get pinRecoveryLink => 'Récupérer le code PIN';

  @override
  String get pinRecoveryTitle => 'Récupérer code PIN';

  @override
  String get pinRecoveryDescription =>
      'Récupérez le code PIN de votre profil protégé.';

  @override
  String get pinRecoveryComingSoon => 'Cette fonctionnalité arrive bientôt.';

  @override
  String get pinRecoveryCodeLabel => 'Code de récupération';

  @override
  String get pinRecoveryCodeHint => '8 chiffres';

  @override
  String get pinRecoveryVerifyButton => 'Vérifier';

  @override
  String get pinRecoveryCodeInvalid => 'Saisissez le code à 8 chiffres';

  @override
  String get pinRecoveryCodeExpired => 'Le code de récupération a expiré';

  @override
  String get pinRecoveryTooManyAttempts =>
      'Trop de tentatives. Réessayez plus tard.';

  @override
  String get pinRecoveryUnknownError => 'Une erreur inattendue est survenue';

  @override
  String get pinRecoveryNewPinLabel => 'Nouveau PIN';

  @override
  String get pinRecoveryNewPinHint => '4-6 chiffres';

  @override
  String get pinRecoveryConfirmPinLabel => 'Confirmer le PIN';

  @override
  String get pinRecoveryConfirmPinHint => 'Répéter le PIN';

  @override
  String get pinRecoveryResetButton => 'Mettre à jour le PIN';

  @override
  String get pinRecoveryPinInvalid => 'Saisissez un PIN de 4 à 6 chiffres';

  @override
  String get pinRecoveryPinMismatch => 'Les PIN ne correspondent pas';

  @override
  String get pinRecoveryResetSuccess => 'PIN mis à jour';

  @override
  String get settingsAccountsSection => 'Comptes';

  @override
  String get settingsIptvSection => 'Paramètres IPTV';

  @override
  String get settingsSourcesManagement => 'Réglages des sources';

  @override
  String get settingsSyncFrequency => 'Fréquence màj';

  @override
  String get settingsAppSection => 'Paramètres de l\'application';

  @override
  String get settingsAccentColor => 'Couleur d\'accent';

  @override
  String get settingsPlaybackSection => 'Paramètres de lecture';

  @override
  String get settingsPreferredAudioLanguage => 'Langue préférée';

  @override
  String get settingsPreferredSubtitleLanguage => 'Sous-titres préférés';

  @override
  String get libraryPlaylistsFilter => 'Playlists';

  @override
  String get librarySagasFilter => 'Sagas';

  @override
  String get libraryArtistsFilter => 'Artistes';

  @override
  String get librarySearchPlaceholder => 'Rechercher dans ma bibliothèque...';

  @override
  String get libraryInProgress => 'En cours';

  @override
  String get libraryFavoriteMovies => 'Films favoris';

  @override
  String get libraryFavoriteSeries => 'Séries favorites';

  @override
  String get libraryWatchHistory => 'Historique de visionnage';

  @override
  String libraryItemCount(int count) {
    return '$count élément';
  }

  @override
  String libraryItemCountPlural(int count) {
    return '$count éléments';
  }

  @override
  String get searchPeopleTitle => 'Personnalités';

  @override
  String get searchSagasTitle => 'Sagas';

  @override
  String get searchByProvidersTitle => 'Par fournisseurs';

  @override
  String get searchByGenresTitle => 'Par genre';

  @override
  String get personRoleActor => 'Acteur';

  @override
  String get personRoleDirector => 'Réalisateur';

  @override
  String get personRoleCreator => 'Créateur';

  @override
  String get tvDistribution => 'Distribution';

  @override
  String tvSeasonLabel(int number) {
    return 'Saison $number';
  }

  @override
  String get tvNoEpisodesAvailable => 'Aucun épisode disponible';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return 'Reprendre S$season E$episode';
  }

  @override
  String get sagaViewPage => 'Voir la page';

  @override
  String get sagaStartNow => 'Commencer maintenant';

  @override
  String get sagaContinue => 'Poursuivre';

  @override
  String sagaMovieCount(int count) {
    return '$count films';
  }

  @override
  String get sagaMoviesList => 'Liste des films';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies films - $shows séries';
  }

  @override
  String get personPlayRandomly => 'Lire aléatoirement';

  @override
  String get personMoviesList => 'Liste des films';

  @override
  String get personSeriesList => 'Liste des séries';

  @override
  String get playlistPlayRandomly => 'Lire aléatoirement';

  @override
  String get playlistAddButton => 'Ajouter';

  @override
  String get playlistSortButton => 'Trier';

  @override
  String get playlistSortByTitle => 'Trier par';

  @override
  String get playlistSortByTitleOption => 'Titre';

  @override
  String get playlistSortRecentAdditions => 'Ajout récents';

  @override
  String get playlistSortOldestFirst => 'Anciens d\'abord';

  @override
  String get playlistSortNewestFirst => 'Récents d\'abord';

  @override
  String get playlistEmptyMessage => 'Aucun élément dans cette playlist';

  @override
  String playlistItemCount(int count) {
    return '$count élément';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count éléments';
  }

  @override
  String get playlistSeasonSingular => 'saison';

  @override
  String get playlistSeasonPlural => 'saisons';

  @override
  String get playlistRenameTitle => 'Renommer la playlist';

  @override
  String get playlistNamePlaceholder => 'Nom de la playlist';

  @override
  String playlistRenamedSuccess(String name) {
    return 'Playlist renommée en \"$name\"';
  }

  @override
  String get playlistDeleteTitle => 'Supprimer';

  @override
  String playlistDeleteConfirm(String title) {
    return 'Êtes-vous sûr de vouloir supprimer \"$title\" ?';
  }

  @override
  String get playlistDeletedSuccess => 'Playlist supprimée';

  @override
  String get playlistItemRemovedSuccess => 'Élément supprimé';

  @override
  String playlistRemoveItemConfirm(String title) {
    return 'Supprimer \"$title\" de la playlist ?';
  }

  @override
  String get categoryLoadFailed => 'Échec du chargement de la catégorie.';

  @override
  String get categoryEmpty => 'Aucun élément dans cette catégorie.';

  @override
  String get categoryLoadingMore => 'Chargement en cours…';

  @override
  String get movieNoPlaylistsAvailable => 'Aucune playlist disponible';

  @override
  String playlistAddedTo(String title) {
    return 'Ajouté à \"$title\"';
  }

  @override
  String errorWithMessage(String message) {
    return 'Erreur: $message';
  }

  @override
  String get movieNotAvailableInPlaylist =>
      'Film non disponible dans la playlist';

  @override
  String errorLoadingPlaylists(String message) {
    return 'Erreur lors du chargement des playlists: $message';
  }

  @override
  String errorPlaybackFailed(String message) {
    return 'Erreur lors de la lecture du film: $message';
  }

  @override
  String get movieNoMedia => 'Aucun média à afficher';

  @override
  String get personNoData => 'Aucune personnalité à afficher.';

  @override
  String get personGenericError =>
      'Une erreur est survenue lors du chargement de cette personnalité.';

  @override
  String get personBiographyTitle => 'Biographie';

  @override
  String get authOtpTitle => 'Connexion';

  @override
  String get authOtpSubtitle =>
      'Saisissez votre e-mail et le code à 8 chiffres que nous vous envoyons.';

  @override
  String get authOtpEmailLabel => 'E-mail';

  @override
  String get authOtpEmailHint => 'votre@email';

  @override
  String get authOtpEmailHelp =>
      'Nous vous enverrons un code à 8 chiffres. Vérifiez les spams si besoin.';

  @override
  String get authOtpCodeLabel => 'Code de vérification';

  @override
  String get authOtpCodeHint => 'Code à 8 chiffres';

  @override
  String get authOtpCodeHelp =>
      'Saisissez le code à 8 chiffres reçu par e-mail.';

  @override
  String get authOtpPrimarySend => 'Envoyer le code';

  @override
  String get authOtpPrimarySubmit => 'Se connecter';

  @override
  String get authOtpResend => 'Renvoyer le code';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Renvoyer le code dans ${seconds}s';
  }

  @override
  String get authOtpChangeEmail => 'Changer d’e-mail';

  @override
  String get resumePlayback => 'Reprendre lecture';

  @override
  String get settingsCloudSyncSection => 'Synchronisation Cloud';

  @override
  String get settingsCloudSyncAuto => 'Synchronisation auto';

  @override
  String get settingsCloudSyncNow => 'Synchroniser maintenant';

  @override
  String get settingsCloudSyncInProgress => 'Synchronisation…';

  @override
  String get settingsCloudSyncNever => 'Jamais';

  @override
  String settingsCloudSyncError(Object error) {
    return 'Dernière erreur : $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return '$entity introuvable';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return '$entity introuvable : $error';
  }

  @override
  String get entityProvider => 'Provider';

  @override
  String get entityGenre => 'Genre';

  @override
  String get entityPlaylist => 'Playlist';

  @override
  String get entitySource => 'Source';

  @override
  String get entityMovie => 'Film';

  @override
  String get entitySeries => 'Série';

  @override
  String get entityPerson => 'Personne';

  @override
  String get entitySaga => 'Saga';

  @override
  String get entityVideo => 'Vidéo';

  @override
  String get entityRoute => 'Route';

  @override
  String get errorTimeoutLoading => 'Timeout lors du chargement';

  @override
  String get parentalContentRestricted => 'Contenu restreint';

  @override
  String get parentalContentRestrictedDefault =>
      'Ce contenu est bloqué par le contrôle parental de ce profil.';

  @override
  String get parentalReasonTooYoung =>
      'Ce contenu nécessite un âge supérieur à la limite de ce profil.';

  @override
  String get parentalReasonUnknownRating =>
      'Le classement d\'âge de ce contenu n\'est pas disponible.';

  @override
  String get parentalReasonInvalidTmdbId =>
      'Ce contenu ne peut pas être évalué pour le contrôle parental.';

  @override
  String get parentalUnlockButton => 'Débloquer';
}

/// The translations for French, as used in Myanmar (`fr_MM`).
class AppLocalizationsFrMm extends AppLocalizationsFr {
  AppLocalizationsFrMm() : super('fr_MM');

  @override
  String get welcomeTitle => 'Que nenni ! Bienv\'nû !';

  @override
  String get welcomeSubtitle =>
      'Remplis tes préférences, c’est point couettos mais utile.';

  @override
  String get labelUsername => 'Sobriquet';

  @override
  String get labelPreferredLanguage => 'Langage de la bourgogne';

  @override
  String get actionContinue => 'Avançons';

  @override
  String get hintUsername => 'Ton sobriquet';

  @override
  String get errorFillFields => 'Faut point oublier d’emplir les champs.';

  @override
  String get homeWatchNow => 'Regarder';

  @override
  String get welcomeSourceTitle => 'Bienv\'nû !';

  @override
  String get welcomeSourceSubtitle =>
      'Ajoute une source, que diable, pour personnaliser Movi.';

  @override
  String get welcomeSourceAdd => 'Ajouter la souce';

  @override
  String get searchTitle => 'Quérir';

  @override
  String get searchHint => 'Tape ta quête';

  @override
  String get clear => 'Ôter';

  @override
  String get moviesTitle => 'Bobines';

  @override
  String get seriesTitle => 'Feuilletons';

  @override
  String get noResults => 'Point de résultat';

  @override
  String get historyTitle => 'Chronique';

  @override
  String get historyEmpty => 'Point de recherche récente';

  @override
  String get delete => 'Pourfendre';

  @override
  String resultsCount(int count) {
    return '($count trouvailles)';
  }

  @override
  String get errorUnknown => 'Méprise inconnue';

  @override
  String errorConnectionFailed(String error) {
    return 'Connexion faillie : $error';
  }

  @override
  String get errorConnectionGeneric => 'Connexion faillie';

  @override
  String get validationRequired => 'Obligé';

  @override
  String get validationInvalidUrl => 'L’adresse est point bonne';

  @override
  String get snackbarSourceAddedBackground =>
      'Source IPTV ajoutée. Ça s’active en coulisse…';

  @override
  String get snackbarSourceAddedSynced => 'Source IPTV ajoutée et arrimée';

  @override
  String get navHome => 'Gîte';

  @override
  String get navSearch => 'Quête';

  @override
  String get navLibrary => 'Réserve';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguageLabel => 'Langage de l’appli';

  @override
  String get settingsGeneralTitle => 'Préférences générales';

  @override
  String get settingsDarkModeTitle => 'Nuit noire';

  @override
  String get settingsDarkModeSubtitle =>
      'Active un thème pour besogner la nuit.';

  @override
  String get settingsNotificationsTitle => 'Avises';

  @override
  String get settingsNotificationsSubtitle => 'Soyez prévenus des nouveautés.';

  @override
  String get settingsAccountTitle => 'Comptoir';

  @override
  String get settingsProfileInfoTitle => 'Billets du profil';

  @override
  String get settingsProfileInfoSubtitle => 'Nom, effigie, préférences';

  @override
  String get settingsAboutTitle => 'À propos';

  @override
  String get settingsLegalMentionsTitle => 'Mentions légales';

  @override
  String get settingsPrivacyPolicyTitle => 'Privautés';

  @override
  String get actionCancel => 'Abandonner';

  @override
  String get actionConfirm => 'Valider la chose';

  @override
  String get actionRetry => 'Recommencer';

  @override
  String get homeErrorSwipeToRetry =>
      'Un couac est advenu. Tire en bas pour réessayer.';

  @override
  String get homeContinueWatching => 'En cours';

  @override
  String get homeNoIptvSources =>
      'Point de source IPTV. Ajoute-en dans Ajustes pour voir tes catégories.';

  @override
  String get homeNoTrends => 'Point de tendances';

  @override
  String get actionRefreshMetadata => 'Rafraîchir les bilboquets';

  @override
  String get actionChangeMetadata => 'Changer les bilboquets';

  @override
  String get actionAddToList => 'Mettre en la liste';

  @override
  String get metadataRefreshed => 'Bilboquets rafraîchis';

  @override
  String get errorRefreshingMetadata =>
      'Couac lors du rafraîchissement des bilboquets';

  @override
  String get actionMarkSeen => 'Marquer comme vu';

  @override
  String get actionMarkUnseen => 'Marquer comme point vu';

  @override
  String get actionReportProblem => 'Signaler un couac';

  @override
  String get featureComingSoon => 'Fonction à venir';

  @override
  String get subtitlesMenuTitle => 'Sous-titres';

  @override
  String get audioMenuTitle => 'Audio';

  @override
  String get videoFitModeMenuTitle => 'Mode d\'affichage';

  @override
  String get videoFitModeContain => 'Proportions de base';

  @override
  String get videoFitModeCover => 'Tout l\'espace';

  @override
  String get actionDisable => 'Désactiver';

  @override
  String defaultTrackLabel(String id) {
    return 'Piste $id';
  }

  @override
  String get controlRewind10 => '10 s';

  @override
  String get controlRewind30 => '30 s';

  @override
  String get controlForward10 => '+ 10 s';

  @override
  String get controlForward30 => '+ 30 s';

  @override
  String get actionNextEpisode => 'Épisode suivant';

  @override
  String get actionRestart => 'Recommencer';

  @override
  String get errorSeriesDataUnavailable =>
      'Impossible de charger les données de la série';

  @override
  String get errorNextEpisodeFailed =>
      'Impossible de déterminer l\'épisode suivant';

  @override
  String get actionLoadMore => 'Charger davantage';

  @override
  String get iptvServerUrlLabel => 'Adresse du serveur';

  @override
  String get iptvServerUrlHint => 'Adresse du serveur Xtream';

  @override
  String get iptvPasswordLabel => 'Mot de passe';

  @override
  String get iptvPasswordHint => 'Mot de passe Xtream';

  @override
  String get actionConnect => 'Se relier';

  @override
  String get settingsRefreshIptvPlaylistsTitle => 'Rafraîchir les listes IPTV';

  @override
  String get statusActive => 'Actif';

  @override
  String get statusNoActiveSource => 'Point de source active';

  @override
  String get overlayPreparingHome => 'Préparation du gîte…';

  @override
  String get bootstrapRefreshing => 'Rafraîchissement des listes IPTV…';

  @override
  String get bootstrapEnriching => 'Préparation des billets…';

  @override
  String get errorPrepareHome => 'Impossible de préparer la page du gîte';

  @override
  String get overlayOpeningHome => 'Ouverture du gîte…';

  @override
  String get overlayRefreshingIptvLists => 'Rafraîchissement des listes IPTV…';

  @override
  String get overlayPreparingMetadata => 'Préparation des billets…';

  @override
  String get errorHomeLoadTimeout => 'Délai de chargement du gîte dépassé';

  @override
  String get faqLabel => 'FAQ';

  @override
  String get iptvUsernameLabel => 'Nom d’utilisateur';

  @override
  String get iptvUsernameHint => 'Identifiant Xtream';

  @override
  String get actionBack => 'Retour';

  @override
  String get actionSeeAll => 'Voir tout';

  @override
  String get actionExpand => 'Élargir';

  @override
  String get actionCollapse => 'Rétrécir';

  @override
  String providerSearchPlaceholder(String provider) {
    return 'Rechercher sur $provider...';
  }

  @override
  String get actionClearHistory => 'Pourfendre la chronique';

  @override
  String get castTitle => 'Troupe';

  @override
  String get recommendationsTitle => 'Conseils';

  @override
  String get libraryHeader => 'Ta réserve';

  @override
  String get libraryDataInfo =>
      'Les données s\'afficheront quand la couche data/domain sera arrimée.';

  @override
  String get libraryEmpty =>
      'Likez des films, séries ou acteurs pour les voir apparaître ici.';

  @override
  String get serie => 'Feuilleton';

  @override
  String get recherche => 'Quête';

  @override
  String get notYetAvailable => 'Pas encore disponible';

  @override
  String get createPlaylistTitle => 'Créer une liste';

  @override
  String get playlistName => 'Nom de la liste';

  @override
  String get addMedia => 'Ajouter des médias';

  @override
  String get renamePlaylist => 'Renommer';

  @override
  String get deletePlaylist => 'Supprimer';

  @override
  String get pinPlaylist => 'Épingler';

  @override
  String get unpinPlaylist => 'Désépingler';

  @override
  String get playlistPinned => 'Liste épinglée';

  @override
  String get playlistUnpinned => 'Liste désépinglée';

  @override
  String get playlistDeleted => 'Liste supprimée';

  @override
  String playlistCreatedSuccess(String name) {
    return 'Liste \"$name\" créée';
  }

  @override
  String playlistCreateError(String error) {
    return 'Couac lors de la création : $error';
  }

  @override
  String get addedToPlaylist => 'Ajouté';

  @override
  String get pinRecoveryLink => 'Récupérer le code PIN';

  @override
  String get pinRecoveryTitle => 'Récupérer code PIN';

  @override
  String get pinRecoveryDescription =>
      'Récupérez le code PIN de votre profil protégé.';

  @override
  String get pinRecoveryComingSoon => 'Cette fonctionnalité arrive bientôt.';

  @override
  String get pinRecoveryCodeLabel => 'Code de récupération';

  @override
  String get pinRecoveryCodeHint => '8 chiffres';

  @override
  String get pinRecoveryVerifyButton => 'Vérifier';

  @override
  String get pinRecoveryCodeInvalid => 'Saisissez le code à 8 chiffres';

  @override
  String get pinRecoveryCodeExpired => 'Le code de récupération a expiré';

  @override
  String get pinRecoveryTooManyAttempts =>
      'Trop de tentatives. Réessayez plus tard.';

  @override
  String get pinRecoveryUnknownError => 'Une erreur inattendue est survenue';

  @override
  String get pinRecoveryNewPinLabel => 'Nouveau PIN';

  @override
  String get pinRecoveryNewPinHint => '4-6 chiffres';

  @override
  String get pinRecoveryConfirmPinLabel => 'Confirmer le PIN';

  @override
  String get pinRecoveryConfirmPinHint => 'Répéter le PIN';

  @override
  String get pinRecoveryResetButton => 'Mettre à jour le PIN';

  @override
  String get pinRecoveryPinInvalid => 'Saisissez un PIN de 4 à 6 chiffres';

  @override
  String get pinRecoveryPinMismatch => 'Les PIN ne correspondent pas';

  @override
  String get pinRecoveryResetSuccess => 'PIN mis à jour';

  @override
  String get settingsAccountsSection => 'Comptoirs';

  @override
  String get settingsIptvSection => 'Ajustes IPTV';

  @override
  String get settingsSourcesManagement => 'Réglages des sources';

  @override
  String get settingsSyncFrequency => 'Fréquence màj';

  @override
  String get settingsAppSection => 'Ajustes de l\'appli';

  @override
  String get settingsAccentColor => 'Couleur d\'accent';

  @override
  String get settingsPlaybackSection => 'Ajustes de lecture';

  @override
  String get settingsPreferredAudioLanguage => 'Langage préféré';

  @override
  String get settingsPreferredSubtitleLanguage => 'Sous-titres préférés';

  @override
  String get libraryPlaylistsFilter => 'Listes';

  @override
  String get librarySagasFilter => 'Sagas';

  @override
  String get libraryArtistsFilter => 'Artistes';

  @override
  String get librarySearchPlaceholder => 'Quérir dans ma réserve...';

  @override
  String get libraryInProgress => 'En cours';

  @override
  String get libraryFavoriteMovies => 'Bobines favorites';

  @override
  String get libraryFavoriteSeries => 'Feuilletons favoris';

  @override
  String get libraryWatchHistory => 'Chronique de visionnage';

  @override
  String libraryItemCount(int count) {
    return '$count élément';
  }

  @override
  String libraryItemCountPlural(int count) {
    return '$count éléments';
  }

  @override
  String get searchPeopleTitle => 'Personnalités';

  @override
  String get searchSagasTitle => 'Sagas';

  @override
  String get searchByProvidersTitle => 'Par fournisseurs';

  @override
  String get searchByGenresTitle => 'Par genre';

  @override
  String get personRoleActor => 'Acteur';

  @override
  String get personRoleDirector => 'Réalisateur';

  @override
  String get personRoleCreator => 'Créateur';

  @override
  String get tvDistribution => 'Troupe';

  @override
  String tvSeasonLabel(int number) {
    return 'Saison $number';
  }

  @override
  String get tvNoEpisodesAvailable => 'Point d\'épisode disponible';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return 'Reprendre S$season E$episode';
  }

  @override
  String get sagaViewPage => 'Voir la page';

  @override
  String get sagaStartNow => 'Commencer toutim';

  @override
  String get sagaContinue => 'Poursuivre';

  @override
  String sagaMovieCount(int count) {
    return '$count bobines';
  }

  @override
  String get sagaMoviesList => 'Liste des bobines';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies bobines - $shows feuilletons';
  }

  @override
  String get personPlayRandomly => 'Lire aléatoirement';

  @override
  String get personMoviesList => 'Liste des bobines';

  @override
  String get personSeriesList => 'Liste des feuilletons';

  @override
  String get playlistPlayRandomly => 'Lire aléatoirement';

  @override
  String get playlistAddButton => 'Ajouter';

  @override
  String get playlistSortButton => 'Trier';

  @override
  String get playlistSortByTitle => 'Trier par';

  @override
  String get playlistSortByTitleOption => 'Titre';

  @override
  String get playlistSortRecentAdditions => 'Ajout récents';

  @override
  String get playlistSortOldestFirst => 'Anciens d\'abord';

  @override
  String get playlistSortNewestFirst => 'Récents d\'abord';

  @override
  String get playlistEmptyMessage => 'Point d\'élément dans cette liste';

  @override
  String playlistItemCount(int count) {
    return '$count élément';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count éléments';
  }

  @override
  String get playlistSeasonSingular => 'saison';

  @override
  String get playlistSeasonPlural => 'saisons';

  @override
  String get playlistRenameTitle => 'Renommer la liste';

  @override
  String get playlistNamePlaceholder => 'Nom de la liste';

  @override
  String playlistRenamedSuccess(String name) {
    return 'Liste renommée en \"$name\"';
  }

  @override
  String get playlistDeleteTitle => 'Supprimer';

  @override
  String playlistDeleteConfirm(String title) {
    return 'Êtes-vous sûr de vouloir supprimer \"$title\" ?';
  }

  @override
  String get playlistDeletedSuccess => 'Liste supprimée';

  @override
  String get playlistItemRemovedSuccess => 'Élément supprimé';

  @override
  String playlistRemoveItemConfirm(String title) {
    return 'Supprimer \"$title\" de la liste ?';
  }

  @override
  String get categoryLoadFailed => 'Couac lors du chargement de la catégorie.';

  @override
  String get categoryEmpty => 'Point d\'élément dans cette catégorie.';

  @override
  String get categoryLoadingMore => 'Chargement en cours…';

  @override
  String get personNoData => 'Point de personnalité à afficher.';

  @override
  String get personGenericError =>
      'Un couac est advenu en chargeant cette personnalité.';

  @override
  String get personBiographyTitle => 'Biographie';

  @override
  String get authOtpTitle => 'Connexion';

  @override
  String get authOtpSubtitle =>
      'Entrez votre courriel et le code à 8 chiffres qu’on vous envoie.';

  @override
  String get authOtpEmailLabel => 'Courriel';

  @override
  String get authOtpEmailHint => 'vous@courriel';

  @override
  String get authOtpEmailHelp =>
      'On vous enverra un code à 8 chiffres. Vérifiez vos indésirables au besoin.';

  @override
  String get authOtpCodeLabel => 'Code de vérification';

  @override
  String get authOtpCodeHint => 'Code à 8 chiffres';

  @override
  String get authOtpCodeHelp =>
      'Recopiez le code à 8 chiffres reçu par courriel.';

  @override
  String get authOtpPrimarySend => 'Envoyer le code';

  @override
  String get authOtpPrimarySubmit => 'Se connecter';

  @override
  String get authOtpResend => 'Renvoyer le code';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Renvoyer le code dans ${seconds}s';
  }

  @override
  String get authOtpChangeEmail => 'Changer de courriel';

  @override
  String get resumePlayback => 'Reprendre la lècture';

  @override
  String get settingsCloudSyncSection => 'Synchronisation Cloud';

  @override
  String get settingsCloudSyncAuto => 'Synchronisation auto';

  @override
  String get settingsCloudSyncNow => 'Synchroniser maintenant';

  @override
  String get settingsCloudSyncInProgress => 'Synchronisation…';

  @override
  String get settingsCloudSyncNever => 'Jamais';

  @override
  String settingsCloudSyncError(Object error) {
    return 'Dernière erreur : $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return '$entity introuvable';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return '$entity introuvable : $error';
  }

  @override
  String get entityProvider => 'Provider';

  @override
  String get entityGenre => 'Genre';

  @override
  String get entityPlaylist => 'Playlist';

  @override
  String get entitySource => 'Source';

  @override
  String get entityMovie => 'Film';

  @override
  String get entitySeries => 'Série';

  @override
  String get entityPerson => 'Personne';

  @override
  String get entitySaga => 'Saga';

  @override
  String get entityVideo => 'Vidéo';

  @override
  String get entityRoute => 'Route';

  @override
  String get errorTimeoutLoading => 'Timeout lors du chargement';
}
