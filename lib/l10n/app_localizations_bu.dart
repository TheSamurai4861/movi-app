// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Burgonde (`bu`).
class AppLocalizationsBu extends AppLocalizations {
  AppLocalizationsBu([String locale = 'bu']) : super(locale);

  @override
  String get welcomeTitle => "Que nenni ! Bienv'nû !";
  @override
  String get welcomeSubtitle =>
      "Remplis tes préférences, c'est point couettos mais utile.";
  @override
  String get labelUsername => 'Sobriquet';
  @override
  String get labelPreferredLanguage => 'Langage de la bourgogne';
  @override
  String get actionContinue => 'Avançons';
  @override
  String get hintUsername => 'Ton sobriquet';
  @override
  String get errorFillFields => 'Faut point oublier d\'emplir les champs.';
  @override
  String get homeWatchNow => 'Regarder toutim';
  @override
  String get welcomeSourceTitle => "Bienv'nû !";
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
  String resultsCount(int count) => '($count trouvailles)';
  @override
  String get errorUnknown => 'Méprise inconnue';
  @override
  String errorConnectionFailed(String error) => 'Connexion faillie : $error';
  @override
  String get errorConnectionGeneric => 'Connexion faillie';
  @override
  String get validationRequired => 'Obligé';
  @override
  String get validationInvalidUrl => 'L\'adresse est point bonne';
  @override
  String get snackbarSourceAddedBackground =>
      'Source IPTV ajoutée. Ça s\'active en coulisse…';
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
  String get settingsLanguageLabel => 'Langage de l\'appli';
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
  String get actionBack => 'Retour';

  @override
  String get actionSeeAll => 'Voir tout';

  @override
  String get actionExpand => 'Élargir';

  @override
  String providerSearchPlaceholder(String provider) =>
      'Rechercher sur $provider...';

  @override
  String get castTitle => 'Troupe';

  @override
  String get libraryDataInfo =>
      'Les données s\'afficheront quand la couche data/domain sera arrimée.';

  @override
  String get libraryEmpty =>
      'Likez des films, séries ou acteurs pour les voir apparaître ici.';

  @override
  String get libraryHeader => 'Ta réserve';

  @override
  String get recommendationsTitle => 'Conseils';
  @override
  String get actionChangeMetadata => 'Changer les bilboquets';
  @override
  String get actionAddToList => 'Mettre en la liste';
  @override
  String get actionMarkSeen => 'Marquer comme vu';
  @override
  String get actionMarkUnseen => 'Marquer comme point vu';
  @override
  String get actionReportProblem => 'Signaler un couac';

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
  String defaultTrackLabel(String id) => 'Piste $id';

  @override
  String get controlRewind10 => '10 s';

  @override
  String get controlRewind30 => '30 s';

  @override
  String get controlForward10 => '+ 10 s';

  @override
  String get controlForward30 => '+ 30 s';

  @override
  String get actionNextEpisode => 'Episode suivant';

  @override
  String get actionRestart => 'Recommencer';

  @override
  String get errorSeriesDataUnavailable =>
      'Impossible de charger les données de la série';

