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
  String get settingsHelpDiagnosticsSection => 'Hilfe & Diagnose';

  @override
  String get settingsExportErrorLogs => 'Fehlerprotokolle exportieren';

  @override
  String get diagnosticsExportTitle => 'Fehlerprotokolle exportieren';

  @override
  String get diagnosticsExportDescription =>
      'Die Diagnose enthält nur aktuelle WARN/ERROR-Logs und gehashte Konto-/Profilkennungen (falls aktiviert). Es sollten keine Schlüssel/Token erscheinen.';

  @override
  String get diagnosticsIncludeHashedIdsTitle =>
      'Konto-/Profilkennungen einschließen (gehasht)';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle =>
      'Hilft, einen Bug zuzuordnen, ohne die rohe ID offenzulegen.';

  @override
  String get diagnosticsCopiedClipboard =>
      'Diagnose in die Zwischenablage kopiert.';

  @override
  String diagnosticsSavedFile(String fileName) {
    return 'Diagnose gespeichert: $fileName';
  }

  @override
  String get diagnosticsActionCopy => 'Kopieren';

  @override
  String get diagnosticsActionSave => 'Speichern';

  @override
  String get actionChangeVersion => 'Version ändern';

  @override
  String get semanticsBack => 'Zurück';

  @override
  String get semanticsMoreActions => 'Weitere Aktionen';

  @override
  String get snackbarLoadingPlaylists => 'Playlists werden geladen…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne =>
      'Keine Playlist verfügbar. Erstelle eine.';

  @override
  String errorAddToPlaylist(String error) {
    return 'Fehler beim Hinzufügen zur Playlist: $error';
  }

  @override
  String get errorAlreadyInPlaylist =>
      'Dieses Medium ist bereits in dieser Playlist';

  @override
  String errorLoadingPlaylists(String message) {
    return 'Fehler beim Laden der Playlists: $message';
  }

  @override
  String get errorReportUnavailableForContent =>
      'Meldung für diesen Inhalt nicht verfügbar.';

  @override
  String get snackbarLoadingEpisodes => 'Episoden werden geladen…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist =>
      'Episode in der Playlist nicht verfügbar';

  @override
  String snackbarGenericError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get snackbarLoading => 'Wird geladen…';

  @override
  String get snackbarNoVersionAvailable => 'Keine Version verfügbar';

  @override
  String get snackbarVersionSaved => 'Version gespeichert';

  @override
  String playbackVariantFallbackLabel(int index) {
    return 'Version $index';
  }

  @override
  String get actionReadMore => 'Mehr lesen';

  @override
  String get actionShowLess => 'Weniger anzeigen';

  @override
  String get actionViewPage => 'Seite ansehen';

  @override
  String get semanticsSeeSagaPage => 'Saga-Seite ansehen';

  @override
  String get libraryTypeSaga => 'Saga';

  @override
  String get libraryTypeInProgress => 'In Arbeit';

  @override
  String get libraryTypeFavoriteMovies => 'Lieblingsfilme';

  @override
  String get libraryTypeFavoriteSeries => 'Lieblingsserien';

  @override
  String get libraryTypeHistory => 'Verlauf';

  @override
  String get libraryTypePlaylist => 'Playlist';

  @override
  String get libraryTypeArtist => 'Künstler';

  @override
  String libraryItemCount(int count) {
    return '$count Element';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return 'Playlist umbenannt in „$name“';
  }

  @override
  String get snackbarPlaylistDeleted => 'Playlist gelöscht';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return 'Möchtest du „$title“ wirklich löschen?';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return 'Keine Ergebnisse für „$query“';
  }

  @override
  String errorGenericWithMessage(String error) {
    return 'Fehler: $error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist =>
      'Dieses Medium ist bereits in der Playlist';

  @override
  String get snackbarAddedToPlaylist => 'Zur Playlist hinzugefügt';

  @override
  String get addMediaTitle => 'Medien hinzufügen';

  @override
  String get searchMinCharsHint => 'Gib mindestens 3 Zeichen zum Suchen ein';

  @override
  String get badgeAdded => 'Hinzugefügt';

  @override
  String get snackbarNotAvailableOnSource =>
      'Auf dieser Quelle nicht verfügbar';

  @override
  String get errorLoadingTitle => 'Ladefehler';

  @override
  String errorLoadingWithMessage(String error) {
    return 'Fehler: $error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return 'Fehler beim Laden: $error';
  }

  @override
  String get libraryClearFilterSemanticLabel => 'Filter entfernen';

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
  String get activeSourceTitle => 'Aktive Quelle';

  @override
  String get statusActive => 'Aktiv';

  @override
  String get statusNoActiveSource => 'Keine aktive Quelle';

  @override
  String get overlayPreparingHome => 'Startseite wird vorbereitet…';

  @override
  String get overlayLoadingMoviesAndSeries => 'Filme & Serien werden geladen…';

  @override
  String get overlayLoadingCategories => 'Kategorien werden geladen…';

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
  String get pinRecoveryRequestCodeButton => 'Send code';

  @override
  String get pinRecoveryCodeSentHint =>
      'Code sent to your account email. Check your messages and enter it below.';

  @override
  String get pinRecoveryComingSoon => 'Diese Funktion kommt bald.';

  @override
  String get pinRecoveryNotAvailable =>
      'PIN recovery by email is currently unavailable.';

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
  String get profilePinSaved => 'PIN saved.';

  @override
  String get profilePinEditLabel => 'Edit PIN code';

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
  String get hc_chargement_episodes_en_cours_33fc4ace =>
      'Episoden werden geladen…';

  @override
  String get hc_aucune_playlist_disponible_creez_en_une_f6b75c90 =>
      'Keine Playlist verfügbar. Erstelle eine.';

  @override
  String get hc_erreur_lors_chargement_playlists_placeholder_97e5c1c3 =>
      'Fehler beim Laden der Playlists: \$e';

  @override
  String get hc_impossible_douvrir_lien_90d0dcaa =>
      'Link kann nicht geöffnet werden';

  @override
  String get hc_qualite_preferee_776dbeea => 'Bevorzugte Qualität';

  @override
  String get hc_annuler_49ba3292 => 'Cancel';

  @override
  String get hc_deconnexion_903dca17 => 'Abmelden';

  @override
  String get hc_erreur_lors_deconnexion_placeholder_f5a211b4 =>
      'Fehler beim Abmelden: \$e';

  @override
  String get hc_choisir_b030d590 => 'Choose';

  @override
  String get hc_avantages_08d7f47c => 'Benefits';

  @override
  String get hc_signalement_envoye_merci_d302e576 => 'Meldung gesendet. Danke.';

  @override
  String get hc_plus_tard_1f42ab3b => 'Später';

  @override
  String get hc_redemarrer_maintenant_053e8e68 => 'Jetzt neu starten';

  @override
  String get hc_utiliser_cette_source_c6c8bbc5 => 'Diese Quelle verwenden?';

  @override
  String get hc_utiliser_fb5e43ce => 'Use';

  @override
  String get hc_source_ajout_e_e41b01d9 => 'Quelle hinzugefügt';

  @override
  String get hc_title_0a57b7eb => 'title: \'...\'';

  @override
  String get hc_labeltext_469a28db => 'labelText: \'...\'';

  @override
  String get hc_hinttext_6fd1d945 => 'hintText: \'...\'';

  @override
  String get hc_tooltip_db0de3fe => 'tooltip: \'...\'';

  @override
  String get hc_parametres_verrouilles_3a9b1b51 => 'Gesperrte Einstellungen';

  @override
  String get hc_compte_cloud_2812b31e => 'Cloud-Konto';

  @override
  String get hc_se_connecter_fedf2439 => 'Anmelden';

  @override
  String get hc_propos_5345add5 => 'Über';

  @override
  String get hc_politique_confidentialite_42b0e51e => 'Datenschutzrichtlinie';

  @override
  String get hc_conditions_dutilisation_9074eac7 => 'Nutzungsbedingungen';

  @override
  String get hc_sources_sauvegardees_9f1382e5 => 'Gespeicherte Quellen';

  @override
  String get hc_rafraichir_be30b7d1 => 'Aktualisieren';

  @override
  String get hc_activer_une_source_749ced38 => 'Quelle aktivieren';

  @override
  String get hc_nom_source_9a3e4156 => 'Quellenname';

  @override
  String get hc_mon_iptv_b239352c => 'Mein IPTV';

  @override
  String get hc_username_84c29015 => 'Benutzername';

  @override
  String get hc_password_8be3c943 => 'Passwort';

  @override
  String get hc_server_url_1d5d1eff => 'Server-URL';

  @override
  String get hc_verification_pin_e17c8fe0 => 'PIN-Bestätigung';

  @override
  String get hc_definir_un_pin_f9c2178d => 'PIN festlegen';

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
      'Auf dieser Quelle nicht verfügbar';

  @override
  String get hc_source_supprimee_4bfaa0a1 => 'Quelle entfernt';

  @override
  String get hc_source_modifiee_335ef502 => 'Quelle aktualisiert';

  @override
  String get hc_definir_code_pin_53a0bd07 => 'PIN-Code festlegen';

  @override
  String get hc_marquer_comme_non_vu_9cf9d3f8 => 'Als ungesehen markieren';

  @override
  String get hc_etes_vous_sur_vouloir_vous_deconnecter_1a096661 =>
      'Möchtest du dich wirklich abmelden?';

  @override
  String get hc_movi_premium_requis_pour_synchronisation_cloud_15b551df =>
      'Movi Premium ist für die Cloud-Synchronisierung erforderlich.';

  @override
  String get hc_auto_c614ba7c => 'Auto';

  @override
  String get hc_organiser_838a7e57 => 'Organisieren';

  @override
  String get hc_modifier_f260e757 => 'Bearbeiten';

  @override
  String get hc_ajouter_87c57ed1 => 'Hinzufügen';

  @override
  String get hc_source_active_e571305e => 'Aktive Quelle';

  @override
  String get hc_autres_sources_e32592a6 => 'Andere Quellen';

  @override
  String get hc_signalement_indisponible_pour_ce_contenu_d9ad88b7 =>
      'Melden ist für diesen Inhalt nicht verfügbar.';

  @override
  String get hc_securisation_contenu_e5195111 => 'Inhalt wird geschützt';

  @override
  String get hc_verification_classifications_d_age_006eebfe =>
      'Altersfreigaben werden geprüft…';

  @override
  String get hc_voir_tout_7b7d86e8 => 'Alle anzeigen';

  @override
  String get hc_signaler_un_probleme_13183c0f => 'Problem melden';

  @override
  String get hc_si_ce_contenu_nest_pas_approprie_ete_accessible_320c2436 =>
      'Wenn dieser Inhalt nicht geeignet ist und trotz Einschränkungen zugänglich war, beschreibe das Problem kurz.';

  @override
  String get hc_envoyer_e9ce243b => 'Senden';

  @override
  String get hc_profil_enfant_cree_39f4eb7d => 'Kinderprofil erstellt';

  @override
  String get hc_un_profil_enfant_ete_cree_pour_securiser_l_40e15a0a =>
      'Ein Kinderprofil wurde erstellt. Um die App zu sichern und Altersfreigaben vorzuladen, wird ein Neustart der App empfohlen.';

  @override
  String get hc_pseudo_4cf966c0 => 'Spitzname';

  @override
  String get hc_profil_enfant_2c8a01c0 => 'Kinderprofil';

  @override
  String get hc_limite_d_age_5b170fc9 => 'Altersgrenze';

  @override
  String get hc_code_pin_e79c48bd => 'PIN-Code';

  @override
  String get hc_changer_code_pin_3b069731 => 'PIN-Code ändern';

  @override
  String get hc_supprimer_code_pin_0dcf8a48 => 'PIN-Code entfernen';

  @override
  String get hc_supprimer_pin_51850c7b => 'PIN entfernen';

  @override
  String get hc_supprimer_1acfc1c7 => 'Löschen';

  @override
  String get hc_oblige_un_pin_active_filtre_pegi_8447ac9b =>
      'Erfordert eine PIN und aktiviert den PEGI-Filter.';

  @override
  String get hc_voulez_vous_activer_cette_source_maintenant_f2593894 =>
      'Möchtest du diese Quelle jetzt aktivieren?';

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
      'Dieses Produkt verwendet die TMDB-API, ist jedoch nicht von TMDB unterstützt oder zertifiziert.';

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
  String get hc_url_invalide_aa227a66 => 'Ungültige URL';

  @override
  String get hc_legacy_iv_missing_cannot_decrypt_legacy_ciphertext_7c7b39c3 =>
      'Legacy-IV fehlt: Legacy-Chiffretext kann nicht entschlüsselt werden.';

  @override
  String get hc_tooltip_rafraichir_a22b17e3 => 'tooltip: \'Aktualisieren\'';

  @override
  String get hc_tooltip_menu_d8fa6679 => 'tooltip: \'Menu\'';

  @override
  String get hc_retour_e5befb1f => 'Zurück';

  @override
  String get hc_semanticlabel_plus_d_actions_1bd19eb6 =>
      'semanticLabel: \'Weitere Aktionen\'';

  @override
  String get hc_plus_d_actions_ffe6be2a => 'Weitere Aktionen';

  @override
  String get hc_semanticlabel_rechercher_3ae4e02c =>
      'semanticLabel: \'Suchen\'';

  @override
  String get hc_semanticlabel_ajouter_ac362a68 =>
      'semanticLabel: \'Hinzufügen\'';

  @override
  String get hc_l10n_86d50bf0 => 'l10n.*';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSignOut => 'Abmelden';

  @override
  String get dialogSignOutBody => 'Möchtest du dich wirklich abmelden?';

  @override
  String get settingsUnableToOpenLink => 'Link konnte nicht geöffnet werden';

  @override
  String get settingsSyncDisabled => 'Deaktiviert';

  @override
  String get settingsSyncEveryHour => 'Jede Stunde';

  @override
  String get settingsSyncEvery2Hours => 'Alle 2 Stunden';

  @override
  String get settingsSyncEvery4Hours => 'Alle 4 Stunden';

  @override
  String get settingsSyncEvery6Hours => 'Alle 6 Stunden';

  @override
  String get settingsSyncEveryDay => 'Täglich';

  @override
  String get settingsSyncEvery2Days => 'Alle 2 Tage';

  @override
  String get settingsColorCustom => 'Benutzerdefiniert';

  @override
  String get settingsColorBlue => 'Blau';

  @override
  String get settingsColorPink => 'Rosa';

  @override
  String get settingsColorGreen => 'Grün';

  @override
  String get settingsColorPurple => 'Violett';

  @override
  String get settingsColorOrange => 'Orange';

  @override
  String get settingsColorTurquoise => 'Türkis';

  @override
  String get settingsColorYellow => 'Gelb';

  @override
  String get settingsColorIndigo => 'Indigo';

  @override
  String get settingsCloudAccountTitle => 'Cloud-Konto';

  @override
  String get settingsAccountConnected => 'Verbunden';

  @override
  String get settingsAccountLocalMode => 'Lokaler Modus';

  @override
  String get settingsAccountCloudUnavailable => 'Cloud nicht verfügbar';

  @override
  String get settingsSubtitlesTitle => 'Untertitel';

  @override
  String get settingsSubtitlesSizeTitle => 'Textgröße';

  @override
  String get settingsSubtitlesColorTitle => 'Textfarbe';

  @override
  String get settingsSubtitlesFontTitle => 'Schriftart';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => 'System';

  @override
  String get settingsSubtitlesQuickSettingsTitle => 'Schnelleinstellungen';

  @override
  String get settingsSubtitlesPreviewTitle => 'Vorschau';

  @override
  String get settingsSubtitlesPreviewSample =>
      'Dies ist eine Untertitelvorschau.\nPasse die Lesbarkeit in Echtzeit an.';

  @override
  String get settingsSubtitlesBackgroundTitle => 'Hintergrund';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => 'Hintergrund-Deckkraft';

  @override
  String get settingsSubtitlesShadowTitle => 'Schatten';

  @override
  String get settingsSubtitlesShadowOff => 'Aus';

  @override
  String get settingsSubtitlesShadowSoft => 'Weich';

  @override
  String get settingsSubtitlesShadowStrong => 'Stark';

  @override
  String get settingsSubtitlesFineSizeTitle => 'Feine Größe';

  @override
  String get settingsSubtitlesFineSizeValueLabel => 'Skalierung';

  @override
  String get settingsSubtitlesResetDefaults => 'Auf Standard zurücksetzen';

  @override
  String get settingsSubtitlesPremiumLockedTitle =>
      'Erweiterter Untertitelstil (Premium)';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      'Hintergrund, Deckkraft, Schatten-Presets und feine Größe sind mit Movi Premium verfügbar.';

  @override
  String get settingsSubtitlesPremiumLockedAction => 'Mit Premium freischalten';

  @override
  String get settingsSyncSectionTitle => 'Audio/Untertitel-Synchronisierung';

  @override
  String get settingsSubtitleOffsetTitle => 'Untertitelverzögerung';

  @override
  String get settingsAudioOffsetTitle => 'Audioverzögerung';

  @override
  String get settingsOffsetUnsupported =>
      'Auf diesem Backend oder dieser Plattform nicht unterstützt.';

  @override
  String get settingsSyncResetOffsets =>
      'Synchronisierungs-Offsets zurücksetzen';

  @override
  String get aboutTmdbDisclaimer =>
      'Dieses Produkt nutzt die TMDB-API, wird jedoch nicht von TMDB unterstützt oder zertifiziert.';

  @override
  String get aboutCreditsSectionTitle => 'Credits';
}
