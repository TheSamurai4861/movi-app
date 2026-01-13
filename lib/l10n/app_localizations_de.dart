// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get welcomeTitle => 'Willkommen!';

  @override
  String get welcomeSubtitle =>
      'Vervollständige deine Einstellungen, um Movi zu personalisieren.';

  @override
  String get labelUsername => 'Spitzname';

  @override
  String get labelPreferredLanguage => 'Bevorzugte Sprache';

  @override
  String get actionContinue => 'Weiter';

  @override
  String get hintUsername => 'Dein Spitzname';

  @override
  String get errorFillFields => 'Bitte fülle die Felder korrekt aus.';

  @override
  String get homeWatchNow => 'Jetzt ansehen';

  @override
  String get welcomeSourceTitle => 'Willkommen!';

  @override
  String get welcomeSourceSubtitle =>
      'Füge eine Quelle hinzu, um deine Erfahrung in Movi zu personalisieren.';

  @override
  String get welcomeSourceAdd => 'Quelle hinzufügen';

  @override
  String get searchTitle => 'Suchen';

  @override
  String get searchHint => 'Gib deine Suche ein';

  @override
  String get clear => 'Löschen';

  @override
  String get moviesTitle => 'Filme';

  @override
  String get seriesTitle => 'Serien';

  @override
  String get noResults => 'Keine Ergebnisse';

  @override
  String get historyTitle => 'Verlauf';

  @override
  String get historyEmpty => 'Keine kürzlichen Suchen';

  @override
  String get delete => 'Löschen';

  @override
  String resultsCount(int count) {
    return '($count Ergebnisse)';
  }

  @override
  String get errorUnknown => 'Unbekannter Fehler';

  @override
  String errorConnectionFailed(String error) {
    return 'Verbindungsfehler: $error';
  }

  @override
  String get errorConnectionGeneric => 'Verbindungsfehler';

  @override
  String get validationRequired => 'Erforderlich';

  @override
  String get validationInvalidUrl => 'Ungültige URL';

  @override
  String get snackbarSourceAddedBackground =>
      'IPTV-Quelle hinzugefügt. Synchronisierung im Hintergrund…';

  @override
  String get snackbarSourceAddedSynced =>
      'IPTV-Quelle hinzugefügt und synchronisiert';

  @override
  String get navHome => 'Startseite';

  @override
  String get navSearch => 'Suchen';

  @override
  String get navLibrary => 'Bibliothek';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguageLabel => 'Anwendungssprache';

  @override
  String get settingsGeneralTitle => 'Allgemeine Einstellungen';

  @override
  String get settingsDarkModeTitle => 'Dunkler Modus';

  @override
  String get settingsDarkModeSubtitle =>
      'Aktiviere ein nachtfreundliches Design.';

  @override
  String get settingsNotificationsTitle => 'Benachrichtigungen';

  @override
  String get settingsNotificationsSubtitle =>
      'Werde über neue Veröffentlichungen benachrichtigt.';

  @override
  String get settingsAccountTitle => 'Konto';

  @override
  String get settingsProfileInfoTitle => 'Profilinformationen';

  @override
  String get settingsProfileInfoSubtitle => 'Name, Avatar, Einstellungen';

  @override
  String get settingsAboutTitle => 'Über';

  @override
  String get settingsLegalMentionsTitle => 'Rechtliche Hinweise';

  @override
  String get settingsPrivacyPolicyTitle => 'Datenschutzrichtlinie';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionConfirm => 'Bestätigen';

  @override
  String get actionRetry => 'Wiederholen';

  @override
  String get homeErrorSwipeToRetry =>
      'Ein Fehler ist aufgetreten. Nach unten wischen, um erneut zu versuchen.';

  @override
  String get homeContinueWatching => 'Weiter ansehen';

  @override
  String get homeNoIptvSources =>
      'Keine IPTV-Quelle aktiv. Füge eine Quelle in den Einstellungen hinzu, um deine Kategorien zu sehen.';

  @override
  String get homeNoTrends => 'Keine Trendinhalte verfügbar';

  @override
  String get actionRefreshMetadata => 'Metadaten aktualisieren';

  @override
  String get actionChangeMetadata => 'Metadaten ändern';

  @override
  String get actionAddToList => 'Zu einer Liste hinzufügen';

  @override
  String get metadataRefreshed => 'Metadaten aktualisiert';

  @override
  String get errorRefreshingMetadata =>
      'Fehler beim Aktualisieren der Metadaten';

  @override
  String get actionMarkSeen => 'Als gesehen markieren';

  @override
  String get actionMarkUnseen => 'Als nicht gesehen markieren';

  @override
  String get actionReportProblem => 'Problem melden';

  @override
  String get featureComingSoon => 'Funktion kommt bald';

  @override
  String get subtitlesMenuTitle => 'Untertitel';

  @override
  String get audioMenuTitle => 'Audio';

  @override
  String get videoFitModeMenuTitle => 'Anzeigemodus';

  @override
  String get videoFitModeContain => 'Originale Proportionen';

  @override
  String get videoFitModeCover => 'Bildschirm füllen';

  @override
  String get actionDisable => 'Deaktivieren';

  @override
  String defaultTrackLabel(String id) {
    return 'Spur $id';
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
  String get actionNextEpisode => 'Nächste Episode';

  @override
  String get actionRestart => 'Neu starten';

  @override
  String get errorSeriesDataUnavailable =>
      'Seriendaten können nicht geladen werden';

  @override
  String get errorNextEpisodeFailed =>
      'Nächste Episode kann nicht bestimmt werden';

  @override
  String get actionLoadMore => 'Mehr laden';

  @override
  String get iptvServerUrlLabel => 'Server-URL';

  @override
  String get iptvServerUrlHint => 'Xtream-Server-URL';

  @override
  String get iptvPasswordLabel => 'Passwort';

  @override
  String get iptvPasswordHint => 'Xtream-Passwort';

  @override
  String get actionConnect => 'Verbinden';

  @override
  String get settingsRefreshIptvPlaylistsTitle =>
      'IPTV-Wiedergabelisten aktualisieren';

  @override
  String get statusActive => 'Aktiv';

  @override
  String get statusNoActiveSource => 'Keine aktive Quelle';

  @override
  String get overlayPreparingHome => 'Startseite wird vorbereitet…';

  @override
  String get bootstrapRefreshing => 'IPTV-Listen werden aktualisiert…';

  @override
  String get bootstrapEnriching => 'Metadaten werden vorbereitet…';

  @override
  String get errorPrepareHome => 'Startseite konnte nicht vorbereitet werden';

  @override
  String get overlayOpeningHome => 'Startseite wird geöffnet…';

  @override
  String get overlayRefreshingIptvLists => 'IPTV-Listen werden aktualisiert…';

  @override
  String get overlayPreparingMetadata => 'Metadaten werden vorbereitet…';

  @override
  String get errorHomeLoadTimeout => 'Timeout beim Laden der Startseite';

  @override
  String get faqLabel => 'FAQ';

  @override
  String get iptvUsernameLabel => 'Benutzername';

  @override
  String get iptvUsernameHint => 'Xtream-Benutzername';

  @override
  String get actionBack => 'Zurück';

  @override
  String get actionSeeAll => 'Alle anzeigen';

  @override
  String get actionExpand => 'Erweitern';

  @override
  String get actionCollapse => 'Reduzieren';

  @override
  String providerSearchPlaceholder(String provider) {
    return 'Suche auf $provider...';
  }

  @override
  String get actionClearHistory => 'Verlauf löschen';

  @override
  String get castTitle => 'Besetzung';

  @override
  String get recommendationsTitle => 'Empfehlungen';

  @override
  String get libraryHeader => 'Deine Videothek';

  @override
  String get libraryDataInfo =>
      'Daten werden angezeigt, wenn data/domain implementiert ist.';

  @override
  String get libraryEmpty =>
      'Markiere Filme, Serien oder Schauspieler, um sie hier zu sehen.';

  @override
  String get serie => 'Serie';

  @override
  String get recherche => 'Suchen';

  @override
  String get notYetAvailable => 'Noch nicht verfügbar';

  @override
  String get createPlaylistTitle => 'Playlist erstellen';

  @override
  String get playlistName => 'Playlist-Name';

  @override
  String get addMedia => 'Medien hinzufügen';

  @override
  String get renamePlaylist => 'Umbenennen';

  @override
  String get deletePlaylist => 'Löschen';

  @override
  String get pinPlaylist => 'Anheften';

  @override
  String get unpinPlaylist => 'Lösen';

  @override
  String get playlistPinned => 'Playlist angeheftet';

  @override
  String get playlistUnpinned => 'Playlist gelöst';

  @override
  String get playlistDeleted => 'Playlist gelöscht';

  @override
  String playlistCreatedSuccess(String name) {
    return 'Playlist \"$name\" erstellt';
  }

  @override
  String playlistCreateError(String error) {
    return 'Fehler beim Erstellen der Playlist: $error';
  }

  @override
  String get addedToPlaylist => 'Hinzugefügt';

  @override
  String get pinRecoveryLink => 'Récupérer le code PIN';

  @override
  String get pinRecoveryTitle => 'PIN-Code wiederherstellen';

  @override
  String get pinRecoveryDescription =>
      'Rufen Sie den PIN-Code für Ihr geschütztes Profil ab.';

  @override
  String get pinRecoveryComingSoon => 'Diese Funktion kommt bald.';

  @override
  String get pinRecoveryCodeLabel => 'Wiederherstellungscode';

  @override
  String get pinRecoveryCodeHint => '8 Ziffern';

  @override
  String get pinRecoveryVerifyButton => 'Überprüfen';

  @override
  String get pinRecoveryCodeInvalid => 'Geben Sie den 8-stelligen Code ein';

  @override
  String get pinRecoveryCodeExpired =>
      'Der Wiederherstellungscode ist abgelaufen';

  @override
  String get pinRecoveryTooManyAttempts =>
      'Zu viele Versuche. Bitte später erneut versuchen.';

  @override
  String get pinRecoveryUnknownError =>
      'Ein unerwarteter Fehler ist aufgetreten';

  @override
  String get pinRecoveryNewPinLabel => 'Neuer PIN';

  @override
  String get pinRecoveryNewPinHint => '4-6 Ziffern';

  @override
  String get pinRecoveryConfirmPinLabel => 'PIN bestätigen';

  @override
  String get pinRecoveryConfirmPinHint => 'PIN erneut eingeben';

  @override
  String get pinRecoveryResetButton => 'PIN aktualisieren';

  @override
  String get pinRecoveryPinInvalid =>
      'Geben Sie eine PIN mit 4 bis 6 Ziffern ein';

  @override
  String get pinRecoveryPinMismatch => 'Die PINs stimmen nicht überein';

  @override
  String get pinRecoveryResetSuccess => 'PIN aktualisiert';

  @override
  String get settingsAccountsSection => 'Konten';

  @override
  String get settingsIptvSection => 'IPTV-Einstellungen';

  @override
  String get settingsSourcesManagement => 'Quellenverwaltung';

  @override
  String get settingsSyncFrequency => 'Aktualisierungsfrequenz';

  @override
  String get settingsAppSection => 'App-Einstellungen';

  @override
  String get settingsAccentColor => 'Akzentfarbe';

  @override
  String get settingsPlaybackSection => 'Wiedergabeeinstellungen';

  @override
  String get settingsPreferredAudioLanguage => 'Bevorzugte Sprache';

  @override
  String get settingsPreferredSubtitleLanguage => 'Bevorzugte Untertitel';

  @override
  String get libraryPlaylistsFilter => 'Wiedergabelisten';

  @override
  String get librarySagasFilter => 'Sagas';

  @override
  String get libraryArtistsFilter => 'Künstler';

  @override
  String get librarySearchPlaceholder => 'In meiner Bibliothek suchen...';

  @override
  String get libraryInProgress => 'In Bearbeitung';

  @override
  String get libraryFavoriteMovies => 'Lieblingsfilme';

  @override
  String get libraryFavoriteSeries => 'Lieblingsserien';

  @override
  String get libraryWatchHistory => 'Wiedergabeverlauf';

  @override
  String libraryItemCount(int count) {
    return '$count Element';
  }

  @override
  String libraryItemCountPlural(int count) {
    return '$count Elemente';
  }

  @override
  String get searchPeopleTitle => 'Personen';

  @override
  String get searchSagasTitle => 'Sagas';

  @override
  String get searchByProvidersTitle => 'Nach Anbietern';

  @override
  String get searchByGenresTitle => 'Nach Genres';

  @override
  String get personRoleActor => 'Schauspieler';

  @override
  String get personRoleDirector => 'Regisseur';

  @override
  String get personRoleCreator => 'Ersteller';

  @override
  String get tvDistribution => 'Besetzung';

  @override
  String tvSeasonLabel(int number) {
    return 'Staffel $number';
  }

  @override
  String get tvNoEpisodesAvailable => 'Keine Episoden verfügbar';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return 'Fortsetzen S$season E$episode';
  }

  @override
  String get sagaViewPage => 'Seite ansehen';

  @override
  String get sagaStartNow => 'Jetzt starten';

  @override
  String get sagaContinue => 'Fortsetzen';

  @override
  String sagaMovieCount(int count) {
    return '$count Filme';
  }

  @override
  String get sagaMoviesList => 'Filmliste';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies Filme - $shows Serien';
  }

  @override
  String get personPlayRandomly => 'Zufällig abspielen';

  @override
  String get personMoviesList => 'Filmliste';

  @override
  String get personSeriesList => 'Serienliste';

  @override
  String get playlistPlayRandomly => 'Zufällig abspielen';

  @override
  String get playlistAddButton => 'Hinzufügen';

  @override
  String get playlistSortButton => 'Sortieren';

  @override
  String get playlistSortByTitle => 'Sortieren nach';

  @override
  String get playlistSortByTitleOption => 'Titel';

  @override
  String get playlistSortRecentAdditions => 'Kürzlich hinzugefügt';

  @override
  String get playlistSortOldestFirst => 'Älteste zuerst';

  @override
  String get playlistSortNewestFirst => 'Neueste zuerst';

  @override
  String get playlistEmptyMessage => 'Keine Elemente in dieser Liste';

  @override
  String playlistItemCount(int count) {
    return '$count Element';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count Elemente';
  }

  @override
  String get playlistSeasonSingular => 'Staffel';

  @override
  String get playlistSeasonPlural => 'Staffeln';

  @override
  String get playlistRenameTitle => 'Liste umbenennen';

  @override
  String get playlistNamePlaceholder => 'Listenname';

  @override
  String playlistRenamedSuccess(String name) {
    return 'Liste umbenannt zu \"$name\"';
  }

  @override
  String get playlistDeleteTitle => 'Löschen';

  @override
  String playlistDeleteConfirm(String title) {
    return 'Möchtest du \"$title\" wirklich löschen?';
  }

  @override
  String get playlistDeletedSuccess => 'Liste gelöscht';

  @override
  String get playlistItemRemovedSuccess => 'Element entfernt';

  @override
  String playlistRemoveItemConfirm(String title) {
    return '\"$title\" aus der Liste entfernen?';
  }

  @override
  String get categoryLoadFailed => 'Fehler beim Laden der Kategorie.';

  @override
  String get categoryEmpty => 'Keine Elemente in dieser Kategorie.';

  @override
  String get categoryLoadingMore => 'Lade mehr…';

  @override
  String get movieNoPlaylistsAvailable => 'Keine Playlist verfügbar';

  @override
  String playlistAddedTo(String title) {
    return 'Hinzugefügt zu \"$title\"';
  }

  @override
  String errorWithMessage(String message) {
    return 'Fehler: $message';
  }

  @override
  String get movieNotAvailableInPlaylist =>
      'Film nicht in der Playlist verfügbar';

  @override
  String errorLoadingPlaylists(String message) {
    return 'Fehler beim Laden der Playlists: $message';
  }

  @override
  String errorPlaybackFailed(String message) {
    return 'Fehler beim Abspielen des Films: $message';
  }

  @override
  String get movieNoMedia => 'Keine Medien zum Anzeigen.';

  @override
  String get personNoData => 'Keine Person anzuzeigen.';

  @override
  String get personGenericError =>
      'Beim Laden dieser Person ist ein Fehler aufgetreten.';

  @override
  String get personBiographyTitle => 'Biografie';

  @override
  String get authOtpTitle => 'Anmelden';

  @override
  String get authOtpSubtitle =>
      'Gib deine E-Mail-Adresse und den 8-stelligen Code ein, den wir dir senden.';

  @override
  String get authOtpEmailLabel => 'E-Mail';

  @override
  String get authOtpEmailHint => 'dein@email';

  @override
  String get authOtpEmailHelp =>
      'Wir senden dir einen 8-stelligen Code. Prüfe ggf. den Spam-Ordner.';

  @override
  String get authOtpCodeLabel => 'Bestätigungscode';

  @override
  String get authOtpCodeHint => '8-stelliger Code';

  @override
  String get authOtpCodeHelp => 'Gib den 8-stelligen Code aus der E-Mail ein.';

  @override
  String get authOtpPrimarySend => 'Code senden';

  @override
  String get authOtpPrimarySubmit => 'Anmelden';

  @override
  String get authOtpResend => 'Code erneut senden';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Code erneut senden in ${seconds}s';
  }

  @override
  String get authOtpChangeEmail => 'E-Mail ändern';

  @override
  String get resumePlayback => 'Wiedergabe fortsetzen';

  @override
  String get settingsCloudSyncSection => 'Cloud-Sync';

  @override
  String get settingsCloudSyncAuto => 'Automatische Synchronisierung';

  @override
  String get settingsCloudSyncNow => 'Jetzt synchronisieren';

  @override
  String get settingsCloudSyncInProgress => 'Synchronisierung…';

  @override
  String get settingsCloudSyncNever => 'Nie';

  @override
  String settingsCloudSyncError(Object error) {
    return 'Letzter Fehler: $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return '$entity nicht gefunden';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return '$entity nicht gefunden: $error';
  }

  @override
  String get entityProvider => 'Anbieter';

  @override
  String get entityGenre => 'Genre';

  @override
  String get entityPlaylist => 'Playlist';

  @override
  String get entitySource => 'Quelle';

  @override
  String get entityMovie => 'Film';

  @override
  String get entitySeries => 'Serie';

  @override
  String get entityPerson => 'Person';

  @override
  String get entitySaga => 'Saga';

  @override
  String get entityVideo => 'Video';

  @override
  String get entityRoute => 'Route';

  @override
  String get errorTimeoutLoading => 'Zeitüberschreitung beim Laden';

  @override
  String get parentalContentRestricted => 'Eingeschränkter Inhalt';

  @override
  String get parentalContentRestrictedDefault =>
      'Dieser Inhalt ist durch die Jugendschutzeinstellungen dieses Profils blockiert.';

  @override
  String get parentalReasonTooYoung =>
      'Dieser Inhalt erfordert ein höheres Alter als die Grenze dieses Profils.';

  @override
  String get parentalReasonUnknownRating =>
      'Die Altersfreigabe für diesen Inhalt ist nicht verfügbar.';

  @override
  String get parentalReasonInvalidTmdbId =>
      'Dieser Inhalt kann nicht für die Jugendschutzkontrolle bewertet werden.';

  @override
  String get parentalUnlockButton => 'Entsperren';
}