  @override
  String get errorNextEpisodeFailed =>
      'Impossible de déterminer l\'épisode suivant';
  @override
  String get featureComingSoon => 'Fonction à venir';
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
  String get iptvUsernameLabel => 'Nom d\'utilisateur';
  @override
  String get iptvUsernameHint => 'Identifiant Xtream';
  @override
  String get actionRefreshMetadata => 'Rafraîchir les billets';
  @override
  String get metadataRefreshed => 'Billets rafraîchis';
  @override
  String get errorRefreshingMetadata =>
      'Couac lors du rafraîchissement des billets';
  @override
  String get actionCollapse => 'Rétrécir';
  @override
  String get actionClearHistory => 'Pourfendre l\'historique';
  @override
  String get serie => 'Feuilletons';
  @override
  String get recherche => 'Quête';
  @override
  String get notYetAvailable => 'Point encore disponible';
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
  String playlistCreatedSuccess(String name) => 'Liste "$name" créée';
  @override
  String playlistCreateError(String error) =>
      'Couac lors de la création: $error';
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
  String get pinRecoveryTooManyAttempts => 'Trop de tentatives. Réessayez plus tard.';

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
  String libraryItemCount(int count) => '$count élément';
  @override
  String libraryItemCountPlural(int count) => '$count éléments';
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
  String tvSeasonLabel(int number) => 'Saison $number';
  @override
  String get tvNoEpisodesAvailable => 'Point d\'épisode disponible';
  @override
  String tvResumeSeasonEpisode(int season, int episode) =>
      'Reprendre S$season E$episode';
  @override
  String get sagaViewPage => 'Voir la page';
  @override
  String get sagaStartNow => 'Commencer maintenant';
  @override
  String get sagaContinue => 'Poursuivre';
  @override
  String sagaMovieCount(int count) => '$count films';
  @override
  String get sagaMoviesList => 'Liste des films';
  @override
  String personMoviesCount(int movies, int shows) =>
      '$movies films - $shows séries';
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
  String get playlistEmptyMessage => 'Point d\'élément dans cette liste';
  @override
  String playlistItemCount(int count) => '$count élément';
  @override
  String playlistItemCountPlural(int count) => '$count éléments';
  @override
  String get playlistSeasonSingular => 'saison';
  @override
  String get playlistSeasonPlural => 'saisons';
  @override
  String get playlistRenameTitle => 'Renommer la liste';
  @override
  String get playlistNamePlaceholder => 'Nom de la liste';
  @override
  String playlistRenamedSuccess(String name) => 'Liste renommée en "$name"';
  @override
  String get playlistDeleteTitle => 'Supprimer';
  @override
  String playlistDeleteConfirm(String title) =>
      'Êtes-vous sûr de vouloir supprimer "$title" ?';
  @override
  String get playlistDeletedSuccess => 'Liste supprimée';
  @override
  String get playlistItemRemovedSuccess => 'Élément supprimé';
  @override
  String playlistRemoveItemConfirm(String title) =>
      'Supprimer "$title" de la liste ?';
  @override
  String get categoryLoadFailed => 'Couac lors du chargement de la catégorie.';
  @override
  String get categoryEmpty => 'Point d\'élément dans cette catégorie.';
  @override
  String get categoryLoadingMore => 'Chargement en cours…';
  @override
  String get movieNoMedia => 'Point de média à afficher';
  @override
  String get movieNoPlaylistsAvailable => 'Point de liste disponible';
  @override
  String playlistAddedTo(String title) => 'Ajouté à "$title"';
  @override
  String errorWithMessage(String message) => 'Couac: $message';
  @override
  String get movieNotAvailableInPlaylist =>
      'Bobine point disponible dans la liste';
  @override
  String errorLoadingPlaylists(String message) =>
      'Couac lors du chargement des listes: $message';
  @override
  String errorPlaybackFailed(String message) =>
      'Couac lors de la lecture de la bobine: $message';
  @override
  String get personNoData => 'Point de personnalité à afficher.';
  @override
  String get personGenericError =>
      'Un couac est advenu en chargeant cette personnalité.';
  @override
  String get personBiographyTitle => 'Biographie';

  // ────────────── Auth OTP (Supabase) ──────────────
  @override
  String get authOtpTitle => 'Se relier';

  @override
  String get authOtpSubtitle =>
      'Tape ton courriel et le code à 8 chiffres que l’on t\'envoie.';

  @override
  String get authOtpEmailLabel => 'Courriel';

  @override
  String get authOtpEmailHint => 'toi@bourgogne';

  @override
  String get authOtpEmailHelp =>
      'On t\'envoie un code à 8 chiffres. Regarde aussi dans les indésirables.';

  @override
  String get authOtpCodeLabel => 'Code de vérification';

  @override
  String get authOtpCodeHint => 'Code à 8 chiffres';

  @override
  String get authOtpCodeHelp => 'Recopie ici le code reçu par courriel.';

  @override
  String get authOtpPrimarySend => 'Recevoir le code';

  @override
  String get authOtpPrimarySubmit => 'Se connecter';

  @override
  String get authOtpResend => 'Renvoyer le code';

  @override
  String authOtpResendDisabled(int seconds) =>
      'Renvoyer le code dans ${seconds}s';

  @override
  String get authOtpChangeEmail => 'Changer de courriel';
  
  @override
  String get resumePlayback => 'Reprendre la lècture';
  
  @override
  String get settingsCloudSyncAuto => 'Synchronisacion auto';
  
  @override
  String settingsCloudSyncError(Object error) {
    return 'Darnére erreur : $error';
  }
  
  @override
  String get settingsCloudSyncInProgress => 'Synchronisacion…';
  
  @override
  String get settingsCloudSyncNever => 'Jâmais';
  
  @override
  String get settingsCloudSyncNow => 'Synchroniser asteur';
  
  @override
  String get settingsCloudSyncSection => 'Synchronisacion Cloud';

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
  String get entityPlaylist => 'Liste';

  @override
  String get entitySource => 'Source';

  @override
  String get entityMovie => 'Bobine';

  @override
  String get entitySeries => 'Feuilleton';

  @override
  String get entityPerson => 'Personnalité';

  @override
  String get entitySaga => 'Saga';

  @override
  String get entityVideo => 'Vidéo';

  @override
  String get entityRoute => 'Route';

  @override
  String get errorTimeoutLoading => 'Délai de chargement dépassé';

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
