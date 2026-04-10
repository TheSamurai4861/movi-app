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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wyniku',
      many: '$count wyników',
      few: '$count wyniki',
      one: '1 wynik',
      zero: 'Brak wyników',
    );
    return '$_temp0';
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
  String get libraryTypeInProgress => 'Oglądaj dalej';

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
    return 'Szukaj w: $provider';
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
  String get pinRecoveryLink => 'Odzyskaj PIN';

  @override
  String get pinRecoveryTitle => 'Odzyskaj PIN';

  @override
  String get pinRecoveryDescription =>
      'Odzyskaj PIN dla profilu chronionego kodem.';

  @override
  String get pinRecoveryRequestCodeButton => 'Wyślij kod';

  @override
  String get pinRecoveryCodeSentHint =>
      'Kod został wysłany na adres e-mail Twojego konta. Sprawdź wiadomości i wpisz go poniżej.';

  @override
  String get pinRecoveryComingSoon => 'Ta funkcja wkrótce będzie dostępna.';

  @override
  String get pinRecoveryNotAvailable =>
      'Odzyskiwanie kodu PIN przez e-mail jest obecnie niedostępne.';

  @override
  String get pinRecoveryCodeLabel => 'Kod odzyskiwania';

  @override
  String get pinRecoveryCodeHint => '8 cyfr';

  @override
  String get pinRecoveryVerifyButton => 'Zweryfikuj kod';

  @override
  String get pinRecoveryCodeInvalid => 'Wpisz 8-cyfrowy kod.';

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
  String get pinRecoveryConfirmPinHint => 'Potwierdź PIN';

  @override
  String get pinRecoveryResetButton => 'Zresetuj PIN';

  @override
  String get pinRecoveryPinInvalid => 'Wpisz PIN składający się z 4–6 cyfr.';

  @override
  String get pinRecoveryPinMismatch => 'Kody PIN nie są takie same';

  @override
  String get pinRecoveryResetSuccess => 'PIN zaktualizowany';

  @override
  String get profilePinSaved => 'Kod PIN zapisany.';

  @override
  String get profilePinEditLabel => 'Edytuj kod PIN';

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
  String get settingsPreferredAudioLanguage => 'Preferowany język audio';

  @override
  String get settingsPreferredSubtitleLanguage => 'Preferowany język napisów';

  @override
  String get libraryPlaylistsFilter => 'Listy odtwarzania';

  @override
  String get librarySagasFilter => 'Sagi';

  @override
  String get libraryArtistsFilter => 'Artyści';

  @override
  String get librarySearchPlaceholder => 'Szukaj w mojej bibliotece...';

  @override
  String get libraryInProgress => 'Oglądaj dalej';

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
    return 'Wznów: S$season · E$episode';
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
  String get playlistAddButton => 'Dodaj do playlisty';

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
  String get playlistDeleteTitle => 'Usuń playlistę';

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
      'Wpisz swój adres e-mail i 8-cyfrowy kod, który wyślemy Ci e-mailem.';

  @override
  String get authOtpEmailLabel => 'Email';

  @override
  String get authOtpEmailHint => 'nazwa@przyklad.pl';

  @override
  String get authOtpEmailHelp =>
      'Wyślemy Ci 8-cyfrowy kod. Sprawdź spam, jeśli to konieczne.';

  @override
  String get authOtpCodeLabel => 'Kod weryfikacyjny';

  @override
  String get authOtpCodeHint => '8-cyfrowy kod';

  @override
  String get authOtpCodeHelp => 'Wpisz 8-cyfrowy kod otrzymany e-mailem.';

  @override
  String get authOtpPrimarySend => 'Wyślij kod';

  @override
  String get authOtpPrimarySubmit => 'Zaloguj się';

  @override
  String get authOtpResend => 'Wyślij kod ponownie';

  @override
  String authOtpResendDisabled(int seconds) {
    return 'Wyślij kod ponownie za $seconds s';
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
  String get settingsSubtitlesTitle => 'Napisy';

  @override
  String get settingsSubtitlesSizeTitle => 'Rozmiar tekstu';

  @override
  String get settingsSubtitlesColorTitle => 'Kolor tekstu';

  @override
  String get settingsSubtitlesFontTitle => 'Czcionka';

  @override
  String get settingsSubtitlesSizeSmall => 'S';

  @override
  String get settingsSubtitlesSizeMedium => 'M';

  @override
  String get settingsSubtitlesSizeLarge => 'L';

  @override
  String get settingsSubtitlesFontSystem => 'Systemowa';

  @override
  String get settingsSubtitlesQuickSettingsTitle => 'Szybkie ustawienia';

  @override
  String get settingsSubtitlesPreviewTitle => 'Podgląd';

  @override
  String get settingsSubtitlesPreviewSample =>
      'To jest podgląd napisów.\nDopasuj czytelność w czasie rzeczywistym.';

  @override
  String get settingsSubtitlesBackgroundTitle => 'Tło';

  @override
  String get settingsSubtitlesBackgroundOpacityLabel => 'Przezroczystość tła';

  @override
  String get settingsSubtitlesShadowTitle => 'Cień';

  @override
  String get settingsSubtitlesShadowOff => 'Wyłączony';

  @override
  String get settingsSubtitlesShadowSoft => 'Miękki';

  @override
  String get settingsSubtitlesShadowStrong => 'Mocny';

  @override
  String get settingsSubtitlesFineSizeTitle => 'Precyzyjny rozmiar';

  @override
  String get settingsSubtitlesFineSizeValueLabel => 'Skala';

  @override
  String get settingsSubtitlesResetDefaults => 'Przywróć domyślne';

  @override
  String get settingsSubtitlesPremiumLockedTitle =>
      'Zaawansowany styl napisów (Premium)';

  @override
  String get settingsSubtitlesPremiumLockedBody =>
      'Tło, przezroczystość, presety cienia i precyzyjny rozmiar są dostępne w Movi Premium.';

  @override
  String get settingsSubtitlesPremiumLockedAction => 'Odblokuj Premium';

  @override
  String get settingsSyncSectionTitle => 'Synchronizacja audio/napisów';

  @override
  String get settingsSubtitleOffsetTitle => 'Przesunięcie napisów';

  @override
  String get settingsAudioOffsetTitle => 'Przesunięcie audio';

  @override
  String get settingsOffsetUnsupported =>
      'Ta funkcja nie jest obsługiwana przez ten backend lub tę platformę.';

  @override
  String get settingsSyncResetOffsets => 'Resetuj przesunięcia synchronizacji';

  @override
  String get aboutTmdbDisclaimer =>
      'Ten produkt korzysta z API TMDB, ale nie jest wspierany ani certyfikowany przez TMDB.';

  @override
  String get aboutCreditsSectionTitle => 'Podziękowania';

  @override
  String get actionSend => 'Wyślij';

  @override
  String get profilePinSetLabel => 'Ustaw kod PIN';

  @override
  String get reportingProblemSentConfirmation =>
      'Zgłoszenie zostało wysłane. Dziękujemy.';

  @override
  String get reportingProblemBody =>
      'Jeśli te treści są nieodpowiednie i mimo ograniczeń były dostępne, krótko opisz problem.';

  @override
  String get reportingProblemExampleHint =>
      'Przykład: film horror dostępny mimo PEGI 12';

  @override
  String get settingsAutomaticOption => 'Automatycznie';

  @override
  String get settingsPreferredPlaybackQuality =>
      'Preferowana jakość odtwarzania';

  @override
  String settingsSignOutError(String error) {
    return 'Błąd podczas wylogowywania: $error';
  }

  @override
  String get settingsTermsOfUseTitle => 'Warunki korzystania';

  @override
  String get settingsCloudSyncPremiumRequiredMessage =>
      'Movi Premium jest wymagane do synchronizacji w chmurze.';
}
