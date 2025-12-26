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
  String get statusActive => 'Actief';

  @override
  String get statusNoActiveSource => 'Geen actieve bron';

  @override
  String get overlayPreparingHome => 'Startpagina voorbereiden…';

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
  String libraryItemCount(int count) {
    return '$count item';
  }

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
  String errorLoadingPlaylists(String message) {
    return 'Fout bij het laden van playlists: $message';
  }

  @override
  String errorPlaybackFailed(String message) {
    return 'Fout bij het afspelen van de film: $message';
  }

  @override
  String get movieNoMedia => 'No media to display';

  @override
  String get personNoData => 'Geen persoon om te tonen.';

  @override
  String get personGenericError =>
      'Er is een fout opgetreden bij het laden van deze persoon.';

  @override
  String get personBiographyTitle => 'Biografie';

  @override
  String get authOtpTitle => 'Sign in';

  @override
  String get authOtpSubtitle =>
      'Enter your email and the 8-digit code we send you.';

  @override
  String get authOtpEmailLabel => 'Email';

  @override
  String get authOtpEmailHint => 'your@email';

  @override
  String get authOtpEmailHelp =>
      'We will send you an 8-digit code. Check spam if needed.';

  @override
  String get authOtpCodeLabel => 'Verification code';

  @override
  String get authOtpCodeHint => '8-digit code';

  @override
  String get authOtpCodeHelp => 'Enter the 8-digit code received by email.';

  @override
  String get authOtpPrimarySend => 'Send code';

  @override
  String get authOtpPrimarySubmit => 'Sign in';

  @override
  String get authOtpResend => 'Resend code';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get authOtpChangeEmail => 'Change email';

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
}
