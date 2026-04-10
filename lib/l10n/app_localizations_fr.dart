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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
      zero: 'Aucun résultat',
    );
    return '$_temp0';
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
  String get settingsHelpDiagnosticsSection => 'Aide & diagnostic';

  @override
  String get settingsExportErrorLogs => 'Exporter les logs d’erreurs';

  @override
  String get diagnosticsExportTitle => 'Exporter les logs d’erreurs';

  @override
  String get diagnosticsExportDescription =>
      'Le diagnostic inclut uniquement des logs WARN/ERROR récents et des identifiants compte/profil hachés (si activé). Aucune clé/token ne doit apparaître.';

  @override
  String get diagnosticsIncludeHashedIdsTitle =>
      'Inclure identifiants compte/profil (hachés)';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle =>
      'Permet de recouper un bug sans exposer l’ID brut.';

  @override
  String get diagnosticsCopiedClipboard =>
      'Diagnostic copié dans le presse-papiers.';

  @override
  String diagnosticsSavedFile(String fileName) {
    return 'Diagnostic enregistré : $fileName';
  }

  @override
  String get diagnosticsActionCopy => 'Copier';

  @override
  String get diagnosticsActionSave => 'Enregistrer';

  @override
  String get actionChangeVersion => 'Changer de version';

  @override
  String get semanticsBack => 'Retour';

  @override
  String get semanticsMoreActions => 'Plus d’actions';

  @override
  String get snackbarLoadingPlaylists => 'Chargement des playlists…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne =>
      'Aucune playlist disponible. Créez-en une.';

  @override
  String errorAddToPlaylist(String error) {
    return 'Erreur lors de l’ajout à la playlist : $error';
  }

  @override
  String get errorAlreadyInPlaylist => 'Ce média est déjà dans cette playlist';

  @override
  String errorLoadingPlaylists(String message) {
    return 'Erreur lors du chargement des playlists: $message';
  }

  @override
  String get errorReportUnavailableForContent =>
      'Signalement indisponible pour ce contenu.';

  @override
  String get snackbarLoadingEpisodes => 'Chargement des épisodes en cours…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist =>
      'Épisode non disponible dans la playlist';

  @override
  String snackbarGenericError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get snackbarLoading => 'Chargement…';

  @override
  String get snackbarNoVersionAvailable => 'Aucune version disponible';

  @override
  String get snackbarVersionSaved => 'Version enregistrée';

  @override
  String playbackVariantFallbackLabel(int index) {
    return 'Version $index';
  }

  @override
  String get actionReadMore => 'Lire plus';

  @override
  String get actionShowLess => 'Réduire';

  @override
  String get actionViewPage => 'Voir la page';

  @override
  String get semanticsSeeSagaPage => 'Voir la page de la saga';

  @override
  String get libraryTypeSaga => 'Saga';

  @override
  String get libraryTypeInProgress => 'En cours';

  @override
  String get libraryTypeFavoriteMovies => 'Films favoris';

  @override
  String get libraryTypeFavoriteSeries => 'Séries favorites';

  @override
  String get libraryTypeHistory => 'Historique';

  @override
  String get libraryTypePlaylist => 'Playlist';

  @override
  String get libraryTypeArtist => 'Artiste';

  @override
  String libraryItemCount(int count) {
    return '$count élément';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return 'Playlist renommée en « $name »';
  }

  @override
  String get snackbarPlaylistDeleted => 'Playlist supprimée';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return 'Êtes-vous sûr de vouloir supprimer « $title » ?';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String errorGenericWithMessage(String error) {
    return 'Erreur : $error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist =>
      'Ce média est déjà dans la playlist';

  @override
  String get snackbarAddedToPlaylist => 'Ajouté à la playlist';

  @override
  String get addMediaTitle => 'Ajouter des médias';

  @override
  String get searchMinCharsHint =>
      'Tapez au moins 3 caractères pour rechercher';

  @override
  String get badgeAdded => 'Ajouté';

  @override
  String get snackbarNotAvailableOnSource => 'Pas disponible sur cette source';

  @override
  String get errorLoadingTitle => 'Erreur de chargement';

  @override
  String errorLoadingWithMessage(String error) {
    return 'Erreur : $error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return 'Erreur lors du chargement : $error';
  }

  @override
  String get libraryClearFilterSemanticLabel => 'Supprimer le filtre';

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
  String get activeSourceTitle => 'Source active';

  @override
  String get statusActive => 'Actif';

  @override
  String get statusNoActiveSource => 'Aucune source active';

  @override
  String get overlayPreparingHome => 'Préparation de l\'accueil…';

  @override
  String get overlayLoadingMoviesAndSeries => 'Chargement des films et séries…';

  @override
  String get overlayLoadingCategories => 'Chargement des catégories…';

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
    return 'Rechercher $provider';
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
  String get pinRecoveryLink => 'Récupérer le PIN';

  @override
  String get pinRecoveryTitle => 'Récupérer le PIN';

  @override
  String get pinRecoveryDescription =>
      'Nous enverrons un code à 8 chiffres à l’adresse e-mail de votre compte pour réinitialiser le PIN de ce profil.';

  @override
  String get pinRecoveryRequestCodeButton => 'Envoyer le code';

  @override
  String get pinRecoveryCodeSentHint =>
      'Code envoyé à l’e-mail de votre compte. Vérifiez vos messages, puis saisissez-le ci-dessous.';

  @override
  String get pinRecoveryComingSoon => 'Cette fonctionnalité arrive bientôt.';

  @override
  String get pinRecoveryNotAvailable =>
      'La récupération du code PIN par e-mail est indisponible pour le moment.';

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
  String get pinRecoveryResetButton => 'Réinitialiser le PIN';

  @override
  String get pinRecoveryPinInvalid => 'Saisissez un PIN de 4 à 6 chiffres';

  @override
  String get pinRecoveryPinMismatch => 'Les PIN ne correspondent pas';

  @override
  String get pinRecoveryResetSuccess => 'PIN mis à jour';

  @override
  String get profilePinSaved => 'PIN enregistré.';

  @override
  String get profilePinEditLabel => 'Modifier le code PIN';

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
  String get settingsPreferredAudioLanguage => 'Langue audio préférée';

  @override
  String get settingsPreferredSubtitleLanguage =>
      'Langue des sous-titres préférée';

  @override
  String get libraryPlaylistsFilter => 'Playlists';

  @override
  String get librarySagasFilter => 'Sagas';

  @override
  String get libraryArtistsFilter => 'Artistes';

  @override
  String get librarySearchPlaceholder => 'Rechercher dans ma bibliothèque...';

  @override
  String get libraryInProgress => 'Continuer à regarder';

  @override
  String get libraryFavoriteMovies => 'Films favoris';

  @override
  String get libraryFavoriteSeries => 'Séries favorites';

  @override
  String get libraryWatchHistory => 'Historique de visionnage';

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
    return 'Reprendre S$season · E$episode';
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
  String get playlistSortRecentAdditions => 'Ajouts récents';

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
  String get authOtpEmailHint => 'nom@exemple.com';

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
    return 'Renvoyer le code dans $seconds s';
  }

  @override
  String get authOtpChangeEmail => 'Changer d’e-mail';

  @override
  String get resumePlayback => 'Reprendre lecture';

  @override
  String get settingsCloudSyncSection => 'Synchronisation cloud';

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

  @override
  String get actionOk => 'OK';

  @override
  String get actionSignOut => 'Déconnexion';

  @override
  String get dialogSignOutBody => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get settingsUnableToOpenLink => 'Impossible d’ouvrir le lien';

  @override
  String get settingsSyncDisabled => 'Désactivé';

  @override
  String get settingsSyncEveryHour => 'Toutes les heures';

  @override
  String get settingsSyncEvery2Hours => 'Toutes les 2 heures';

  @override
  String get settingsSyncEvery4Hours => 'Toutes les 4 heures';

  @override
  String get settingsSyncEvery6Hours => 'Toutes les 6 heures';

  @override
  String get settingsSyncEveryDay => 'Tous les jours';

  @override
  String get settingsSyncEvery2Days => 'Tous les 2 jours';

  @override
  String get settingsColorCustom => 'Personnalisé';

  @override
  String get settingsColorBlue => 'Bleu';

  @override
  String get settingsColorPink => 'Rose';

  @override
  String get settingsColorGreen => 'Vert';

  @override
  String get settingsColorPurple => 'Violet';

  @override
  String get settingsColorOrange => 'Orange';

  @override
  String get settingsColorTurquoise => 'Turquoise';

  @override
  String get settingsColorYellow => 'Jaune';

  @override
  String get settingsColorIndigo => 'Indigo';

  @override
  String get settingsCloudAccountTitle => 'Compte cloud';

  @override
  String get settingsAccountConnected => 'Connecté';

  @override
  String get settingsAccountLocalMode => 'Mode local';

  @override
  String get settingsAccountCloudUnavailable => 'Cloud indisponible';

  @override
  String get settingsSubtitlesTitle => 'Sous-titres';

  @override
  String get settingsSubtitlesSizeTitle => 'Taille du texte';

  @override
  String get settingsSubtitlesColorTitle => 'Couleur du texte';

  @override
  String get settingsSubtitlesFontTitle => 'Police';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => 'Système';

  @override
  String get settingsSubtitlesQuickSettingsTitle => 'Réglages rapides';

  @override
  String get settingsSubtitlesPreviewTitle => 'Aperçu';

  @override
  String get settingsSubtitlesPreviewSample =>
      'Ceci est un aperçu des sous-titres.\nAjustez la lisibilité en temps réel.';

  @override
  String get settingsSubtitlesBackgroundTitle => 'Fond';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => 'Opacité du fond';

  @override
  String get settingsSubtitlesShadowTitle => 'Ombre';

  @override
  String get settingsSubtitlesShadowOff => 'Aucune';

  @override
  String get settingsSubtitlesShadowSoft => 'Douce';

  @override
  String get settingsSubtitlesShadowStrong => 'Forte';

  @override
  String get settingsSubtitlesFineSizeTitle => 'Taille fine';

  @override
  String get settingsSubtitlesFineSizeValueLabel => 'Échelle';

  @override
  String get settingsSubtitlesResetDefaults => 'Réinitialiser par défaut';

  @override
  String get settingsSubtitlesPremiumLockedTitle =>
      'Style sous-titres avancé (Premium)';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      'Le fond, l’opacité, les presets d’ombre et la taille fine sont disponibles avec Movi Premium.';

  @override
  String get settingsSubtitlesPremiumLockedAction => 'Débloquer avec Premium';

  @override
  String get settingsSyncSectionTitle => 'Synchronisation audio/ST';

  @override
  String get settingsSubtitleOffsetTitle => 'Décalage sous-titres';

  @override
  String get settingsAudioOffsetTitle => 'Décalage audio';

  @override
  String get settingsOffsetUnsupported =>
      'Non pris en charge par ce backend ou cette plateforme.';

  @override
  String get settingsSyncResetOffsets => 'Réinitialiser les décalages';

  @override
  String get aboutTmdbDisclaimer =>
      'Ce produit utilise l\'API TMDB mais n\'est ni approuvé ni certifié par TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Crédits';

  @override
  String get actionSend => 'Envoyer';

  @override
  String get profilePinSetLabel => 'Définir un code PIN';

  @override
  String get reportingProblemSentConfirmation => 'Signalement envoyé. Merci.';

  @override
  String get reportingProblemBody =>
      'Si ce contenu n\'est pas approprié et a été accessible malgré les restrictions, décrivez brièvement le problème.';

  @override
  String get reportingProblemExampleHint =>
      'Exemple : film d\'horreur visible malgré PEGI 12';

  @override
  String get settingsAutomaticOption => 'Automatique';

  @override
  String get settingsPreferredPlaybackQuality => 'Qualité de lecture préférée';

  @override
  String settingsSignOutError(String error) {
    return 'Erreur lors de la déconnexion : $error';
  }

  @override
  String get settingsTermsOfUseTitle => 'Conditions d\'utilisation';

  @override
  String get settingsCloudSyncPremiumRequiredMessage =>
      'Movi Premium est requis pour la synchronisation cloud.';
}
