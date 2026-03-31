// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get welcomeTitle => 'Witamy!';

  @override
  String get welcomeSubtitle =>
      'Uzupełnij preferencje, aby spersonalizować Movi.';

  @override
  String get labelUsername => 'Pseudonim';

  @override
  String get labelPreferredLanguage => 'Preferowany język';

  @override
  String get actionContinue => 'Kontynuuj';

  @override
  String get hintUsername => 'Twój pseudonim';

  @override
  String get errorFillFields => 'Proszę poprawnie wypełnić pola.';

  @override
  String get homeWatchNow => 'Oglądaj teraz';

  @override
  String get welcomeSourceTitle => 'Witamy!';

  @override
  String get welcomeSourceSubtitle => 'Dodaj źródło, aby spersonalizować Movi.';

  @override
  String get welcomeSourceAdd => 'Dodaj źródło';

  @override
  String get searchTitle => 'Szukaj';

  @override
  String get searchHint => 'Wpisz wyszukiwanie';

  @override
  String get clear => 'Wyczyść';

  @override
  String get moviesTitle => 'Filmy';

  @override
  String get seriesTitle => 'Seriale';

  @override
  String get noResults => 'Brak wyników';

  @override
  String get historyTitle => 'Historia';

  @override
  String get historyEmpty => 'Brak ostatnich wyszukiwań';

  @override
  String get delete => 'Usuń';

  @override
  String resultsCount(int count) {
    return '($count wyników)';
  }

  @override
  String get errorUnknown => 'Nieznany błąd';

  @override
  String errorConnectionFailed(String error) {
    return 'Połączenie nieudane: $error';
  }

  @override
  String get errorConnectionGeneric => 'Połączenie nieudane';

  @override
  String get validationRequired => 'Wymagane';

  @override
  String get validationInvalidUrl => 'Nieprawidłowy URL';

  @override
  String get snackbarSourceAddedBackground =>
      'Źródło IPTV dodane. Synchronizacja w tle…';

  @override
  String get snackbarSourceAddedSynced =>
      'Źródło IPTV dodane i zsynchronizowane';

  @override
  String get navHome => 'Strona główna';

  @override
  String get navSearch => 'Szukaj';

  @override
  String get navLibrary => 'Biblioteka';

  @override
  String get navSettings => 'Ustawienia';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get settingsLanguageLabel => 'Język aplikacji';

  @override
  String get settingsGeneralTitle => 'Preferencje ogólne';

  @override
  String get settingsDarkModeTitle => 'Tryb ciemny';

  @override
  String get settingsDarkModeSubtitle => 'Włącz motyw przyjazny nocy.';

  @override
  String get settingsNotificationsTitle => 'Powiadomienia';

  @override
  String get settingsNotificationsSubtitle =>
      'Bądź powiadamiany o nowych wydaniach.';

  @override
  String get settingsAccountTitle => 'Konto';

  @override
  String get settingsProfileInfoTitle => 'Informacje profilu';

  @override
  String get settingsProfileInfoSubtitle => 'Imię, avatar, preferencje';

  @override
  String get settingsAboutTitle => 'O aplikacji';

  @override
  String get settingsLegalMentionsTitle => 'Informacje prawne';

  @override
  String get settingsPrivacyPolicyTitle => 'Polityka prywatności';

  @override
  String get actionCancel => 'Anuluj';

  @override
  String get actionConfirm => 'Zatwierdź';

  @override
  String get actionRetry => 'Spróbuj ponownie';

  @override
  String get settingsHelpDiagnosticsSection => 'Pomoc i diagnostyka';

  @override
  String get settingsExportErrorLogs => 'Eksportuj logi błędów';

  @override
  String get diagnosticsExportTitle => 'Eksportuj logi błędów';

  @override
  String get diagnosticsExportDescription =>
      'Diagnoza zawiera tylko ostatnie logi WARN/ERROR oraz zahaszowane identyfikatory konta/profilu (jeśli włączone). Nie powinny pojawić się żadne klucze/tokeny.';

  @override
  String get diagnosticsIncludeHashedIdsTitle =>
      'Dołącz identyfikatory konta/profilu (hash)';

  @override
  String get diagnosticsIncludeHashedIdsSubtitle =>
      'Pomaga powiązać błąd bez ujawniania surowego ID.';

  @override
  String get diagnosticsCopiedClipboard => 'Diagnoza skopiowana do schowka.';

  @override
  String diagnosticsSavedFile(String fileName) {
    return 'Diagnoza zapisana: $fileName';
  }

  @override
  String get diagnosticsActionCopy => 'Kopiuj';

  @override
  String get diagnosticsActionSave => 'Zapisz';

  @override
  String get actionChangeVersion => 'Zmień wersję';

  @override
  String get semanticsBack => 'Wstecz';

  @override
  String get semanticsMoreActions => 'Więcej akcji';

  @override
  String get snackbarLoadingPlaylists => 'Ładowanie playlist…';

  @override
  String get snackbarNoPlaylistsAvailableCreateOne =>
      'Brak dostępnej playlisty. Utwórz nową.';

  @override
  String errorAddToPlaylist(String error) {
    return 'Błąd podczas dodawania do playlisty: $error';
  }

  @override
  String get errorAlreadyInPlaylist => 'Ten element jest już w tej playliście';

  @override
  String errorLoadingPlaylists(String message) {
    return 'Błąd podczas ładowania playlist: $message';
  }

  @override
  String get errorReportUnavailableForContent =>
      'Zgłoszenie jest niedostępne dla tej treści.';

  @override
  String get snackbarLoadingEpisodes => 'Ładowanie odcinków…';

  @override
  String get snackbarEpisodeUnavailableInPlaylist =>
      'Odcinek niedostępny w playliście';

  @override
  String snackbarGenericError(String error) {
    return 'Błąd: $error';
  }

  @override
  String get snackbarLoading => 'Ładowanie…';

  @override
  String get snackbarNoVersionAvailable => 'Brak dostępnej wersji';

  @override
  String get snackbarVersionSaved => 'Wersja zapisana';

  @override
  String playbackVariantFallbackLabel(int index) {
    return 'Wersja $index';
  }

  @override
  String get actionReadMore => 'Czytaj więcej';

  @override
  String get actionShowLess => 'Pokaż mniej';

  @override
  String get actionViewPage => 'Zobacz stronę';

  @override
  String get semanticsSeeSagaPage => 'Zobacz stronę sagi';

  @override
  String get libraryTypeSaga => 'Saga';

  @override
  String get libraryTypeInProgress => 'W toku';

  @override
  String get libraryTypeFavoriteMovies => 'Ulubione filmy';

  @override
  String get libraryTypeFavoriteSeries => 'Ulubione seriale';

  @override
  String get libraryTypeHistory => 'Historia';

  @override
  String get libraryTypePlaylist => 'Playlist';

  @override
  String get libraryTypeArtist => 'Artysta';

  @override
  String libraryItemCount(int count) {
    return '$count element';
  }

  @override
  String snackbarPlaylistRenamed(String name) {
    return 'Playlist zmieniona na „$name”';
  }

  @override
  String get snackbarPlaylistDeleted => 'Playlist usunięta';

  @override
  String dialogConfirmDeletePlaylist(String title) {
    return 'Czy na pewno chcesz usunąć „$title”?';
  }

  @override
  String libraryNoResultsForQuery(String query) {
    return 'Brak wyników dla „$query”';
  }

  @override
  String errorGenericWithMessage(String error) {
    return 'Błąd: $error';
  }

  @override
  String get snackbarMediaAlreadyInPlaylist =>
      'Ten element jest już w playliście';

  @override
  String get snackbarAddedToPlaylist => 'Dodano do playlisty';

  @override
  String get addMediaTitle => 'Dodaj media';

  @override
  String get searchMinCharsHint => 'Wpisz co najmniej 3 znaki, aby wyszukać';

  @override
  String get badgeAdded => 'Dodano';

  @override
  String get snackbarNotAvailableOnSource => 'Niedostępne na tym źródle';

  @override
  String get errorLoadingTitle => 'Błąd ładowania';

  @override
  String errorLoadingWithMessage(String error) {
    return 'Błąd: $error';
  }

  @override
  String errorLoadingPlaylistsWithMessage(String error) {
    return 'Błąd podczas ładowania: $error';
  }

  @override
  String get libraryClearFilterSemanticLabel => 'Usuń filtr';

  @override
  String get homeErrorSwipeToRetry =>
      'Wystąpił błąd. Przeciągnij w dół, aby spróbować ponownie.';

  @override
  String get homeContinueWatching => 'Oglądane';

  @override
  String get homeNoIptvSources =>
      'Brak aktywnego źródła IPTV. Dodaj źródło w Ustawieniach, aby zobaczyć kategorie.';

  @override
  String get homeNoTrends => 'Brak treści na czasie';

  @override
  String get actionRefreshMetadata => 'Odśwież metadane';

  @override
  String get actionChangeMetadata => 'Zmień metadane';

  @override
  String get actionAddToList => 'Dodaj do listy';

  @override
  String get metadataRefreshed => 'Metadane odświeżone';

  @override
  String get errorRefreshingMetadata => 'Błąd podczas odświeżania metadanych';

  @override
  String get actionMarkSeen => 'Oznacz jako obejrzane';

  @override
  String get actionMarkUnseen => 'Oznacz jako nieobejrzane';

  @override
  String get actionReportProblem => 'Zgłoś problem';

  @override
  String get featureComingSoon => 'Funkcja wkrótce dostępna';

  @override
  String get subtitlesMenuTitle => 'Napisy';

  @override
  String get audioMenuTitle => 'Dźwięk';

  @override
  String get videoFitModeMenuTitle => 'Tryb wyświetlania';

  @override
  String get videoFitModeContain => 'Oryginalne proporcje';

  @override
  String get videoFitModeCover => 'Wypełnij ekran';

  @override
  String get actionDisable => 'Wyłącz';

  @override
  String defaultTrackLabel(String id) {
    return 'Ścieżka $id';
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
  String get actionNextEpisode => 'Następny odcinek';

  @override
  String get actionRestart => 'Uruchom ponownie';

  @override
  String get errorSeriesDataUnavailable => 'Nie można załadować danych serialu';

  @override
  String get errorNextEpisodeFailed => 'Nie można określić następnego odcinka';

  @override
  String get actionLoadMore => 'Załaduj więcej';

  @override
  String get iptvServerUrlLabel => 'URL serwera';

  @override
  String get iptvServerUrlHint => 'URL serwera Xtream';

  @override
  String get iptvPasswordLabel => 'Hasło';

  @override
  String get iptvPasswordHint => 'Hasło Xtream';

  @override
  String get actionConnect => 'Połącz';

  @override
  String get settingsRefreshIptvPlaylistsTitle => 'Odśwież listy IPTV';

  @override
  String get activeSourceTitle => 'Aktywne źródło';

  @override
  String get statusActive => 'Aktywne';

  @override
  String get statusNoActiveSource => 'Brak aktywnego źródła';

  @override
  String get overlayPreparingHome => 'Przygotowywanie strony głównej…';

  @override
  String get overlayLoadingMoviesAndSeries => 'Ładowanie filmów i seriali…';

  @override
  String get overlayLoadingCategories => 'Ładowanie kategorii…';

  @override
  String get bootstrapRefreshing => 'Odświeżanie list IPTV…';

  @override
  String get bootstrapEnriching => 'Przygotowywanie metadanych…';

  @override
  String get errorPrepareHome => 'Nie można przygotować strony głównej';

  @override
  String get overlayOpeningHome => 'Otwieranie strony głównej…';

  @override
  String get overlayRefreshingIptvLists => 'Odświeżanie list IPTV…';

  @override
  String get overlayPreparingMetadata => 'Przygotowywanie metadanych…';

  @override
  String get errorHomeLoadTimeout =>
      'Przekroczono czas oczekiwania ładowania strony głównej';

  @override
  String get faqLabel => 'Najczęściej zadawane pytania';

  @override
  String get iptvUsernameLabel => 'Nazwa użytkownika';

  @override
  String get iptvUsernameHint => 'Nazwa użytkownika Xtream';

  @override
  String get actionBack => 'Wstecz';

  @override
  String get actionSeeAll => 'Zobacz wszystko';

  @override
  String get actionExpand => 'Rozwiń';

  @override
  String get actionCollapse => 'Zwiń';

  @override
  String providerSearchPlaceholder(String provider) {
    return 'Szukaj na $provider...';
  }

  @override
  String get actionClearHistory => 'Wyczyść historię';

  @override
  String get castTitle => 'Obsada';

  @override
  String get recommendationsTitle => 'Polecane';

  @override
  String get libraryHeader => 'Twoja wideoteka';

  @override
  String get libraryDataInfo =>
      'Dane zostaną wyświetlone po implementacji warstw data/domain.';

  @override
  String get libraryEmpty =>
      'Polub filmy, seriale lub aktorów, aby zobaczyć je tutaj.';

  @override
  String get serie => 'Serial';

  @override
  String get recherche => 'Szukaj';

  @override
  String get notYetAvailable => 'Jeszcze niedostępne';

  @override
  String get createPlaylistTitle => 'Utwórz listę';

  @override
  String get playlistName => 'Nazwa listy';

  @override
  String get addMedia => 'Dodaj media';

  @override
  String get renamePlaylist => 'Zmień nazwę';

  @override
  String get deletePlaylist => 'Usuń';

  @override
  String get pinPlaylist => 'Przypnij';

  @override
  String get unpinPlaylist => 'Odepnij';

  @override
  String get playlistPinned => 'Lista przypięta';

  @override
  String get playlistUnpinned => 'Lista odpięta';

  @override
  String get playlistDeleted => 'Lista usunięta';

  @override
  String playlistCreatedSuccess(String name) {
    return 'Lista \"$name\" utworzona';
  }

  @override
  String playlistCreateError(String error) {
    return 'Błąd podczas tworzenia listy: $error';
  }

  @override
  String get addedToPlaylist => 'Dodano';

  @override
  String get pinRecoveryLink => 'Récupérer le code PIN';

  @override
  String get pinRecoveryTitle => 'Odzyskaj kod PIN';

  @override
  String get pinRecoveryDescription =>
      'Odzyskaj kod PIN dla chronionego profilu.';

  @override
  String get pinRecoveryComingSoon => 'Ta funkcja wkrótce będzie dostępna.';

  @override
  String get pinRecoveryCodeLabel => 'Kod odzyskiwania';

  @override
  String get pinRecoveryCodeHint => '8 cyfr';

  @override
  String get pinRecoveryVerifyButton => 'Zweryfikuj';

  @override
  String get pinRecoveryCodeInvalid => 'Wpisz 8-cyfrowy kod';

  @override
  String get pinRecoveryCodeExpired => 'Kod odzyskiwania wygasł';

  @override
  String get pinRecoveryTooManyAttempts =>
      'Za dużo prób. Spróbuj ponownie później.';

  @override
  String get pinRecoveryUnknownError => 'Wystąpił nieoczekiwany błąd';

  @override
  String get pinRecoveryNewPinLabel => 'Nowy PIN';

  @override
  String get pinRecoveryNewPinHint => '4-6 cyfr';

  @override
  String get pinRecoveryConfirmPinLabel => 'Potwierdź PIN';

  @override
  String get pinRecoveryConfirmPinHint => 'Powtórz PIN';

  @override
  String get pinRecoveryResetButton => 'Zaktualizuj PIN';

  @override
  String get pinRecoveryPinInvalid => 'Wpisz PIN z 4 do 6 cyfr';

  @override
  String get pinRecoveryPinMismatch => 'Kody PIN nie są takie same';

  @override
  String get pinRecoveryResetSuccess => 'PIN zaktualizowany';

  @override
  String get settingsAccountsSection => 'Konta';

  @override
  String get settingsIptvSection => 'Ustawienia IPTV';

  @override
  String get settingsSourcesManagement => 'Zarządzanie źródłami';

  @override
  String get settingsSyncFrequency => 'Częstotliwość aktualizacji';

  @override
  String get settingsAppSection => 'Ustawienia aplikacji';

  @override
  String get settingsAccentColor => 'Kolor akcentu';

  @override
  String get settingsPlaybackSection => 'Ustawienia odtwarzania';

  @override
  String get settingsPreferredAudioLanguage => 'Preferowany język';

  @override
  String get settingsPreferredSubtitleLanguage => 'Preferowane napisy';

  @override
  String get libraryPlaylistsFilter => 'Listy odtwarzania';

  @override
  String get librarySagasFilter => 'Sagi';

  @override
  String get libraryArtistsFilter => 'Artyści';

  @override
  String get librarySearchPlaceholder => 'Szukaj w mojej bibliotece...';

  @override
  String get libraryInProgress => 'W trakcie';

  @override
  String get libraryFavoriteMovies => 'Ulubione filmy';

  @override
  String get libraryFavoriteSeries => 'Ulubione seriale';

  @override
  String get libraryWatchHistory => 'Historia oglądania';

  @override
  String libraryItemCountPlural(int count) {
    return '$count elementów';
  }

  @override
  String get searchPeopleTitle => 'Osoby';

  @override
  String get searchSagasTitle => 'Sagi';

  @override
  String get searchByProvidersTitle => 'Według dostawców';

  @override
  String get searchByGenresTitle => 'Według gatunków';

  @override
  String get personRoleActor => 'Aktor';

  @override
  String get personRoleDirector => 'Reżyser';

  @override
  String get personRoleCreator => 'Twórca';

  @override
  String get tvDistribution => 'Obsada';

  @override
  String tvSeasonLabel(int number) {
    return 'Sezon $number';
  }

  @override
  String get tvNoEpisodesAvailable => 'Brak dostępnych odcinków';

  @override
  String tvResumeSeasonEpisode(int season, int episode) {
    return 'Wznów S$season E$episode';
  }

  @override
  String get sagaViewPage => 'Zobacz stronę';

  @override
  String get sagaStartNow => 'Zacznij teraz';

  @override
  String get sagaContinue => 'Kontynuuj';

  @override
  String sagaMovieCount(int count) {
    return '$count filmów';
  }

  @override
  String get sagaMoviesList => 'Lista filmów';

  @override
  String personMoviesCount(int movies, int shows) {
    return '$movies filmów - $shows seriali';
  }

  @override
  String get personPlayRandomly => 'Odtwarzaj losowo';

  @override
  String get personMoviesList => 'Lista filmów';

  @override
  String get personSeriesList => 'Lista seriali';

  @override
  String get playlistPlayRandomly => 'Odtwarzaj losowo';

  @override
  String get playlistAddButton => 'Dodaj';

  @override
  String get playlistSortButton => 'Sortuj';

  @override
  String get playlistSortByTitle => 'Sortuj według';

  @override
  String get playlistSortByTitleOption => 'Tytuł';

  @override
  String get playlistSortRecentAdditions => 'Ostatnio dodane';

  @override
  String get playlistSortOldestFirst => 'Najstarsze najpierw';

  @override
  String get playlistSortNewestFirst => 'Najnowsze najpierw';

  @override
  String get playlistEmptyMessage => 'Brak elementów na tej liście';

  @override
  String playlistItemCount(int count) {
    return '$count element';
  }

  @override
  String playlistItemCountPlural(int count) {
    return '$count elementów';
  }

  @override
  String get playlistSeasonSingular => 'sezon';

  @override
  String get playlistSeasonPlural => 'sezony';

  @override
  String get playlistRenameTitle => 'Zmień nazwę listy';

  @override
  String get playlistNamePlaceholder => 'Nazwa listy';

  @override
  String playlistRenamedSuccess(String name) {
    return 'Lista przemianowana na \"$name\"';
  }

  @override
  String get playlistDeleteTitle => 'Usuń';

  @override
  String playlistDeleteConfirm(String title) {
    return 'Czy na pewno chcesz usunąć \"$title\"?';
  }

  @override
  String get playlistDeletedSuccess => 'Lista usunięta';

  @override
  String get playlistItemRemovedSuccess => 'Element usunięty';

  @override
  String playlistRemoveItemConfirm(String title) {
    return 'Usunąć \"$title\" z listy?';
  }

  @override
  String get categoryLoadFailed => 'Błąd podczas ładowania kategorii.';

  @override
  String get categoryEmpty => 'Brak elementów w tej kategorii.';

  @override
  String get categoryLoadingMore => 'Ładowanie więcej…';

  @override
  String get movieNoPlaylistsAvailable => 'Brak dostępnych playlist';

  @override
  String playlistAddedTo(String title) {
    return 'Dodano do \"$title\"';
  }

  @override
  String errorWithMessage(String message) {
    return 'Błąd: $message';
  }

  @override
  String get movieNotAvailableInPlaylist => 'Film niedostępny na playliście';

  @override
  String errorPlaybackFailed(String message) {
    return 'Błąd podczas odtwarzania filmu: $message';
  }

  @override
  String get movieNoMedia => 'Brak treści do wyświetlenia';

  @override
  String get personNoData => 'Brak osoby do wyświetlenia.';

  @override
  String get personGenericError => 'Wystąpił błąd podczas ładowania tej osoby.';

  @override
  String get personBiographyTitle => 'Biografia';

  @override
  String get authOtpTitle => 'Zaloguj się';

  @override
  String get authOtpSubtitle =>
      'Wpisz swój email i 8-cyfrowy kod, który Ci wyślemy.';

  @override
  String get authOtpEmailLabel => 'Email';

  @override
  String get authOtpEmailHint => 'twoj@email';

  @override
  String get authOtpEmailHelp =>
      'Wyślemy Ci 8-cyfrowy kod. Sprawdź spam, jeśli to konieczne.';

  @override
  String get authOtpCodeLabel => 'Kod weryfikacyjny';

  @override
  String get authOtpCodeHint => '8-cyfrowy kod';

  @override
  String get authOtpCodeHelp => 'Wpisz 8-cyfrowy kod otrzymany mailem.';

  @override
  String get authOtpPrimarySend => 'Wyślij kod';

  @override
  String get authOtpPrimarySubmit => 'Zaloguj się';

  @override
  String get authOtpResend => 'Wyślij kod ponownie';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Wyślij kod ponownie za ${seconds}s';
  }

  @override
  String get authOtpChangeEmail => 'Zmień email';

  @override
  String get resumePlayback => 'Wznów odtwarzanie';

  @override
  String get settingsCloudSyncSection => 'Synchronizacja w chmurze';

  @override
  String get settingsCloudSyncAuto => 'Synchronizacja automatyczna';

  @override
  String get settingsCloudSyncNow => 'Synchronizuj teraz';

  @override
  String get settingsCloudSyncInProgress => 'Synchronizowanie…';

  @override
  String get settingsCloudSyncNever => 'Nigdy';

  @override
  String settingsCloudSyncError(Object error) {
    return 'Ostatni błąd: $error';
  }

  @override
  String notFoundWithEntity(String entity) {
    return 'Nie znaleziono: $entity';
  }

  @override
  String notFoundWithEntityAndError(String entity, String error) {
    return 'Nie znaleziono: $entity: $error';
  }

  @override
  String get entityProvider => 'Dostawca';

  @override
  String get entityGenre => 'Gatunek';

  @override
  String get entityPlaylist => 'Playlista';

  @override
  String get entitySource => 'Źródło';

  @override
  String get entityMovie => 'Film';

  @override
  String get entitySeries => 'Serial';

  @override
  String get entityPerson => 'Osoba';

  @override
  String get entitySaga => 'Saga';

  @override
  String get entityVideo => 'Wideo';

  @override
  String get entityRoute => 'Trasa';

  @override
  String get errorTimeoutLoading => 'Przekroczono limit czasu ładowania';

  @override
  String get parentalContentRestricted => 'Zawartość ograniczona';

  @override
  String get parentalContentRestrictedDefault =>
      'Ta zawartość jest zablokowana przez kontrolę rodzicielską tego profilu.';

  @override
  String get parentalReasonTooYoung =>
      'Ta zawartość wymaga wyższego wieku niż limit tego profilu.';

  @override
  String get parentalReasonUnknownRating =>
      'Klasyfikacja wiekowa tej zawartości nie jest dostępna.';

  @override
  String get parentalReasonInvalidTmdbId =>
      'Ta zawartość nie może być oceniona pod kątem kontroli rodzicielskiej.';

  @override
  String get parentalUnlockButton => 'Odblokuj';

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
      'Trwa ładowanie odcinków…';

  @override
  String get hc_aucune_playlist_disponible_creez_en_une_f6b75c90 =>
      'Brak dostępnej playlisty. Utwórz nową.';

  @override
  String get hc_erreur_lors_chargement_playlists_placeholder_97e5c1c3 =>
      'Błąd podczas ładowania playlist: \$e';

  @override
  String get hc_impossible_douvrir_lien_90d0dcaa => 'Nie można otworzyć linku';

  @override
  String get hc_qualite_preferee_776dbeea => 'Preferowana jakość';

  @override
  String get hc_annuler_49ba3292 => 'Cancel';

  @override
  String get hc_deconnexion_903dca17 => 'Wyloguj się';

  @override
  String get hc_erreur_lors_deconnexion_placeholder_f5a211b4 =>
      'Błąd podczas wylogowywania: \$e';

  @override
  String get hc_choisir_b030d590 => 'Choose';

  @override
  String get hc_avantages_08d7f47c => 'Benefits';

  @override
  String get hc_signalement_envoye_merci_d302e576 =>
      'Zgłoszenie wysłane. Dziękujemy.';

  @override
  String get hc_plus_tard_1f42ab3b => 'Później';

  @override
  String get hc_redemarrer_maintenant_053e8e68 => 'Uruchom ponownie teraz';

  @override
  String get hc_utiliser_cette_source_c6c8bbc5 => 'Użyć tego źródła?';

  @override
  String get hc_utiliser_fb5e43ce => 'Use';

  @override
  String get hc_source_ajout_e_e41b01d9 => 'Źródło dodane';

  @override
  String get hc_title_0a57b7eb => 'title: \'...\'';

  @override
  String get hc_labeltext_469a28db => 'labelText: \'...\'';

  @override
  String get hc_hinttext_6fd1d945 => 'hintText: \'...\'';

  @override
  String get hc_tooltip_db0de3fe => 'tooltip: \'...\'';

  @override
  String get hc_parametres_verrouilles_3a9b1b51 => 'Zablokowane ustawienia';

  @override
  String get hc_compte_cloud_2812b31e => 'Konto w chmurze';

  @override
  String get hc_se_connecter_fedf2439 => 'Zaloguj się';

  @override
  String get hc_propos_5345add5 => 'O aplikacji';

  @override
  String get hc_politique_confidentialite_42b0e51e => 'Polityka prywatności';

  @override
  String get hc_conditions_dutilisation_9074eac7 => 'Warunki użytkowania';

  @override
  String get hc_sources_sauvegardees_9f1382e5 => 'Zapisane źródła';

  @override
  String get hc_rafraichir_be30b7d1 => 'Odśwież';

  @override
  String get hc_activer_une_source_749ced38 => 'Aktywuj źródło';

  @override
  String get hc_nom_source_9a3e4156 => 'Nazwa źródła';

  @override
  String get hc_mon_iptv_b239352c => 'Moje IPTV';

  @override
  String get hc_username_84c29015 => 'Nazwa użytkownika';

  @override
  String get hc_password_8be3c943 => 'Hasło';

  @override
  String get hc_server_url_1d5d1eff => 'URL serwera';

  @override
  String get hc_verification_pin_e17c8fe0 => 'Weryfikacja PIN';

  @override
  String get hc_definir_un_pin_f9c2178d => 'Ustaw PIN';

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
      'Niedostępne w tym źródle';

  @override
  String get hc_source_supprimee_4bfaa0a1 => 'Źródło usunięte';

  @override
  String get hc_source_modifiee_335ef502 => 'Źródło zaktualizowane';

  @override
  String get hc_definir_code_pin_53a0bd07 => 'Ustaw kod PIN';

  @override
  String get hc_marquer_comme_non_vu_9cf9d3f8 => 'Oznacz jako nieobejrzane';

  @override
  String get hc_etes_vous_sur_vouloir_vous_deconnecter_1a096661 =>
      'Na pewno chcesz się wylogować?';

  @override
  String get hc_movi_premium_requis_pour_synchronisation_cloud_15b551df =>
      'Do synchronizacji w chmurze wymagany jest Movi Premium.';

  @override
  String get hc_auto_c614ba7c => 'Auto';

  @override
  String get hc_organiser_838a7e57 => 'Uporządkuj';

  @override
  String get hc_modifier_f260e757 => 'Edytuj';

  @override
  String get hc_ajouter_87c57ed1 => 'Dodaj';

  @override
  String get hc_source_active_e571305e => 'Aktywne źródło';

  @override
  String get hc_autres_sources_e32592a6 => 'Inne źródła';

  @override
  String get hc_signalement_indisponible_pour_ce_contenu_d9ad88b7 =>
      'Zgłaszanie jest niedostępne dla tej treści.';

  @override
  String get hc_securisation_contenu_e5195111 => 'Zabezpieczanie treści';

  @override
  String get hc_verification_classifications_d_age_006eebfe =>
      'Sprawdzanie klasyfikacji wiekowych…';

  @override
  String get hc_voir_tout_7b7d86e8 => 'Zobacz wszystko';

  @override
  String get hc_signaler_un_probleme_13183c0f => 'Zgłoś problem';

  @override
  String get hc_si_ce_contenu_nest_pas_approprie_ete_accessible_320c2436 =>
      'Jeśli ta treść nie jest odpowiednia i była dostępna mimo ograniczeń, krótko opisz problem.';

  @override
  String get hc_envoyer_e9ce243b => 'Wyślij';

  @override
  String get hc_profil_enfant_cree_39f4eb7d => 'Utworzono profil dziecka';

  @override
  String get hc_un_profil_enfant_ete_cree_pour_securiser_l_40e15a0a =>
      'Utworzono profil dziecka. Aby zabezpieczyć aplikację i wstępnie wczytać klasyfikacje wiekowe, zaleca się ponowne uruchomienie aplikacji.';

  @override
  String get hc_pseudo_4cf966c0 => 'Pseudonim';

  @override
  String get hc_profil_enfant_2c8a01c0 => 'Profil dziecka';

  @override
  String get hc_limite_d_age_5b170fc9 => 'Limit wieku';

  @override
  String get hc_code_pin_e79c48bd => 'Kod PIN';

  @override
  String get hc_changer_code_pin_3b069731 => 'Zmień kod PIN';

  @override
  String get hc_supprimer_code_pin_0dcf8a48 => 'Usuń kod PIN';

  @override
  String get hc_supprimer_pin_51850c7b => 'Usuń PIN';

  @override
  String get hc_supprimer_1acfc1c7 => 'Usuń';

  @override
  String get hc_oblige_un_pin_active_filtre_pegi_8447ac9b =>
      'Wymaga PIN i włącza filtr PEGI.';

  @override
  String get hc_voulez_vous_activer_cette_source_maintenant_f2593894 =>
      'Czy chcesz aktywować to źródło teraz?';

  @override
  String get hc_application_b291beb8 => 'Aplikacja';

  @override
  String get hc_version_1_0_0_347e553c => 'Version 1.0.0';

  @override
  String get hc_credits_293a6081 => 'Twórcy';

  @override
  String get hc_this_product_uses_tmdb_api_but_is_not_0033d77f =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  String get hc_ce_produit_utilise_l_api_tmdb_mais_n_0b55273a =>
      'Ten produkt korzysta z API TMDB, ale nie jest wspierany ani certyfikowany przez TMDB.';

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
  String get hc_url_invalide_aa227a66 => 'Nieprawidłowy URL';

  @override
  String get hc_legacy_iv_missing_cannot_decrypt_legacy_ciphertext_7c7b39c3 =>
      'Missing legacy IV: cannot decrypt legacy ciphertext.';

  @override
  String get hc_tooltip_rafraichir_a22b17e3 => 'tooltip: \'Odśwież\'';

  @override
  String get hc_tooltip_menu_d8fa6679 => 'tooltip: \'Menu\'';

  @override
  String get hc_retour_e5befb1f => 'Wstecz';

  @override
  String get hc_semanticlabel_plus_d_actions_1bd19eb6 =>
      'semanticLabel: \'Więcej działań\'';

  @override
  String get hc_plus_d_actions_ffe6be2a => 'Więcej działań';

  @override
  String get hc_semanticlabel_rechercher_3ae4e02c =>
      'semanticLabel: \'Szukaj\'';

  @override
  String get hc_semanticlabel_ajouter_ac362a68 => 'semanticLabel: \'Dodaj\'';

  @override
  String get hc_l10n_86d50bf0 => 'l10n.*';

  @override
  String get actionOk => 'OK';

  @override
  String get actionSignOut => 'Wyloguj';

  @override
  String get dialogSignOutBody => 'Czy na pewno chcesz się wylogować?';

  @override
  String get settingsUnableToOpenLink => 'Nie można otworzyć linku';

  @override
  String get settingsSyncDisabled => 'Wyłączone';

  @override
  String get settingsSyncEveryHour => 'Co godzinę';

  @override
  String get settingsSyncEvery2Hours => 'Co 2 godziny';

  @override
  String get settingsSyncEvery4Hours => 'Co 4 godziny';

  @override
  String get settingsSyncEvery6Hours => 'Co 6 godzin';

  @override
  String get settingsSyncEveryDay => 'Codziennie';

  @override
  String get settingsSyncEvery2Days => 'Co 2 dni';

  @override
  String get settingsColorCustom => 'Niestandardowy';

  @override
  String get settingsColorBlue => 'Niebieski';

  @override
  String get settingsColorPink => 'Różowy';

  @override
  String get settingsColorGreen => 'Zielony';

  @override
  String get settingsColorPurple => 'Fioletowy';

  @override
  String get settingsColorOrange => 'Pomarańczowy';

  @override
  String get settingsColorTurquoise => 'Turkusowy';

  @override
  String get settingsColorYellow => 'Żółty';

  @override
  String get settingsColorIndigo => 'Indygo';

  @override
  String get settingsCloudAccountTitle => 'Konto w chmurze';

  @override
  String get settingsAccountConnected => 'Połączono';

  @override
  String get settingsAccountLocalMode => 'Tryb lokalny';

  @override
  String get settingsAccountCloudUnavailable => 'Chmura niedostępna';

  @override
  String get aboutTmdbDisclaimer =>
      'Ten produkt korzysta z API TMDB, ale nie jest wspierany ani certyfikowany przez TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Podziękowania';
}
