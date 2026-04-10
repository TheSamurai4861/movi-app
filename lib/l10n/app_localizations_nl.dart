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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '($count resultaten)',
      one: '(1 resultaat)',
      zero: '(geen resultaten)',
    );
    return '$_temp0';
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
      'Nog geen afspeellijsten. Maak er één aan.';

  @override
  String errorAddToPlaylist(String error) {
    return 'Fout bij toevoegen aan afspeellijst: $error';
  }

  @override
  String get errorAlreadyInPlaylist =>
      'Deze media staat al in deze afspeellijst.';

  @override
  String errorLoadingPlaylists(String message) {
    return 'Fout bij het laden van afspeellijsten: $message';
  }

  @override
  String get errorReportUnavailableForContent =>
      'Melden is niet beschikbaar voor deze inhoud.';

  @override
  String get snackbarLoadingEpisodes => 'Afleveringen laden…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist =>
      'Aflevering niet beschikbaar in deze afspeellijst.';

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
  String get libraryTypeInProgress => 'Verderkijken';

  @override
  String get libraryTypeFavoriteMovies => 'Favoriete films';

  @override
  String get libraryTypeFavoriteSeries => 'Favoriete series';

  @override
  String get libraryTypeHistory => 'Geschiedenis';

  @override
  String get libraryTypePlaylist => 'Afspeellijst';

  @override
  String get libraryTypeArtist => 'Artiest';

  @override
  String libraryItemCount(int count) {
    return '$count item';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return 'Afspeellijst hernoemd naar \"$name\"';
  }

  @override
  String get snackbarPlaylistDeleted => 'Afspeellijst verwijderd';

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
      'Deze media staat al in de afspeellijst.';

  @override
  String get snackbarAddedToPlaylist => 'Toegevoegd aan de afspeellijst';

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
    return '$provider doorzoeken';
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
  String get pinRecoveryLink => 'PIN herstellen';

  @override
  String get pinRecoveryTitle => 'PIN herstellen';

  @override
  String get pinRecoveryDescription =>
      'Herstel de PIN van je beveiligde profiel.';

  @override
  String get pinRecoveryRequestCodeButton => 'Code verzenden';

  @override
  String get pinRecoveryCodeSentHint =>
      'De code is verzonden naar het e-mailadres van je account. Controleer je berichten en voer hem hieronder in.';

  @override
  String get pinRecoveryComingSoon => 'Deze functie komt binnenkort.';

  @override
  String get pinRecoveryNotAvailable =>
      'PIN-herstel via e-mail is momenteel niet beschikbaar.';

  @override
  String get pinRecoveryCodeLabel => 'Herstelcode';

  @override
  String get pinRecoveryCodeHint => '8 cijfers';

  @override
  String get pinRecoveryVerifyButton => 'Code verifiëren';

  @override
  String get pinRecoveryCodeInvalid => 'Voer de 8-cijferige code in.';

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
  String get pinRecoveryResetButton => 'PIN opnieuw instellen';

  @override
  String get pinRecoveryPinInvalid => 'Voer een PIN van 4 tot 6 cijfers in.';

  @override
  String get pinRecoveryPinMismatch => 'De pincodes komen niet overeen';

  @override
  String get pinRecoveryResetSuccess => 'Pincode bijgewerkt';

  @override
  String get profilePinSaved => 'PIN opgeslagen.';

  @override
  String get profilePinEditLabel => 'PIN-code bewerken';

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
  String get settingsPreferredAudioLanguage => 'Gewenste audiotaal';

  @override
  String get settingsPreferredSubtitleLanguage => 'Gewenste ondertitelingstaal';

  @override
  String get libraryPlaylistsFilter => 'Afspeellijsten';

  @override
  String get librarySagasFilter => 'Saga\'s';

  @override
  String get libraryArtistsFilter => 'Artiesten';

  @override
  String get librarySearchPlaceholder => 'Zoeken in mijn bibliotheek...';

  @override
  String get libraryInProgress => 'Verderkijken';

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
    return 'Verderkijken S$season · E$episode';
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
  String get playlistAddButton => 'Aan afspeellijst toevoegen';

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
  String get playlistDeleteTitle => 'Afspeellijst verwijderen';

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
  String get movieNoPlaylistsAvailable => 'Geen afspeellijsten beschikbaar';

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
      'Film niet beschikbaar in deze afspeellijst';

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
      'Vul je e-mailadres en de 8-cijferige code in die we je sturen.';

  @override
  String get authOtpEmailLabel => 'E-mail';

  @override
  String get authOtpEmailHint => 'naam@voorbeeld.nl';

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
    return 'Code opnieuw verzenden over ${seconds}s';
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
  String get entityPlaylist => 'Afspeellijst';

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
      'Niet ondersteund door deze backend of op dit platform.';

  @override
  String get settingsSyncResetOffsets => 'Synchronisatie-offsets resetten';

  @override
  String get aboutTmdbDisclaimer =>
      'Dit product gebruikt de TMDB-API, maar wordt niet onderschreven of gecertificeerd door TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Credits';

  @override
  String get actionSend => 'Verzenden';

  @override
  String get profilePinSetLabel => 'Pincode instellen';

  @override
  String get reportingProblemSentConfirmation => 'Melding verzonden. Bedankt.';

  @override
  String get reportingProblemBody =>
      'Als deze inhoud niet geschikt is en ondanks de beperkingen toch toegankelijk was, beschrijf het probleem dan kort.';

  @override
  String get reportingProblemExampleHint =>
      'Voorbeeld: horrorfilm zichtbaar ondanks PEGI 12';

  @override
  String get settingsAutomaticOption => 'Automatisch';

  @override
  String get settingsPreferredPlaybackQuality =>
      'Voorkeurskwaliteit voor afspelen';

  @override
  String settingsSignOutError(String error) {
    return 'Fout bij uitloggen: $error';
  }

  @override
  String get settingsTermsOfUseTitle => 'Gebruiksvoorwaarden';

  @override
  String get settingsCloudSyncPremiumRequiredMessage =>
      'Movi Premium is vereist voor cloudsynchronisatie.';
}
