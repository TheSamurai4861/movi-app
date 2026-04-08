// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get welcomeTitle => 'Welkom!';

  @override
  String get welcomeSubtitle =>
      'Vul je voorkeuren in om Movi te personaliseren.';

  @override
  String get labelUsername => 'Bijnaam';

  @override
  String get labelPreferredLanguage => 'Voorkeurstaal';

  @override
  String get actionContinue => 'Doorgaan';

  @override
  String get hintUsername => 'Je bijnaam';

  @override
  String get errorFillFields => 'Vul de velden correct in.';

  @override
  String get homeWatchNow => 'Nu kijken';

  @override
  String get welcomeSourceTitle => 'Welkom!';

  @override
  String get welcomeSourceSubtitle =>
      'Voeg een bron toe om je Movi-ervaring te personaliseren.';

  @override
  String get welcomeSourceAdd => 'Bron toevoegen';

  @override
  String get searchTitle => 'Zoeken';

  @override
  String get searchHint => 'Typ je zoekopdracht';

  @override
  String get clear => 'Wissen';

  @override
  String get moviesTitle => 'Films';

  @override
  String get seriesTitle => 'Series';

  @override
  String get noResults => 'Geen resultaten';

  @override
  String get historyTitle => 'Geschiedenis';

  @override
  String get historyEmpty => 'Geen recente zoekopdrachten';

  @override
  String get delete => 'Verwijderen';

  @override
  String resultsCount(int count) {
    return '($count resultaten)';
  }

  @override
  String get errorUnknown => 'Onbekende fout';

  @override
  String errorConnectionFailed(String error) {
    return 'Verbinding mislukt: $error';
  }

  @override
  String get errorConnectionGeneric => 'Verbinding mislukt';

  @override
  String get validationRequired => 'Vereist';

  @override
  String get validationInvalidUrl => 'Ongeldige URL';

  @override
  String get snackbarSourceAddedBackground =>
      'IPTV-bron toegevoegd. Synchronisatie op de achtergrond…';

  @override
  String get snackbarSourceAddedSynced =>
      'IPTV-bron toegevoegd en gesynchroniseerd';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Zoeken';

  @override
  String get navLibrary => 'Bibliotheek';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsLanguageLabel => 'App-taal';

  @override
  String get settingsGeneralTitle => 'Algemene voorkeuren';

  @override
  String get settingsDarkModeTitle => 'Donkere modus';

  @override
  String get settingsDarkModeSubtitle =>
      'Schakel een nachtvriendelijk thema in.';

  @override
  String get settingsNotificationsTitle => 'Meldingen';

  @override
  String get settingsNotificationsSubtitle =>
      'Ontvang bericht over nieuwe releases.';

  @override
  String get settingsAccountTitle => 'Account';

  @override
  String get settingsProfileInfoTitle => 'Profielinformatie';

  @override
  String get settingsProfileInfoSubtitle => 'Naam, avatar, voorkeuren';

  @override
  String get settingsAboutTitle => 'Over';

  @override
  String get settingsLegalMentionsTitle => 'Juridische vermeldingen';

  @override
  String get settingsPrivacyPolicyTitle => 'Privacybeleid';

  @override
  String get actionCancel => 'Annuleren';

  @override
  String get actionConfirm => 'Bevestigen';

  @override
  String get actionRetry => 'Opnieuw proberen';

  @override
  String get settingsHelpDiagnosticsSection => 'Hulp en diagnostiek';

  @override
  String get settingsExportErrorLogs => 'Foutlogboeken exporteren';

  @override
  String get diagnosticsExportTitle => 'Foutlogboeken exporteren';

  @override
  String get diagnosticsExportDescription =>
      'De diagnose bevat alleen recente WARN/ERROR-logs en gehashte account-/profiel-id’s (indien ingeschakeld). Er mogen geen sleutels/tokens verschijnen.';

  @override
  String get diagnosticsIncludeHashedIdsTitle =>
      'Account-/profiel-id’s opnemen (gehasht)';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle =>
      'Helpt een bug te correleren zonder de ruwe ID bloot te geven.';

  @override
  String get diagnosticsCopiedClipboard =>
      'Diagnose gekopieerd naar het klembord.';

  @override
  String diagnosticsSavedFile(String fileName) {
    return 'Diagnose opgeslagen: $fileName';
  }

  @override
  String get diagnosticsActionCopy => 'Kopiëren';

  @override
  String get diagnosticsActionSave => 'Opslaan';

  @override
  String get actionChangeVersion => 'Versie wijzigen';

  @override
  String get semanticsBack => 'Terug';

  @override
  String get semanticsMoreActions => 'Meer acties';

  @override
  String get snackbarLoadingPlaylists => 'Playlists laden…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne =>
      'Geen playlist beschikbaar. Maak er één.';

  @override
  String errorAddToPlaylist(String error) {
    return 'Fout bij toevoegen aan playlist: $error';
  }

  @override
  String get errorAlreadyInPlaylist => 'Deze media staat al in deze playlist';

  @override
  String errorLoadingPlaylists(String message) {
    return 'Fout bij het laden van playlists: $message';
  }

  @override
  String get errorReportUnavailableForContent =>
      'Melden is niet beschikbaar voor deze inhoud.';

  @override
  String get snackbarLoadingEpisodes => 'Afleveringen laden…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist =>
      'Aflevering niet beschikbaar in playlist';

  @override
  String snackbarGenericError(String error) {
    return 'Fout: $error';
  }

  @override
  String get snackbarLoading => 'Laden…';

  @override
  String get snackbarNoVersionAvailable => 'Geen versie beschikbaar';

  @override
  String get snackbarVersionSaved => 'Versie opgeslagen';

  @override
  String playbackVariantFallbackLabel(int index) {
    return 'Versie $index';
  }

  @override
  String get actionReadMore => 'Meer lezen';

  @override
  String get actionShowLess => 'Minder tonen';

  @override
  String get actionViewPage => 'Pagina bekijken';

  @override
  String get semanticsSeeSagaPage => 'Sagapagina bekijken';

  @override
  String get libraryTypeSaga => 'Saga';

  @override
  String get libraryTypeInProgress => 'Bezig';

  @override
  String get libraryTypeFavoriteMovies => 'Favoriete films';

  @override
  String get libraryTypeFavoriteSeries => 'Favoriete series';

  @override
  String get libraryTypeHistory => 'Geschiedenis';

  @override
  String get libraryTypePlaylist => 'Playlist';

  @override
  String get libraryTypeArtist => 'Artiest';

  @override
  String libraryItemCount(int count) {
    return '$count item';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return 'Playlist hernoemd naar \"$name\"';
  }

  @override
  String get snackbarPlaylistDeleted => 'Playlist verwijderd';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return 'Weet je zeker dat je \"$title\" wilt verwijderen?';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return 'Geen resultaten voor \"$query\"';
  }

  @override
  String errorGenericWithMessage(String error) {
    return 'Fout: $error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist =>
      'Deze media staat al in de playlist';

  @override
  String get snackbarAddedToPlaylist => 'Toegevoegd aan de playlist';

  @override
  String get addMediaTitle => 'Media toevoegen';

  @override
  String get searchMinCharsHint => 'Typ minstens 3 tekens om te zoeken';

  @override
  String get badgeAdded => 'Toegevoegd';

  @override
  String get snackbarNotAvailableOnSource => 'Niet beschikbaar op deze bron';

  @override
  String get errorLoadingTitle => 'Laadfout';

  @override
  String errorLoadingWithMessage(String error) {
    return 'Fout: $error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return 'Fout bij laden: $error';
  }

  @override
  String get libraryClearFilterSemanticLabel => 'Filter verwijderen';

  @override
  String get homeErrorSwipeToRetry =>
      'Er is een fout opgetreden. Veeg omlaag om opnieuw te proberen.';

  @override
  String get homeContinueWatching => 'Verder kijken';

  @override
  String get homeNoIptvSources =>
      'Geen IPTV-bron actief. Voeg een bron toe in Instellingen om je categorieën te zien.';

  @override
  String get homeNoTrends => 'Geen trending inhoud beschikbaar';

  @override
  String get actionRefreshMetadata => 'Metadata vernieuwen';

  @override
  String get actionChangeMetadata => 'Metadata wijzigen';

  @override
  String get actionAddToList => 'Toevoegen aan een lijst';

  @override
  String get metadataRefreshed => 'Metadata vernieuwd';

  @override
  String get errorRefreshingMetadata => 'Fout bij vernieuwen van metadata';

  @override
  String get actionMarkSeen => 'Markeren als gezien';

  @override
  String get actionMarkUnseen => 'Markeren als niet gezien';

  @override
  String get actionReportProblem => 'Een probleem melden';

  @override
  String get featureComingSoon => 'Functie binnenkort beschikbaar';

  @override
  String get subtitlesMenuTitle => 'Ondertitels';

  @override
  String get audioMenuTitle => 'Audio';

  @override
  String get videoFitModeMenuTitle => 'Weergavemodus';

  @override
  String get videoFitModeContain => 'Originele verhoudingen';

  @override
  String get videoFitModeCover => 'Scherm vullen';

  @override
  String get actionDisable => 'Uitschakelen';

  @override
  String defaultTrackLabel(String id) {
    return 'Track $id';
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
  String get actionNextEpisode => 'Volgende aflevering';

  @override
  String get actionRestart => 'Opnieuw starten';

  @override
  String get errorSeriesDataUnavailable => 'Kan seriedata niet laden';

  @override
  String get errorNextEpisodeFailed => 'Kan volgende aflevering niet bepalen';

  @override
  String get actionLoadMore => 'Meer laden';

  @override
  String get iptvServerUrlLabel => 'Server-URL';

  @override
  String get iptvServerUrlHint => 'Xtream server-URL';

  @override
  String get iptvPasswordLabel => 'Wachtwoord';

  @override
  String get iptvPasswordHint => 'Xtream wachtwoord';

  @override
  String get actionConnect => 'Verbinden';

  @override
  String get settingsRefreshIptvPlaylistsTitle =>
      'IPTV-afspeellijsten vernieuwen';

  @override
  String get activeSourceTitle => 'Actieve bron';

  @override
  String get statusActive => 'Actief';

  @override
  String get statusNoActiveSource => 'Geen actieve bron';

  @override
  String get overlayPreparingHome => 'Startpagina voorbereiden…';

  @override
  String get overlayLoadingMoviesAndSeries => 'Films en series laden…';

  @override
  String get overlayLoadingCategories => 'Categorieën laden…';

  @override
  String get bootstrapRefreshing => 'IPTV-lijsten vernieuwen…';

  @override
  String get bootstrapEnriching => 'Metagegevens voorbereiden…';

  @override
  String get errorPrepareHome => 'Kan de startpagina niet voorbereiden';

  @override
  String get overlayOpeningHome => 'Startpagina openen…';

  @override
  String get overlayRefreshingIptvLists => 'IPTV-lijsten vernieuwen…';

  @override
  String get overlayPreparingMetadata => 'Metadata voorbereiden…';

  @override
  String get errorHomeLoadTimeout => 'Time-out bij laden startpagina';

  @override
  String get faqLabel => 'Veelgestelde vragen';

  @override
  String get iptvUsernameLabel => 'Gebruikersnaam';

  @override
  String get iptvUsernameHint => 'Xtream gebruikersnaam';

  @override
  String get actionBack => 'Terug';

  @override
  String get actionSeeAll => 'Alles bekijken';

  @override
  String get actionExpand => 'Uitklappen';

  @override
  String get actionCollapse => 'Inklappen';

  @override
  String providerSearchPlaceholder(String provider) {
    return 'Zoeken op $provider...';
  }

  @override
  String get actionClearHistory => 'Geschiedenis wissen';

  @override
  String get castTitle => 'Cast';

  @override
  String get recommendationsTitle => 'Aanbevelingen';

  @override
  String get libraryHeader => 'Jouw videotheek';

  @override
  String get libraryDataInfo =>
      'Gegevens worden getoond zodra data/domain is geïmplementeerd.';

  @override
  String get libraryEmpty =>
      'Like films, series of acteurs om ze hier te zien verschijnen.';

  @override
  String get serie => 'Serie';

  @override
  String get recherche => 'Zoeken';

  @override
  String get notYetAvailable => 'Nog niet beschikbaar';

  @override
  String get createPlaylistTitle => 'Afspeellijst maken';

  @override
  String get playlistName => 'Naam afspeellijst';

  @override
  String get addMedia => 'Media toevoegen';

  @override
  String get renamePlaylist => 'Hernoemen';

  @override
  String get deletePlaylist => 'Verwijderen';

  @override
  String get pinPlaylist => 'Vastmaken';

  @override
  String get unpinPlaylist => 'Losmaken';

  @override
  String get playlistPinned => 'Afspeellijst vastgemaakt';

  @override
  String get playlistUnpinned => 'Afspeellijst losgemaakt';

  @override
  String get playlistDeleted => 'Afspeellijst verwijderd';

  @override
  String playlistCreatedSuccess(String name) {
    return 'Afspeellijst \"$name\" gemaakt';
  }

  @override
  String playlistCreateError(String error) {
    return 'Fout bij het maken van de afspeellijst: $error';
  }

  @override
  String get addedToPlaylist => 'Toegevoegd';

  @override
  String get pinRecoveryLink => 'Récupérer le code PIN';

  @override
  String get pinRecoveryTitle => 'PIN-code herstellen';

  @override
  String get pinRecoveryDescription =>
      'Herstel de PIN-code van je beveiligde profiel.';

  @override
  String get pinRecoveryRequestCodeButton => 'Send code';

  @override
  String get pinRecoveryCodeSentHint =>
      'Code sent. Check your messages and enter it below.';

  @override
  String get pinRecoveryComingSoon => 'Deze functie komt binnenkort.';

  @override
  String get pinRecoveryCodeLabel => 'Herstelcode';

  @override
  String get pinRecoveryCodeHint => '8 cijfers';

  @override
  String get pinRecoveryVerifyButton => 'Controleren';

  @override
  String get pinRecoveryCodeInvalid => 'Voer de 8-cijferige code in';

  @override
  String get pinRecoveryCodeExpired => 'De herstelcode is verlopen';

  @override
  String get pinRecoveryTooManyAttempts =>
      'Te veel pogingen. Probeer het later opnieuw.';

  @override
  String get pinRecoveryUnknownError => 'Er is een onverwachte fout opgetreden';

  @override
  String get pinRecoveryNewPinLabel => 'Nieuwe pincode';

  @override
  String get pinRecoveryNewPinHint => '4-6 cijfers';

  @override
  String get pinRecoveryConfirmPinLabel => 'Bevestig pincode';

  @override
  String get pinRecoveryConfirmPinHint => 'Herhaal de pincode';

  @override
  String get pinRecoveryResetButton => 'Pincode bijwerken';

  @override
  String get pinRecoveryPinInvalid => 'Voer een pincode van 4 tot 6 cijfers in';

  @override
  String get pinRecoveryPinMismatch => 'De pincodes komen niet overeen';

  @override
  String get pinRecoveryResetSuccess => 'Pincode bijgewerkt';

  @override
  String get settingsAccountsSection => 'Accounts';

  @override
  String get settingsIptvSection => 'IPTV-instellingen';

  @override
  String get settingsSourcesManagement => 'Bronbeheer';

  @override
  String get settingsSyncFrequency => 'Updatefrequentie';

  @override
  String get settingsAppSection => 'App-instellingen';

  @override
  String get settingsAccentColor => 'Accentkleur';

  @override
  String get settingsPlaybackSection => 'Afspeelinstellingen';

  @override
  String get settingsPreferredAudioLanguage => 'Voorkeurstaal';

  @override
  String get settingsPreferredSubtitleLanguage => 'Voorkeur ondertitels';

  @override
  String get libraryPlaylistsFilter => 'Afspeellijsten';

  @override
  String get librarySagasFilter => 'Saga\'s';

  @override
  String get libraryArtistsFilter => 'Artiesten';

  @override
  String get librarySearchPlaceholder => 'Zoeken in mijn bibliotheek...';

  @override
  String get libraryInProgress => 'Bezig';

  @override
  String get libraryFavoriteMovies => 'Favoriete films';

  @override
  String get libraryFavoriteSeries => 'Favoriete series';

  @override
  String get libraryWatchHistory => 'Kijkgeschiedenis';

  @override
  String libraryItemCountPlural(int count) {
    return '$count items';
  }

  @override
  String get searchPeopleTitle => 'Personen';

  @override
  String get searchSagasTitle => 'Saga\'s';

  @override
  String get searchByProvidersTitle => 'Per provider';

  @override
  String get searchByGenresTitle => 'Per genre';

  @override
  String get personRoleActor => 'Acteur';

  @override
  String get personRoleDirector => 'Regisseur';

  @override
  String get personRoleCreator => 'Maker';

  @override
  String get tvDistribution => 'Cast';

  @override
  String tvSeasonLabel(int number) {
    return 'Seizoen $number';
  }

  @override
  String get tvNoEpisodesAvailable => 'Geen afleveringen beschikbaar';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return 'Hervatten S$season E$episode';
  }

  @override
  String get sagaViewPage => 'Pagina bekijken';

  @override
  String get sagaStartNow => 'Nu beginnen';

  @override
  String get sagaContinue => 'Doorgaan';

  @override
  String sagaMovieCount(int count) {
    return '$count films';
  }

  @override
  String get sagaMoviesList => 'Filmlijst';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies films - $shows series';
  }

  @override
  String get personPlayRandomly => 'Willekeurig afspelen';

  @override
  String get personMoviesList => 'Filmlijst';

  @override
  String get personSeriesList => 'Serielijst';

  @override
  String get playlistPlayRandomly => 'Willekeurig afspelen';

  @override
  String get playlistAddButton => 'Toevoegen';

  @override
  String get playlistSortButton => 'Sorteren';

  @override
  String get playlistSortByTitle => 'Sorteren op';

  @override
  String get playlistSortByTitleOption => 'Titel';

  @override
  String get playlistSortRecentAdditions => 'Recent toegevoegd';

  @override
  String get playlistSortOldestFirst => 'Oudste eerst';

  @override
  String get playlistSortNewestFirst => 'Nieuwste eerst';

  @override
  String get playlistEmptyMessage => 'Geen items in deze lijst';

  @override
  String playlistItemCount(int count) {
    return '$count item';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count items';
  }

  @override
  String get playlistSeasonSingular => 'seizoen';

  @override
  String get playlistSeasonPlural => 'seizoenen';

  @override
  String get playlistRenameTitle => 'Lijst hernoemen';

  @override
  String get playlistNamePlaceholder => 'Lijstnaam';

  @override
  String playlistRenamedSuccess(String name) {
    return 'Lijst hernoemd naar \"$name\"';
  }

  @override
  String get playlistDeleteTitle => 'Verwijderen';

  @override
  String playlistDeleteConfirm(String title) {
    return 'Weet je zeker dat je \"$title\" wilt verwijderen?';
  }

  @override
  String get playlistDeletedSuccess => 'Lijst verwijderd';

  @override
  String get playlistItemRemovedSuccess => 'Item verwijderd';

  @override
  String playlistRemoveItemConfirm(String title) {
    return '\"$title\" uit de lijst verwijderen?';
  }

  @override
  String get categoryLoadFailed => 'Fout bij het laden van de categorie.';

  @override
  String get categoryEmpty => 'Geen items in deze categorie.';

  @override
  String get categoryLoadingMore => 'Meer laden…';

  @override
  String get movieNoPlaylistsAvailable => 'Geen playlist beschikbaar';

  @override
  String playlistAddedTo(String title) {
    return 'Toegevoegd aan \"$title\"';
  }

  @override
  String errorWithMessage(String message) {
    return 'Fout: $message';
  }

  @override
  String get movieNotAvailableInPlaylist =>
      'Film niet beschikbaar in de playlist';

  @override
  String errorPlaybackFailed(String message) {
    return 'Fout bij het afspelen van de film: $message';
  }

  @override
  String get movieNoMedia => 'Geen media om te tonen';

  @override
  String get personNoData => 'Geen persoon om te tonen.';

  @override
  String get personGenericError =>
      'Er is een fout opgetreden bij het laden van deze persoon.';

  @override
  String get personBiographyTitle => 'Biografie';

  @override
  String get authOtpTitle => 'Inloggen';

  @override
  String get authOtpSubtitle =>
      'Voer je e-mailadres en de 8-cijferige code in die we je sturen.';

  @override
  String get authOtpEmailLabel => 'E-mail';

  @override
  String get authOtpEmailHint => 'jij@email';

  @override
  String get authOtpEmailHelp =>
      'We sturen je een 8-cijferige code. Controleer spam indien nodig.';

  @override
  String get authOtpCodeLabel => 'Verificatiecode';

  @override
  String get authOtpCodeHint => '8-cijferige code';

  @override
  String get authOtpCodeHelp =>
      'Voer de 8-cijferige code in die je per e-mail hebt ontvangen.';

  @override
  String get authOtpPrimarySend => 'Code verzenden';

  @override
  String get authOtpPrimarySubmit => 'Inloggen';

  @override
  String get authOtpResend => 'Code opnieuw verzenden';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Code opnieuw verzenden in ${seconds}s';
  }

  @override
  String get authOtpChangeEmail => 'E-mail wijzigen';

  @override
  String get resumePlayback => 'Afspelen hervatten';

  @override
  String get settingsCloudSyncSection => 'Cloudsync';

  @override
  String get settingsCloudSyncAuto => 'Automatisch synchroniseren';

  @override
  String get settingsCloudSyncNow => 'Nu synchroniseren';

  @override
  String get settingsCloudSyncInProgress => 'Synchroniseren…';

  @override
  String get settingsCloudSyncNever => 'Nooit';

  @override
  String settingsCloudSyncError(Object error) {
    return 'Laatste fout: $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return '$entity niet gevonden';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return '$entity niet gevonden: $error';
  }

  @override
  String get entityProvider => 'Provider';

  @override
  String get entityGenre => 'Genre';

  @override
  String get entityPlaylist => 'Playlist';

  @override
  String get entitySource => 'Bron';

  @override
  String get entityMovie => 'Film';

  @override
  String get entitySeries => 'Serie';

  @override
  String get entityPerson => 'Persoon';

  @override
  String get entitySaga => 'Saga';

  @override
  String get entityVideo => 'Video';

  @override
  String get entityRoute => 'Route';

  @override
  String get errorTimeoutLoading => 'Time-out tijdens laden';

  @override
  String get parentalContentRestricted => 'Beperkte inhoud';

  @override
  String get parentalContentRestrictedDefault =>
      'Deze inhoud is geblokkeerd door de ouderlijke controle van dit profiel.';

  @override
  String get parentalReasonTooYoung =>
      'Deze inhoud vereist een hogere leeftijd dan de limiet van dit profiel.';

  @override
  String get parentalReasonUnknownRating =>
      'De leeftijdsclassificatie voor deze inhoud is niet beschikbaar.';

  @override
  String get parentalReasonInvalidTmdbId =>
      'Deze inhoud kan niet worden beoordeeld voor ouderlijke controle.';

  @override
  String get parentalUnlockButton => 'Deblokkeren';

  @override
  String get hc_arb_dir_4de4827b => 'arb-dir';

  @override
  String get hc_template_arb_file_eeae5194 => 'template-arb-file';

  @override
  String get hc_output_localization_file_ed018380 => 'output-localization-file';

  @override
  String get hc_output_class_f1ae6b52 => 'output-class';

  @override
  String get hc_applocalizations_878fdc50 => 'AppLocalizations';

  @override
  String get hc_untranslated_messages_file_fa6a22b7 =>
      'untranslated-messages-file';

  @override
  String get hc_chargement_episodes_en_cours_33fc4ace => 'Afleveringen laden…';

  @override
  String get hc_aucune_playlist_disponible_creez_en_une_f6b75c90 =>
      'Geen afspeellijst beschikbaar. Maak er een aan.';

  @override
  String get hc_erreur_lors_chargement_playlists_placeholder_97e5c1c3 =>
      'Fout bij het laden van afspeellijsten: \$e';

  @override
  String get hc_impossible_douvrir_lien_90d0dcaa => 'Kan de link niet openen';

  @override
  String get hc_qualite_preferee_776dbeea => 'Voorkeurskwaliteit';

  @override
  String get hc_annuler_49ba3292 => 'Cancel';

  @override
  String get hc_deconnexion_903dca17 => 'Afmelden';

  @override
  String get hc_erreur_lors_deconnexion_placeholder_f5a211b4 =>
      'Fout bij afmelden: \$e';

  @override
  String get hc_choisir_b030d590 => 'Choose';

  @override
  String get hc_avantages_08d7f47c => 'Benefits';

  @override
  String get hc_signalement_envoye_merci_d302e576 =>
      'Melding verzonden. Bedankt.';

  @override
  String get hc_plus_tard_1f42ab3b => 'Later';

  @override
  String get hc_redemarrer_maintenant_053e8e68 => 'Nu opnieuw starten';

  @override
  String get hc_utiliser_cette_source_c6c8bbc5 => 'Deze bron gebruiken?';

  @override
  String get hc_utiliser_fb5e43ce => 'Use';

  @override
  String get hc_source_ajout_e_e41b01d9 => 'Bron toegevoegd';

  @override
  String get hc_title_0a57b7eb => 'title: \'...\'';

  @override
  String get hc_labeltext_469a28db => 'labelText: \'...\'';

  @override
  String get hc_hinttext_6fd1d945 => 'hintText: \'...\'';

  @override
  String get hc_tooltip_db0de3fe => 'tooltip: \'...\'';

  @override
  String get hc_parametres_verrouilles_3a9b1b51 => 'Vergrendelde instellingen';

  @override
  String get hc_compte_cloud_2812b31e => 'Cloudaccount';

  @override
  String get hc_se_connecter_fedf2439 => 'Inloggen';

  @override
  String get hc_propos_5345add5 => 'Over';

  @override
  String get hc_politique_confidentialite_42b0e51e => 'Privacybeleid';

  @override
  String get hc_conditions_dutilisation_9074eac7 => 'Gebruiksvoorwaarden';

  @override
  String get hc_sources_sauvegardees_9f1382e5 => 'Opgeslagen bronnen';

  @override
  String get hc_rafraichir_be30b7d1 => 'Vernieuwen';

  @override
  String get hc_activer_une_source_749ced38 => 'Bron activeren';

  @override
  String get hc_nom_source_9a3e4156 => 'Naam van de bron';

  @override
  String get hc_mon_iptv_b239352c => 'Mijn IPTV';

  @override
  String get hc_username_84c29015 => 'Gebruikersnaam';

  @override
  String get hc_password_8be3c943 => 'Wachtwoord';

  @override
  String get hc_server_url_1d5d1eff => 'Server-URL';

  @override
  String get hc_verification_pin_e17c8fe0 => 'PIN-verificatie';

  @override
  String get hc_definir_un_pin_f9c2178d => 'PIN instellen';

  @override
  String get hc_pin_3adadd31 => 'PIN';

  @override
  String get hc_message_9ff08507 => 'message: \'...\'';

  @override
  String get hc_subscription_offer_not_found_placeholder_d07ac9d3 =>
      'Subscription offer not found: \$offerId.';

  @override
  String get hc_subscription_purchase_was_cancelled_by_user_443e1dab =>
      'The subscription purchase was cancelled by the user.';

  @override
  String get hc_store_operation_timed_out_placeholder_6c3f9df2 =>
      'The store operation timed out: \$operation.';

  @override
  String get hc_erreur_http_lors_handshake_02db57b2 =>
      'HTTP error during handshake';

  @override
  String get hc_reponse_non_json_serveur_xtream_e896b8df =>
      'Non-JSON response from Xtream server';

  @override
  String get hc_reponse_invalide_serveur_xtream_afc0955f =>
      'Invalid response from Xtream server';

  @override
  String get hc_rg_exe_af0d2be6 => 'rg.exe';

  @override
  String get hc_alertdialog_5a747a86 => 'AlertDialog';

  @override
  String get hc_cupertinoalertdialog_3ed27f52 => 'CupertinoAlertDialog';

  @override
  String get hc_pas_disponible_sur_cette_source_fa6e19a7 =>
      'Niet beschikbaar op deze bron';

  @override
  String get hc_source_supprimee_4bfaa0a1 => 'Bron verwijderd';

  @override
  String get hc_source_modifiee_335ef502 => 'Bron bijgewerkt';

  @override
  String get hc_definir_code_pin_53a0bd07 => 'PIN-code instellen';

  @override
  String get hc_marquer_comme_non_vu_9cf9d3f8 => 'Markeren als niet bekeken';

  @override
  String get hc_etes_vous_sur_vouloir_vous_deconnecter_1a096661 =>
      'Weet je zeker dat je wilt afmelden?';

  @override
  String get hc_movi_premium_requis_pour_synchronisation_cloud_15b551df =>
      'Movi Premium is vereist voor cloudsynchronisatie.';

  @override
  String get hc_auto_c614ba7c => 'Auto';

  @override
  String get hc_organiser_838a7e57 => 'Ordenen';

  @override
  String get hc_modifier_f260e757 => 'Bewerken';

  @override
  String get hc_ajouter_87c57ed1 => 'Toevoegen';

  @override
  String get hc_source_active_e571305e => 'Actieve bron';

  @override
  String get hc_autres_sources_e32592a6 => 'Andere bronnen';

  @override
  String get hc_signalement_indisponible_pour_ce_contenu_d9ad88b7 =>
      'Melden is niet beschikbaar voor deze content.';

  @override
  String get hc_securisation_contenu_e5195111 => 'Content beveiligen';

  @override
  String get hc_verification_classifications_d_age_006eebfe =>
      'Leeftijdsclassificaties controleren…';

  @override
  String get hc_voir_tout_7b7d86e8 => 'Alles bekijken';

  @override
  String get hc_signaler_un_probleme_13183c0f => 'Een probleem melden';

  @override
  String get hc_si_ce_contenu_nest_pas_approprie_ete_accessible_320c2436 =>
      'Als deze content niet geschikt is en toch toegankelijk was ondanks beperkingen, beschrijf het probleem kort.';

  @override
  String get hc_envoyer_e9ce243b => 'Verzenden';

  @override
  String get hc_profil_enfant_cree_39f4eb7d => 'Kinderprofiel aangemaakt';

  @override
  String get hc_un_profil_enfant_ete_cree_pour_securiser_l_40e15a0a =>
      'Er is een kinderprofiel aangemaakt. Om de app te beveiligen en leeftijdsclassificaties vooraf te laden, wordt aangeraden de app opnieuw te starten.';

  @override
  String get hc_pseudo_4cf966c0 => 'Bijnaam';

  @override
  String get hc_profil_enfant_2c8a01c0 => 'Kinderprofiel';

  @override
  String get hc_limite_d_age_5b170fc9 => 'Leeftijdslimiet';

  @override
  String get hc_code_pin_e79c48bd => 'PIN-code';

  @override
  String get hc_changer_code_pin_3b069731 => 'PIN-code wijzigen';

  @override
  String get hc_supprimer_code_pin_0dcf8a48 => 'PIN-code verwijderen';

  @override
  String get hc_supprimer_pin_51850c7b => 'PIN verwijderen';

  @override
  String get hc_supprimer_1acfc1c7 => 'Verwijderen';

  @override
  String get hc_oblige_un_pin_active_filtre_pegi_8447ac9b =>
      'Vereist een PIN en schakelt het PEGI-filter in.';

  @override
  String get hc_voulez_vous_activer_cette_source_maintenant_f2593894 =>
      'Wil je deze bron nu activeren?';

  @override
  String get hc_application_b291beb8 => 'App';

  @override
  String get hc_version_1_0_0_347e553c => 'Version 1.0.0';

  @override
  String get hc_credits_293a6081 => 'Credits';

  @override
  String get hc_this_product_uses_tmdb_api_but_is_not_0033d77f =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  String get hc_ce_produit_utilise_l_api_tmdb_mais_n_0b55273a =>
      'Dit product gebruikt de TMDB API, maar is niet onderschreven of gecertificeerd door TMDB.';

  @override
  String get hc_verification_targets_d51632f8 => 'Verification targets';

  @override
  String get hc_fade_must_eat_frame_5f1bfc77 => 'The fade must eat the frame';

  @override
  String get hc_invalid_xtream_streamid_eb04e9f9 =>
      'Invalid Xtream streamId: ...';

  @override
  String get hc_series_xtream_missing_poster_065b5103 =>
      'Series xtream:... missing poster';

  @override
  String get hc_movie_not_found_a7fe72d9 => 'Movie ... not found ...';

  @override
  String get hc_missing_poster_1c9ba558 => '... missing poster';

  @override
  String get hc_invalid_watchlist_outbox_payload_327ac6c3 =>
      'Invalid watchlist outbox payload.';

  @override
  String get hc_unknown_watchlist_operation_e9259c07 =>
      'Unknown watchlist operation: ...';

  @override
  String get hc_invalid_playlist_outbox_payload_2d76e64f =>
      'Invalid playlist outbox payload.';

  @override
  String get hc_unknown_playlist_operation_c98cbd41 =>
      'Unknown playlist operation: ...';

  @override
  String get hc_url_invalide_aa227a66 => 'Ongeldige URL';

  @override
  String get hc_legacy_iv_missing_cannot_decrypt_legacy_ciphertext_7c7b39c3 =>
      'Missing legacy IV: cannot decrypt legacy ciphertext.';

  @override
  String get hc_tooltip_rafraichir_a22b17e3 => 'tooltip: \'Vernieuwen\'';

  @override
  String get hc_tooltip_menu_d8fa6679 => 'tooltip: \'Menu\'';

  @override
  String get hc_retour_e5befb1f => 'Terug';

  @override
  String get hc_semanticlabel_plus_d_actions_1bd19eb6 =>
      'semanticLabel: \'Meer acties\'';

  @override
  String get hc_plus_d_actions_ffe6be2a => 'Meer acties';

  @override
  String get hc_semanticlabel_rechercher_3ae4e02c =>
      'semanticLabel: \'Zoeken\'';

  @override
  String get hc_semanticlabel_ajouter_ac362a68 =>
      'semanticLabel: \'Toevoegen\'';

  @override
  String get hc_l10n_86d50bf0 => 'l10n.*';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSignOut => 'Afmelden';

  @override
  String get dialogSignOutBody => 'Weet je zeker dat je je wilt afmelden?';

  @override
  String get settingsUnableToOpenLink => 'Kan de link niet openen';

  @override
  String get settingsSyncDisabled => 'Uitgeschakeld';

  @override
  String get settingsSyncEveryHour => 'Elk uur';

  @override
  String get settingsSyncEvery2Hours => 'Elke 2 uur';

  @override
  String get settingsSyncEvery4Hours => 'Elke 4 uur';

  @override
  String get settingsSyncEvery6Hours => 'Elke 6 uur';

  @override
  String get settingsSyncEveryDay => 'Elke dag';

  @override
  String get settingsSyncEvery2Days => 'Elke 2 dagen';

  @override
  String get settingsColorCustom => 'Aangepast';

  @override
  String get settingsColorBlue => 'Blauw';

  @override
  String get settingsColorPink => 'Roze';

  @override
  String get settingsColorGreen => 'Groen';

  @override
  String get settingsColorPurple => 'Paars';

  @override
  String get settingsColorOrange => 'Oranje';

  @override
  String get settingsColorTurquoise => 'Turkoois';

  @override
  String get settingsColorYellow => 'Geel';

  @override
  String get settingsColorIndigo => 'Indigo';

  @override
  String get settingsCloudAccountTitle => 'Cloudaccount';

  @override
  String get settingsAccountConnected => 'Verbonden';

  @override
  String get settingsAccountLocalMode => 'Lokale modus';

  @override
  String get settingsAccountCloudUnavailable => 'Cloud niet beschikbaar';

  @override
  String get settingsSubtitlesTitle => 'Ondertitels';

  @override
  String get settingsSubtitlesSizeTitle => 'Tekstgrootte';

  @override
  String get settingsSubtitlesColorTitle => 'Tekstkleur';

  @override
  String get settingsSubtitlesFontTitle => 'Lettertype';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => 'Systeem';

  @override
  String get settingsSubtitlesQuickSettingsTitle => 'Snelle instellingen';

  @override
  String get settingsSubtitlesPreviewTitle => 'Voorbeeld';

  @override
  String get settingsSubtitlesPreviewSample =>
      'Dit is een ondertitelvoorbeeld.\nPas de leesbaarheid in realtime aan.';

  @override
  String get settingsSubtitlesBackgroundTitle => 'Achtergrond';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => 'Achtergronddekking';

  @override
  String get settingsSubtitlesShadowTitle => 'Schaduw';

  @override
  String get settingsSubtitlesShadowOff => 'Uit';

  @override
  String get settingsSubtitlesShadowSoft => 'Zacht';

  @override
  String get settingsSubtitlesShadowStrong => 'Sterk';

  @override
  String get settingsSubtitlesFineSizeTitle => 'Fijne grootte';

  @override
  String get settingsSubtitlesFineSizeValueLabel => 'Schaal';

  @override
  String get settingsSubtitlesResetDefaults => 'Standaard herstellen';

  @override
  String get settingsSubtitlesPremiumLockedTitle =>
      'Geavanceerde ondertitelstijl (Premium)';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      'Achtergrond, dekking, schaduwpresets en fijne grootte zijn beschikbaar met Movi Premium.';

  @override
  String get settingsSubtitlesPremiumLockedAction => 'Ontgrendel met Premium';

  @override
  String get settingsSyncSectionTitle => 'Audio/ondertitels synchronisatie';

  @override
  String get settingsSubtitleOffsetTitle => 'Ondertitelvertraging';

  @override
  String get settingsAudioOffsetTitle => 'Audiovertraging';

  @override
  String get settingsOffsetUnsupported =>
      'Niet ondersteund op deze backend of dit platform.';

  @override
  String get settingsSyncResetOffsets => 'Synchronisatie-offsets resetten';

  @override
  String get aboutTmdbDisclaimer =>
      'Dit product gebruikt de TMDB-API, maar wordt niet onderschreven of gecertificeerd door TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Credits';
}
