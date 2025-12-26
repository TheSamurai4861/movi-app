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
  String get statusActive => 'Aktywne';

  @override
  String get statusNoActiveSource => 'Brak aktywnego źródła';

  @override
  String get overlayPreparingHome => 'Przygotowywanie strony głównej…';

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
  String libraryItemCount(int count) {
    return '$count element';
  }

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
  String errorLoadingPlaylists(String message) {
    return 'Błąd podczas ładowania playlist: $message';
  }

  @override
  String errorPlaybackFailed(String message) {
    return 'Błąd podczas odtwarzania filmu: $message';
  }

  @override
  String get movieNoMedia => 'No media to display';

  @override
  String get personNoData => 'Brak osoby do wyświetlenia.';

  @override
  String get personGenericError => 'Wystąpił błąd podczas ładowania tej osoby.';

  @override
  String get personBiographyTitle => 'Biografia';

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
}
